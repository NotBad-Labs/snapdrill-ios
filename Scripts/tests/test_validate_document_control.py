#!/usr/bin/env python3
"""Regression tests for Markdown document control checks."""
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "Scripts" / "validate_document_control.py"


def load_module():
    spec = importlib.util.spec_from_file_location("validate_document_control", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load Scripts/validate_document_control.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


document_control = load_module()


class DocumentControlTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "docs").mkdir()
        (self.root / "docs" / "authority.md").write_text(
            "# Authority\n\n## Scope\n",
            encoding="utf-8",
        )
        (self.root / "docs" / "history.md").write_text(
            "# History\n\n> 文档状态：固定基线历史证据。\n",
            encoding="utf-8",
        )
        self.paths = {"docs/authority.md", "docs/history.md"}

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def registry(self) -> dict[str, object]:
        return {
            "schema_version": 1,
            "rules": [
                {
                    "id": "authority",
                    "role": "authority",
                    "lifecycle": "effective",
                    "paths": ["docs/authority.md"],
                },
                {
                    "id": "history",
                    "role": "evidence",
                    "lifecycle": "frozen",
                    "paths": ["docs/history.md"],
                    "status_marker": "文档状态：固定基线历史证据",
                },
            ],
        }

    def test_complete_registry_passes(self) -> None:
        errors, assignments = document_control.validate_registry(
            self.root,
            self.registry(),
            self.paths,
        )

        self.assertEqual(errors, [])
        self.assertEqual(set(assignments), self.paths)

    def test_unclassified_markdown_fails(self) -> None:
        paths = self.paths | {"docs/unclassified.md"}
        (self.root / "docs" / "unclassified.md").write_text("# New\n", encoding="utf-8")

        errors, _ = document_control.validate_registry(
            self.root,
            self.registry(),
            paths,
        )

        self.assertIn(
            "document-control.json: unclassified repository Markdown: docs/unclassified.md",
            errors,
        )

    def test_ambiguous_rules_fail(self) -> None:
        registry = self.registry()
        registry["rules"].append(
            {
                "id": "overlap",
                "role": "evidence",
                "lifecycle": "current",
                "patterns": ["docs/*.md"],
            }
        )

        errors, _ = document_control.validate_registry(self.root, registry, self.paths)

        self.assertTrue(any("matches both" in error for error in errors))

    def test_invalid_role_lifecycle_fails(self) -> None:
        registry = self.registry()
        registry["rules"][0]["lifecycle"] = "current"

        errors, _ = document_control.validate_registry(self.root, registry, self.paths)

        self.assertIn(
            "document-control.json: authority has invalid role/lifecycle: authority/current",
            errors,
        )

    def test_malformed_matcher_schema_fails_closed(self) -> None:
        registry = self.registry()
        registry["rules"][0]["paths"] = "docs/authority.md"
        registry["rules"][1]["status_marker"] = ["not", "a", "string"]

        errors, _ = document_control.validate_registry(
            self.root,
            registry,
            self.paths,
        )

        self.assertIn(
            "document-control.json: authority paths must be a list",
            errors,
        )
        self.assertIn(
            "document-control.json: history status_marker must be a string",
            errors,
        )

    def test_missing_visible_status_marker_fails(self) -> None:
        (self.root / "docs" / "history.md").write_text("# History\n", encoding="utf-8")

        errors, _ = document_control.validate_registry(
            self.root,
            self.registry(),
            self.paths,
        )

        self.assertIn(
            "docs/history.md: opening must contain visible status marker: "
            "文档状态：固定基线历史证据",
            errors,
        )

    def test_local_links_and_heading_anchors_pass(self) -> None:
        (self.root / "docs" / "authority.md").write_text(
            "# Authority\n\n[History](history.md)\n[Scope](#scope)\n\n## Scope\n",
            encoding="utf-8",
        )

        errors = document_control.validate_local_links(
            self.root,
            self.paths,
            alias_paths=set(),
        )

        self.assertEqual(errors, [])

    def test_missing_local_link_fails_but_external_and_fenced_links_do_not(self) -> None:
        (self.root / "docs" / "authority.md").write_text(
            "# Authority\n\n"
            "[Missing](missing.md)\n"
            "[External](https://example.com/not-local.md)\n"
            "```markdown\n[Example](also-missing.md)\n```\n",
            encoding="utf-8",
        )

        errors = document_control.validate_local_links(
            self.root,
            self.paths,
            alias_paths=set(),
        )

        self.assertEqual(
            errors,
            ["docs/authority.md: missing local link target: missing.md"],
        )

    def test_wiki_links_fail_closed(self) -> None:
        (self.root / "docs" / "authority.md").write_text(
            "# Authority\n\nSee [[ADR-001]].\n",
            encoding="utf-8",
        )

        errors = document_control.validate_local_links(
            self.root,
            self.paths,
            alias_paths=set(),
        )

        self.assertEqual(
            errors,
            [
                "docs/authority.md: unsupported wiki link; use Markdown: "
                "[[ADR-001]]"
            ],
        )


if __name__ == "__main__":
    unittest.main()
