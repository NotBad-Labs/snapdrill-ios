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
