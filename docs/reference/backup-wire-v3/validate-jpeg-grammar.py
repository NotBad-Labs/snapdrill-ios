#!/usr/bin/env python3

import pathlib
import sys


FIXED_JFIF = bytes.fromhex(
    "ffd8ffe000104a46494600010200000100010000"
)
SOF_MARKERS = {0xC0}
ALLOWED_SEGMENTS = SOF_MARKERS | {0xC4, 0xDA, 0xDB, 0xDD}
MAX_SCAN_COUNT = 3


class JPEGError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise JPEGError(message)


def parse_dqt(payload, definitions):
    offset = 0
    while offset < len(payload):
        info = payload[offset]
        offset += 1
        precision = info >> 4
        identifier = info & 0x0F
        require(precision in (0, 1), "invalid DQT precision")
        require(identifier <= 3, "invalid DQT identifier")
        size = 64 * (precision + 1)
        require(offset + size <= len(payload), "truncated DQT")
        require(identifier not in definitions, "duplicate DQT definition")
        values = payload[offset : offset + size]
        if precision == 0:
            require(all(value != 0 for value in values), "zero DQT coefficient")
        else:
            require(
                all(
                    values[index : index + 2] != b"\x00\x00"
                    for index in range(0, len(values), 2)
                ),
                "zero DQT coefficient",
            )
        definitions.add(identifier)
        offset += size
    require(offset == len(payload), "DQT trailing bytes")


def parse_dht(payload, active_definitions):
    offset = 0
    segment_definitions = set()
    while offset < len(payload):
        require(offset + 17 <= len(payload), "truncated DHT header")
        info = payload[offset]
        offset += 1
        table_class = info >> 4
        identifier = info & 0x0F
        require(table_class in (0, 1), "invalid DHT class")
        require(identifier <= 3, "invalid DHT identifier")
        counts = payload[offset : offset + 16]
        offset += 16
        symbol_count = sum(counts)
        require(symbol_count > 0, "empty DHT symbol set")
        require(symbol_count <= 256, "oversized DHT symbol set")
        remaining_codes = 1
        for count in counts:
            remaining_codes = remaining_codes * 2 - count
            require(remaining_codes >= 0, "oversubscribed DHT")
        require(offset + symbol_count <= len(payload), "truncated DHT symbols")
        symbols = payload[offset : offset + symbol_count]
        require(len(set(symbols)) == len(symbols), "duplicate DHT symbol")
        if table_class == 0:
            require(all(symbol <= 11 for symbol in symbols), "invalid DC Huffman symbol")
        else:
            require(
                all(
                    (symbol & 0x0F) <= 10
                    and ((symbol & 0x0F) != 0 or (symbol >> 4) in (0, 15))
                    for symbol in symbols
                ),
                "invalid AC Huffman symbol",
            )
        key = (table_class, identifier)
        require(key not in segment_definitions, "duplicate DHT definition in one segment")
        require(
            active_definitions.get(key, True),
            "unreferenced DHT definition replaced",
        )
        segment_definitions.add(key)
        active_definitions[key] = False
        offset += symbol_count
    require(offset == len(payload), "DHT trailing bytes")


def parse_sof(marker, payload):
    require(len(payload) >= 6, "truncated SOF")
    precision = payload[0]
    height = int.from_bytes(payload[1:3], "big")
    width = int.from_bytes(payload[3:5], "big")
    component_count = payload[5]
    require(precision == 8, "SOF precision is not 8-bit")
    require(1 <= width <= 2000 and 1 <= height <= 2000, "SOF dimensions out of range")
    require(component_count in (1, 3), "SOF component count")
    require(len(payload) == 6 + 3 * component_count, "SOF length mismatch")

    components = {}
    offset = 6
    for _ in range(component_count):
        identifier = payload[offset]
        sampling = payload[offset + 1]
        quantization = payload[offset + 2]
        offset += 3
        horizontal = sampling >> 4
        vertical = sampling & 0x0F
        require(identifier not in components, "duplicate SOF component")
        require(1 <= horizontal <= 4 and 1 <= vertical <= 4, "invalid sampling factor")
        require(quantization <= 3, "invalid SOF DQT reference")
        components[identifier] = quantization

    expected_ids = [1] if component_count == 1 else [1, 2, 3]
    require(list(components) == expected_ids, "noncanonical SOF component IDs/order")
    return marker, width, height, components


