#!/usr/bin/env python3

import hashlib
import importlib.util
import json
import os
import pathlib
import shutil
import sqlite3
import struct
import subprocess
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
BASELINE = ROOT / "iOS-26.5-full-v3.sqlite"
CANONICAL_SCHEMA_MANIFEST = (ROOT / "schema-manifest.txt").read_bytes()
PAGE_SIZE = 4_096
APPLICATION_ID = 707_275_168
USER_VERSION = 3
SIDECAR_SUFFIXES = ("-wal", "-shm", "-journal")
EXPECTED_SEMANTIC_MANIFEST_SHA256 = (
    "95b9c2a599be186b978281667f22917bd30763345832c0eae2b4c53441508ec5"
)

REFERENCE_PATH = ROOT / "reference-validator.py"
REFERENCE_SPEC = importlib.util.spec_from_file_location(
    "structure_reference_validator",
    REFERENCE_PATH,
)
if REFERENCE_SPEC is None or REFERENCE_SPEC.loader is None:
    raise RuntimeError("cannot load reference validator")
REFERENCE = importlib.util.module_from_spec(REFERENCE_SPEC)
REFERENCE_SPEC.loader.exec_module(REFERENCE)


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(256 * 1_024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def uint32(data, offset):
    return struct.unpack(">I", data[offset : offset + 4])[0]


def replace_bytes(data, offset, replacement):
    return data[:offset] + replacement + data[offset + len(replacement) :]


def header_failure(data):
    if len(data) < 100:
        return "minimum-header-length"
    if data[:16] != b"SQLite format 3\0":
        return "sqlite-magic"

    encoded_page_size = struct.unpack(">H", data[16:18])[0]
    page_size = 65_536 if encoded_page_size == 1 else encoded_page_size
    if page_size != PAGE_SIZE:
        return "page-size"
    if data[18] != 1:
        return "write-version"
    if data[19] != 1:
        return "read-version"
    if data[20] != 0:
        return "reserved-bytes"
    if data[21:24] != bytes((64, 32, 32)):
        return "payload-fractions"
    if uint32(data, 32) != 0:
        return "freelist-trunk"
    if uint32(data, 36) != 0:
        return "freelist-count"
    if uint32(data, 44) != 4:
        return "schema-format"
    if uint32(data, 52) != 0:
        return "auto-vacuum-root"
    if uint32(data, 56) != 1:
        return "utf8-encoding"
    if uint32(data, 60) != USER_VERSION:
        return "user-version"
    if uint32(data, 64) != 0:
        return "incremental-vacuum"
    if uint32(data, 68) != APPLICATION_ID:
        return "application-id"
    if data[72:92] != bytes(20):
        return "header-expansion"

    page_count = uint32(data, 28)
    if page_count == 0:
        return "positive-page-count"
    if len(data) != page_count * PAGE_SIZE:
        return "page-count-file-size"
    if data[24:28] != data[92:96]:
        return "change-counter-version-valid-for"
    return None


def header_definitions(baseline):
    page_count = uint32(baseline, 28)
    counter = uint32(baseline, 24)
    return [
        (
            "V3-N-HEADER-TRUNCATED",
            "minimum-header-length",
            baseline[:99],
        ),
        (
            "V3-N-HEADER-MAGIC",
            "sqlite-magic",
            replace_bytes(baseline, 0, b"NotSQLiteFormat!"),
        ),
        (
            "V3-N-HEADER-PAGE-SIZE",
            "page-size",
            replace_bytes(baseline, 16, struct.pack(">H", 8_192)),
        ),
        (
            "V3-N-HEADER-WRITE-VERSION",
            "write-version",
            replace_bytes(baseline, 18, b"\x02"),
        ),
        (
            "V3-N-HEADER-READ-VERSION",
            "read-version",
            replace_bytes(baseline, 19, b"\x02"),
        ),
        (
            "V3-N-HEADER-RESERVED-BYTES",
            "reserved-bytes",
            replace_bytes(baseline, 20, b"\x01"),
        ),
        (
            "V3-N-HEADER-PAYLOAD-FRACTIONS",
            "payload-fractions",
            replace_bytes(baseline, 21, b"\x3F"),
        ),
        (
            "V3-N-HEADER-FREELIST-TRUNK",
            "freelist-trunk",
            replace_bytes(baseline, 32, struct.pack(">I", 1)),
        ),
        (
            "V3-N-HEADER-FREELIST-COUNT",
            "freelist-count",
            replace_bytes(baseline, 36, struct.pack(">I", 1)),
        ),
        (
            "V3-N-HEADER-SCHEMA-FORMAT",
            "schema-format",
            replace_bytes(baseline, 44, struct.pack(">I", 3)),
        ),
        (
            "V3-N-HEADER-AUTO-VACUUM",
            "auto-vacuum-root",
            replace_bytes(baseline, 52, struct.pack(">I", 1)),
        ),
        (
            "V3-N-HEADER-ENCODING",
            "utf8-encoding",
            replace_bytes(baseline, 56, struct.pack(">I", 2)),
        ),
        (
            "V3-N-HEADER-USER-VERSION",
            "user-version",
            replace_bytes(baseline, 60, struct.pack(">I", USER_VERSION + 1)),
        ),
        (
            "V3-N-HEADER-INCREMENTAL-VACUUM",
            "incremental-vacuum",
            replace_bytes(baseline, 64, struct.pack(">I", 1)),
        ),
        (
            "V3-N-HEADER-APPLICATION-ID",
            "application-id",
            replace_bytes(baseline, 68, struct.pack(">I", APPLICATION_ID + 1)),
        ),
        (
            "V3-N-HEADER-EXPANSION",
            "header-expansion",
            replace_bytes(baseline, 72, b"\x01"),
        ),
        (
            "V3-N-HEADER-PAGE-COUNT-ZERO",
            "positive-page-count",
            replace_bytes(baseline, 28, bytes(4)),
        ),
        (
            "V3-N-HEADER-PAGE-COUNT-MISMATCH",
            "page-count-file-size",
            replace_bytes(baseline, 28, struct.pack(">I", page_count + 1)),
        ),
        (
            "V3-N-HEADER-TRAILING-PAGE",
            "page-count-file-size",
            baseline + bytes(PAGE_SIZE),
        ),
        (
            "V3-N-HEADER-COUNTER-MISMATCH",
            "change-counter-version-valid-for",
            replace_bytes(baseline, 92, struct.pack(">I", counter + 1)),
        ),
    ]


def generate_header_cases(output_root):
    baseline = BASELINE.read_bytes()
    if header_failure(baseline) is not None:
        raise AssertionError("physical oracle does not satisfy the header contract")

    cases = []
    for identifier, target_rule, hostile in header_definitions(baseline):
        observed = header_failure(hostile)
        if observed != target_rule:
            raise AssertionError(
                f"{identifier}: expected {target_rule}, observed {observed}"
            )
        path = output_root / (identifier.lower() + ".sqlite")
        path.write_bytes(hostile)
        expected_rejection = "header:" + target_rule
        try:
            REFERENCE.validate_database(path)
        except REFERENCE.ValidationError as error:
            if error.code != expected_rejection:
                raise AssertionError(
                    f"{identifier}: expected reference rejection "
                    f"{expected_rejection}, observed {error.code}"
                ) from error
        else:
            raise AssertionError(
                f"{identifier}: reference validator accepted hostile header"
            )
        cases.append(
            {
                "case_id": identifier,
                "case_class": "header",
                "target_rule": target_rule,
                "reference_outcome": "rejected:" + expected_rejection,
                "byte_count": len(hostile),
                "sha256": sha256_bytes(hostile),
            }
        )
    return cases


def run_sqlite(path, sql):
    try:
        subprocess.run(
            ["/usr/bin/sqlite3", "-batch", "-bail", str(path), sql],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        raise AssertionError(
            f"sqlite3 failed for {path.name}: {error.stderr.strip()}"
        ) from error


def schema_rows(path):
    database = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        return database.execute(
            """
            SELECT type, name, tbl_name, hex(sql)
            FROM sqlite_schema
            ORDER BY type, name
            """
        ).fetchall()
    finally:
        database.close()


def schema_manifest(path):
    return "".join(
        "|".join(str(value) for value in row) + "\n"
        for row in schema_rows(path)
    ).encode()


def require_clean_structure(path, identifier, require_integrity):
    data = path.read_bytes()
    failure = header_failure(data)
    if failure is not None:
        raise AssertionError(f"{identifier}: header failed before schema: {failure}")
    if any(
        os.path.lexists(path.with_name(path.name + suffix))
        for suffix in SIDECAR_SUFFIXES
    ):
        raise AssertionError(f"{identifier}: unexpected SQLite sidecar")

    database = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        integrity = database.execute("PRAGMA integrity_check").fetchall()
        foreign_keys = database.execute("PRAGMA foreign_key_check").fetchall()
    finally:
        database.close()
    if require_integrity and integrity != [("ok",)]:
        raise AssertionError(f"{identifier}: integrity failure {integrity!r}")
    if foreign_keys:
        raise AssertionError(f"{identifier}: foreign-key failure {foreign_keys!r}")


SCHEMA_DEFINITIONS = [
    (
        "V3-N-SCHEMA-EXTRA",
        "extra-object",
        """
        CREATE VIEW unexpected_schema_object AS
        SELECT singleton FROM backup_root;
        """,
        True,
    ),
    (
        "V3-N-SCHEMA-SQLITE-PREFIX",
        "sqlite-prefixed-extra-object",
        "ANALYZE;",
        True,
    ),
    (
        "V3-N-SCHEMA-MISSING",
        "missing-object",
        """
        PRAGMA writable_schema=ON;
        DELETE FROM sqlite_schema
        WHERE type='index' AND name='ux_category_dimension_name';
        PRAGMA schema_version=4242;
        PRAGMA writable_schema=OFF;
        """,
        False,
    ),
    (
        "V3-N-SCHEMA-WRONG-TYPE",
        "wrong-object-type",
        """
        DROP INDEX ux_category_dimension_name;
        CREATE TABLE ux_category_dimension_name(unexpected INTEGER);
        """,
        True,
    ),
    (
        "V3-N-SCHEMA-WRONG-NAME",
        "wrong-object-name",
        """
        DROP INDEX ux_category_dimension_name;
        CREATE UNIQUE INDEX ux_category_dimension_wrong_name
        ON category_dimension(name);
        """,
        True,
    ),
    (
        "V3-N-SCHEMA-WRONG-TABLE",
        "wrong-owning-table",
        """
        DROP INDEX ux_category_dimension_name;
        CREATE UNIQUE INDEX ux_category_dimension_name
        ON category_value(name);
        """,
        True,
    ),
    (
        "V3-N-SCHEMA-WRONG-SQL",
        "wrong-stored-sql",
        """
        DROP INDEX ux_category_dimension_name;
        CREATE UNIQUE INDEX ux_category_dimension_name
        ON category_dimension(name DESC);
        """,
        True,
    ),
]


def require_schema_probe(identifier, rows):
    by_name = {row[1]: row for row in rows}
    expected_name = "ux_category_dimension_name"
    if identifier == "V3-N-SCHEMA-EXTRA":
        if "unexpected_schema_object" not in by_name or len(rows) != 11:
            raise AssertionError(f"{identifier}: extra object absent")
    elif identifier == "V3-N-SCHEMA-SQLITE-PREFIX":
        if "sqlite_stat1" not in by_name or len(rows) != 11:
            raise AssertionError(f"{identifier}: sqlite_stat1 absent")
    elif identifier == "V3-N-SCHEMA-MISSING":
        if expected_name in by_name or len(rows) != 9:
            raise AssertionError(f"{identifier}: expected object still present")
    elif identifier == "V3-N-SCHEMA-WRONG-TYPE":
        if by_name.get(expected_name, (None,))[0] != "table":
            raise AssertionError(f"{identifier}: wrong type absent")
    elif identifier == "V3-N-SCHEMA-WRONG-NAME":
        if expected_name in by_name or "ux_category_dimension_wrong_name" not in by_name:
            raise AssertionError(f"{identifier}: wrong name absent")
    elif identifier == "V3-N-SCHEMA-WRONG-TABLE":
        if by_name.get(expected_name, (None, None, None))[2] != "category_value":
            raise AssertionError(f"{identifier}: wrong table absent")
    elif identifier == "V3-N-SCHEMA-WRONG-SQL":
        row = by_name.get(expected_name)
        if row is None or "DESC" not in bytes.fromhex(row[3]).decode("utf-8"):
            raise AssertionError(f"{identifier}: wrong SQL absent")
    else:
        raise AssertionError(f"unknown schema case {identifier}")


def generate_schema_cases(output_root):
    cases = []
    for identifier, target_rule, sql, require_integrity in SCHEMA_DEFINITIONS:
        path = output_root / (identifier.lower() + ".sqlite")
        shutil.copyfile(BASELINE, path)
        run_sqlite(path, sql)
        require_clean_structure(path, identifier, require_integrity)
        manifest = schema_manifest(path)
        if manifest == CANONICAL_SCHEMA_MANIFEST:
            raise AssertionError(f"{identifier}: canonical schema still matches")
        rows = schema_rows(path)
        require_schema_probe(identifier, rows)
        try:
            REFERENCE.validate_database(path)
        except REFERENCE.ValidationError as error:
            if error.code != "schema:manifest":
                raise AssertionError(
                    f"{identifier}: expected schema:manifest, "
                    f"observed {error.code}"
                ) from error
        else:
            raise AssertionError(
                f"{identifier}: reference validator accepted hostile schema"
            )
        cases.append(
            {
                "case_id": identifier,
                "case_class": "schema",
                "target_rule": target_rule,
                "reference_outcome": "rejected:schema:manifest",
                "schema_row_count": len(rows),
                "schema_manifest_sha256": sha256_bytes(manifest),
                "byte_count": path.stat().st_size,
                "sha256": sha256_file(path),
            }
        )
    return cases


def generate_non_utf8_schema_case(output_root):
    identifier = "V3-N-SCHEMA-NONUTF8-NAME"
    path = output_root / (identifier.lower() + ".sqlite")
    shutil.copyfile(BASELINE, path)
    run_sqlite(
        path,
        """
        PRAGMA writable_schema=ON;
        UPDATE sqlite_schema
        SET name=CAST(X'FF' AS TEXT)
        WHERE name='ux_category_dimension_name';
        PRAGMA schema_version=4243;
        PRAGMA writable_schema=OFF;
        """,
    )
    if header_failure(path.read_bytes()) is not None:
        raise AssertionError(f"{identifier}: hostile header must remain valid")
    if any(
        os.path.lexists(path.with_name(path.name + suffix))
        for suffix in SIDECAR_SUFFIXES
    ):
        raise AssertionError(f"{identifier}: unexpected SQLite sidecar")
    expected_rejection = "schema:unreadable"
    assert_reference_rejection(path, identifier, expected_rejection)
    return [
        {
            "case_id": identifier,
            "case_class": "schema",
            "target_rule": "non-utf8-object-name-is-staged-rejection",
            "reference_outcome": "rejected:" + expected_rejection,
            "mutated_name_hex": "ff",
            "byte_count": path.stat().st_size,
            "sha256": sha256_file(path),
        }
    ]


def verify_non_utf8_schema_cursor_rejection():
    class NonUTF8SchemaCursor:
        @staticmethod
        def execute(_statement):
            return [(b"index", b"\xff", b"category_dimension", b"00")]

    try:
        REFERENCE.schema_manifest(NonUTF8SchemaCursor())
    except REFERENCE.ValidationError as error:
        if error.code != "schema:manifest":
            raise AssertionError(
                "non-UTF-8 schema cursor returned unexpected rejection "
                f"{error.code}"
            ) from error
    else:
        raise AssertionError("non-UTF-8 schema cursor was accepted")
    print("PASS non-UTF-8 schema cursor staged rejection")


def generate_reference_resource_cases(output_root):
    identifier = "V3-N-REFERENCE-ROW-LIMIT"
    path = output_root / (identifier.lower() + ".sqlite")
    shutil.copyfile(BASELINE, path)
    database = sqlite3.connect(path)
    try:
        database.executemany(
            """
            INSERT INTO library_item (
                id,
                content,
                created_at_ms,
                last_reviewed_at_ms,
                next_review_at_ms,
                ease_factor,
                interval_days,
                repetitions,
                answer_text,
                record_sha256
            ) VALUES (?, NULL, 0, NULL, NULL, 2.5, 0, 0, NULL, ?)
            """,
            (
                (
                    b"\x80" + index.to_bytes(15, "big"),
                    bytes(32),
                )
                for index in range(1, 9_998)
            ),
        )
        database.commit()
    finally:
        database.close()
    require_clean_structure(path, identifier, require_integrity=True)
    expected_rejection = "reference:row-limit:library_item"
    assert_reference_rejection(path, identifier, expected_rejection)
    cases = [
        {
            "case_id": identifier,
            "case_class": "reference-resource",
            "target_rule": "row-cap-before-physical-and-value-traversal",
            "reference_outcome": "rejected:" + expected_rejection,
            "row_count": 10_001,
            "byte_count": path.stat().st_size,
            "sha256": sha256_file(path),
        }
    ]

    identifier = "V3-N-REFERENCE-FILE-LIMIT"
    path = output_root / (identifier.lower() + ".sqlite")
    shutil.copyfile(BASELINE, path)
    file_size = REFERENCE.REFERENCE_MAX_FILE_BYTES + 1
    with path.open("r+b") as database_file:
        database_file.truncate(file_size)
    expected_rejection = "reference:file-size-limit"
    assert_reference_rejection(path, identifier, expected_rejection)
    cases.append(
        {
            "case_id": identifier,
            "case_class": "reference-resource",
            "target_rule": "file-cap-before-header-or-database-open",
            "reference_outcome": "rejected:" + expected_rejection,
            "file_size": file_size,
            "byte_count": path.stat().st_size,
            "sha256": sha256_file(path),
        }
    )
    return cases


def existing_sidecars(path):
    return [
        suffix
        for suffix in SIDECAR_SUFFIXES
        if os.path.lexists(path.with_name(path.name + suffix))
    ]


def generate_sidecar_cases(output_root):
    cases = []
    for suffix in SIDECAR_SUFFIXES:
        identifier = "V3-N-SIDECAR-" + suffix[1:].upper()
        case_root = output_root / identifier.lower()
        case_root.mkdir()
        path = case_root / "input.snapdrillbackup"
        shutil.copyfile(BASELINE, path)
        sidecar = path.with_name(path.name + suffix)
        sidecar.write_bytes(b"hostile-sidecar:" + suffix.encode("ascii"))
        observed = existing_sidecars(path)
        if observed != [suffix]:
            raise AssertionError(
                f"{identifier}: expected [{suffix!r}], observed {observed!r}"
            )
        if header_failure(path.read_bytes()) is not None:
            raise AssertionError(f"{identifier}: baseline header changed")
        expected_rejection = "filesystem:sidecar:" + suffix[1:]
        try:
            REFERENCE.validate_database(path)
        except REFERENCE.ValidationError as error:
            if error.code != expected_rejection:
                raise AssertionError(
                    f"{identifier}: expected reference rejection "
                    f"{expected_rejection}, observed {error.code}"
                ) from error
        else:
            raise AssertionError(
                f"{identifier}: reference validator accepted sidecar"
            )
        cases.append(
            {
                "case_id": identifier,
                "case_class": "sidecar",
                "target_rule": "no-journal-wal-shm-sibling",
                "reference_outcome": "rejected:" + expected_rejection,
                "suffix": suffix,
                "byte_count": sidecar.stat().st_size,
                "sha256": sha256_file(sidecar),
            }
        )
    identifier = "V3-N-SIDECAR-WAL-DANGLING-SYMLINK"
    case_root = output_root / identifier.lower()
    case_root.mkdir()
    path = case_root / "input.snapdrillbackup"
    shutil.copyfile(BASELINE, path)
    sidecar = path.with_name(path.name + "-wal")
    link_target = "missing-sidecar-target"
    sidecar.symlink_to(link_target)
    observed = existing_sidecars(path)
    if observed != ["-wal"]:
        raise AssertionError(
            f"{identifier}: expected ['-wal'], observed {observed!r}"
        )
    expected_rejection = "filesystem:sidecar:wal"
    try:
        REFERENCE.validate_database(path)
    except REFERENCE.ValidationError as error:
        if error.code != expected_rejection:
            raise AssertionError(
                f"{identifier}: expected reference rejection "
                f"{expected_rejection}, observed {error.code}"
            ) from error
    else:
        raise AssertionError(
            f"{identifier}: reference validator accepted dangling sidecar"
        )
    link_bytes = link_target.encode("utf-8")
    cases.append(
        {
            "case_id": identifier,
            "case_class": "sidecar",
            "target_rule": "lexical-no-journal-wal-shm-sibling",
            "reference_outcome": "rejected:" + expected_rejection,
            "suffix": "-wal",
            "node_type": "dangling-symlink",
            "link_target": link_target,
            "byte_count": len(link_bytes),
            "sha256": sha256_bytes(link_bytes),
        }
    )
    return cases


def index_leaf_page(index_name):
    database = sqlite3.connect(f"file:{BASELINE}?mode=ro", uri=True)
    try:
        rows = database.execute(
            """
            SELECT pageno
            FROM dbstat('main')
            WHERE name = ? AND pagetype = 'leaf'
            ORDER BY pageno
            """,
            (index_name,),
        ).fetchall()
    finally:
        database.close()
    if len(rows) != 1:
        raise AssertionError(
            f"{index_name}: expected one index leaf page, observed {rows!r}"
        )
    return rows[0][0]


def assert_reference_rejection(path, identifier, expected_rejection):
    try:
        REFERENCE.validate_database(path)
    except REFERENCE.ValidationError as error:
        if error.code != expected_rejection:
            raise AssertionError(
                f"{identifier}: expected reference rejection "
                f"{expected_rejection}, observed {error.code}"
            ) from error
    else:
        raise AssertionError(
            f"{identifier}: reference validator accepted physical corruption"
        )


def generate_physical_cases(output_root):
    baseline = BASELINE.read_bytes()
    page_count = uint32(baseline, 28)
    cases = []

    identifier = "V3-N-PHYSICAL-UNOWNED-PAGE"
    hostile = replace_bytes(
        baseline,
        28,
        struct.pack(">I", page_count + 1),
    ) + bytes(PAGE_SIZE)
    if header_failure(hostile) is not None:
        raise AssertionError(f"{identifier}: hostile header must remain valid")
    path = output_root / (identifier.lower() + ".sqlite")
    path.write_bytes(hostile)
    expected_rejection = "physical:page-closure"
    assert_reference_rejection(path, identifier, expected_rejection)
    cases.append(
        {
            "case_id": identifier,
            "case_class": "physical",
            "target_rule": "every-page-owned-exactly-once",
            "reference_outcome": "rejected:" + expected_rejection,
            "byte_count": len(hostile),
            "sha256": sha256_bytes(hostile),
        }
    )

    identifier = "V3-N-PHYSICAL-INDEX-PARITY"
    index_page = index_leaf_page("ux_category_dimension_name")
    page_start = (index_page - 1) * PAGE_SIZE
    page_end = page_start + PAGE_SIZE
    needle = b"Category"
    page = baseline[page_start:page_end]
    if page.count(needle) != 1:
        raise AssertionError(
            f"{identifier}: expected one {needle!r} index payload"
        )
    hostile = replace_bytes(
        baseline,
        page_start + page.index(needle),
        b"Bategory",
    )
    if header_failure(hostile) is not None:
        raise AssertionError(f"{identifier}: hostile header must remain valid")
    path = output_root / (identifier.lower() + ".sqlite")
    path.write_bytes(hostile)
    expected_rejection = "physical:index-parity"
    assert_reference_rejection(path, identifier, expected_rejection)
    cases.append(
        {
            "case_id": identifier,
            "case_class": "physical",
            "target_rule": "secondary-index-equals-owning-table",
            "reference_outcome": "rejected:" + expected_rejection,
            "index_name": "ux_category_dimension_name",
            "index_page": index_page,
            "byte_count": len(hostile),
            "sha256": sha256_bytes(hostile),
        }
    )
    return cases


def generate_corpus(output_root):
    cases = []
    cases.extend(generate_header_cases(output_root))
    cases.extend(generate_schema_cases(output_root))
    cases.extend(generate_non_utf8_schema_case(output_root))
    cases.extend(generate_reference_resource_cases(output_root))
    cases.extend(generate_physical_cases(output_root))
    cases.extend(generate_sidecar_cases(output_root))
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
    verify_non_utf8_schema_cursor_rejection()
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-structure-a-") as first:
        with tempfile.TemporaryDirectory(prefix="snapdrill-v3-structure-b-") as second:
            first_cases = generate_corpus(pathlib.Path(first))
            second_cases = generate_corpus(pathlib.Path(second))
            if semantic_manifest(first_cases) != semantic_manifest(second_cases):
                raise AssertionError("structure corpus manifest is nondeterministic")
            first_files = [
                (case["byte_count"], case["sha256"]) for case in first_cases
            ]
            second_files = [
                (case["byte_count"], case["sha256"]) for case in second_cases
            ]
            if first_files != second_files:
                raise AssertionError("structure corpus files are nondeterministic")
            manifest_bytes = json.dumps(
                semantic_manifest(first_cases),
                separators=(",", ":"),
                sort_keys=True,
            ).encode()
            manifest_sha256 = sha256_bytes(manifest_bytes)
            if manifest_sha256 != EXPECTED_SEMANTIC_MANIFEST_SHA256:
                raise AssertionError(
                    "structure corpus manifest changed: "
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
    print("PASS deterministic SQLite structure corpus")


if __name__ == "__main__":
    main()
