#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import pathlib
import re
import struct
import subprocess
import sys


SHA256_PATTERN = re.compile(r"[0-9a-f]{64}")
COMMIT_PATTERN = re.compile(r"[0-9a-f]{40}")
MANIFEST_KEYS = {
    "manifest_version",
    "package_purpose",
    "source_baseline",
    "lifecycle_owner",
    "candidate_sha256",
    "wire_version",
    "application_id",
    "user_version",
    "closed_product_decisions",
    "unresolved_product_decisions",
    "known_missing_evidence",
    "review_input",
    "physical_oracle",
    "artifacts",
}
CLOSED_DECISION_KEYS = {"id", "authority", "effective_commit"}
REVIEW_INPUT_KEYS = {"algorithm", "framing", "sha256", "artifacts"}
REVIEW_INPUT_ARTIFACT_KEYS = {"path", "sha256"}
REVIEW_OUTPUT_PATHS = {
    "independent-review-evidence.txt",
    "independent-review-result.json",
}
PHYSICAL_ORACLE_KEYS = {
    "runtime",
    "sqlite_version",
    "file",
    "sha256",
    "byte_count",
    "page_size",
    "page_count",
    "reserved_bytes",
    "schema_manifest_sha256",
    "inventory_sha256",
}
ARTIFACT_KEYS = {"path", "role", "byte_count", "sha256"}
PHYSICAL_PROVENANCE_KEYS = {
    "generated_at_utc",
    "runtime",
    "simulator",
    "xcode",
    "sdk",
    "minimum_target",
    "compiler",
    "initializer_source",
    "initializer_source_sha256",
    "initializer_binary_sha256",
    "initializer_runtime_sqlite_version",
    "initializer_reserved_bytes",
    "population_cli",
    "population_cli_sqlite_version",
    "schema",
    "schema_sha256",
    "fixture_loader",
    "fixture_loader_sha256",
    "recipe",
    "recipe_sha256",
    "reproduced_byte_count",
    "reproduced_sha256",
    "retained_oracle",
    "retained_oracle_sha256",
    "reproduced_bytes_match_retained",
}
INDEPENDENT_REVIEW_KEYS = {
    "generated_at_utc",
    "reviewer",
    "requested_model",
    "model_usage",
    "mode",
    "allowed_tools",
    "permission_denials",
    "review_input_sha256",
    "structured_result",
    "structured_result_sha256",
    "verdict",
    "finding_count",
}


