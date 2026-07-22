#!/usr/bin/env python3

import argparse
import hashlib
import importlib.util
import math
import os
import pathlib
import re
import sqlite3
import stat
import struct
import sys
import urllib.parse


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
CANONICAL_SCHEMA_MANIFEST = (ROOT / "schema-manifest.txt").read_bytes()
DOMAIN = bytes.fromhex("536e61704472696c6c204261636b757020763300")
APPLICATION_ID = 707_275_168
USER_VERSION = 3
PAGE_SIZE = 4_096
TEXT_LIMIT = 1_048_576
NAME_LIMIT = 1_024
ICON_LIMIT = 256
IMAGE_BYTE_LIMIT = 52_428_800
DATE_LIMIT = 1_000_000_000_000_000
INT64_MAX = (1 << 63) - 1
SIDECAR_SUFFIXES = ("-wal", "-shm", "-journal")
REFERENCE_MAX_FILE_BYTES = 64 * 1_024 * 1_024
REFERENCE_MAX_ROWS_PER_TABLE = 10_000
ALLOWED_DBSTAT_NAMES = {
    "sqlite_schema",
    "backup_root",
    "category_dimension",
    "category_value",
    "library_item",
    "item_category_value",
    "item_image",
    "ux_category_dimension_name",
    "ux_category_dimension_system_key",
    "ux_category_value_dimension_name",
    "ux_item_image_item_role",
}
ALLOWED_DBSTAT_NAME_BYTES = {
    name.encode("utf-8") for name in ALLOWED_DBSTAT_NAMES
}
ALLOWED_DBSTAT_PAGE_TYPES = {b"internal", b"leaf", b"overflow"}

JPEG_SPEC = importlib.util.spec_from_file_location(
    "reference_jpeg_grammar",
    ROOT / "validate-jpeg-grammar.py",
)
if JPEG_SPEC is None or JPEG_SPEC.loader is None:
    raise RuntimeError("cannot load JPEG grammar validator")
JPEG_GRAMMAR = importlib.util.module_from_spec(JPEG_SPEC)
JPEG_SPEC.loader.exec_module(JPEG_GRAMMAR)

TABLE_COLUMNS = {
    "backup_root": [
        "singleton",
        "artifact_kind",
        "wire_version",
        "created_at_ms",
        "writer_marketing_version",
        "writer_build",
        "digest_algorithm",
        "item_count",
        "dimension_count",
        "value_count",
        "item_value_count",
        "image_count",
        "image_byte_count",
        "inventory_sha256",
    ],
    "category_dimension": [
        "id",
        "name",
        "is_multi_value",
        "is_built_in",
        "system_key",
        "sort_order",
        "icon",
        "record_sha256",
    ],
    "category_value": [
        "id",
        "dimension_id",
        "name",
        "icon",
        "color_hex",
        "sort_order",
        "created_at_ms",
        "record_sha256",
    ],
    "library_item": [
        "id",
        "content",
        "created_at_ms",
        "last_reviewed_at_ms",
        "next_review_at_ms",
        "ease_factor",
        "interval_days",
        "repetitions",
        "answer_text",
        "record_sha256",
    ],
    "item_category_value": [
        "item_id",
        "value_id",
        "record_sha256",
    ],
    "item_image": [
        "blob_id",
        "item_id",
        "role",
        "media_type",
        "pixel_width",
        "pixel_height",
        "byte_count",
        "content_sha256",
        "record_sha256",
        "jpeg_bytes",
    ],
}
REFERENCE_COUNT_SCAN = {
    table: (
        "NOT INDEXED"
        if table == "item_image"
        else f"INDEXED BY sqlite_autoindex_{table}_1"
    )
    for table in TABLE_COLUMNS
}

