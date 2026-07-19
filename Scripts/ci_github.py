#!/usr/bin/env python3
"""Fail-closed contracts used by the GitHub Actions source-validation jobs."""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import time
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator, Mapping, Sequence

TOOLCHAIN_KEYS = {
    "XCODE_VERSION",
    "XCODE_BUILD_VERSION",
    "SWIFTLINT_VERSION",
    "SIMULATOR_RUNTIME_IDENTIFIER",
}
UUID_PATTERN = re.compile(
    r"[0-9A-Fa-f]{8}-(?:[0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}"
)
RUNTIME_PREFIX = "com.apple.CoreSimulator.SimRuntime."
IOS_RUNTIME_PATTERN = re.compile(
    rf"{re.escape(RUNTIME_PREFIX)}iOS-\d+(?:-\d+)+"
)
EVIDENCE_MARKER_NAME = ".snapdrill-ci-evidence-root"
EVIDENCE_MARKER_CONTENT = "SnapDrill routine CI evidence root v1\n"
EVIDENCE_LOCK_NAME = ".snapdrill-ci-evidence.lock"
EVIDENCE_METADATA_RESERVE_BYTES = 1024 * 1024
RUN_ID_PATTERN = re.compile(r"[1-9]\d*")
JOB_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}")
SHA_PATTERN = re.compile(r"[0-9A-Fa-f]{40}")
EVIDENCE_OUTCOMES = {"success", "failure", "cancelled", "skipped"}


class ContractError(ValueError):
    """Raised when CI input cannot prove the required contract."""


@dataclass(frozen=True)
class Toolchain:
    xcode_version: str
    xcode_build_version: str
    swiftlint_version: str
    simulator_runtime_identifier: str


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
    if IOS_RUNTIME_PATTERN.fullmatch(values["SIMULATOR_RUNTIME_IDENTIFIER"]) is None:
        raise ContractError(
            "SIMULATOR_RUNTIME_IDENTIFIER must be a full iOS runtime identifier"
        )

    return Toolchain(
        xcode_version=values["XCODE_VERSION"],
        xcode_build_version=values["XCODE_BUILD_VERSION"],
        swiftlint_version=values["SWIFTLINT_VERSION"],
        simulator_runtime_identifier=values["SIMULATOR_RUNTIME_IDENTIFIER"],
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
    runtime_identifier: str,
) -> Simulator:
    if not isinstance(inventory, dict) or not isinstance(inventory.get("devices"), dict):
        raise ContractError("simctl inventory must contain a devices object")
    if IOS_RUNTIME_PATTERN.fullmatch(runtime_identifier) is None:
        raise ContractError("expected simulator runtime must be a full iOS identifier")

    matches: list[Simulator] = []
    for candidate_runtime, devices in inventory["devices"].items():
        if not isinstance(candidate_runtime, str) or not isinstance(devices, list):
            raise ContractError("simctl runtime entries must map identifiers to device arrays")
        if candidate_runtime != runtime_identifier:
            continue
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
            if not isinstance(state, str) or not state or "\n" in state:
                raise ContractError(f"exact simulator {exact_name!r} has an invalid state")
            matches.append(
                Simulator(
                    name=exact_name,
                    udid=udid,
                    runtime_identifier=candidate_runtime,
                    device_type_identifier=device_type_identifier,
                    state=state,
                )
            )

    if len(matches) != 1:
        raise ContractError(
            f"expected exactly one available {exact_name!r} ({device_type_identifier}) "
            f"on {runtime_identifier}, "
            f"found {len(matches)}"
        )
    return matches[0]


def find_exact_xctestrun(
    root: Path,
    pattern: str,
    *,
    confinement_root: Path,
) -> Path:
    if confinement_root.is_symlink() or not confinement_root.is_dir():
        raise ContractError(
            f"xctestrun confinement root does not exist: {confinement_root}"
        )
    if root.is_symlink() or not root.is_dir():
        raise ContractError(f"xctestrun root does not exist: {root}")
    if not pattern or "/" in pattern or pattern in {".", ".."}:
        raise ContractError(f"invalid xctestrun filename pattern: {pattern!r}")

    lexical_confinement_root = confinement_root.absolute()
    lexical_root = root.absolute()
    if not _is_within(lexical_root, lexical_confinement_root):
        raise ContractError("xctestrun root must stay within its confinement root")
    current = lexical_confinement_root
    for component in lexical_root.relative_to(lexical_confinement_root).parts:
        current /= component
        if current.is_symlink():
            raise ContractError(f"xctestrun root contains a symbolic link: {current}")

    resolved_confinement_root = confinement_root.resolve(strict=True)
    resolved_root = root.resolve(strict=True)
    if not _is_within(resolved_root, resolved_confinement_root):
        raise ContractError("xctestrun root escaped its confinement root")
    matches: list[Path] = []
    for path in resolved_root.rglob(pattern):
        if path.is_symlink():
            raise ContractError(f"xctestrun must not be a symbolic link: {path}")
        if not path.is_file():
            continue
        resolved_path = path.resolve(strict=True)
        if resolved_path != path.absolute():
            raise ContractError(f"xctestrun path contains a symbolic link: {path}")
        if not _is_within(resolved_path, resolved_root):
            raise ContractError(f"xctestrun must stay within its build root: {path}")
        matches.append(resolved_path)
    matches.sort()
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