def fail(message):
    raise SystemExit(f"FAIL: {message}")


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(256 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def sqlite_rows(database, statement):
    result = subprocess.run(
        [
            "/usr/bin/sqlite3",
            "-readonly",
            "-json",
            str(database),
            statement,
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def require_equal(expected, actual, label):
    if expected != actual:
        fail(f"{label}: expected {expected!r}, got {actual!r}")


def require_type(value, expected_type, label):
    if type(value) is not expected_type:
        fail(f"{label}: expected {expected_type.__name__}, got {type(value).__name__}")


def require_sha256(value, label):
    require_type(value, str, label)
    if SHA256_PATTERN.fullmatch(value) is None:
        fail(f"{label}: expected lowercase SHA-256")


def require_unique_strings(values, label):
    require_type(values, list, label)
    if any(type(value) is not str or not value for value in values):
        fail(f"{label}: expected nonempty strings")
    if len(values) != len(set(values)):
        fail(f"{label}: duplicate value")


def require_safe_relative_path(value, label):
    require_type(value, str, label)
    relative = pathlib.PurePosixPath(value)
    if (
        not value
        or relative.is_absolute()
        or ".." in relative.parts
        or relative.as_posix() != value
        or relative == pathlib.PurePosixPath(".")
    ):
        fail(f"{label}: unsafe relative path")
    return relative


def review_input_sha256(artifacts):
    framed = bytearray()
    for item in artifacts:
        framed.extend(item["path"].encode("utf-8"))
        framed.append(0)
        framed.extend(item["sha256"].encode("ascii"))
        framed.append(10)
    return hashlib.sha256(framed).hexdigest()


def validate_manifest(manifest):
    require_type(manifest, dict, "manifest")
    require_equal(MANIFEST_KEYS, set(manifest), "manifest keys")
    require_equal(2, manifest["manifest_version"], "manifest version")
    require_equal(
        "backup-wire-v3-contract-evidence",
        manifest["package_purpose"],
        "package purpose",
    )
    require_equal(
        "../backup-wire-format.md",
        manifest["lifecycle_owner"],
        "lifecycle owner",
    )

    require_type(manifest["source_baseline"], str, "source baseline")
    if COMMIT_PATTERN.fullmatch(manifest["source_baseline"]) is None:
        fail("source baseline: expected lowercase commit SHA")
    require_sha256(manifest["candidate_sha256"], "candidate SHA-256")
    require_equal(3, manifest["wire_version"], "wire version")
    require_type(manifest["application_id"], int, "application ID")
    require_type(manifest["user_version"], int, "user version")
    if not 0 <= manifest["application_id"] <= 0xFFFFFFFF:
        fail("application ID: outside UInt32")
    if not 0 <= manifest["user_version"] <= 0xFFFFFFFF:
        fail("user version: outside UInt32")

    decisions = manifest["closed_product_decisions"]
    require_type(decisions, list, "closed product decisions")
    decision_ids = []
    for index, decision in enumerate(decisions):
        require_type(decision, dict, f"closed product decision {index}")
        require_equal(
            CLOSED_DECISION_KEYS,
            set(decision),
            f"closed product decision {index} keys",
        )
        require_type(decision["id"], str, f"closed product decision {index} id")
        if not decision["id"]:
            fail(f"closed product decision {index} id: empty")
        decision_ids.append(decision["id"])
        require_safe_relative_path(
            decision["authority"],
            f"closed product decision {index} authority",
        )
        require_type(
            decision["effective_commit"],
            str,
            f"closed product decision {index} effective commit",
        )
        if COMMIT_PATTERN.fullmatch(decision["effective_commit"]) is None:
            fail(f"closed product decision {index}: expected lowercase commit SHA")
    if decision_ids != sorted(decision_ids):
        fail("closed product decisions: expected ID order")
    if len(decision_ids) != len(set(decision_ids)):
        fail("closed product decisions: duplicate ID")

    require_unique_strings(
        manifest["unresolved_product_decisions"],
        "unresolved product decisions",
    )
    require_unique_strings(manifest["known_missing_evidence"], "missing evidence")

    review_input = manifest["review_input"]
    require_type(review_input, dict, "review input")
    require_equal(REVIEW_INPUT_KEYS, set(review_input), "review input keys")
    require_equal("sha256", review_input["algorithm"], "review input algorithm")
    require_equal(
        "utf8-path-nul-lowercase-sha256-lf-sorted-by-path",
        review_input["framing"],
        "review input framing",
    )
    require_sha256(review_input["sha256"], "review input SHA-256")
    review_artifacts = review_input["artifacts"]
    require_type(review_artifacts, list, "review input artifacts")
    review_paths = []
    for index, item in enumerate(review_artifacts):
        require_type(item, dict, f"review input artifact {index}")
        require_equal(
            REVIEW_INPUT_ARTIFACT_KEYS,
            set(item),
            f"review input artifact {index} keys",
        )
        require_safe_relative_path(item["path"], f"review input artifact {index} path")
        require_sha256(item["sha256"], f"review input artifact {index} SHA-256")
        review_paths.append(item["path"])
    require_equal(sorted(review_paths), review_paths, "review input artifact order")
    require_equal(
        review_input["sha256"],
        review_input_sha256(review_artifacts),
        "review input aggregate SHA-256",
    )

    oracle = manifest["physical_oracle"]
    require_type(oracle, dict, "physical oracle")
    require_equal(PHYSICAL_ORACLE_KEYS, set(oracle), "physical oracle keys")
    for field in ("runtime", "sqlite_version", "file"):
        require_type(oracle[field], str, f"physical oracle {field}")
        if not oracle[field]:
            fail(f"physical oracle {field}: empty")
    for field in ("sha256", "schema_manifest_sha256", "inventory_sha256"):
        require_sha256(oracle[field], f"physical oracle {field}")
    for field in ("byte_count", "page_size", "page_count", "reserved_bytes"):
        require_type(oracle[field], int, f"physical oracle {field}")
        if oracle[field] < 0:
            fail(f"physical oracle {field}: negative")

    artifacts = manifest["artifacts"]
    require_type(artifacts, list, "artifacts")
    if not artifacts:
        fail("artifacts: empty")
    artifact_paths = []
    for index, item in enumerate(artifacts):
        require_type(item, dict, f"artifact {index}")
        require_equal(ARTIFACT_KEYS, set(item), f"artifact {index} keys")
        for field in ("path", "role"):
            require_type(item[field], str, f"artifact {index} {field}")
            if not item[field]:
                fail(f"artifact {index} {field}: empty")
        require_type(item["byte_count"], int, f"artifact {index} byte count")
        if item["byte_count"] < 0:
            fail(f"artifact {index} byte count: negative")
        require_sha256(item["sha256"], f"artifact {index} SHA-256")
        artifact_paths.append(item["path"])
    if len(artifact_paths) != len(set(artifact_paths)):
        fail("artifacts: duplicate path")
    review_outputs = set(artifact_paths) & REVIEW_OUTPUT_PATHS
    if review_outputs and review_outputs != REVIEW_OUTPUT_PATHS:
        fail("independent review artifacts must appear as a pair")
    require_equal(
        set(artifact_paths) - REVIEW_OUTPUT_PATHS,
        set(review_paths),
        "review input artifact set",
    )


def validate_artifacts(root, manifest):
    listed = set()
    artifact_digests = {}
    for item in manifest["artifacts"]:
        relative = require_safe_relative_path(item["path"], "artifact path")
        if item["path"] in listed:
            fail(f"duplicate artifact path: {relative}")
        listed.add(item["path"])
        artifact_digests[item["path"]] = item["sha256"]

        path = root / relative
        if not path.is_file() or path.is_symlink():
            fail(f"artifact is not a regular file: {relative}")
        try:
            resolved = path.resolve(strict=True)
            resolved.relative_to(root)
        except (FileNotFoundError, ValueError):
            fail(f"artifact escapes package root: {relative}")
        if resolved != path.absolute():
            fail(f"artifact path contains a symbolic link: {relative}")
        require_equal(item["byte_count"], path.stat().st_size, f"{relative} size")
        require_equal(item["sha256"], sha256(path), f"{relative} SHA-256")

    expected_paths = listed | {"manifest.json"}
    actual_paths = set()
    for path in root.rglob("*"):
        relative = path.relative_to(root).as_posix()
        if path.is_symlink():
            fail(f"package contains symbolic link: {relative}")
        if path.is_file():
            actual_paths.add(relative)
    require_equal(expected_paths, actual_paths, "package file set")

    candidate = root / "backup-wire-v3-candidate.md"
    require_equal(
        manifest["candidate_sha256"],
        sha256(candidate),
        "candidate SHA-256",
    )

    if "review_input" in manifest:
        for item in manifest["review_input"]["artifacts"]:
            require_equal(
                item["sha256"],
                artifact_digests.get(item["path"]),
                f"review input {item['path']} artifact SHA-256",
            )

    if "lifecycle_owner" in manifest:
        lifecycle_owner = (root / manifest["lifecycle_owner"]).resolve(strict=True)
        if not lifecycle_owner.is_file() or lifecycle_owner.is_symlink():
            fail("lifecycle owner is not a regular file")


def git_output(root, arguments, label, allow_failure=False):
    result = subprocess.run(
        ["git", *arguments],
        cwd=root,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 and not allow_failure:
        fail(f"{label}: git command failed")
    return result


def validate_product_decision_provenance(root, manifest):
    repo_root = root.parents[2]
    baseline = manifest["source_baseline"]
    for decision in manifest["closed_product_decisions"]:
        decision_id = decision["id"]
        authority = decision["authority"]
        authority_path = repo_root / authority
        try:
            authority_path.resolve(strict=True).relative_to(repo_root.resolve(strict=True))
        except (FileNotFoundError, ValueError):
            fail(f"closed product decision {decision_id}: authority is outside repository")
        if not authority_path.is_file() or authority_path.is_symlink():
            fail(f"closed product decision {decision_id}: authority is not a regular file")

        commit = decision["effective_commit"]
        ancestor = git_output(
            repo_root,
            ["merge-base", "--is-ancestor", commit, baseline],
            f"closed product decision {decision_id} ancestry",
            allow_failure=True,
        )
        if ancestor.returncode != 0:
            fail(f"closed product decision {decision_id}: effective commit is not in baseline")

        current = git_output(
            repo_root,
            ["show", f"{commit}:{authority}"],
            f"closed product decision {decision_id} authority at effective commit",
        )
        if decision_id not in current.stdout:
            fail(f"closed product decision {decision_id}: missing at effective commit")
        previous = git_output(
            repo_root,
            ["show", f"{commit}^1:{authority}"],
            f"closed product decision {decision_id} prior authority",
            allow_failure=True,
        )
        if previous.returncode == 0 and decision_id in previous.stdout:
            fail(f"closed product decision {decision_id}: effective commit is not introduction point")


def read_key_value_evidence(path, expected_header):
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != expected_header:
        fail(f"{path.name}: unexpected evidence header")
    values = {}
    for line in lines[1:]:
        if not line or "=" not in line:
            fail(f"{path.name}: malformed evidence line")
        key, value = line.split("=", 1)
        if not key or not value:
            fail(f"{path.name}: empty evidence key or value")
        if key in values:
            fail(f"{path.name}: duplicate evidence key {key}")
        values[key] = value
    return values


def validate_physical_provenance(root, manifest):
    evidence = read_key_value_evidence(
        root / "physical-oracle-evidence.txt",
        "SnapDrill Backup v3 physical-oracle provenance",
    )
    require_equal(
        PHYSICAL_PROVENANCE_KEYS,
        set(evidence),
        "physical provenance keys",
    )

    file_fields = {
        "initializer_source": "initializer_source_sha256",
        "schema": "schema_sha256",
        "fixture_loader": "fixture_loader_sha256",
        "recipe": "recipe_sha256",
        "retained_oracle": "retained_oracle_sha256",
    }
    for path_field, digest_field in file_fields.items():
        name = evidence[path_field]
        if pathlib.PurePath(name).name != name:
            fail(f"physical provenance {path_field}: expected package basename")
        require_sha256(
            evidence[digest_field],
            f"physical provenance {digest_field}",
        )
        require_equal(
            evidence[digest_field],
            sha256(root / name),
            f"physical provenance {name} SHA-256",
        )

    oracle = manifest["physical_oracle"]
    require_equal(oracle["runtime"], evidence["runtime"], "physical provenance runtime")
    require_equal(
        oracle["sqlite_version"],
        evidence["initializer_runtime_sqlite_version"],
        "physical provenance initializer SQLite version",
    )
    require_equal(
        oracle["sqlite_version"],
        evidence["population_cli_sqlite_version"],
        "physical provenance population SQLite version",
    )
    require_equal(
        str(oracle["reserved_bytes"]),
        evidence["initializer_reserved_bytes"],
        "physical provenance reserved bytes",
    )
    require_equal(
        str(oracle["byte_count"]),
        evidence["reproduced_byte_count"],
        "physical provenance reproduced byte count",
    )
    require_equal(
        oracle["sha256"],
        evidence["reproduced_sha256"],
        "physical provenance reproduced SHA-256",
    )
    require_equal(
        oracle["sha256"],
        evidence["retained_oracle_sha256"],
        "physical provenance retained SHA-256",
    )
    require_equal(
        "true",
        evidence["reproduced_bytes_match_retained"],
        "physical provenance byte identity",
    )
    require_sha256(
        evidence["initializer_binary_sha256"],
        "physical provenance initializer binary SHA-256",
    )


def validate_independent_review(root, manifest, require_review):
    evidence_path = root / "independent-review-evidence.txt"
    result_path = root / "independent-review-result.json"
    evidence_exists = evidence_path.is_file() and not evidence_path.is_symlink()
    result_exists = result_path.is_file() and not result_path.is_symlink()
    if evidence_exists != result_exists:
        fail("independent review evidence is incomplete")
    if not evidence_exists:
        if require_review:
            fail("final independent review is missing")
        return False

    evidence = read_key_value_evidence(
        evidence_path,
        "SnapDrill Backup v3 independent reference-validator review",
    )
    require_equal(INDEPENDENT_REVIEW_KEYS, set(evidence), "independent review keys")
    require_sha256(
        evidence["review_input_sha256"],
        "independent review input SHA-256",
    )
    require_equal(
        manifest["review_input"]["sha256"],
        evidence["review_input_sha256"],
        "independent review input SHA-256",
    )
    require_sha256(
        evidence["structured_result_sha256"],
        "independent review structured result SHA-256",
    )

    result_name = evidence["structured_result"]
    if pathlib.PurePath(result_name).name != result_name:
        fail("independent review result: expected package basename")
    require_equal(result_path.name, result_name, "independent review result name")
    require_equal(
        evidence["structured_result_sha256"],
        sha256(result_path),
        "independent review result SHA-256",
    )
    result = json.loads(result_path.read_text(encoding="utf-8"))
    require_equal(
        {"review_input_sha256", "verdict", "findings", "coverage_notes"},
        set(result),
        "independent review result keys",
    )
    require_equal(
        manifest["review_input"]["sha256"],
        result["review_input_sha256"],
        "independent review result input SHA-256",
    )
    require_equal("PASS", result["verdict"], "independent review verdict")
    require_equal([], result["findings"], "independent review findings")
    require_type(result["coverage_notes"], list, "independent review coverage notes")
    if any(type(note) is not str or not note for note in result["coverage_notes"]):
        fail("independent review coverage notes: expected nonempty strings")

    require_equal("PASS", evidence["verdict"], "independent review evidence verdict")
    require_equal("0", evidence["finding_count"], "independent review finding count")
    require_equal("0", evidence["permission_denials"], "independent review denials")
    return True


def validate_embedded_ddl(root):
    candidate = (root / "backup-wire-v3-candidate.md").read_text(encoding="utf-8")
    marker = "```sql\n"
    require_equal(1, candidate.count(marker), "candidate SQL fence count")
    start = candidate.find(marker)
    end = candidate.find("\n```", start + len(marker))
    if end < 0:
        fail("candidate SQL fence is unterminated")
    embedded = candidate[start + len(marker) : end] + "\n"
    schema = (root / "schema.sql").read_text(encoding="utf-8")
    require_equal(schema, embedded, "embedded DDL")


def validate_header(database, manifest):
    data = database.read_bytes()
    oracle = manifest["physical_oracle"]
    require_equal(oracle["byte_count"], len(data), "physical byte count")
    require_equal(oracle["sha256"], hashlib.sha256(data).hexdigest(), "physical SHA-256")
    if len(data) < 100:
        fail("physical oracle is shorter than the SQLite header")

    header = data[:100]
    require_equal(b"SQLite format 3\0", header[:16], "SQLite magic")
    page_size = struct.unpack(">H", header[16:18])[0]
    page_size = 65_536 if page_size == 1 else page_size
    require_equal(oracle["page_size"], page_size, "page size")
    require_equal(1, header[18], "write version")
    require_equal(1, header[19], "read version")
    require_equal(oracle["reserved_bytes"], header[20], "reserved bytes")
    require_equal(bytes([64, 32, 32]), header[21:24], "payload fractions")
    page_count = struct.unpack(">I", header[28:32])[0]
    require_equal(oracle["page_count"], page_count, "page count")
    require_equal(len(data), page_count * page_size, "page-aligned file length")
    require_equal(0, struct.unpack(">I", header[32:36])[0], "freelist trunk")
    require_equal(0, struct.unpack(">I", header[36:40])[0], "freelist count")
    require_equal(4, struct.unpack(">I", header[44:48])[0], "schema format")
    require_equal(0, struct.unpack(">I", header[52:56])[0], "auto-vacuum root")
    require_equal(1, struct.unpack(">I", header[56:60])[0], "UTF-8 encoding")
    require_equal(manifest["user_version"], struct.unpack(">I", header[60:64])[0], "user version")
    require_equal(0, struct.unpack(">I", header[64:68])[0], "incremental vacuum")
    require_equal(manifest["application_id"], struct.unpack(">I", header[68:72])[0], "application ID")
    require_equal(bytes(20), header[72:92], "header expansion")
    require_equal(header[24:28], header[92:96], "change counter/version-valid-for")


def validate_database(root, manifest):
    oracle = manifest["physical_oracle"]
    database = root / oracle["file"]
    validate_header(database, manifest)

    checks = sqlite_rows(
        database,
        """
        SELECT
          (SELECT integrity_check FROM pragma_integrity_check) AS integrity_check,
          (SELECT COUNT(*) FROM pragma_foreign_key_check) AS foreign_key_failures,
          (SELECT COUNT(*) FROM dbstat('main')) AS dbstat_rows,
          (SELECT COUNT(DISTINCT pageno) FROM dbstat('main')) AS dbstat_distinct_pages,
          (SELECT MIN(pageno) FROM dbstat('main')) AS dbstat_min_page,
          (SELECT MAX(pageno) FROM dbstat('main')) AS dbstat_max_page;
        """,
    )
    require_equal(1, len(checks), "database check row count")
    row = checks[0]
    require_equal("ok", row["integrity_check"], "integrity_check")
    require_equal(0, row["foreign_key_failures"], "foreign_key_check")
    require_equal(oracle["page_count"], row["dbstat_rows"], "DBSTAT row count")
    require_equal(oracle["page_count"], row["dbstat_distinct_pages"], "DBSTAT distinct pages")
    require_equal(1, row["dbstat_min_page"], "DBSTAT first page")
    require_equal(oracle["page_count"], row["dbstat_max_page"], "DBSTAT last page")

    schema_result = subprocess.run(
        [
            "/usr/bin/sqlite3",
            "-readonly",
            "-noheader",
            "-separator",
            "|",
            str(database),
            """
            SELECT type,name,tbl_name,hex(sql)
            FROM sqlite_schema
            ORDER BY type,name;
            """,
        ],
        check=True,
        capture_output=True,
    )
    require_equal(
        oracle["schema_manifest_sha256"],
        hashlib.sha256(schema_result.stdout).hexdigest(),
        "schema manifest SHA-256",
    )
    require_equal(
        (root / "schema-manifest.txt").read_bytes(),
        schema_result.stdout,
        "schema manifest bytes",
    )

    roots = sqlite_rows(
        database,
        """
        SELECT item_count, dimension_count, value_count, item_value_count,
               image_count, image_byte_count, lower(hex(inventory_sha256)) inventory_sha256
        FROM backup_root;
        """,
    )
    require_equal(1, len(roots), "backup_root row count")
    root_row = roots[0]
    require_equal([4, 6, 4, 4, 4, 2178], [
        root_row["item_count"],
        root_row["dimension_count"],
        root_row["value_count"],
        root_row["item_value_count"],
        root_row["image_count"],
        root_row["image_byte_count"],
    ], "root counts")
    require_equal(
        oracle["inventory_sha256"],
        root_row["inventory_sha256"],
        "inventory SHA-256",
    )


def run_oracle(command, require_pass):
    environment = os.environ.copy()
    environment["PYTHONDONTWRITEBYTECODE"] = "1"
    label = pathlib.Path(command[1]).name if len(command) > 1 else command[0]
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
            env=environment,
        )
    except subprocess.CalledProcessError as error:
        fail(f"oracle failed: {label} exit={error.returncode}")
    if require_pass and "PASS" not in result.stdout:
        fail(f"oracle produced no PASS output: {label}")


def run_oracles(root):
    commands = [
        (["python3", str(root / "generate-digests.py")], True),
        (["node", str(root / "verify-empty-item-vectors.js")], True),
        (["python3", str(root / "v3-digest.py")], True),
        (["python3", str(root / "generate-empty-fixtures.py")], True),
        (
            [
                "python3",
                str(root / "reference-validator.py"),
                str(root / "iOS-26.5-full-v3.sqlite"),
            ],
            True,
        ),
        (
            [
                "ruby",
                str(root / "verify-physical-oracle.rb"),
                str(root / "iOS-26.5-full-v3.sqlite"),
            ],
            True,
        ),
        (["swift", str(root / "timestamp-vectors.swift")], True),
        (["python3", str(root / "verify-extraction.py")], True),
        (
            [
                "python3",
                str(root / "validate-jpeg-grammar.py"),
                str(root / "canonical-rgb-sof0-2x2.jpg"),
                str(root / "canonical-gray-sof0-2x2.jpg"),
                str(root / "canonical-rgb-sof0-2000x2000.jpg"),
            ],
            True,
        ),
        (["python3", str(root / "test-jpeg-grammar.py")], True),
        (["python3", str(root / "generate-limit-probes.py")], True),
        (["python3", str(root / "verify-large-jpeg.py")], True),
        (["python3", str(root / "generate-type-corpus.py")], True),
        (["python3", str(root / "generate-check-corpus.py")], True),
        (["python3", str(root / "generate-semantic-corpus.py")], True),
        (["python3", str(root / "generate-structure-corpus.py")], True),
        (["python3", str(root / "generate-filesystem-corpus.py")], True),
        (["python3", str(root / "verify-corpus-identities.py")], True),
        (["python3", str(root / "test-package-validator.py")], True),
    ]
    for command, require_pass in commands:
        run_oracle(command, require_pass)


def validate_qualification(manifest, qualify_contract, review_present):
    missing = manifest["known_missing_evidence"]
    if qualify_contract and missing:
        fail("contract evidence incomplete: " + ", ".join(missing))
    unresolved = manifest["unresolved_product_decisions"]
    if qualify_contract and unresolved:
        fail("contract decisions unresolved: " + ", ".join(unresolved))
    if qualify_contract and not review_present:
        fail("final independent review is missing")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parent,
    )
    parser.add_argument("--qualify-contract", action="store_true")
    arguments = parser.parse_args()
    root = arguments.root.resolve()

    manifest_path = root / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    validate_manifest(manifest)
    validate_artifacts(root, manifest)
    validate_product_decision_provenance(root, manifest)
    validate_physical_provenance(root, manifest)
    validate_embedded_ddl(root)
    validate_database(root, manifest)
    run_oracles(root)

    review_present = validate_independent_review(
        root,
        manifest,
        arguments.qualify_contract,
    )

    missing = manifest["known_missing_evidence"]
    validate_qualification(manifest, arguments.qualify_contract, review_present)

    print(
        f"PASS package artifacts={len(manifest['artifacts'])} "
        f"missing_evidence={len(missing)}"
    )


if __name__ == "__main__":
    main()
