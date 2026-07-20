#!/usr/bin/env python3
"""Validate source-owned Release platform configuration."""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
PROJECT_PATH = Path("SnapDrill.xcodeproj/project.pbxproj")
TARGET_NAME = "SnapDrill"
APPLICATION_PRODUCT_TYPE = "com.apple.product-type.application"
PROJECT_TARGET_TYPES = {"PBXNativeTarget", "PBXAggregateTarget", "PBXLegacyTarget"}
CONFIGURATION_NAMES = ("Debug", "Release")
REQUIRED_SETTINGS = {
    "TARGETED_DEVICE_FAMILY": "1",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "UIInterfaceOrientationPortrait",
}


def validate_project(project: object) -> list[str]:
    if not isinstance(project, Mapping):
        return ["project root must be an object"]

    objects = project.get("objects")
    if not isinstance(objects, Mapping):
        return ["project objects must be an object"]

    root_object_id = project.get("rootObject")
    if not isinstance(root_object_id, str):
        return ["project rootObject must be a string object ID"]

    root_object = objects.get(root_object_id)
    if not isinstance(root_object, Mapping) or root_object.get("isa") != "PBXProject":
        return ["project rootObject does not resolve to PBXProject"]

    target_ids = root_object.get("targets")
    if not isinstance(target_ids, list) or not all(
        isinstance(target_id, str) for target_id in target_ids
    ):
        return ["PBXProject targets must be a list of string object IDs"]
    if len(target_ids) != len(set(target_ids)):
        return ["PBXProject targets must not contain duplicate object IDs"]

    project_targets: list[Mapping[str, Any]] = []
    for target_id in target_ids:
        target = objects.get(target_id)
        if not isinstance(target, Mapping) or target.get("isa") not in PROJECT_TARGET_TYPES:
            return [f"PBXProject target {target_id} does not resolve to a known target type"]
        if target.get("isa") == "PBXNativeTarget":
            project_targets.append(target)

    matching_targets = [
        target for target in project_targets if target.get("name") == TARGET_NAME
    ]
    if len(matching_targets) != 1:
        return [
            f"expected exactly one project PBXNativeTarget named {TARGET_NAME}, "
            f"found {len(matching_targets)}"
        ]

    target = matching_targets[0]
    if target.get("productType") != APPLICATION_PRODUCT_TYPE:
        return [
            f"{TARGET_NAME} must have productType={APPLICATION_PRODUCT_TYPE}, "
            f"found {target.get('productType')!r}"
        ]

    configuration_list_id = target.get("buildConfigurationList")
    if not isinstance(configuration_list_id, str):
        return [f"{TARGET_NAME} buildConfigurationList must be a string object ID"]

    configuration_list = objects.get(configuration_list_id)
    if not isinstance(configuration_list, Mapping) or configuration_list.get("isa") != "XCConfigurationList":
        return [f"{TARGET_NAME} buildConfigurationList does not resolve to XCConfigurationList"]

    configuration_ids = configuration_list.get("buildConfigurations")
    if not isinstance(configuration_ids, list) or not all(
        isinstance(configuration_id, str) for configuration_id in configuration_ids
    ):
        return [f"{TARGET_NAME} buildConfigurations must be a list of string object IDs"]

    configurations: dict[str, list[Mapping[str, Any]]] = {}
    errors: list[str] = []
    for configuration_id in configuration_ids:
        configuration = objects.get(configuration_id)
        if not isinstance(configuration, Mapping) or configuration.get("isa") != "XCBuildConfiguration":
            errors.append(
                f"{TARGET_NAME} configuration {configuration_id} does not resolve to XCBuildConfiguration"
            )
            continue
        name = configuration.get("name")
        if not isinstance(name, str):
            errors.append(f"{TARGET_NAME} configuration {configuration_id} has a non-string name")
            continue
        configurations.setdefault(name, []).append(configuration)

    unexpected_names = sorted(set(configurations) - set(CONFIGURATION_NAMES))
    if unexpected_names:
        errors.append(
            f"{TARGET_NAME} has unvalidated configurations: {', '.join(unexpected_names)}"
        )

    for name in CONFIGURATION_NAMES:
        matches = configurations.get(name, [])
        if len(matches) != 1:
            errors.append(
                f"expected exactly one {TARGET_NAME} {name} configuration, found {len(matches)}"
            )
            continue

        settings = matches[0].get("buildSettings")
        if not isinstance(settings, Mapping):
            errors.append(f"{TARGET_NAME} {name} buildSettings must be an object")
            continue
        for key, expected in REQUIRED_SETTINGS.items():
            actual = settings.get(key)
            if actual != expected:
                errors.append(
                    f"{TARGET_NAME} {name} requires {key}={expected}, found {actual!r}"
                )

    return errors


def load_project(path: Path) -> object:
    result = subprocess.run(
        ["/usr/bin/plutil", "-convert", "json", "-o", "-", str(path)],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or f"plutil exited {result.returncode}"
        raise ValueError(f"unable to parse {path}: {detail}")
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise ValueError(f"plutil returned invalid JSON for {path}: {error}") from error


def run_checks(
    repo_root: Path = REPO_ROOT,
    project_path: Path = PROJECT_PATH,
) -> list[str]:
    path = project_path if project_path.is_absolute() else repo_root / project_path
    if not path.is_file():
        return [f"missing Xcode project source: {path}"]
    try:
        project = load_project(path)
    except (OSError, ValueError) as error:
        return [str(error)]
    return validate_project(project)


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate without modifying files")
    parser.add_argument("--project", type=Path, default=PROJECT_PATH)
    arguments = parser.parse_args(argv)

    errors = run_checks(project_path=arguments.project)
    if errors:
        for error in errors:
            print(f"[error] {error}", file=sys.stderr)
        return 1
    print("[ok] Release platform configuration passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
