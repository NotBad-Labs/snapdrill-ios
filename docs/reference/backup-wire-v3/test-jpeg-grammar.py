#!/usr/bin/env python3

import contextlib
import hashlib
import importlib.util
import io
import json
import pathlib
import re


ROOT = pathlib.Path(__file__).resolve().parent
VALIDATOR_PATH = ROOT / "validate-jpeg-grammar.py"
SPEC = importlib.util.spec_from_file_location("jpeg_grammar", VALIDATOR_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot load JPEG grammar validator")
JPEG_GRAMMAR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(JPEG_GRAMMAR)
NORMALIZER_PATH = ROOT / "normalize-jpeg.py"
NORMALIZER_SPEC = importlib.util.spec_from_file_location(
    "jpeg_normalizer",
    NORMALIZER_PATH,
)
if NORMALIZER_SPEC is None or NORMALIZER_SPEC.loader is None:
    raise RuntimeError("cannot load JPEG normalizer")
JPEG_NORMALIZER = importlib.util.module_from_spec(NORMALIZER_SPEC)
NORMALIZER_SPEC.loader.exec_module(JPEG_NORMALIZER)
NEGATIVE_CASES = []
EXPECTED_NEGATIVE_MANIFEST_SHA256 = (
    "00ab96ea1e255c93ca09d28fc3aa34d4c1920c3de0bd2b5ea76d49d8a64d9ad0"
)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def segment_spans(data):
    offset = len(JPEG_GRAMMAR.FIXED_JFIF)
    spans = []
    while offset < len(data):
        start = offset
        require(data[offset] == 0xFF, "fixture marker prefix")
        marker = data[offset + 1]
        offset += 2
        if marker == 0xD9:
            spans.append((marker, start, offset))
            break

        length = int.from_bytes(data[offset : offset + 2], "big")
        offset += length
        if marker == 0xDA:
            offset = JPEG_GRAMMAR.entropy_end(data, offset)
        spans.append((marker, start, offset))
    return spans


def first_span(data, marker):
    return next(span for span in segment_spans(data) if span[0] == marker)


def marker_spans(data, marker):
    return [span for span in segment_spans(data) if span[0] == marker]


def insert_after_prefix(data, segment):
    prefix_length = len(JPEG_GRAMMAR.FIXED_JFIF)
    return data[:prefix_length] + segment + data[prefix_length:]


def insert_before_first_scan(data, segment):
    _, start, _ = first_span(data, 0xDA)
    return data[:start] + segment + data[start:]


def mutate_marker_payload(data, marker, payload_offset, value, occurrence=0):
    _, start, _ = marker_spans(data, marker)[occurrence]
    result = bytearray(data)
    result[start + 4 + payload_offset] = value
    return bytes(result)


def duplicate_segment(data, marker):
    _, start, end = first_span(data, marker)
    return data[:end] + data[start:end] + data[end:]


def remove_segment(data, marker):
    _, start, end = first_span(data, marker)
    return data[:start] + data[end:]


def mutate_segment_length(data):
    _, start, _ = first_span(data, 0xDB)
    result = bytearray(data)
    result[start + 2 : start + 4] = b"\x00\x01"
    return bytes(result)


def mutate_undefined_huffman_reference(data):
    _, start, _ = first_span(data, 0xDA)
    result = bytearray(data)
    result[start + 6] = 0x33
    return bytes(result)


def mutate_zero_quantization(data):
    _, start, _ = first_span(data, 0xDB)
    result = bytearray(data)
    result[start + 5] = 0
    return bytes(result)


def move_quantization_after_scan(data):
    _, dqt_start, dqt_end = first_span(data, 0xDB)
    without_dqt = data[:dqt_start] + data[dqt_end:]
    return without_dqt[:-2] + data[dqt_start:dqt_end] + without_dqt[-2:]


def mutate_oversubscribed_huffman(data):
    _, start, _ = first_span(data, 0xC4)
    result = bytearray(data)
    result[start + 5] = 3
    return bytes(result)


def mutate_empty_huffman(data):
    _, start, _ = first_span(data, 0xC4)
    result = bytearray(data)
    result[start + 5 : start + 21] = bytes(16)
    return bytes(result)


def mutate_duplicate_huffman_symbol(data):
    _, start, _ = first_span(data, 0xC4)
    symbol_start = start + 4 + 17
    result = bytearray(data)
    result[symbol_start + 1] = result[symbol_start]
    return bytes(result)


def mutate_invalid_ac_huffman_symbol(data):
    _, start, _ = next(
        span
        for span in segment_spans(data)
        if span[0] == 0xC4 and data[span[1] + 4] >> 4 == 1
    )
    result = bytearray(data)
    result[start + 4 + 17] = 0x0B
    return bytes(result)


def duplicate_dht_in_one_segment(data):
    _, start, end = first_span(data, 0xC4)
    payload = data[start + 4 : end]
    replacement = (
        b"\xFF\xC4"
        + (2 + 2 * len(payload)).to_bytes(2, "big")
        + payload
        + payload
    )
    return data[:start] + replacement + data[end:]


def replace_unreferenced_dht(data):
    _, start, end = first_span(data, 0xC4)
    return data[:end] + data[start:end] + data[end:]


def append_unreferenced_dht(data):
    definition = (
        b"\xFF\xC4\x00\x14\x02"
        + b"\x01"
        + b"\x00" * 15
        + b"\x00"
    )
    return data[:-2] + definition + data[-2:]


def duplicate_sequential_scan(data):
    _, start, end = first_span(data, 0xDA)
    return data[:-2] + data[start:end] + data[-2:]


def replace_marker(data, original, replacement):
    _, start, _ = first_span(data, original)
    result = bytearray(data)
    result[start + 1] = replacement
    return bytes(result)


def mutate_sequential_spectral_start(data):
    _, start, _ = first_span(data, 0xDA)
    component_count = data[start + 4]
    result = bytearray(data)
    result[start + 4 + 1 + 2 * component_count] = 1
    return bytes(result)


def insert_entropy_marker(data, marker):
    return data[:-2] + bytes([0xFF, marker]) + data[-2:]


def insert_dri(data, interval):
    segment = b"\xFF\xDD\x00\x04" + interval.to_bytes(2, "big")
    return insert_before_first_scan(data, segment)


def expect_reject(name, data, message_fragment):
    try:
        JPEG_GRAMMAR.validate_jpeg(data)
    except JPEG_GRAMMAR.JPEGError as error:
        require(
            message_fragment in str(error),
            f"{name}: expected {message_fragment!r}, got {str(error)!r}",
        )
        case_suffix = re.sub(r"[^A-Z0-9]+", "-", name.upper()).strip("-")
        NEGATIVE_CASES.append(
            {
                "case_id": f"V3-N-JPEG-{case_suffix}",
                "target_rule": f"raw-jpeg-grammar:{message_fragment}",
                "reference_outcome": f"rejected:jpeg:grammar:{error}",
                "byte_count": len(data),
                "sha256": hashlib.sha256(data).hexdigest(),
            }
        )
        print(f"PASS reject {name}: {error}")
        return
    raise AssertionError(f"{name}: validator accepted hostile input")


def main():
    NEGATIVE_CASES.clear()
    rgb = (ROOT / "canonical-rgb-sof0-2x2.jpg").read_bytes()
    gray = (ROOT / "canonical-gray-sof0-2x2.jpg").read_bytes()

    expected = [
        (rgb, 0xC0, 3, 1),
        (gray, 0xC0, 1, 1),
    ]
    for data, marker, components, scans in expected:
        result = JPEG_GRAMMAR.validate_jpeg(data)
        require(result["frame_marker"] == marker, "positive SOF marker")
        require(result["components"] == components, "positive component count")
        require(result["scan_count"] == scans, "positive scan count")
    print("PASS two canonical JPEG positives")

    metadata_segments = b"".join(
        bytes([0xFF, marker, 0x00, 0x02])
        for marker in range(0xE0, 0xF0)
    ) + b"\xFF\xFE\x00\x02"
    metadata_rich = insert_after_prefix(rgb, metadata_segments)
    require(
        JPEG_NORMALIZER.normalize_jpeg(metadata_rich) == rgb,
        "normalizer metadata stripping",
    )
    print("PASS normalizer strips APP0...APP15 and COM byte-exactly")

    for app_marker in range(0xE0, 0xF0):
        expect_reject(
            f"APP{app_marker - 0xE0}",
            insert_after_prefix(
                rgb,
                bytes([0xFF, app_marker, 0x00, 0x02]),
            ),
            f"forbidden marker FF{app_marker:02X}",
        )
    expect_reject(
        "COM",
        insert_after_prefix(rgb, b"\xFF\xFE\x00\x02"),
        "forbidden marker FFFE",
    )
    expect_reject("trailer", rgb + b"\x00", "trailing bytes after EOI")
    expect_reject("missing EOI", rgb[:-2], "missing EOI")
    expect_reject(
        "truncated entropy marker",
        rgb[:-2] + b"\xFF",
        "truncated entropy marker",
    )
    expect_reject(
        "entropy marker fill",
        insert_entropy_marker(rgb, 0xFF),
        "noncanonical fill byte in entropy stream",
    )
    expect_reject(
        "RST without DRI",
        insert_entropy_marker(rgb, 0xD0),
        "RST marker without nonzero DRI",
    )
    expect_reject(
        "RST after zero DRI",
        insert_entropy_marker(insert_dri(rgb, 0), 0xD0),
        "RST marker without nonzero DRI",
    )
    expect_reject(
        "RST sequence does not start at zero",
        insert_entropy_marker(insert_dri(rgb, 1), 0xD1),
        "out-of-sequence RST marker",
    )
    expect_reject(
        "invalid DRI length",
        insert_before_first_scan(rgb, b"\xFF\xDD\x00\x03\x01"),
        "invalid DRI length",
    )
    expect_reject(
        "duplicate DRI",
        insert_before_first_scan(
            rgb,
            b"\xFF\xDD\x00\x04\x00\x01\xFF\xDD\x00\x04\x00\x01",
        ),
        "duplicate DRI",
    )
    expect_reject("bad segment length", mutate_segment_length(rgb), "invalid segment length")
    expect_reject(
        "zero quantization coefficient",
        mutate_zero_quantization(rgb),
        "zero DQT coefficient",
    )
    expect_reject(
        "DQT first defined after scan",
        move_quantization_after_scan(rgb),
        "undefined DQT reference before scan",
    )
    expect_reject(
        "invalid DQT precision",
        mutate_marker_payload(rgb, 0xDB, 0, 0x20),
        "invalid DQT precision",
    )
    expect_reject(
        "invalid DQT identifier",
        mutate_marker_payload(rgb, 0xDB, 0, 0x04),
        "invalid DQT identifier",
    )
    expect_reject(
        "duplicate DQT",
        duplicate_segment(rgb, 0xDB),
        "duplicate DQT definition",
    )
    expect_reject(
        "oversubscribed Huffman tree",
        mutate_oversubscribed_huffman(rgb),
        "oversubscribed DHT",
    )
    expect_reject(
        "invalid DHT class",
        mutate_marker_payload(rgb, 0xC4, 0, 0x20),
        "invalid DHT class",
    )
    expect_reject(
        "invalid DHT identifier",
        mutate_marker_payload(rgb, 0xC4, 0, 0x04),
        "invalid DHT identifier",
    )
    expect_reject(
        "empty DHT symbol set",
        mutate_empty_huffman(rgb),
        "empty DHT symbol set",
    )
    expect_reject(
        "duplicate DHT symbol",
        mutate_duplicate_huffman_symbol(rgb),
        "duplicate DHT symbol",
    )
    expect_reject(
        "invalid DC Huffman symbol",
        mutate_marker_payload(rgb, 0xC4, 17, 12),
        "invalid DC Huffman symbol",
    )
    expect_reject(
        "invalid AC Huffman symbol",
        mutate_invalid_ac_huffman_symbol(rgb),
        "invalid AC Huffman symbol",
    )
    expect_reject(
        "undefined Huffman table",
        mutate_undefined_huffman_reference(rgb),
        "undefined DHT reference",
    )
    expect_reject(
        "same-segment DHT duplicate",
        duplicate_dht_in_one_segment(rgb),
        "duplicate DHT definition in one segment",
    )
    expect_reject(
        "unreferenced DHT replacement",
        replace_unreferenced_dht(rgb),
        "unreferenced DHT definition replaced",
    )
    expect_reject(
        "unreferenced final DHT",
        append_unreferenced_dht(rgb),
        "unreferenced DHT definition",
    )
    expect_reject(
        "SOF precision",
        mutate_marker_payload(rgb, 0xC0, 0, 12),
        "SOF precision is not 8-bit",
    )
    expect_reject(
        "SOF width plus one",
        mutate_marker_payload(
            mutate_marker_payload(rgb, 0xC0, 3, 0x07),
            0xC0,
            4,
            0xD1,
        ),
        "SOF dimensions out of range",
    )
    expect_reject(
        "SOF height plus one",
        mutate_marker_payload(
            mutate_marker_payload(rgb, 0xC0, 1, 0x07),
            0xC0,
            2,
            0xD1,
        ),
        "SOF dimensions out of range",
    )
    expect_reject(
        "SOF component count",
        mutate_marker_payload(rgb, 0xC0, 5, 2),
        "SOF component count",
    )
    expect_reject(
        "SOF component order",
        mutate_marker_payload(rgb, 0xC0, 12, 4),
        "noncanonical SOF component IDs/order",
    )
    expect_reject(
        "SOF sampling factor",
        mutate_marker_payload(rgb, 0xC0, 7, 0x01),
        "invalid sampling factor",
    )
    expect_reject(
        "SOF DQT identifier",
        mutate_marker_payload(rgb, 0xC0, 8, 4),
        "invalid SOF DQT reference",
    )
    expect_reject(
        "duplicate SOF",
        duplicate_segment(rgb, 0xC0),
        "duplicate SOF",
    )
    expect_reject(
        "SOF1 frame",
        replace_marker(rgb, 0xC0, 0xC1),
        "forbidden marker FFC1",
    )
    expect_reject(
        "SOF2 frame",
        replace_marker(rgb, 0xC0, 0xC2),
        "forbidden marker FFC2",
    )
    expect_reject(
        "missing SOF",
        remove_segment(rgb, 0xC0),
        "SOS precedes SOF",
    )
    expect_reject(
        "missing SOS",
        remove_segment(rgb, 0xDA),
        "missing SOS",
    )
    expect_reject(
        "unknown SOS component",
        mutate_marker_payload(rgb, 0xDA, 1, 4),
        "unknown SOS component",
    )
    expect_reject(
        "duplicate SOS component",
        mutate_marker_payload(rgb, 0xDA, 3, 1),
        "duplicate SOS component",
    )
    expect_reject(
        "sequential spectral parameters",
        mutate_sequential_spectral_start(rgb),
        "invalid sequential SOS parameters",
    )
    expect_reject(
        "duplicate sequential component scan",
        duplicate_sequential_scan(rgb),
        "sequential component scanned more than once",
    )
    semantic_manifest = [
        {
            key: value
            for key, value in case.items()
            if key not in {"byte_count", "sha256"}
        }
        for case in sorted(NEGATIVE_CASES, key=lambda item: item["case_id"])
    ]
    manifest_bytes = json.dumps(
        semantic_manifest,
        separators=(",", ":"),
        sort_keys=True,
    ).encode()
    observed = hashlib.sha256(manifest_bytes).hexdigest()
    require(
        observed == EXPECTED_NEGATIVE_MANIFEST_SHA256,
        "JPEG grammar negative manifest changed: "
        f"expected {EXPECTED_NEGATIVE_MANIFEST_SHA256}, got {observed}",
    )
    print(
        f"PASS JPEG grammar negative manifest cases={len(NEGATIVE_CASES)} "
        f"sha256={observed}"
    )


def build_case_manifest():
    with contextlib.redirect_stdout(io.StringIO()):
        main()
    return sorted(NEGATIVE_CASES, key=lambda case: case["case_id"])


if __name__ == "__main__":
    main()
