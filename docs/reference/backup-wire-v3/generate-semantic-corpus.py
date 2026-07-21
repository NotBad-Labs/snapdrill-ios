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


def load_module(name, path):
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {path.name}")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


V3_DIGEST = load_module("v3_digest", ROOT / "v3-digest.py")
JPEG_GRAMMAR = load_module("jpeg_grammar", ROOT / "validate-jpeg-grammar.py")
REFERENCE = load_module(
    "reference_validator",
    ROOT / "reference-validator.py",
)

DIMENSION_CATEGORY = bytes(15) + b"\x01"
DIMENSION_SOURCE = bytes(15) + b"\x02"
DIMENSION_CUSTOM = bytes(15) + b"\x06"
VALUE_HOME = bytes(15) + b"\x14"
ITEM_IMAGE = bytes(15) + b"\x22"
ITEM_PLAIN = bytes(15) + b"\x24"
NEW_ID = bytes(15) + b"\xFE"
EXPECTED_SEMANTIC_MANIFEST_SHA256 = (
    "6991df1ead81c50ba0cdbf214cc8b3afbe73cae58613fc4bf99c7f1eca8deb22"
)


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


def copied_database(output_root, identifier):
    path = output_root / (identifier.lower() + ".sqlite")
    shutil.copyfile(BASELINE, path)
    return path


def require_clean_ddl(path, identifier):
    database = sqlite3.connect(path)
    try:
        database.execute("SELECT COUNT(*) FROM sqlite_schema").fetchone()
    finally:
        database.close()
    if schema_manifest(path) != SCHEMA_MANIFEST:
        raise AssertionError(f"{identifier}: canonical schema changed")


def canonical_schema_rows():
    database = sqlite3.connect(f"file:{BASELINE}?mode=ro", uri=True)
    try:
        return database.execute(
            """
            SELECT type, name, sql
            FROM sqlite_schema
            WHERE sql IS NOT NULL
            ORDER BY type, name
            """
        ).fetchall()
    finally:
        database.close()


CANONICAL_SCHEMA_ROWS = canonical_schema_rows()


def restore_canonical_schema(path, identifier):
    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            """
            SELECT type, name
            FROM sqlite_schema
            WHERE sql IS NOT NULL
            ORDER BY type, name
            """
        ).fetchall()
        expected = [(row[0], row[1]) for row in CANONICAL_SCHEMA_ROWS]
        if observed != expected:
            raise AssertionError(
                f"{identifier}: hostile object inventory drift {observed!r}"
            )
        schema_version = database.execute(
            "PRAGMA schema_version"
        ).fetchone()[0]
    finally:
        database.close()
    statements = ["PRAGMA writable_schema=ON;"]
    for object_type, name, sql in CANONICAL_SCHEMA_ROWS:
        quoted_sql = sql.replace("'", "''")
        quoted_type = object_type.replace("'", "''")
        quoted_name = name.replace("'", "''")
        statements.append(
            "UPDATE sqlite_master "
            f"SET sql='{quoted_sql}' "
            f"WHERE type='{quoted_type}' AND name='{quoted_name}';"
        )
    statements.extend(
        (
            f"PRAGMA schema_version={schema_version + 1};",
            "PRAGMA writable_schema=OFF;",
        )
    )
    subprocess.run(
        ["/usr/bin/sqlite3", "-batch", "-bail", str(path)],
        input="\n".join(statements) + "\n",
        check=True,
        capture_output=True,
        text=True,
    )


def rebuild_table_with_duplicate(
    path,
    identifier,
    table,
    alternate_ddl,
    duplicate_row,
    indexes=(),
    transform=None,
):
    columns = REFERENCE.TABLE_COLUMNS[table]
    database = sqlite3.connect(path)
    try:
        database.execute("PRAGMA foreign_keys=OFF")
        rows = database.execute(
            f'SELECT {", ".join(columns)} FROM "{table}"'
        ).fetchall()
        if transform is not None:
            rows = [transform(row) for row in rows]
        database.execute(f'DROP TABLE "{table}"')
        database.execute(alternate_ddl)
        placeholders = ", ".join("?" for _ in columns)
        database.executemany(
            f'INSERT INTO "{table}" VALUES({placeholders})',
            [*rows, duplicate_row],
        )
        for statement in indexes:
            database.execute(statement)
        database.commit()
        database.execute("VACUUM")
    finally:
        database.close()
    restore_canonical_schema(path, identifier)


def replace_unique_index_with_duplicate(
    path,
    identifier,
    index_name,
    nonunique_ddl,
    insert_sql,
    parameters,
):
    database = sqlite3.connect(path)
    try:
        database.execute("PRAGMA foreign_keys=OFF")
        database.execute(f'DROP INDEX "{index_name}"')
        database.execute(nonunique_ddl)
        database.execute(insert_sql, parameters)
        database.commit()
        database.execute("VACUUM")
    finally:
        database.close()
    restore_canonical_schema(path, identifier)


