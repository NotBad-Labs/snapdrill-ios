#!/usr/bin/env python3

import importlib.util
import json
import pathlib
import sys


sys.dont_write_bytecode = True
ROOT = pathlib.Path(__file__).resolve().parent
REFRESH_PATH = ROOT / "refresh-corpus-identities.py"
SPECIFICATION = importlib.util.spec_from_file_location(
    "corpus_identity_refresh",
    REFRESH_PATH,
)
if SPECIFICATION is None or SPECIFICATION.loader is None:
    raise RuntimeError("cannot load corpus identity builder")
REFRESH = importlib.util.module_from_spec(SPECIFICATION)
SPECIFICATION.loader.exec_module(REFRESH)


def main():
    expected = json.loads(
        (ROOT / "corpus-identities.json").read_text(encoding="utf-8")
    )
    observed = REFRESH.build_manifest()
    if observed != expected:
        raise AssertionError("generated corpus identities changed")
    case_count = sum(
        len(cases) for cases in observed["corpora"].values()
    )
    print(
        f"PASS corpus identities cases={case_count} "
        f"candidate_sha256={observed['candidate_sha256']}"
    )


if __name__ == "__main__":
    main()
