#!/usr/bin/env python3

import hashlib
import importlib.util
import json
import pathlib
import sys
import tempfile


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
OUTPUT = ROOT / "corpus-identities.json"


def load_module(name, filename):
    path = ROOT / filename
    specification = importlib.util.spec_from_file_location(name, path)
    if specification is None or specification.loader is None:
        raise RuntimeError(f"cannot load {filename}")
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


TYPE_CORPUS = load_module("identity_type_corpus", "generate-type-corpus.py")
CHECK_CORPUS = load_module("identity_check_corpus", "generate-check-corpus.py")
SEMANTIC_CORPUS = load_module(
    "identity_semantic_corpus",
    "generate-semantic-corpus.py",
)
STRUCTURE_CORPUS = load_module(
    "identity_structure_corpus",
    "generate-structure-corpus.py",
)
JPEG_CORPUS = load_module(
    "identity_jpeg_corpus",
    "test-jpeg-grammar.py",
)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(256 * 1_024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ordered(cases):
    return sorted(cases, key=lambda case: case["case_id"])


def build_manifest():
    with tempfile.TemporaryDirectory(
        prefix="snapdrill-v3-corpus-identities-"
    ) as directory:
        temporary = pathlib.Path(directory)
        type_root = temporary / "type"
        check_root = temporary / "check"
        semantic_root = temporary / "semantic"
        structure_root = temporary / "structure"
        for root in (type_root, check_root, semantic_root, structure_root):
            root.mkdir()

        type_cases = TYPE_CORPUS.generate_corpus(type_root)
        check_cases = [
            CHECK_CORPUS.apply_case(check_root, definition)
            for definition in CHECK_CORPUS.build_cases()
        ]
        semantic_cases = SEMANTIC_CORPUS.generate_corpus(semantic_root)
        structure_cases = STRUCTURE_CORPUS.generate_corpus(structure_root)

    return {
        "manifest_version": 1,
        "source_baseline_sha256": sha256(
            ROOT / "iOS-26.5-full-v3.sqlite"
        ),
        "candidate_sha256": sha256(
            ROOT / "backup-wire-v3-candidate.md"
        ),
        "corpora": {
            "check": ordered(check_cases),
            "jpeg-grammar": JPEG_CORPUS.build_case_manifest(),
            "semantic": ordered(semantic_cases),
            "structure": ordered(structure_cases),
            "type": ordered(type_cases),
        },
    }


def main():
    manifest = build_manifest()
    OUTPUT.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    case_count = sum(
        len(cases) for cases in manifest["corpora"].values()
    )
    print(
        f"PASS refreshed corpus identities cases={case_count} "
        f"sha256={sha256(OUTPUT)}"
    )


if __name__ == "__main__":
    main()