def result(
    path,
    identifier,
    target_rule,
    digests_recomputed,
    expected_rejection=None,
    m1_policy="A",
    requires_po_decision=None,
):
    require_clean_ddl(path, identifier)
    if expected_rejection is None:
        inventory = REFERENCE.validate_database(path, m1_policy)
        reference_outcome = "accepted:" + inventory.hex()
    else:
        try:
            REFERENCE.validate_database(path, m1_policy)
        except REFERENCE.ValidationError as error:
            if error.code != expected_rejection:
                raise AssertionError(
                    f"{identifier}: expected reference rejection "
                    f"{expected_rejection}, observed {error.code}"
                ) from error
            reference_outcome = "rejected:" + error.code
        else:
            raise AssertionError(
                f"{identifier}: reference validator accepted hostile case"
            )
    case = {
        "case_id": identifier,
        "target_rule": target_rule,
        "dependent_digests_recomputed": digests_recomputed,
        "reference_outcome": reference_outcome,
        "byte_count": path.stat().st_size,
        "sha256": file_sha256(path),
    }
    if requires_po_decision is not None:
        case["requires_po_decision"] = requires_po_decision
    return case


def mutate_and_recompute(
    output_root,
    identifier,
    table,
    updates,
    where,
    parameters,
    target_rule,
    probe_sql,
    probe_parameters,
    expected,
    expected_rejection,
):
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        assignments = ", ".join(f'"{column}"=?' for column in updates)
        cursor = database.execute(
            f'UPDATE "{table}" SET {assignments} WHERE {where}',
            (*updates.values(), *parameters),
        )
        if cursor.rowcount != 1:
            raise AssertionError(f"{identifier}: update count {cursor.rowcount}")
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        observed = database.execute(probe_sql, probe_parameters).fetchone()
    finally:
        database.close()
    if observed != expected:
        raise AssertionError(
            f"{identifier}: expected {expected!r}, observed {observed!r}"
        )
    return result(
        path,
        identifier,
        target_rule,
        True,
        expected_rejection,
    )


