#!/usr/bin/env python3
"""Regression tests for Release platform configuration checks."""
from __future__ import annotations

import copy
import importlib.util
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "Scripts" / "validate_release_configuration.py"


def load_validator():
    spec = importlib.util.spec_from_file_location("validate_release_configuration", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load Scripts/validate_release_configuration.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


validator = load_validator()

EXPECTED_SETTINGS = {
    "TARGETED_DEVICE_FAMILY": "1",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
}


def valid_effective_release_settings() -> list[dict[str, object]]:
    return [
        {
            "target": target,
            "buildSettings": {
                "CONFIGURATION": "Release",
                "OTHER_SWIFT_FLAGS": "$(inherited) -default-isolation MainActor",
            },
        }
        for target in sorted(validator.RELEASE_XCODE_TARGET_NAMES)
    ]


def valid_effective_package_settings() -> dict[str, object]:
    return {
        "targets": [
            {
                "name": "Library",
                "type": "regular",
                "settings": [
                    {
                        "tool": "swift",
                        "condition": {"config": "debug", "platformNames": []},
                        "kind": {"define": {"_0": "DEBUG"}},
                    },
                    {
                        "tool": "swift",
                        "condition": {"config": "debug", "platformNames": []},
                        "kind": {"unsafeFlags": {"_0": ["-DDEBUG"]}},
                    },
                ],
            },
            {"name": "LibraryTests", "type": "test", "settings": []},
        ]
    }


def valid_project() -> dict[str, object]:
    return {
        "rootObject": "PROJECT",
        "objects": {
            "PROJECT": {
                "isa": "PBXProject",
                "targets": ["APP", "SHARE"],
            },
            "APP": {
                "isa": "PBXNativeTarget",
                "name": "SnapDrill",
                "productType": "com.apple.product-type.application",
                "buildConfigurationList": "APP_CONFIGS",
            },
            "SHARE": {
                "isa": "PBXNativeTarget",
                "name": "SnapDrillShare",
                "productType": "com.apple.product-type.app-extension",
                "buildConfigurationList": "SHARE_CONFIGS",
            },
            "APP_CONFIGS": {
                "isa": "XCConfigurationList",
                "buildConfigurations": ["APP_DEBUG", "APP_RELEASE"],
            },
            "APP_DEBUG": {
                "isa": "XCBuildConfiguration",
                "name": "Debug",
                "buildSettings": copy.deepcopy(EXPECTED_SETTINGS),
            },
            "APP_RELEASE": {
                "isa": "XCBuildConfiguration",
                "name": "Release",
                "buildSettings": copy.deepcopy(EXPECTED_SETTINGS),
            },
        }
    }


class ValidateReleaseConfigurationTests(unittest.TestCase):
    def test_current_repository_configuration_passes(self) -> None:
        self.assertEqual(validator.run_checks(), [])

    def test_valid_minimal_project_passes(self) -> None:
        self.assertEqual(validator.validate_project(valid_project()), [])

    def test_validator_contract_matches_independent_oracle(self) -> None:
        self.assertEqual(validator.REQUIRED_SETTINGS, EXPECTED_SETTINGS)

    def test_missing_or_duplicate_app_target_fails_closed(self) -> None:
        missing = valid_project()
        missing["objects"]["PROJECT"]["targets"].remove("APP")
        duplicate = valid_project()
        duplicate["objects"]["APP_DUPLICATE"] = copy.deepcopy(duplicate["objects"]["APP"])
        duplicate["objects"]["PROJECT"]["targets"].append("APP_DUPLICATE")

        for project in (missing, duplicate):
            with self.subTest(project=project):
                errors = validator.validate_project(project)
                self.assertTrue(any("exactly one project PBXNativeTarget" in error for error in errors))

    def test_orphan_or_non_application_target_cannot_satisfy_gate(self) -> None:
        orphan = valid_project()
        orphan["objects"]["PROJECT"]["targets"].remove("APP")

        wrong_product_type = valid_project()
        wrong_product_type["objects"]["APP"]["productType"] = (
            "com.apple.product-type.bundle.unit-test"
        )

        self.assertTrue(
            any(
                "exactly one project PBXNativeTarget" in error
                for error in validator.validate_project(orphan)
            )
        )
        self.assertTrue(
            any(
                "productType=com.apple.product-type.application" in error
                for error in validator.validate_project(wrong_product_type)
            )
        )

    def test_unrelated_aggregate_target_is_allowed(self) -> None:
        project = valid_project()
        project["objects"]["AGGREGATE"] = {
            "isa": "PBXAggregateTarget",
            "name": "Tooling",
        }
        project["objects"]["PROJECT"]["targets"].append("AGGREGATE")

        self.assertEqual(validator.validate_project(project), [])

    def test_missing_or_duplicate_configuration_fails_closed(self) -> None:
        missing = valid_project()
        missing["objects"]["APP_CONFIGS"]["buildConfigurations"] = ["APP_DEBUG"]
        duplicate = valid_project()
        duplicate["objects"]["APP_RELEASE_DUPLICATE"] = copy.deepcopy(
            duplicate["objects"]["APP_RELEASE"]
        )
        duplicate["objects"]["APP_CONFIGS"]["buildConfigurations"].append(
            "APP_RELEASE_DUPLICATE"
        )

        for project in (missing, duplicate):
            with self.subTest(project=project):
                errors = validator.validate_project(project)
                self.assertTrue(any("Release configuration" in error for error in errors))

    def test_unvalidated_configuration_fails_closed(self) -> None:
        project = valid_project()
        project["objects"]["APP_PROFILE"] = {
            "isa": "XCBuildConfiguration",
            "name": "Profile",
            "buildSettings": {},
        }
        project["objects"]["APP_CONFIGS"]["buildConfigurations"].append("APP_PROFILE")

        errors = validator.validate_project(project)

        self.assertTrue(any("unvalidated configurations: Profile" in error for error in errors))

    def test_each_required_setting_is_enforced_in_each_configuration(self) -> None:
        for configuration_id in ("APP_DEBUG", "APP_RELEASE"):
            for key, expected in EXPECTED_SETTINGS.items():
                for mutation in (None, "YES" if expected == "NO" else "1,2"):
                    with self.subTest(
                        configuration=configuration_id,
                        key=key,
                        mutation=mutation,
                    ):
                        project = valid_project()
                        settings = project["objects"][configuration_id]["buildSettings"]
                        if mutation is None:
                            settings.pop(key)
                        else:
                            settings[key] = mutation

                        errors = validator.validate_project(project)

                        self.assertTrue(
                            any(
                                configuration_id.removeprefix("APP_").title() in error
                                and key in error
                                for error in errors
                            )
                        )

    def test_landscape_orientation_fails_in_each_configuration(self) -> None:
        key = "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone"
        value = (
            "UIInterfaceOrientationPortrait "
            "UIInterfaceOrientationLandscapeLeft "
            "UIInterfaceOrientationLandscapeRight"
        )

        for configuration_id in ("APP_DEBUG", "APP_RELEASE"):
            with self.subTest(configuration=configuration_id):
                project = valid_project()
                project["objects"][configuration_id]["buildSettings"][key] = value

                errors = validator.validate_project(project)

                self.assertTrue(
                    any(
                        configuration_id.removeprefix("APP_").title() in error
                        and key in error
                        and value in error
                        for error in errors
                    )
                )

    def test_effective_release_swift_conditions_reject_debug_defines(self) -> None:
        valid = valid_effective_release_settings()
        self.assertEqual(validator.validate_effective_release_settings(valid), [])

        for target_index in range(len(valid)):
            for key, value in (
                ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "DEBUG $(inherited)"),
                ("OTHER_SWIFT_FLAGS", "$(inherited) -DDEBUG"),
                ("OTHER_SWIFT_FLAGS", "$(inherited) -D DEBUG"),
            ):
                with self.subTest(target_index=target_index, key=key, value=value):
                    payload = copy.deepcopy(valid)
                    payload[target_index]["buildSettings"][key] = value
                    errors = validator.validate_effective_release_settings(payload)
                    self.assertTrue(
                        any(key in error and "DEBUG" in error for error in errors)
                    )

    def test_effective_release_swift_conditions_fail_closed_on_wrong_shape(self) -> None:
        cases = (
            None,
            [],
            [valid_effective_release_settings()[0]],
            [
                {
                    "target": "Other",
                    "buildSettings": {"CONFIGURATION": "Release"},
                }
            ],
            [
                {
                    "target": "SnapDrill",
                    "buildSettings": {"CONFIGURATION": "Debug"},
                },
                valid_effective_release_settings()[1],
            ],
            [
                {"target": "SnapDrill", "buildSettings": []},
                valid_effective_release_settings()[1],
            ],
        )
        for payload in cases:
            with self.subTest(payload=payload):
                self.assertNotEqual(
                    validator.validate_effective_release_settings(payload), []
                )

    def test_effective_package_release_conditions_reject_debug_defines(self) -> None:
        valid = valid_effective_package_settings()
        self.assertEqual(validator.validate_effective_package_settings(valid), [])

        unsafe_flag_cases = (
            ["-DDEBUG"],
            ["-D", "DEBUG"],
            ["$(inherited)", "-DDEBUG=1"],
            ["-Xfrontend", "-D", "-Xfrontend", "DEBUG"],
            ["@compiler-flags.rsp"],
            ["-warnings-as-errors"],
        )
        for flags in unsafe_flag_cases:
            with self.subTest(flags=flags):
                payload = valid_effective_package_settings()
                payload["targets"][0]["settings"] = [
                    {
                        "tool": "swift",
                        "kind": {"unsafeFlags": {"_0": flags}},
                    }
                ]
                errors = validator.validate_effective_package_settings(payload)
                self.assertTrue(any("unsafeFlags" in error for error in errors))

        for condition in (None, {"config": "release", "platformNames": []}):
            with self.subTest(condition=condition):
                setting = {
                    "tool": "swift",
                    "kind": {"define": {"_0": "DEBUG"}},
                }
                if condition is not None:
                    setting["condition"] = condition
                payload = valid_effective_package_settings()
                payload["targets"][0]["settings"] = [setting]
                errors = validator.validate_effective_package_settings(payload)
                self.assertTrue(any("must not define DEBUG" in error for error in errors))

    def test_effective_package_settings_fail_closed_on_wrong_shape(self) -> None:
        cases = (
            None,
            {},
            {"targets": []},
            {"targets": [None]},
            {"targets": [{"name": "Library", "type": "regular", "settings": {}}]},
            {
                "targets": [
                    {
                        "name": "Library",
                        "type": "regular",
                        "settings": [
                            {
                                "tool": "swift",
                                "condition": {"config": "profile"},
                                "kind": {"define": {"_0": "DEBUG"}},
                            }
                        ],
                    }
                ]
            },
        )
        for payload in cases:
            with self.subTest(payload=payload):
                self.assertNotEqual(
                    validator.validate_effective_package_settings(payload), []
                )

    def test_malformed_object_graph_fails_closed(self) -> None:
        cases = (
            None,
            {},
            {"objects": []},
            {
                "rootObject": "PROJECT",
                "objects": {
                    "PROJECT": {
                        "isa": "PBXProject",
                        "targets": ["APP"],
                    },
                    "APP": {
                        "isa": "PBXNativeTarget",
                        "name": "SnapDrill",
                        "productType": "com.apple.product-type.application",
                        "buildConfigurationList": 42,
                    }
                }
            },
        )
        for project in cases:
            with self.subTest(project=project):
                self.assertNotEqual(validator.validate_project(project), [])


if __name__ == "__main__":
    unittest.main()
