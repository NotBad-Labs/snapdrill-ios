#!/usr/bin/env bash
#
#  ci-local.sh
#  SnapDrill
#
#  在本地模拟 CI 流水线，推送前执行以发现问题。
#  用法：bash Scripts/ci-local.sh
#

set -euo pipefail

SCHEME="AllTests"
DESTINATION="platform=iOS Simulator,name=iPhone 17"
DERIVED_DATA_PATH="${TMPDIR:-/tmp}/snapdrill-local-ci-deriveddata"

echo "▶ [1/4] Lint（--strict）"
swiftlint --strict

echo ""
echo "▶ [2/4] Documentation gates"
python3 Scripts/generate_feature_status.py --check
python3 Scripts/validate_docs.py --check

echo ""
echo "▶ [3/4] Build for testing"
xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -testPlan AllTests \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY=""

echo ""
echo "▶ [4/4] Test without building（CI configuration）"
XCTESTRUN_PATH=$(find "$DERIVED_DATA_PATH/Build/Products" -name "AllTests_*.xctestrun" | head -1)
if [ -z "$XCTESTRUN_PATH" ] || [ ! -f "$XCTESTRUN_PATH" ]; then
    echo "error: xctestrun not found under $DERIVED_DATA_PATH/Build/Products" >&2
    exit 1
fi

xcodebuild test-without-building \
    -xctestrun "$XCTESTRUN_PATH" \
    -only-test-configuration CI \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY=""

echo ""
echo "✅ 本地 CI 全部通过，可以推送。"
