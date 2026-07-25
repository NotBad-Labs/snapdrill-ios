from __future__ import annotations

import importlib.util
import os
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "Scripts" / "validate_docs.py"


def load_module():
    spec = importlib.util.spec_from_file_location("validate_docs", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load validate_docs.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validate_docs = load_module()


class DocumentationValidatorTests(unittest.TestCase):
    def test_live_repository_passes(self):
        self.assertEqual(validate_docs.run_checks(), [])

    def test_extra_markdown_is_rejected(self):
        tracked = set(validate_docs.ALLOWED_MARKDOWN)
        tracked.add("docs/NOTES.md")
        with tempfile.TemporaryDirectory() as directory:
            errors = validate_docs.validate(Path(directory), tracked)
        self.assertIn(
            "unapproved Markdown outside the minimal set: docs/NOTES.md",
            errors,
        )

    def test_link_target_resolves_relative_paths(self):
        self.assertEqual(
            validate_docs.link_target(
                "docs/DEVELOPMENT.md",
                "ARCHITECTURE.md#modules",
            ),
            "docs/ARCHITECTURE.md",
        )
        self.assertEqual(
            validate_docs.link_target(
                "docs/DEVELOPMENT.md",
                "<supporting material/ARCHITECTURE.md#modules>",
            ),
            "docs/supporting material/ARCHITECTURE.md",
        )
        self.assertIsNone(
            validate_docs.link_target(
                "docs/PRD.md",
                "https://example.com/reference",
            )
        )

    def test_markdown_link_targets_support_reference_links(self):
        targets, errors = validate_docs.markdown_link_targets(
            "[Architecture][arch]\n"
            "[Data][]\n"
            "[PRD]\n"
            "[Named](<supporting material/notes.md>)\n"
            "\n"
            "[arch]: ARCHITECTURE.md#modules\n"
            "[Data]: DATA.md\n"
            "[PRD]: PRD.md\n"
        )

        self.assertEqual(errors, [])
        self.assertCountEqual(
            targets,
            [
                "<supporting material/notes.md>",
                "ARCHITECTURE.md#modules",
                "DATA.md",
                "PRD.md",
            ],
        )

    def test_markdown_link_targets_reject_undefined_reference(self):
        _, errors = validate_docs.markdown_link_targets("[Missing][unknown]")
        self.assertEqual(errors, ["undefined reference link: unknown"])

    def test_cycle_detection(self):
        graph = {
            "docs/PRD.md": {"docs/DATA.md"},
            "docs/DATA.md": {"docs/PRD.md"},
        }
        self.assertEqual(
            validate_docs.graph_cycles(graph),
            [["docs/DATA.md", "docs/PRD.md", "docs/DATA.md"]],
        )

    def test_alias_targets_are_stable(self):
        self.assertTrue((REPO_ROOT / "CLAUDE.md").is_symlink())
        self.assertEqual(os.readlink(REPO_ROOT / "CLAUDE.md"), "AGENTS.md")
        copilot = REPO_ROOT / ".github/copilot-instructions.md"
        self.assertTrue(copilot.is_symlink())
        self.assertEqual(os.readlink(copilot), "../AGENTS.md")


if __name__ == "__main__":
    unittest.main()