def duplicate_identity_cases(output_root):
    cases = []

    identifier = "V3-N-SEMANTIC-DUPLICATE-DIMENSION-ID"
    path = copied_database(output_root, identifier)
    rebuild_table_with_duplicate(
        path,
        identifier,
        "category_dimension",
        """
        CREATE TABLE category_dimension (
            id BLOB NOT NULL,
            name TEXT NOT NULL,
            is_multi_value INTEGER NOT NULL,
            is_built_in INTEGER NOT NULL,
            system_key TEXT,
            sort_order INTEGER NOT NULL,
            icon TEXT NOT NULL,
            record_sha256 BLOB NOT NULL,
            PRIMARY KEY(id, name)
        ) STRICT, WITHOUT ROWID
        """,
        (
            bytes(15) + b"\x05",
            "Duplicate ID",
            0,
            0,
            None,
            99,
            "folder",
            bytes((0xA1,)) * 32,
        ),
        (
            "CREATE UNIQUE INDEX ux_category_dimension_name "
            "ON category_dimension(name)",
            "CREATE UNIQUE INDEX ux_category_dimension_system_key "
            "ON category_dimension(system_key) WHERE system_key IS NOT NULL",
        ),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-category-dimension-primary-identity",
            False,
            "semantic:duplicate:category_dimension.id",
        )
    )

    identifier = "V3-N-SEMANTIC-DUPLICATE-DIMENSION-NAME"
    path = copied_database(output_root, identifier)
    replace_unique_index_with_duplicate(
        path,
        identifier,
        "ux_category_dimension_name",
        "CREATE INDEX ux_category_dimension_name ON category_dimension(name)",
        """
        INSERT INTO category_dimension(
            id, name, is_multi_value, is_built_in, system_key,
            sort_order, icon, record_sha256
        ) VALUES(?, 'Category', 0, 0, NULL, 99, 'folder', ?)
        """,
        (NEW_ID, bytes((0xA2,)) * 32),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-category-dimension-byte-name",
            False,
            "semantic:duplicate:category_dimension.name",
        )
    )

    identifier = "V3-N-SEMANTIC-DUPLICATE-DIMENSION-SYSTEM-KEY"
    path = copied_database(output_root, identifier)
    replace_unique_index_with_duplicate(
        path,
        identifier,
        "ux_category_dimension_system_key",
        "CREATE INDEX ux_category_dimension_system_key "
        "ON category_dimension(system_key) WHERE system_key IS NOT NULL",
        """
        INSERT INTO category_dimension(
            id, name, is_multi_value, is_built_in, system_key,
            sort_order, icon, record_sha256
        ) VALUES(?, 'Second Source', 0, 1, 'source', 99, 'folder', ?)
        """,
        (NEW_ID, bytes((0xA3,)) * 32),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-built-in-system-key",
            False,
            "semantic:duplicate:category_dimension.system_key",
        )
    )

    identifier = "V3-N-SEMANTIC-DUPLICATE-VALUE-ID"
    path = copied_database(output_root, identifier)
    rebuild_table_with_duplicate(
        path,
        identifier,
        "category_value",
        """
        CREATE TABLE category_value (
            id BLOB NOT NULL,
            dimension_id BLOB NOT NULL,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            created_at_ms INTEGER NOT NULL,
            record_sha256 BLOB NOT NULL,
            PRIMARY KEY(id, dimension_id)
        ) STRICT, WITHOUT ROWID
        """,
        (
            VALUE_HOME,
            DIMENSION_CATEGORY,
            "Duplicate ID",
            "folder",
            "#123456",
            99,
            1_720_000_099_000,
            bytes((0xA4,)) * 32,
        ),
        (
            "CREATE UNIQUE INDEX ux_category_value_dimension_name "
            "ON category_value(dimension_id, name)",
        ),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-category-value-primary-identity",
            False,
            "semantic:duplicate:category_value.id",
        )
    )

    identifier = "V3-N-SEMANTIC-DUPLICATE-VALUE-DIMENSION-NAME"
    path = copied_database(output_root, identifier)
    replace_unique_index_with_duplicate(
        path,
        identifier,
        "ux_category_value_dimension_name",
        "CREATE INDEX ux_category_value_dimension_name "
        "ON category_value(dimension_id, name)",
        """
        INSERT INTO category_value(
            id, dimension_id, name, icon, color_hex, sort_order,
            created_at_ms, record_sha256
        ) VALUES(?, ?, 'Home', 'folder', '#123456', 99, 1720000099000, ?)
        """,
        (NEW_ID, DIMENSION_CUSTOM, bytes((0xA5,)) * 32),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-category-value-byte-name-within-dimension",
            False,
            "semantic:duplicate:category_value.dimension_name",
        )
    )

    identifier = "V3-N-SEMANTIC-DUPLICATE-ITEM-ID"
    path = copied_database(output_root, identifier)
    rebuild_table_with_duplicate(
        path,
        identifier,
        "library_item",
        """
        CREATE TABLE library_item (
            id BLOB NOT NULL,
            content TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            last_reviewed_at_ms INTEGER,
            next_review_at_ms INTEGER,
            ease_factor REAL NOT NULL,
            interval_days INTEGER NOT NULL,
            repetitions INTEGER NOT NULL,
            answer_text TEXT,
            record_sha256 BLOB NOT NULL,
            PRIMARY KEY(id, content)
        ) STRICT, WITHOUT ROWID
        """,
        (
            ITEM_PLAIN,
            "Duplicate ID",
            1_720_000_099_000,
            None,
            None,
            2.5,
            0,
            0,
            None,
            bytes((0xA6,)) * 32,
        ),
        transform=lambda row: (
            row[0],
            "" if row[1] is None else row[1],
            *row[2:],
        ),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-library-item-primary-identity",
            False,
            "semantic:duplicate:library_item.id",
        )
    )

    identifier = "V3-N-SEMANTIC-DUPLICATE-ITEM-VALUE-LINK"
    path = copied_database(output_root, identifier)
    rebuild_table_with_duplicate(
        path,
        identifier,
        "item_category_value",
        """
        CREATE TABLE item_category_value (
            item_id BLOB NOT NULL,
            value_id BLOB NOT NULL,
            record_sha256 BLOB NOT NULL,
            PRIMARY KEY(item_id, value_id, record_sha256)
        ) STRICT, WITHOUT ROWID
        """,
        (
            ITEM_IMAGE,
            bytes(15) + b"\x11",
            bytes((0xA7,)) * 32,
        ),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-item-value-primary-identity",
            False,
            "semantic:duplicate:item_category_value.primary_key",
        )
    )

    identifier = "V3-N-SEMANTIC-DUPLICATE-IMAGE-ROLE"
    path = copied_database(output_root, identifier)
    replace_unique_index_with_duplicate(
        path,
        identifier,
        "ux_item_image_item_role",
        "CREATE INDEX ux_item_image_item_role ON item_image(item_id, role)",
        """
        INSERT INTO item_image(
            blob_id, item_id, role, media_type, pixel_width, pixel_height,
            byte_count, content_sha256, record_sha256, jpeg_bytes
        )
        SELECT 5, item_id, role, media_type, pixel_width, pixel_height,
               byte_count, content_sha256, record_sha256, jpeg_bytes
        FROM item_image WHERE blob_id=1
        """,
        (),
    )
    cases.append(
        result(
            path,
            identifier,
            "duplicate-image-role-within-item",
            False,
            "semantic:duplicate:item_image.item_role",
        )
    )

    identifier = "V3-P-SEMANTIC-IMAGE-BLOB-ID-ROWID-IDENTITY"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        try:
            database.execute(
                """
                INSERT INTO item_image(
                    blob_id, item_id, role, media_type, pixel_width,
                    pixel_height, byte_count, content_sha256,
                    record_sha256, jpeg_bytes
                )
                SELECT blob_id, item_id, role, media_type, pixel_width,
                       pixel_height, byte_count, content_sha256,
                       record_sha256, jpeg_bytes
                FROM item_image WHERE blob_id=1
                """
            )
        except sqlite3.IntegrityError:
            database.rollback()
        else:
            raise AssertionError(f"{identifier}: duplicate rowid was inserted")
    finally:
        database.close()
        path.unlink()
    cases.append(
        {
            "case_id": identifier,
            "target_rule": "INTEGER-PRIMARY-KEY-is-rowid-identity",
            "dependent_digests_recomputed": False,
            "reference_outcome": "unconstructible:SQLITE_CONSTRAINT_PRIMARYKEY",
            "construction": "sqlite-rowid-alias-engine-invariant",
        }
    )
    return cases


def writer_label_nul_case(output_root):
    identifier = "V3-P-SEMANTIC-WRITER-LABEL-NUL"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute(
            """
            UPDATE backup_root
            SET writer_marketing_version=?, writer_build=?
            """,
            ("1.0\0beta", "42\0local"),
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            """
            SELECT hex(CAST(writer_marketing_version AS BLOB)),
                   hex(CAST(writer_build AS BLOB))
            FROM backup_root
            """
        ).fetchone()
    finally:
        database.close()
    if observed != ("312E300062657461", "3432006C6F63616C"):
        raise AssertionError(f"{identifier}: NUL label bytes changed")
    return result(path, identifier, "opaque-writer-label-byte-preservation", True)