def _is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def _require_one_line(value: str, label: str, *, allow_empty: bool = False) -> str:
    if (not value and not allow_empty) or "\n" in value or "\r" in value:
        raise ContractError(f"{label} must be a valid one-line value")
    return value


def swift_imports(paths: Sequence[Path]) -> list[tuple[Path, str, int, str]]:
    if not paths:
        raise ContractError("expected at least one Swift source path")
    helper = Path(__file__).with_name("swift_dependency_imports.swift")
    if helper.is_symlink() or not helper.is_file():
        raise ContractError(f"Swift dependency helper is missing: {helper}")

    swiftc_path = Path(run_output(["/usr/bin/xcrun", "--find", "swiftc"]))
    if not swiftc_path.is_absolute() or not swiftc_path.is_file():
        raise ContractError(f"xcrun returned an invalid swiftc path: {swiftc_path}")
    resolved_swiftc = swiftc_path.resolve(strict=True)
    toolchain_root = resolved_swiftc.parent.parent.parent
    developer_dir = toolchain_root.parent.parent
    if (
        toolchain_root.suffix != ".xctoolchain"
        or toolchain_root.parent.name != "Toolchains"
        or developer_dir.name != "Developer"
    ):
        raise ContractError(f"swiftc is not inside an Xcode toolchain: {resolved_swiftc}")
    host_libraries = resolved_swiftc.parent.parent / "lib/swift/host"
    required_host_artifacts = (
        host_libraries / "SwiftParser.swiftmodule",
        host_libraries / "SwiftSyntax.swiftmodule",
        host_libraries / "libSwiftParser.dylib",
        host_libraries / "libSwiftSyntax.dylib",
    )
    if any(not artifact.exists() for artifact in required_host_artifacts):
        raise ContractError(f"Swift parser host libraries are missing: {host_libraries}")
    sdk_path = Path(
        run_output(["/usr/bin/xcrun", "--sdk", "macosx", "--show-sdk-path"])
    )
    if (
        not sdk_path.is_absolute()
        or not sdk_path.is_dir()
        or not _is_within(sdk_path.resolve(strict=True), developer_dir)
    ):
        raise ContractError(f"xcrun returned an invalid macOS SDK path: {sdk_path}")

    path_lookup = {str(path): path for path in paths}
    output = run_output(
        [
            "/usr/bin/xcrun",
            "swift",
            "-I",
            str(host_libraries),
            "-L",
            str(host_libraries),
            "-lSwiftSyntax",
            "-lSwiftParser",
            "-sdk",
            str(sdk_path),
            str(helper),
            *path_lookup,
        ]
    )
    imports: list[tuple[Path, str, int, str]] = []
    for output_line in output.splitlines():
        try:
            record = json.loads(output_line)
        except json.JSONDecodeError as error:
            raise ContractError("Swift dependency helper emitted invalid JSON") from error
        if not isinstance(record, dict) or set(record) != {
            "path",
            "line",
            "module",
            "declaration",
        }:
            raise ContractError("Swift dependency helper emitted an invalid record")
        path_value = record["path"]
        line_value = record["line"]
        module_value = record["module"]
        declaration_value = record["declaration"]
        if (
            not isinstance(path_value, str)
            or path_value not in path_lookup
            or not isinstance(line_value, int)
            or isinstance(line_value, bool)
            or line_value < 1
            or not isinstance(module_value, str)
            or not module_value
            or "\n" in module_value
            or "\r" in module_value
            or not isinstance(declaration_value, str)
            or not declaration_value
        ):
            raise ContractError("Swift dependency helper emitted an invalid record")
        imports.append(
            (
                path_lookup[path_value],
                module_value,
                line_value,
                " ".join(declaration_value.split()),
            )
        )
    return imports


def validate_package_dependencies(repository: Path) -> None:
    if repository.is_symlink() or not repository.is_dir():
        raise ContractError(f"repository root must be a real directory: {repository}")
    resolved_repository = repository.resolve(strict=True)
    rules = (
        (
            Path("Packages/SnapDrillCore/Sources"),
            set(),
            "Core must not import downstream packages",
        ),
        (
            Path("Packages/SnapDrillData/Sources"),
            {"SnapDrillCore"},
            "Data must only import Core",
        ),
        (
            Path("Packages/SnapDrillUI/Sources"),
            {"SnapDrillCore"},
            "UI must only import Core",
        ),
        (
            Path("SnapDrillShare"),
            set(),
            "Share Extension must not import SnapDrill packages",
        ),
    )
    violations: list[str] = []
    for relative_root, allowed_snapdrill_modules, message in rules:
        source_root = resolved_repository / relative_root
        if source_root.is_symlink() or not source_root.is_dir():
            raise ContractError(f"dependency source root is missing: {relative_root}")
        if source_root.resolve(strict=True) != source_root:
            raise ContractError(f"dependency source root contains a symlink: {relative_root}")

        swift_files: list[Path] = []
        for path in source_root.rglob("*"):
            if path.is_symlink():
                raise ContractError(f"dependency source tree contains a symlink: {path}")
            if path.is_file() and path.suffix == ".swift":
                swift_files.append(path)
        if not swift_files:
            raise ContractError(f"dependency source root has no Swift files: {relative_root}")

        for path, module, line_number, declaration in swift_imports(
            sorted(swift_files)
        ):
            is_forbidden = (
                module.startswith("SnapDrill")
                and module not in allowed_snapdrill_modules
            )
            if is_forbidden:
                location = path.relative_to(resolved_repository)
                violations.append(
                    f"{location}:{line_number}: {message}: {declaration}"
                )

    if violations:
        raise ContractError(
            "dependency direction violations:\n" + "\n".join(violations)
        )


