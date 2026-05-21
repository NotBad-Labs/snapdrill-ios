"""Tests for pr_review_trace.py (S-D7-002)."""
from __future__ import annotations

import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

import yaml

# Make sibling module importable
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pr_review_trace  # noqa: E402


POLICY = {
    "version": 1,
    "required_section": "## F-005 Review Trace",
    "required_fields": ["Review Required", "Review Scope", "Human Merge Approval"],
    "normal_review": {
        "review_required": "yes",
        "required_fields": ["Codex Review", "Codex Evidence", "Findings Resolved"],
        "accepted_verdicts": ["PASS", "PASS_WITH_FINDINGS"],
        "optional_review_fields": ["Gemini Review", "Xcode Review"],
    },
    "placeholder_patterns": [
        r"^\[填[写入]",
        r"^TBD$",
        r"^placeholder$",
        r"^\.\.\.+$",
        r"^N/A$",
    ],
    "ui_review": {
        "path_globs": [
            "Packages/SnapDrillFeatures/Sources/**/*.swift",
            "Packages/SnapDrillUI/Sources/**/*.swift",
        ],
        "required_fields": ["Xcode Review", "Xcode Evidence"],
        "ui_accepted_verdicts": ["PASS", "PASS_WITH_FINDINGS"],
    },
    "exemptions": {
        "docs-only": {
            "allowed_globs": ["docs/**/*.md", "*.md"],
            "denied_globs": ["docs/workflow.md", "docs/standards/**"],
            "required_fields": ["Exemption Rationale", "Disallowed Paths Present"],
        },
        "trivial": {
            "max_files": 1,
            "allowed_globs": ["docs/**/*.md"],
            "denied_globs": ["Packages/**"],
            "required_fields": ["Exemption Rationale"],
        },
    },
    "direct_push": {
        "commit_msg_trailer": "F-005-Review-Trace:",
    },
}


