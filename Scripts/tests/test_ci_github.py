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
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_ROOT = REPO_ROOT / "Scripts"
sys.path.insert(0, str(SCRIPTS_ROOT))

import ci_github  # noqa: E402

SCRIPT = SCRIPTS_ROOT / "ci_github.py"
WORKFLOW = REPO_ROOT / ".github/workflows/ci.yml"
TOOLCHAIN = REPO_ROOT / "Configs/Toolchain.env"
DEVICE_TYPE = "com.apple.CoreSimulator.SimDeviceType.iPhone-17"
RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
OTHER_RUNTIME = "com.apple.CoreSimulator.SimRuntime.iOS-26-4"
EXACT_UDID = "11111111-2222-3333-4444-555555555555"
TOOLCHAIN_TEXT = TOOLCHAIN.read_text(encoding="utf-8")
EXPECTED_TOOLCHAIN = ci_github.parse_toolchain(TOOLCHAIN_TEXT)


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


def make_dependency_tree(root: Path) -> None:
    sources = {
        "Packages/SnapDrillCore/Sources/Core.swift": "import Foundation\n",
        "Packages/SnapDrillData/Sources/Data.swift": "import SnapDrillCore\n",
        "Packages/SnapDrillUI/Sources/UI.swift": "import SnapDrillCore\n",
        "SnapDrillShare/Share.swift": "import SwiftUI\n",
    }
    for relative_path, content in sources.items():
        path = root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


