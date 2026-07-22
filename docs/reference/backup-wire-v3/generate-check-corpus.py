#!/usr/bin/env python3

import hashlib
import importlib.util
import json
import math
import pathlib
import shutil
import sqlite3
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
BASELINE = ROOT / "iOS-26.5-full-v3.sqlite"
SCHEMA_MANIFEST = (ROOT / "schema-manifest.txt").read_bytes()
CHECK_TARGETS_PATH = ROOT / "check-targets.json"
CHECK_TARGETS = json.loads(CHECK_TARGETS_PATH.read_text())["targets"]
DIGEST_PATH = ROOT / "v3-digest.py"
DIGEST_SPEC = importlib.util.spec_from_file_location("v3_digest", DIGEST_PATH)
if DIGEST_SPEC is None or DIGEST_SPEC.loader is None:
    raise RuntimeError("cannot load v3 digest oracle")
V3_DIGEST = importlib.util.module_from_spec(DIGEST_SPEC)
DIGEST_SPEC.loader.exec_module(V3_DIGEST)
REFERENCE_PATH = ROOT / "reference-validator.py"
REFERENCE_SPEC = importlib.util.spec_from_file_location(
    "check_reference_validator",
    REFERENCE_PATH,
)
if REFERENCE_SPEC is None or REFERENCE_SPEC.loader is None:
    raise RuntimeError("cannot load reference validator")
REFERENCE = importlib.util.module_from_spec(REFERENCE_SPEC)
REFERENCE_SPEC.loader.exec_module(REFERENCE)

DIMENSION_ID = bytes(15) + b"\x05"
VALUE_ID = bytes(15) + b"\x14"
ITEM_ID = bytes(15) + b"\x24"
JOIN_ITEM_ID = bytes(15) + b"\x22"
JOIN_VALUE_ID = bytes(15) + b"\x11"
EXPECTED_SEMANTIC_MANIFEST_SHA256 = (
    "9f1a7c9a7b435c9a6f4a24722801a9917acd69490f9d954e3b49d4139dac8353"
)


def case(
    identifier,
    table,
    updates,
    where,
    parameters=(),
    probe_sql=None,
    probe_parameters=(),
    expected=None,
    recompute=True,
):
    if probe_sql is None:
        columns = ", ".join(f'"{column}"' for column in updates)
        probe_sql = f'SELECT {columns} FROM "{table}" WHERE {where}'
        probe_parameters = parameters
        expected = tuple(updates.values())
    return {
        "case_id": identifier,
        "table": table,
        "updates": updates,
        "where": where,
        "parameters": parameters,
        "probe_sql": probe_sql,
        "probe_parameters": probe_parameters,
        "expected": expected,
        "recompute": recompute,
    }


def column_case(
    identifier,
    table,
    column,
    value,
    where,
    parameters=(),
    recompute=True,
):
    return case(
        identifier,
        table,
        {column: value},
        where,
        parameters,
        recompute=recompute,
    )