def prepare_evidence_root(root: Path, workspace: Path) -> Path:
    if not root.is_absolute():
        raise ContractError("evidence root must be an absolute path")
    if root.is_symlink():
        raise ContractError("evidence root must not be a symbolic link")
    if root.parent.is_symlink():
        raise ContractError("evidence root parent must not be a symbolic link")
    if not workspace.is_dir():
        raise ContractError(f"workspace does not exist: {workspace}")

    resolved_workspace = workspace.resolve(strict=True)
    prospective_root = root.resolve(strict=False)
    if _is_within(prospective_root, resolved_workspace) or _is_within(
        resolved_workspace,
        prospective_root,
    ):
        raise ContractError("evidence root and GITHUB_WORKSPACE must not overlap")
    if root.exists() and not root.is_dir():
        raise ContractError("evidence root must be a directory")
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    resolved_root = root.resolve(strict=True)
    if _is_within(resolved_root, resolved_workspace) or _is_within(
        resolved_workspace,
        resolved_root,
    ):
        raise ContractError("evidence root and GITHUB_WORKSPACE must not overlap")

    marker = resolved_root / EVIDENCE_MARKER_NAME
    if marker.exists():
        if marker.is_symlink() or not marker.is_file():
            raise ContractError("evidence root marker must be a regular file")
        if marker.read_text(encoding="utf-8") != EVIDENCE_MARKER_CONTENT:
            raise ContractError("evidence root marker does not match")
    else:
        if any(resolved_root.iterdir()):
            raise ContractError("refusing to claim a non-empty unmarked evidence root")
        marker.write_text(EVIDENCE_MARKER_CONTENT, encoding="utf-8")
        marker.chmod(0o600)
    resolved_root.chmod(0o700)
    return resolved_root


@contextmanager
def _locked_evidence_root(root: Path) -> Iterator[None]:
    lock_path = root / EVIDENCE_LOCK_NAME
    if lock_path.is_symlink():
        raise ContractError("evidence root lock must not be a symbolic link")
    flags = os.O_RDWR | os.O_CREAT
    if hasattr(os, "O_CLOEXEC"):
        flags |= os.O_CLOEXEC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    try:
        descriptor = os.open(lock_path, flags, 0o600)
    except OSError as error:
        raise ContractError(f"cannot open evidence root lock: {error}") from error
    try:
        lock_status = os.fstat(descriptor)
        if not stat.S_ISREG(lock_status.st_mode):
            raise ContractError("evidence root lock must be a regular file")
        os.fchmod(descriptor, 0o600)
        fcntl.flock(descriptor, fcntl.LOCK_EX)
        yield
    finally:
        try:
            fcntl.flock(descriptor, fcntl.LOCK_UN)
        finally:
            os.close(descriptor)


def _managed_run_directories(root: Path) -> list[Path]:
    marker = root / EVIDENCE_MARKER_NAME
    if (
        marker.is_symlink()
        or not marker.is_file()
        or marker.read_text(encoding="utf-8") != EVIDENCE_MARKER_CONTENT
    ):
        raise ContractError("cannot clean an unowned evidence root")

    runs: list[Path] = []
    for entry in root.iterdir():
        if entry.name == EVIDENCE_MARKER_NAME:
            continue
        if entry.name == EVIDENCE_LOCK_NAME:
            if entry.is_symlink() or not entry.is_file():
                raise ContractError("evidence root lock must be a regular file")
            continue
        if re.fullmatch(r"run-[1-9]\d*", entry.name) is None:
            raise ContractError(f"unexpected entry in evidence root: {entry.name}")
        if entry.is_symlink() or not entry.is_dir():
            raise ContractError(f"managed run must be a real directory: {entry.name}")
        runs.append(entry)
    return runs


def evidence_allocated_size(path: Path) -> int:
    if path.is_symlink():
        return path.lstat().st_blocks * 512
    if not path.exists():
        raise ContractError(f"evidence path does not exist: {path}")

    total = 0
    pending = [path]
    while pending:
        current = pending.pop()
        current_status = current.lstat()
        blocks = getattr(current_status, "st_blocks", None)
        total += current_status.st_size if blocks is None else blocks * 512
        if not stat.S_ISDIR(current_status.st_mode):
            continue
        with os.scandir(current) as entries:
            for entry in entries:
                child = Path(entry.path)
                child_status = entry.stat(follow_symlinks=False)
                if stat.S_ISDIR(child_status.st_mode):
                    pending.append(child)
                else:
                    child_blocks = getattr(child_status, "st_blocks", None)
                    total += (
                        child_status.st_size
                        if child_blocks is None
                        else child_blocks * 512
                    )
    return total


