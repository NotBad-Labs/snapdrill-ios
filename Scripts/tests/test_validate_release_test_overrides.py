#!/usr/bin/env python3
"""Regression tests for Release test-override source policy."""
from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "Scripts" / "validate_release_test_overrides.py"


def load_validator():
    module_name = "test_subject_validate_release_test_overrides"
    spec = importlib.util.spec_from_file_location(module_name, MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load Scripts/validate_release_test_overrides.py")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    return module


validator = load_validator()


def base_sources(app_source: str = "let production = true\n") -> dict[str, str]:
    return {
        "SnapDrill/App/App.swift": app_source,
        "SnapDrillShare/ShareViewController.swift": "let share = true\n",
        "Packages/Core/Sources/Core/Mocks.swift": """
public final class MockServiceContainer {
    let analytics = AnalyticsServiceMock()
}
public final class AnalyticsServiceMock {}
""",
    }


class ValidateReleaseTestOverridesTests(unittest.TestCase):
    def test_module_is_import_safe_from_unrelated_working_directory(self) -> None:
        program = f"""
import importlib.util, pathlib, sys
path = pathlib.Path({str(MODULE_PATH)!r})
spec = importlib.util.spec_from_file_location('isolated_validator', path)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
assert module.validate_sources
"""
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [sys.executable, "-c", program],
                cwd=directory,
                capture_output=True,
                text=True,
                check=False,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_clean_mapping_passes(self) -> None:
        self.assertEqual(validator.validate_sources(base_sources()), [])

    def test_red_before_fixture_detects_each_live_defect_class(self) -> None:
        sources = base_sources(
            """
let arguments = ProcessInfo.processInfo.arguments
let environment = ProcessInfo.processInfo.environment
let token = "--uitesting"
let featureToken = "--ui-test-durable-capture-draft"
let services = MockServiceContainer()
let analytics = AnalyticsServiceMock()
"""
        )
        errors = validator.validate_sources(sources)

        self.assertTrue(any(".arguments selector" in error for error in errors))
        self.assertTrue(any(".environment selector" in error for error in errors))
        self.assertTrue(any("custom UI-test token '--uitesting'" in error for error in errors))
        self.assertTrue(any("--ui-test-durable-capture-draft" in error for error in errors))
        self.assertTrue(any("mock reference MockServiceContainer" in error for error in errors))
        self.assertTrue(any("mock reference AnalyticsServiceMock" in error for error in errors))

    def test_process_info_sequence_ignores_whitespace_and_comments(self) -> None:
        sources = base_sources(
            "let value = ProcessInfo /* nested /* comment */ end */ . processInfo\n"
            "    . environment\n"
        )
        errors = validator.validate_sources(sources)

        self.assertTrue(any("ProcessInfo.processInfo.environment selector" in error for error in errors))

    def test_only_exact_debug_false_branch_is_exempt(self) -> None:
        cases = {
            "#if DEBUG\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": False,
            "#if DEBUG && canImport(UIKit)\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": False,
            "#if canImport(UIKit) && DEBUG\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": False,
            "#if DEBUG\n#else\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": True,
            "#if feature\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": True,
            "#if feature\n#else\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": True,
            "#if !DEBUG\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": True,
            "#if DEBUG || targetEnvironment(simulator)\nlet x = ProcessInfo.processInfo.arguments\n#endif\n": True,
        }
        for source, should_fail in cases.items():
            with self.subTest(source=source):
                errors = validator.validate_sources(base_sources(source))
                found = any("ProcessInfo.processInfo.arguments selector" in error for error in errors)
                self.assertEqual(found, should_fail, errors)

    def test_comments_do_not_create_custom_tokens(self) -> None:
        sources = base_sources(
            """
// "--uitesting"
/* "--ui-test-comment" */
let safe = "production"
"""
        )
        self.assertEqual(validator.validate_sources(sources), [])

    def test_normal_raw_multiline_and_escaped_custom_tokens_are_rejected(self) -> None:
        sources = base_sources(
            r'''
let normal = "--uitesting"
let raw = ##"--ui-test-raw"##
let multiline = """--ui-test-multiline"""
let escaped = "\u{2d}\u{2d}ui-test-escaped"
'''
        )
        errors = validator.validate_sources(sources)

        for value in (
            "--uitesting",
            "--ui-test-raw",
            "--ui-test-multiline",
            "--ui-test-escaped",
        ):
            with self.subTest(value=value):
                self.assertTrue(any(value in error for error in errors), errors)

    def test_interpolation_code_is_recursively_validated(self) -> None:
        sources = base_sources(
            r'let value = "\(ProcessInfo.processInfo.arguments.contains("--uitesting"))"'
        )
        errors = validator.validate_sources(sources)

        self.assertTrue(any("ProcessInfo.processInfo.arguments selector" in error for error in errors))
        self.assertTrue(any("custom UI-test token '--uitesting'" in error for error in errors))

    def test_mock_identifiers_are_allowed_only_in_either_exact_declaration_body(self) -> None:
        clean = base_sources()
        self.assertEqual(validator.validate_sources(clean), [])

        same_file_external = dict(clean)
        same_file_external["Packages/Core/Sources/Core/Mocks.swift"] += (
            "\nlet leaked = MockServiceContainer()\n"
        )
        errors = validator.validate_sources(same_file_external)
        self.assertTrue(any("mock reference MockServiceContainer" in error for error in errors))

        debug_external = dict(clean)
        debug_external["Packages/Core/Sources/Core/Mocks.swift"] += (
            "\n#if DEBUG\nlet preview = MockServiceContainer()\n#endif\n"
        )
        self.assertEqual(validator.validate_sources(debug_external), [])

    def test_preview_has_no_release_allowlist(self) -> None:
        release_preview = base_sources(
            "#Preview { MockServiceContainer() }\n"
        )
        errors = validator.validate_sources(release_preview)
        self.assertTrue(any("mock reference MockServiceContainer" in error for error in errors))

        debug_preview = base_sources(
            "#if DEBUG\n#Preview { MockServiceContainer() }\n#endif\n"
        )
        self.assertEqual(validator.validate_sources(debug_preview), [])

    def test_missing_or_duplicate_mock_declaration_fails_closed(self) -> None:
        missing = base_sources()
        missing["Packages/Core/Sources/Core/Mocks.swift"] = "let value = 1\n"
        duplicate = base_sources()
        duplicate["Packages/Core/Sources/Core/MoreMocks.swift"] = (
            "final class MockServiceContainer {}\n"
        )

        self.assertTrue(
            any("expected exactly one AnalyticsServiceMock" in error for error in validator.validate_sources(missing))
        )
        self.assertTrue(
            any("expected exactly one MockServiceContainer" in error for error in validator.validate_sources(duplicate))
        )

    def test_malformed_source_fails_closed_before_policy_scan(self) -> None:
        cases = (
            "/* unterminated",
            'let value = "unterminated',
            "#if DEBUG\nlet value = 1",
            "#if os()\n#endif",
            "#if DEBUG\n#else\n#else\n#endif",
        )
        for source in cases:
            with self.subTest(source=source):
                errors = validator.validate_sources(base_sources(source))
                self.assertTrue(any("offset" in error for error in errors), errors)

    def test_expected_custom_value_census_is_exact(self) -> None:
        sources = base_sources("#if DEBUG\nlet token = \"--uitesting\"\n#endif\n")

        self.assertEqual(
            validator.validate_sources(sources, expected_custom_values=("--uitesting",)),
            [],
        )
        errors = validator.validate_sources(
            sources, expected_custom_values=("--uitesting", "--ui-test-missing")
        )
        self.assertTrue(any("token census mismatch" in error for error in errors))
        self.assertEqual(len(validator.EXPECTED_CUSTOM_TOKEN_VALUES), 19)

    def test_discovery_includes_top_level_share_and_deep_package_sentinel(self) -> None:
        with TemporaryGitRepo() as repo:
            files = {
                "SnapDrill/App.swift": "let app = 1\n",
                "SnapDrill/Nested/Child.swift": "let child = 1\n",
                "SnapDrillShare/ShareViewController.swift": "let share = 1\n",
                "SnapDrillShare/Nested/Writer.swift": "let writer = 1\n",
                "Packages/Core/Sources/Top.swift": "let top = 1\n",
                "Packages/Core/Sources/Core/Support/AppConfiguration.swift": "let config = 1\n",
                "Packages/Core/Tests/CoreTests/Test.swift": "let packageTest = 1\n",
                "SnapDrillUITests/Test.swift": "let uiTest = 1\n",
                "SnapDrillShareTests/Test.swift": "let shareTest = 1\n",
                "SnapDrill/ignored.txt": "not Swift\n",
            }
            repo.add(files)
            sentinel = "Packages/Core/Sources/Core/Support/AppConfiguration.swift"
            sources = validator.discover_tracked_sources(
                repo.root,
                expected_count=6,
                required_sentinels=(sentinel, "SnapDrillShare/ShareViewController.swift"),
            )

        self.assertEqual(
            set(sources),
            {
                "SnapDrill/App.swift",
                "SnapDrill/Nested/Child.swift",
                "SnapDrillShare/ShareViewController.swift",
                "SnapDrillShare/Nested/Writer.swift",
                "Packages/Core/Sources/Top.swift",
                sentinel,
            },
        )

    def test_discovery_requires_each_root_count_and_sentinel(self) -> None:
        with TemporaryGitRepo() as repo:
            repo.add(
                {
                    "SnapDrill/App.swift": "let app = 1\n",
                    "SnapDrillShare/Share.swift": "let share = 1\n",
                    "Packages/Core/Sources/Core.swift": "let core = 1\n",
                }
            )
            with self.assertRaisesRegex(
                validator.ReleaseOverrideValidationError, "census mismatch"
            ):
                validator.discover_tracked_sources(
                    repo.root, expected_count=4, required_sentinels=()
                )
            with self.assertRaisesRegex(
                validator.ReleaseOverrideValidationError, "missing production sentinel"
            ):
                validator.discover_tracked_sources(
                    repo.root,
                    expected_count=3,
                    required_sentinels=("SnapDrill/Missing.swift",),
                )

        with TemporaryGitRepo() as repo:
            repo.add(
                {
                    "SnapDrill/App.swift": "let app = 1\n",
                    "Packages/Core/Sources/Core.swift": "let core = 1\n",
                }
            )
            with self.assertRaisesRegex(
                validator.ReleaseOverrideValidationError, "SnapDrillShare"
            ):
                validator.discover_tracked_sources(
                    repo.root, expected_count=None, required_sentinels=()
                )

    def test_discovery_rejects_non_git_and_non_utf8_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(
                validator.ReleaseOverrideValidationError, "git ls-files failed"
            ):
                validator.discover_tracked_sources(
                    Path(directory), expected_count=None, required_sentinels=()
                )

        with TemporaryGitRepo() as repo:
            repo.add(
                {
                    "SnapDrill/App.swift": b"\xff",
                    "SnapDrillShare/Share.swift": "let share = 1\n",
                    "Packages/Core/Sources/Core.swift": "let core = 1\n",
                }
            )
            with self.assertRaisesRegex(
                validator.ReleaseOverrideValidationError, "not UTF-8"
            ):
                validator.discover_tracked_sources(
                    repo.root, expected_count=3, required_sentinels=()
                )

    def test_path_filter_rejects_duplicates_and_non_normalized_paths(self) -> None:
        valid = [
            "SnapDrill/App.swift",
            "SnapDrillShare/Share.swift",
            "Packages/Core/Sources/Core.swift",
        ]
        with self.assertRaisesRegex(
            validator.ReleaseOverrideValidationError, "duplicate tracked path"
        ):
            validator.select_production_paths(valid + [valid[0]])
        for invalid in ("/SnapDrill/App.swift", "../App.swift", "SnapDrill/./App.swift"):
            with self.subTest(path=invalid):
                with self.assertRaises(validator.ReleaseOverrideValidationError):
                    validator.select_production_paths(valid + [invalid])

    def test_mapping_rejects_tests_and_other_nonproduction_paths(self) -> None:
        for path in (
            "SnapDrillUITests/Test.swift",
            "SnapDrillShareTests/Test.swift",
            "Packages/Core/Tests/CoreTests/Test.swift",
        ):
            with self.subTest(path=path):
                sources = base_sources()
                sources[path] = "let test = 1\n"
                errors = validator.validate_sources(sources)
                self.assertTrue(any("non-production path" in error for error in errors))


class TemporaryGitRepo:
    def __enter__(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        subprocess.run(
            ["git", "init", "--quiet"],
            cwd=self.root,
            check=True,
            capture_output=True,
            env=self.git_environment(),
        )
        return self

    def __exit__(self, exc_type, exc, traceback) -> None:
        self.temporary_directory.cleanup()

    def add(self, files: dict[str, object]) -> None:
        for relative_path, content in files.items():
            path = self.root / relative_path
            path.parent.mkdir(parents=True, exist_ok=True)
            if isinstance(content, bytes):
                path.write_bytes(content)
            else:
                path.write_text(str(content), encoding="utf-8")
        env = self.git_environment()
        env.update(
            {
                "GIT_AUTHOR_NAME": "Tests",
                "GIT_AUTHOR_EMAIL": "tests@example.invalid",
                "GIT_COMMITTER_NAME": "Tests",
                "GIT_COMMITTER_EMAIL": "tests@example.invalid",
            }
        )
        subprocess.run(
            ["git", "add", "--", "."],
            cwd=self.root,
            check=True,
            capture_output=True,
            env=env,
        )

    @staticmethod
    def git_environment() -> dict[str, str]:
        return {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("GIT_")
        }


if __name__ == "__main__":
    unittest.main()