ALLOWED_TYPES = {
    "backup_root": {
        "singleton": {"integer"},
        "artifact_kind": {"text"},
        "wire_version": {"integer"},
        "created_at_ms": {"integer"},
        "writer_marketing_version": {"text"},
        "writer_build": {"text"},
        "digest_algorithm": {"text"},
        "item_count": {"integer"},
        "dimension_count": {"integer"},
        "value_count": {"integer"},
        "item_value_count": {"integer"},
        "image_count": {"integer"},
        "image_byte_count": {"integer"},
        "inventory_sha256": {"blob"},
    },
    "category_dimension": {
        "id": {"blob"},
        "name": {"text"},
        "is_multi_value": {"integer"},
        "is_built_in": {"integer"},
        "system_key": {"null", "text"},
        "sort_order": {"integer"},
        "icon": {"text"},
        "record_sha256": {"blob"},
    },
    "category_value": {
        "id": {"blob"},
        "dimension_id": {"blob"},
        "name": {"text"},
        "icon": {"text"},
        "color_hex": {"text"},
        "sort_order": {"integer"},
        "created_at_ms": {"integer"},
        "record_sha256": {"blob"},
    },
    "library_item": {
        "id": {"blob"},
        "content": {"null", "text"},
        "created_at_ms": {"integer"},
        "last_reviewed_at_ms": {"null", "integer"},
        "next_review_at_ms": {"null", "integer"},
        "ease_factor": {"real"},
        "interval_days": {"integer"},
        "repetitions": {"integer"},
        "answer_text": {"null", "text"},
        "record_sha256": {"blob"},
    },
    "item_category_value": {
        "item_id": {"blob"},
        "value_id": {"blob"},
        "record_sha256": {"blob"},
    },
    "item_image": {
        "blob_id": {"integer"},
        "item_id": {"blob"},
        "role": {"integer"},
        "media_type": {"text"},
        "pixel_width": {"integer"},
        "pixel_height": {"integer"},
        "byte_count": {"integer"},
        "content_sha256": {"blob"},
        "record_sha256": {"blob"},
        "jpeg_bytes": {"blob"},
    },
}

ORDERS = {
    "backup_root": "singleton",
    "category_dimension": "id",
    "category_value": "id",
    "library_item": "id",
    "item_category_value": "item_id, value_id",
    "item_image": "item_id, role",
}


class ValidationError(Exception):
    def __init__(self, code, stage, detail=""):
        super().__init__(code)
        self.code = code
        self.stage = stage
        self.detail = detail


def reject(code, stage, detail=""):
    raise ValidationError(code, stage, detail)


def uint32(data, offset):
    return struct.unpack(">I", data[offset : offset + 4])[0]


def lexical_exists(path):
    return os.path.lexists(path)


def node_identity(node):
    return (
        node.st_dev,
        node.st_ino,
        node.st_size,
        node.st_mtime_ns,
        node.st_ctime_ns,
    )


def validate_filesystem(path):
    try:
        node = path.lstat()
    except FileNotFoundError:
        reject("filesystem:missing", "filesystem")
    if not stat.S_ISREG(node.st_mode) or stat.S_ISLNK(node.st_mode):
        reject("filesystem:not-regular", "filesystem")
    if node.st_uid != os.getuid():
        reject("filesystem:owner", "filesystem")
    if node.st_nlink != 1:
        reject("filesystem:link-count", "filesystem")
    for suffix in SIDECAR_SUFFIXES:
        if lexical_exists(path.with_name(path.name + suffix)):
            reject(f"filesystem:sidecar:{suffix[1:]}", "filesystem")
    return node


def validate_construction_root(root):
    try:
        node = root.lstat()
    except FileNotFoundError:
        reject("filesystem:construction-root-missing", "filesystem")
    if not stat.S_ISDIR(node.st_mode) or stat.S_ISLNK(node.st_mode):
        reject("filesystem:construction-root-type", "filesystem")
    if node.st_uid != os.getuid():
        reject("filesystem:construction-root-owner", "filesystem")
    if stat.S_IMODE(node.st_mode) != 0o700:
        reject("filesystem:construction-root-mode", "filesystem")
    return node


