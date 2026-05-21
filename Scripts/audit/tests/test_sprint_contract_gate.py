"""Tests for sprint_contract_gate.py (S-D7-003)."""
from __future__ import annotations

import sys
import textwrap
import unittest
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import sprint_contract_gate  # noqa: E402


POLICY = {
    "version": 1,
    "required_section": "## Sprint Contract",
    "required_fields": ["Contract Required", "Issue", "Contract Author"],
    "normal_contract": {
        "contract_required": "yes",
        "required_fields": [
            "Issue Type", "Appetite", "Status",
            "Touches", "No-Touch", "DoD Minimum",
        ],
        "full_required_fields": ["Interface Delta", "Test Additions", "Uncertainties"],
        "accepted_issue_types": ["enhancement", "chore"],
        "accepted_status_values": ["Building", "status:building", "building"],
        "accepted_appetites": ["Small", "Medium", "Large"],
    },
    "small_chore": {
        "issue_type": "chore",
        "appetite": "Small",
        "required_fields": ["Touches", "No-Touch", "DoD Minimum"],
    },
    "closeout": {
        "required_section": "## Sprint Contract Closeout",
        "required_fields": ["Touches", "DoD"],
    },
    "issue_detection": {
        "explicit_env": "SPRINT_CONTRACT_ISSUE",
        "branch_patterns": [r"(?:fix|feat|chore)/(?P<number>[0-9]+)"],
        "building_labels": ["status:building", "building"],
        "eligible_issue_types": ["enhancement", "chore"],
        "exempt_labels": ["bug", "trivial", "no-contract", "epic"],
    },
    "protected_edit_globs": [
        "Packages/**/*.swift",
        "SnapDrill/**/*.swift",
        ".github/**",
        "Scripts/**",
    ],
    "ignore_path_globs": ["docs/**", "*.md", "STATUS.md"],
    "exemptions": {
        "trivial": {
            "max_files": 1,
            "allowed_globs": ["docs/**/*.md"],
            "denied_globs": ["docs/workflow.md", "Packages/**"],
            "required_fields": [
                "Changed Paths Checked", "Disallowed Paths Present", "Exemption Rationale",
            ],
        },
    },
    "placeholder_patterns": [r"^\[填[写入]", r"^TBD$", r"^placeholder$"],
}


FULL_CONTRACT = textwrap.dedent("""\
    ## Sprint Contract

    Contract Required: yes
    Issue: #123
    Issue Type: enhancement
    Appetite: Medium
    Status: Building
    Touches:
    - Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift
    - Packages/SnapDrillCore/Tests/SnapDrillCoreTests/FooTests.swift
    No-Touch:
    - Packages/SnapDrillData/**
    - SnapDrillShare/**
    Interface Delta:
    - public func buildFoo(input: FooInput) async throws -> FooResult
    Test Additions:
    - FooTests.testBuildFooRejectsInvalidInput
    DoD Minimum:
    - swiftlint --strict
    - xcodebuild build-for-testing
    Uncertainties:
    - Existing API may cover query path
    Contract Author: claude
""")


SMALL_CHORE_CONTRACT = textwrap.dedent("""\
    ## Sprint Contract

    Contract Required: yes
    Issue: #735
    Issue Type: chore
    Appetite: Small
    Status: Building
    Touches:
    - docs/product/product-vision.md
    No-Touch:
    - Packages/**
    DoD Minimum:
    - docaudit all --strict --baseline
    Contract Author: claude
""")


class ContractParseTests(unittest.TestCase):

    def test_parse_full_contract(self):
        fields = sprint_contract_gate.parse_contract(FULL_CONTRACT)
        self.assertEqual(fields["Contract Required"], "yes")
        self.assertEqual(fields["Issue"], "#123")
        self.assertEqual(fields["Issue Type"], "enhancement")
        self.assertIsInstance(fields["Touches"], list)
        self.assertIn("Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift", fields["Touches"])
        self.assertIsInstance(fields["No-Touch"], list)

    def test_parse_missing_section(self):
        fields = sprint_contract_gate.parse_contract("## Summary\nNothing here")
        self.assertEqual(fields, {})


