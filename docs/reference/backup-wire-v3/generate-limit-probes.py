#!/usr/bin/env python3

import hashlib
import json
import pathlib
import sqlite3
import tempfile


ROOT = pathlib.Path(__file__).resolve().parent
TEXT_LIMIT = 1_048_576
NAME_LIMIT = 1_024
ICON_LIMIT = 256
PIXEL_LIMIT = 2_000
IMAGE_BYTE_LIMIT = 52_428_800
CHUNK_SIZE = 256 * 1_024
CHUNK_COUNT = IMAGE_BYTE_LIMIT // CHUNK_SIZE
PROBE_CHUNK = hashlib.shake_256(
    b"SnapDrill Backup v3 image-byte limit probe"
).digest(CHUNK_SIZE)
EXPECTED_PROBE_CHUNK_SHA256 = (
    "645c49f73bf75d185ac5c74e14b82ca34bfb4aff56d2d46ef6901a8b48678aa6"
)
EXPECTED_EXACT_STREAM_SHA256 = (
    "409538bf1585784af5e2a4f5254982bff12fba93530f3f9b502068c0ab69cb99"
)
EXPECTED_OVER_STREAM_SHA256 = (
    "41a6fb447d5a58fbbc00f4ed1e7585a290712ab3232c4610dd1960c785b5ffc7"
)

TEXT_EXACT = b"a" * (TEXT_LIMIT - 3) + "中".encode("utf-8")
TEXT_OVER = TEXT_EXACT + b"a"
NAME_EXACT = b"a" * (NAME_LIMIT - 3) + "中".encode("utf-8")
NAME_OVER = NAME_EXACT + b"a"
ICON_EXACT = b"a" * ICON_LIMIT
ICON_OVER = ICON_EXACT + b"a"

BYTE_VECTORS = {
    "V3-P-LIMIT-CONTENT-EXACT": (
        TEXT_EXACT,
        TEXT_LIMIT,
        True,
        "77373de0a8942cc44b0c8cf959820008beb977cffddd7f09deddb41ed703038d",
    ),
    "V3-N-LIMIT-CONTENT-PLUS1": (
        TEXT_OVER,
        TEXT_LIMIT,
        False,
        "da991a21db760717ff60f8b05561b8c3bb043c3c38156deea9e564e7965f3ec1",
    ),
    "V3-P-LIMIT-ANSWER-EXACT": (
        TEXT_EXACT,
        TEXT_LIMIT,
        True,
        "77373de0a8942cc44b0c8cf959820008beb977cffddd7f09deddb41ed703038d",
    ),
    "V3-N-LIMIT-ANSWER-PLUS1": (
        TEXT_OVER,
        TEXT_LIMIT,
        False,
        "da991a21db760717ff60f8b05561b8c3bb043c3c38156deea9e564e7965f3ec1",
    ),
    "V3-P-LIMIT-DIMENSION-NAME-EXACT": (
        NAME_EXACT,
        NAME_LIMIT,
        True,
        "374c675abcaad04d7f56bdffdd5b3201b71c10262ccf68d692a6c38dbf5c6675",
    ),
    "V3-N-LIMIT-DIMENSION-NAME-PLUS1": (
        NAME_OVER,
        NAME_LIMIT,
        False,
        "b0ff76ae1ff71bef26e872a3cb6b517679d9df639b2cd1980ce3c87956b5a1ca",
    ),
    "V3-P-LIMIT-VALUE-NAME-EXACT": (
        NAME_EXACT,
        NAME_LIMIT,
        True,
        "374c675abcaad04d7f56bdffdd5b3201b71c10262ccf68d692a6c38dbf5c6675",
    ),
    "V3-N-LIMIT-VALUE-NAME-PLUS1": (
        NAME_OVER,
        NAME_LIMIT,
        False,
        "b0ff76ae1ff71bef26e872a3cb6b517679d9df639b2cd1980ce3c87956b5a1ca",
    ),
    "V3-P-LIMIT-DIMENSION-ICON-EXACT": (
        ICON_EXACT,
        ICON_LIMIT,
        True,
        "02d7160d77e18c6447be80c2e355c7ed4388545271702c50253b0914c65ce5fe",
    ),
    "V3-N-LIMIT-DIMENSION-ICON-PLUS1": (
        ICON_OVER,
        ICON_LIMIT,
        False,
        "e8d95cc2b4bc198c54b40bd214df958afb65f5e73d2c2eafe0593cf5c635c1f0",
    ),
    "V3-P-LIMIT-VALUE-ICON-EXACT": (
        ICON_EXACT,
        ICON_LIMIT,
        True,
        "02d7160d77e18c6447be80c2e355c7ed4388545271702c50253b0914c65ce5fe",
    ),
    "V3-N-LIMIT-VALUE-ICON-PLUS1": (
        ICON_OVER,
        ICON_LIMIT,
        False,
        "e8d95cc2b4bc198c54b40bd214df958afb65f5e73d2c2eafe0593cf5c635c1f0",
    ),
}


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(CHUNK_SIZE), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_stream_probes(root):
    exact = root / "image-byte-limit-exact.bin"
    over = root / "image-byte-limit-plus1.bin"
    for path, trailing in ((exact, b""), (over, b"\xA5")):
        with path.open("xb") as destination:
            for _ in range(CHUNK_COUNT):
                destination.write(PROBE_CHUNK)
            destination.write(trailing)

    require(exact.stat().st_size == IMAGE_BYTE_LIMIT, "exact stream size")
    require(over.stat().st_size == IMAGE_BYTE_LIMIT + 1, "plus-one stream size")
    require(sha256(exact) == EXPECTED_EXACT_STREAM_SHA256, "exact stream SHA-256")
    require(sha256(over) == EXPECTED_OVER_STREAM_SHA256, "plus-one stream SHA-256")
    return exact, over