def validate_quarantine_node(path, require_read_only=True):
    validate_construction_root(path.parent)
    node = validate_filesystem(path)
    if require_read_only and stat.S_IMODE(node.st_mode) & 0o222:
        reject("filesystem:writable-quarantine", "filesystem")
    return node


def validate_header(path):
    file_size = path.stat().st_size
    if file_size > REFERENCE_MAX_FILE_BYTES:
        reject("reference:file-size-limit", "reference")
    with path.open("rb", buffering=0) as source:
        data = source.read(100)
    if len(data) != 100:
        reject("header:minimum-header-length", "header")
    if data[:16] != b"SQLite format 3\0":
        reject("header:sqlite-magic", "header")
    encoded_page_size = struct.unpack(">H", data[16:18])[0]
    page_size = 65_536 if encoded_page_size == 1 else encoded_page_size
    checks = [
        (page_size == PAGE_SIZE, "page-size"),
        (data[18] == 1, "write-version"),
        (data[19] == 1, "read-version"),
        (data[20] == 0, "reserved-bytes"),
        (data[21:24] == bytes((64, 32, 32)), "payload-fractions"),
        (uint32(data, 32) == 0, "freelist-trunk"),
        (uint32(data, 36) == 0, "freelist-count"),
        (uint32(data, 44) == 4, "schema-format"),
        (uint32(data, 52) == 0, "auto-vacuum-root"),
        (uint32(data, 56) == 1, "utf8-encoding"),
        (uint32(data, 60) == USER_VERSION, "user-version"),
        (uint32(data, 64) == 0, "incremental-vacuum"),
        (uint32(data, 68) == APPLICATION_ID, "application-id"),
        (data[72:92] == bytes(20), "header-expansion"),
    ]
    for condition, code in checks:
        if not condition:
            reject(f"header:{code}", "header")
    page_count = uint32(data, 28)
    if page_count == 0:
        reject("header:positive-page-count", "header")
    if file_size != page_count * PAGE_SIZE:
        reject("header:page-count-file-size", "header")
    if data[24:28] != data[92:96]:
        reject("header:change-counter-version-valid-for", "header")


def schema_manifest(database):
    expected_lines = CANONICAL_SCHEMA_MANIFEST.splitlines(keepends=True)
    cursor = database.execute(
        """
        SELECT type, name, tbl_name, hex(sql)
        FROM sqlite_schema
        ORDER BY type, name
        """
    )
    observed_lines = []
    for index, row in enumerate(cursor):
        if index >= len(expected_lines):
            reject("schema:manifest", "schema", "extra-row")
        line = b"|".join(
            value if isinstance(value, bytes) else str(value).encode("utf-8")
            for value in row
        ) + b"\n"
        if line != expected_lines[index]:
            reject("schema:manifest", "schema", f"row-{index}")
        observed_lines.append(line)
    if len(observed_lines) != len(expected_lines):
        reject("schema:manifest", "schema", "missing-row")
    return b"".join(observed_lines)


def validate_schema(database):
    try:
        schema_manifest(database)
    except sqlite3.DatabaseError as error:
        reject("schema:unreadable", "schema", str(error))


def validate_reference_row_counts(database):
    for table in TABLE_COLUMNS:
        scan = REFERENCE_COUNT_SCAN[table]
        cursor = database.execute(
            f'SELECT 1 FROM "{table}" {scan} '
            f"LIMIT {REFERENCE_MAX_ROWS_PER_TABLE + 1}"
        )
        for count, _ in enumerate(cursor, start=1):
            if count > REFERENCE_MAX_ROWS_PER_TABLE:
                reject(f"reference:row-limit:{table}", "reference")


