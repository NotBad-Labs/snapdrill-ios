#!/bin/zsh

set -euo pipefail

echo "🔍 NotBad 代码质量检查"
echo "========================"

# 1. 代码规范（若本地安装了 SwiftLint）
if command -v swiftlint >/dev/null 2>&1; then
  echo "📝 运行 SwiftLint..."
  swiftlint || true
else
  echo "⚠️ 未检测到 swiftlint，跳过规范检查"
fi

# 2. 单元测试 + 覆盖率（使用 iPhone 17 模拟器）
echo "🧪 运行单元测试并收集覆盖率..."
xcodebuild test \
  -project NotBad.xcodeproj \
  -scheme NotBad \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -parallel-testing-enabled YES \
  -enableCodeCoverage YES | xcpretty -c || true

# 3. 基础文档存在性检查
echo "📚 检查文档..."
[[ -f README.md ]] || echo "❌ 缺少项目 README.md"
[[ -d docs/adr || -d docs/ADR || -d docs/adr ]] || echo "❌ 缺少 ADR 目录"

# 4. 依赖注入快速体检（简单启发式）
echo "💉 DI 体检（启发式）..."
grep -R "= .*()" NotBad/**/*.swift | head -5 || true

echo "📊 质量检查完成（详尽报告建议在 CI 中生成并归档）"
