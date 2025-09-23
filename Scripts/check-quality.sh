#!/bin/zsh

set -euo pipefail

echo "🔍 NotBad 代码质量检查"
echo "========================"

# 配置项
SIM_DEVICE=${SIM_DEVICE:-"iPhone 17"}
# 兼容旧变量：COVERAGE_THRESHOLD/WARN_THRESHOLD 用于逻辑覆盖率（保留向后兼容）
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}
WARN_THRESHOLD=${WARN_THRESHOLD:-80}

# 新增双门槛：逻辑覆盖率与整体覆盖率分别检查
LOGIC_COVERAGE_THRESHOLD=${LOGIC_COVERAGE_THRESHOLD:-$COVERAGE_THRESHOLD}
LOGIC_WARN_THRESHOLD=${LOGIC_WARN_THRESHOLD:-$WARN_THRESHOLD}
OVERALL_COVERAGE_THRESHOLD=${OVERALL_COVERAGE_THRESHOLD:-65}
OVERALL_WARN_THRESHOLD=${OVERALL_WARN_THRESHOLD:-65}
RESULT_BUNDLE=${RESULT_BUNDLE:-"TestResults.xcresult"}
ARTIFACTS_DIR="local_artifacts"
SNAPSHOT_DIR="docs/coverage"

# 默认排除 SwiftUI 视图文件（通常通过快照/UI 测试覆盖，不纳入逻辑覆盖率门槛）
# 同时匹配顶层 Presentation/Views 以及任意层级下的 .../Views 目录：
#   NotBad/NotBad/Presentation/Views/.../*.swift
#   NotBad/NotBad/Presentation/<any>/Views/.../*.swift
# 注意：该正则将用于 Python 的 re 模块；'(.*/)?' 使中间层级为可选，从而涵盖两种路径结构。
export COVERAGE_EXCLUDE_REGEX=${COVERAGE_EXCLUDE_REGEX:-'NotBad/NotBad/Presentation/(.*/)?Views/.*\.swift'}

mkdir -p "$ARTIFACTS_DIR" "$SNAPSHOT_DIR"

# 获取 Python 解释器
if [[ -x ".venv/bin/python" ]]; then
  PYTHON=".venv/bin/python"
else
  if command -v python3 >/dev/null 2>&1; then
    PYTHON="python3"
  else
    PYTHON="python"
  fi
fi

# 1. 代码规范（若本地安装了 SwiftLint）
if command -v swiftlint >/dev/null 2>&1; then
  echo "📝 运行 SwiftLint..."
  swiftlint || true
else
  echo "⚠️ 未检测到 swiftlint，跳过规范检查"
fi

# 2. 单元测试 + 覆盖率（使用可配置模拟器）
echo "🧪 运行单元测试并收集覆盖率..."
set +e
if command -v xcpretty >/dev/null 2>&1; then
  XCB_PIPE="xcpretty -c"
elif command -v xcbeautify >/dev/null 2>&1; then
  XCB_PIPE="xcbeautify"
else
  XCB_PIPE="cat"
fi
set -e

# 清理旧的 result bundle，避免冲突
rm -rf "$RESULT_BUNDLE"

# 运行测试并生成结果包
set +e
xcodebuild test \
  -project NotBad.xcodeproj \
  -scheme NotBad \
  -destination "platform=iOS Simulator,name=${SIM_DEVICE}" \
  -parallel-testing-enabled YES \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT_BUNDLE" | eval $XCB_PIPE
XCB_STATUS=$?
set -e

if [[ $XCB_STATUS -ne 0 ]]; then
  echo "⚠️ xcodebuild 返回非零退出码（$XCB_STATUS），继续进行覆盖率导出与报告"
fi

if [[ ! -d "$RESULT_BUNDLE" ]]; then
  echo "❌ 未生成结果包：$RESULT_BUNDLE"
  exit 1
fi

# 3. 导出覆盖率 JSON
echo "📤 导出覆盖率 JSON..."
if ! xcrun xccov view --report --json "$RESULT_BUNDLE" > "$ARTIFACTS_DIR/coverage-local.json" 2>/dev/null; then
  echo "❌ 无法从结果包导出覆盖率（可能未启用覆盖率或测试未执行）"
  exit 1
fi

# 4. 运行覆盖率校验（双门槛）
echo "📏 覆盖率阈值检查：双门槛 (逻辑: ${LOGIC_COVERAGE_THRESHOLD}% / 整体: ${OVERALL_COVERAGE_THRESHOLD}%)"
set +e
echo "— 逻辑覆盖率(排除 SwiftUI 视图)…"
echo "   ↳ 排除正则: $COVERAGE_EXCLUDE_REGEX"
$PYTHON Scripts/check_coverage.py "$ARTIFACTS_DIR/coverage-local.json" "$LOGIC_COVERAGE_THRESHOLD" --warn-threshold "$LOGIC_WARN_THRESHOLD" --show-details --exclude-path-regex "$COVERAGE_EXCLUDE_REGEX"
LOGIC_STATUS=$?

echo "— 整体覆盖率(包含全部文件)…"
$PYTHON Scripts/check_coverage.py "$ARTIFACTS_DIR/coverage-local.json" "$OVERALL_COVERAGE_THRESHOLD" --warn-threshold "$OVERALL_WARN_THRESHOLD" --show-details --exclude-path-regex 'a^'
OVERALL_STATUS=$?
set -e

# 5. 快照当前覆盖率报告
STAMP=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_FILE="$SNAPSHOT_DIR/coverage-${STAMP}.json"
cp "$ARTIFACTS_DIR/coverage-local.json" "$SNAPSHOT_FILE"
echo "🗂️ 覆盖率快照: $SNAPSHOT_FILE"

# 6. 基础文档存在性检查
echo "📚 检查文档..."
[[ -f README.md ]] || echo "❌ 缺少项目 README.md"
[[ -d docs/adr || -d docs/ADR ]] || echo "❌ 缺少 ADR 目录"

# 7. 依赖注入快速体检（简单启发式）
echo "💉 DI 体检（启发式）..."
grep -R "= .*()" NotBad/**/*.swift | head -5 || true

if [[ $LOGIC_STATUS -ne 0 || $OVERALL_STATUS -ne 0 ]]; then
  echo "📊 质量检查完成：有覆盖率门槛未达标（可在 CI 中严格执行终止）。"
  # 统一非零退出，但保留更具体的状态码优先返回整体门槛，其次逻辑门槛
  if [[ $OVERALL_STATUS -ne 0 ]]; then
    exit $OVERALL_STATUS
  else
    exit $LOGIC_STATUS
  fi
fi

echo "📊 质量检查完成：双门槛均达标。"
