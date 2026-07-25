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
        target, anchor = validate_docs.resolve_doc_ref("ADR-002")

        self.assertEqual(target.name, "ADR-002-remove-att-authorization.md")
        self.assertIsNone(anchor)
        self.assertTrue(validate_docs.ref_target_exists(target, anchor))

    def test_current_architecture_decisions_pass(self) -> None:
        errors: list[str] = []

        validate_docs.validate_architecture_decisions(errors)

        self.assertEqual(errors, [])

    def test_active_adr_rejects_retired_status(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        adr = validate_docs.ADR_ROOT / "ADR-002-remove-att-authorization.md"

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == adr:
                return text.replace("status: accepted", "status: superseded")
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_architecture_decisions(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any("active ADR status must be one of" in error for error in errors)
        )

    def test_active_adr_requires_standard_sections(self) -> None:
        errors = self.validation_errors_after_removing(
            validate_docs.ADR_ROOT / "ADR-005-analytics-privacy-strategy.md",
            ("## 备选方案（Alternatives）",),
            validate_docs.validate_architecture_decisions,
        )

        self.assertTrue(
            any("ADR H2 headings must be exactly" in error for error in errors)
        )

    def test_current_adr_table_matches_accepted_files(self) -> None:
        errors = self.validation_errors_after_removing(
            validate_docs.ADR_POLICY,
            (
                "| [ADR-005](ADR-005-analytics-privacy-strategy.md) "
                "| 生产环境无后端行为遥测，使用本地 MetricKit 诊断 | accepted |",
            ),
            validate_docs.validate_architecture_decisions,
        )

        self.assertTrue(
            any(
                "current ADR table must match accepted ADR files" in error
                for error in errors
            )
        )

    def test_retired_decision_table_matches_declared_ids(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == validate_docs.RETIRED_DECISIONS:
                return text.replace("| ADR-003 |", "| ADR-099 |")
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_architecture_decisions(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any("table ADR IDs must match retired_ids" in error for error in errors)
        )

    def test_retired_decision_index_requires_history_only_marker(self) -> None:
        errors = self.validation_errors_after_removing(
            validate_docs.RETIRED_DECISIONS,
            ("定义当前需求、范围、架构或执行顺序",),
            validate_docs.validate_architecture_decisions,
        )

        self.assertTrue(any("retired decision index" in error for error in errors))

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

    def test_feature_intent_rejects_proposed_adr(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        adr = validate_docs.ADR_ROOT / "ADR-002-remove-att-authorization.md"

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == adr:
                return text.replace("status: accepted", "status: proposed")
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_feature_intent(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                "intent_refs ADR must be accepted: ADR-002" in error
                for error in errors
            )
        )

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

    def test_frontmatter_document_references_resolve(self) -> None:
        errors: list[str] = []

        validate_docs.validate_frontmatter_document_references(errors)

        self.assertEqual(errors, [])

    def test_stale_frontmatter_document_path_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        assumptions = (
            validate_docs.DOCS_ROOT / "explanations" / "assumptions.md"
        )

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == assumptions:
                return text.replace(
                    "  - ../product/vision.md",
                    "  - vision.md",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_frontmatter_document_references(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/explanations/assumptions.md: "
            "derived_from target does not exist: vision.md",
            errors,
        )

    def test_stale_upstream_document_path_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == validate_docs.RELEASE_ONE_PRD:
                return text.replace(
                    "  - vision.md",
                    "  - missing-vision.md",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_frontmatter_document_references(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/product/release-1-prd.md: "
            "upstream target does not exist: missing-vision.md",
            errors,
        )

    def test_active_feature_specs_use_one_why_what_how_verify_structure(self) -> None:
        errors: list[str] = []

        validate_docs.validate_active_feature_structure(errors)

        self.assertEqual(errors, [])

    def test_parallel_contract_heading_in_active_feature_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        feature = (
            validate_docs.DOCS_ROOT / "features" / "active" / "feat-library.md"
        )

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == feature:
                return text.replace(
                    "## 意图追溯（永久保留）",
                    "## 5. Parallel Contracts\n\n"
                    "Duplicate requirements.\n\n"
                    "## 意图追溯（永久保留）",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_active_feature_structure(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                "unexpected H2 '5. Parallel Contracts'" in error
                for error in errors
            )
        )

    def test_renamed_feature_what_heading_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        feature = (
            validate_docs.DOCS_ROOT / "features" / "active" / "feat-dashboard.md"
        )

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == feature:
                return text.replace(
                    "## 2. 需求规则 (What)",
                    "## 2. Release 1 PRD",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_active_feature_structure(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                "numbered H2 sections must be exactly" in error
                for error in errors
            )
        )
        self.assertTrue(
            any("unexpected H2 '2. Release 1 PRD'" in error for error in errors)
        )

    def test_candidate_roadmap_does_not_repeat_product_authority(self) -> None:
        errors: list[str] = []

        validate_docs.validate_roadmap_boundaries(errors)

        self.assertEqual(errors, [])

    def test_root_readme_is_the_only_cold_start_entrypoint(self) -> None:
        errors: list[str] = []

        validate_docs.validate_cold_start_entrypoint(errors)

        self.assertEqual(errors, [])

    def test_missing_root_readme_cold_start_marker_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        root_readme = validate_docs.REPO_ROOT / "README.md"

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == root_readme:
                return text.replace(
                    "根 README 是人和 Agent 的唯一冷启动入口",
                    "根 README 是一个入口",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_cold_start_entrypoint(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                "cold-start entrypoint missing requirement" in error
                for error in errors
            )
        )

    def test_competing_cold_start_declaration_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        feature = (
            validate_docs.DOCS_ROOT / "features" / "active" / "feat-library.md"
        )

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == feature:
                return f"{text}\n本文件是唯一冷启动入口。\n"
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_cold_start_entrypoint(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/features/active/feat-library.md: competing cold-start "
            "declaration; root README is the only cold-start owner and "
            "docs/README.md is its router",
            errors,
        )

    def test_roadmap_product_authority_heading_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == validate_docs.SCOPE_AND_ROADMAP:
                return f"{text}\n## 耐久非目标\n\nDuplicated from Vision.\n"
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_roadmap_boundaries(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any("parallel product authority heading" in error for error in errors)
        )

    def test_release_one_prd_is_the_only_declared_prd(self) -> None:
        errors: list[str] = []

        validate_docs.validate_product_document_authority(errors)

        self.assertEqual(errors, [])

    def test_release_prd_summary_declares_index_only_role(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == validate_docs.RELEASE_ONE_PRD:
                return text.replace(
                    "下表只是稳定决策 ID 的审阅索引，不独立定义完整约束。",
                    "",
                )
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_product_document_authority(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/product/release-1-prd.md: decision summary must state that it "
            "is an index and does not independently define complete constraints",
            errors,
        )

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

    def test_line_wrapped_legacy_authority_term_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        ready_doc = validate_docs.DOCS_ROOT / "how-to" / "definition-of-ready.md"

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == ready_doc:
                return f"{text}\nRelease\nProduct Contract\n"
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_current_product_authority_terms(errors)
        finally:
            validate_docs.read = original_read

        self.assertTrue(
            any(
                error.startswith("docs/how-to/definition-of-ready.md:")
                and "obsolete product authority term 'Release Product Contract'"
                in error
                for error in errors
            )
        )

    def test_repository_fact_ownership_policy_is_complete(self) -> None:
        errors: list[str] = []

        validate_docs.validate_repository_fact_ownership(errors)

        self.assertEqual(errors, [])

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

    def test_current_documents_do_not_reintroduce_stale_lifecycle_sections(
        self,
    ) -> None:
        errors: list[str] = []

        validate_docs.validate_current_document_lifecycle(errors)

        self.assertEqual(errors, [])

    def test_stale_release_snapshot_fails_closed(self) -> None:
        errors: list[str] = []
        original_read = validate_docs.read
        release_ops = (
            validate_docs.DOCS_ROOT / "how-to" / "release-and-ci.md"
        )

        def fake_read(path: Path) -> str:
            text = original_read(path)
            if path == release_ops:
                return f"{text}\n### 当前发布实证快照（旧）\n"
            return text

        validate_docs.read = fake_read
        try:
            validate_docs.validate_current_document_lifecycle(errors)
        finally:
            validate_docs.read = original_read

        self.assertIn(
            "docs/how-to/release-and-ci.md: stale lifecycle marker in current "
            "document: ### 当前发布实证快照",
            errors,
        )

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

    def test_frozen_decision_receipts_and_ui_redesign_are_excluded_from_term_scan(self) -> None:
        decision_receipts = (
            validate_docs.DOCS_ROOT
            / "reference"
            / "audits"
            / "2026-07-po-decision-receipts.md"
        )
        redesign_path = (
            validate_docs.DOCS_ROOT / "ui-redesign" / "library-flagship-polish-plan.md"
        )
        generated_path = validate_docs.DOCS_ROOT / "reference" / "feature-status.md"

        self.assertTrue(validate_docs.should_skip_positioning_term_scan(decision_receipts))
        self.assertTrue(validate_docs.should_skip_positioning_term_scan(redesign_path))
        self.assertTrue(validate_docs.should_skip_positioning_term_scan(generated_path))
        self.assertTrue(validate_docs.should_skip_taxonomy_canonical_scan(decision_receipts))
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
