#!/usr/bin/env python3

import copy
import hashlib
import importlib.util
import json
import pathlib
import sqlite3
import struct
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
VALIDATOR_PATH = ROOT / "validate-package.py"
SPEC = importlib.util.spec_from_file_location("package_validator", VALIDATOR_PATH)
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("cannot load package validator")
VALIDATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VALIDATOR)


def expect_fail(name, message_fragment, operation):
    try:
        operation()
    except SystemExit as error:
        message = str(error)
        if message_fragment not in message:
            raise AssertionError(
                f"{name}: expected {message_fragment!r}, got {message!r}"
            ) from error
        print(f"PASS reject {name}: {message}")
        return
    raise AssertionError(f"{name}: validator accepted hostile input")


def mutated_manifest(manifest, mutation):
    result = copy.deepcopy(manifest)
    mutation(result)
    return result


def artifact_manifest(data=b"candidate\n"):
    digest = hashlib.sha256(data).hexdigest()
    return {
        "candidate_sha256": digest,
        "artifacts": [
            {
                "path": "backup-wire-v3-candidate.md",
                "role": "candidate",
                "byte_count": len(data),
                "sha256": digest,
            }
        ],
    }


def write_minimal_package(root, data=b"candidate\n"):
    (root / "backup-wire-v3-candidate.md").write_bytes(data)
    (root / "manifest.json").write_text("{}\n", encoding="utf-8")


def test_manifest_schema():
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    VALIDATOR.validate_manifest(manifest)
    print("PASS current manifest schema")

    expect_fail(
        "unknown manifest key",
        "manifest keys",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(manifest, lambda value: value.update({"extra": True}))
        ),
    )
    expect_fail(
        "lifecycle claim injected",
        "manifest keys",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(manifest, lambda value: value.update({"effective": True}))
        ),
    )
    expect_fail(
        "uppercase digest",
        "expected lowercase SHA-256",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(
                manifest,
                lambda value: value.update(
                    {"candidate_sha256": value["candidate_sha256"].upper()}
                ),
            )
        ),
    )
    expect_fail(
        "duplicate closed decision",
        "closed product decisions: duplicate ID",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(
                manifest,
                lambda value: value["closed_product_decisions"].insert(
                    1,
                    copy.deepcopy(value["closed_product_decisions"][0]),
                ),
            )
        ),
    )
    expect_fail(
        "review input aggregate drift",
        "review input aggregate SHA-256",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(
                manifest,
                lambda value: value["review_input"].update({"sha256": "0" * 64}),
            )
        ),
    )
    expect_fail(
        "review input omits executable dependency",
        "review input artifact set",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(
                manifest,
                lambda value: (
                    value["review_input"]["artifacts"].pop(),
                    value["review_input"].update(
                        {
                            "sha256": VALIDATOR.review_input_sha256(
                                value["review_input"]["artifacts"]
                            )
                        }
                    ),
                ),
            )
        ),
    )
    expect_fail(
        "physical oracle schema drift",
        "physical oracle keys",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(
                manifest,
                lambda value: value["physical_oracle"].pop("page_count"),
            )
        ),
    )
    expect_fail(
        "artifact schema drift",
        "artifact 0 keys",
        lambda: VALIDATOR.validate_manifest(
            mutated_manifest(
                manifest,
                lambda value: value["artifacts"][0].update({"optional": True}),
            )
        ),
    )

    incomplete = mutated_manifest(
        manifest,
        lambda value: value.update({"known_missing_evidence": ["fixture-gap"]}),
    )
    expect_fail(
        "incomplete qualification",
        "contract evidence incomplete",
        lambda: VALIDATOR.validate_qualification(incomplete, True, True),
    )
    complete = mutated_manifest(
        manifest,
        lambda value: value.update(
            {"known_missing_evidence": [], "unresolved_product_decisions": []}
        ),
    )
    VALIDATOR.validate_qualification(complete, True, True)
    unresolved = mutated_manifest(
        complete,
        lambda value: value.update({"unresolved_product_decisions": ["P2-X"]}),
    )
    expect_fail(
        "unresolved-decision qualification",
        "contract decisions unresolved",
        lambda: VALIDATOR.validate_qualification(unresolved, True, True),
    )
    expect_fail(
        "missing final review",
        "final independent review is missing",
        lambda: VALIDATOR.validate_qualification(complete, True, False),
    )
    VALIDATOR.validate_qualification(manifest, False, False)
    print("PASS qualification state")


