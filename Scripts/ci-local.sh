#!/usr/bin/env bash

set -euo pipefail

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

script_path="${BASH_SOURCE[0]}"
[[ "$script_path" == */* ]] || script_path="./$script_path"
script_dir="$(cd "${script_path%/*}" && pwd -P)"
require_command git
repo_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
cd "$repo_root"

toolchain_file="$repo_root/Configs/Toolchain.env"
[[ -f "$toolchain_file" ]] || die "missing toolchain identity: Configs/Toolchain.env"
# shellcheck source=../Configs/Toolchain.env
source "$toolchain_file"

for variable in XCODE_VERSION XCODE_BUILD_VERSION SWIFTLINT_VERSION; do
  [[ -n "${!variable:-}" ]] || die "missing $variable in Configs/Toolchain.env"
done

require_command xcodebuild
require_command swiftlint
require_command python3
require_command find
require_command mktemp

checkout_sha="$(git rev-parse HEAD)"
worktree_state="$(git status --porcelain --untracked-files=all)"
if [[ -n "$worktree_state" ]]; then
  printf '%s\n' "$worktree_state" >&2
  die "canonical source gate requires a clean committed checkout"
fi

expected_xcode_output="$(printf 'Xcode %s\nBuild version %s' "$XCODE_VERSION" "$XCODE_BUILD_VERSION")"
actual_xcode_output="$(xcodebuild -version)"
[[ "$actual_xcode_output" == "$expected_xcode_output" ]] || {
  printf 'error: Xcode identity mismatch\nexpected:\n%s\nactual:\n%s\n' \
    "$expected_xcode_output" "$actual_xcode_output" >&2
  exit 1
}

actual_swiftlint_version="$(swiftlint version)"
[[ "$actual_swiftlint_version" == "$SWIFTLINT_VERSION" ]] || {
  printf 'error: SwiftLint identity mismatch; expected %s, actual %s\n' \
    "$SWIFTLINT_VERSION" "$actual_swiftlint_version" >&2
  exit 1
}

destination="platform=iOS Simulator,name=iPhone 17"
test_plan="SnapDrill.xcodeproj/xcshareddata/xctestplans/AllTests.xctestplan"

printf 'Source identity: %s (clean)\n' "$checkout_sha"
printf 'Xcode identity:\n%s\n' "$actual_xcode_output"
printf 'SwiftLint identity: %s\n' "$actual_swiftlint_version"
printf 'Requested destination: %s\n' "$destination"

printf '\n[1/6] SwiftLint strict\n'
swiftlint --strict

printf '\n[2/6] Script and documentation gates\n'
python3 -m unittest discover -s Scripts/tests
python3 Scripts/generate_feature_status.py --check
python3 Scripts/generate_intent_traceability.py --check
python3 Scripts/test_doc_generators.py
python3 Scripts/validate_document_control.py --check
python3 Scripts/validate_docs.py --check
python3 Scripts/validate_capture_contract.py --check
python3 Scripts/validate_release_configuration.py --check
python3 Scripts/validate_release_test_overrides.py --check

printf '\n[3/6] Dependency direction checks\n'
python3 Scripts/ci_github.py dependencies --root "$repo_root"

printf '\n[4/6] AllTests plan contract\n'
python3 -c '
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    plan = json.load(handle)
configurations = [item.get("name") for item in plan.get("configurations", [])]
if configurations.count("CI") != 1:
    raise SystemExit("AllTests plan must contain exactly one CI configuration")
if not plan.get("testTargets"):
    raise SystemExit("AllTests plan must contain at least one test target")
' "$test_plan"

tmp_parent="${TMPDIR:-/tmp}"
[[ -d "$tmp_parent" ]] || die "temporary directory does not exist: $tmp_parent"
run_root="$(mktemp -d "${tmp_parent%/}/snapdrill-ci-local.XXXXXX")"
[[ "$run_root" == "${tmp_parent%/}"/snapdrill-ci-local.* ]] || \
  die "mktemp returned an unexpected path: $run_root"
derived_data="$run_root/DerivedData"
build_results="$run_root/BuildResults.xcresult"
test_results="$run_root/TestResults.xcresult"

cleanup_artifacts() {
  local status=$?
  if [[ "$status" -eq 0 ]]; then
    rm -rf -- "$run_root"
  else
    printf 'Source-gate artifacts preserved at: %s\n' "$run_root" >&2
  fi
}
trap cleanup_artifacts EXIT

printf '\n[5/6] AllTests build-for-testing\n'
xcodebuild build-for-testing \
  -scheme AllTests \
  -testPlan AllTests \
  -destination "$destination" \
  -derivedDataPath "$derived_data" \
  -resultBundlePath "$build_results" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

xctestrun_list="$run_root/xctestrun-paths"
if ! find "$derived_data/Build/Products" \
  -type f -name 'AllTests_*.xctestrun' -print0 > "$xctestrun_list"; then
  die "failed to inspect generated AllTests xctestrun files"
fi

xctestrun_paths=()
while IFS= read -r -d '' candidate; do
  xctestrun_paths[${#xctestrun_paths[@]}]="$candidate"
done < "$xctestrun_list"

if [[ "${#xctestrun_paths[@]}" -ne 1 ]]; then
  printf 'error: expected exactly one AllTests_*.xctestrun, found %s\n' \
    "${#xctestrun_paths[@]}" >&2
  if [[ "${#xctestrun_paths[@]}" -gt 0 ]]; then
    printf '  %s\n' "${xctestrun_paths[@]}" >&2
  fi
  exit 1
fi
xctestrun_path="${xctestrun_paths[0]}"

printf '\n[6/6] AllTests CI test-without-building\n'
xcodebuild test-without-building \
  -xctestrun "$xctestrun_path" \
  -only-test-configuration CI \
  -destination "$destination" \
  -parallel-testing-enabled NO \
  -resultBundlePath "$test_results" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

[[ "$(git rev-parse HEAD)" == "$checkout_sha" ]] || die "checkout HEAD changed during validation"
final_worktree_state="$(git status --porcelain --untracked-files=all)"
[[ -z "$final_worktree_state" ]] || {
  printf '%s\n' "$final_worktree_state" >&2
  die "validation changed the checkout"
}

printf '\nSource gate PASSED for %s\n' "$checkout_sha"
printf 'Evaluated: exact tools, SwiftLint, docs/static gates, AllTests CI build and tests.\n'
printf 'NOT evaluated: exact simulator identity/allocation; app UI/XCUITest or AX; archive/install; privacy/network; candidate conformance.\n'
printf 'This result does not authorize merge, upload, TestFlight, go/no-go, or release.\n'