def _require_self_contained_tree(path: Path, label: str) -> None:
    pending = [path]
    while pending:
        current = pending.pop()
        current_status = current.lstat()
        if stat.S_ISLNK(current_status.st_mode):
            raise ContractError(f"{label} must not contain symbolic links: {current}")
        if stat.S_ISDIR(current_status.st_mode):
            with os.scandir(current) as entries:
                pending.extend(Path(entry.path) for entry in entries)
        elif not stat.S_ISREG(current_status.st_mode):
            raise ContractError(f"{label} must contain only files and directories: {current}")


def validate_complete_xcresult(path: Path) -> None:
    output = run_output(
        [
            "xcrun",
            "xcresulttool",
            "get",
            "test-results",
            "summary",
            "--path",
            str(path),
            "--format",
            "json",
        ]
    )
    try:
        summary = json.loads(output)
    except json.JSONDecodeError as error:
        raise ContractError("xcresulttool returned invalid JSON") from error
    if not isinstance(summary, dict):
        raise ContractError("xcresult summary must be a JSON object")
    if summary.get("result") != "Passed":
        raise ContractError("successful test evidence requires a passed xcresult")
    total_test_count = summary.get("totalTestCount")
    if (
        not isinstance(total_test_count, int)
        or isinstance(total_test_count, bool)
        or total_test_count <= 0
    ):
        raise ContractError("successful xcresult must contain at least one test")


def _validate_evidence_sources(
    *,
    root: Path,
    source_log: Path,
    source_result: Path,
    outcome: str,
) -> int:
    allocated_bytes = 0
    if source_log.exists():
        if source_log.is_symlink() or not source_log.is_file():
            raise ContractError("test log must be a regular file")
        if _is_within(source_log.resolve(strict=True), root):
            raise ContractError("test log source must be outside the durable evidence root")
        if outcome in {"success", "failure"} and source_log.stat().st_size == 0:
            raise ContractError(f"{outcome} test step produced an empty log")
        allocated_bytes += evidence_allocated_size(source_log)
    elif outcome in {"success", "failure"}:
        raise ContractError(f"{outcome} test step did not produce a log")

    if source_result.exists():
        if source_result.is_symlink() or not source_result.is_dir():
            raise ContractError("xcresult source must be a real directory")
        if _is_within(source_result.resolve(strict=True), root):
            raise ContractError("xcresult source must be outside the durable evidence root")
        _require_self_contained_tree(source_result, "xcresult source")
        if outcome == "success":
            validate_complete_xcresult(source_result)
        allocated_bytes += evidence_allocated_size(source_result)
    elif outcome == "success":
        raise ContractError("successful test step did not produce an xcresult")
    return allocated_bytes


def _cleanup_evidence_unlocked(
    root: Path,
    *,
    protected_run_name: str | None,
    retention_days: int,
    max_total_bytes: int,
    reserved_bytes: int = 0,
    now_timestamp: float | None = None,
) -> list[str]:
    if (
        protected_run_name is not None
        and re.fullmatch(r"run-[1-9]\d*", protected_run_name) is None
    ):
        raise ContractError("protected run name must use run-<positive integer>")
    if retention_days <= 0:
        raise ContractError("retention days must be positive")
    if max_total_bytes <= 0:
        raise ContractError("maximum evidence bytes must be positive")
    if reserved_bytes < 0 or reserved_bytes >= max_total_bytes:
        raise ContractError("reserved evidence bytes must be below the total size limit")

    now = time.time() if now_timestamp is None else now_timestamp
    runs = _managed_run_directories(root)
    if protected_run_name is not None and not any(
        run.name == protected_run_name for run in runs
    ):
        raise ContractError(f"protected evidence run is missing: {protected_run_name}")

    removed: list[str] = []
    cutoff = now - retention_days * 24 * 60 * 60
    for run in sorted(runs, key=lambda candidate: (candidate.stat().st_mtime, candidate.name)):
        if run.name != protected_run_name and run.stat().st_mtime < cutoff:
            shutil.rmtree(run)
            removed.append(run.name)

    remaining = _managed_run_directories(root)
    total_bytes = sum(evidence_allocated_size(run) for run in remaining)
    available_bytes = max_total_bytes - reserved_bytes
    for run in sorted(
        remaining,
        key=lambda candidate: (candidate.stat().st_mtime, candidate.name),
    ):
        if total_bytes <= available_bytes:
            break
        if run.name == protected_run_name:
            continue
        run_bytes = evidence_allocated_size(run)
        shutil.rmtree(run)
        total_bytes -= run_bytes
        removed.append(run.name)

    if total_bytes > available_bytes:
        raise ContractError(
            "protected evidence plus reserved incoming bytes exceeds the size limit; "
            "protected material was preserved and the job must fail"
        )
    return removed


def cleanup_evidence(
    root: Path,
    *,
    current_run_name: str,
    retention_days: int,
    max_total_bytes: int,
    now_timestamp: float | None = None,
) -> list[str]:
    with _locked_evidence_root(root):
        return _cleanup_evidence_unlocked(
            root,
            protected_run_name=current_run_name,
            retention_days=retention_days,
            max_total_bytes=max_total_bytes,
            now_timestamp=now_timestamp,
        )