def test_artifact_closure():
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-manifest-") as directory:
        root = pathlib.Path(directory).resolve()
        data = b"candidate\n"
        write_minimal_package(root, data)
        manifest = artifact_manifest(data)
        VALIDATOR.validate_artifacts(root, manifest)
        print("PASS minimal closed artifact set")

        (root / "backup-wire-v3-candidate.md").write_bytes(data + b"tamper")
        expect_fail(
            "artifact tamper",
            "size",
            lambda: VALIDATOR.validate_artifacts(root, manifest),
        )
        (root / "backup-wire-v3-candidate.md").write_bytes(data)

        wrong_size = copy.deepcopy(manifest)
        wrong_size["artifacts"][0]["byte_count"] += 1
        expect_fail(
            "declared byte count",
            "size",
            lambda: VALIDATOR.validate_artifacts(root, wrong_size),
        )

        duplicate = copy.deepcopy(manifest)
        duplicate["artifacts"].append(copy.deepcopy(duplicate["artifacts"][0]))
        expect_fail(
            "duplicate artifact",
            "duplicate artifact path",
            lambda: VALIDATOR.validate_artifacts(root, duplicate),
        )

        unsafe = copy.deepcopy(manifest)
        unsafe["artifacts"][0]["path"] = "../escape"
        expect_fail(
            "path traversal",
            "artifact path: unsafe relative path",
            lambda: VALIDATOR.validate_artifacts(root, unsafe),
        )

        (root / "unlisted").write_bytes(b"x")
        expect_fail(
            "unlisted file",
            "package file set",
            lambda: VALIDATOR.validate_artifacts(root, manifest),
        )
        (root / "unlisted").unlink()

        candidate = root / "backup-wire-v3-candidate.md"
        target = root / "target"
        target.write_bytes(data)
        candidate.unlink()
        candidate.symlink_to(target.name)
        expect_fail(
            "symbolic link",
            "not a regular file",
            lambda: VALIDATOR.validate_artifacts(root, manifest),
        )


def test_product_decision_provenance():
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    VALIDATOR.validate_product_decision_provenance(ROOT, manifest)
    stale = copy.deepcopy(manifest)
    stale["closed_product_decisions"][0]["effective_commit"] = manifest[
        "source_baseline"
    ]
    expect_fail(
        "stale effective-decision commit",
        "effective commit is not introduction point",
        lambda: VALIDATOR.validate_product_decision_provenance(ROOT, stale),
    )
    print("PASS closed product decision provenance")


def test_embedded_ddl():
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-ddl-") as directory:
        root = pathlib.Path(directory)
        (root / "backup-wire-v3-candidate.md").write_text(
            "# Candidate\n\n```sql\nSELECT 1;\n```\n",
            encoding="utf-8",
        )
        (root / "schema.sql").write_text("SELECT 1;\n", encoding="utf-8")
        VALIDATOR.validate_embedded_ddl(root)
        print("PASS embedded DDL equality")

        (root / "schema.sql").write_text("SELECT 2;\n", encoding="utf-8")
        expect_fail(
            "embedded DDL mismatch",
            "embedded DDL",
            lambda: VALIDATOR.validate_embedded_ddl(root),
        )
        (root / "schema.sql").write_text("SELECT 1;\n", encoding="utf-8")
        with (root / "backup-wire-v3-candidate.md").open("a", encoding="utf-8") as file:
            file.write("\n```sql\nSELECT 1;\n```\n")
        expect_fail(
            "multiple SQL fences",
            "candidate SQL fence count",
            lambda: VALIDATOR.validate_embedded_ddl(root),
        )


def oracle_manifest(manifest, database):
    result = copy.deepcopy(manifest)
    data = database.read_bytes()
    result["physical_oracle"]["file"] = database.name
    result["physical_oracle"]["byte_count"] = len(data)
    result["physical_oracle"]["sha256"] = hashlib.sha256(data).hexdigest()
    result["physical_oracle"]["page_count"] = struct.unpack(
        ">I",
        data[28:32],
    )[0]
    return result


def test_physical_oracle_drift():
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-physical-") as directory:
        root = pathlib.Path(directory)
        source = ROOT / "iOS-26.5-full-v3.sqlite"
        header_drift = root / "header-drift.sqlite"
        header_drift.write_bytes(source.read_bytes())
        data = bytearray(header_drift.read_bytes())
        data[20] = 1
        header_drift.write_bytes(data)
        header_manifest = oracle_manifest(manifest, header_drift)
        expect_fail(
            "reserved header byte drift",
            "reserved bytes",
            lambda: VALIDATOR.validate_header(header_drift, header_manifest),
        )

        (root / "schema-manifest.txt").write_bytes(
            (ROOT / "schema-manifest.txt").read_bytes()
        )
        schema_drift = root / "schema-drift.sqlite"
        schema_drift.write_bytes(source.read_bytes())
        database = sqlite3.connect(schema_drift)
        database.execute("CREATE TABLE unexpected(value INTEGER)")
        database.commit()
        database.close()
        schema_manifest = oracle_manifest(manifest, schema_drift)
        expect_fail(
            "physical schema drift",
            "schema manifest SHA-256",
            lambda: VALIDATOR.validate_database(root, schema_manifest),
        )

        count_drift = root / "count-drift.sqlite"
        count_drift.write_bytes(source.read_bytes())
        database = sqlite3.connect(count_drift)
        database.execute("UPDATE backup_root SET item_count = item_count + 1")
        database.commit()
        database.close()
        count_manifest = oracle_manifest(manifest, count_drift)
        expect_fail(
            "root count drift",
            "root counts",
            lambda: VALIDATOR.validate_database(root, count_manifest),
        )


