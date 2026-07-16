#!/usr/bin/env python3
"""Regression tests for GitHub Actions CI contracts."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_ROOT = REPO_ROOT / "Scripts"
sys.path.insert(0, str(SCRIPTS_ROOT))

import ci_github  # noqa: E402

SCRIPT = SCRIPTS_ROOT / "ci_github.py"
WORKFLOW = REPO_ROOT / ".github/workflows/ci.yml"
TOOLCHAIN = REPO_ROOT / "Configs/Toolchain.env"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
EXACT_UDID = "11111111-2222-3333-4444-555555555555"


def simulator_device(
    name: str,
    udid: str,
    *,
    device_type: str,
    available: bool = True,
) -> dict[str, object]:
    return {
        "name": name,
        "udid": udid,
        "deviceTypeIdentifier": device_type,
        "isAvailable": available,
        "state": "Shutdown",
    }


def simulator_inventory() -> dict[str, object]:
    return {
        "devices": {
            RUNTIME: [
                simulator_device(
                    "iPhone 17 Pro",
                    "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
                    device_type="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
                ),
                simulator_device(
                    "iPhone 17 Pro Max",
                    "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF",
                    device_type="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro-Max",
                ),
                simulator_device(
                    "iPhone 17e",
                    "CCCCCCCC-DDDD-EEEE-FFFF-AAAAAAAAAAAA",
                    device_type="com.apple.CoreSimulator.SimDeviceType.iPhone-17e",
                ),
                simulator_device(
                    "iPhone 17",
                    EXACT_UDID,
                    device_type=DEVICE_TYPE,
                ),
            ]
        }
    }


class ToolchainContractTests(unittest.TestCase):
    def test_repository_toolchain_parses(self) -> None:
        parsed = ci_github.parse_toolchain(TOOLCHAIN.read_text(encoding="utf-8"))

        self.assertEqual(parsed.xcode_version, "26.6")
        self.assertEqual(parsed.xcode_build_version, "17F113")
        self.assertEqual(parsed.swiftlint_version, "0.63.2")

    def test_toolchain_parser_rejects_unknown_duplicate_and_shell_values(self) -> None:
        invalid_inputs = (
            "XCODE_VERSION=26.6\nXCODE_BUILD_VERSION=17F113\n"
            "SWIFTLINT_VERSION=0.63.2\nEXTRA=value\n",
            "XCODE_VERSION=26.6\nXCODE_VERSION=26.5\n"
            "XCODE_BUILD_VERSION=17F113\nSWIFTLINT_VERSION=0.63.2\n",
            "XCODE_VERSION=$(whoami)\nXCODE_BUILD_VERSION=17F113\n"
            "SWIFTLINT_VERSION=0.63.2\n",
        )
        for text in invalid_inputs:
            with self.subTest(text=text), self.assertRaises(ci_github.ContractError):
                ci_github.parse_toolchain(text)

    def test_toolchain_identity_requires_exact_two_line_xcode_and_swiftlint(self) -> None:
        expected = ci_github.Toolchain("26.6", "17F113", "0.63.2")
        ci_github.validate_toolchain(expected, "Xcode 26.6\nBuild version 17F113", "0.63.2")

        invalid = (
            ("Xcode 26.5\nBuild version 17F113", "0.63.2"),
            ("Xcode 26.6\nBuild version WRONG", "0.63.2"),
            ("Xcode 26.6\nBuild version 17F113\nextra", "0.63.2"),
            ("Xcode 26.6\nBuild version 17F113", "0.64.0"),
        )
        for xcode_output, swiftlint_output in invalid:
            with self.subTest(
                xcode=xcode_output,
                swiftlint=swiftlint_output,
            ), self.assertRaises(ci_github.ContractError):
                ci_github.validate_toolchain(expected, xcode_output, swiftlint_output)

    def test_toolchain_cli_freezes_validated_developer_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            self.write_executable(
                bin_dir / "xcode-select",
                """
                #!/bin/sh
                [ "$1" = "-p" ] || exit 8
                printf '%s\n' '/Applications/Xcode.app/Contents/Developer'
                """,
            )
            self.write_executable(
                bin_dir / "xcodebuild",
                """
                #!/bin/sh
                [ "$DEVELOPER_DIR" = "/Applications/Xcode.app/Contents/Developer" ] || exit 9
                printf 'Xcode 26.6\nBuild version 17F113\n'
                """,
            )
            self.write_executable(
                bin_dir / "swiftlint",
                """
                #!/bin/sh
                printf '%s\n' '0.63.2'
                """,
            )
            github_env = root / "github-env"
            environment = os.environ.copy()
            environment["PATH"] = str(bin_dir)

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "toolchain",
                    "--config",
                    str(TOOLCHAIN),
                    "--github-env",
                    str(github_env),
                ],
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("Xcode 26.6 (17F113)", result.stdout)
            self.assertEqual(
                github_env.read_text(encoding="utf-8"),
                "DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer\n",
            )

    def test_toolchain_cli_fails_when_required_tool_is_missing(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            self.write_executable(
                bin_dir / "xcode-select",
                "#!/bin/sh\nprintf '%s\\n' '/Applications/Xcode.app/Contents/Developer'\n",
            )
            self.write_executable(
                bin_dir / "xcodebuild",
                "#!/bin/sh\nprintf 'Xcode 26.6\\nBuild version 17F113\\n'\n",
            )
            environment = os.environ.copy()
            environment["PATH"] = str(bin_dir)

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "toolchain",
                    "--config",
                    str(TOOLCHAIN),
                    "--github-env",
                    str(root / "github-env"),
                ],
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("cannot execute swiftlint", result.stderr)

    @staticmethod
    def write_executable(path: Path, body: str) -> None:
        path.write_text(textwrap.dedent(body).lstrip(), encoding="utf-8")
        path.chmod(0o755)


class SimulatorContractTests(unittest.TestCase):
    def test_exact_device_wins_even_when_variants_are_listed_first(self) -> None:
        selected = ci_github.select_simulator(
            simulator_inventory(),
            exact_name="iPhone 17",
            device_type_identifier=DEVICE_TYPE,
        )

        self.assertEqual(selected.udid, EXACT_UDID)
        self.assertEqual(selected.runtime_identifier, RUNTIME)
        self.assertEqual(selected.destination, f"platform=iOS Simulator,id={EXACT_UDID}")

    def test_missing_duplicate_wrong_type_and_unavailable_devices_fail_closed(self) -> None:
        cases: dict[str, dict[str, object]] = {}

        missing = simulator_inventory()
        missing["devices"][RUNTIME] = missing["devices"][RUNTIME][:-1]  # type: ignore[index]
        cases["missing"] = missing

        duplicate = simulator_inventory()
        duplicate["devices"]["com.apple.CoreSimulator.SimRuntime.iOS-26-4"] = [  # type: ignore[index]
            simulator_device(
                "iPhone 17",
                "22222222-3333-4444-5555-666666666666",
                device_type=DEVICE_TYPE,
            )
        ]
        cases["duplicate"] = duplicate

        wrong_type = simulator_inventory()
        wrong_type["devices"][RUNTIME][-1]["deviceTypeIdentifier"] = (  # type: ignore[index]
            "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
        )
        cases["wrong_type"] = wrong_type

        unavailable = simulator_inventory()
        unavailable["devices"][RUNTIME][-1]["isAvailable"] = False  # type: ignore[index]
        cases["unavailable"] = unavailable

        for name, inventory in cases.items():
            with self.subTest(case=name), self.assertRaises(ci_github.ContractError):
                ci_github.select_simulator(
                    inventory,
                    exact_name="iPhone 17",
                    device_type_identifier=DEVICE_TYPE,
                )

    def test_malformed_inventory_and_exact_device_fields_fail_closed(self) -> None:
        invalid_uuid = simulator_inventory()
        invalid_uuid["devices"][RUNTIME][-1]["udid"] = "not-a-uuid"  # type: ignore[index]

        cases: tuple[object, ...] = (
            {},
            {"devices": []},
            {"devices": {RUNTIME: ["not-an-object"]}},
            invalid_uuid,
        )
        for inventory in cases:
            with self.subTest(inventory=inventory), self.assertRaises(ci_github.ContractError):
                ci_github.select_simulator(
                    inventory,
                    exact_name="iPhone 17",
                    device_type_identifier=DEVICE_TYPE,
                )

    def test_simulator_cli_writes_step_scoped_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            inventory = root / "devices.json"
            output = root / "github-output"
            inventory.write_text(json.dumps(simulator_inventory()), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "simulator",
                    "--inventory",
                    str(inventory),
                    "--name",
                    "iPhone 17",
                    "--device-type",
                    DEVICE_TYPE,
                    "--github-output",
                    str(output),
                ],
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            values = dict(
                line.split("=", maxsplit=1)
                for line in output.read_text(encoding="utf-8").splitlines()
            )
            self.assertEqual(values["name"], "iPhone 17")
            self.assertEqual(values["udid"], EXACT_UDID)
            self.assertEqual(values["runtime"], RUNTIME)
            self.assertEqual(values["device_type"], DEVICE_TYPE)
            self.assertEqual(values["destination"], f"platform=iOS Simulator,id={EXACT_UDID}")


class XCTestRunContractTests(unittest.TestCase):
    def test_exactly_one_nested_xctestrun_is_returned(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            expected = root / "nested/AllTests_fixture.xctestrun"
            expected.parent.mkdir()
            expected.touch()

            selected = ci_github.find_exact_xctestrun(root, "AllTests_*.xctestrun")

            self.assertEqual(selected, expected.resolve())

    def test_zero_or_multiple_xctestruns_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with self.assertRaises(ci_github.ContractError):
                ci_github.find_exact_xctestrun(root, "AllTests_*.xctestrun")

            (root / "AllTests_one.xctestrun").touch()
            (root / "AllTests_two.xctestrun").touch()
            with self.assertRaises(ci_github.ContractError):
                ci_github.find_exact_xctestrun(root, "AllTests_*.xctestrun")


class WorkflowContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.workflow = WORKFLOW.read_text(encoding="utf-8")
        jobs = self.workflow.split("  build:\n", maxsplit=1)[1]
        self.build, self.ui = jobs.split("  ui-tests:\n", maxsplit=1)

    def test_checkout_is_pinned_read_only_and_drops_credentials(self) -> None:
        checkout = "actions/checkout@93cb6efe18208431cddfb8368fd83d5badbf9bfd"
        checkout_count = self.workflow.count("uses: actions/checkout@")
        self.assertEqual(checkout_count, 2)
        self.assertEqual(self.workflow.count(checkout), checkout_count)
        self.assertEqual(self.workflow.count("persist-credentials: false"), checkout_count)
        self.assertEqual(self.workflow.count("permissions:"), 1)
        self.assertIn("permissions:\n  contents: read", self.workflow)
        self.assertNotIn("contents: write", self.workflow)
        self.assertNotIn("persist-credentials: true", self.workflow)

    def test_both_jobs_bind_tools_checkout_and_simulator_through_contract(self) -> None:
        for job in (self.build, self.ui):
            with self.subTest(job=job[:30]):
                self.assertIn("python3 Scripts/ci_github.py toolchain", job)
                self.assertIn("--config Configs/Toolchain.env", job)
                self.assertIn('"$(git rev-parse HEAD)" != "$GITHUB_SHA"', job)
                self.assertIn("python3 Scripts/ci_github.py simulator", job)
                self.assertIn(
                    'xcrun simctl list devices available -j > "$INVENTORY"',
                    job,
                )
                self.assertIn("id: simulator", job)
                self.assertGreaterEqual(
                    job.count("DEVICE_ID: ${{ steps.simulator.outputs.udid }}"),
                    3,
                )
                self.assertIn('platform=iOS Simulator,id=$DEVICE_ID', job)

    def test_workflow_has_one_resolve_and_one_test_per_job_without_generic_retry(self) -> None:
        for job in (self.build, self.ui):
            with self.subTest(job=job[:30]):
                self.assertEqual(job.count("-resolvePackageDependencies"), 1)
                self.assertEqual(job.count("test-without-building"), 1)
                self.assertIn("python3 Scripts/ci_github.py xctestrun", job)
                self.assertIn("steps.xctestrun.outputs.path", job)

        forbidden = (
            "head -1",
            "platform=iOS Simulator,name=iPhone 17",
            "brew install swiftlint",
            "sudo xcode-select",
            "git config --global",
            "while :",
            "UI test attempt",
            "likely simulator launch flake",
            "xcpretty",
        )
        for text in forbidden:
            with self.subTest(text=text):
                self.assertNotIn(text, self.workflow)


if __name__ == "__main__":
    unittest.main()