def build_cases():
    cases = [
        column_case("V3-N-CHECK-ROOT-SINGLETON", "backup_root", "singleton", 2, "1=1"),
        column_case(
            "V3-N-CHECK-ROOT-ARTIFACT-KIND",
            "backup_root",
            "artifact_kind",
            "partial",
            "1=1",
        ),
        column_case("V3-N-CHECK-ROOT-WIRE-VERSION", "backup_root", "wire_version", 4, "1=1"),
        column_case(
            "V3-N-CHECK-ROOT-CREATED-AT",
            "backup_root",
            "created_at_ms",
            1_000_000_000_000_001,
            "1=1",
        ),
        column_case(
            "V3-N-CHECK-ROOT-MARKETING-EMPTY",
            "backup_root",
            "writer_marketing_version",
            "",
            "1=1",
        ),
        column_case(
            "V3-N-CHECK-ROOT-MARKETING-OVER",
            "backup_root",
            "writer_marketing_version",
            "m" * 129,
            "1=1",
        ),
        column_case(
            "V3-N-CHECK-ROOT-BUILD-EMPTY",
            "backup_root",
            "writer_build",
            "",
            "1=1",
        ),
        column_case(
            "V3-N-CHECK-ROOT-BUILD-OVER",
            "backup_root",
            "writer_build",
            "b" * 65,
            "1=1",
        ),
        column_case(
            "V3-N-CHECK-ROOT-DIGEST-ALGORITHM",
            "backup_root",
            "digest_algorithm",
            "sha1",
            "1=1",
        ),
        column_case(
            "V3-N-CHECK-ROOT-INVENTORY-LENGTH",
            "backup_root",
            "inventory_sha256",
            bytes(31),
            "1=1",
            recompute=False,
        ),
    ]
    for column in (
        "item_count",
        "dimension_count",
        "value_count",
        "item_value_count",
        "image_count",
        "image_byte_count",
    ):
        cases.append(
            column_case(
                f"V3-N-CHECK-ROOT-{column.replace('_', '-').upper()}",
                "backup_root",
                column,
                -1,
                "1=1",
            )
        )

    dimension_where = "id=?"
    dimension_parameters = (DIMENSION_ID,)
    cases.extend(
        [
            case(
                "V3-N-CHECK-DIMENSION-ID-LENGTH",
                "category_dimension",
                {"id": bytes(15)},
                dimension_where,
                dimension_parameters,
                "SELECT length(id) FROM category_dimension WHERE name='Empty'",
                (),
                (15,),
                False,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-NAME-EMPTY",
                "category_dimension",
                "name",
                "",
                dimension_where,
                dimension_parameters,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-NAME-OVER",
                "category_dimension",
                "name",
                "n" * 1_025,
                dimension_where,
                dimension_parameters,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-MULTI-BOOL",
                "category_dimension",
                "is_multi_value",
                2,
                dimension_where,
                dimension_parameters,
                False,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-BUILTIN-BOOL",
                "category_dimension",
                "is_built_in",
                2,
                dimension_where,
                dimension_parameters,
                False,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-ICON-EMPTY",
                "category_dimension",
                "icon",
                "",
                dimension_where,
                dimension_parameters,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-ICON-OVER",
                "category_dimension",
                "icon",
                "a" * 257,
                dimension_where,
                dimension_parameters,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-ICON-NUL",
                "category_dimension",
                "icon",
                "square\x00fill",
                dimension_where,
                dimension_parameters,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-ICON-GRAMMAR",
                "category_dimension",
                "icon",
                "Square",
                dimension_where,
                dimension_parameters,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-RECORD-LENGTH",
                "category_dimension",
                "record_sha256",
                bytes(31),
                dimension_where,
                dimension_parameters,
                False,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-CUSTOM-SYSTEM-KEY",
                "category_dimension",
                "system_key",
                "custom",
                dimension_where,
                dimension_parameters,
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-BUILTIN-MISSING-KEY",
                "category_dimension",
                "system_key",
                None,
                "id=?",
                (bytes(15) + b"\x01",),
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-TAG-NOT-MULTI",
                "category_dimension",
                "is_multi_value",
                0,
                "id=?",
                (bytes(15) + b"\x04",),
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-SINGLE-KEY-MULTI",
                "category_dimension",
                "is_multi_value",
                1,
                "id=?",
                (bytes(15) + b"\x01",),
            ),
            column_case(
                "V3-N-CHECK-DIMENSION-UNKNOWN-BUILTIN-KEY",
                "category_dimension",
                "system_key",
                "unknown",
                "id=?",
                (bytes(15) + b"\x01",),
            ),
        ]
    )

    value_where = "id=?"
    value_parameters = (VALUE_ID,)
    cases.extend(
        [
            case(
                "V3-N-CHECK-VALUE-ID-LENGTH",
                "category_value",
                {"id": bytes(15)},
                value_where,
                value_parameters,
                "SELECT length(id) FROM category_value WHERE name='Home'",
                (),
                (15,),
                False,
            ),
            column_case(
                "V3-N-CHECK-VALUE-NAME-EMPTY",
                "category_value",
                "name",
                "",
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-NAME-OVER",
                "category_value",
                "name",
                "n" * 1_025,
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-ICON-EMPTY",
                "category_value",
                "icon",
                "",
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-ICON-OVER",
                "category_value",
                "icon",
                "a" * 257,
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-ICON-NUL",
                "category_value",
                "icon",
                "house\x00fill",
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-ICON-GRAMMAR",
                "category_value",
                "icon",
                "House",
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-COLOR-LENGTH",
                "category_value",
                "color_hex",
                "#12345",
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-COLOR-GRAMMAR",
                "category_value",
                "color_hex",
                "#GGGGGG",
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-COLOR-LOWERCASE",
                "category_value",
                "color_hex",
                "#abcdef",
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-CREATED-AT",
                "category_value",
                "created_at_ms",
                -1_000_000_000_000_001,
                value_where,
                value_parameters,
            ),
            column_case(
                "V3-N-CHECK-VALUE-RECORD-LENGTH",
                "category_value",
                "record_sha256",
                bytes(31),
                value_where,
                value_parameters,
                False,
            ),
        ]
    )

    item_where = "id=?"
    item_parameters = (ITEM_ID,)
    cases.extend(
        [
            case(
                "V3-N-CHECK-ITEM-ID-LENGTH",
                "library_item",
                {"id": bytes(15)},
                item_where,
                item_parameters,
                "SELECT length(id) FROM library_item WHERE content='No answer'",
                (),
                (15,),
                False,
            ),
            column_case(
                "V3-N-CHECK-ITEM-CONTENT-OVER",
                "library_item",
                "content",
                "a" * 1_048_577,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-CREATED-AT",
                "library_item",
                "created_at_ms",
                1_000_000_000_000_001,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-LAST-REVIEWED",
                "library_item",
                "last_reviewed_at_ms",
                -1_000_000_000_000_001,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-NEXT-REVIEW",
                "library_item",
                "next_review_at_ms",
                1_000_000_000_000_001,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-EASE-NONFINITE",
                "library_item",
                "ease_factor",
                math.inf,
                item_where,
                item_parameters,
                False,
            ),
            column_case(
                "V3-N-CHECK-ITEM-INTERVAL-LOW",
                "library_item",
                "interval_days",
                -1,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-INTERVAL-HIGH",
                "library_item",
                "interval_days",
                366,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-REPETITIONS",
                "library_item",
                "repetitions",
                -1,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-ANSWER-OVER",
                "library_item",
                "answer_text",
                "a" * 1_048_577,
                item_where,
                item_parameters,
            ),
            column_case(
                "V3-N-CHECK-ITEM-RECORD-LENGTH",
                "library_item",
                "record_sha256",
                bytes(31),
                item_where,
                item_parameters,
                False,
            ),
        ]
    )

    cases.append(
        column_case(
            "V3-N-CHECK-JOIN-RECORD-LENGTH",
            "item_category_value",
            "record_sha256",
            bytes(31),
            "item_id=? AND value_id=?",
            (JOIN_ITEM_ID, JOIN_VALUE_ID),
            False,
        )
    )

    image_where = "blob_id=1"
    cases.extend(
        [
            case(
                "V3-N-CHECK-IMAGE-BLOB-ID",
                "item_image",
                {"blob_id": 0},
                image_where,
                probe_sql=(
                    "SELECT blob_id FROM item_image "
                    "WHERE item_id=? AND role=0"
                ),
                probe_parameters=(bytes(15) + b"\x22",),
                expected=(0,),
            ),
            column_case(
                "V3-N-CHECK-IMAGE-ROLE",
                "item_image",
                "role",
                2,
                image_where,
                recompute=False,
            ),
            column_case(
                "V3-N-CHECK-IMAGE-MEDIA-TYPE",
                "item_image",
                "media_type",
                "image/png",
                image_where,
            ),
            column_case("V3-N-CHECK-IMAGE-WIDTH-LOW", "item_image", "pixel_width", 0, image_where),
            column_case(
                "V3-N-CHECK-IMAGE-WIDTH-HIGH",
                "item_image",
                "pixel_width",
                2_001,
                image_where,
            ),
            column_case("V3-N-CHECK-IMAGE-HEIGHT-LOW", "item_image", "pixel_height", 0, image_where),
            column_case(
                "V3-N-CHECK-IMAGE-HEIGHT-HIGH",
                "item_image",
                "pixel_height",
                2_001,
                image_where,
            ),
            column_case(
                "V3-N-CHECK-IMAGE-BYTE-COUNT-LOW",
                "item_image",
                "byte_count",
                0,
                image_where,
            ),
            column_case(
                "V3-N-CHECK-IMAGE-BYTE-COUNT-HIGH",
                "item_image",
                "byte_count",
                52_428_801,
                image_where,
            ),
            column_case(
                "V3-N-CHECK-IMAGE-CONTENT-DIGEST-LENGTH",
                "item_image",
                "content_sha256",
                bytes(31),
                image_where,
                recompute=False,
            ),
            column_case(
                "V3-N-CHECK-IMAGE-RECORD-LENGTH",
                "item_image",
                "record_sha256",
                bytes(31),
                image_where,
                recompute=False,
            ),
            case(
                "V3-N-CHECK-IMAGE-BYTE-LENGTH-MISMATCH",
                "item_image",
                {"jpeg_bytes": (ROOT / "canonical-rgb-sof0-2x2.jpg").read_bytes() + b"\x00"},
                image_where,
                probe_sql=(
                    "SELECT length(jpeg_bytes), byte_count "
                    "FROM item_image WHERE blob_id=1"
                ),
                expected=(728, 727),
            ),
        ]
    )
    return cases