def empty_item_main_image_case(output_root):
    identifier = "V3-P-SEMANTIC-EMPTY-ITEM-WITH-MAIN-IMAGE"
    path = copied_database(output_root, identifier)
    jpeg = (ROOT / "canonical-rgb-sof0-2x2.jpg").read_bytes()
    database = sqlite3.connect(path)
    try:
        database.execute(
            """
            INSERT INTO library_item VALUES(
                ?, '', 1720000070000, NULL, NULL, 2.5, 0, 0, '', ?
            )
            """,
            (bytes(15) + b"\x25", bytes(32)),
        )
        database.execute(
            """
            INSERT INTO item_image VALUES(
                5, ?, 0, 'image/jpeg', 2, 2, ?, ?, ?, ?
            )
            """,
            (
                bytes(15) + b"\x25",
                len(jpeg),
                hashlib.sha256(jpeg).digest(),
                bytes(32),
                jpeg,
            ),
        )
        database.execute(
            """
            UPDATE backup_root
            SET item_count=item_count+1,
                image_count=image_count+1,
                image_byte_count=image_byte_count+?
            """,
            (len(jpeg),),
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            """
            SELECT hex(record_sha256),
                   (SELECT COUNT(*) FROM item_image
                    WHERE item_id=library_item.id AND role=0)
            FROM library_item WHERE id=?
            """,
            (bytes(15) + b"\x25",),
        ).fetchone()
    finally:
        database.close()
    if observed != (
        "AF0ACDE4B154D286232862C495EAAEE7B9413203E91A15A89B36BFA2D2D6FF00",
        1,
    ):
        raise AssertionError(f"{identifier}: empty-item closure drift {observed!r}")
    return result(path, identifier, "empty-content-main-image-semantic-closure", True)


def reversed_image_order_case(output_root):
    identifier = "V3-P-SEMANTIC-IMAGE-BLOB-ID-REVERSED"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute("UPDATE item_image SET blob_id=blob_id+100")
        database.execute(
            """
            UPDATE item_image
            SET blob_id=CASE blob_id
                WHEN 101 THEN 4
                WHEN 102 THEN 3
                WHEN 103 THEN 2
                WHEN 104 THEN 1
            END
            """
        )
        database.commit()
    finally:
        database.close()
    inventory = V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        blob_order = database.execute(
            """
            SELECT blob_id FROM item_image ORDER BY item_id, role
            """
        ).fetchall()
    finally:
        database.close()
    if blob_order != [(4,), (3,), (2,), (1,)]:
        raise AssertionError(f"{identifier}: image row order was not reversed")
    if inventory.hex() != (
        "1b9a3235235ffa39f71c7bd4d11a592ae7692ef468fecd59333ca3fc62cb872f"
    ):
        raise AssertionError(f"{identifier}: semantic inventory changed")
    return result(path, identifier, "image-digest-order-excludes-blob-id", True)


def root_count_cases(output_root):
    definitions = {
        "item_count": "library_item",
        "dimension_count": "category_dimension",
        "value_count": "category_value",
        "item_value_count": "item_category_value",
        "image_count": "item_image",
        "image_byte_count": None,
    }
    cases = []
    for column, table in definitions.items():
        identifier = f"V3-N-SEMANTIC-ROOT-{column.replace('_', '-').upper()}"
        path = copied_database(output_root, identifier)
        database = sqlite3.connect(path)
        try:
            database.execute(
                f'UPDATE backup_root SET "{column}" = "{column}" + 1'
            )
            database.commit()
        finally:
            database.close()
        V3_DIGEST.recompute_database(path)
        database = sqlite3.connect(path)
        try:
            declared = database.execute(
                f'SELECT "{column}" FROM backup_root'
            ).fetchone()[0]
            if table is None:
                actual = 0
                for (byte_count,) in database.execute(
                    "SELECT byte_count FROM item_image ORDER BY blob_id"
                ):
                    actual = REFERENCE.checked_add(actual, byte_count)
            else:
                actual = database.execute(
                    f'SELECT COUNT(*) FROM "{table}"'
                ).fetchone()[0]
        finally:
            database.close()
        if declared != actual + 1:
            raise AssertionError(f"{identifier}: count mismatch not preserved")
        expected = (
            "semantic:root-image-byte-count"
            if column == "image_byte_count"
            else f"semantic:root-{column}"
        )
        cases.append(
            result(
                path,
                identifier,
                "root-checked-inventory-equality",
                True,
                expected,
            )
        )
    return cases


