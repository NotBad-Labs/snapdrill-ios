#!/usr/bin/env python3
"""Fail-closed contracts used by the GitHub Actions source-validation jobs."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping, Sequence

TOOLCHAIN_KEYS = {
    "XCODE_VERSION",
    "XCODE_BUILD_VERSION",
    "SWIFTLINT_VERSION",
}
UUID_PATTERN = re.compile(
    r"[0-9A-Fa-f]{8}-(?:[0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}"
)
RUNTIME_PREFIX = "com.apple.CoreSimulator.SimRuntime."


class ContractError(ValueError):
    """Raised when CI input cannot prove the required contract."""


@dataclass(frozen=True)
class Toolchain:
    xcode_version: str
    xcode_build_version: str
    swiftlint_version: str


@dataclass(frozen=True)
class Simulator:
    name: str
    udid: str
    runtime_identifier: str
    device_type_identifier: str
    state: str

    @property
    def destination(self) -> str:
        return f"platform=iOS Simulator,id={self.udid}"


def parse_toolchain(text: str) -> Toolchain:
    values: dict[str, str] = {}
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            raise ContractError(f"invalid toolchain line {line_number}: expected KEY=VALUE")
        key, value = line.split("=", maxsplit=1)
        if key not in TOOLCHAIN_KEYS:
            raise ContractError(f"unknown toolchain key on line {line_number}: {key}")
        if key in values:
            raise ContractError(f"duplicate toolchain key on line {line_number}: {key}")
        if not value or value != value.strip():
            raise ContractError(f"invalid value for {key} on line {line_number}")
        values[key] = value

    missing = sorted(TOOLCHAIN_KEYS - values.keys())
    if missing:
        raise ContractError(f"missing toolchain keys: {', '.join(missing)}")

    if re.fullmatch(r"\d+\.\d+(?:\.\d+)?", values["XCODE_VERSION"]) is None:
        raise ContractError("XCODE_VERSION must be a numeric dotted version")
    if re.fullmatch(r"[A-Za-z0-9]+", values["XCODE_BUILD_VERSION"]) is None:
        raise ContractError("XCODE_BUILD_VERSION must be alphanumeric")
    if re.fullmatch(r"\d+\.\d+\.\d+", values["SWIFTLINT_VERSION"]) is None:
        raise ContractError("SWIFTLINT_VERSION must be a semantic version")

    return Toolchain(
        xcode_version=values["XCODE_VERSION"],
        xcode_build_version=values["XCODE_BUILD_VERSION"],
        swiftlint_version=values["SWIFTLINT_VERSION"],
    )


def validate_toolchain(
    expected: Toolchain,
    xcode_output: str,
    swiftlint_output: str,
) -> None:
    expected_xcode = (
        f"Xcode {expected.xcode_version}\n"
        f"Build version {expected.xcode_build_version}"
    )
    if xcode_output != expected_xcode:
        raise ContractError(
            "Xcode identity mismatch; "
            f"expected {expected_xcode!r}, actual {xcode_output!r}"
        )
    if swiftlint_output != expected.swiftlint_version:
        raise ContractError(
            "SwiftLint identity mismatch; "
            f"expected {expected.swiftlint_version!r}, actual {swiftlint_output!r}"
        )


def run_output(command: Sequence[str], *, environment: Mapping[str, str] | None = None) -> str:
    try:
        completed = subprocess.run(
            command,
            env=dict(environment) if environment is not None else None,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except OSError as error:
        raise ContractError(f"cannot execute {command[0]}: {error}") from error
    if completed.returncode != 0:
        detail = completed.stderr.rstrip("\n") or completed.stdout.rstrip("\n")
        raise ContractError(
            f"{' '.join(command)} failed with status {completed.returncode}: {detail}"
        )
    return completed.stdout.rstrip("\n")


def validate_installed_toolchain(config_path: Path) -> tuple[Toolchain, str]:
    expected = parse_toolchain(config_path.read_text(encoding="utf-8"))
    developer_dir = run_output(["xcode-select", "-p"])
    if not developer_dir or "\n" in developer_dir:
        raise ContractError("xcode-select must return exactly one developer directory")

    command_environment = os.environ.copy()
    command_environment["DEVELOPER_DIR"] = developer_dir
    xcode_output = run_output(["xcodebuild", "-version"], environment=command_environment)
    swiftlint_output = run_output(["swiftlint", "version"], environment=command_environment)
    validate_toolchain(expected, xcode_output, swiftlint_output)
    return expected, developer_dir


def select_simulator(
    inventory: object,
    *,
    exact_name: str,
    device_type_identifier: str,
) -> Simulator:
    if not isinstance(inventory, dict) or not isinstance(inventory.get("devices"), dict):
        raise ContractError("simctl inventory must contain a devices object")

    matches: list[Simulator] = []
    for runtime_identifier, devices in inventory["devices"].items():
        if not isinstance(runtime_identifier, str) or not isinstance(devices, list):
            raise ContractError("simctl runtime entries must map identifiers to device arrays")
        for device in devices:
            if not isinstance(device, dict):
                raise ContractError("simctl device entries must be objects")
            if (
                device.get("name") != exact_name
                or device.get("deviceTypeIdentifier") != device_type_identifier
                or device.get("isAvailable") is not True
            ):
                continue

            udid = device.get("udid")
            state = device.get("state")
            if not isinstance(udid, str) or UUID_PATTERN.fullmatch(udid) is None:
                raise ContractError(f"exact simulator {exact_name!r} has an invalid UDID")
            if not runtime_identifier.startswith(RUNTIME_PREFIX):
                raise ContractError(f"exact simulator {exact_name!r} has an invalid runtime")
            if not isinstance(state, str) or not state or "\n" in state:
                raise ContractError(f"exact simulator {exact_name!r} has an invalid state")
            matches.append(
                Simulator(
                    name=exact_name,
                    udid=udid,
                    runtime_identifier=runtime_identifier,
                    device_type_identifier=device_type_identifier,
                    state=state,
                )
            )

    if len(matches) != 1:
        raise ContractError(
            f"expected exactly one available {exact_name!r} ({device_type_identifier}), "
            f"found {len(matches)}"
        )
    return matches[0]


def find_exact_xctestrun(root: Path, pattern: str) -> Path:
    if not root.is_dir():
        raise ContractError(f"xctestrun root does not exist: {root}")
    if not pattern or "/" in pattern or pattern in {".", ".."}:
        raise ContractError(f"invalid xctestrun filename pattern: {pattern!r}")
    matches = sorted(path.resolve() for path in root.rglob(pattern) if path.is_file())
    if len(matches) != 1:
        rendered = "\n".join(f"  {path}" for path in matches)
        suffix = f"\n{rendered}" if rendered else ""
        raise ContractError(
            f"expected exactly one {pattern!r} under {root}, found {len(matches)}{suffix}"
        )
    return matches[0]


def append_github_values(path: Path, values: Mapping[str, str]) -> None:
    lines: list[str] = []
    for key, value in values.items():
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key) is None:
            raise ContractError(f"invalid GitHub output key: {key!r}")
        if "\n" in value or "\r" in value:
            raise ContractError(f"GitHub output value for {key} must be one line")
        lines.append(f"{key}={value}\n")
    with path.open("a", encoding="utf-8") as handle:
        handle.writelines(lines)


def command_toolchain(arguments: argparse.Namespace) -> None:
    expected, developer_dir = validate_installed_toolchain(arguments.config)
    append_github_values(arguments.github_env, {"DEVELOPER_DIR": developer_dir})
    print(f"Xcode {expected.xcode_version} ({expected.xcode_build_version})")
    print(f"SwiftLint {expected.swiftlint_version}")
    print(f"Developer directory: {developer_dir}")


def command_simulator(arguments: argparse.Namespace) -> None:
    with arguments.inventory.open(encoding="utf-8") as handle:
        inventory = json.load(handle)
    simulator = select_simulator(
        inventory,
        exact_name=arguments.name,
        device_type_identifier=arguments.device_type,
    )
    append_github_values(
        arguments.github_output,
        {
            "name": simulator.name,
            "udid": simulator.udid,
            "runtime": simulator.runtime_identifier,
            "device_type": simulator.device_type_identifier,
            "state": simulator.state,
            "destination": simulator.destination,
        },
    )
    print(
        f"Simulator: {simulator.name} ({simulator.device_type_identifier}), "
        f"runtime={simulator.runtime_identifier}, udid={simulator.udid}, "
        f"state={simulator.state}"
    )


def command_xctestrun(arguments: argparse.Namespace) -> None:
    path = find_exact_xctestrun(arguments.root, arguments.pattern)
    append_github_values(arguments.github_output, {"path": str(path)})
    print(f"xctestrun: {path}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    toolchain = subparsers.add_parser("toolchain")
    toolchain.add_argument("--config", type=Path, required=True)
    toolchain.add_argument("--github-env", type=Path, required=True)
    toolchain.set_defaults(handler=command_toolchain)

    simulator = subparsers.add_parser("simulator")
    simulator.add_argument("--inventory", type=Path, required=True)
    simulator.add_argument("--name", required=True)
    simulator.add_argument("--device-type", required=True)
    simulator.add_argument("--github-output", type=Path, required=True)
    simulator.set_defaults(handler=command_simulator)

    xctestrun = subparsers.add_parser("xctestrun")
    xctestrun.add_argument("--root", type=Path, required=True)
    xctestrun.add_argument("--pattern", required=True)
    xctestrun.add_argument("--github-output", type=Path, required=True)
    xctestrun.set_defaults(handler=command_xctestrun)
    return parser


def main() -> int:
    arguments = build_parser().parse_args()
    try:
        arguments.handler(arguments)
    except (ContractError, OSError, json.JSONDecodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