class FieldValidationTests(unittest.TestCase):

    def test_full_contract_pass(self):
        fields = sprint_contract_gate.parse_contract(FULL_CONTRACT)
        errors = sprint_contract_gate.validate_contract_fields(
            fields, "medium", POLICY, ["Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift"]
        )
        self.assertEqual(errors, [])

    def test_small_chore_minimal_pass(self):
        fields = sprint_contract_gate.parse_contract(SMALL_CHORE_CONTRACT)
        errors = sprint_contract_gate.validate_contract_fields(
            fields, "small", POLICY, ["docs/product/product-vision.md"]
        )
        self.assertEqual(errors, [])

    def test_missing_interface_delta_for_medium(self):
        body = SMALL_CHORE_CONTRACT.replace("Appetite: Small", "Appetite: Medium").replace("chore", "enhancement")
        fields = sprint_contract_gate.parse_contract(body)
        errors = sprint_contract_gate.validate_contract_fields(
            fields, "medium", POLICY, ["Packages/Foo.swift"]
        )
        self.assertTrue(any("Interface Delta" in e for e in errors))

    def test_placeholder_in_touches_rejected(self):
        body = FULL_CONTRACT.replace(
            "- Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift",
            "- TBD",
        )
        fields = sprint_contract_gate.parse_contract(body)
        errors = sprint_contract_gate.validate_contract_fields(
            fields, "medium", POLICY, ["Packages/Foo.swift"]
        )
        self.assertTrue(any("占位符" in e for e in errors))

    def test_invalid_status_rejected(self):
        body = FULL_CONTRACT.replace("Status: Building", "Status: Draft")
        fields = sprint_contract_gate.parse_contract(body)
        errors = sprint_contract_gate.validate_contract_fields(
            fields, "medium", POLICY, ["Packages/Foo.swift"]
        )
        self.assertTrue(any("Status must be" in e for e in errors))


class ScopeCreepTests(unittest.TestCase):

    def test_file_in_touches_pass(self):
        fields = sprint_contract_gate.parse_contract(FULL_CONTRACT)
        errors = sprint_contract_gate.check_file_scope(
            "Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift",
            fields, POLICY,
        )
        self.assertEqual(errors, [])

    def test_file_in_no_touch_rejected(self):
        fields = sprint_contract_gate.parse_contract(FULL_CONTRACT)
        errors = sprint_contract_gate.check_file_scope(
            "Packages/SnapDrillData/Sources/Foo.swift",
            fields, POLICY,
        )
        self.assertTrue(any("No-Touch" in e for e in errors))

    def test_file_outside_touches_rejected(self):
        fields = sprint_contract_gate.parse_contract(FULL_CONTRACT)
        errors = sprint_contract_gate.check_file_scope(
            "Packages/SnapDrillFeatures/Sources/Bar.swift",
            fields, POLICY,
        )
        self.assertTrue(any("Touches" in e for e in errors))

    def test_status_md_always_allowed(self):
        fields = sprint_contract_gate.parse_contract(FULL_CONTRACT)
        errors = sprint_contract_gate.check_file_scope(
            "STATUS.md", fields, POLICY,
        )
        self.assertEqual(errors, [])

    def test_docs_path_ignored(self):
        fields = sprint_contract_gate.parse_contract(FULL_CONTRACT)
        errors = sprint_contract_gate.check_file_scope(
            "docs/product/foo.md", fields, POLICY,
        )
        self.assertEqual(errors, [])


class PathProtectionTests(unittest.TestCase):

    def test_swift_path_protected(self):
        self.assertTrue(
            sprint_contract_gate.is_path_protected("Packages/SnapDrillCore/Sources/Foo.swift", POLICY)
        )

    def test_docs_md_not_protected(self):
        self.assertFalse(
            sprint_contract_gate.is_path_protected("docs/product/foo.md", POLICY)
        )

    def test_status_md_not_protected(self):
        self.assertFalse(
            sprint_contract_gate.is_path_protected("STATUS.md", POLICY)
        )


