#!/usr/bin/env python3

import hashlib
import importlib.util
import json
import pathlib
import shutil
import sqlite3
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
BASELINE = ROOT / "iOS-26.5-full-v3.sqlite"
SCHEMA_MANIFEST = (ROOT / "schema-manifest.txt").read_bytes()

REFERENCE_PATH = ROOT / "reference-validator.py"
REFERENCE_SPEC = importlib.util.spec_from_file_location(
    "type_reference_validator",
    REFERENCE_PATH,
)
if REFERENCE_SPEC is None or REFERENCE_SPEC.loader is None:
    raise RuntimeError("cannot load reference validator")
REFERENCE = importlib.util.module_from_spec(REFERENCE_SPEC)
REFERENCE_SPEC.loader.exec_module(REFERENCE)
STORAGE_CLASSES = {"null", "integer", "real", "text", "blob"}
VALUES = {
    "null": None,
    "integer": 7,
    "real": 0.5,
    "text": "wrong-type",
    "blob": b"\x01\x02",
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

PERMISSIVE_SCHEMAS = {
    "backup_root": """
        CREATE TABLE backup_root(
            singleton BLOB PRIMARY KEY, artifact_kind BLOB, wire_version BLOB,
            created_at_ms BLOB, writer_marketing_version BLOB, writer_build BLOB,
            digest_algorithm BLOB, item_count BLOB, dimension_count BLOB,
            value_count BLOB, item_value_count BLOB, image_count BLOB,
            image_byte_count BLOB, inventory_sha256 BLOB
        ) WITHOUT ROWID
    """,
    "category_dimension": """
        CREATE TABLE category_dimension(
            id BLOB PRIMARY KEY, name BLOB, is_multi_value BLOB,
            is_built_in BLOB, system_key BLOB, sort_order BLOB, icon BLOB,
            record_sha256 BLOB
        ) WITHOUT ROWID
    """,
    "category_value": """
        CREATE TABLE category_value(
            id BLOB PRIMARY KEY, dimension_id BLOB, name BLOB, icon BLOB,
            color_hex BLOB, sort_order BLOB, created_at_ms BLOB,
            record_sha256 BLOB
        ) WITHOUT ROWID
    """,
    "library_item": """
        CREATE TABLE library_item(
            id BLOB PRIMARY KEY, content BLOB, created_at_ms BLOB,
            last_reviewed_at_ms BLOB, next_review_at_ms BLOB, ease_factor BLOB,
            interval_days BLOB, repetitions BLOB, answer_text BLOB,
            record_sha256 BLOB
        ) WITHOUT ROWID
    """,
    "item_category_value": """
        CREATE TABLE item_category_value(
            item_id BLOB, value_id BLOB, record_sha256 BLOB,
            PRIMARY KEY(item_id, value_id)
        ) WITHOUT ROWID
    """,
    "item_image": """
        CREATE TABLE item_image(
            blob_id INTEGER PRIMARY KEY, item_id BLOB, role BLOB,
            media_type BLOB, pixel_width BLOB, pixel_height BLOB,
            byte_count BLOB, content_sha256 BLOB, record_sha256 BLOB,
            jpeg_bytes BLOB
        )
    """,
}

PRIMARY_KEY_COLUMNS = {
    ("backup_root", "singleton"),
    ("category_dimension", "id"),
    ("category_value", "id"),
    ("library_item", "id"),
    ("item_category_value", "item_id"),
    ("item_category_value", "value_id"),
}
EXPECTED_SEMANTIC_MANIFEST_SHA256 = (
    "1f02b9c5db77484e1d8b790040902323f16f214ac4b6e2370ac2ddd4b3d7c1fb"
)


def quoted(identifier):
    return '"' + identifier.replace('"', '""') + '"'


def schema_sql(database, table):
    row = database.execute(
        "SELECT sql FROM sqlite_schema WHERE type='table' AND name=?",
        (table,),
    ).fetchone()
    if row is None:
        raise AssertionError(f"missing schema for {table}")
    return row[0]


def install_schema(database_path, table, sql):
    database = sqlite3.connect(f"file:{database_path}?mode=ro", uri=True)
    try:
        version = database.execute("PRAGMA schema_version").fetchone()[0]
    finally:
        database.close()
    normalized = sql.strip().replace("'", "''")
    table_literal = table.replace("'", "''")
    run_sqlite(
        database_path,
        (
            "PRAGMA writable_schema=ON;"
            "UPDATE sqlite_schema "
            f"SET sql='{normalized}' "
            f"WHERE type='table' AND name='{table_literal}';"
            f"PRAGMA schema_version={version + 1};"
            "PRAGMA writable_schema=OFF;"
        ),
    )


def run_sqlite(database_path, sql):
    try:
        return subprocess.run(
            ["/usr/bin/sqlite3", "-batch", "-bail", str(database_path), sql],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        raise AssertionError(
            f"sqlite3 failed for {database_path.name}: {error.stderr.strip()}"
        ) from error


def sql_literal(value):
    if value is None:
        return "NULL"
    if isinstance(value, bytes):
        return "X'" + value.hex() + "'"
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"
    return repr(value)


def render_where(where, parameters):
    result = where
    for parameter in parameters:
        result = result.replace("?", sql_literal(parameter), 1)
    if "?" in result:
        raise AssertionError(f"unbound selector parameter: {where}")
    return result


def selector(table, target_column):
    if table == "backup_root":
        return "1=1", ()
    if table == "category_dimension":
        if target_column == "id":
            return "system_key='category'", ()
        return "id=?", (bytes(15) + b"\x01",)
    if table == "category_value":
        if target_column == "id":
            return "name='Archive'", ()
        return "id=?", (bytes(15) + b"\x11",)
    if table == "library_item":
        if target_column == "id":
            return "created_at_ms=1720000010000", ()
        return "id=?", (bytes(15) + b"\x21",)
    if table == "item_category_value":
        if target_column in {"item_id", "value_id"}:
            return "record_sha256=?", (
                bytes.fromhex(
                    "74e3c87d0ed7ceaad5de19c9f378863c"
                    "0a7090b6e6d6b98b00d568db79746b18"
                ),
            )
        return "item_id=? AND value_id=?", (
            bytes(15) + b"\x22",
            bytes(15) + b"\x11",
        )
    if table == "item_image":
        return "blob_id=1", ()
    raise AssertionError(f"unknown table {table}")


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


def file_sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(256 * 1_024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def case_id(table, column, storage_class):
    return (
        f"V3-N-TYPE-{table}-{column}-{storage_class}"
        .replace("_", "-")
        .upper()
    )


def expected_unobservable(table, column, storage_class):
    if table == "item_image" and column == "blob_id":
        return "INTEGER PRIMARY KEY is exposed as the rowid integer"
    if storage_class == "null" and (table, column) in PRIMARY_KEY_COLUMNS:
        return "WITHOUT ROWID primary-key cells cannot be NULL"
    if table == "library_item" and column == "ease_factor" and storage_class == "integer":
        return "REAL affinity exposes an integral serial value as real"
    return None


def generate_case(output_root, table, column, storage_class, original_schema):
    identifier = case_id(table, column, storage_class)
    unobservable = expected_unobservable(table, column, storage_class)
    if unobservable is not None:
        return {
            "case_id": identifier,
            "table": table,
            "column": column,
            "requested_type": storage_class,
            "construction": "not-observable-in-well-formed-sqlite",
            "reason": unobservable,
            "reference_outcome": "not-constructible",
        }

    path = output_root / f"{identifier.lower()}.sqlite"
    shutil.copyfile(BASELINE, path)
    install_schema(path, table, PERMISSIVE_SCHEMAS[table])
    where, parameters = selector(table, column)
    result = run_sqlite(
        path,
        (
            f"UPDATE {quoted(table)} "
            f"SET {quoted(column)}={sql_literal(VALUES[storage_class])} "
            f"WHERE {render_where(where, parameters)};"
            "SELECT changes();"
        ),
    )
    if result.stdout.strip() != "1":
        raise AssertionError(f"{identifier}: update count {result.stdout!r}")
    install_schema(path, table, original_schema)

    database = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        where, parameters = selector(table, column)
        observed = database.execute(
            f"SELECT typeof({quoted(column)}) FROM {quoted(table)} WHERE {where}",
            parameters,
        ).fetchone()
    finally:
        database.close()
    if observed is None or observed[0] != storage_class:
        raise AssertionError(
            f"{identifier}: expected {storage_class}, observed {observed}"
        )
    if schema_manifest(path) != SCHEMA_MANIFEST:
        raise AssertionError(f"{identifier}: canonical schema was not restored")
    expected_rejection = f"type:{table}.{column}"
    try:
        REFERENCE.validate_database(path)
    except REFERENCE.ValidationError as error:
        if error.code != expected_rejection:
            raise AssertionError(
                f"{identifier}: expected reference rejection "
                f"{expected_rejection}, observed {error.code}"
            ) from error
    else:
        raise AssertionError(f"{identifier}: reference validator accepted")
    return {
        "case_id": identifier,
        "table": table,
        "column": column,
        "requested_type": storage_class,
        "observed_type": observed[0],
        "construction": "generated",
        "reference_outcome": "rejected:" + expected_rejection,
        "byte_count": path.stat().st_size,
        "sha256": file_sha256(path),
    }


def generate_corpus(output_root):
    baseline = sqlite3.connect(f"file:{BASELINE}?mode=ro", uri=True)
    try:
        original_schemas = {
            table: schema_sql(baseline, table) for table in ALLOWED_TYPES
        }
    finally:
        baseline.close()

    cases = []
    for table, columns in ALLOWED_TYPES.items():
        for column, allowed in columns.items():
            for storage_class in sorted(STORAGE_CLASSES - allowed):
                cases.append(
                    generate_case(
                        output_root,
                        table,
                        column,
                        storage_class,
                        original_schemas[table],
                    )
                )
    return cases


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
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-types-a-") as first:
        with tempfile.TemporaryDirectory(prefix="snapdrill-v3-types-b-") as second:
            first_cases = generate_corpus(pathlib.Path(first))
            second_cases = generate_corpus(pathlib.Path(second))
            if semantic_manifest(first_cases) != semantic_manifest(second_cases):
                raise AssertionError("type corpus semantic manifest is nondeterministic")
            first_files = [
                (case.get("byte_count"), case.get("sha256"))
                for case in first_cases
                if case["construction"] == "generated"
            ]
            second_files = [
                (case.get("byte_count"), case.get("sha256"))
                for case in second_cases
                if case["construction"] == "generated"
            ]
            if first_files != second_files:
                raise AssertionError("type corpus physical outputs are nondeterministic")

            semantic = semantic_manifest(first_cases)
            manifest_bytes = json.dumps(
                semantic,
                ensure_ascii=True,
                separators=(",", ":"),
                sort_keys=True,
            ).encode()
            manifest_sha256 = hashlib.sha256(manifest_bytes).hexdigest()
            if manifest_sha256 != EXPECTED_SEMANTIC_MANIFEST_SHA256:
                raise AssertionError("type corpus case manifest changed")
            generated = sum(
                case["construction"] == "generated" for case in first_cases
            )
            unobservable = len(first_cases) - generated
            print(
                json.dumps(
                    {
                        "case_count": len(first_cases),
                        "generated_count": generated,
                        "unobservable_count": unobservable,
                        "semantic_manifest_sha256": manifest_sha256,
                        "sqlite_version": sqlite3.sqlite_version,
                    },
                    sort_keys=True,
                )
            )
    print("PASS deterministic SQLite logical-type corpus")


if __name__ == "__main__":
    main()
