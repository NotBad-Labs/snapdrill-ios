#!/usr/bin/env python3
"""Reject Release-possible UI-test selectors and implicit mock references."""
from __future__ import annotations

import argparse
import importlib.util
import os
import subprocess
import sys
from pathlib import Path
from types import ModuleType
from typing import Dict, Iterable, List, Mapping, NamedTuple, Optional, Sequence, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent
LEXER_PATH = Path(__file__).resolve().with_name("swift_source_lexer.py")

EXPECTED_PRODUCTION_SWIFT_FILE_COUNT = 207
EXPECTED_SENTINELS = frozenset(
    {
        "Packages/SnapDrillCore/Sources/SnapDrillCore/Support/AppConfiguration.swift",
        "SnapDrillShare/ShareDeepLinkBuilder.swift",
        "SnapDrillShare/ShareImageDownsampler.swift",
        "SnapDrillShare/ShareViewController.swift",
        "SnapDrillShare/SharedContainerImageWriter.swift",
    }
)
EXPECTED_CUSTOM_TOKEN_VALUES = frozenset(
    {
        "--uitesting",
        "--ui-test-camera-permission-denied",
        "--ui-test-capture-continuous-crop-result",
        "--ui-test-capture-image-result",
        "--ui-test-capture-pdf-page-picker",
        "--ui-test-capture-scan-page-picker",
        "--ui-test-data-sync-backup-progress",
        "--ui-test-data-sync-import-progress",
        "--ui-test-durable-capture-draft",
        "--ui-test-edit-profile-photo-avatar",
        "--ui-test-force-degraded-banner",
        "--ui-test-force-store-recovery",
        "--ui-test-library-edit-metadata-failure",
        "--ui-test-library-edit-metadata-loading",
        "--ui-test-library-edit-missing-answer",
        "--ui-test-library-edit-slow-image",
        "--ui-test-notification-permission-denied",
        "--ui-test-seed-durable-capture-draft",
        "--ui-test-seed-image-library",
    }
)
MOCK_TYPES = frozenset({"MockServiceContainer", "AnalyticsServiceMock"})
DECLARATION_KEYWORDS = frozenset({"actor", "class", "enum", "protocol", "struct"})


class ReleaseOverrideValidationError(ValueError):
    pass