class ToolchainContractTests(unittest.TestCase):
    def test_repository_toolchain_parses(self) -> None:
        parsed = EXPECTED_TOOLCHAIN

        self.assertEqual(parsed.xcode_version, "26.6")
        self.assertEqual(parsed.xcode_build_version, "17F113")
        self.assertEqual(parsed.swiftlint_version, "0.63.2")
        self.assertEqual(parsed.simulator_runtime_identifier, RUNTIME)

    def test_toolchain_parser_rejects_unknown_duplicate_and_shell_values(self) -> None:
        invalid_inputs = (
            TOOLCHAIN_TEXT + "EXTRA=value\n",
            TOOLCHAIN_TEXT + "XCODE_VERSION=26.5\n",
            TOOLCHAIN_TEXT.replace(
                f"XCODE_VERSION={EXPECTED_TOOLCHAIN.xcode_version}",
                "XCODE_VERSION=$(whoami)",
            ),
            TOOLCHAIN_TEXT.replace(RUNTIME, "com.apple.CoreSimulator.SimRuntime.latest"),
        )
        for text in invalid_inputs:
            with self.subTest(text=text), self.assertRaises(ci_github.ContractError):
                ci_github.parse_toolchain(text)

    def test_toolchain_identity_requires_exact_two_line_xcode_and_swiftlint(self) -> None:
        expected = EXPECTED_TOOLCHAIN
        exact_xcode = (
            f"Xcode {expected.xcode_version}\n"
            f"Build version {expected.xcode_build_version}"
        )
        ci_github.validate_toolchain(expected, exact_xcode, expected.swiftlint_version)

        invalid = (
            ("Xcode 26.5\nBuild version 17F113", expected.swiftlint_version),
            (f"Xcode {expected.xcode_version}\nBuild version WRONG", expected.swiftlint_version),
            (exact_xcode + "\nextra", expected.swiftlint_version),
            (exact_xcode, "0.64.0"),
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
                f"""
                #!/bin/sh
                [ "$DEVELOPER_DIR" = "/Applications/Xcode.app/Contents/Developer" ] || exit 9
                printf 'Xcode {EXPECTED_TOOLCHAIN.xcode_version}\nBuild version {EXPECTED_TOOLCHAIN.xcode_build_version}\n'
                """,
            )
            self.write_executable(
                bin_dir / "swiftlint",
                f"""
                #!/bin/sh
                printf '%s\n' '{EXPECTED_TOOLCHAIN.swiftlint_version}'
                """,
            )
            github_env = root / "github-env"
            github_output = root / "github-output"
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
                    "--github-output",
                    str(github_output),
                ],
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn(
                f"Xcode {EXPECTED_TOOLCHAIN.xcode_version} "
                f"({EXPECTED_TOOLCHAIN.xcode_build_version})",
                result.stdout,
            )
            self.assertIn(f"Simulator runtime: {RUNTIME}", result.stdout)
            self.assertEqual(
                github_env.read_text(encoding="utf-8"),
                "DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer\n"
                f"SIMULATOR_RUNTIME_IDENTIFIER={RUNTIME}\n",
            )
            outputs = dict(
                line.split("=", maxsplit=1)
                for line in github_output.read_text(encoding="utf-8").splitlines()
            )
            self.assertEqual(outputs["validated"], "true")
            self.assertEqual(
                outputs["developer_dir"],
                "/Applications/Xcode.app/Contents/Developer",
            )
            self.assertEqual(outputs["xcode_version"], EXPECTED_TOOLCHAIN.xcode_version)
            self.assertEqual(
                outputs["xcode_build_version"],
                EXPECTED_TOOLCHAIN.xcode_build_version,
            )
            self.assertEqual(
                outputs["swiftlint_version"],
                EXPECTED_TOOLCHAIN.swiftlint_version,
            )
            self.assertEqual(outputs["simulator_runtime"], RUNTIME)

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
                "#!/bin/sh\n"
                f"printf 'Xcode {EXPECTED_TOOLCHAIN.xcode_version}\\n"
                f"Build version {EXPECTED_TOOLCHAIN.xcode_build_version}\\n'\n",
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
                    "--github-output",
                    str(root / "github-output"),
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
    def test_exact_device_and_runtime_win_when_variants_and_other_runtime_precede(self) -> None:
        expected_runtime_devices = simulator_inventory()["devices"][RUNTIME]  # type: ignore[index]
        inventory = {
            "devices": {
                OTHER_RUNTIME: [
                    simulator_device(
                        "iPhone 17",
                        "22222222-3333-4444-5555-666666666666",
                        device_type=DEVICE_TYPE,
                    )
                ],
                RUNTIME: expected_runtime_devices,
            }
        }
        selected = ci_github.select_simulator(
            inventory,
            exact_name="iPhone 17",
            device_type_identifier=DEVICE_TYPE,
            runtime_identifier=RUNTIME,
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
        duplicate["devices"][RUNTIME].append(  # type: ignore[index]
            simulator_device(
                "iPhone 17",
                "22222222-3333-4444-5555-666666666666",
                device_type=DEVICE_TYPE,
            )
        )
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
                    runtime_identifier=RUNTIME,
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
                    runtime_identifier=RUNTIME,
                )

        with self.assertRaises(ci_github.ContractError):
            ci_github.select_simulator(
                simulator_inventory(),
                exact_name="iPhone 17",
                device_type_identifier=DEVICE_TYPE,
                runtime_identifier="iOS latest",
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
                    "--runtime",
                    RUNTIME,
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

            selected = ci_github.find_exact_xctestrun(
                root,
                "AllTests_*.xctestrun",
                confinement_root=root,
            )

            self.assertEqual(selected, expected.resolve())

    def test_zero_or_multiple_xctestruns_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with self.assertRaises(ci_github.ContractError):
                ci_github.find_exact_xctestrun(
                    root,
                    "AllTests_*.xctestrun",
                    confinement_root=root,
                )

            (root / "AllTests_one.xctestrun").touch()
            (root / "AllTests_two.xctestrun").touch()
            with self.assertRaises(ci_github.ContractError):
                ci_github.find_exact_xctestrun(
                    root,
                    "AllTests_*.xctestrun",
                    confinement_root=root,
                )

    def test_xctestrun_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            root = container / "products"
            root.mkdir()
            outside = container / "stale.xctestrun"
            outside.touch()
            (root / "AllTests_link.xctestrun").symlink_to(outside)

            with self.assertRaisesRegex(ci_github.ContractError, "symbolic link"):
                ci_github.find_exact_xctestrun(
                    root,
                    "AllTests_*.xctestrun",
                    confinement_root=root,
                )

    def test_xctestrun_root_with_symlinked_ancestor_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            real_derived_data = container / "real-derived-data"
            products = real_derived_data / "Build/Products"
            products.mkdir(parents=True)
            (products / "AllTests_fixture.xctestrun").touch()
            linked_derived_data = container / "DerivedData"
            linked_derived_data.symlink_to(real_derived_data, target_is_directory=True)

            with self.assertRaisesRegex(
                ci_github.ContractError,
                "contains a symbolic link",
            ):
                ci_github.find_exact_xctestrun(
                    linked_derived_data / "Build/Products",
                    "AllTests_*.xctestrun",
                    confinement_root=container,
                )


class DependencyContractTests(unittest.TestCase):
    def test_valid_dependency_tree_passes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)

            ci_github.validate_package_dependencies(root)

    def test_missing_or_empty_source_root_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            missing_root = root / "Packages/SnapDrillUI/Sources"
            for source in missing_root.iterdir():
                source.unlink()
            missing_root.rmdir()

            with self.assertRaisesRegex(ci_github.ContractError, "source root is missing"):
                ci_github.validate_package_dependencies(root)

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            empty_root = root / "SnapDrillShare"
            for source in empty_root.iterdir():
                source.unlink()

            with self.assertRaisesRegex(ci_github.ContractError, "has no Swift files"):
                ci_github.validate_package_dependencies(root)

    def test_reverse_imports_report_exact_locations(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            core = root / "Packages/SnapDrillCore/Sources/Core.swift"
            core.write_text("import struct SnapDrillData.ArchiveItem\n", encoding="utf-8")
            share = root / "SnapDrillShare/Share.swift"
            share.write_text("import SnapDrillCore\n", encoding="utf-8")

            with self.assertRaises(ci_github.ContractError) as context:
                ci_github.validate_package_dependencies(root)

            detail = str(context.exception)
            self.assertIn("Packages/SnapDrillCore/Sources/Core.swift:1", detail)
            self.assertIn("SnapDrillShare/Share.swift:1", detail)

    def test_annotated_multiline_and_access_level_imports_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            core = root / "Packages/SnapDrillCore/Sources/Core.swift"
            core.write_text(
                "@_implementationOnly /* boundary */ import SnapDrillData\n"
                "@_spi(Testing) public import SnapDrillFeatures\n",
                encoding="utf-8",
            )
            ui = root / "Packages/SnapDrillUI/Sources/UI.swift"
            ui.write_text(
                "@preconcurrency\nimport SnapDrillData\n",
                encoding="utf-8",
            )
            share = root / "SnapDrillShare/Share.swift"
            share.write_text("public import SnapDrillCore\n", encoding="utf-8")

            with self.assertRaises(ci_github.ContractError) as context:
                ci_github.validate_package_dependencies(root)

            detail = str(context.exception)
            self.assertIn("Packages/SnapDrillCore/Sources/Core.swift:1", detail)
            self.assertIn("Packages/SnapDrillCore/Sources/Core.swift:2", detail)
            self.assertIn("Packages/SnapDrillUI/Sources/UI.swift:2", detail)
            self.assertIn("SnapDrillShare/Share.swift:1", detail)

    def test_backtick_and_same_line_imports_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            core = root / "Packages/SnapDrillCore/Sources/Core.swift"
            core.write_text(
                "import Foundation; public import `SnapDrillData`\n",
                encoding="utf-8",
            )

            with self.assertRaises(ci_github.ContractError) as context:
                ci_github.validate_package_dependencies(root)

            self.assertIn("Packages/SnapDrillCore/Sources/Core.swift:1", str(context.exception))

    def test_import_text_inside_literals_and_nested_comments_is_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            core = root / "Packages/SnapDrillCore/Sources/Core.swift"
            core.write_text(
                textwrap.dedent(
                    '''
                    let ordinary = "import SnapDrillData"
                    let raw = #"import SnapDrillUI"#
                    let multiline = """
                    import SnapDrillFeatures
                    """
                    let regex = /import SnapDrillData/
                    let extendedRegex = #/
                    import SnapDrillFeatures
                    /#
                    // import SnapDrillUI
                    /* outer
                       /* import SnapDrillFeatures */
                       import SnapDrillData
                    */
                    import Foundation
                    '''
                ).lstrip(),
                encoding="utf-8",
            )

            ci_github.validate_package_dependencies(root)

    def test_compiler_parser_handles_adversarial_legal_swift(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            core = root / "Packages/SnapDrillCore/Sources/Core.swift"
            core.write_text(
                textwrap.dedent(
                    r'''
                    let string = #"foo \#"#; import SnapDrillData"#
                    let regex = #/foo\/#; import SnapDrillData/#
                    let closure = { (_: String) in /foo; import SnapDrillData/ }
                    let `你好` = 1
                    let astText = #"(import_decl harmless)"#
                    let astRegex = #/\(import_decl harmless\)/#
                    '''
                ).lstrip(),
                encoding="utf-8",
            )

            ci_github.validate_package_dependencies(root)

    def test_conditional_compilation_imports_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            core = root / "Packages/SnapDrillCore/Sources/Core.swift"
            core.write_text(
                textwrap.dedent(
                    '''
                    #if os(iOS)
                    import SnapDrillData
                    #elseif canImport(SnapDrillFeatures)
                    import SnapDrillFeatures
                    #else
                    import Foundation
                    #endif
                    '''
                ).lstrip(),
                encoding="utf-8",
            )

            with self.assertRaises(ci_github.ContractError) as context:
                ci_github.validate_package_dependencies(root)

            detail = str(context.exception)
            self.assertIn("Packages/SnapDrillCore/Sources/Core.swift:2", detail)
            self.assertIn("Packages/SnapDrillCore/Sources/Core.swift:4", detail)

    def test_unterminated_comment_or_string_fails_closed(self) -> None:
        cases = ("/* import SnapDrillData", '"import SnapDrillData')
        for source in cases:
            with self.subTest(source=source), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                make_dependency_tree(root)
                core = root / "Packages/SnapDrillCore/Sources/Core.swift"
                core.write_text(source, encoding="utf-8")

                with self.assertRaises(ci_github.ContractError):
                    ci_github.validate_package_dependencies(root)

    def test_symlinked_source_parent_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            make_dependency_tree(root)
            core_package = root / "Packages/SnapDrillCore"
            real_core_package = root / "RealCore"
            core_package.rename(real_core_package)
            core_package.symlink_to(real_core_package, target_is_directory=True)

            with self.assertRaisesRegex(ci_github.ContractError, "contains a symlink"):
                ci_github.validate_package_dependencies(root)


class XCResultContractTests(unittest.TestCase):
    def test_complete_xcresult_requires_parseable_passed_tests(self) -> None:
        summary = json.dumps({"result": "Passed", "totalTestCount": 42})
        with mock.patch.object(ci_github, "run_output", return_value=summary) as run:
            ci_github.validate_complete_xcresult(Path("/tmp/results.xcresult"))

        run.assert_called_once_with(
            [
                "xcrun",
                "xcresulttool",
                "get",
                "test-results",
                "summary",
                "--path",
                "/tmp/results.xcresult",
                "--format",
                "json",
            ]
        )

    def test_invalid_failed_or_empty_xcresult_fails_closed(self) -> None:
        invalid_summaries = (
            "not json",
            "[]",
            json.dumps({"result": "Failed", "totalTestCount": 1}),
            json.dumps({"result": "Passed", "totalTestCount": 0}),
        )
        for summary in invalid_summaries:
            with (
                self.subTest(summary=summary),
                mock.patch.object(ci_github, "run_output", return_value=summary),
                self.assertRaises(ci_github.ContractError),
            ):
                ci_github.validate_complete_xcresult(Path("/tmp/results.xcresult"))


class EvidenceContractTests(unittest.TestCase):
    SHA = "a" * 40
    NOW = 1_700_000_000.0

    def test_success_evidence_copies_artifacts_and_records_routine_scope(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = container / "evidence"
            log = container / "source.log"
            log.write_text("tests passed\n", encoding="utf-8")
            result = container / "SourceResults.xcresult"
            result.mkdir()
            (result / "Info.plist").write_text("fixture", encoding="utf-8")
            github_summary = container / "github-summary.md"

            xcresult_summary = json.dumps({"result": "Passed", "totalTestCount": 42})
            with mock.patch.object(
                ci_github,
                "run_output",
                return_value=xcresult_summary,
            ) as run:
                attempt = ci_github.finalize_evidence(
                    root=root,
                    workspace=workspace,
                    source_log=log,
                    source_result=result,
                    github_summary=github_summary,
                    toolchain=EXPECTED_TOOLCHAIN,
                    toolchain_validated=True,
                    trigger_sha=self.SHA,
                    sha=self.SHA,
                    run_id="123",
                    run_attempt="2",
                    job="build",
                    event_name="pull_request",
                    outcome="success",
                    exit_code="0",
                    developer_dir="/Applications/Xcode.app/Contents/Developer",
                    simulator_name="iPhone 17",
                    simulator_udid=EXACT_UDID,
                    simulator_runtime=RUNTIME,
                    simulator_device_type=DEVICE_TYPE,
                    simulator_destination=f"platform=iOS Simulator,id={EXACT_UDID}",
                    scheme="AllTests",
                    test_plan="AllTests",
                    test_configuration="CI",
                    default_timeout_seconds=120,
                    maximum_timeout_seconds=300,
                    retention_days=14,
                    max_total_bytes=20 * 1024 * 1024,
                    now_timestamp=self.NOW,
                )
            self.assertEqual(run.call_count, 2)

            self.assertEqual(attempt, root.resolve() / "run-123/build/attempt-2")
            self.assertEqual((attempt / "test.log").read_text(encoding="utf-8"), "tests passed\n")
            self.assertEqual(
                (attempt / "results.xcresult/Info.plist").read_text(encoding="utf-8"),
                "fixture",
            )
            summary = json.loads((attempt / "summary.json").read_text(encoding="utf-8"))
            self.assertEqual(summary["classification"], "routine-ci-only")
            self.assertEqual(summary["source"]["sha"], self.SHA)
            self.assertEqual(summary["run"]["outcome"], "success")
            self.assertEqual(summary["run"]["exit_code"], 0)
            self.assertEqual(summary["run"]["event"], "pull_request")
            self.assertTrue(summary["toolchain"]["validated"])
            self.assertEqual(
                summary["toolchain"]["developer_dir"],
                "/Applications/Xcode.app/Contents/Developer",
            )
            self.assertEqual(summary["simulator"]["udid"], EXACT_UDID)
            self.assertEqual(summary["simulator"]["device_type"], DEVICE_TYPE)
            self.assertEqual(
                summary["simulator"]["destination"],
                f"platform=iOS Simulator,id={EXACT_UDID}",
            )
            self.assertEqual(summary["test"]["scheme"], "AllTests")
            self.assertEqual(summary["test"]["plan"], "AllTests")
            self.assertEqual(summary["test"]["default_timeout_seconds"], 120)
            self.assertEqual(summary["test"]["maximum_timeout_seconds"], 300)
            self.assertEqual(summary["artifacts"]["log"], "test.log")
            self.assertEqual(summary["artifacts"]["result_bundle"], "results.xcresult")
            self.assertIsNone(summary["artifacts"]["omission_reason"])
            self.assertIn("release candidate conformance", " ".join(summary["limitations"]))
            self.assertEqual((root / "run-123").stat().st_mtime, self.NOW)
            rendered = github_summary.read_text(encoding="utf-8")
            self.assertIn(str(attempt), rendered)
            self.assertIn("routine CI only", rendered)
            self.assertIn("does not prove", rendered)

    def test_failure_evidence_preserves_log_and_partial_result(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            log = container / "failure.log"
            log.write_text("assertion failed\n", encoding="utf-8")
            result = container / "FailureResults.xcresult"
            result.mkdir()
            (result / "partial").write_text("diagnostic", encoding="utf-8")

            attempt = ci_github.finalize_evidence(
                root=container / "evidence",
                workspace=workspace,
                source_log=log,
                source_result=result,
                github_summary=container / "github-summary.md",
                toolchain=EXPECTED_TOOLCHAIN,
                toolchain_validated=True,
                trigger_sha=self.SHA,
                sha=self.SHA,
                run_id="124",
                run_attempt="1",
                job="ui-tests",
                event_name="workflow_dispatch",
                outcome="failure",
                exit_code="65",
                developer_dir="/Applications/Xcode.app/Contents/Developer",
                simulator_name="iPhone 17",
                simulator_udid=EXACT_UDID,
                simulator_runtime=RUNTIME,
                simulator_device_type=DEVICE_TYPE,
                simulator_destination=f"platform=iOS Simulator,id={EXACT_UDID}",
                scheme="SnapDrill",
                test_plan="UITests",
                test_configuration="CI",
                default_timeout_seconds=300,
                maximum_timeout_seconds=600,
                retention_days=14,
                max_total_bytes=20 * 1024 * 1024,
                now_timestamp=self.NOW,
            )

            summary = json.loads((attempt / "summary.json").read_text(encoding="utf-8"))
            self.assertEqual(summary["run"]["outcome"], "failure")
            self.assertEqual(summary["run"]["exit_code"], 65)
            self.assertTrue((attempt / "test.log").is_file())
            self.assertTrue((attempt / "results.xcresult/partial").is_file())

    def test_failure_without_xcresult_is_preserved_but_success_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            log = container / "test.log"
            log.write_text("xcodebuild failed before result finalization\n", encoding="utf-8")
            missing_result = container / "missing.xcresult"
            common = {
                "workspace": workspace,
                "source_log": log,
                "source_result": missing_result,
                "toolchain": EXPECTED_TOOLCHAIN,
                "toolchain_validated": True,
                "trigger_sha": self.SHA,
                "sha": self.SHA,
                "run_attempt": "1",
                "job": "build",
                "event_name": "pull_request",
                "developer_dir": "/Applications/Xcode.app/Contents/Developer",
                "simulator_name": "iPhone 17",
                "simulator_udid": EXACT_UDID,
                "simulator_runtime": RUNTIME,
                "simulator_device_type": DEVICE_TYPE,
                "simulator_destination": f"platform=iOS Simulator,id={EXACT_UDID}",
                "scheme": "AllTests",
                "test_plan": "AllTests",
                "test_configuration": "CI",
                "default_timeout_seconds": 120,
                "maximum_timeout_seconds": 300,
                "retention_days": 14,
                "max_total_bytes": 20 * 1024 * 1024,
                "now_timestamp": self.NOW,
            }

            failed_attempt = ci_github.finalize_evidence(
                root=container / "failure-evidence",
                github_summary=container / "failure-summary.md",
                run_id="125",
                outcome="failure",
                exit_code="65",
                **common,
            )
            failed_summary = json.loads(
                (failed_attempt / "summary.json").read_text(encoding="utf-8")
            )
            self.assertIsNone(failed_summary["artifacts"]["result_bundle"])
            self.assertTrue((failed_attempt / "test.log").is_file())

            with self.assertRaises(ci_github.ContractError):
                ci_github.finalize_evidence(
                    root=container / "success-evidence",
                    github_summary=container / "success-summary.md",
                    run_id="126",
                    outcome="success",
                    exit_code="0",
                    **common,
                )

    def test_skipped_evidence_does_not_claim_unvalidated_checkout_or_toolchain(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()

            attempt = ci_github.finalize_evidence(
                root=container / "evidence",
                workspace=workspace,
                source_log=container / "missing.log",
                source_result=container / "missing.xcresult",
                github_summary=container / "summary.md",
                toolchain=None,
                toolchain_validated=False,
                trigger_sha=self.SHA,
                sha="",
                run_id="127",
                run_attempt="1",
                job="build",
                event_name="pull_request",
                outcome="skipped",
                exit_code="",
                developer_dir="",
                simulator_name="",
                simulator_udid="",
                simulator_runtime="",
                simulator_device_type="",
                simulator_destination="",
                scheme="AllTests",
                test_plan="AllTests",
                test_configuration="CI",
                default_timeout_seconds=120,
                maximum_timeout_seconds=300,
                retention_days=14,
                max_total_bytes=20 * 1024 * 1024,
                now_timestamp=self.NOW,
            )

            summary = json.loads((attempt / "summary.json").read_text(encoding="utf-8"))
            self.assertEqual(summary["source"]["trigger_sha"], self.SHA)
            self.assertIsNone(summary["source"]["sha"])
            self.assertFalse(summary["source"]["checkout_validated"])
            self.assertFalse(summary["toolchain"]["validated"])
            self.assertIsNone(summary["toolchain"]["xcode_version"])
            self.assertIsNone(summary["toolchain"]["developer_dir"])

    def test_oversize_evidence_fails_after_preserving_minimal_summary(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = container / "evidence"
            log = container / "failure.log"
            log.write_bytes(b"x" * 128 * 1024)
            github_summary = container / "github-summary.md"

            with self.assertRaisesRegex(
                ci_github.ContractError,
                "minimal summary preserved",
            ):
                ci_github.finalize_evidence(
                    root=root,
                    workspace=workspace,
                    source_log=log,
                    source_result=container / "missing.xcresult",
                    github_summary=github_summary,
                    toolchain=EXPECTED_TOOLCHAIN,
                    toolchain_validated=True,
                    trigger_sha=self.SHA,
                    sha=self.SHA,
                    run_id="129",
                    run_attempt="1",
                    job="build",
                    event_name="push",
                    outcome="failure",
                    exit_code="65",
                    developer_dir="/Applications/Xcode.app/Contents/Developer",
                    simulator_name="iPhone 17",
                    simulator_udid=EXACT_UDID,
                    simulator_runtime=RUNTIME,
                    simulator_device_type=DEVICE_TYPE,
                    simulator_destination=f"platform=iOS Simulator,id={EXACT_UDID}",
                    scheme="AllTests",
                    test_plan="AllTests",
                    test_configuration="CI",
                    default_timeout_seconds=120,
                    maximum_timeout_seconds=300,
                    retention_days=14,
                    max_total_bytes=(
                        ci_github.EVIDENCE_METADATA_RESERVE_BYTES + 64 * 1024
                    ),
                    now_timestamp=self.NOW,
                )

            attempt = root.resolve() / "run-129/build/attempt-1"
            summary = json.loads((attempt / "summary.json").read_text(encoding="utf-8"))
            self.assertIsNone(summary["artifacts"]["log"])
            self.assertIsNone(summary["artifacts"]["result_bundle"])
            self.assertIn(
                "exceeds the total size limit",
                summary["artifacts"]["omission_reason"],
            )
            self.assertFalse((attempt / "test.log").exists())
            self.assertFalse((attempt / "results.xcresult").exists())
            self.assertIn("attachments: omitted", github_summary.read_text(encoding="utf-8"))

    def test_evidence_sources_reject_nested_xcresult_symlinks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = ci_github.prepare_evidence_root(container / "evidence", workspace)
            log = container / "test.log"
            log.write_text("failed\n", encoding="utf-8")
            result = container / "FailureResults.xcresult"
            result.mkdir()
            outside = container / "outside"
            outside.write_text("not durable\n", encoding="utf-8")
            (result / "external").symlink_to(outside)

            with self.assertRaisesRegex(ci_github.ContractError, "symbolic links"):
                ci_github._validate_evidence_sources(
                    root=root,
                    source_log=log,
                    source_result=result,
                    outcome="failure",
                )

    def test_finalize_reclaims_expired_runs_before_copying(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = ci_github.prepare_evidence_root(container / "evidence", workspace)
            old_run = root / "run-129"
            old_run.mkdir()
            (old_run / "old.bin").write_bytes(b"x" * 4_096)
            old_timestamp = self.NOW - 15 * 24 * 60 * 60
            os.utime(old_run, (old_timestamp, old_timestamp))
            original_copy = ci_github._copy_evidence_artifacts
            copy_observed = False

            def assert_cleanup_before_copy(**keywords: object) -> dict[str, str | None]:
                nonlocal copy_observed
                copy_observed = True
                self.assertFalse(old_run.exists())
                return original_copy(**keywords)

            with mock.patch.object(
                ci_github,
                "_copy_evidence_artifacts",
                side_effect=assert_cleanup_before_copy,
            ):
                ci_github.finalize_evidence(
                    root=root,
                    workspace=workspace,
                    source_log=container / "missing.log",
                    source_result=container / "missing.xcresult",
                    github_summary=container / "summary.md",
                    toolchain=None,
                    toolchain_validated=False,
                    trigger_sha=self.SHA,
                    sha="",
                    run_id="130",
                    run_attempt="1",
                    job="build",
                    event_name="pull_request",
                    outcome="skipped",
                    exit_code="",
                    developer_dir="",
                    simulator_name="",
                    simulator_udid="",
                    simulator_runtime="",
                    simulator_device_type="",
                    simulator_destination="",
                    scheme="AllTests",
                    test_plan="AllTests",
                    test_configuration="CI",
                    default_timeout_seconds=120,
                    maximum_timeout_seconds=300,
                    retention_days=14,
                    max_total_bytes=20 * 1024 * 1024,
                    now_timestamp=self.NOW,
                )

            self.assertTrue(copy_observed)

    def test_mismatched_checkout_sha_cannot_be_marked_validated(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            log = container / "test.log"
            log.write_text("tests passed\n", encoding="utf-8")
            result = container / "SourceResults.xcresult"
            result.mkdir()

            with self.assertRaisesRegex(
                ci_github.ContractError,
                "validated checkout SHA must match the trigger SHA",
            ):
                ci_github.finalize_evidence(
                    root=container / "evidence",
                    workspace=workspace,
                    source_log=log,
                    source_result=result,
                    github_summary=container / "summary.md",
                    toolchain=EXPECTED_TOOLCHAIN,
                    toolchain_validated=True,
                    trigger_sha=self.SHA,
                    sha="b" * 40,
                    run_id="128",
                    run_attempt="1",
                    job="build",
                    event_name="pull_request",
                    outcome="success",
                    exit_code="0",
                    developer_dir="/Applications/Xcode.app/Contents/Developer",
                    simulator_name="iPhone 17",
                    simulator_udid=EXACT_UDID,
                    simulator_runtime=RUNTIME,
                    simulator_device_type=DEVICE_TYPE,
                    simulator_destination=(
                        f"platform=iOS Simulator,id={EXACT_UDID}"
                    ),
                    scheme="AllTests",
                    test_plan="AllTests",
                    test_configuration="CI",
                    default_timeout_seconds=120,
                    maximum_timeout_seconds=300,
                    retention_days=14,
                    max_total_bytes=20 * 1024 * 1024,
                    now_timestamp=self.NOW,
                )

    def test_owned_root_rejects_checkout_unmarked_content_and_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()

            with self.assertRaises(ci_github.ContractError):
                ci_github.prepare_evidence_root(workspace / "evidence", workspace)
            self.assertFalse((workspace / "evidence").exists())

            nested_workspace_root = container / "nested-root"
            nested_workspace = nested_workspace_root / "run-99/workspace"
            nested_workspace.mkdir(parents=True)
            with self.assertRaises(ci_github.ContractError):
                ci_github.prepare_evidence_root(
                    nested_workspace_root,
                    nested_workspace,
                )
            self.assertTrue(nested_workspace.is_dir())

            occupied = container / "occupied"
            occupied.mkdir()
            (occupied / "unrelated").write_text("keep", encoding="utf-8")
            with self.assertRaises(ci_github.ContractError):
                ci_github.prepare_evidence_root(occupied, workspace)
            self.assertTrue((occupied / "unrelated").is_file())

            outside = container / "outside"
            outside.mkdir()
            linked = container / "linked-evidence"
            linked.symlink_to(outside, target_is_directory=True)
            with self.assertRaises(ci_github.ContractError):
                ci_github.prepare_evidence_root(linked, workspace)
            self.assertTrue(outside.is_dir())

            linked_parent = container / "linked-parent"
            linked_parent.symlink_to(outside, target_is_directory=True)
            with self.assertRaises(ci_github.ContractError):
                ci_github.prepare_evidence_root(linked_parent / "evidence", workspace)

            owned = ci_github.prepare_evidence_root(container / "owned", workspace)
            lock_target = container / "lock-target"
            lock_target.write_text("keep", encoding="utf-8")
            (owned / ci_github.EVIDENCE_LOCK_NAME).symlink_to(lock_target)
            with self.assertRaises(ci_github.ContractError):
                ci_github.cleanup_evidence(
                    owned,
                    current_run_name="run-1",
                    retention_days=14,
                    max_total_bytes=20 * 1024,
                    now_timestamp=self.NOW,
                )
            self.assertEqual(lock_target.read_text(encoding="utf-8"), "keep")

    def test_cleanup_removes_only_owned_old_runs_and_never_follows_symlinks(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = ci_github.prepare_evidence_root(container / "evidence", workspace)
            old_run = root / "run-1"
            old_run.mkdir()
            (old_run / "old.bin").write_bytes(b"x" * 200)
            current_run = root / "run-2"
            current_run.mkdir()
            (current_run / "current.bin").write_bytes(b"x" * 20)
            old_timestamp = self.NOW - 15 * 24 * 60 * 60
            os.utime(old_run, (old_timestamp, old_timestamp))

            removed = ci_github.cleanup_evidence(
                root,
                current_run_name="run-2",
                retention_days=14,
                max_total_bytes=20 * 1024,
                now_timestamp=self.NOW,
            )

            self.assertEqual(removed, ["run-1"])
            self.assertFalse(old_run.exists())
            self.assertTrue(current_run.is_dir())

            outside = container / "outside"
            outside.mkdir()
            (outside / "keep").write_text("keep", encoding="utf-8")
            (root / "run-3").symlink_to(outside, target_is_directory=True)
            with self.assertRaises(ci_github.ContractError):
                ci_github.cleanup_evidence(
                    root,
                    current_run_name="run-2",
                    retention_days=14,
                    max_total_bytes=20 * 1024,
                    now_timestamp=self.NOW,
                )
            self.assertEqual((outside / "keep").read_text(encoding="utf-8"), "keep")

    def test_cleanup_uses_allocated_size_oldest_first_and_preserves_current(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = ci_github.prepare_evidence_root(container / "evidence", workspace)
            oldest = root / "run-10"
            oldest.mkdir()
            (oldest / "old.bin").write_bytes(b"x" * 4_096)
            current = root / "run-11"
            current.mkdir()
            (current / "current.bin").write_bytes(b"x" * 4_096)
            os.utime(oldest, (self.NOW - 10, self.NOW - 10))
            os.utime(current, (self.NOW, self.NOW))
            current_bytes = ci_github.evidence_allocated_size(current)

            removed = ci_github.cleanup_evidence(
                root,
                current_run_name="run-11",
                retention_days=14,
                max_total_bytes=current_bytes,
                now_timestamp=self.NOW,
            )

            self.assertEqual(removed, ["run-10"])
            self.assertFalse(oldest.exists())
            self.assertTrue(current.is_dir())

            with self.assertRaises(ci_github.ContractError):
                ci_github.cleanup_evidence(
                    root,
                    current_run_name="run-11",
                    retention_days=14,
                    max_total_bytes=current_bytes - 1,
                    now_timestamp=self.NOW,
                )
            self.assertTrue(current.is_dir())

    def test_cleanup_reserves_capacity_for_incoming_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = ci_github.prepare_evidence_root(container / "evidence", workspace)
            old = root / "run-20"
            old.mkdir()
            (old / "old.bin").write_bytes(b"x" * 4_096)
            current = root / "run-21"
            current.mkdir()
            (current / "current.bin").write_bytes(b"x" * 4_096)
            os.utime(old, (self.NOW - 10, self.NOW - 10))
            total_bytes = (
                ci_github.evidence_allocated_size(old)
                + ci_github.evidence_allocated_size(current)
            )
            reserved_bytes = ci_github.evidence_allocated_size(old)

            removed = ci_github._cleanup_evidence_unlocked(
                root,
                protected_run_name="run-21",
                retention_days=14,
                max_total_bytes=total_bytes,
                reserved_bytes=reserved_bytes,
                now_timestamp=self.NOW,
            )

            self.assertEqual(removed, ["run-20"])
            self.assertFalse(old.exists())
            self.assertTrue(current.exists())

    def test_scheduled_prune_requires_no_current_run(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            container = Path(temporary)
            workspace = container / "workspace"
            workspace.mkdir()
            root = ci_github.prepare_evidence_root(container / "evidence", workspace)
            expired = root / "run-30"
            expired.mkdir()
            (expired / "expired.bin").write_bytes(b"x" * 4_096)
            recent = root / "run-31"
            recent.mkdir()
            (recent / "recent.bin").write_bytes(b"x" * 4_096)
            os.utime(expired, (self.NOW - 15 * 24 * 60 * 60,) * 2)
            os.utime(recent, (self.NOW,) * 2)
            recent_bytes = ci_github.evidence_allocated_size(recent)

            removed = ci_github.prune_evidence(
                root,
                retention_days=14,
                max_total_bytes=recent_bytes - 1,
                now_timestamp=self.NOW,
            )

            self.assertEqual(removed, ["run-30", "run-31"])
            self.assertFalse(expired.exists())
            self.assertFalse(recent.exists())


class WorkflowContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.workflow = WORKFLOW.read_text(encoding="utf-8")
        jobs = self.workflow.split("  build:\n", maxsplit=1)[1]
        self.build, ui_and_janitor = jobs.split("  ui-tests:\n", maxsplit=1)
        self.ui, self.janitor = ui_and_janitor.split(
            "  evidence-janitor:\n",
            maxsplit=1,
        )

    @staticmethod
    def step_body(job: str, name: str) -> str:
        marker = f"      - name: {name}\n"
        body = job.split(marker, maxsplit=1)[1]
        return body.split("\n      - name: ", maxsplit=1)[0]

    def test_checkout_is_pinned_read_only_and_drops_credentials(self) -> None:
        checkout = "actions/checkout@93cb6efe18208431cddfb8368fd83d5badbf9bfd"
        checkout_count = self.workflow.count("uses: actions/checkout@")
        self.assertEqual(checkout_count, 3)
        self.assertEqual(self.workflow.count(checkout), checkout_count)
        self.assertEqual(self.workflow.count("persist-credentials: false"), checkout_count)
        self.assertEqual(self.workflow.count("permissions:"), 1)
        self.assertIn("permissions:\n  contents: read", self.workflow)
        self.assertNotIn("contents: write", self.workflow)
        self.assertNotIn("persist-credentials: true", self.workflow)

    def test_fork_prs_are_kept_off_the_persistent_runner(self) -> None:
        self.assertIn("pull_request:", self.workflow)
        self.assertIn("github.event.pull_request.head.repo.full_name", self.build)
        self.assertIn("== github.repository", self.build)
        self.assertIn("github.event_name != 'schedule'", self.build)

    def test_daily_janitor_enforces_retention_without_running_tests(self) -> None:
        self.assertIn('cron: "17 3 * * *"', self.workflow)
        self.assertIn("if: github.event_name == 'schedule'", self.janitor)
        self.assertIn("python3 Scripts/ci_github.py evidence-janitor", self.janitor)
        self.assertIn("--retention-days 14", self.janitor)
        self.assertIn("--max-total-bytes 21474836480", self.janitor)
        self.assertNotIn("xcodebuild", self.janitor)

    def test_dependency_gate_uses_fail_closed_contract(self) -> None:
        dependency_step = self.step_body(self.build, "Check Package Dependencies")
        self.assertIn(
            'python3 Scripts/ci_github.py dependencies --root "$GITHUB_WORKSPACE"',
            dependency_step,
        )
        self.assertNotIn("grep ", dependency_step)
        self.assertNotIn("2>/dev/null", dependency_step)

    def test_build_job_enforces_release_test_override_boundary(self) -> None:
        docs_step = self.step_body(self.build, "Validate docs")

        self.assertIn(
            "python3 Scripts/validate_release_test_overrides.py --check",
            docs_step,
        )

    def test_both_jobs_bind_tools_checkout_and_simulator_through_contract(self) -> None:
        for job in (self.build, self.ui):
            with self.subTest(job=job[:30]):
                self.assertIn("python3 Scripts/ci_github.py toolchain", job)
                self.assertIn("--config Configs/Toolchain.env", job)
                self.assertIn("--github-output \"$GITHUB_OUTPUT\"", job)
                self.assertIn("id: checkout-identity", job)
                self.assertIn("id: toolchain", job)
                self.assertIn('"$CHECKOUT_SHA" != "$GITHUB_SHA"', job)
                self.assertIn("python3 Scripts/ci_github.py simulator", job)
                self.assertIn(
                    'xcrun simctl list devices available -j > "$INVENTORY"',
                    job,
                )
                self.assertIn('--runtime "$SIMULATOR_RUNTIME_IDENTIFIER"', job)
                self.assertIn("id: simulator", job)
                self.assertGreaterEqual(
                    job.count("DEVICE_ID: ${{ steps.simulator.outputs.udid }}"),
                    3,
                )
                self.assertIn('platform=iOS Simulator,id=$DEVICE_ID', job)

    def test_workflow_has_one_resolve_and_one_test_per_job_without_generic_retry(self) -> None:
        jobs = (
            (self.build, "Test without building"),
            (self.ui, "Test without building (UI)"),
        )
        for job, step_name in jobs:
            with self.subTest(job=step_name):
                self.assertEqual(job.count("-resolvePackageDependencies"), 1)
                self.assertEqual(job.count("test-without-building"), 1)
                self.assertIn("python3 Scripts/ci_github.py xctestrun", job)
                self.assertIn("--confinement-root \"$GITHUB_WORKSPACE\"", job)
                self.assertIn("steps.xctestrun.outputs.path", job)
                test_step = self.step_body(job, step_name)
                self.assertNotRegex(test_step, r"(?m)^\s*(?:for|while|until)\b")
                self.assertNotIn("&& break", test_step)
                self.assertNotIn("sleep ", test_step)

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
            "continue-on-error",
        )
        for text in forbidden:
            with self.subTest(text=text):
                self.assertNotIn(text, self.workflow)

    def test_both_jobs_finalize_durable_evidence_and_apply_ci_only_timeouts(self) -> None:
        jobs = (
            (
                self.build,
                "Test without building",
                "Finalize routine CI evidence",
                "120",
                "300",
            ),
            (
                self.ui,
                "Test without building (UI)",
                "Finalize routine UI evidence",
                "300",
                "600",
            ),
        )
        for job, test_name, finalizer_name, default_timeout, maximum_timeout in jobs:
            with self.subTest(job=test_name):
                test_step = self.step_body(job, test_name)
                self.assertIn('2>&1 | tee "$TEST_LOG_PATH"', test_step)
                self.assertIn('-resultBundlePath "$TEST_RESULT_PATH"', test_step)
                self.assertNotIn("$GITHUB_WORKSPACE/TestResults", test_step)
                self.assertNotIn("$GITHUB_WORKSPACE/UITestResults", test_step)
                self.assertIn("-test-timeouts-enabled YES", test_step)
                self.assertIn(
                    f"-default-test-execution-time-allowance {default_timeout}",
                    test_step,
                )
                self.assertIn(
                    f"-maximum-test-execution-time-allowance {maximum_timeout}",
                    test_step,
                )
                self.assertIn('"exit_code=$TEST_STATUS" >> "$GITHUB_OUTPUT"', test_step)
                self.assertIn('exit "$TEST_STATUS"', test_step)

                finalizer = self.step_body(job, finalizer_name)
                self.assertIn("if: always()", finalizer)
                self.assertIn("python3 Scripts/ci_github.py evidence", finalizer)
                self.assertIn('--root "$HOME/.snapdrill/ci-evidence"', finalizer)
                self.assertIn('--workspace "$GITHUB_WORKSPACE"', finalizer)
                self.assertIn('--github-summary "$GITHUB_STEP_SUMMARY"', finalizer)
                self.assertNotIn("--config Configs/Toolchain.env", finalizer)
                self.assertIn('--trigger-sha "$GITHUB_SHA"', finalizer)
                self.assertIn('--checkout-sha "$CHECKOUT_SHA"', finalizer)
                self.assertIn(
                    '--toolchain-validated "$TOOLCHAIN_VALIDATED"',
                    finalizer,
                )
                self.assertIn('--xcode-version "$XCODE_VERSION"', finalizer)
                self.assertIn('--event-name "$GITHUB_EVENT_NAME"', finalizer)
                self.assertIn('--developer-dir "$DEVELOPER_DIR"', finalizer)
                self.assertIn('--simulator-device-type "$DEVICE_TYPE"', finalizer)
                self.assertIn(
                    '--simulator-destination "$DEVICE_DESTINATION"',
                    finalizer,
                )
                self.assertIn(
                    f"--default-timeout-seconds {default_timeout}",
                    finalizer,
                )
                self.assertIn(
                    f"--maximum-timeout-seconds {maximum_timeout}",
                    finalizer,
                )
                self.assertIn("--retention-days 14", finalizer)
                self.assertIn("--max-total-bytes 21474836480", finalizer)

        self.assertEqual(self.workflow.count("if: always()"), 2)
        self.assertNotIn("actions/upload-artifact", self.workflow)


if __name__ == "__main__":
    unittest.main()