class EndToEndValidateEditTests(unittest.TestCase):

    def test_no_issue_with_protected_path_rejected(self):
        # 用环境隔离避免推导出真实 Issue
        import os
        original = os.environ.get("SPRINT_CONTRACT_ISSUE")
        if "SPRINT_CONTRACT_ISSUE" in os.environ:
            del os.environ["SPRINT_CONTRACT_ISSUE"]
        try:
            # 通过 monkey-patch 强制 derive_issue 返回 None
            orig_derive = sprint_contract_gate.derive_issue
            sprint_contract_gate.derive_issue = lambda policy: None
            try:
                exit_code, errors = sprint_contract_gate.validate_edit(
                    "Packages/SnapDrillCore/Foo.swift", [], POLICY,
                )
                self.assertEqual(exit_code, 2)
                self.assertTrue(any("No associated Issue" in e for e in errors))
            finally:
                sprint_contract_gate.derive_issue = orig_derive
        finally:
            if original is not None:
                os.environ["SPRINT_CONTRACT_ISSUE"] = original

    def test_unprotected_path_pass(self):
        exit_code, errors = sprint_contract_gate.validate_edit(
            "docs/product/foo.md", ["docs/product/foo.md"], POLICY,
        )
        self.assertEqual(exit_code, 0)
        self.assertEqual(errors, [])

    def test_exempt_label_pass(self):
        orig_derive = sprint_contract_gate.derive_issue
        orig_fetch = sprint_contract_gate.fetch_issue
        sprint_contract_gate.derive_issue = lambda policy: "999"
        sprint_contract_gate.fetch_issue = lambda n: {
            "labels": [{"name": "bug"}], "state": "OPEN", "body": "", "comments": [],
        }
        try:
            exit_code, errors = sprint_contract_gate.validate_edit(
                "Packages/Foo.swift", [], POLICY,
            )
            self.assertEqual(exit_code, 0)
            self.assertEqual(errors, [])
        finally:
            sprint_contract_gate.derive_issue = orig_derive
            sprint_contract_gate.fetch_issue = orig_fetch

    def test_full_contract_pass_with_in_scope_file(self):
        orig_derive = sprint_contract_gate.derive_issue
        orig_fetch = sprint_contract_gate.fetch_issue
        sprint_contract_gate.derive_issue = lambda policy: "123"
        sprint_contract_gate.fetch_issue = lambda n: {
            "labels": [{"name": "enhancement"}, {"name": "status:building"}],
            "state": "OPEN",
            "body": "",
            "comments": [{"body": FULL_CONTRACT}],
        }
        try:
            exit_code, errors = sprint_contract_gate.validate_edit(
                "Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift", [], POLICY,
            )
            self.assertEqual(exit_code, 0)
            self.assertEqual(errors, [])
        finally:
            sprint_contract_gate.derive_issue = orig_derive
            sprint_contract_gate.fetch_issue = orig_fetch

    def test_missing_contract_rejected(self):
        orig_derive = sprint_contract_gate.derive_issue
        orig_fetch = sprint_contract_gate.fetch_issue
        sprint_contract_gate.derive_issue = lambda policy: "123"
        sprint_contract_gate.fetch_issue = lambda n: {
            "labels": [{"name": "enhancement"}, {"name": "status:building"}],
            "state": "OPEN", "body": "", "comments": [],
        }
        try:
            exit_code, errors = sprint_contract_gate.validate_edit(
                "Packages/SnapDrillCore/Sources/SnapDrillCore/Foo.swift", [], POLICY,
            )
            self.assertEqual(exit_code, 1)
            self.assertTrue(any("`## Sprint Contract`" in e for e in errors))
        finally:
            sprint_contract_gate.derive_issue = orig_derive
            sprint_contract_gate.fetch_issue = orig_fetch

    def test_scope_creep_rejected(self):
        orig_derive = sprint_contract_gate.derive_issue
        orig_fetch = sprint_contract_gate.fetch_issue
        sprint_contract_gate.derive_issue = lambda policy: "123"
        sprint_contract_gate.fetch_issue = lambda n: {
            "labels": [{"name": "enhancement"}, {"name": "status:building"}],
            "state": "OPEN",
            "body": "",
            "comments": [{"body": FULL_CONTRACT}],
        }
        try:
            # Edit 文件不在 Touches 内
            exit_code, errors = sprint_contract_gate.validate_edit(
                "Packages/SnapDrillData/Sources/Bar.swift", [], POLICY,
            )
            self.assertEqual(exit_code, 1)
            self.assertTrue(any("No-Touch" in e or "Touches" in e for e in errors))
        finally:
            sprint_contract_gate.derive_issue = orig_derive
            sprint_contract_gate.fetch_issue = orig_fetch


class CloseoutTests(unittest.TestCase):

    def test_closeout_missing_rejected(self):
        orig_fetch = sprint_contract_gate.fetch_issue
        sprint_contract_gate.fetch_issue = lambda n: {
            "labels": [], "state": "OPEN", "body": "", "comments": [],
        }
        try:
            errors = sprint_contract_gate.validate_closeout("123", POLICY)
            self.assertTrue(any("缺 closeout 段" in e for e in errors))
        finally:
            sprint_contract_gate.fetch_issue = orig_fetch

    def test_closeout_pass(self):
        orig_fetch = sprint_contract_gate.fetch_issue
        body = textwrap.dedent("""\
            ## Sprint Contract Closeout

            Touches: Packages/Foo.swift
            DoD: swiftlint clean
        """)
        sprint_contract_gate.fetch_issue = lambda n: {
            "labels": [], "state": "OPEN", "body": body, "comments": [],
        }
        try:
            errors = sprint_contract_gate.validate_closeout("123", POLICY)
            self.assertEqual(errors, [])
        finally:
            sprint_contract_gate.fetch_issue = orig_fetch


class PolicyYAMLLoadTests(unittest.TestCase):

    def test_real_policy_loads(self):
        repo_root = Path(__file__).resolve().parents[3]
        policy_path = repo_root / ".github" / "sprint-contract-policy.yml"
        if not policy_path.exists():
            self.skipTest(f"policy file not present at {policy_path}")
        policy = yaml.safe_load(policy_path.read_text(encoding="utf-8"))
        self.assertIn("required_section", policy)
        self.assertIn("normal_contract", policy)
        self.assertIn("small_chore", policy)
        self.assertIn("closeout", policy)
        self.assertIn("protected_edit_globs", policy)
        self.assertIn("placeholder_patterns", policy)


if __name__ == "__main__":
    unittest.main()
