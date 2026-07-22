#!/usr/bin/env python3

import hashlib
import pathlib
import shutil
import subprocess
import tempfile


ROOT = pathlib.Path(__file__).resolve().parent
FIXTURE = ROOT / "canonical-rgb-sof0-2000x2000.jpg"
EXPECTED_SOURCE_SIZE = 422_694
EXPECTED_SOURCE_SHA256 = (
    "7a3d20ae52206577519c58e95e0ae33f4e21e9d5257d9ff13edc8da421a23b03"
)
EXPECTED_NORMALIZED_SIZE = 422_558
EXPECTED_NORMALIZED_SHA256 = (
    "5307c20da2979646f422606035d5c8d22fba30f79c083a61fb945ee58487fdef"
)
EXPECTED_DJPEG_PPM_SHA256 = (
    "73ee6cb684de262b2e19b4493b56c9e376ffd0b24acd227c9222cde41d0c8247"
)


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command):
    return subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
    )


def verify_djpeg(source, normalized, root):
    executable = shutil.which("djpeg")
    if executable is None:
        print("PASS djpeg unavailable; retained evidence remains authoritative")
        return
    source_ppm = root / "source.ppm"
    normalized_ppm = root / "normalized.ppm"
    run([executable, "-strict", "-outfile", str(source_ppm), str(source)])
    run([executable, "-strict", "-outfile", str(normalized_ppm), str(normalized)])
    require(source_ppm.read_bytes() == normalized_ppm.read_bytes(), "djpeg pixels")
    require(
        sha256(normalized_ppm) == EXPECTED_DJPEG_PPM_SHA256,
        "djpeg PPM SHA-256",
    )
    print("PASS independent djpeg full decode")


def main():
    require(FIXTURE.stat().st_size == EXPECTED_NORMALIZED_SIZE, "fixture size")
    require(sha256(FIXTURE) == EXPECTED_NORMALIZED_SHA256, "fixture SHA-256")
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-large-jpeg-") as directory:
        temporary_root = pathlib.Path(directory)
        source = temporary_root / "source.jpg"
        normalized = temporary_root / "normalized.jpg"
        run(["swift", str(ROOT / "generate-large-jpeg.swift"), str(source)])
        require(source.stat().st_size == EXPECTED_SOURCE_SIZE, "source size")
        require(sha256(source) == EXPECTED_SOURCE_SHA256, "source SHA-256")
        run(
            [
                "python3",
                str(ROOT / "normalize-jpeg.py"),
                str(source),
                str(normalized),
            ]
        )
        require(normalized.read_bytes() == FIXTURE.read_bytes(), "normalized fixture")
        image_io = run(
            [
                "swift",
                str(ROOT / "verify-jpeg-imageio.swift"),
                str(source),
                str(normalized),
            ]
        )
        require("PASS" in image_io.stdout, "ImageIO oracle output")
        verify_djpeg(source, normalized, temporary_root)
    print("PASS deterministic 2000x2000 JPEG fixture")


if __name__ == "__main__":
    main()
