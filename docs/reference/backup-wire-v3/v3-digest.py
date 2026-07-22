#!/usr/bin/env python3

import hashlib
import math
import pathlib
import shutil
import sqlite3
import struct
import tempfile


ROOT = pathlib.Path(__file__).resolve().parent
DOMAIN = bytes.fromhex("536e61704472696c6c204261636b757020763300")
EXPECTED_FULL_ROOT = (
    "1b9a3235235ffa39f71c7bd4d11a592ae7692ef468fecd59333ca3fc62cb872f"
)


def frame(type_byte, payload=b""):
    return bytes([type_byte]) + len(payload).to_bytes(8, "big") + payload


def null_frame():
    return frame(0x00)


def bool_frame(value):
    if type(value) is not int or value not in (0, 1):
        raise ValueError("invalid canonical bool")
    return frame(0x01, bytes([value]))


def int_frame(value):
    if type(value) is not int:
        raise ValueError("invalid canonical Int64")
    return frame(0x02, value.to_bytes(8, "big", signed=True))


def double_frame(value):
    if type(value) is not float or not math.isfinite(value):
        raise ValueError("invalid canonical Double")
    normalized = 0.0 if value == 0.0 else value
    return frame(0x03, struct.pack(">d", normalized))


def text_frame(value):
    if value is None:
        return null_frame()
    if type(value) is not str:
        raise ValueError("invalid canonical UTF-8")
    return frame(0x04, value.encode("utf-8"))


def uuid_frame(value):
    if type(value) is not bytes or len(value) != 16:
        raise ValueError("invalid canonical UUID")
    return frame(0x05, value)


def sha_frame(value):
    if type(value) is not bytes or len(value) != 32:
        raise ValueError("invalid canonical SHA-256")
    return frame(0x06, value)


def role_frame(value):
    if type(value) is not int or value not in (0, 1):
        raise ValueError("invalid canonical image role")
    return frame(0x07, bytes([value]))


def digest(tag, fields):
    return hashlib.sha256(DOMAIN + bytes([tag]) + b"".join(fields)).digest()


def dimension_digest(row):
    return digest(
        0x11,
        [
            uuid_frame(row["id"]),
            text_frame(row["name"]),
            bool_frame(row["is_multi_value"]),
            bool_frame(row["is_built_in"]),
            text_frame(row["system_key"]),
            int_frame(row["sort_order"]),
            text_frame(row["icon"]),
        ],
    )


def value_digest(row):
    return digest(
        0x12,
        [
            uuid_frame(row["id"]),
            uuid_frame(row["dimension_id"]),
            text_frame(row["name"]),
            text_frame(row["icon"]),
            text_frame(row["color_hex"]),
            int_frame(row["sort_order"]),
            int_frame(row["created_at_ms"]),
        ],
    )


def item_digest(row):
    return digest(
        0x13,
        [
            uuid_frame(row["id"]),
            text_frame(row["content"]),
            int_frame(row["created_at_ms"]),
            null_frame()
            if row["last_reviewed_at_ms"] is None
            else int_frame(row["last_reviewed_at_ms"]),
            null_frame()
            if row["next_review_at_ms"] is None
            else int_frame(row["next_review_at_ms"]),
            double_frame(row["ease_factor"]),
            int_frame(row["interval_days"]),
            int_frame(row["repetitions"]),
            text_frame(row["answer_text"]),
        ],
    )


def join_digest(row):
    return digest(
        0x14,
        [
            uuid_frame(row["item_id"]),
            uuid_frame(row["value_id"]),
        ],
    )


def image_digest(row, content_sha256):
    return digest(
        0x15,
        [
            uuid_frame(row["item_id"]),
            role_frame(row["role"]),
            text_frame(row["media_type"]),
            int_frame(row["pixel_width"]),
            int_frame(row["pixel_height"]),
            int_frame(row["byte_count"]),
            sha_frame(content_sha256),
        ],
    )


def root_digest(root, entries):
    fields = [
        int_frame(root["singleton"]),
        text_frame(root["artifact_kind"]),
        int_frame(root["wire_version"]),
        int_frame(root["created_at_ms"]),
        text_frame(root["writer_marketing_version"]),
        text_frame(root["writer_build"]),
        text_frame(root["digest_algorithm"]),
        int_frame(root["item_count"]),
        int_frame(root["dimension_count"]),
        int_frame(root["value_count"]),
        int_frame(root["item_value_count"]),
        int_frame(root["image_count"]),
        int_frame(root["image_byte_count"]),
    ]
    framed_entries = [
        bytes([tag]) + sha_frame(record_digest)
        for tag, record_digest in entries
    ]
    return hashlib.sha256(
        DOMAIN + bytes([0x10]) + b"".join(fields) + b"".join(framed_entries)
    ).digest()


def selected_rows(database, table, order):
    return database.execute(
        f'SELECT * FROM "{table}" ORDER BY {order}'
    ).fetchall()


def recompute_database(database_path):
    database = sqlite3.connect(database_path)
    database.row_factory = sqlite3.Row
    try:
        database.execute("PRAGMA ignore_check_constraints=ON")
        entries = []

        dimensions = selected_rows(database, "category_dimension", "id")
        for row in dimensions:
            record = dimension_digest(row)
            database.execute(
                "UPDATE category_dimension SET record_sha256=? WHERE id=?",
                (record, row["id"]),
            )
            entries.append((0x11, record))

        values = selected_rows(database, "category_value", "id")
        for row in values:
            record = value_digest(row)
            database.execute(
                "UPDATE category_value SET record_sha256=? WHERE id=?",
                (record, row["id"]),
            )
            entries.append((0x12, record))

        items = selected_rows(database, "library_item", "id")
        for row in items:
            record = item_digest(row)
            database.execute(
                "UPDATE library_item SET record_sha256=? WHERE id=?",
                (record, row["id"]),
            )
            entries.append((0x13, record))

        joins = selected_rows(
            database,
            "item_category_value",
            "item_id, value_id",
        )
        for row in joins:
            record = join_digest(row)
            database.execute(
                """
                UPDATE item_category_value
                SET record_sha256=?
                WHERE item_id=? AND value_id=?
                """,
                (record, row["item_id"], row["value_id"]),
            )
            entries.append((0x14, record))

        images = selected_rows(database, "item_image", "item_id, role")
        for row in images:
            content = hashlib.sha256(row["jpeg_bytes"]).digest()
            record = image_digest(row, content)
            database.execute(
                """
                UPDATE item_image
                SET content_sha256=?, record_sha256=?
                WHERE blob_id=?
                """,
                (content, record, row["blob_id"]),
            )
            entries.append((0x15, record))

        root = database.execute("SELECT * FROM backup_root").fetchone()
        inventory = root_digest(root, entries)
        database.execute(
            "UPDATE backup_root SET inventory_sha256=?",
            (inventory,),
        )
        database.commit()
        return inventory
    finally:
        database.close()


def main():
    source = ROOT / "iOS-26.5-full-v3.sqlite"
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-digest-") as directory:
        target = pathlib.Path(directory) / "fixture.sqlite"
        shutil.copyfile(source, target)
        inventory = recompute_database(target)
        if inventory.hex() != EXPECTED_FULL_ROOT:
            raise AssertionError("full fixture inventory known answer changed")
    print(f"PASS generic v3 digest oracle inventory={inventory.hex()}")


if __name__ == "__main__":
    main()