def _load_lexer() -> ModuleType:
    module_name = "snapdrill_swift_source_lexer"
    existing = sys.modules.get(module_name)
    if existing is not None:
        return existing
    spec = importlib.util.spec_from_file_location(module_name, LEXER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load lexer module: {LEXER_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    try:
        spec.loader.exec_module(module)
    except BaseException:
        sys.modules.pop(module_name, None)
        raise
    return module


lexer = _load_lexer()
ConditionalState = lexer.ConditionalState
SourceToken = lexer.SourceToken
SwiftLexicalError = lexer.SwiftLexicalError
TokenKind = lexer.TokenKind
condition_and = lexer.condition_and
tokenize = lexer.tokenize


class DeclarationSpan(NamedTuple):
    path: str
    start_offset: int
    end_offset: int


def _validate_repository_path(path: str) -> None:
    if not isinstance(path, str) or not path:
        raise ReleaseOverrideValidationError("tracked path must be a nonempty string")
    if "\0" in path or "\\" in path or path.startswith("/"):
        raise ReleaseOverrideValidationError(f"invalid tracked path: {path!r}")
    components = path.split("/")
    if any(component in ("", ".", "..") for component in components):
        raise ReleaseOverrideValidationError(f"non-normalized tracked path: {path!r}")


def is_production_swift_path(path: str) -> bool:
    if not path.endswith(".swift"):
        return False
    if path.startswith("SnapDrill/") or path.startswith("SnapDrillShare/"):
        return True
    components = path.split("/")
    return (
        len(components) >= 4
        and components[0] == "Packages"
        and bool(components[1])
        and components[2] == "Sources"
    )


def select_production_paths(paths: Sequence[str]) -> List[str]:
    seen = set()
    selected: List[str] = []
    roots = {"SnapDrill": 0, "SnapDrillShare": 0, "Packages": 0}
    for path in paths:
        _validate_repository_path(path)
        if path in seen:
            raise ReleaseOverrideValidationError(f"duplicate tracked path: {path}")
        seen.add(path)
        if not is_production_swift_path(path):
            continue
        selected.append(path)
        if path.startswith("SnapDrill/"):
            roots["SnapDrill"] += 1
        elif path.startswith("SnapDrillShare/"):
            roots["SnapDrillShare"] += 1
        else:
            roots["Packages"] += 1
    missing = [name for name, count in roots.items() if count == 0]
    if missing:
        raise ReleaseOverrideValidationError(
            "empty configured production root(s): " + ", ".join(missing)
        )
    return sorted(selected)


def discover_tracked_sources(
    repo_root: Path = REPO_ROOT,
    expected_count: Optional[int] = EXPECTED_PRODUCTION_SWIFT_FILE_COUNT,
    required_sentinels: Sequence[str] = tuple(EXPECTED_SENTINELS),
) -> Dict[str, str]:
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z", "--", "*.swift"],
            cwd=str(repo_root),
            env={
                key: value
                for key, value in os.environ.items()
                if not key.startswith("GIT_")
            },
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    except OSError as error:
        raise ReleaseOverrideValidationError(f"git ls-files failed: {error}") from error
    if result.returncode != 0:
        stderr = result.stderr.decode("utf-8", errors="replace").strip()
        raise ReleaseOverrideValidationError(
            f"git ls-files failed with exit {result.returncode}: {stderr}"
        )
    if result.stdout and not result.stdout.endswith(b"\0"):
        raise ReleaseOverrideValidationError("git ls-files returned malformed NUL output")
    try:
        tracked_paths = [
            item.decode("utf-8") for item in result.stdout.split(b"\0") if item
        ]
    except UnicodeDecodeError as error:
        raise ReleaseOverrideValidationError(
            f"git ls-files returned a non-UTF-8 path at byte {error.start}"
        ) from error

    production_paths = select_production_paths(tracked_paths)
    if expected_count is not None and len(production_paths) != expected_count:
        raise ReleaseOverrideValidationError(
            "production Swift census mismatch: "
            f"expected {expected_count}, found {len(production_paths)}"
        )
    missing_sentinels = sorted(set(required_sentinels) - set(production_paths))
    if missing_sentinels:
        raise ReleaseOverrideValidationError(
            "missing production sentinel(s): " + ", ".join(missing_sentinels)
        )

    sources: Dict[str, str] = {}
    root = repo_root.resolve()
    for relative_path in production_paths:
        path = repo_root / relative_path
        try:
            if path.is_symlink() or not path.is_file():
                raise ReleaseOverrideValidationError(
                    f"tracked production source is not a regular file: {relative_path}"
                )
            if root not in path.resolve().parents:
                raise ReleaseOverrideValidationError(
                    f"tracked production source escapes repository: {relative_path}"
                )
            sources[relative_path] = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as error:
            raise ReleaseOverrideValidationError(
                f"tracked production source is not UTF-8: {relative_path}:{error.start}"
            ) from error
        except OSError as error:
            raise ReleaseOverrideValidationError(
                f"unable to read tracked production source {relative_path}: {error}"
            ) from error
    return sources


def _tokenize_sources(
    sources: Mapping[str, str],
) -> Tuple[Dict[str, List[SourceToken]], List[str]]:
    errors: List[str] = []
    tokenized: Dict[str, List[SourceToken]] = {}
    try:
        selected_paths = select_production_paths(list(sources.keys()))
    except ReleaseOverrideValidationError as error:
        return {}, [str(error)]
    if set(selected_paths) != set(sources.keys()):
        extras = sorted(set(sources.keys()) - set(selected_paths))
        return {}, ["source mapping contains non-production path(s): " + ", ".join(extras)]
    for path in selected_paths:
        source = sources[path]
        if not isinstance(source, str):
            errors.append(f"{path}: source must be UTF-8 text")
            continue
        try:
            tokenized[path] = tokenize(source)
        except SwiftLexicalError as error:
            errors.append(f"{path}:{error}")
    return tokenized, errors


def _find_declaration_spans(
    tokenized: Mapping[str, Sequence[SourceToken]],
) -> Tuple[Dict[str, DeclarationSpan], List[str]]:
    candidates: Dict[str, List[DeclarationSpan]] = {name: [] for name in MOCK_TYPES}
    errors: List[str] = []
    for path, tokens in tokenized.items():
        for index, token in enumerate(tokens):
            if token.kind is not TokenKind.IDENTIFIER or token.value not in MOCK_TYPES:
                continue
            if index == 0:
                continue
            previous = tokens[index - 1]
            if (
                previous.kind is not TokenKind.IDENTIFIER
                or previous.value not in DECLARATION_KEYWORDS
            ):
                continue
            opening = index + 1
            while opening < len(tokens):
                candidate = tokens[opening]
                if candidate.kind is TokenKind.PUNCTUATION and candidate.value == "{":
                    break
                if candidate.kind is TokenKind.PUNCTUATION and candidate.value in (";", "}"):
                    break
                opening += 1
            if opening >= len(tokens) or tokens[opening].value != "{":
                errors.append(
                    f"{path}:{token.line}:{token.column} missing body for {token.value} declaration"
                )
                continue
            depth = 0
            closing = opening
            while closing < len(tokens):
                current = tokens[closing]
                if current.kind is TokenKind.PUNCTUATION:
                    if current.value == "{":
                        depth += 1
                    elif current.value == "}":
                        depth -= 1
                        if depth == 0:
                            break
                closing += 1
            if closing >= len(tokens) or depth:
                errors.append(
                    f"{path}:{token.line}:{token.column} unterminated body for {token.value} declaration"
                )
                continue
            candidates[token.value].append(
                DeclarationSpan(path, token.offset, tokens[closing].end_offset)
            )

    spans: Dict[str, DeclarationSpan] = {}
    for name in sorted(MOCK_TYPES):
        found = candidates[name]
        if len(found) != 1:
            errors.append(f"expected exactly one {name} declaration body, found {len(found)}")
        else:
            spans[name] = found[0]
    return spans, errors


def _is_inside_any_declaration(
    path: str, token: SourceToken, spans: Iterable[DeclarationSpan]
) -> bool:
    return any(
        span.path == path
        and span.start_offset <= token.offset < span.end_offset
        for span in spans
    )


def _combined_condition(tokens: Sequence[SourceToken]) -> ConditionalState:
    state = ConditionalState.TRUE
    for token in tokens:
        state = condition_and(state, token.condition)
    return state


def _format_error(path: str, token: SourceToken, message: str) -> str:
    return f"{path}:{token.line}:{token.column} Release-possible {message}"


def validate_sources(
    sources: Mapping[str, str],
    expected_custom_values: Optional[Sequence[str]] = None,
) -> List[str]:
    """Validate an explicit production path-to-source mapping without filesystem discovery."""

    if not isinstance(sources, Mapping) or not sources:
        return ["source mapping must be nonempty"]
    tokenized, errors = _tokenize_sources(sources)
    if errors:
        return sorted(errors)

    declaration_spans, declaration_errors = _find_declaration_spans(tokenized)
    errors.extend(declaration_errors)
    allowed_spans = tuple(declaration_spans.values())
    observed_custom_values = set()
    process_pattern = (
        (TokenKind.IDENTIFIER, "ProcessInfo"),
        (TokenKind.PUNCTUATION, "."),
        (TokenKind.IDENTIFIER, "processInfo"),
        (TokenKind.PUNCTUATION, "."),
    )

    for path in sorted(tokenized):
        tokens = tokenized[path]
        for index, token in enumerate(tokens):
            if token.kind is TokenKind.STRING_SEGMENT and (
                token.value == "--uitesting" or token.value.startswith("--ui-test-")
            ):
                observed_custom_values.add(token.value)
                if token.condition is not ConditionalState.FALSE:
                    errors.append(
                        _format_error(path, token, f"custom UI-test token {token.value!r}")
                    )
            if (
                token.kind is TokenKind.IDENTIFIER
                and token.value in MOCK_TYPES
                and token.condition is not ConditionalState.FALSE
                and not _is_inside_any_declaration(path, token, allowed_spans)
            ):
                errors.append(
                    _format_error(path, token, f"mock reference {token.value}")
                )
            if index + 5 > len(tokens):
                continue
            candidate = tokens[index : index + 5]
            if any(
                item.kind is not expected_kind or item.value != expected_value
                for item, (expected_kind, expected_value) in zip(
                    candidate[:4], process_pattern
                )
            ):
                continue
            tail = candidate[4]
            if tail.kind is not TokenKind.IDENTIFIER or tail.value not in (
                "arguments",
                "environment",
            ):
                continue
            if _combined_condition(candidate) is not ConditionalState.FALSE:
                errors.append(
                    _format_error(
                        path,
                        token,
                        f"ProcessInfo.processInfo.{tail.value} selector",
                    )
                )

    if expected_custom_values is not None:
        expected = set(expected_custom_values)
        if observed_custom_values != expected:
            missing = sorted(expected - observed_custom_values)
            unexpected = sorted(observed_custom_values - expected)
            details = []
            if missing:
                details.append("missing=" + ",".join(missing))
            if unexpected:
                details.append("unexpected=" + ",".join(unexpected))
            errors.append("custom UI-test token census mismatch: " + "; ".join(details))
    return sorted(set(errors))


def run_checks(repo_root: Path = REPO_ROOT) -> List[str]:
    try:
        sources = discover_tracked_sources(repo_root)
    except ReleaseOverrideValidationError as error:
        return [str(error)]
    return validate_sources(sources, EXPECTED_CUSTOM_TOKEN_VALUES)


def main(argv: Optional[Iterable[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="validate without modifying files")
    parser.parse_args(argv)

    errors = run_checks()
    if errors:
        for error in errors:
            print(f"[error] {error}", file=sys.stderr)
        return 1
    print("[ok] Release test override checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
