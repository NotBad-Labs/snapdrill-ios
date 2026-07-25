#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

export PATH="$HOME/.local/bin:$HOME/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

for tool in git python3 swiftlint xcodebuild; do
  if ! command -v "$tool" >/dev/null; then
    echo "error: required tool not found: $tool" >&2
    exit 1
  fi
done

echo "Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "SwiftLint: $(swiftlint version)"

git diff --check
python3 Scripts/validate_docs.py --check
swiftlint --strict

destination="${SNAPDRILL_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=latest}"
derived_data="$(mktemp -d "${TMPDIR:-/tmp}/snapdrill-check.XXXXXX")"

cleanup() {
  if [[ -d "$derived_data" ]]; then
    rm -r "$derived_data"
  fi
}
trap cleanup EXIT

xcodebuild test \
  -scheme AllTests \
  -testPlan AllTests \
  -only-test-configuration CI \
  -destination "$destination" \
  -derivedDataPath "$derived_data" \
  -clonedSourcePackagesDirPath "$HOME/.spm-cache/snapdrill" \
  -parallel-testing-enabled NO \
  -test-timeouts-enabled YES \
  -default-test-execution-time-allowance 120 \
  -maximum-test-execution-time-allowance 300 \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""
