#!/usr/bin/env python3
"""Regression tests for the canonical local source gate."""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CI_LOCAL = REPO_ROOT / "Scripts" / "ci-local.sh"
LINT = REPO_ROOT / "Scripts" / "lint.sh"
TOOLCHAIN = REPO_ROOT / "Configs" / "Toolchain.env"
README = REPO_ROOT / "README.md"
TEST_PLAN = REPO_ROOT / "SnapDrill.xcodeproj/xcshareddata/xctestplans/AllTests.xctestplan"
FAKE_SHA = "0123456789abcdef0123456789abcdef01234567"


def read_toolchain() -> dict[str, str]:
    values: dict[str, str] = {}
    for line in TOOLCHAIN.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        key, value = line.split("=", maxsplit=1)
        values[key] = value
    return values


class CILocalTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.bin_dir = self.root / "bin"
        self.tmp_dir = self.root / "tmp"
        self.log_path = self.root / "commands.log"
        self.bin_dir.mkdir()
        self.tmp_dir.mkdir()
        self.toolchain = read_toolchain()
        self.write_fake_commands()

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_executable(self, name: str, body: str) -> None:
        path = self.bin_dir / name
        path.write_text(textwrap.dedent(body).lstrip(), encoding="utf-8")
        path.chmod(0o755)

    def write_fake_commands(self) -> None:
        self.write_executable(
            "git",
            r"""
            #!/bin/bash
            set -euo pipefail
            printf 'git|%s|%s\n' "$PWD" "$*" >> "$FAKE_COMMAND_LOG"
            if [[ "${1:-}" == "-C" && "${3:-}" == "rev-parse" && "${4:-}" == "--show-toplevel" ]]; then
              printf '%s\n' "$FAKE_REPO_ROOT"
            elif [[ "$*" == "rev-parse HEAD" ]]; then
              printf '%s\n' "$FAKE_SHA"
            elif [[ "$*" == "status --porcelain --untracked-files=all" ]]; then
              if [[ -n "${FAKE_DIRTY_STATE:-}" ]]; then
                printf '%s\n' "$FAKE_DIRTY_STATE"
              fi
            else
              exit 97
            fi
            """,
        )
        self.write_executable(
            "swiftlint",
            r"""
            #!/bin/bash
            set -euo pipefail
            printf 'swiftlint|%s|%s\n' "$PWD" "$*" >> "$FAKE_COMMAND_LOG"
            if [[ "${1:-}" == "version" ]]; then
              printf '%s\n' "$FAKE_SWIFTLINT_VERSION"
              exit 0
            fi
            if [[ "${FAKE_FAIL_STAGE:-}" == "lint" ]]; then
              exit 21
            fi
            exit 0
            """,
        )
        self.write_executable(
            "swift",
            r"""
            #!/bin/bash
            set -euo pipefail
            printf 'swift|%s|%s\n' "$PWD" "$*" >> "$FAKE_COMMAND_LOG"
            if [[ "$*" == package\ --package-path\ *\ dump-package ]]; then
              printf '%s\n' '{"targets":[{"name":"Fixture","type":"regular","settings":[]}]}'
              exit 0
            fi
            exit 96
            """,
        )
        self.write_executable(
            "python3",
            r"""
            #!/bin/bash
            set -euo pipefail
            printf 'python3|%s|%s\n' "$PWD" "$*" >> "$FAKE_COMMAND_LOG"
            if [[ "$*" == *"validate_docs.py"* ]]; then
              printf '%s\n' '[warning] retained policy warning' >&2
            fi
            if [[ -n "${FAKE_FAIL_PATTERN:-}" && "$*" == *"$FAKE_FAIL_PATTERN"* ]]; then
              exit 22
            fi
            if [[ "$*" == *"--effective-"* ]]; then
              /bin/cat >/dev/null
            fi
            exit 0
            """,
        )
        self.write_executable(
            "find",
            r"""
            #!/bin/bash
            set -euo pipefail
            printf 'find|%s|%s\n' "$PWD" "$*" >> "$FAKE_COMMAND_LOG"
            if [[ "${FAKE_FIND_FAILURE:-}" == "1" ]]; then
              exit 25
            fi
            exec /usr/bin/find "$@"
            """,
        )
        self.write_executable(
            "xcodebuild",
            r"""
            #!/bin/bash
            set -euo pipefail
            printf 'xcodebuild|%s|%s\n' "$PWD" "$*" >> "$FAKE_COMMAND_LOG"
            if [[ "${1:-}" == "-version" ]]; then
              printf 'Xcode %s\nBuild version %s\n' "$FAKE_XCODE_VERSION" "$FAKE_XCODE_BUILD_VERSION"
              exit 0
            fi

            if [[ "$*" == *"-showBuildSettings"* && "$*" == *"-json"* ]]; then
              payload='[{"target":"SnapDrill",'
              payload+='"buildSettings":{"CONFIGURATION":"Release"}},'
              payload+='{"target":"SnapDrillShare",'
              payload+='"buildSettings":{"CONFIGURATION":"Release"}}]'
              printf '%s\n' "$payload"
              exit 0
            fi

            derived_data=""
            result_bundle=""
            previous=""
            for argument in "$@"; do
              if [[ "$previous" == "-derivedDataPath" ]]; then
                derived_data="$argument"
              elif [[ "$previous" == "-resultBundlePath" ]]; then
                result_bundle="$argument"
              fi
              previous="$argument"
            done

            if [[ "${1:-}" == "build-for-testing" ]]; then
              if [[ "${FAKE_FAIL_STAGE:-}" == "build" ]]; then
                exit 23
              fi
              mkdir -p "$derived_data/Build/Products" "$result_bundle"
              count="${FAKE_XCTESTRUN_COUNT:-1}"
              index=1
              while [[ "$index" -le "$count" ]]; do
                touch "$derived_data/Build/Products/AllTests_fixture_${index}.xctestrun"
                index=$((index + 1))
              done
              exit 0
            fi

            if [[ "${1:-}" == "test-without-building" ]]; then
              mkdir -p "$result_bundle"
              if [[ "${FAKE_FAIL_STAGE:-}" == "test" ]]; then
                exit 24
              fi
              exit 0
            fi
            exit 98
            """,
        )
        self.write_executable(
            "xcpretty",
            r"""
            #!/bin/bash
            printf 'xcpretty|%s|%s\n' "$PWD" "$*" >> "$FAKE_COMMAND_LOG"
            exit 0
            """,
        )

    def environment(self, **overrides: str) -> dict[str, str]:
        environment = os.environ.copy()
        environment.pop("BASH_ENV", None)
        environment.update(
            {
                "PATH": f"{self.bin_dir}:{environment['PATH']}",
                "TMPDIR": str(self.tmp_dir),
                "FAKE_COMMAND_LOG": str(self.log_path),
                "FAKE_REPO_ROOT": str(REPO_ROOT),
                "FAKE_SHA": FAKE_SHA,
                "FAKE_XCODE_VERSION": self.toolchain["XCODE_VERSION"],
                "FAKE_XCODE_BUILD_VERSION": self.toolchain["XCODE_BUILD_VERSION"],
                "FAKE_SWIFTLINT_VERSION": self.toolchain["SWIFTLINT_VERSION"],
            }
        )
        environment.update(overrides)
        return environment

    def run_gate(
        self,
        *,
        cwd: Path = REPO_ROOT,
        environment: dict[str, str] | None = None,
    ) -> subprocess.CompletedProcess[str]:
        self.log_path.unlink(missing_ok=True)
        return subprocess.run(
            ["/bin/bash", str(CI_LOCAL)],
            cwd=cwd,
            env=environment or self.environment(),
            text=True,
            capture_output=True,
            check=False,
        )

    def command_log(self) -> list[str]:
        return self.log_path.read_text(encoding="utf-8").splitlines()

    def test_happy_path_runs_one_alltests_build_and_ci_test(self) -> None:
        sentinel = self.tmp_dir / "keep-me"
        sentinel.write_text("owned by caller", encoding="utf-8")

        result = self.run_gate()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Source gate PASSED", result.stdout)
        self.assertIn("[warning] retained policy warning", result.stderr)
        log = self.command_log()
        build = [line for line in log if "|build-for-testing " in line]
        test = [line for line in log if "|test-without-building " in line]
        self.assertEqual(len(build), 1)
        self.assertEqual(len(test), 1)
        self.assertIn("-scheme AllTests", build[0])
        self.assertIn("-testPlan AllTests", build[0])
        self.assertIn("-only-test-configuration CI", test[0])
        self.assertIn("-destination platform=iOS Simulator,name=iPhone 17", build[0])
        self.assertIn("-destination platform=iOS Simulator,name=iPhone 17", test[0])
        self.assertTrue(
            any(
                line.startswith("python3|")
                and "ci_github.py dependencies --root" in line
                for line in log
            )
        )
        self.assertFalse(any(line.startswith("grep|") for line in log))
        self.assertNotIn("-skip-testing", "\n".join(log))
        self.assertFalse(any(line.startswith("xcpretty|") for line in log))
        release_settings = [
            line
            for line in log
            if line.startswith("xcodebuild|")
            and "-configuration Release" in line
            and "-showBuildSettings -json" in line
        ]
        self.assertEqual(len(release_settings), 4)
        self.assertEqual(
            sum("-scheme SnapDrill " in line for line in release_settings),
            2,
        )
        self.assertEqual(
            sum("-scheme SnapDrillShare " in line for line in release_settings),
            2,
        )
        self.assertTrue(
            any("-destination generic/platform=iOS Simulator" in line for line in release_settings)
        )
        self.assertTrue(
            any("-destination generic/platform=iOS -showBuildSettings" in line for line in release_settings)
        )
        self.assertEqual(
            sum("--effective-release-settings-stdin" in line for line in log),
            4,
        )
        self.assertEqual(
            sum("--expected-release-target" in line for line in log),
            4,
        )
        package_dumps = [
            line
            for line in log
            if line.startswith("swift|") and " dump-package" in line
        ]
        self.assertEqual(len(package_dumps), 4)
        self.assertTrue(
            all("package --package-path Packages/" in line for line in package_dumps)
        )
        self.assertEqual(
            sum("--effective-package-settings-stdin" in line for line in log),
            4,
        )
        self.assertTrue(sentinel.exists())
        self.assertEqual(list(self.tmp_dir.glob("snapdrill-ci-local.*")), [])

    def test_lint_build_and_test_failures_never_print_success(self) -> None:
        for stage in ("lint", "build", "test"):
            with self.subTest(stage=stage):
                result = self.run_gate(environment=self.environment(FAKE_FAIL_STAGE=stage))
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Source gate PASSED", result.stdout)
                if stage == "build":
                    self.assertFalse(
                        any("|test-without-building " in line for line in self.command_log())
                    )

    def test_each_python_gate_failure_is_propagated(self) -> None:
        patterns = (
            "-m unittest",
            "generate_feature_status.py",
            "generate_intent_traceability.py",
            "test_doc_generators.py",
            "validate_docs.py",
            "validate_capture_contract.py",
            "validate_release_configuration.py",
            "validate_release_test_overrides.py",
            "ci_github.py dependencies",
            "AllTests.xctestplan",
        )
        for pattern in patterns:
            with self.subTest(pattern=pattern):
                result = self.run_gate(
                    environment=self.environment(FAKE_FAIL_PATTERN=pattern)
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("Source gate PASSED", result.stdout)

    def test_missing_or_duplicate_xctestrun_fails_before_test(self) -> None:
        for count in ("0", "2"):
            with self.subTest(count=count):
                result = self.run_gate(
                    environment=self.environment(FAKE_XCTESTRUN_COUNT=count)
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("expected exactly one", result.stderr)
                self.assertFalse(
                    any("|test-without-building " in line for line in self.command_log())
                )

    def test_xctestrun_discovery_error_fails_closed(self) -> None:
        result = self.run_gate(
            environment=self.environment(FAKE_FIND_FAILURE="1")
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failed to inspect generated AllTests xctestrun files", result.stderr)
        self.assertFalse(
            any("|test-without-building " in line for line in self.command_log())
        )

    def test_tool_identity_mismatch_stops_before_lint(self) -> None:
        cases = (
            {"FAKE_XCODE_VERSION": "0.0"},
            {"FAKE_XCODE_BUILD_VERSION": "INVALID"},
            {"FAKE_SWIFTLINT_VERSION": "0.0.0"},
        )
        for overrides in cases:
            with self.subTest(overrides=overrides):
                result = self.run_gate(environment=self.environment(**overrides))
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(
                    any(
                        line.startswith("swiftlint|") and line.endswith("|--strict")
                        for line in self.command_log()
                    )
                )

    def test_missing_xcode_or_swiftlint_fails_before_validation(self) -> None:
        for tool in ("xcodebuild", "swiftlint"):
            with self.subTest(tool=tool):
                path = self.bin_dir / tool
                backup = self.bin_dir / f"{tool}.disabled"
                path.rename(backup)
                try:
                    result = self.run_gate(
                        environment=self.environment(PATH=str(self.bin_dir))
                    )
                finally:
                    backup.rename(path)

                self.assertNotEqual(result.returncode, 0)
                self.assertIn(f"required command not found: {tool}", result.stderr)
                self.assertFalse(any("|build-for-testing " in line for line in self.command_log()))

    def test_dirty_checkout_fails_before_validation(self) -> None:
        result = self.run_gate(
            environment=self.environment(FAKE_DIRTY_STATE=" M Packages/Changed.swift")
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("clean committed checkout", result.stderr)
        self.assertFalse(any(line.startswith("xcodebuild|") for line in self.command_log()))

    def test_nested_invocation_runs_commands_from_repository_root(self) -> None:
        nested = self.root / "elsewhere" / "nested"
        nested.mkdir(parents=True)

        result = self.run_gate(cwd=nested)

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        log = self.command_log()
        self.assertIn(f"git|{nested.resolve()}|-C ", log[0])
        self.assertIn("rev-parse --show-toplevel", log[0])
        for line in log[1:]:
            if line.count("|") < 2:
                continue
            _, working_directory, _ = line.split("|", maxsplit=2)
            self.assertEqual(working_directory, str(REPO_ROOT))

    def test_invocation_from_scripts_directory_resolves_repository_root(self) -> None:
        self.log_path.unlink(missing_ok=True)
        result = subprocess.run(
            ["/bin/bash", "ci-local.sh"],
            cwd=REPO_ROOT / "Scripts",
            env=self.environment(),
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Source gate PASSED", result.stdout)

    def test_success_claim_has_explicit_evidence_boundary(self) -> None:
        result = self.run_gate()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("exact simulator identity/allocation", result.stdout)
        self.assertIn("app UI/XCUITest or AX", result.stdout)
        self.assertIn("archive/install", result.stdout)
        self.assertIn("privacy/network", result.stdout)
        self.assertIn("candidate conformance", result.stdout)
        self.assertIn("does not authorize merge, upload, TestFlight, go/no-go, or release", result.stdout)

    def test_release_test_override_gate_is_in_the_canonical_path(self) -> None:
        result = self.run_gate()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(
            any(
                line.startswith("python3|")
                and "Scripts/validate_release_test_overrides.py --check" in line
                for line in self.command_log()
            )
        )

    def test_default_plan_and_readme_cannot_select_snapshot_record(self) -> None:
        plan = json.loads(TEST_PLAN.read_text(encoding="utf-8"))
        configurations = [item.get("name") for item in plan.get("configurations", [])]
        self.assertEqual(configurations.count("CI"), 1)
        self.assertGreater(len(plan.get("testTargets", [])), 0)

        readme = README.read_text(encoding="utf-8")
        testing = readme.split("## 测试", maxsplit=1)[1]
        default_path = testing.split("### 快照重录", maxsplit=1)[0]
        self.assertIn("bash Scripts/ci-local.sh", default_path)
        self.assertNotIn("SnapshotRecord", default_path)
        self.assertNotIn("Cmd+U", default_path)

    def test_lint_wrapper_fails_when_swiftlint_is_missing(self) -> None:
        empty_path = self.root / "empty-path"
        empty_path.mkdir()
        environment = os.environ.copy()
        environment["PATH"] = str(empty_path)

        result = subprocess.run(
            ["/bin/bash", str(LINT)],
            cwd=REPO_ROOT,
            env=environment,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SwiftLint not installed", result.stderr)


if __name__ == "__main__":
    unittest.main()