def schema_manifest(database_path):
    database = sqlite3.connect(f"file:{database_path}?mode=ro", uri=True)
    try:
        rows = database.execute(
            """
            SELECT type, name, tbl_name, hex(sql)
            FROM sqlite_schema
            ORDER BY type, name
            """
        ).fetchall()
    finally:
        database.close()
    return "".join("|".join(str(value) for value in row) + "\n" for row in rows).encode()


def apply_case(output_root, definition):
    path = output_root / (definition["case_id"].lower() + ".sqlite")
    shutil.copyfile(BASELINE, path)
    database = sqlite3.connect(path)
    try:
        database.execute("PRAGMA ignore_check_constraints=ON")
        assignments = ", ".join(
            f'"{column}"=?' for column in definition["updates"]
        )
        cursor = database.execute(
            f'UPDATE "{definition["table"]}" SET {assignments} '
            f'WHERE {definition["where"]}',
            (*definition["updates"].values(), *definition["parameters"]),
        )
        if cursor.rowcount != 1:
            raise AssertionError(
                f'{definition["case_id"]}: update count {cursor.rowcount}'
            )
        database.commit()
    finally:
        database.close()

    if definition["recompute"]:
        V3_DIGEST.recompute_database(path)

    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            definition["probe_sql"],
            definition["probe_parameters"],
        ).fetchone()
        integrity = database.execute("PRAGMA integrity_check").fetchall()
    finally:
        database.close()
    if observed != definition["expected"]:
        raise AssertionError(
            f'{definition["case_id"]}: expected {definition["expected"]!r}, '
            f"observed {observed!r}"
        )
    if integrity == [("ok",)]:
        raise AssertionError(f'{definition["case_id"]}: integrity_check passed')
    if schema_manifest(path) != SCHEMA_MANIFEST:
        raise AssertionError(f'{definition["case_id"]}: schema changed')
    try:
        REFERENCE.validate_database(path)
    except REFERENCE.ValidationError as error:
        expected_code = CHECK_TARGETS[definition["case_id"]]
        if error.stage != "check" or error.code != expected_code:
            raise AssertionError(
                f'{definition["case_id"]}: expected {expected_code}, '
                f'observed {error.code}'
            ) from error
        reference_outcome = "rejected:" + error.code
    else:
        raise AssertionError(
            f'{definition["case_id"]}: reference validator accepted'
        )
    return {
        "case_id": definition["case_id"],
        "table": definition["table"],
        "columns": sorted(definition["updates"]),
        "target_rule": CHECK_TARGETS[definition["case_id"]],
        "dependent_digests_recomputed": definition["recompute"],
        "integrity_error_count": len(integrity),
        "reference_outcome": reference_outcome,
        "byte_count": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def semantic_manifest(cases):
    return [
        {
            key: value
            for key, value in case.items()
            if key not in {"byte_count", "sha256"}
        }
        for case in cases
    ]


def main():
    definitions = build_cases()
    identifiers = [definition["case_id"] for definition in definitions]
    if len(identifiers) != len(set(identifiers)):
        raise AssertionError("duplicate CHECK case ID")
    if set(identifiers) != set(CHECK_TARGETS):
        missing = sorted(set(identifiers) - set(CHECK_TARGETS))
        extra = sorted(set(CHECK_TARGETS) - set(identifiers))
        raise AssertionError(
            f"CHECK target set mismatch: missing={missing!r}, extra={extra!r}"
        )
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-checks-a-") as first:
        with tempfile.TemporaryDirectory(prefix="snapdrill-v3-checks-b-") as second:
            first_cases = [
                apply_case(pathlib.Path(first), definition)
                for definition in definitions
            ]
            second_cases = [
                apply_case(pathlib.Path(second), definition)
                for definition in definitions
            ]
            if semantic_manifest(first_cases) != semantic_manifest(second_cases):
                raise AssertionError("CHECK corpus semantic manifest is nondeterministic")
            first_files = [
                (case["byte_count"], case["sha256"]) for case in first_cases
            ]
            second_files = [
                (case["byte_count"], case["sha256"]) for case in second_cases
            ]
            if first_files != second_files:
                raise AssertionError("CHECK corpus physical outputs are nondeterministic")
            manifest_bytes = json.dumps(
                semantic_manifest(first_cases),
                separators=(",", ":"),
                sort_keys=True,
            ).encode()
            manifest_sha256 = hashlib.sha256(manifest_bytes).hexdigest()
            if manifest_sha256 != EXPECTED_SEMANTIC_MANIFEST_SHA256:
                raise AssertionError(
                    "CHECK corpus case manifest changed: "
                    f"expected {EXPECTED_SEMANTIC_MANIFEST_SHA256}, "
                    f"observed {manifest_sha256}"
                )
            print(
                json.dumps(
                    {
                        "case_count": len(first_cases),
                        "semantic_manifest_sha256": manifest_sha256,
                        "sqlite_version": sqlite3.sqlite_version,
                    },
                    sort_keys=True,
                )
            )
    print("PASS deterministic SQLite CHECK corpus")


if __name__ == "__main__":
    main()