def root_boundary_cases(output_root):
    cases = []

    identifier = "V3-N-SEMANTIC-ROOT-ZERO-ROWS"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute("DELETE FROM backup_root")
        database.commit()
    finally:
        database.close()
    cases.append(
        result(
            path,
            identifier,
            "exactly-one-root-row",
            False,
            "check:backup_root.row_count",
        )
    )

    identifier = "V3-N-SEMANTIC-ROOT-HUGE-COUNT"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute(
            "UPDATE backup_root SET item_count=?",
            ((1 << 63) - 1,),
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    cases.append(
        result(
            path,
            identifier,
            "root-count-is-not-allocation-hint",
            True,
            "semantic:root-item_count",
        )
    )

    identifier = "V3-N-SEMANTIC-CHECKED-OVERFLOW"
    try:
        REFERENCE.checked_add((1 << 63) - 1, 1)
    except REFERENCE.ValidationError as error:
        if error.code != "semantic:checked-overflow":
            raise AssertionError(
                f"{identifier}: unexpected rejection {error.code}"
            ) from error
    else:
        raise AssertionError(f"{identifier}: overflow helper accepted")
    cases.append(
        {
            "case_id": identifier,
            "target_rule": "overflow-reporting-Int64-accumulation",
            "dependent_digests_recomputed": False,
            "reference_outcome": "rejected:semantic:checked-overflow",
            "construction": "reference-helper-boundary",
        }
    )
    return cases


def missing_builtin_case(output_root):
    identifier = "V3-N-SEMANTIC-BUILTIN-MISSING"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute("PRAGMA foreign_keys=OFF")
        database.execute(
            "DELETE FROM category_dimension WHERE id=?",
            (DIMENSION_SOURCE,),
        )
        database.execute(
            "UPDATE backup_root SET dimension_count=dimension_count-1"
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            """
            SELECT COUNT(*)
            FROM category_dimension
            WHERE system_key IN ('category', 'source', 'level', 'tag')
            """
        ).fetchone()
    finally:
        database.close()
    if observed != (3,):
        raise AssertionError(f"{identifier}: expected three built-ins")
    return result(
        path,
        identifier,
        "exact-built-in-inventory",
        True,
        "semantic:built-in-inventory",
    )


def content_closure_case(output_root):
    cases = []
    for identifier, value, expected_length in (
        ("V3-N-SEMANTIC-CONTENT-EMPTY-NO-MAIN", "", 0),
        ("V3-N-SEMANTIC-CONTENT-NULL-NO-MAIN", None, None),
    ):
        cases.append(
            mutate_and_recompute(
                output_root,
                identifier,
                "library_item",
                {"content": value},
                "id=?",
                (ITEM_PLAIN,),
                "nonempty-content-or-main-image",
                """
                SELECT length(CAST(content AS BLOB)),
                       (SELECT COUNT(*) FROM item_image
                        WHERE item_id=library_item.id AND role=0)
                FROM library_item WHERE id=?
                """,
                (ITEM_PLAIN,),
                (expected_length, 0),
                "semantic:content-or-main-image",
            )
        )
    return cases


def dangling_cases(output_root):
    definitions = [
        (
            "V3-N-SEMANTIC-DANGLING-VALUE-DIMENSION",
            "category_value",
            {"dimension_id": NEW_ID},
            "id=?",
            (VALUE_HOME,),
            "SELECT COUNT(*) FROM pragma_foreign_key_check",
            (1,),
        ),
        (
            "V3-N-SEMANTIC-DANGLING-JOIN-ITEM",
            "item_category_value",
            {"item_id": NEW_ID},
            "item_id=? AND value_id=?",
            (ITEM_IMAGE, bytes(15) + b"\x11"),
            "SELECT COUNT(*) FROM pragma_foreign_key_check",
            (1,),
        ),
        (
            "V3-N-SEMANTIC-DANGLING-JOIN-VALUE",
            "item_category_value",
            {"value_id": NEW_ID},
            "item_id=? AND value_id=?",
            (ITEM_IMAGE, bytes(15) + b"\x11"),
            "SELECT COUNT(*) FROM pragma_foreign_key_check",
            (1,),
        ),
        (
            "V3-N-SEMANTIC-DANGLING-IMAGE-ITEM",
            "item_image",
            {"item_id": NEW_ID},
            "blob_id=1",
            (),
            "SELECT COUNT(*) FROM pragma_foreign_key_check",
            (1,),
        ),
    ]
    cases = []
    for (
        identifier,
        table,
        updates,
        where,
        parameters,
        probe_sql,
        expected,
    ) in definitions:
        cases.append(
            mutate_and_recompute(
                output_root,
                identifier,
                table,
                updates,
                where,
                parameters,
                "foreign-key-closure",
                probe_sql,
                (),
                expected,
                "semantic:foreign-key-closure",
            )
        )
    return cases


def relationship_id_length_cases(output_root):
    definitions = [
        (
            "V3-N-SEMANTIC-JOIN-ITEM-ID-LENGTH",
            "item_category_value",
            {"item_id": bytes(15)},
            "item_id=? AND value_id=?",
            (ITEM_IMAGE, bytes(15) + b"\x11"),
            "SELECT length(item_id) FROM item_category_value WHERE value_id=?",
            (bytes(15) + b"\x11",),
            "check:item_category_value.item_id",
        ),
        (
            "V3-N-SEMANTIC-JOIN-VALUE-ID-LENGTH",
            "item_category_value",
            {"value_id": bytes(15)},
            "item_id=? AND value_id=?",
            (ITEM_IMAGE, bytes(15) + b"\x11"),
            "SELECT length(value_id) FROM item_category_value WHERE item_id=?",
            (ITEM_IMAGE,),
            "check:item_category_value.value_id",
        ),
        (
            "V3-N-SEMANTIC-IMAGE-ITEM-ID-LENGTH",
            "item_image",
            {"item_id": bytes(15)},
            "blob_id=1",
            (),
            "SELECT length(item_id) FROM item_image WHERE blob_id=1",
            (),
            "check:item_image.item_id",
        ),
    ]
    cases = []
    for (
        identifier,
        table,
        updates,
        where,
        parameters,
        probe_sql,
        probe_parameters,
        expected_rejection,
    ) in definitions:
        path = copied_database(output_root, identifier)
        database = sqlite3.connect(path)
        try:
            assignments = ", ".join(f'"{column}"=?' for column in updates)
            database.execute(
                f'UPDATE "{table}" SET {assignments} WHERE {where}',
                (*updates.values(), *parameters),
            )
            database.commit()
            observed = database.execute(
                probe_sql,
                probe_parameters,
            ).fetchone()
        finally:
            database.close()
        if observed != (15,):
            raise AssertionError(f"{identifier}: ID length mutation failed")
        cases.append(
            result(
                path,
                identifier,
                "relationship-uuid-length-before-foreign-key-check",
                False,
                expected_rejection,
            )
        )
    return cases


def single_value_multiplicity_case(output_root):
    identifier = "V3-N-SEMANTIC-M1A-SINGLE-VALUE-MULTIPLICITY"
    path = copied_database(output_root, identifier)
    new_value = bytes(15) + b"\x15"
    database = sqlite3.connect(path)
    try:
        database.execute(
            """
            INSERT INTO category_value(
                id, dimension_id, name, icon, color_hex, sort_order,
                created_at_ms, record_sha256
            ) VALUES(?, ?, 'Second', 'folder', '#445566', 1, 1720000005000, ?)
            """,
            (new_value, DIMENSION_CATEGORY, bytes(32)),
        )
        database.execute(
            """
            INSERT INTO item_category_value(item_id, value_id, record_sha256)
            VALUES(?, ?, ?)
            """,
            (ITEM_IMAGE, new_value, bytes(32)),
        )
        database.execute(
            """
            UPDATE backup_root
            SET value_count=value_count+1,
                item_value_count=item_value_count+1
            """
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            """
            SELECT COUNT(*)
            FROM item_category_value AS item_value
            JOIN category_value AS value ON value.id=item_value.value_id
            WHERE item_value.item_id=? AND value.dimension_id=?
            """,
            (ITEM_IMAGE, DIMENSION_CATEGORY),
        ).fetchone()
    finally:
        database.close()
    if observed != (2,):
        raise AssertionError(f"{identifier}: expected two single-value links")
    return result(
        path,
        identifier,
        "M1-A-single-value-multiplicity",
        True,
        "semantic:M1-A-single-value-multiplicity",
        m1_policy="A",
        requires_po_decision="M1-A",
    )


def jpeg_cases(output_root):
    cases = []
    identifier = "V3-N-SEMANTIC-JPEG-APP1"
    path = copied_database(output_root, identifier)
    original = (ROOT / "canonical-rgb-sof0-2x2.jpg").read_bytes()
    fixed_length = len(JPEG_GRAMMAR.FIXED_JFIF)
    hostile = (
        original[:fixed_length]
        + b"\xFF\xE1\x00\x02"
        + original[fixed_length:]
    )
    database = sqlite3.connect(path)
    try:
        database.execute(
            """
            UPDATE item_image
            SET jpeg_bytes=?, byte_count=?
            WHERE blob_id=1
            """,
            (hostile, len(hostile)),
        )
        database.execute(
            """
            UPDATE backup_root
            SET image_byte_count=image_byte_count+?
            """,
            (len(hostile) - len(original),),
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    try:
        JPEG_GRAMMAR.validate_jpeg(hostile)
    except JPEG_GRAMMAR.JPEGError as error:
        if "forbidden marker FFE1" not in str(error):
            raise
    else:
        raise AssertionError(f"{identifier}: hostile JPEG accepted")
    cases.append(
        result(
            path,
            identifier,
            "normalized-JPEG-grammar",
            True,
            "jpeg:grammar",
        )
    )

    identifier = "V3-N-SEMANTIC-JPEG-DIMENSION-MISMATCH"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute(
            "UPDATE item_image SET pixel_width=1 WHERE blob_id=1"
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    parsed = JPEG_GRAMMAR.validate_jpeg(original)
    database = sqlite3.connect(path)
    try:
        stored = database.execute(
            "SELECT pixel_width, pixel_height FROM item_image WHERE blob_id=1"
        ).fetchone()
    finally:
        database.close()
    if stored != (1, 2) or (parsed["width"], parsed["height"]) != (2, 2):
        raise AssertionError(f"{identifier}: dimension mismatch absent")
    cases.append(
        result(
            path,
            identifier,
            "JPEG-row-dimension-equality",
            True,
            "jpeg:dimension-match",
        )
    )

    identifier = "V3-N-SEMANTIC-JPEG-CONTENT-SHA"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute(
            "UPDATE item_image SET content_sha256=? WHERE blob_id=1",
            (bytes(32),),
        )
        database.commit()
        stored, payload = database.execute(
            "SELECT content_sha256, jpeg_bytes FROM item_image WHERE blob_id=1"
        ).fetchone()
    finally:
        database.close()
    if stored == hashlib.sha256(payload).digest():
        raise AssertionError(f"{identifier}: content digest still matches")
    cases.append(
        result(
            path,
            identifier,
            "JPEG-content-SHA-256",
            False,
            "digest:item_image.content_sha256",
        )
    )
    return cases


def corrupt_digest_cases(output_root):
    definitions = [
        (
            "V3-N-SEMANTIC-DIMENSION-RECORD-SHA",
            "category_dimension",
            "id=?",
            (bytes(15) + b"\x05",),
        ),
        (
            "V3-N-SEMANTIC-VALUE-RECORD-SHA",
            "category_value",
            "id=?",
            (VALUE_HOME,),
        ),
        (
            "V3-N-SEMANTIC-ITEM-RECORD-SHA",
            "library_item",
            "id=?",
            (ITEM_PLAIN,),
        ),
        (
            "V3-N-SEMANTIC-JOIN-RECORD-SHA",
            "item_category_value",
            "item_id=? AND value_id=?",
            (ITEM_IMAGE, bytes(15) + b"\x11"),
        ),
        (
            "V3-N-SEMANTIC-IMAGE-RECORD-SHA",
            "item_image",
            "blob_id=1",
            (),
        ),
    ]
    cases = []
    for identifier, table, where, parameters in definitions:
        path = copied_database(output_root, identifier)
        database = sqlite3.connect(path)
        try:
            database.execute(
                f'UPDATE "{table}" SET record_sha256=? WHERE {where}',
                (bytes(32), *parameters),
            )
            database.commit()
            observed = database.execute(
                f'SELECT record_sha256 FROM "{table}" WHERE {where}',
                parameters,
            ).fetchone()
        finally:
            database.close()
        if observed != (bytes(32),):
            raise AssertionError(f"{identifier}: record digest mutation failed")
        cases.append(
            result(
                path,
                identifier,
                "record-SHA-256",
                False,
                f"digest:{table}.record_sha256",
            )
        )

    identifier = "V3-N-SEMANTIC-ROOT-INVENTORY-SHA"
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute(
            "UPDATE backup_root SET inventory_sha256=?",
            (bytes(32),),
        )
        database.commit()
    finally:
        database.close()
    cases.append(
        result(
            path,
            identifier,
            "inventory-SHA-256",
            False,
            "digest:backup_root.inventory_sha256",
        )
    )
    return cases


def utf8_cases(output_root):
    content_vectors = {
        "V3-N-UTF8-TRUNC": "c3",
        "V3-N-UTF8-OVERLONG": "c080",
        "V3-N-UTF8-SURROGATE": "eda080",
        "V3-N-UTF8-REPLACEMENT-FALLBACK": "f4908080",
    }
    targets = [
        (
            identifier,
            payload_hex,
            "library_item",
            "content",
            "id=X'00000000000000000000000000000024'",
        )
        for identifier, payload_hex in content_vectors.items()
    ]
    targets.extend(
        [
            (
                "V3-N-UTF8-ROOT-ARTIFACT-KIND",
                "c3",
                "backup_root",
                "artifact_kind",
                "singleton=1",
            ),
            (
                "V3-N-UTF8-ROOT-MARKETING-VERSION",
                "c3",
                "backup_root",
                "writer_marketing_version",
                "singleton=1",
            ),
            (
                "V3-N-UTF8-ROOT-WRITER-BUILD",
                "c3",
                "backup_root",
                "writer_build",
                "singleton=1",
            ),
            (
                "V3-N-UTF8-ROOT-DIGEST-ALGORITHM",
                "c3",
                "backup_root",
                "digest_algorithm",
                "singleton=1",
            ),
            (
                "V3-N-UTF8-DIMENSION-NAME",
                "c3",
                "category_dimension",
                "name",
                "id=X'00000000000000000000000000000005'",
            ),
            (
                "V3-N-UTF8-DIMENSION-SYSTEM-KEY",
                "c3",
                "category_dimension",
                "system_key",
                "id=X'00000000000000000000000000000001'",
            ),
            (
                "V3-N-UTF8-DIMENSION-ICON",
                "c3",
                "category_dimension",
                "icon",
                "id=X'00000000000000000000000000000005'",
            ),
            (
                "V3-N-UTF8-VALUE-NAME",
                "c3",
                "category_value",
                "name",
                "id=X'00000000000000000000000000000014'",
            ),
            (
                "V3-N-UTF8-VALUE-ICON",
                "c3",
                "category_value",
                "icon",
                "id=X'00000000000000000000000000000014'",
            ),
            (
                "V3-N-UTF8-VALUE-COLOR",
                "c3",
                "category_value",
                "color_hex",
                "id=X'00000000000000000000000000000014'",
            ),
            (
                "V3-N-UTF8-ITEM-ANSWER",
                "c3",
                "library_item",
                "answer_text",
                "id=X'00000000000000000000000000000021'",
            ),
            (
                "V3-N-UTF8-IMAGE-MEDIA-TYPE",
                "c3",
                "item_image",
                "media_type",
                "blob_id=1",
            ),
        ]
    )
    cases = []
    for identifier, payload_hex, table, column, where in targets:
        payload = bytes.fromhex(payload_hex)
        try:
            payload.decode("utf-8", errors="strict")
        except UnicodeDecodeError:
            pass
        else:
            raise AssertionError(f"{identifier}: vector is valid UTF-8")
        if "\uFFFD" not in payload.decode("utf-8", errors="replace"):
            raise AssertionError(f"{identifier}: replacement fallback not exercised")

        path = copied_database(output_root, identifier)
        sql = (
            "PRAGMA ignore_check_constraints=ON;"
            f'UPDATE "{table}" '
            f'SET "{column}"=CAST(X\'{payload_hex}\' AS TEXT) '
            f"WHERE {where};"
        )
        subprocess.run(
            ["/usr/bin/sqlite3", "-batch", "-bail", str(path), sql],
            check=True,
            capture_output=True,
            text=True,
        )
        probe = subprocess.run(
            [
                "/usr/bin/sqlite3",
                "-batch",
                "-noheader",
                str(path),
                (
                    f'SELECT lower(hex(CAST("{column}" AS BLOB))) '
                    f'FROM "{table}" WHERE {where};'
                ),
            ],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.strip()
        if probe != payload_hex:
            raise AssertionError(f"{identifier}: stored bytes changed")
        cases.append(
            result(
                path,
                identifier,
                "strict-UTF-8-before-check-or-digest",
                False,
                f"utf8:{table}.{column}",
            )
        )

    identifier = "V3-P-UTF8-UFFFD"
    payload = bytes.fromhex("efbfbd")
    if payload.decode("utf-8").encode("utf-8") != payload:
        raise AssertionError(f"{identifier}: valid U+FFFD did not round trip")
    path = copied_database(output_root, identifier)
    database = sqlite3.connect(path)
    try:
        database.execute(
            "UPDATE library_item SET content=? WHERE id=?",
            ("\uFFFD", ITEM_PLAIN),
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            """
            SELECT lower(hex(CAST(content AS BLOB)))
            FROM library_item WHERE id=?
            """,
            (ITEM_PLAIN,),
        ).fetchone()
    finally:
        database.close()
    if observed != ("efbfbd",):
        raise AssertionError(f"{identifier}: stored bytes changed")
    cases.append(
        result(
            path,
            identifier,
            "valid-U+FFFD-preservation",
            True,
        )
    )
    return cases


def canonical_name_case(output_root):
    identifier = "V3-P-TAXONOMY-CANONICAL-NAMES-WIRE"
    path = copied_database(output_root, identifier)
    first_id = bytes(15) + b"\x16"
    second_id = bytes(15) + b"\x17"
    database = sqlite3.connect(path)
    try:
        database.executemany(
            """
            INSERT INTO category_value(
                id, dimension_id, name, icon, color_hex, sort_order,
                created_at_ms, record_sha256
            ) VALUES(?, ?, ?, 'tag', '#123456', ?, ?, ?)
            """,
            [
                (
                    first_id,
                    DIMENSION_CUSTOM,
                    "\u00E9",
                    1,
                    1_720_000_005_000,
                    bytes(32),
                ),
                (
                    second_id,
                    DIMENSION_CUSTOM,
                    "e\u0301",
                    2,
                    1_720_000_006_000,
                    bytes(32),
                ),
            ],
        )
        database.execute(
            "UPDATE backup_root SET value_count=value_count+2"
        )
        database.commit()
    finally:
        database.close()
    V3_DIGEST.recompute_database(path)
    database = sqlite3.connect(path)
    try:
        observed = database.execute(
            """
            SELECT lower(hex(CAST(name AS BLOB)))
            FROM category_value
            WHERE id IN (?, ?)
            ORDER BY id
            """,
            (first_id, second_id),
        ).fetchall()
    finally:
        database.close()
    if observed != [("c3a9",), ("65cc81",)]:
        raise AssertionError(f"{identifier}: canonical names merged or changed")
    return result(path, identifier, "byte-distinct-Unicode-names", True)


def generate_corpus(output_root):
    cases = []
    cases.extend(duplicate_identity_cases(output_root))
    cases.append(writer_label_nul_case(output_root))
    cases.append(empty_item_main_image_case(output_root))
    cases.append(reversed_image_order_case(output_root))
    cases.extend(root_count_cases(output_root))
    cases.extend(root_boundary_cases(output_root))
    cases.append(missing_builtin_case(output_root))
    cases.extend(content_closure_case(output_root))
    cases.extend(dangling_cases(output_root))
    cases.extend(relationship_id_length_cases(output_root))
    cases.append(single_value_multiplicity_case(output_root))
    cases.extend(jpeg_cases(output_root))
    cases.extend(corrupt_digest_cases(output_root))
    cases.extend(utf8_cases(output_root))
    cases.append(canonical_name_case(output_root))
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
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-semantic-a-") as first:
        with tempfile.TemporaryDirectory(prefix="snapdrill-v3-semantic-b-") as second:
            first_cases = generate_corpus(pathlib.Path(first))
            second_cases = generate_corpus(pathlib.Path(second))
            if semantic_manifest(first_cases) != semantic_manifest(second_cases):
                raise AssertionError("semantic corpus manifest is nondeterministic")
            first_files = [
                (case["case_id"], case["byte_count"], case["sha256"])
                for case in first_cases
                if "sha256" in case
            ]
            second_files = [
                (case["case_id"], case["byte_count"], case["sha256"])
                for case in second_cases
                if "sha256" in case
            ]
            if first_files != second_files:
                raise AssertionError("semantic corpus files are nondeterministic")
            manifest_bytes = json.dumps(
                semantic_manifest(first_cases),
                separators=(",", ":"),
                sort_keys=True,
            ).encode()
            manifest_sha256 = hashlib.sha256(manifest_bytes).hexdigest()
            if manifest_sha256 != EXPECTED_SEMANTIC_MANIFEST_SHA256:
                raise AssertionError(
                    "semantic corpus manifest changed: "
                    f"expected {EXPECTED_SEMANTIC_MANIFEST_SHA256}, "
                    f"observed {manifest_sha256}"
                )
            print(
                json.dumps(
                    {
                        "case_count": len(first_cases),
                        "candidate_sha256": file_sha256(
                            ROOT / "backup-wire-v3-candidate.md"
                        ),
                        "semantic_manifest_sha256": manifest_sha256,
                        "python_sqlite_version": sqlite3.sqlite_version,
                        "sqlite_cli_version": subprocess.run(
                            ["/usr/bin/sqlite3", "--version"],
                            check=True,
                            capture_output=True,
                            text=True,
                        ).stdout.split()[0],
                    },
                    sort_keys=True,
                )
            )
    print("PASS deterministic SQLite semantic corpus")


if __name__ == "__main__":
    main()
