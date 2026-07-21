#!/usr/bin/env python3

import importlib.util
import pathlib
import sys


ROOT = pathlib.Path(__file__).resolve().parent
VALIDATOR_PATH = ROOT / "validate-jpeg-grammar.py"
SPEC = importlib.util.spec_from_file_location("jpeg_grammar", VALIDATOR_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot load JPEG grammar validator")
JPEG_GRAMMAR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(JPEG_GRAMMAR)


class NormalizationError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise NormalizationError(message)


def normalize_jpeg(data):
    require(data.startswith(b"\xFF\xD8"), "missing SOI")
    output = bytearray(JPEG_GRAMMAR.FIXED_JFIF)
    offset = 2
    saw_eoi = False

    while offset < len(data):
        marker_start = offset
        require(offset + 2 <= len(data), "truncated marker")
        require(data[offset] == 0xFF, "expected marker prefix")
        marker = data[offset + 1]
        require(marker != 0xFF, "noncanonical marker fill byte")
        offset += 2

        if marker == 0xD9:
            require(offset == len(data), "trailing bytes after EOI")
            output.extend(b"\xFF\xD9")
            saw_eoi = True
            break
        require(
            marker not in {0x01, 0xD8} and not 0xD0 <= marker <= 0xD7,
            f"unexpected standalone marker FF{marker:02X}",
        )
        require(offset + 2 <= len(data), "truncated segment length")
        length = int.from_bytes(data[offset : offset + 2], "big")
        require(length >= 2, "invalid segment length")
        segment_end = offset + length
        require(segment_end <= len(data), "segment overrun")

        if not (0xE0 <= marker <= 0xEF or marker == 0xFE):
            output.extend(data[marker_start:segment_end])
        offset = segment_end

        if marker == 0xDA:
            entropy_start = offset
            while offset < len(data):
                if data[offset] != 0xFF:
                    offset += 1
                    continue
                require(offset + 1 < len(data), "truncated entropy marker")
                entropy_marker = data[offset + 1]
                if entropy_marker == 0x00 or 0xD0 <= entropy_marker <= 0xD7:
                    offset += 2
                    continue
                break
            output.extend(data[entropy_start:offset])

    require(saw_eoi, "missing EOI")
    normalized = bytes(output)
    JPEG_GRAMMAR.validate_jpeg(normalized)
    return normalized


def main(arguments):
    if len(arguments) != 2:
        raise SystemExit("usage: normalize-jpeg.py input.jpg output.jpg")
    source = pathlib.Path(arguments[0])
    destination = pathlib.Path(arguments[1])
    normalized = normalize_jpeg(source.read_bytes())
    destination.write_bytes(normalized)
    print(
        f"PASS normalized {source.name} -> {destination.name} "
        f"bytes={len(normalized)}"
    )


if __name__ == "__main__":
    main(sys.argv[1:])
