#!/usr/bin/env python3
"""Unit tests for documentation generator scripts.

These tests use a temporary mini-doc tree instead of the real repository docs.
They lock the failure modes that matter for CI gates: missing intent references,
unknown upstream references, and stale generated output.
"""
from __future__ import annotations

import importlib.util
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path
from unittest.mock import patch


SCRIPTS_DIR = Path(__file__).resolve().parent


def load_script(name: str):
    path = SCRIPTS_DIR / f"{name}.py"
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


class IntentTraceabilityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.docs = self.root / "docs"
        (self.docs / "explanations").mkdir(parents=True)
        (self.docs / "decisions").mkdir()
        (self.docs / "features" / "active").mkdir(parents=True)
        (self.docs / "reference").mkdir()

        (self.docs / "explanations" / "vision.md").write_text(
            "# Vision\n\n### P1. Capture and organize work\n",
            encoding="utf-8",
        )
        (self.docs / "decisions" / "ADR-001-local-first.md").write_text(
            "# ADR-001: Local-first storage\n",
            encoding="utf-8",
        )
        (self.docs / "decisions" / "ADR-002-legacy-cloud.md").write_text(
            """---
current_status: superseded
historical_record: true
current_authority: docs/decisions/ADR-001-local-first.md
---
# ADR-002: Legacy cloud analytics
""",
            encoding="utf-8",
        )

        self.module = load_script("generate_intent_traceability")
        self.module.REPO_ROOT = self.root
        self.module.DOCS_ROOT = self.docs
        self.module.FEATURES_DIR = self.docs / "features"
        self.module.OUTPUT = self.docs / "reference" / "intent-traceability.md"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_feature(self, body: str) -> Path:
        path = self.docs / "features" / "active" / "feat-capture.md"
        path.write_text(body, encoding="utf-8")
        return path

    def test_generates_feature_to_intent_index(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
  - ADR-001
---

# Feature: Capture
"""
        )

        refs = self.module.collect_known_refs()
        features = self.module.collect_features(refs)
        content = self.module.render(features, refs)

        self.assertIn("vision:P1", content)
        self.assertIn("ADR-001", content)
        self.assertIn("Capture", content)

    def test_historical_adr_labels_show_current_authority(self) -> None:
        refs = self.module.collect_known_refs()

        self.assertIn("ADR-002", refs)
        self.assertEqual(
            refs["ADR-002"]["label"],
            "历史记录（已取代，当前权威：ADR-001）：Legacy cloud analytics",
        )

    def test_rejects_missing_intent_refs(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
---

# Feature: Capture
"""
        )

        refs = self.module.collect_known_refs()
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(refs)

        self.assertEqual(raised.exception.code, 1)

    def test_rejects_unknown_intent_refs(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P999
---

# Feature: Capture
"""
        )

        refs = self.module.collect_known_refs()
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(refs)

        self.assertEqual(raised.exception.code, 1)

    def test_check_mode_rejects_stale_output(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
---

# Feature: Capture
"""
        )
        self.module.OUTPUT.write_text("stale\n", encoding="utf-8")

        with redirect_stderr(io.StringIO()):
            with patch.object(sys, "argv", ["generate_intent_traceability.py", "--check"]):
                with self.assertRaises(SystemExit) as raised:
                    self.module.main()

        self.assertEqual(raised.exception.code, 1)


if __name__ == "__main__":
    unittest.main()
