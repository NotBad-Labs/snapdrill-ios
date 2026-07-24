#!/usr/bin/env python3
"""Unit tests for documentation generator scripts.

These tests use a temporary mini-doc tree instead of the real repository docs.
They lock the failure modes that matter for CI gates: missing intent references,
invalid Release PRD references, unknown upstream references, and stale
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

import yaml


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
        (self.docs / "product").mkdir(parents=True)
        (self.docs / "decisions").mkdir()
        (self.docs / "features" / "active").mkdir(parents=True)
        (self.docs / "features" / "backlog").mkdir()
        (self.docs / "how-to").mkdir()
        (self.docs / "reference").mkdir()

        (self.docs / "product" / "vision.md").write_text(
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
        self.write_release_prd()
        self.write_release_operations()

        self.module = load_script("generate_intent_traceability")
        self.module.REPO_ROOT = self.root
        self.module.DOCS_ROOT = self.docs
        self.module.FEATURES_DIR = self.docs / "features"
        self.module.OUTPUT = self.docs / "reference" / "intent-traceability.md"

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_release_prd(
        self,
        frontmatter: str = (
            'ratified_decisions: ["C1-A", "C2-Core", "C6-A", "#932-A", "ORI-A"]\n'
            'pending_decisions: ["C9-Pending"]\n'
        ),
        *,
        include_section_7: bool = True,
    ) -> Path:
        ratified = yaml.safe_load(frontmatter)["ratified_decisions"]
        decision_rows = "\n".join(
            f"| {decision} | RATIFIED | Decision {decision} |"
            for decision in ratified
        )
        section_7 = "\n## 7. 明确非目标与隐藏能力\n" if include_section_7 else ""
        outcomes = "\n".join(
            f"{index}. **M{index}** — Outcome {index}"
            for index in range(1, 11)
        )
        path = self.docs / "product" / "release-1-prd.md"
        path.write_text(
            f"---\n{frontmatter}---\n# Release 1 PRD\n\n"
            "| ID | 状态 | 结论 |\n|---|---|---|\n"
            f"{decision_rows}\n\n"
            f"## 3.1 Must outcomes\n\n{outcomes}\n{section_7}",
            encoding="utf-8",
        )
        return path

    def write_release_operations(
        self,
        *,
        refs: tuple[str, ...] = ("C1-A", "C6-A", "#932-A", "ORI-A"),
        outcomes: tuple[str, ...] = tuple(f"M{index}" for index in range(1, 11)),
    ) -> Path:
        release_refs = "\n".join(f"  - release-1:{ref}" for ref in refs)
        oracle_rows = "\n".join(
            f"| {outcome} | {outcome} result oracle | {outcome} owner |"
            for outcome in outcomes
        )
        path = self.docs / "how-to" / "release-and-ci.md"
        path.write_text(
            f"---\nrelease_refs:\n{release_refs}\n---\n"
            "# Release operations\n\n"
            "### M1-M10 双向追溯\n\n"
            "| Must | Result oracle | Evidence owner |\n"
            "|---|---|---|\n"
            f"{oracle_rows}\n",
            encoding="utf-8",
        )
        return path

    def write_feature(
        self,
        body: str,
        *,
        directory: str = "active",
        name: str = "feat-capture.md",
        include_release_outcomes: bool = True,
    ) -> Path:
        if (
            directory == "active"
            and include_release_outcomes
            and "release_outcomes:" not in body
        ):
            closing = body.find("\n---", 4)
            if closing == -1:
                raise ValueError("feature fixture requires closing frontmatter")
            outcomes = ", ".join(f"M{index}" for index in range(1, 11))
            body = body[:closing] + f"\nrelease_outcomes: [{outcomes}]" + body[closing:]
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
        self.assertIn("不证明 Release 1 PRD 符合", content)
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

    def test_collects_release_refs_from_effective_prd(self) -> None:
        known_release_refs, pending_release_refs = self.module.collect_release_refs()

        self.assertEqual(
            list(known_release_refs),
            [
                "release-1:C1-A",
                "release-1:C2-Core",
                "release-1:C6-A",
                "release-1:#932-A",
                "release-1:ORI-A",
                "release-1:section-7",
            ],
        )
        self.assertEqual(pending_release_refs, {"release-1:C9-Pending"})

    def test_rejects_ratified_frontmatter_body_drift(self) -> None:
        path = self.docs / "product" / "release-1-prd.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "| ORI-A | RATIFIED | Decision ORI-A |\n",
                "",
            ),
            encoding="utf-8",
        )

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_release_refs()

        self.assertEqual(raised.exception.code, 1)
        self.assertIn(
            "frontmatter must match RATIFIED decision-summary rows exactly",
            stderr.getvalue(),
        )

    def test_rejects_ratified_pending_overlap(self) -> None:
        self.write_release_prd(
            'ratified_decisions: ["C1-A"]\n'
            'pending_decisions: ["C1-A"]\n'
        )

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_release_refs()

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("cannot be both ratified and pending", stderr.getvalue())

    def test_rejects_missing_release_prd_section_7(self) -> None:
        self.write_release_prd(include_section_7=False)

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_release_refs()

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("missing exact heading", stderr.getvalue())

    def test_rejects_missing_must_outcome_identity(self) -> None:
        path = self.docs / "product" / "release-1-prd.md"
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "10. **M10** — Outcome 10\n",
                "",
            ),
            encoding="utf-8",
        )

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_release_outcomes()

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("labeled exactly M1-M10 in order", stderr.getvalue())

    def test_active_feature_requires_explicit_must_ownership(self) -> None:
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
""",
            include_release_outcomes=False,
        )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    known_refs,
                    known_release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("active feature release_outcomes must be a list", stderr.getvalue())

    def test_rejects_unknown_and_duplicate_release_outcomes(self) -> None:
        all_outcomes = [f"M{index}" for index in range(1, 11)]
        cases = {
            "unknown": (
                [*all_outcomes, "M11"],
                "unknown release_outcomes ['M11']",
            ),
            "duplicate": (
                [*all_outcomes, "M1"],
                "duplicate release_outcomes ['M1']",
            ),
        }

        for name, (outcomes, expected_error) in cases.items():
            with self.subTest(name=name):
                values = ", ".join(outcomes)
                self.write_feature(
                    f"""---
id: feat-capture
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
release_outcomes: [{values}]
---

# Feature: Capture
"""
                )
                stderr = io.StringIO()
                with redirect_stderr(stderr):
                    with self.assertRaises(SystemExit) as raised:
                        self.collect_traceability()

                self.assertEqual(raised.exception.code, 1)
                self.assertIn(expected_error, stderr.getvalue())

    def test_rejects_must_ownership_on_non_active_feature(self) -> None:
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
id: feat-candidate
title: Candidate
status: backlog
tier: undecided
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
release_outcomes: [M1]
---

