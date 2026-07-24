#!/usr/bin/env python3
"""Validate source-owned Release platform configuration."""
from __future__ import annotations

import argparse
import json
import shlex
import subprocess
import sys
from collections.abc import Iterable, Mapping
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
PROJECT_PATH = Path("SnapDrill.xcodeproj/project.pbxproj")
TARGET_NAME = "SnapDrill"
RELEASE_XCODE_TARGET_NAMES = frozenset({"SnapDrill", "SnapDrillShare"})
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


def validate_effective_release_settings(
    payload: object,
    expected_targets: frozenset[str] = RELEASE_XCODE_TARGET_NAMES,
) -> list[str]:
    """Validate JSON emitted by xcodebuild -showBuildSettings -json."""

    if not isinstance(payload, list):
        return ["effective Release settings must be a target-entry list"]
    errors: list[str] = []
    entries: dict[str, Mapping[str, Any]] = {}
    for index, entry in enumerate(payload):
        if not isinstance(entry, Mapping):
            errors.append(f"effective Release entry {index} must be an object")
            continue
        target = entry.get("target")
        if not isinstance(target, str) or not target:
            errors.append(f"effective Release entry {index} target must be a string")
            continue
        if target in entries:
            errors.append(f"effective Release target {target} must be unique")
            continue
        entries[target] = entry

    actual_targets = set(entries)
    if actual_targets != expected_targets:
        errors.append(
            "effective Release targets must be "
            f"{sorted(expected_targets)!r}, found {sorted(actual_targets)!r}"
        )

    for target, entry in entries.items():
        settings = entry.get("buildSettings")
        if not isinstance(settings, Mapping):
            errors.append(f"effective Release {target} buildSettings must be an object")
            continue
        if settings.get("CONFIGURATION") != "Release":
            errors.append(
                f"effective Release {target} CONFIGURATION must be 'Release', "
                f"found {settings.get('CONFIGURATION')!r}"
            )
        for key in ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", "OTHER_SWIFT_FLAGS"):
            value = settings.get(key, "")
            if not isinstance(value, str):
                errors.append(f"effective Release {target} {key} must be a string")
                continue
            if "DEBUG" in value:
                errors.append(
                    f"effective Release {target} {key} must not define DEBUG, "
                    f"found {value!r}"
                )
            if key == "OTHER_SWIFT_FLAGS":
                try:
                    flags = shlex.split(value)
                except ValueError as error:
                    errors.append(
                        f"effective Release {target} {key} must be tokenizable: {error}"
                    )
                    continue
                response_files = [flag for flag in flags if flag.startswith("@")]
                if response_files:
                    errors.append(
                        f"effective Release {target} {key} must not use response files, "
                        f"found {response_files!r}"
                    )
    return errors


def validate_effective_package_settings(payload: object) -> list[str]:
    """Validate effective Swift settings emitted by swift package dump-package."""

    if not isinstance(payload, Mapping):
        return ["effective package manifest must be an object"]
    targets = payload.get("targets")
    if not isinstance(targets, list):
        return ["effective package targets must be a list"]

    errors: list[str] = []
    regular_target_count = 0
    seen_names: set[str] = set()
    for index, target in enumerate(targets):
        if not isinstance(target, Mapping):
            errors.append(f"effective package target {index} must be an object")
            continue
        if target.get("type") != "regular":
            continue
        regular_target_count += 1
        name = target.get("name")
        if not isinstance(name, str) or not name:
            errors.append(f"effective package regular target {index} needs a name")
            continue
        if name in seen_names:
            errors.append(f"effective package regular target {name} must be unique")
            continue
        seen_names.add(name)

        settings = target.get("settings", [])
        if settings is None:
            settings = []
        if not isinstance(settings, list):
            errors.append(f"effective package target {name} settings must be a list")
            continue
        for setting_index, setting in enumerate(settings):
            if not isinstance(setting, Mapping):
                errors.append(
                    f"effective package target {name} setting {setting_index} "
                    "must be an object"
                )
                continue
            if setting.get("tool") != "swift":
                continue
            condition = setting.get("condition")
            if condition is not None and not isinstance(condition, Mapping):
                errors.append(
                    f"effective package target {name} setting {setting_index} "
                    "condition must be an object"
                )
                continue
            configuration = condition.get("config") if condition else None
            if configuration not in (None, "debug", "release"):
                errors.append(
                    f"effective package target {name} setting {setting_index} "
                    f"has unknown configuration {configuration!r}"
                )
                continue
            if configuration == "debug":
                continue

            kind = setting.get("kind")
            if not isinstance(kind, Mapping):
                errors.append(
                    f"effective package target {name} setting {setting_index} "
                    "kind must be an object"
                )
                continue
            define = kind.get("define")
            if "define" in kind:
                if not isinstance(define, Mapping) or not isinstance(
                    define.get("_0"), str
                ):
                    errors.append(
                        f"effective package target {name} define must name a string"
                    )
                elif define.get("_0") == "DEBUG":
                    errors.append(
                        f"effective package target {name} must not define DEBUG "
                        "in Release"
                    )
            unsafe_flags = kind.get("unsafeFlags")
            if "unsafeFlags" in kind:
                if not isinstance(unsafe_flags, Mapping):
                    errors.append(
                        f"effective package target {name} unsafeFlags must be an object"
                    )
                    continue
                flags = unsafe_flags.get("_0")
                if not isinstance(flags, list) or not all(
                    isinstance(flag, str) for flag in flags
                ):
                    errors.append(
                        f"effective package target {name} unsafeFlags must be a "
                        "string list"
                    )
                else:
                    errors.append(
                        f"effective package target {name} must not use unsafeFlags "
                        "in Release"
                    )

    if regular_target_count == 0:
        errors.append("effective package manifest must contain a regular target")
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
    input_group = parser.add_mutually_exclusive_group()
    input_group.add_argument(
        "--effective-release-settings-stdin",
        action="store_true",
        help="validate xcodebuild -showBuildSettings -json from standard input",
    )
    input_group.add_argument(
        "--effective-package-settings-stdin",
        action="store_true",
        help="validate swift package dump-package JSON from standard input",
    )
    parser.add_argument(
        "--expected-release-target",
        action="append",
        choices=sorted(RELEASE_XCODE_TARGET_NAMES),
        help=(
            "expected target in effective Release settings; repeat for multiple targets "
            "(defaults to all production targets)"
        ),
    )
    arguments = parser.parse_args(argv)
    if (
        arguments.expected_release_target
        and not arguments.effective_release_settings_stdin
    ):
        parser.error(
            "--expected-release-target requires --effective-release-settings-stdin"
        )

    if (
        arguments.effective_release_settings_stdin
        or arguments.effective_package_settings_stdin
    ):
        try:
            payload = json.load(sys.stdin)
        except json.JSONDecodeError as error:
            errors = [f"effective settings are not valid JSON: {error}"]
        else:
            if arguments.effective_release_settings_stdin:
                expected_targets = frozenset(
                    arguments.expected_release_target
                    or RELEASE_XCODE_TARGET_NAMES
                )
                errors = validate_effective_release_settings(
                    payload,
                    expected_targets=expected_targets,
                )
            else:
                errors = validate_effective_package_settings(payload)
    else:
        errors = run_checks(project_path=arguments.project)
    if errors:
        for error in errors:
            print(f"[error] {error}", file=sys.stderr)
        return 1
    if arguments.effective_release_settings_stdin:
        print("[ok] effective Release Swift conditions passed")
    elif arguments.effective_package_settings_stdin:
        print("[ok] effective package Release Swift conditions passed")
    else:
        print("[ok] Release platform configuration passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