def parse_sos(payload, frame_marker, frame_components):
    require(frame_marker is not None, "SOS precedes SOF")
    require(len(payload) >= 4, "truncated SOS")
    component_count = payload[0]
    require(1 <= component_count <= len(frame_components), "SOS component count")
    require(len(payload) == 4 + 2 * component_count, "SOS length mismatch")

    offset = 1
    components = []
    selectors = {}
    for _ in range(component_count):
        identifier = payload[offset]
        tables = payload[offset + 1]
        offset += 2
        require(identifier in frame_components, "unknown SOS component")
        require(identifier not in selectors, "duplicate SOS component")
        dc_table = tables >> 4
        ac_table = tables & 0x0F
        require(dc_table <= 3 and ac_table <= 3, "invalid SOS DHT reference")
        components.append(identifier)
        selectors[identifier] = (dc_table, ac_table)

    spectral_start = payload[offset]
    spectral_end = payload[offset + 1]
    approximation = payload[offset + 2]
    high = approximation >> 4
    low = approximation & 0x0F
    require(
        (spectral_start, spectral_end, high, low) == (0, 63, 0, 0),
        "invalid sequential SOS parameters",
    )

    references = set()
    for identifier, (dc_table, ac_table) in selectors.items():
        references.add((0, dc_table))
        references.add((1, ac_table))
    return set(components), references


def entropy_end(data, offset, restart_interval=None):
    expected_restart = 0
    while offset < len(data):
        if data[offset] != 0xFF:
            offset += 1
            continue
        require(offset + 1 < len(data), "truncated entropy marker")
        marker = data[offset + 1]
        if marker == 0x00:
            offset += 2
            continue
        if 0xD0 <= marker <= 0xD7:
            require(
                restart_interval is not None and restart_interval > 0,
                "RST marker without nonzero DRI",
            )
            require(
                marker == 0xD0 + expected_restart,
                "out-of-sequence RST marker",
            )
            expected_restart = (expected_restart + 1) % 8
            offset += 2
            continue
        require(marker != 0xFF, "noncanonical fill byte in entropy stream")
        return offset
    raise JPEGError("missing EOI")


def validate_jpeg(data):
    require(data.startswith(FIXED_JFIF), "missing fixed JFIF 1.02 prefix")
    offset = len(FIXED_JFIF)
    quantization_tables = set()
    huffman_tables = {}
    frame_marker = None
    frame_width = None
    frame_height = None
    frame_components = None
    scanned_components = set()
    restart_interval = None
    scan_count = 0

    while offset < len(data):
        require(offset + 2 <= len(data), "truncated marker")
        require(data[offset] == 0xFF, "expected marker prefix")
        marker = data[offset + 1]
        require(marker != 0xFF, "noncanonical marker fill byte")
        offset += 2

        if marker == 0xD9:
            require(offset == len(data), "trailing bytes after EOI")
            require(frame_marker is not None, "missing SOF")
            require(scan_count > 0, "missing SOS")
            require(scanned_components == set(frame_components), "unscanned frame component")
            require(set(frame_components.values()) <= quantization_tables, "undefined DQT reference")
            require(all(huffman_tables.values()), "unreferenced DHT definition")
            return {
                "width": frame_width,
                "height": frame_height,
                "components": len(frame_components),
                "frame_marker": frame_marker,
                "scan_count": scan_count,
            }

        require(marker in ALLOWED_SEGMENTS, f"forbidden marker FF{marker:02X}")
        require(offset + 2 <= len(data), "truncated segment length")
        length = int.from_bytes(data[offset : offset + 2], "big")
        require(length >= 2, "invalid segment length")
        end = offset + length
        require(end <= len(data), "segment overrun")
        payload = data[offset + 2 : end]
        offset = end

        if marker == 0xDB:
            parse_dqt(payload, quantization_tables)
        elif marker == 0xC4:
            parse_dht(payload, huffman_tables)
        elif marker == 0xDD:
            require(restart_interval is None, "duplicate DRI")
            require(len(payload) == 2, "invalid DRI length")
            restart_interval = int.from_bytes(payload, "big")
        elif marker in SOF_MARKERS:
            require(frame_marker is None, "duplicate SOF")
            (
                frame_marker,
                frame_width,
                frame_height,
                frame_components,
            ) = parse_sof(marker, payload)
        elif marker == 0xDA:
            components, references = parse_sos(
                payload,
                frame_marker,
                frame_components,
            )
            required_quantization = {
                frame_components[component] for component in components
            }
            require(
                required_quantization <= quantization_tables,
                "undefined DQT reference before scan",
            )
            require(references <= set(huffman_tables), "undefined DHT reference")
            for reference in references:
                huffman_tables[reference] = True
            require(
                scanned_components.isdisjoint(components),
                "sequential component scanned more than once",
            )
            scanned_components.update(components)
            scan_count += 1
            require(scan_count <= MAX_SCAN_COUNT, "too many SOS scans")
            offset = entropy_end(data, offset, restart_interval)

    raise JPEGError("missing EOI")


def main(paths):
    if not paths:
        raise SystemExit("usage: validate-jpeg-grammar.py image.jpg [...]")
    for argument in paths:
        path = pathlib.Path(argument)
        result = validate_jpeg(path.read_bytes())
        print(
            f"PASS {path.name} {result['width']}x{result['height']} "
            f"components={result['components']} SOF={result['frame_marker']:02X} "
            f"scans={result['scan_count']}"
        )


if __name__ == "__main__":
    main(sys.argv[1:])