class ReviewTraceParseTests(unittest.TestCase):
    def test_missing_section_raises(self):
        with self.assertRaises(ValueError):
            pr_review_trace.parse_trace("## Summary\nNo trace\n")

    def test_parse_fields(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: yes
            Review Scope: full-pr
            Codex Review: PASS
            Codex Evidence: https://example.com/pr/1#issue-1
            Findings Resolved: yes
            Human Merge Approval: yes

            ## Next section
        """)
        fields = pr_review_trace.parse_trace(body)
        self.assertEqual(fields["Review Required"], "yes")
        self.assertEqual(fields["Codex Review"], "PASS")
        self.assertEqual(fields["Codex Evidence"], "https://example.com/pr/1#issue-1")
        self.assertEqual(fields["Human Merge Approval"], "yes")


class ReviewTraceValidateTests(unittest.TestCase):
    def test_normal_review_pass(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: yes
            Review Scope: full-pr
            Codex Review: PASS
            Codex Evidence: https://github.com/example/repo/pull/1#issuecomment-1
            Findings Resolved: yes
            Human Merge Approval: yes
        """)
        errors = pr_review_trace.validate(body, ["Packages/SnapDrillData/Foo.swift"], POLICY)
        self.assertEqual(errors, [])

    def test_pr_without_section_rejected(self):
        errors = pr_review_trace.validate("## Summary\n", ["Packages/Foo.swift"], POLICY)
        self.assertTrue(any("missing required section" in e for e in errors))

    def test_codex_evidence_placeholder_rejected(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: yes
            Review Scope: full-pr
            Codex Review: PASS
            Codex Evidence: [填写审查证据]
            Findings Resolved: yes
            Human Merge Approval: yes
        """)
        errors = pr_review_trace.validate(body, ["Packages/Foo.swift"], POLICY)
        self.assertTrue(any("placeholder or empty" in e for e in errors))

    def test_codex_review_invalid_verdict_rejected(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: yes
            Review Scope: full-pr
            Codex Review: LGTM
            Codex Evidence: https://example.com/pr/1
            Findings Resolved: yes
            Human Merge Approval: yes
        """)
        errors = pr_review_trace.validate(body, ["Packages/Foo.swift"], POLICY)
        self.assertTrue(any("Codex Review must be" in e for e in errors))

    def test_ui_pr_requires_xcode_review(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: yes
            Review Scope: full-pr
            Codex Review: PASS
            Codex Evidence: https://example.com/pr/1
            Xcode Review: N/A
            Xcode Evidence: N/A
            Findings Resolved: yes
            Human Merge Approval: yes
        """)
        errors = pr_review_trace.validate(
            body,
            ["Packages/SnapDrillFeatures/Sources/Foo.swift"],
            POLICY,
        )
        self.assertTrue(any("UI-impacting PR requires Xcode Review" in e for e in errors))

    def test_docs_only_exemption_pass(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: exempt
            Review Exemption: docs-only
            Review Scope: docs-only
            Exemption Rationale: typo fix in product docs
            Disallowed Paths Present: no
            Human Merge Approval: yes
        """)
        errors = pr_review_trace.validate(
            body,
            ["docs/product/product-vision.md"],
            POLICY,
        )
        self.assertEqual(errors, [])

    def test_docs_only_exemption_denied_path(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: exempt
            Review Exemption: docs-only
            Review Scope: docs-only
            Exemption Rationale: workflow.md update
            Disallowed Paths Present: no
            Human Merge Approval: yes
        """)
        errors = pr_review_trace.validate(
            body,
            ["docs/workflow.md"],
            POLICY,
        )
        self.assertTrue(any("denied for paths" in e for e in errors))

    def test_findings_resolved_must_be_yes(self):
        body = textwrap.dedent("""\
            ## F-005 Review Trace

            Review Required: yes
            Review Scope: full-pr
            Codex Review: PASS
            Codex Evidence: https://example.com/pr/1
            Findings Resolved: no
            Human Merge Approval: yes
        """)
        errors = pr_review_trace.validate(body, ["Packages/Foo.swift"], POLICY)
        self.assertTrue(any("Findings Resolved must be 'yes'" in e for e in errors))


class DirectPushTests(unittest.TestCase):
    def test_docs_only_direct_push_exempt(self):
        # patch commit_range_msgs since we don't have a real git repo here
        errors = pr_review_trace.validate_direct_push(
            "FAKE..HEAD",
            ["docs/product/foo.md"],
            POLICY,
        )
        self.assertEqual(errors, [])

    def test_code_direct_push_without_trailer_rejected(self):
        original = pr_review_trace.commit_range_msgs
        pr_review_trace.commit_range_msgs = lambda r: "fix: emergency hotfix"
        try:
            errors = pr_review_trace.validate_direct_push(
                "FAKE..HEAD",
                ["Packages/Foo.swift"],
                POLICY,
            )
            self.assertTrue(any("F-005-Review-Trace:" in e for e in errors))
        finally:
            pr_review_trace.commit_range_msgs = original

    def test_code_direct_push_with_trailer_pass(self):
        original = pr_review_trace.commit_range_msgs
        pr_review_trace.commit_range_msgs = lambda r: (
            "fix: thing\n\nF-005-Review-Trace: codex local review SHA abc"
        )
        try:
            errors = pr_review_trace.validate_direct_push(
                "FAKE..HEAD",
                ["Packages/Foo.swift"],
                POLICY,
            )
            self.assertEqual(errors, [])
        finally:
            pr_review_trace.commit_range_msgs = original


class PolicyYAMLLoadTests(unittest.TestCase):
    """Smoke test：实际 policy YAML 文件可加载且 schema 完整。"""

    def test_real_policy_loads(self):
        repo_root = Path(__file__).resolve().parents[3]
        policy_path = repo_root / ".github" / "review-trace-policy.yml"
        if not policy_path.exists():
            self.skipTest(f"policy file not present at {policy_path}")
        policy = yaml.safe_load(policy_path.read_text(encoding="utf-8"))
        self.assertIn("required_fields", policy)
        self.assertIn("normal_review", policy)
        self.assertIn("ui_review", policy)
        self.assertIn("exemptions", policy)
        self.assertIn("docs-only", policy["exemptions"])
        self.assertIn("trivial", policy["exemptions"])
        self.assertIn("direct_push", policy)


if __name__ == "__main__":
    unittest.main()
