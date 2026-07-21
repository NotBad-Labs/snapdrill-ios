#!/usr/bin/env python3

import hashlib
import importlib.util
import json
import pathlib
import sqlite3
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
SCHEMA = (ROOT / "schema.sql").read_text(encoding="utf-8")
EXPECTED_MANIFEST_SHA256 = (
    "06e8291bd91f55f55b597f1b05aacbff66c55555ff09145bb9b1dc6a3b8dc7ee"
)
EXPECTED_INVENTORIES = {
    "en": "6703a7d6927174a7edd6ecb2bb30dba4f281725d366cb06178866790b3013cdd",
    "zh-Hans": "15326e585fa2c3de3e03d8ae63309202d55d943a65cb33c5086b4bda971cc00c",
}


def load_module(name, filename):
    path = ROOT / filename
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {filename}")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


V3_DIGEST = load_module("empty_fixture_digest", "v3-digest.py")
REFERENCE = load_module("empty_fixture_reference", "reference-validator.py")


FIXTURES = {
    "en": {
        "prefix": 0x10,
        "dimensions": [
            (
                "category",
                "Category",
                False,
                "square.grid.2x2.fill",
                [
                    ("Material", "checklist", "#4FC3F7"),
                    ("Documents", "doc.text.fill", "#5C6BC0"),
                    ("Receipts", "receipt.fill", "#66BB6A"),
                    ("Training", "book.closed.fill", "#FFB74D"),
                    ("Work", "briefcase.fill", "#7986CB"),
                    ("Other", "folder.fill", "#78909C"),
                ],
            ),
            (
                "source",
                "Source",
                False,
                "doc.text.fill",
                [
                    ("Document", "doc.text.fill", "#5C6BC0"),
                    ("Web", "safari.fill", "#42A5F5"),
                    ("Training material", "book.closed.fill", "#66BB6A"),
                    ("Screenshot", "rectangle.on.rectangle", "#EF5350"),
                    ("Other", "folder.fill", "#78909C"),
                ],
            ),
            (
                "level",
                "Level",
                False,
                "slider.horizontal.3",
                [
                    ("Basic", "circle", "#808080"),
                    ("Intermediate", "circle", "#808080"),
                    ("Priority", "circle", "#808080"),
                    ("Advanced", "circle", "#808080"),
                ],
            ),
            ("tag", "Tag", True, "tag.fill", []),
        ],
    },
    "zh-Hans": {
        "prefix": 0x20,
        "dimensions": [
            (
                "category",
                "分类",
                False,
                "square.grid.2x2.fill",
                [
                    ("资料", "checklist", "#4FC3F7"),
                    ("文档", "doc.text.fill", "#5C6BC0"),
                    ("票据", "receipt.fill", "#66BB6A"),
                    ("培训", "book.closed.fill", "#FFB74D"),
                    ("工作", "briefcase.fill", "#7986CB"),
                    ("其他", "folder.fill", "#78909C"),
                ],
            ),
            (
                "source",
                "来源",
                False,
                "doc.text.fill",
                [
                    ("文档", "doc.text.fill", "#5C6BC0"),
                    ("网页", "safari.fill", "#42A5F5"),
                    ("培训资料", "book.closed.fill", "#66BB6A"),
                    ("截图", "rectangle.on.rectangle", "#EF5350"),
                    ("其他", "folder.fill", "#78909C"),
                ],
            ),
            (
                "level",
                "级别",
                False,
                "slider.horizontal.3",
                [
                    ("基础", "circle", "#808080"),
                    ("进阶", "circle", "#808080"),
                    ("重点", "circle", "#808080"),
                    ("挑战", "circle", "#808080"),
                ],
            ),
            ("tag", "标签", True, "tag.fill", []),
        ],
    },
}


def fixture_id(prefix, index):
    return bytes((prefix,)) + index.to_bytes(15, "big")


