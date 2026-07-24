#!/usr/bin/env python3
"""Regression tests for documentation health checks."""
from __future__ import annotations

import importlib.util
import unittest
from collections.abc import Callable
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
    def validation_errors_after_removing(
        self,
        path: Path,
        markers: tuple[str, ...],
        validator: Callable[[list[str]], None],
    ) -> list[str]:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(candidate: Path) -> str:
            text = original_read(candidate)
            if candidate == path:
                for marker in markers:
                    text = text.replace(marker, "")
            return text

        validate_docs.read = fake_read
        try:
            validator(errors)
        finally:
            validate_docs.read = original_read
        return errors

    def test_vision_principle_ref_resolves(self) -> None:
        target, anchor = validate_docs.resolve_doc_ref("vision:P4")

        self.assertEqual(
            target,
            validate_docs.DOCS_ROOT / "product" / "vision.md",
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

    def test_release_one_prd_is_the_only_declared_prd(self) -> None:
        errors: list[str] = []

        validate_docs.validate_product_document_authority(errors)

        self.assertEqual(errors, [])

    def test_current_product_authority_surfaces_use_standard_terms(self) -> None:
        errors: list[str] = []

        validate_docs.validate_current_product_authority_terms(errors)

        self.assertEqual(errors, [])

    def test_legacy_product_authority_term_in_package_doc_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        package_readme = validate_docs.PACKAGES_ROOT / "SnapDrillCore" / "README.md"

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == package_readme:
                return f"{text}\nRelease Contract\n"
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_current_product_authority_terms(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                error.startswith("Packages/SnapDrillCore/README.md:")
                and "obsolete product authority term 'Release Contract'" in error
                for error in errors
            )
        )

    def test_missing_product_vision_layer_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == validate_docs.PRODUCT_VISION:
                return text.replace("layer: product-vision\n", "layer: explanation\n")
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_product_document_authority(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/product/vision.md: layer must be 'product-vision'",
            errors,
        )
        self.assertTrue(
            any(
                "Product direction must have exactly one product-vision layer"
                in error
                for error in errors
            )
        )

    def test_duplicate_product_vision_layer_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == validate_docs.RELEASE_ONE_PRD:
                return text.replace("layer: release-prd\n", "layer: product-vision\n")
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_product_document_authority(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                "Product direction must have exactly one product-vision layer"
                in error
                and "docs/product/release-1-prd.md" in error
                for error in errors
            )
        )

    def test_missing_release_prd_role_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == validate_docs.RELEASE_ONE_PRD:
                return text.replace("product_role: release-prd\n", "")
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_product_document_authority(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/product/release-1-prd.md: "
            "product_role must be 'release-prd'",
            errors,
        )
        self.assertTrue(
            any(
                "Release 1 must have exactly one declared PRD authority" in error
                for error in errors
            )
        )

    def test_duplicate_release_prd_role_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        duplicate_path = validate_docs.DOCS_ROOT / "product" / "vision.md"

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == duplicate_path:
                return text.replace(
                    "layer: product-vision\n",
                    "layer: product-vision\n"
                    "release: 1\n"
                    "product_role: release-prd\n",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_product_document_authority(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                "Release 1 must have exactly one declared PRD authority" in error
                and "docs/product/vision.md" in error
                for error in errors
            )
        )

    def test_duplicate_release_prd_layer_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        duplicate_path = validate_docs.DOCS_ROOT / "product" / "vision.md"

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == duplicate_path:
                return text.replace(
                    "layer: product-vision\n",
                    "layer: release-prd\nrelease: 1\n",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_product_document_authority(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                "Release 1 must have exactly one release-prd layer" in error
                and "docs/product/vision.md" in error
                for error in errors
            )
        )

    def test_root_prd_filename_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        original_tracked_paths = (
            validate_docs.validate_document_control.tracked_markdown_paths
        )
        root_prd = validate_docs.REPO_ROOT / "PRD.md"

        def fake_read(path: Path) -> str:
            if path == root_prd:
                return "# Parallel PRD\n"
            return original_read(path)

        def fake_tracked_paths(root: Path) -> set[str]:
            return original_tracked_paths(root) | {"PRD.md"}

        validate_docs.read = fake_read
        validate_docs.validate_document_control.tracked_markdown_paths = (
            fake_tracked_paths
        )
        try:
            validate_docs.validate_product_document_authority(errors)
        finally:
            validate_docs.read = original_read
            validate_docs.validate_document_control.tracked_markdown_paths = (
                original_tracked_paths
            )

        self.assertIn(
            "PRD.md: PRD-named Markdown duplicates or obscures the owning "
            "Release PRD",
            errors,
        )

    def test_current_admission_policy_and_templates_are_complete(self) -> None:
        errors: list[str] = []

        validate_docs.validate_current_admission(errors)

        self.assertEqual(errors, [])

    def test_current_admission_template_requires_base_and_evidence(self) -> None:
        path = (
            validate_docs.REPO_ROOT
            / ".github"
            / "ISSUE_TEMPLATE"
            / "bug_report.md"
        )

        errors = self.validation_errors_after_removing(
            path,
            ("Base / current evidence",),
            validate_docs.validate_current_admission,
        )

        self.assertIn(
            ".github/ISSUE_TEMPLATE/bug_report.md: current admission template "
            "missing requirement: base and current evidence",
            errors,
        )

    def test_current_admission_template_requires_authority_and_outcome(self) -> None:
        path = (
            validate_docs.REPO_ROOT
            / ".github"
            / "ISSUE_TEMPLATE"
            / "chore.md"
        )

        errors = self.validation_errors_after_removing(
            path,
            ("Authority / outcome",),
            validate_docs.validate_current_admission,
        )

        self.assertIn(
            ".github/ISSUE_TEMPLATE/chore.md: current admission template "
            "missing requirement: authority and outcome",
            errors,
        )

    def test_current_admission_template_requires_routing_and_gates(self) -> None:
        path = (
            validate_docs.REPO_ROOT
            / ".github"
            / "ISSUE_TEMPLATE"
            / "feature_request.md"
        )

        errors = self.validation_errors_after_removing(
            path,
            ("Routing / dependencies / unresolved gates",),
            validate_docs.validate_current_admission,
        )

        self.assertIn(
            ".github/ISSUE_TEMPLATE/feature_request.md: current admission template "
            "missing requirement: routing dependencies and gates",
            errors,
        )

    def test_current_admission_rejects_number_and_state_only_authority(self) -> None:
        path = (
            validate_docs.DOCS_ROOT
            / "how-to"
            / "definition-of-ready.md"
        )

        errors = self.validation_errors_after_removing(
            path,
            (
                "Age, number",
                "open / closed state, Draft / Ready state",
            ),
            validate_docs.validate_current_admission,
        )

        self.assertIn(
            "docs/how-to/definition-of-ready.md: current admission policy "
            "missing requirement: age or number does not authorize",
            errors,
        )
        self.assertIn(
            "docs/how-to/definition-of-ready.md: current admission policy "
            "missing requirement: workflow state does not authorize",
            errors,
        )

    def test_merge_authorization_requires_exact_head_binding(self) -> None:
        path = (
            validate_docs.DOCS_ROOT
            / "how-to"
            / "parallel-lanes.md"
        )

        errors = self.validation_errors_after_removing(
            path,
            ("`expected_head_sha`",),
            validate_docs.validate_merge_authorization,
        )

        self.assertIn(
            "docs/how-to/parallel-lanes.md: merge authorization policy "
            "missing requirement: merge binds the displayed exact head",
            errors,
        )

    def test_merge_authorization_invalidates_a_moved_head(self) -> None:
        path = validate_docs.REPO_ROOT / ".github" / "PULL_REQUEST_TEMPLATE.md"

        errors = self.validation_errors_after_removing(
            path,
            ("原授权失效",),
            validate_docs.validate_merge_authorization,
        )

        self.assertIn(
            ".github/PULL_REQUEST_TEMPLATE.md: merge authorization policy "
            "missing requirement: a moved head invalidates authorization",
            errors,
        )

    def test_competitive_analysis_does_not_reset_product_category(self) -> None:
        text = validate_docs.read(
            validate_docs.DOCS_ROOT / "explanations" / "competitive-analysis.md"
        )

        self.assertNotIn("错题本 App 市场已形成三个梯队", text)
        self.assertIn("通用效率工具定位", text)

    def test_positioning_reset_claims_fail_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        original_docs_root = validate_docs.DOCS_ROOT

        def fake_read(path: Path) -> str:
            if path == original_docs_root / "explanations" / "competitive-analysis.md":
                return "错题本 App 市场已形成三个梯队：\n"
            return original_read(path)

        validate_docs.read = fake_read
        try:
            validate_docs.validate_positioning_resets(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/explanations/competitive-analysis.md:1 positioning reset: "
            "错题本 App 市场已形成三个梯队",
            errors,
        )

    def test_positive_positioning_terms_fail_closed(self) -> None:
        path = validate_docs.DOCS_ROOT / "features" / "active" / "feat-library.md"

        severity, message = validate_docs.classify_positioning_line(
            path,
            "SnapDrill 是面向学生的儿童作业工具。",
        )

        self.assertEqual(severity, "error")
        self.assertEqual(message, "positive pre-pivot positioning term")

    def test_negation_and_guardrail_contexts_do_not_fail(self) -> None:
        path = validate_docs.DOCS_ROOT / "features" / "active" / "feat-library.md"

        examples = [
            "避免把资料库描述成儿童、作业或校园专用场景。",
            "SnapDrill 不面向儿童。",
            "Profile 不表达为儿童、学生或独立账号。",
            "不建立儿童账户或儿童模式。",
        ]

        for line in examples:
            with self.subTest(line=line):
                severity, message = validate_docs.classify_positioning_line(path, line)
                self.assertIsNone(severity)
                self.assertIsNone(message)

    def test_positioning_taxonomy_terms_are_warning_only(self) -> None:
        path = validate_docs.DOCS_ROOT / "features" / "active" / "feat-library.md"

        severity, message = validate_docs.classify_positioning_line(
            path,
            "字段配置支持学科 / 年级 / 来源。",
        )

        self.assertEqual(severity, "warning")
        self.assertEqual(message, "taxonomy term requires PO context, not a hard fail")

    def test_taxonomy_canonical_terms_fail_in_current_docs(self) -> None:
        path = validate_docs.DOCS_ROOT / "features" / "active" / "feat-library.md"

        examples = [
            "字段配置支持学科 / 年级 / 来源。",
            "Use `CategorySystemKey.subject` for the primary dimension.",
            "The library.sort_by_subject key drives sorting.",
        ]

        for line in examples:
            with self.subTest(line=line):
                severity, message = validate_docs.classify_taxonomy_canonical_line(path, line)
                self.assertEqual(severity, "error")
                self.assertEqual(
                    message,
                    "old taxonomy term; use category/level canonical terminology",
                )

    def test_ambiguous_english_taxonomy_terms_warn_instead_of_fail(self) -> None:
        path = validate_docs.DOCS_ROOT / "features" / "active" / "feat-library.md"

        severity, message = validate_docs.classify_taxonomy_canonical_line(
            path,
            "This product is subject to platform constraints.",
        )

        self.assertEqual(severity, "warning")
        self.assertEqual(message, "ambiguous taxonomy term requires human review")

    def test_taxonomy_negation_and_allow_marker_do_not_fail(self) -> None:
        path = validate_docs.DOCS_ROOT / "explanations" / "positioning-and-audience.md"

        examples = [
            "无注册，不要求姓名、手机号、学校或年级。",
            "历史说明：旧版本使用学科字段。 <!-- taxonomy-allow: historical quote -->",
        ]

        for line in examples:
            with self.subTest(line=line):
                severity, message = validate_docs.classify_taxonomy_canonical_line(path, line)
                self.assertIsNone(severity)
                self.assertIsNone(message)

    def test_taxonomy_legal_gated_docs_warn_instead_of_fail(self) -> None:
        path = validate_docs.DOCS_ROOT / "reference" / "appstore-metadata.md"

        severity, message = validate_docs.classify_taxonomy_canonical_line(
            path,
            "Subject, source, tags, and grade classification.",
        )

        self.assertEqual(severity, "warning")
        self.assertEqual(message, "legal/fact-gated taxonomy term requires owner review")

    def test_historical_adr_and_ui_redesign_are_excluded_from_term_scan(self) -> None:
        adr_path = validate_docs.DOCS_ROOT / "decisions" / "ADR-003-dual-region-release.md"
        redesign_path = (
            validate_docs.DOCS_ROOT / "ui-redesign" / "library-flagship-polish-plan.md"
        )
        generated_path = validate_docs.DOCS_ROOT / "reference" / "feature-status.md"

        self.assertTrue(validate_docs.should_skip_positioning_term_scan(adr_path))
        self.assertTrue(validate_docs.should_skip_positioning_term_scan(redesign_path))
        self.assertTrue(validate_docs.should_skip_positioning_term_scan(generated_path))
        self.assertTrue(validate_docs.should_skip_taxonomy_canonical_scan(adr_path))
        self.assertTrue(validate_docs.should_skip_taxonomy_canonical_scan(redesign_path))
        self.assertTrue(validate_docs.should_skip_taxonomy_canonical_scan(generated_path))

    def test_frozen_audit_evidence_is_excluded_from_current_term_scan(self) -> None:
        frozen_path = (
            validate_docs.DOCS_ROOT
            / "reference"
            / "audits"
            / "2026-07-repository"
            / "phases"
            / "02-results.md"
        )

        self.assertTrue(validate_docs.is_inactive_historical_doc(frozen_path))
        self.assertTrue(validate_docs.should_skip_positioning_term_scan(frozen_path))
        self.assertTrue(validate_docs.should_skip_taxonomy_canonical_scan(frozen_path))

    def test_repo_owned_package_docs_are_scanned_for_taxonomy_contracts(self) -> None:
        owned = validate_docs.PACKAGES_ROOT / "SnapDrillData" / "README.md"
        third_party = (
            validate_docs.PACKAGES_ROOT / "SnapDrillFeatures" / ".build"
            / "checkouts" / "SomeDependency" / "README.md"
        )

        self.assertTrue(validate_docs.is_repo_owned_package_doc(owned))
        self.assertFalse(validate_docs.is_repo_owned_package_doc(third_party))
        self.assertIn(owned, list(validate_docs.iter_taxonomy_contract_docs()))

    def test_legal_gated_docs_warn_instead_of_fail(self) -> None:
        path = validate_docs.DOCS_ROOT / "reference" / "appstore-metadata.md"

        severity, message = validate_docs.classify_positioning_line(
            path,
            "SnapDrill is a productivity utility for homework.",
        )

        self.assertEqual(severity, "warning")
        self.assertEqual(message, "legal/fact-gated positioning term requires owner review")

    def test_current_repo_docs_pass(self) -> None:
        self.assertEqual(validate_docs.run_checks(), [])


if __name__ == "__main__":
    unittest.main()
