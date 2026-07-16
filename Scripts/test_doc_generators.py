#!/usr/bin/env python3
"""Unit tests for documentation generator scripts.

These tests use a temporary mini-doc tree instead of the real repository docs.
They lock the failure modes that matter for CI gates: missing intent references,
invalid Release Contract references, unknown upstream references, and stale
generated output.
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
        (self.docs / "features" / "backlog").mkdir()
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
        self.write_release_contract()

        self.module = load_script("generate_intent_traceability")
        self.module.REPO_ROOT = self.root
        self.module.DOCS_ROOT = self.docs
        self.module.FEATURES_DIR = self.docs / "features"
        self.module.OUTPUT = self.docs / "reference" / "intent-traceability.md"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_release_contract(
        self,
        frontmatter: str = (
            'ratified_decisions: ["C1-A", "C2-Core", "C6-A"]\n'
            'pending_decisions: ["C9-Pending"]\n'
        ),
        *,
        include_section_7: bool = True,
    ) -> Path:
        section_7 = "\n## 7. 明确非目标与隐藏能力\n" if include_section_7 else ""
        path = self.docs / "reference" / "release-1-contract.md"
        path.write_text(
            f"---\n{frontmatter}---\n# Release 1 Product Contract\n{section_7}",
            encoding="utf-8",
        )
        return path

    def write_feature(
        self,
        body: str,
        *,
        directory: str = "active",
        name: str = "feat-capture.md",
    ) -> Path:
        path = self.docs / "features" / directory / name
        path.write_text(body, encoding="utf-8")
        return path

    def collect_traceability(self) -> tuple[dict, dict, list[dict]]:
        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        features = self.module.collect_features(
            known_refs,
            known_release_refs,
            pending_release_refs,
        )
        return known_refs, known_release_refs, features

    def test_generates_feature_to_intent_index(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
  - ADR-001
release_refs:
  - release-1:C2-Core
---

# Feature: Capture
"""
        )

        refs, release_refs, features = self.collect_traceability()
        content = self.module.render(features, refs, release_refs)

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

    def test_renders_undecided_tier_for_unratified_candidate(self) -> None:
        self.write_feature(
            """---
title: Candidate
status: backlog
tier: undecided
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
---

# Feature: Candidate
"""
        )

        refs, release_refs, features = self.collect_traceability()
        content = self.module.render(features, refs, release_refs)

        self.assertIn("| 未定 |", content)

    def test_intent_index_does_not_claim_release_conformance(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
---

# Feature: Capture
"""
        )

        refs, release_refs, features = self.collect_traceability()
        content = self.module.render(features, refs, release_refs)

        self.assertIn("🧩 实现存在", content)
        self.assertIn("不证明 Release 1 合同符合", content)
        self.assertNotIn("✅ 已实现", content)

    def test_rejects_missing_intent_refs(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
release_refs:
  - release-1:C2-Core
---

# Feature: Capture
"""
        )

        refs = self.module.collect_known_refs()
        release_refs, pending_release_refs = self.module.collect_release_refs()
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    refs,
                    release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)

    def test_rejects_unknown_intent_refs(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P999
release_refs:
  - release-1:C2-Core
---

# Feature: Capture
"""
        )

        refs = self.module.collect_known_refs()
        release_refs, pending_release_refs = self.module.collect_release_refs()
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    refs,
                    release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)

    def test_check_mode_rejects_stale_output(self) -> None:
        self.write_feature(
            """---
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
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

    def test_collects_release_refs_from_effective_contract(self) -> None:
        known_release_refs, pending_release_refs = self.module.collect_release_refs()

        self.assertEqual(
            list(known_release_refs),
            [
                "release-1:C1-A",
                "release-1:C2-Core",
                "release-1:C6-A",
                "release-1:section-7",
            ],
        )
        self.assertEqual(pending_release_refs, {"release-1:C9-Pending"})

    def test_rejects_invalid_release_ref_shapes_and_values(self) -> None:
        cases = {
            "non-list": "release_refs: release-1:C2-Core\n",
            "empty": "release_refs: []\n",
            "non-string": "release_refs:\n  - 42\n",
            "duplicate": (
                "release_refs:\n"
                "  - release-1:C2-Core\n"
                "  - release-1:C2-Core\n"
            ),
            "unknown": "release_refs:\n  - release-1:C9-Unknown\n",
            "pending": "release_refs:\n  - release-1:C9-Pending\n",
        }

        for name, release_refs in cases.items():
            with self.subTest(name=name):
                self.write_feature(
                    f"""---
id: feat-capture
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
{release_refs}---

# Feature: Capture
"""
                )
                known_refs = self.module.collect_known_refs()
                known_release_refs, pending_release_refs = self.module.collect_release_refs()
                with redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as raised:
                        self.module.collect_features(
                            known_refs,
                            known_release_refs,
                            pending_release_refs,
                        )

                self.assertEqual(raised.exception.code, 1)

    def test_active_feature_requires_exact_release_ref(self) -> None:
        self.write_feature(
            """---
id: feat-capture
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:section-7
---

# Feature: Capture
"""
        )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    known_refs,
                    known_release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)

    def test_section_7_only_allows_named_backlog_features(self) -> None:
        self.write_feature(
            """---
id: feat-advanced-stats
title: Advanced Stats
status: backlog
tier: undecided
intent_refs:
  - vision:P1
release_refs:
  - release-1:section-7
---

# Feature: Advanced Stats
""",
            directory="backlog",
            name="feat-advanced-stats.md",
        )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        features = self.module.collect_features(
            known_refs,
            known_release_refs,
            pending_release_refs,
        )
        self.assertEqual(features[0]["id"], "feat-advanced-stats")

        self.write_feature(
            """---
id: feat-image-enhance
title: Image Enhance
status: backlog
tier: undecided
intent_refs:
  - vision:P1
release_refs:
  - release-1:section-7
---

# Feature: Image Enhance
""",
            directory="backlog",
            name="feat-image-enhance.md",
        )
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    known_refs,
                    known_release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)

    def test_release_operations_are_not_fabricated_as_feature_owners(self) -> None:
        self.write_feature(
            """---
id: feat-capture
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
---

# Feature: Capture
"""
        )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        features = self.module.collect_features(
            known_refs,
            known_release_refs,
            pending_release_refs,
        )
        content = self.module.render(features, known_refs, known_release_refs)

        self.assertIn(
            "| [`release-1:C1-A`](release-1-contract.md) | `release-operations` |",
            content,
        )
        self.assertIn(
            "| [`release-1:C6-A`](release-1-contract.md) | `release-operations` |",
            content,
        )

        self.write_feature(
            """---
id: feat-capture
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:C6-A
---

# Feature: Capture
"""
        )
        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    known_refs,
                    known_release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)

    def test_release_index_is_deterministic_and_disclaims_conformance(self) -> None:
        self.write_feature(
            """---
id: feat-capture
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
---

# Feature: Capture
"""
        )
        self.write_feature(
            """---
id: feat-word-export
title: Word Export
status: backlog
tier: undecided
intent_refs:
  - vision:P1
release_refs:
  - release-1:section-7
---

# Feature: Word Export
""",
            directory="backlog",
            name="feat-word-export.md",
        )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        features = self.module.collect_features(
            known_refs,
            known_release_refs,
            pending_release_refs,
        )
        first = self.module.render(features, known_refs, known_release_refs)
        second = self.module.render(features, known_refs, known_release_refs)

        self.assertEqual(first, second)
        self.assertIn("## Feature -> Release 1", first)
        self.assertIn("## Release 1 -> Feature / Operations", first)
        self.assertIn("不证明语义正确、实现符合或候选纳入", first)
        self.assertIn("不证明 M1-M10 已有证据", first)


class FeatureStatusTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.features = self.root / "docs" / "features" / "active"
        self.reference = self.root / "docs" / "reference"
        self.features.mkdir(parents=True)
        self.reference.mkdir(parents=True)

        self.module = load_script("generate_feature_status")
        self.module.REPO_ROOT = self.root
        self.module.FEATURES_DIR = self.root / "docs" / "features"
        self.module.OUTPUT = self.reference / "feature-status.md"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_feature(self, frontmatter: str) -> Path:
        path = self.features / "feat-capture.md"
        path.write_text(f"---\n{frontmatter}---\n# Feature: Capture\n", encoding="utf-8")
        return path

    def test_collects_valid_feature_status_frontmatter(self) -> None:
        self.write_feature(
            """id: feat-capture
title: Capture
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-14
"""
        )

        specs = self.module.collect()

        self.assertEqual(len(specs), 1)
        self.assertEqual(specs[0]["id"], "feat-capture")

    def test_rejects_unknown_feature_status(self) -> None:
        self.write_feature(
            """id: feat-capture
title: Capture
status: maybe
tier: free
blocked_by: []
mode: full
last_updated: 2026-06-14
"""
        )

        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect()

        self.assertEqual(raised.exception.code, 1)

    def test_renders_undecided_tier_for_unratified_candidate(self) -> None:
        self.write_feature(
            """id: feat-capture
title: Candidate
status: backlog
tier: undecided
blocked_by: []
mode: lightweight
last_updated: 2026-07-12
"""
        )

        content = self.module.render(self.module.collect())

        self.assertIn("| 未定 |", content)

    def test_implemented_label_does_not_claim_release_conformance(self) -> None:
        self.write_feature(
            """id: feat-capture
title: Capture
status: implemented
tier: free
blocked_by: []
mode: full
last_updated: 2026-07-16
"""
        )

        content = self.module.render(self.module.collect())

        self.assertIn("🧩 实现存在", content)
        self.assertIn("不表示符合 Release 1 Contract", content)
        self.assertNotIn("✅ 已实现", content)

    def test_rejects_invalid_blocked_by_type(self) -> None:
        self.write_feature(
            """id: feat-capture
title: Capture
status: blocked
tier: free
blocked_by: 479
mode: full
last_updated: 2026-06-14
"""
        )

        with redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect()

        self.assertEqual(raised.exception.code, 1)


if __name__ == "__main__":
    unittest.main()
