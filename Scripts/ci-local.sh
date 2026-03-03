#!/bin/bash
#
#  ci-local.sh
#  SnapDrill
#
#  在本地模拟 CI 流水线，推送前执行以发现问题。
#  用法：bash Scripts/ci-local.sh
#

set -e

SCHEME="SnapDrill"
DESTINATION="platform=iOS Simulator,name=iPhone 17"
SIGNING_FLAGS="CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="

echo "▶ [1/3] Lint（--strict）"
swiftlint --strict

echo ""
echo "▶ [2/3] Build"
xcodebuild build \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    | xcpretty || xcodebuild build \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY=""

echo ""
echo "▶ [3/3] Test（跳过 UITests）"
xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -skip-testing:SnapDrillUITests \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    | xcpretty || xcodebuild test \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -skip-testing:SnapDrillUITests \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY=""

echo ""
echo "✅ 本地 CI 全部通过，可以推送。"
