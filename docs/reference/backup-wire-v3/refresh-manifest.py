#!/usr/bin/env python3

import hashlib
import json
import pathlib


ROOT = pathlib.Path(__file__).resolve().parent
MANIFEST_PATH = ROOT / "manifest.json"
ROLES = {
    "backup-wire-v3-candidate.md": "exact-contract-candidate",
    "canonical-gray-sof0-2x2.jpg": "canonical-jpeg-positive",
    "canonical-rgb-sof0-2000x2000.jpg": "dimension-ceiling-jpeg-positive",
    "canonical-rgb-sof0-2x2.jpg": "canonical-jpeg-positive",
    "check-targets.json": "exact-check-case-target-map",
    "corpus-identities.json": "generated-hostile-corpus-identity-lock",
    "extract-trusted-fixture.sh": "standard-sqlite-extraction-recipe",
    "full-fixture.sql": "semantic-fixture-loader",
    "generate-check-corpus.py": "deterministic-check-hostile-generator",
    "generate-digests.py": "primary-digest-vector-generator",
    "generate-empty-fixtures.py": "deterministic-bilingual-empty-fixture-generator",
    "generate-filesystem-corpus.py": "deterministic-posix-hostile-generator",
    "generate-large-jpeg.swift": "dimension-ceiling-jpeg-generator",
    "generate-limit-probes.py": "deterministic-limit-probe-generator",
    "generate-semantic-corpus.py": "deterministic-semantic-hostile-generator",
    "generate-structure-corpus.py": "deterministic-structure-hostile-generator",
    "generate-type-corpus.py": "deterministic-type-hostile-generator",
    "iOS-26.5-full-v3.sqlite": "physical-oracle",
    "iossim-init.c": "reserve-zero-simulator-initializer",
    "large-jpeg-evidence.txt": "independent-large-jpeg-evidence",
    "normalize-jpeg.py": "canonical-jpeg-normalizer",
    "physical-oracle-evidence.txt": "physical-oracle-runtime-provenance",
    "reference-validator.py": "independent-contract-reference-validator",
    "reproduce-physical-oracle.sh": "physical-oracle-reproduction-recipe",
    "refresh-corpus-identities.py": "hostile-corpus-identity-generator",
    "refresh-manifest.py": "artifact-manifest-generator",
    "schema-manifest.txt": "canonical-sqlite-schema-manifest",
    "schema.sql": "canonical-ddl",
    "sqlite-capability-ios26.5-evidence.txt": "ios26.5-capability-runner-evidence",
    "sqlite-capability-ios26.5.txt": "ios26.5-capability-probe-output",
    "sqlite-capability-probe.c": "ios-sqlite-capability-probe",
    "test-jpeg-grammar.py": "raw-jpeg-grammar-regression-tests",
    "test-package-validator.py": "package-validator-regression-tests",
    "timestamp-vectors.swift": "swift-writer-quantization-vectors",
    "v3-digest.py": "generic-digest-oracle",
    "validate-jpeg-grammar.py": "raw-jpeg-grammar-validator",
    "validate-package.py": "contract-package-validator",
    "verify-extraction.py": "trusted-extraction-oracle",
    "verify-corpus-identities.py": "hostile-corpus-identity-verifier",
    "verify-empty-item-vectors.js": "independent-node-empty-item-digest-oracle",
    "verify-jpeg-imageio.swift": "independent-imageio-pixel-oracle",
    "verify-large-jpeg.py": "dimension-ceiling-jpeg-orchestrator",
    "verify-physical-oracle.rb": "independent-ruby26-extractor",
}
REVIEW_ROLES = {
    "independent-review-evidence.txt": "final-independent-review-provenance",
    "independent-review-result.json": "final-independent-review-result",
}


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(256 * 1_024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def aggregate_review_input(artifacts):
    framed = bytearray()
    for item in artifacts:
        framed.extend(item["path"].encode("utf-8"))
        framed.append(0)
        framed.extend(item["sha256"].encode("ascii"))
        framed.append(10)
    return hashlib.sha256(framed).hexdigest()


def main():
    actual = {
        path.name
        for path in ROOT.iterdir()
        if path.is_file() and path.name != MANIFEST_PATH.name
    }
    review_present = set(REVIEW_ROLES) & actual
    if review_present and review_present != set(REVIEW_ROLES):
        raise AssertionError("independent review artifacts must appear as a pair")
    roles = ROLES | (REVIEW_ROLES if review_present else {})
    expected = set(roles)
    if actual != expected:
        missing = sorted(expected - actual)
        unclassified = sorted(actual - expected)
        raise AssertionError(
            f"artifact role map drift: missing={missing}, unclassified={unclassified}"
        )

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    candidate = ROOT / "backup-wire-v3-candidate.md"
    manifest["candidate_sha256"] = sha256(candidate)
    review_artifacts = [
        {"path": name, "sha256": sha256(ROOT / name)}
        for name in sorted(ROLES)
    ]
    manifest["review_input"] = {
        "algorithm": "sha256",
        "framing": "utf8-path-nul-lowercase-sha256-lf-sorted-by-path",
        "sha256": aggregate_review_input(review_artifacts),
        "artifacts": review_artifacts,
    }
    manifest["artifacts"] = [
        {
            "path": name,
            "role": roles[name],
            "byte_count": (ROOT / name).stat().st_size,
            "sha256": sha256(ROOT / name),
        }
        for name in sorted(roles)
    ]
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
    )
    print(
        f"PASS refreshed manifest artifacts={len(manifest['artifacts'])} "
        f"candidate_sha256={manifest['candidate_sha256']}"
    )


if __name__ == "__main__":
    main()