# Feature: Candidate
""",
            directory="backlog",
            name="feat-candidate.md",
        )

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.collect_traceability()

        self.assertEqual(raised.exception.code, 1)
        self.assertIn(
            "release_outcomes may be non-empty only for active features",
            stderr.getvalue(),
        )

    def test_rejects_unowned_must_outcome(self) -> None:
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
release_outcomes: [M1]
---

# Feature: Capture
"""
        )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    known_refs,
                    known_release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("['M2', 'M3', 'M4', 'M5', 'M6'", stderr.getvalue())

    def test_release_oracle_rows_must_cover_all_outcomes(self) -> None:
        self.write_release_operations(
            outcomes=tuple(f"M{index}" for index in range(1, 10)),
        )

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_release_oracles(
                    self.module.collect_release_outcomes(),
                )

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("oracle rows must match PRD order exactly", stderr.getvalue())

    def test_release_oracle_rows_require_oracle_and_dri(self) -> None:
        cases = {
            "oracle": (
                "| M4 | M4 result oracle | M4 owner |",
                "| M4 | — | M4 owner |",
                "M4 requires a non-empty outcome oracle",
            ),
            "dri": (
                "| M4 | M4 result oracle | M4 owner |",
                "| M4 | M4 result oracle | — |",
                "M4 requires a non-empty DRI",
            ),
        }

        for name, (original, replacement, expected_error) in cases.items():
            with self.subTest(name=name):
                path = self.write_release_operations()
                path.write_text(
                    path.read_text(encoding="utf-8").replace(original, replacement),
                    encoding="utf-8",
                )
                stderr = io.StringIO()
                with redirect_stderr(stderr):
                    with self.assertRaises(SystemExit) as raised:
                        self.module.collect_release_oracles(
                            self.module.collect_release_outcomes(),
                        )

                self.assertEqual(raised.exception.code, 1)
                self.assertIn(expected_error, stderr.getvalue())

    def test_release_oracle_rows_are_scoped_to_exact_section(self) -> None:
        path = self.write_release_operations()
        content = path.read_text(encoding="utf-8")
        path.write_text(
            content.replace(
                "### M1-M10 双向追溯",
                "| M11 | unrelated table row | unrelated owner |\n\n"
                "### M1-M10 双向追溯",
            ),
            encoding="utf-8",
        )

        rows = self.module.collect_release_oracles(
            self.module.collect_release_outcomes(),
        )

        self.assertEqual(list(rows), [f"M{index}" for index in range(1, 11)])

    def test_release_oracle_rows_reject_extra_columns(self) -> None:
        path = self.write_release_operations()
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "| M4 | M4 result oracle | M4 owner |",
                "| M4 | M4 result oracle | M4 owner | unexpected |",
            ),
            encoding="utf-8",
        )

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_release_oracles(
                    self.module.collect_release_outcomes(),
                )

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("M4 oracle row must contain exactly 3 columns", stderr.getvalue())

    def test_release_oracle_requires_one_exact_section_heading(self) -> None:
        path = self.write_release_operations()
        path.write_text(
            path.read_text(encoding="utf-8").replace(
                "### M1-M10 双向追溯",
                "### M1-M10 evidence",
            ),
            encoding="utf-8",
        )

        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_release_oracles(
                    self.module.collect_release_outcomes(),
                )

        self.assertEqual(raised.exception.code, 1)
        self.assertIn("requires exactly one exact heading", stderr.getvalue())

    def test_release_operations_consumers_come_from_frontmatter(self) -> None:
        self.write_release_operations(refs=("C1-A",))

        known_release_refs, _ = self.module.collect_release_refs()

        self.assertEqual(
            known_release_refs["release-1:C1-A"]["operations_consumer"],
            "release-operations",
        )
        self.assertIsNone(
            known_release_refs["release-1:C6-A"]["operations_consumer"]
        )

    def test_rejects_invalid_release_operations_refs(self) -> None:
        cases = {
            "pending": (
                ("C1-A", "C9-Pending"),
                "pending release_refs ['release-1:C9-Pending']",
            ),
            "unknown": (
                ("C1-A", "C9-Unknown"),
                "unknown release_refs ['release-1:C9-Unknown']",
            ),
            "section-7": (
                ("C1-A", "section-7"),
                "release-1:section-7 is not an operations decision",
            ),
        }

        for name, (refs, expected_error) in cases.items():
            with self.subTest(name=name):
                self.write_release_operations(refs=refs)
                stderr = io.StringIO()
                with redirect_stderr(stderr):
                    with self.assertRaises(SystemExit) as raised:
                        self.module.collect_release_refs()

                self.assertEqual(raised.exception.code, 1)
                self.assertIn(expected_error, stderr.getvalue())

    def test_rejects_invalid_release_ref_shapes_and_values(self) -> None:
        cases = {
            "non-list": (
                "release_refs: release-1:C2-Core\n",
                "release_refs must be a non-empty list",
            ),
            "empty": (
                "release_refs: []\n",
                "release_refs must be a non-empty list",
            ),
            "non-string": (
                "release_refs:\n  - 42\n",
                "release_refs entries must be non-empty strings",
            ),
            "duplicate": (
                "release_refs:\n"
                "  - release-1:C2-Core\n"
                "  - release-1:C2-Core\n",
                "duplicate release_refs ['release-1:C2-Core']",
            ),
            "unknown": (
                "release_refs:\n"
                "  - release-1:C2-Core\n"
                "  - release-1:C9-Unknown\n",
                "unknown release_refs ['release-1:C9-Unknown']",
            ),
            "pending": (
                "release_refs:\n"
                "  - release-1:C2-Core\n"
                "  - release-1:C9-Pending\n",
                "pending release_refs ['release-1:C9-Pending']",
            ),
        }

        self.write_feature(
            """---
id: feat-valid
title: Valid Consumer
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:C2-Core
---

# Feature: Valid Consumer
""",
            name="feat-valid.md",
        )

        for name, (release_refs, expected_error) in cases.items():
            with self.subTest(name=name):
                self.write_feature(
                    f"""---
id: feat-invalid
title: Invalid Consumer
status: implemented
tier: free
intent_refs:
  - vision:P1
{release_refs}---

# Feature: Invalid Consumer
""",
                    directory="backlog",
                    name="feat-invalid.md",
                )
                known_refs = self.module.collect_known_refs()
                known_release_refs, pending_release_refs = self.module.collect_release_refs()
                stderr = io.StringIO()
                with redirect_stderr(stderr):
                    with self.assertRaises(SystemExit) as raised:
                        self.module.collect_features(
                            known_refs,
                            known_release_refs,
                            pending_release_refs,
                        )

                self.assertEqual(raised.exception.code, 1)
                self.assertIn(expected_error, stderr.getvalue())

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
        self.assertIn("feat-advanced-stats", {feature["id"] for feature in features})

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

    def test_release_operations_are_not_fabricated_as_feature_consumers(self) -> None:
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
            "| [`release-1:C1-A`](../product/release-1-prd.md) | `release-operations` |",
            content,
        )
        self.assertIn(
            "| [`release-1:C6-A`](../product/release-1-prd.md) | `release-operations` |",
            content,
        )
        self.assertIn(
            "| [`release-1:#932-A`](../product/release-1-prd.md) | `release-operations` |",
            content,
        )
        self.assertIn(
            "| [`release-1:ORI-A`](../product/release-1-prd.md) | `release-operations` |",
            content,
        )

        for decision in ("C1-A", "C6-A", "#932-A", "ORI-A"):
            with self.subTest(decision=decision):
                self.write_feature(
                    f"""---
id: feat-capture
title: Capture
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
  - release-1:{decision}
---

# Feature: Capture
"""
                )
                stderr = io.StringIO()
                with redirect_stderr(stderr):
                    with self.assertRaises(SystemExit) as raised:
                        self.module.collect_features(
                            known_refs,
                            known_release_refs,
                            pending_release_refs,
                        )

                self.assertEqual(raised.exception.code, 1)
                self.assertIn("release-operations-only", stderr.getvalue())

    def test_rejects_ratified_release_decision_without_consumer(self) -> None:
        self.write_release_prd(
            'ratified_decisions: ["C1-A", "C2-Core", "C6-A", "#932-A", "ORI-A", "D4-B"]\n'
            "pending_decisions: []\n"
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
  - release-1:C2-Core
---

# Feature: Capture
"""
        )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        stderr = io.StringIO()
        with redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                self.module.collect_features(
                    known_refs,
                    known_release_refs,
                    pending_release_refs,
                )

        self.assertEqual(raised.exception.code, 1)
        self.assertIn(
            "ratified release refs require at least one Feature or "
            "release-operations consumer ['release-1:D4-B']",
            stderr.getvalue(),
        )

    def test_safety_decisions_require_feature_consumers(self) -> None:
        safety_decisions = ("S1-A", "M1-A", "D4S-A")
        self.write_release_prd(
            'ratified_decisions: ["C1-A", "C2-Core", "C6-A", "#932-A", '
            '"ORI-A", "S1-A", "M1-A", "D4S-A"]\n'
            "pending_decisions: []\n"
        )

        def write_with_decisions(decisions: tuple[str, ...]) -> None:
            refs = "\n".join(
                f"  - release-1:{decision}"
                for decision in ("C2-Core", *decisions)
            )
            self.write_feature(
                f"""---
id: feat-library
title: Library
status: implemented
tier: free
intent_refs:
  - vision:P1
release_refs:
{refs}
---

# Feature: Library
"""
            )

        known_refs = self.module.collect_known_refs()
        known_release_refs, pending_release_refs = self.module.collect_release_refs()
        write_with_decisions(safety_decisions)
        self.module.collect_features(
            known_refs,
            known_release_refs,
            pending_release_refs,
        )

        for omitted in safety_decisions:
            with self.subTest(omitted=omitted):
                write_with_decisions(
                    tuple(
                        decision
                        for decision in safety_decisions
                        if decision != omitted
                    )
                )
                stderr = io.StringIO()
                with redirect_stderr(stderr):
                    with self.assertRaises(SystemExit) as raised:
                        self.module.collect_features(
                            known_refs,
                            known_release_refs,
                            pending_release_refs,
                        )

                self.assertEqual(raised.exception.code, 1)
                self.assertIn(f"release-1:{omitted}", stderr.getvalue())

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
        self.assertIn("## Release 1 -> Feature / Operations Consumers", first)
        self.assertIn("## Release 1 Must Outcome -> Feature / Proof Plan", first)
        self.assertIn("不证明语义正确、实现符合", first)
        self.assertIn("M1-M10 已执行证据", first)


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
        self.assertIn("不表示符合 Release 1 PRD", content)
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