def prune_evidence(
    root: Path,
    *,
    retention_days: int,
    max_total_bytes: int,
    now_timestamp: float | None = None,
) -> list[str]:
    with _locked_evidence_root(root):
        return _cleanup_evidence_unlocked(
            root,
            protected_run_name=None,
            retention_days=retention_days,
            max_total_bytes=max_total_bytes,
            now_timestamp=now_timestamp,
        )


def _create_attempt_directory(
    root: Path,
    *,
    run_id: str,
    job: str,
    run_attempt: str,
) -> tuple[Path, str]:
    if RUN_ID_PATTERN.fullmatch(run_id) is None:
        raise ContractError("run id must be a positive integer")
    if RUN_ID_PATTERN.fullmatch(run_attempt) is None:
        raise ContractError("run attempt must be a positive integer")
    if JOB_PATTERN.fullmatch(job) is None:
        raise ContractError("job must contain only letters, digits, underscores, or hyphens")

    run_name = f"run-{run_id}"
    run_directory = root / run_name
    job_directory = run_directory / job
    attempt_directory = job_directory / f"attempt-{run_attempt}"
    for directory in (run_directory, job_directory):
        if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
            raise ContractError(f"evidence path must be a real directory: {directory}")
        directory.mkdir(exist_ok=True, mode=0o700)
    if attempt_directory.exists() or attempt_directory.is_symlink():
        raise ContractError(f"refusing to overwrite existing evidence: {attempt_directory}")
    attempt_directory.mkdir(mode=0o700)
    return attempt_directory, run_name


def _copy_evidence_artifacts(
    *,
    attempt_directory: Path,
    source_log: Path,
    source_result: Path,
    outcome: str,
) -> dict[str, str | None]:
    log_target = attempt_directory / "test.log"
    result_target = attempt_directory / "results.xcresult"
    log_name: str | None = None
    result_name: str | None = None

    if source_log.exists():
        shutil.copy2(source_log, log_target)
        log_name = log_target.name

    if source_result.exists():
        shutil.copytree(source_result, result_target, symlinks=True)
        _require_self_contained_tree(result_target, "copied xcresult")
        if outcome == "success":
            validate_complete_xcresult(result_target)
        result_name = result_target.name

    return {"log": log_name, "result_bundle": result_name}


def _discard_partial_evidence_artifacts(attempt_directory: Path) -> None:
    log_target = attempt_directory / "test.log"
    result_target = attempt_directory / "results.xcresult"
    if log_target.exists() and not log_target.is_symlink():
        log_target.unlink()
    if result_target.exists() and not result_target.is_symlink():
        shutil.rmtree(result_target)