def image_size_stage(path):
    byte_count = 0
    with path.open("rb") as source:
        while True:
            chunk = source.read(CHUNK_SIZE)
            if not chunk:
                return True, byte_count
            if len(chunk) > IMAGE_BYTE_LIMIT - byte_count:
                return False, byte_count + len(chunk)
            byte_count += len(chunk)


def validate_byte_vectors():
    output = []
    for case_id, (payload, limit, accepted, expected_sha256) in BYTE_VECTORS.items():
        payload.decode("utf-8", errors="strict")
        actual_accepted = len(payload) <= limit
        require(actual_accepted == accepted, f"{case_id} decision")
        digest = hashlib.sha256(payload).hexdigest()
        require(digest == expected_sha256, f"{case_id} SHA-256")
        output.append(
            {
                "case_id": case_id,
                "byte_count": len(payload),
                "accepted": accepted,
                "sha256": digest,
            }
        )
    return output


def validate_dimension_vectors():
    vectors = [
        ("V3-P-LIMIT-WIDTH-EXACT", PIXEL_LIMIT, 1, True),
        ("V3-N-LIMIT-WIDTH-PLUS1", PIXEL_LIMIT + 1, 1, False),
        ("V3-P-LIMIT-HEIGHT-EXACT", 1, PIXEL_LIMIT, True),
        ("V3-N-LIMIT-HEIGHT-PLUS1", 1, PIXEL_LIMIT + 1, False),
    ]
    output = []
    for case_id, width, height, accepted in vectors:
        actual_accepted = (
            1 <= width <= PIXEL_LIMIT and 1 <= height <= PIXEL_LIMIT
        )
        require(actual_accepted == accepted, f"{case_id} decision")
        output.append(
            {
                "case_id": case_id,
                "width": width,
                "height": height,
                "accepted": accepted,
            }
        )
    return output


def validate_sqlite_image_byte_check(root):
    database_path = root / "image-byte-limit.sqlite"
    database = sqlite3.connect(database_path)
    try:
        database.execute("PRAGMA foreign_keys=ON")
        database.executescript((ROOT / "schema.sql").read_text(encoding="utf-8"))
        database.execute(
            """
            INSERT INTO library_item(
                id, content, created_at_ms, last_reviewed_at_ms,
                next_review_at_ms, ease_factor, interval_days,
                repetitions, answer_text, record_sha256
            ) VALUES(?, 'probe', 0, NULL, NULL, 0.0, 0, 0, NULL, ?)
            """,
            (bytes(16), bytes(32)),
        )
        database.execute(
            """
            INSERT INTO item_image(
                blob_id, item_id, role, media_type, pixel_width, pixel_height,
                byte_count, content_sha256, record_sha256, jpeg_bytes
            ) VALUES(1, ?, 0, 'image/jpeg', 1, 1, ?, ?, ?, zeroblob(?))
            """,
            (
                bytes(16),
                IMAGE_BYTE_LIMIT,
                bytes(32),
                bytes(32),
                IMAGE_BYTE_LIMIT,
            ),
        )
        database.commit()
        stored = database.execute(
            "SELECT byte_count, length(jpeg_bytes) FROM item_image"
        ).fetchone()
        require(
            stored == (IMAGE_BYTE_LIMIT, IMAGE_BYTE_LIMIT),
            "SQLite exact image-byte boundary",
        )

        try:
            database.execute(
                """
                INSERT INTO item_image(
                    blob_id, item_id, role, media_type, pixel_width, pixel_height,
                    byte_count, content_sha256, record_sha256, jpeg_bytes
                ) VALUES(2, ?, 1, 'image/jpeg', 1, 1, ?, ?, ?, zeroblob(?))
                """,
                (
                    bytes(16),
                    IMAGE_BYTE_LIMIT + 1,
                    bytes(32),
                    bytes(32),
                    IMAGE_BYTE_LIMIT + 1,
                ),
            )
        except sqlite3.IntegrityError:
            database.rollback()
        else:
            raise AssertionError("SQLite accepted image-byte plus-one")
    finally:
        database.close()


def main():
    require(
        hashlib.sha256(PROBE_CHUNK).hexdigest()
        == EXPECTED_PROBE_CHUNK_SHA256,
        "probe chunk SHA-256",
    )
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-limits-") as directory:
        root = pathlib.Path(directory)
        exact, over = write_stream_probes(root)
        require(
            image_size_stage(exact) == (True, IMAGE_BYTE_LIMIT),
            "exact stream size stage",
        )
        require(
            image_size_stage(over) == (False, IMAGE_BYTE_LIMIT + 1),
            "plus-one stream size stage",
        )
        validate_sqlite_image_byte_check(root)
        report = {
            "seed": "SnapDrill Backup v3 image-byte limit probe",
            "chunk_size": CHUNK_SIZE,
            "image_byte_limit": IMAGE_BYTE_LIMIT,
            "exact_stream_sha256": EXPECTED_EXACT_STREAM_SHA256,
            "plus1_stream_sha256": EXPECTED_OVER_STREAM_SHA256,
            "byte_vectors": validate_byte_vectors(),
            "dimension_vectors": validate_dimension_vectors(),
        }
        print(json.dumps(report, ensure_ascii=True, sort_keys=True))
    print("PASS deterministic limit probes")


if __name__ == "__main__":
    main()
