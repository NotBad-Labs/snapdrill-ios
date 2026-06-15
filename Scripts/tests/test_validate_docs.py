#!/usr/bin/env python3
"""Regression tests for documentation health checks."""
from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "Scripts" / "validate_docs.py"


def load_validate_docs():
    spec = importlib.util.spec_from_file_location("validate_docs", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load Scripts/validate_docs.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate_docs = load_validate_docs()


class ValidateDocsTests(unittest.TestCase):
    def test_vision_principle_ref_resolves(self) -> None:
        target, anchor = validate_docs.resolve_doc_ref("vision:P4")

        self.assertEqual(
            target,
            validate_docs.DOCS_ROOT / "explanations" / "vision.md",
        )
        self.assertEqual(anchor, "vision:P4")
        self.assertTrue(validate_docs.ref_target_exists(target, anchor))

    def test_adr_ref_resolves_to_unique_decision_file(self) -> None:
        target, anchor = validate_docs.resolve_doc_ref("ADR-001")

        self.assertEqual(target.name, "ADR-001-smart-paper-analytics-pricing.md")
        self.assertIsNone(anchor)
        self.assertTrue(validate_docs.ref_target_exists(target, anchor))

    def test_stem_ref_and_heading_anchor_resolve(self) -> None:
        target, anchor = validate_docs.resolve_doc_ref("positioning-and-audience#已决定位")

        self.assertEqual(target.name, "positioning-and-audience.md")
        self.assertEqual(anchor, "已决定位")
        self.assertTrue(validate_docs.ref_target_exists(target, anchor))

    def test_missing_refs_fail_closed(self) -> None:
        missing_adr, missing_adr_anchor = validate_docs.resolve_doc_ref("ADR-999")
        missing_doc, missing_doc_anchor = validate_docs.resolve_doc_ref(
            "not-a-real-upstream-doc"
        )

        self.assertIsNone(missing_adr)
        self.assertIsNone(missing_adr_anchor)
        self.assertIsNone(missing_doc)
        self.assertIsNone(missing_doc_anchor)

    def test_missing_heading_anchor_fails(self) -> None:
        target, anchor = validate_docs.resolve_doc_ref(
            "positioning-and-audience#not-real-anchor"
        )

        self.assertEqual(target.name, "positioning-and-audience.md")
        self.assertEqual(anchor, "not-real-anchor")
        self.assertFalse(validate_docs.ref_target_exists(target, anchor))

    def test_feature_specs_require_acceptance_evidence_row(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        original_docs_root = validate_docs.DOCS_ROOT

        def fake_read(path: Path) -> str:
            if path == original_docs_root / "features" / "active" / "feat-library.md":
                return original_read(path).replace(
                    "| 验收证据 | §4 验证标准 GWT + AllTests | 见本 spec Verify 节 |\n",
                    "",
                )
            return original_read(path)

        validate_docs.read = fake_read
        try:
            validate_docs.validate_feature_intent(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/features/active/feat-library.md: missing intent traceability row '验收证据'",
            errors,
        )

    def test_competitive_analysis_does_not_reset_product_category(self) -> None:
        text = validate_docs.read(
            validate_docs.DOCS_ROOT / "explanations" / "competitive-analysis.md"
        )

        self.assertNotIn("错题本 App 市场已形成三个梯队", text)
        self.assertIn("通用效率工具定位", text)

    def test_current_repo_docs_pass(self) -> None:
        self.assertEqual(validate_docs.run_checks(), [])


if __name__ == "__main__":
    unittest.main()