def finalize_evidence(
    *,
    root: Path,
    workspace: Path,
    source_log: Path,
    source_result: Path,
    github_summary: Path,
    toolchain: Toolchain | None,
    toolchain_validated: bool,
    trigger_sha: str,
    sha: str,
    run_id: str,
    run_attempt: str,
    job: str,
    event_name: str,
    outcome: str,
    exit_code: str,
    developer_dir: str,
    simulator_name: str,
    simulator_udid: str,
    simulator_runtime: str,
    simulator_device_type: str,
    simulator_destination: str,
    scheme: str,
    test_plan: str,
    test_configuration: str,
    default_timeout_seconds: int,
    maximum_timeout_seconds: int,
    retention_days: int,
    max_total_bytes: int,
    now_timestamp: float | None = None,
) -> Path:
    if SHA_PATTERN.fullmatch(trigger_sha) is None:
        raise ContractError("trigger SHA must contain exactly 40 hexadecimal characters")
    if outcome not in EVIDENCE_OUTCOMES:
        raise ContractError(f"unsupported test outcome: {outcome!r}")
    if sha and SHA_PATTERN.fullmatch(sha) is None:
        raise ContractError("checkout SHA must contain exactly 40 hexadecimal characters")
    if sha and sha != trigger_sha:
        raise ContractError("validated checkout SHA must match the trigger SHA")
    if outcome in {"success", "failure"} and not sha:
        raise ContractError(f"{outcome} evidence requires a validated checkout SHA")
    if toolchain_validated != (toolchain is not None):
        raise ContractError("toolchain proof fields must agree with validation state")
    if toolchain_validated:
        _require_one_line(developer_dir, "developer directory")
    elif developer_dir:
        raise ContractError("unvalidated toolchain must not claim a developer directory")
    if outcome in {"success", "failure"} and not toolchain_validated:
        raise ContractError(f"{outcome} evidence requires a validated toolchain")
    _require_one_line(event_name, "event name")
    _require_one_line(scheme, "scheme")
    _require_one_line(test_plan, "test plan")
    _require_one_line(test_configuration, "test configuration")
    if default_timeout_seconds <= 0:
        raise ContractError("default test timeout must be positive")
    if maximum_timeout_seconds < default_timeout_seconds:
        raise ContractError("maximum test timeout must not be below the default")

    parsed_exit_code: int | None = None
    if exit_code:
        try:
            parsed_exit_code = int(exit_code)
        except ValueError as error:
            raise ContractError("test exit code must be an integer") from error
        if parsed_exit_code < 0:
            raise ContractError("test exit code must not be negative")
    if outcome == "success" and parsed_exit_code != 0:
        raise ContractError("successful test outcome requires exit code 0")
    if outcome == "failure" and (parsed_exit_code is None or parsed_exit_code == 0):
        raise ContractError("failed test outcome requires a nonzero exit code")

    if outcome in {"success", "failure"}:
        _require_one_line(simulator_name, "simulator name")
        if UUID_PATTERN.fullmatch(simulator_udid) is None:
            raise ContractError("test evidence requires a valid simulator UDID")
        if IOS_RUNTIME_PATTERN.fullmatch(simulator_runtime) is None:
            raise ContractError("test evidence requires a full iOS runtime identifier")
        _require_one_line(simulator_device_type, "simulator device type")
        expected_destination = f"platform=iOS Simulator,id={simulator_udid}"
        if simulator_destination != expected_destination:
            raise ContractError(
                "simulator destination must identify the validated simulator UDID"
            )
        if (
            toolchain is not None
            and toolchain.simulator_runtime_identifier != simulator_runtime
        ):
            raise ContractError("simulator runtime must match the validated toolchain")
    else:
        _require_one_line(developer_dir, "developer directory", allow_empty=True)
        _require_one_line(simulator_name, "simulator name", allow_empty=True)
        _require_one_line(simulator_udid, "simulator UDID", allow_empty=True)
        _require_one_line(simulator_runtime, "simulator runtime", allow_empty=True)
        _require_one_line(
            simulator_device_type,
            "simulator device type",
            allow_empty=True,
        )
        _require_one_line(
            simulator_destination,
            "simulator destination",
            allow_empty=True,
        )

    prepared_root = prepare_evidence_root(root, workspace)
    finalization_error: str | None = None
    with _locked_evidence_root(prepared_root):
        incoming_bytes = _validate_evidence_sources(
            root=prepared_root,
            source_log=source_log,
            source_result=source_result,
            outcome=outcome,
        )
        attempt_directory, run_name = _create_attempt_directory(
            prepared_root,
            run_id=run_id,
            job=job,
            run_attempt=run_attempt,
        )
        timestamp = time.time() if now_timestamp is None else now_timestamp
        removed: list[str] = []
        artifacts: dict[str, str | None] = {
            "log": None,
            "result_bundle": None,
        }
        try:
            removed.extend(
                _cleanup_evidence_unlocked(
                    prepared_root,
                    protected_run_name=run_name,
                    retention_days=retention_days,
                    max_total_bytes=max_total_bytes,
                    reserved_bytes=EVIDENCE_METADATA_RESERVE_BYTES,
                    now_timestamp=timestamp,
                )
            )
        except ContractError as error:
            finalization_error = str(error)

        reserved_bytes = incoming_bytes + EVIDENCE_METADATA_RESERVE_BYTES
        if finalization_error is None and reserved_bytes >= max_total_bytes:
            finalization_error = (
                "incoming evidence plus metadata reserve exceeds the total size limit"
            )

        if finalization_error is None:
            try:
                removed.extend(
                    _cleanup_evidence_unlocked(
                        prepared_root,
                        protected_run_name=run_name,
                        retention_days=retention_days,
                        max_total_bytes=max_total_bytes,
                        reserved_bytes=reserved_bytes,
                        now_timestamp=timestamp,
                    )
                )
                artifacts = _copy_evidence_artifacts(
                    attempt_directory=attempt_directory,
                    source_log=source_log,
                    source_result=source_result,
                    outcome=outcome,
                )
            except (ContractError, OSError) as error:
                _discard_partial_evidence_artifacts(attempt_directory)
                finalization_error = f"durable attachment publication failed: {error}"

        os.utime(prepared_root / run_name, (timestamp, timestamp))
        try:
            removed.extend(
                _cleanup_evidence_unlocked(
                    prepared_root,
                    protected_run_name=run_name,
                    retention_days=retention_days,
                    max_total_bytes=max_total_bytes,
                    reserved_bytes=EVIDENCE_METADATA_RESERVE_BYTES,
                    now_timestamp=timestamp,
                )
            )
        except ContractError as error:
            if artifacts["log"] is not None or artifacts["result_bundle"] is not None:
                _discard_partial_evidence_artifacts(attempt_directory)
                artifacts = {"log": None, "result_bundle": None}
            if finalization_error is None:
                finalization_error = str(error)

        created_at = datetime.fromtimestamp(timestamp, timezone.utc).isoformat().replace(
            "+00:00", "Z"
        )
        limitations = [
            "signed archive and installed app were not evaluated",
            "privacy and network runtime behavior were not evaluated",
            "release candidate conformance was not evaluated",
            "this evidence does not authorize merge, upload, TestFlight, go/no-go, or release",
        ]
        summary = {
            "schema_version": 1,
            "classification": "routine-ci-only",
            "created_at": created_at,
            "source": {
                "trigger_sha": trigger_sha,
                "sha": sha or None,
                "checkout_validated": bool(sha),
            },
            "run": {
                "id": int(run_id),
                "attempt": int(run_attempt),
                "job": job,
                "event": event_name,
                "outcome": outcome,
                "exit_code": parsed_exit_code,
            },
            "toolchain": {
                "xcode_version": toolchain.xcode_version if toolchain else None,
                "xcode_build_version": (
                    toolchain.xcode_build_version if toolchain else None
                ),
                "swiftlint_version": toolchain.swiftlint_version if toolchain else None,
                "developer_dir": developer_dir or None,
                "validated": toolchain_validated,
            },
            "simulator": {
                "name": simulator_name or None,
                "udid": simulator_udid or None,
                "runtime": simulator_runtime or None,
                "device_type": simulator_device_type or None,
                "destination": simulator_destination or None,
            },
            "test": {
                "scheme": scheme,
                "plan": test_plan,
                "configuration": test_configuration,
                "default_timeout_seconds": default_timeout_seconds,
                "maximum_timeout_seconds": maximum_timeout_seconds,
            },
            "artifacts": {
                **artifacts,
                "omission_reason": finalization_error,
            },
            "limitations": limitations,
        }
        (attempt_directory / "summary.json").write_text(
            json.dumps(summary, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        attachment_markdown = (
            f"- Durable attachments: omitted (`{finalization_error}`)\n\n"
            if finalization_error
            else "- Durable attachments: retained\n\n"
        )
        markdown = (
            "# Routine CI evidence\n\n"
            f"- Outcome: `{outcome}`\n"
            f"- Trigger SHA: `{trigger_sha}`\n"
            f"- Validated checkout SHA: `{sha or 'not validated'}`\n"
            f"- Test plan/configuration: `{test_plan}` / `{test_configuration}`\n"
            f"- Durable local path: `{attempt_directory}`\n\n"
            f"{attachment_markdown}"
            "> This is routine CI only. It does not prove signed archive/install, "
            "privacy/network behavior, or release candidate conformance and does not "
            "authorize release.\n"
        )
        (attempt_directory / "summary.md").write_text(markdown, encoding="utf-8")
        with github_summary.open("a", encoding="utf-8") as handle:
            handle.write(markdown)

    if removed:
        print(
            "Removed expired/over-budget evidence runs: "
            + ", ".join(dict.fromkeys(removed))
        )
    if finalization_error is not None:
        raise ContractError(
            f"{finalization_error}; minimal summary preserved at {attempt_directory}"
        )
    return attempt_directory


def command_toolchain(arguments: argparse.Namespace) -> None:
    expected, developer_dir = validate_installed_toolchain(arguments.config)
    append_github_values(
        arguments.github_env,
        {
            "DEVELOPER_DIR": developer_dir,
            "SIMULATOR_RUNTIME_IDENTIFIER": expected.simulator_runtime_identifier,
        },
    )
    append_github_values(
        arguments.github_output,
        {
            "validated": "true",
            "developer_dir": developer_dir,
            "xcode_version": expected.xcode_version,
            "xcode_build_version": expected.xcode_build_version,
            "swiftlint_version": expected.swiftlint_version,
            "simulator_runtime": expected.simulator_runtime_identifier,
        },
    )
    print(f"Xcode {expected.xcode_version} ({expected.xcode_build_version})")
    print(f"SwiftLint {expected.swiftlint_version}")
    print(f"Simulator runtime: {expected.simulator_runtime_identifier}")
    print(f"Developer directory: {developer_dir}")


def command_simulator(arguments: argparse.Namespace) -> None:
    with arguments.inventory.open(encoding="utf-8") as handle:
        inventory = json.load(handle)
    simulator = select_simulator(
        inventory,
        exact_name=arguments.name,
        device_type_identifier=arguments.device_type,
        runtime_identifier=arguments.runtime,
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
    path = find_exact_xctestrun(
        arguments.root,
        arguments.pattern,
        confinement_root=arguments.confinement_root,
    )
    append_github_values(arguments.github_output, {"path": str(path)})
    print(f"xctestrun: {path}")


def command_dependencies(arguments: argparse.Namespace) -> None:
    validate_package_dependencies(arguments.root)
    print("All package dependency directions are correct")


def command_evidence(arguments: argparse.Namespace) -> None:
    if arguments.toolchain_validated not in {"", "true"}:
        raise ContractError("toolchain validation output must be empty or true")
    toolchain_validated = arguments.toolchain_validated == "true"
    toolchain: Toolchain | None = None
    if toolchain_validated:
        toolchain = parse_toolchain(
            "\n".join(
                (
                    f"XCODE_VERSION={arguments.xcode_version}",
                    f"XCODE_BUILD_VERSION={arguments.xcode_build_version}",
                    f"SWIFTLINT_VERSION={arguments.swiftlint_version}",
                    f"SIMULATOR_RUNTIME_IDENTIFIER={arguments.toolchain_runtime}",
                )
            )
        )
    elif any(
        (
            arguments.xcode_version,
            arguments.xcode_build_version,
            arguments.swiftlint_version,
            arguments.toolchain_runtime,
        )
    ):
        raise ContractError("unvalidated toolchain must not provide identity fields")

    attempt = finalize_evidence(
        root=arguments.root,
        workspace=arguments.workspace,
        source_log=arguments.source_log,
        source_result=arguments.source_result,
        github_summary=arguments.github_summary,
        toolchain=toolchain,
        toolchain_validated=toolchain_validated,
        trigger_sha=arguments.trigger_sha,
        sha=arguments.checkout_sha,
        run_id=arguments.run_id,
        run_attempt=arguments.run_attempt,
        job=arguments.job,
        event_name=arguments.event_name,
        outcome=arguments.outcome,
        exit_code=arguments.exit_code,
        developer_dir=arguments.developer_dir,
        simulator_name=arguments.simulator_name,
        simulator_udid=arguments.simulator_udid,
        simulator_runtime=arguments.simulator_runtime,
        simulator_device_type=arguments.simulator_device_type,
        simulator_destination=arguments.simulator_destination,
        scheme=arguments.scheme,
        test_plan=arguments.test_plan,
        test_configuration=arguments.test_configuration,
        default_timeout_seconds=arguments.default_timeout_seconds,
        maximum_timeout_seconds=arguments.maximum_timeout_seconds,
        retention_days=arguments.retention_days,
        max_total_bytes=arguments.max_total_bytes,
    )
    print(f"Durable routine CI evidence: {attempt}")


def command_evidence_janitor(arguments: argparse.Namespace) -> None:
    root = prepare_evidence_root(arguments.root, arguments.workspace)
    removed = prune_evidence(
        root,
        retention_days=arguments.retention_days,
        max_total_bytes=arguments.max_total_bytes,
    )
    if removed:
        print("Removed evidence runs: " + ", ".join(removed))
    else:
        print("Evidence retention policy already satisfied")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    toolchain = subparsers.add_parser("toolchain")
    toolchain.add_argument("--config", type=Path, required=True)
    toolchain.add_argument("--github-env", type=Path, required=True)
    toolchain.add_argument("--github-output", type=Path, required=True)
    toolchain.set_defaults(handler=command_toolchain)

    simulator = subparsers.add_parser("simulator")
    simulator.add_argument("--inventory", type=Path, required=True)
    simulator.add_argument("--name", required=True)
    simulator.add_argument("--device-type", required=True)
    simulator.add_argument("--runtime", required=True)
    simulator.add_argument("--github-output", type=Path, required=True)
    simulator.set_defaults(handler=command_simulator)

    xctestrun = subparsers.add_parser("xctestrun")
    xctestrun.add_argument("--root", type=Path, required=True)
    xctestrun.add_argument("--confinement-root", type=Path, required=True)
    xctestrun.add_argument("--pattern", required=True)
    xctestrun.add_argument("--github-output", type=Path, required=True)
    xctestrun.set_defaults(handler=command_xctestrun)

    dependencies = subparsers.add_parser("dependencies")
    dependencies.add_argument("--root", type=Path, required=True)
    dependencies.set_defaults(handler=command_dependencies)

    evidence = subparsers.add_parser("evidence")
    evidence.add_argument("--root", type=Path, required=True)
    evidence.add_argument("--workspace", type=Path, required=True)
    evidence.add_argument("--source-log", type=Path, required=True)
    evidence.add_argument("--source-result", type=Path, required=True)
    evidence.add_argument("--github-summary", type=Path, required=True)
    evidence.add_argument("--trigger-sha", required=True)
    evidence.add_argument("--checkout-sha", default="")
    evidence.add_argument("--run-id", required=True)
    evidence.add_argument("--run-attempt", required=True)
    evidence.add_argument("--job", required=True)
    evidence.add_argument("--event-name", required=True)
    evidence.add_argument("--outcome", required=True)
    evidence.add_argument("--exit-code", default="")
    evidence.add_argument("--toolchain-validated", default="")
    evidence.add_argument("--xcode-version", default="")
    evidence.add_argument("--xcode-build-version", default="")
    evidence.add_argument("--swiftlint-version", default="")
    evidence.add_argument("--toolchain-runtime", default="")
    evidence.add_argument("--developer-dir", default="")
    evidence.add_argument("--simulator-name", default="")
    evidence.add_argument("--simulator-udid", default="")
    evidence.add_argument("--simulator-runtime", default="")
    evidence.add_argument("--simulator-device-type", default="")
    evidence.add_argument("--simulator-destination", default="")
    evidence.add_argument("--scheme", required=True)
    evidence.add_argument("--test-plan", required=True)
    evidence.add_argument("--test-configuration", required=True)
    evidence.add_argument("--default-timeout-seconds", type=int, required=True)
    evidence.add_argument("--maximum-timeout-seconds", type=int, required=True)
    evidence.add_argument("--retention-days", type=int, required=True)
    evidence.add_argument("--max-total-bytes", type=int, required=True)
    evidence.set_defaults(handler=command_evidence)

    evidence_janitor = subparsers.add_parser("evidence-janitor")
    evidence_janitor.add_argument("--root", type=Path, required=True)
    evidence_janitor.add_argument("--workspace", type=Path, required=True)
    evidence_janitor.add_argument("--retention-days", type=int, required=True)
    evidence_janitor.add_argument("--max-total-bytes", type=int, required=True)
    evidence_janitor.set_defaults(handler=command_evidence_janitor)
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