def test_physical_provenance():
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    VALIDATOR.validate_physical_provenance(ROOT, manifest)
    print("PASS current physical provenance")

    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-provenance-") as directory:
        root = pathlib.Path(directory)
        for name in (
            "physical-oracle-evidence.txt",
            "iossim-init.c",
            "schema.sql",
            "full-fixture.sql",
            "reproduce-physical-oracle.sh",
            "iOS-26.5-full-v3.sqlite",
        ):
            (root / name).write_bytes((ROOT / name).read_bytes())
        evidence = root / "physical-oracle-evidence.txt"
        evidence.write_text(
            evidence.read_text(encoding="utf-8").replace(
                "schema_sha256=e9cc",
                "schema_sha256=0000",
            ),
            encoding="utf-8",
        )
        expect_fail(
            "physical provenance digest drift",
            "physical provenance schema.sql SHA-256",
            lambda: VALIDATOR.validate_physical_provenance(root, manifest),
        )


def test_independent_review():
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    review_present = VALIDATOR.validate_independent_review(ROOT, manifest, False)
    print(
        "PASS current independent review state "
        + ("closed" if review_present else "draft")
    )

    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-review-missing-") as directory:
        root = pathlib.Path(directory)
        if VALIDATOR.validate_independent_review(root, manifest, False):
            raise AssertionError("missing optional review was accepted as present")
        expect_fail(
            "missing independent review",
            "final independent review is missing",
            lambda: VALIDATOR.validate_independent_review(root, manifest, True),
        )

    with tempfile.TemporaryDirectory(prefix="snapdrill-v3-review-") as directory:
        root = pathlib.Path(directory)
        review_input = manifest["review_input"]["sha256"]
        result = root / "independent-review-result.json"
        payload = {
            "review_input_sha256": review_input,
            "verdict": "PASS",
            "findings": [],
            "coverage_notes": ["bounded regression fixture"],
        }
        result.write_text(json.dumps(payload) + "\n", encoding="utf-8")
        result_sha = hashlib.sha256(result.read_bytes()).hexdigest()
        evidence = root / "independent-review-evidence.txt"
        evidence.write_text(
            "\n".join(
                (
                    "SnapDrill Backup v3 independent reference-validator review",
                    "generated_at_utc=2026-07-21T00:00:00Z",
                    "reviewer=regression-fixture",
                    "requested_model=fixture",
                    "model_usage=fixture",
                    "mode=read-only",
                    "allowed_tools=read-only",
                    "permission_denials=0",
                    f"review_input_sha256={review_input}",
                    "structured_result=independent-review-result.json",
                    f"structured_result_sha256={result_sha}",
                    "verdict=PASS",
                    "finding_count=0",
                    "",
                )
            ),
            encoding="utf-8",
        )
        if not VALIDATOR.validate_independent_review(root, manifest, True):
            raise AssertionError("valid independent review was not accepted")

        stale_manifest = copy.deepcopy(manifest)
        stale_manifest["review_input"]["sha256"] = "0" * 64
        expect_fail(
            "stale independent review input",
            "independent review input SHA-256",
            lambda: VALIDATOR.validate_independent_review(root, stale_manifest, True),
        )

        payload["verdict"] = "FAIL"
        result.write_text(json.dumps(payload), encoding="utf-8")
        expect_fail(
            "independent review result tamper",
            "independent review result SHA-256",
            lambda: VALIDATOR.validate_independent_review(root, manifest, True),
        )
    print("PASS independent review binding")


def test_sub_oracle_failure():
    VALIDATOR.run_oracle(["python3", "-c", "print('PASS child')"], True)
    expect_fail(
        "sub-oracle missing PASS",
        "oracle produced no PASS output",
        lambda: VALIDATOR.run_oracle(["python3", "-c", "print('done')"], True),
    )
    expect_fail(
        "sub-oracle nonzero exit",
        "oracle failed",
        lambda: VALIDATOR.run_oracle(
            ["python3", "-c", "raise SystemExit(7)"],
            True,
        ),
    )
    print("PASS sub-oracle propagation")


def main():
    test_manifest_schema()
    test_artifact_closure()
    test_product_decision_provenance()
    test_embedded_ddl()
    test_physical_oracle_drift()
    test_physical_provenance()
    test_independent_review()
    test_sub_oracle_failure()
    print("PASS package validator regression suite")


if __name__ == "__main__":
    main()