def validate_physical_closure(database, page_count):
    seen = bytearray((page_count + 7) // 8)
    observed_count = 0
    try:
        cursor = database.execute(
            """
            SELECT name, pageno, pagetype, pgoffset, pgsize
            FROM dbstat('main')
            """
        )
        for name, pageno, page_type, page_offset, page_size in cursor:
            name_bytes = (
                name if isinstance(name, bytes) else str(name).encode("utf-8")
            )
            page_type_bytes = (
                page_type
                if isinstance(page_type, bytes)
                else str(page_type).encode("utf-8")
            )
            if name_bytes not in ALLOWED_DBSTAT_NAME_BYTES:
                reject(
                    "physical:dbstat-object",
                    "physical",
                    name_bytes.hex(),
                )
            if not 1 <= pageno <= page_count:
                reject("physical:dbstat-page-range", "physical")
            if page_type_bytes not in ALLOWED_DBSTAT_PAGE_TYPES:
                reject(
                    "physical:dbstat-page-type",
                    "physical",
                    page_type_bytes.hex(),
                )
            if page_size != PAGE_SIZE:
                reject("physical:dbstat-page-size", "physical")
            if (
                page_type_bytes != b"overflow"
                and page_offset != (pageno - 1) * PAGE_SIZE
            ):
                reject("physical:dbstat-page-offset", "physical")
            byte_index = (pageno - 1) // 8
            bit = 1 << ((pageno - 1) % 8)
            if seen[byte_index] & bit:
                reject("physical:duplicate-page", "physical")
            seen[byte_index] |= bit
            observed_count += 1
    except sqlite3.DatabaseError as error:
        reject("physical:dbstat-unreadable", "physical", str(error))
    if observed_count != page_count:
        reject("physical:page-closure", "physical")
    for pageno in range(1, page_count + 1):
        byte_index = (pageno - 1) // 8
        bit = 1 << ((pageno - 1) % 8)
        if not seen[byte_index] & bit:
            reject("physical:page-closure", "physical", str(pageno))

    parity_pairs = [
        (
            """
            SELECT name, id
            FROM category_dimension INDEXED BY ux_category_dimension_name
            ORDER BY name, id
            """,
            """
            SELECT name, id
            FROM category_dimension
            INDEXED BY sqlite_autoindex_category_dimension_1
            ORDER BY name, id
            """,
        ),
        (
            """
            SELECT system_key, id
            FROM category_dimension
            INDEXED BY ux_category_dimension_system_key
            WHERE system_key IS NOT NULL
            ORDER BY system_key, id
            """,
            """
            SELECT system_key, id
            FROM category_dimension
            INDEXED BY sqlite_autoindex_category_dimension_1
            WHERE system_key IS NOT NULL
            ORDER BY system_key, id
            """,
        ),
        (
            """
            SELECT dimension_id, name, id
            FROM category_value
            INDEXED BY ux_category_value_dimension_name
            ORDER BY dimension_id, name, id
            """,
            """
            SELECT dimension_id, name, id
            FROM category_value
            INDEXED BY sqlite_autoindex_category_value_1
            ORDER BY dimension_id, name, id
            """,
        ),
        (
            """
            SELECT item_id, role, blob_id
            FROM item_image INDEXED BY ux_item_image_item_role
            ORDER BY item_id, role, blob_id
            """,
            """
            SELECT item_id, role, blob_id
            FROM item_image NOT INDEXED
            ORDER BY item_id, role, blob_id
            """,
        ),
    ]
    for indexed_sql, table_sql in parity_pairs:
        try:
            indexed = database.execute(indexed_sql)
            table = database.execute(table_sql)
            while True:
                indexed_row = indexed.fetchone()
                table_row = table.fetchone()
                if indexed_row != table_row:
                    reject("physical:index-parity", "physical")
                if indexed_row is None:
                    break
        except sqlite3.DatabaseError as error:
            reject("physical:index-parity", "physical", str(error))


def selected_rows(database, table):
    columns = TABLE_COLUMNS[table]
    selected = []
    for column in columns:
        selected.append(f'typeof("{column}")')
        selected.append(f'"{column}"')
    statement = (
        f'SELECT {", ".join(selected)} FROM "{table}" '
        f'ORDER BY {ORDERS[table]}'
    )
    rows = []
    for raw in database.execute(statement):
        if len(rows) >= REFERENCE_MAX_ROWS_PER_TABLE:
            reject(f"reference:row-limit:{table}", "reference")
        row = {}
        for index, column in enumerate(columns):
            logical_type = raw[index * 2]
            if isinstance(logical_type, bytes):
                logical_type = logical_type.decode("ascii")
            row[column] = raw[index * 2 + 1]
            row[column + "__type"] = logical_type
        rows.append(row)
    return rows


def validate_types(rows_by_table):
    for table, rows in rows_by_table.items():
        for row in rows:
            for column, allowed in ALLOWED_TYPES[table].items():
                observed = row[column + "__type"]
                if observed not in allowed:
                    reject(f"type:{table}.{column}", "type", observed)


def validate_utf8(rows_by_table):
    for table, rows in rows_by_table.items():
        for row in rows:
            for column in TABLE_COLUMNS[table]:
                if row[column + "__type"] != "text":
                    continue
                value = row[column]
                try:
                    decoded = value.decode("utf-8", errors="strict")
                except UnicodeDecodeError as error:
                    reject(f"utf8:{table}.{column}", "utf8", str(error))
                if decoded.encode("utf-8") != value:
                    reject(f"utf8:{table}.{column}", "utf8", "round-trip")


def require_check(condition, table, column):
    if not condition:
        reject(f"check:{table}.{column}", "check")


def in_date_range(value):
    return -DATE_LIMIT <= value <= DATE_LIMIT


def valid_icon(value):
    return (
        1 <= len(value) <= ICON_LIMIT
        and b"\0" not in value
        and re.fullmatch(rb"[a-z0-9.]+", value) is not None
    )


def validate_checks(rows_by_table):
    roots = rows_by_table["backup_root"]
    require_check(len(roots) == 1, "backup_root", "row_count")
    root = roots[0]
    require_check(root["singleton"] == 1, "backup_root", "singleton")
    require_check(
        root["artifact_kind"] == b"external-complete",
        "backup_root",
        "artifact_kind",
    )
    require_check(root["wire_version"] == 3, "backup_root", "wire_version")
    require_check(
        in_date_range(root["created_at_ms"]),
        "backup_root",
        "created_at_ms",
    )
    require_check(
        1 <= len(root["writer_marketing_version"]) <= 128,
        "backup_root",
        "writer_marketing_version",
    )
    require_check(
        1 <= len(root["writer_build"]) <= 64,
        "backup_root",
        "writer_build",
    )
    require_check(
        root["digest_algorithm"] == b"sha256",
        "backup_root",
        "digest_algorithm",
    )
    for column in (
        "item_count",
        "dimension_count",
        "value_count",
        "item_value_count",
        "image_count",
        "image_byte_count",
    ):
        require_check(root[column] >= 0, "backup_root", column)
    require_check(
        len(root["inventory_sha256"]) == 32,
        "backup_root",
        "inventory_sha256",
    )

    for row in rows_by_table["category_dimension"]:
        require_check(len(row["id"]) == 16, "category_dimension", "id")
        require_check(
            1 <= len(row["name"]) <= NAME_LIMIT,
            "category_dimension",
            "name",
        )
        require_check(
            row["is_multi_value"] in (0, 1),
            "category_dimension",
            "is_multi_value",
        )
        require_check(
            row["is_built_in"] in (0, 1),
            "category_dimension",
            "is_built_in",
        )
        require_check(valid_icon(row["icon"]), "category_dimension", "icon")
        require_check(
            len(row["record_sha256"]) == 32,
            "category_dimension",
            "record_sha256",
        )
        if row["is_built_in"] == 0:
            grammar = row["system_key"] is None
        else:
            grammar = (
                row["system_key"] == b"tag"
                and row["is_multi_value"] == 1
            ) or (
                row["system_key"] in (b"category", b"source", b"level")
                and row["is_multi_value"] == 0
            )
        require_check(grammar, "category_dimension", "built_in_grammar")

    for row in rows_by_table["category_value"]:
        require_check(len(row["id"]) == 16, "category_value", "id")
        require_check(
            len(row["dimension_id"]) == 16,
            "category_value",
            "dimension_id",
        )
        require_check(
            1 <= len(row["name"]) <= NAME_LIMIT,
            "category_value",
            "name",
        )
        require_check(valid_icon(row["icon"]), "category_value", "icon")
        require_check(
            re.fullmatch(rb"#[0-9A-F]{6}", row["color_hex"]) is not None,
            "category_value",
            "color_hex",
        )
        require_check(
            in_date_range(row["created_at_ms"]),
            "category_value",
            "created_at_ms",
        )
        require_check(
            len(row["record_sha256"]) == 32,
            "category_value",
            "record_sha256",
        )

    for row in rows_by_table["library_item"]:
        require_check(len(row["id"]) == 16, "library_item", "id")
        require_check(
            row["content"] is None or len(row["content"]) <= TEXT_LIMIT,
            "library_item",
            "content",
        )
        require_check(
            in_date_range(row["created_at_ms"]),
            "library_item",
            "created_at_ms",
        )
        require_check(
            row["last_reviewed_at_ms"] is None
            or in_date_range(row["last_reviewed_at_ms"]),
            "library_item",
            "last_reviewed_at_ms",
        )
        require_check(
            row["next_review_at_ms"] is None
            or in_date_range(row["next_review_at_ms"]),
            "library_item",
            "next_review_at_ms",
        )
        require_check(
            math.isfinite(row["ease_factor"]),
            "library_item",
            "ease_factor",
        )
        require_check(
            0 <= row["interval_days"] <= 365,
            "library_item",
            "interval_days",
        )
        require_check(
            row["repetitions"] >= 0,
            "library_item",
            "repetitions",
        )
        require_check(
            row["answer_text"] is None
            or len(row["answer_text"]) <= TEXT_LIMIT,
            "library_item",
            "answer_text",
        )
        require_check(
            len(row["record_sha256"]) == 32,
            "library_item",
            "record_sha256",
        )

    for row in rows_by_table["item_category_value"]:
        require_check(
            len(row["item_id"]) == 16,
            "item_category_value",
            "item_id",
        )
        require_check(
            len(row["value_id"]) == 16,
            "item_category_value",
            "value_id",
        )
        require_check(
            len(row["record_sha256"]) == 32,
            "item_category_value",
            "record_sha256",
        )

    for row in rows_by_table["item_image"]:
        require_check(row["blob_id"] > 0, "item_image", "blob_id")
        require_check(len(row["item_id"]) == 16, "item_image", "item_id")
        require_check(row["role"] in (0, 1), "item_image", "role")
        require_check(
            row["media_type"] == b"image/jpeg",
            "item_image",
            "media_type",
        )
        require_check(
            1 <= row["pixel_width"] <= 2_000,
            "item_image",
            "pixel_width",
        )
        require_check(
            1 <= row["pixel_height"] <= 2_000,
            "item_image",
            "pixel_height",
        )
        require_check(
            1 <= row["byte_count"] <= IMAGE_BYTE_LIMIT,
            "item_image",
            "byte_count",
        )
        require_check(
            len(row["content_sha256"]) == 32,
            "item_image",
            "content_sha256",
        )
        require_check(
            len(row["record_sha256"]) == 32,
            "item_image",
            "record_sha256",
        )
        require_check(
            len(row["jpeg_bytes"]) == row["byte_count"],
            "item_image",
            "jpeg_bytes",
        )


def require_unique(rows, columns, rule, skip_null=False):
    keys = []
    for row in rows:
        key = tuple(row[column] for column in columns)
        if skip_null and any(value is None for value in key):
            continue
        keys.append(key)
    keys.sort()
    for previous, current in zip(keys, keys[1:]):
        if previous == current:
            reject(f"semantic:duplicate:{rule}", "semantic")


def validate_uniqueness(rows_by_table):
    rules = [
        ("category_dimension", ("id",), "category_dimension.id", False),
        ("category_dimension", ("name",), "category_dimension.name", False),
        (
            "category_dimension",
            ("system_key",),
            "category_dimension.system_key",
            True,
        ),
        ("category_value", ("id",), "category_value.id", False),
        (
            "category_value",
            ("dimension_id", "name"),
            "category_value.dimension_name",
            False,
        ),
        ("library_item", ("id",), "library_item.id", False),
        (
            "item_category_value",
            ("item_id", "value_id"),
            "item_category_value.primary_key",
            False,
        ),
        ("item_image", ("blob_id",), "item_image.blob_id", False),
        (
            "item_image",
            ("item_id", "role"),
            "item_image.item_role",
            False,
        ),
    ]
    for table, columns, rule, skip_null in rules:
        require_unique(rows_by_table[table], columns, rule, skip_null)


def validate_foreign_keys(database):
    row = database.execute("PRAGMA foreign_key_check").fetchone()
    if row is not None:
        reject("semantic:foreign-key-closure", "semantic")


def checked_add(left, right):
    result = left + right
    if result > INT64_MAX:
        reject("semantic:checked-overflow", "semantic")
    return result


def frame(type_byte, payload=b""):
    return bytes((type_byte,)) + len(payload).to_bytes(8, "big") + payload


def null_frame():
    return frame(0x00)


def bool_frame(value):
    return frame(0x01, bytes((value,)))


def int_frame(value):
    return frame(0x02, value.to_bytes(8, "big", signed=True))


def double_frame(value):
    normalized = 0.0 if value == 0.0 else value
    return frame(0x03, struct.pack(">d", normalized))


def text_frame(value):
    return null_frame() if value is None else frame(0x04, value)


def uuid_frame(value):
    return frame(0x05, value)


def sha_frame(value):
    return frame(0x06, value)


def role_frame(value):
    return frame(0x07, bytes((value,)))


def record_digest(tag, fields):
    return hashlib.sha256(
        DOMAIN + bytes((tag,)) + b"".join(fields)
    ).digest()


def dimension_digest(row):
    return record_digest(
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
    return record_digest(
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
    return record_digest(
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
    return record_digest(
        0x14,
        [
            uuid_frame(row["item_id"]),
            uuid_frame(row["value_id"]),
        ],
    )


def image_digest(row, content_sha256):
    return record_digest(
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


def validate_semantics(rows_by_table, m1_policy):
    roots = rows_by_table["backup_root"]
    root = roots[0]
    dimensions = rows_by_table["category_dimension"]
    values = rows_by_table["category_value"]
    items = rows_by_table["library_item"]
    joins = rows_by_table["item_category_value"]
    images = rows_by_table["item_image"]

    expected_counts = {
        "item_count": len(items),
        "dimension_count": len(dimensions),
        "value_count": len(values),
        "item_value_count": len(joins),
        "image_count": len(images),
    }
    for column, observed in expected_counts.items():
        if root[column] != observed:
            reject(f"semantic:root-{column}", "semantic")
    image_byte_count = 0
    for image in images:
        image_byte_count = checked_add(image_byte_count, image["byte_count"])
    if root["image_byte_count"] != image_byte_count:
        reject("semantic:root-image-byte-count", "semantic")

    built_in_keys = [
        row["system_key"]
        for row in dimensions
        if row["is_built_in"] == 1
    ]
    if sorted(built_in_keys) != [
        b"category",
        b"level",
        b"source",
        b"tag",
    ]:
        reject("semantic:built-in-inventory", "semantic")

    if m1_policy == "A":
        dimension_by_value = {
            row["id"]: row["dimension_id"] for row in values
        }
        multi_by_dimension = {
            row["id"]: row["is_multi_value"] for row in dimensions
        }
        links = {}
        for join in joins:
            dimension_id = dimension_by_value[join["value_id"]]
            if multi_by_dimension[dimension_id] == 0:
                key = (join["item_id"], dimension_id)
                links[key] = links.get(key, 0) + 1
                if links[key] > 1:
                    reject("semantic:M1-A-single-value-multiplicity", "semantic")
    elif m1_policy != "C":
        raise ValueError(f"unsupported M1 policy {m1_policy}")

    main_image_items = {
        row["item_id"] for row in images if row["role"] == 0
    }
    for item in items:
        if (
            item["content"] is None or len(item["content"]) == 0
        ) and item["id"] not in main_image_items:
            reject("semantic:content-or-main-image", "semantic")

    entries = []
    for row in dimensions:
        digest = dimension_digest(row)
        if row["record_sha256"] != digest:
            reject("digest:category_dimension.record_sha256", "digest")
        entries.append((0x11, digest))
    for row in values:
        digest = value_digest(row)
        if row["record_sha256"] != digest:
            reject("digest:category_value.record_sha256", "digest")
        entries.append((0x12, digest))
    for row in items:
        digest = item_digest(row)
        if row["record_sha256"] != digest:
            reject("digest:library_item.record_sha256", "digest")
        entries.append((0x13, digest))
    for row in joins:
        digest = join_digest(row)
        if row["record_sha256"] != digest:
            reject("digest:item_category_value.record_sha256", "digest")
        entries.append((0x14, digest))
    for row in images:
        content_sha256 = hashlib.sha256(row["jpeg_bytes"]).digest()
        if row["content_sha256"] != content_sha256:
            reject("digest:item_image.content_sha256", "digest")
        digest = image_digest(row, content_sha256)
        if row["record_sha256"] != digest:
            reject("digest:item_image.record_sha256", "digest")
        try:
            parsed = JPEG_GRAMMAR.validate_jpeg(row["jpeg_bytes"])
        except JPEG_GRAMMAR.JPEGError as error:
            reject("jpeg:grammar", "jpeg", str(error))
        if (parsed["width"], parsed["height"]) != (
            row["pixel_width"],
            row["pixel_height"],
        ):
            reject("jpeg:dimension-match", "jpeg")
        entries.append((0x15, digest))

    root_fields = [
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
        bytes((tag,)) + sha_frame(digest) for tag, digest in entries
    ]
    inventory = hashlib.sha256(
        DOMAIN
        + b"\x10"
        + b"".join(root_fields)
        + b"".join(framed_entries)
    ).digest()
    if root["inventory_sha256"] != inventory:
        reject("digest:backup_root.inventory_sha256", "digest")
    return inventory


def validate_database(path, m1_policy="A"):
    path = pathlib.Path(path)
    initial_node = validate_filesystem(path)
    validate_header(path)
    page_count = path.stat().st_size // PAGE_SIZE
    encoded_path = urllib.parse.quote(str(path.resolve()), safe="/")
    database = sqlite3.connect(
        f"file:{encoded_path}?mode=ro&immutable=1&cache=private",
        uri=True,
    )
    database.text_factory = bytes
    try:
        validate_schema(database)
        validate_reference_row_counts(database)
        validate_physical_closure(database, page_count)
        rows_by_table = {
            table: selected_rows(database, table) for table in TABLE_COLUMNS
        }
        validate_types(rows_by_table)
        validate_utf8(rows_by_table)
        validate_checks(rows_by_table)
        validate_uniqueness(rows_by_table)
        validate_foreign_keys(database)
        inventory = validate_semantics(rows_by_table, m1_policy)
    except sqlite3.DatabaseError as error:
        reject("sqlite:database-error", "sqlite", str(error))
    finally:
        database.close()
    final_node = path.lstat()
    if node_identity(initial_node) != node_identity(final_node):
        reject("filesystem:source-mutated", "filesystem")
    return inventory


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("database", type=pathlib.Path)
    parser.add_argument("--m1-policy", choices=("A", "C"), default="A")
    arguments = parser.parse_args()
    try:
        inventory = validate_database(arguments.database, arguments.m1_policy)
    except ValidationError as error:
        print(
            f"REJECT code={error.code} stage={error.stage} "
            f"detail={error.detail}"
        )
        raise SystemExit(1)
    print(f"PASS reference validator inventory_sha256={inventory.hex()}")


if __name__ == "__main__":
    main()