def create_fixture(path, locale, fixture):
    created_at = 1_730_000_000_000
    database = sqlite3.connect(path)
    try:
        database.executescript(SCHEMA)
        database.execute("PRAGMA foreign_keys=ON")
        value_index = 1
        for dimension_index, definition in enumerate(
            fixture["dimensions"],
            start=1,
        ):
            system_key, name, is_multi_value, icon, values = definition
            dimension_id = fixture_id(fixture["prefix"], dimension_index)
            database.execute(
                """
                INSERT INTO category_dimension VALUES (?, ?, ?, 1, ?, ?, ?, ?)
                """,
                (
                    dimension_id,
                    name,
                    int(is_multi_value),
                    system_key,
                    dimension_index - 1,
                    icon,
                    bytes(32),
                ),
            )
            for sort_order, (value_name, value_icon, color_hex) in enumerate(
                values
            ):
                database.execute(
                    """
                    INSERT INTO category_value
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        fixture_id(fixture["prefix"] + 1, value_index),
                        dimension_id,
                        value_name,
                        value_icon,
                        color_hex,
                        sort_order,
                        created_at + value_index,
                        bytes(32),
                    ),
                )
                value_index += 1
        database.execute(
            """
            INSERT INTO backup_root VALUES (
                1, 'external-complete', 3, ?, ?, '0', 'sha256',
                0, 4, ?, 0, 0, 0, ?
            )
            """,
            (
                created_at,
                f"fixture-{locale}",
                value_index - 1,
                bytes(32),
            ),
        )
        database.commit()
    finally:
        database.close()

    inventory = V3_DIGEST.recompute_database(path)
    observed = REFERENCE.validate_database(path)
    if observed != inventory:
        raise AssertionError(f"{locale}: reference inventory mismatch")
    return inventory


def hex_or_value(value):
    return value.hex() if isinstance(value, bytes) else value


def extract_fixture(path, locale, inventory):
    database = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        dimensions = database.execute(
            """
            SELECT id, name, is_multi_value, is_built_in, system_key,
                   sort_order, icon, record_sha256
            FROM category_dimension
            ORDER BY id
            """
        ).fetchall()
        values = database.execute(
            """
            SELECT id, dimension_id, name, icon, color_hex, sort_order,
                   created_at_ms, record_sha256
            FROM category_value
            ORDER BY id
            """
        ).fetchall()
    finally:
        database.close()
    return {
        "case_id": "V3-P-EMPTY-ZH" if locale == "zh-Hans" else "V3-P-EMPTY-EN",
        "locale": locale,
        "inventory_sha256": inventory.hex(),
        "dimensions": [
            [hex_or_value(value) for value in row] for row in dimensions
        ],
        "values": [
            [hex_or_value(value) for value in row] for row in values
        ],
    }


def generate(root):
    manifests = []
    for locale, fixture in FIXTURES.items():
        path = root / f"empty-{locale}.sqlite"
        inventory = create_fixture(path, locale, fixture)
        expected = EXPECTED_INVENTORIES[locale]
        if inventory.hex() != expected:
            raise AssertionError(
                f"{locale}: expected inventory {expected}, "
                f"observed {inventory.hex()}"
            )
        manifests.append(extract_fixture(path, locale, inventory))
    return manifests


def sha256_json(value):
    payload = json.dumps(
        value,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def main():
    with tempfile.TemporaryDirectory(
        prefix="snapdrill-v3-empty-a-"
    ) as first:
        with tempfile.TemporaryDirectory(
            prefix="snapdrill-v3-empty-b-"
        ) as second:
            first_manifest = generate(pathlib.Path(first))
            second_manifest = generate(pathlib.Path(second))
            if first_manifest != second_manifest:
                raise AssertionError("empty fixture manifest is nondeterministic")
            manifest_sha256 = sha256_json(first_manifest)
            if manifest_sha256 != EXPECTED_MANIFEST_SHA256:
                raise AssertionError(
                    "empty fixture manifest changed: "
                    f"expected {EXPECTED_MANIFEST_SHA256}, "
                    f"observed {manifest_sha256}"
                )
            print(
                json.dumps(
                    {
                        "case_count": len(first_manifest),
                        "inventories": {
                            fixture["locale"]: fixture["inventory_sha256"]
                            for fixture in first_manifest
                        },
                        "semantic_manifest_sha256": manifest_sha256,
                    },
                    sort_keys=True,
                )
            )
    print("PASS deterministic bilingual empty fixtures")


if __name__ == "__main__":
    main()
