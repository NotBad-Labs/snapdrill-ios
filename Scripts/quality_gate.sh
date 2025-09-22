#!/bin/bash
# Scripts/quality_gate.sh
# 质量门槛检查脚本 - NotBad 项目

# Note: We don't use 'set -e' to allow individual checks to fail and continue

echo "🚀 NotBad 质量门槛检查开始..."

# 可配置的阈值参数
COVERAGE_THRESHOLD=${COVERAGE_THRESHOLD:-80}  # 测试覆盖率阈值，可通过环境变量覆盖
PROJECT_NAME="NotBad"  # 项目名称，用于精确查找覆盖率文件

# CI 对齐模式：
# - 使用与自托管 CI 相同的测试计划与结果收集方式
# - 跳过严格的覆盖率阈值与性能回归检查（CI 默认不强制这些）
CI_PARITY=false
if [ "${1:-}" = "--ci-parity" ] || [ "${CI_PARITY}" = "1" ]; then
    CI_PARITY=true
    echo "🧩 已启用 CI 对齐模式 (--ci-parity)"
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查结果统计
CHECKS_PASSED=0
CHECKS_FAILED=0

check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 通过${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ $1 失败${NC}"
        ((CHECKS_FAILED++))
    fi
}

# 工具可用性预检查
echo -e "${BLUE}🔧 检查必需工具可用性...${NC}"
TOOLS_STATUS=""
for tool in swiftlint; do
    if command -v "$tool" &> /dev/null; then
        echo -e "  ✅ $tool: $(command -v "$tool")"
    else
        echo -e "  ❌ $tool: 未安装"
        TOOLS_STATUS="${TOOLS_STATUS}${tool} "
    fi
done

for tool in npx python3; do
    if command -v "$tool" &> /dev/null; then
        echo -e "  ✅ $tool: 可用"
    else
        echo -e "  ⚠️ $tool: 未安装，部分检查可能跳过"
    fi
done

if [ -n "$TOOLS_STATUS" ]; then
    echo -e "${YELLOW}⚠️ 缺少工具: $TOOLS_STATUS${NC}"
    echo -e "${YELLOW}提示: 运行 'brew install swiftlint' 安装缺失工具${NC}"
fi
echo ""

echo "📝 1. SwiftLint 代码风格检查..."
if command -v swiftlint &> /dev/null; then
    swiftlint --strict
    check_result "SwiftLint检查"
else
    echo -e "${YELLOW}⚠️ SwiftLint 未安装，跳过检查${NC}"
fi

echo "🧹 2. Markdown 文档规范检查 (markdownlint)..."
if command -v npx &> /dev/null; then
    npx -y markdownlint "**/*.md" --ignore node_modules --config .markdownlint.jsonc
    check_result "markdownlint检查"
else
    echo -e "${YELLOW}⚠️ Node/npm 未安装，跳过 markdownlint 检查${NC}"
fi

echo "🔎 3. 文档链接检查 (lychee)..."
if command -v lychee &> /dev/null; then
    # 使用仓库根目录的统一配置，确保与 CI 一致
    if [ -f ".lychee.toml" ]; then
        # 检查配置文件是否已包含 inputs；无论是否包含，总是提供默认 inputs 避免参数错误
        lychee --config .lychee.toml "README.md" "docs/**/*.md"
    else
        # 兼容回退：直接扫描常见文档
        lychee "README.md" "docs/**/*.md"
    fi
    check_result "链接检查"
else
    echo -e "${YELLOW}⚠️ lychee 未安装，跳过链接检查（CI 会执行）${NC}"
fi

echo "🧭 4. 文档一致性检查..."
if [ -f "Scripts/docs_consistency_check.py" ]; then
    python3 Scripts/docs_consistency_check.py
    check_result "文档一致性检查"
else
    echo -e "${YELLOW}⚠️ 文档一致性检查脚本未找到${NC}"
fi

echo "🛠️ 5. 项目编译检查..."
# 允许通过环境变量自定义模拟器设备，默认与本地一致使用 iPhone 17（避免机型不一致导致的找不到模拟器问题）
SIM_DEVICE=${SIM_DEVICE:-"iPhone 17"}
xcodebuild -project NotBad.xcodeproj -scheme NotBad -destination "platform=iOS Simulator,name=${SIM_DEVICE}" clean build
check_result "项目编译"

echo "🧪 6. 单元测试运行..."
LOCAL_XCRESULT="./Local-TestResults-$(date +%s).xcresult"
if [ "$CI_PARITY" = true ]; then
    # 与 CI 保持一致：指定 UnitTestPlan，并收集 result bundle
    xcodebuild test \
        -project NotBad.xcodeproj \
        -scheme NotBad \
        -destination "platform=iOS Simulator,name=${SIM_DEVICE}" \
        -testPlan UnitTestPlan \
        -enableCodeCoverage YES \
        -resultBundlePath "$LOCAL_XCRESULT"
else
    # 本地模式同样生成覆盖率 JSON，便于后续阈值判断
    xcodebuild test \
        -project NotBad.xcodeproj \
        -scheme NotBad \
        -destination "platform=iOS Simulator,name=${SIM_DEVICE}" \
        -enableCodeCoverage YES \
        -resultBundlePath "$LOCAL_XCRESULT"
fi
TEST_STATUS=$?
if [ $TEST_STATUS -eq 0 ]; then
    if command -v xcrun &> /dev/null; then
        mkdir -p ./local_artifacts ./docs/coverage
        xcrun xccov view --report --json "$LOCAL_XCRESULT" > ./local_artifacts/coverage-local.json || true
        # 固化一份覆盖率快照到 docs/coverage，便于对比与归档
        SNAPSHOT_NAME="coverage-$(date +%Y%m%d-%H%M%S).json"
        cp ./local_artifacts/coverage-local.json ./docs/coverage/$SNAPSHOT_NAME 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ 单元测试 通过${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ 单元测试 失败${NC}"
    ((CHECKS_FAILED++))
fi

echo "📊 7. 测试覆盖率检查..."
# 优先使用本地JSON文件，如果不存在则查找CI模式文件
if [ -f ./local_artifacts/coverage-local.json ] && [ -f "Scripts/check_coverage.py" ]; then
    echo "ℹ️ 使用本地覆盖率文件: coverage-local.json (阈值: ${COVERAGE_THRESHOLD}%)"
    python3 Scripts/check_coverage.py ./local_artifacts/coverage-local.json "$COVERAGE_THRESHOLD"
    check_result "测试覆盖率"
elif [ "$CI_PARITY" = true ]; then
    echo -e "${YELLOW}⚠️ 未能生成覆盖率 JSON，跳过阈值判断（CI 对齐模式）${NC}"
else
    echo -e "${YELLOW}⚠️ 覆盖率检查脚本或覆盖率文件未找到${NC}"
fi

echo "🔍 8. 性能测试检查..."
if [ "$CI_PARITY" = true ]; then
    echo -e "${YELLOW}ℹ️ CI 对齐模式：跳过性能回归检查（需显式启用）${NC}"
else
    if [ -f "Scripts/check_performance_regression.py" ]; then
            python3 Scripts/check_performance_regression.py
            check_result "性能回归检查"
    else
            echo -e "${YELLOW}⚠️ 性能检查脚本未找到${NC}"
    fi
fi

# 总结
echo ""
echo "📋 质量门槛检查总结:"
echo -e "通过: ${GREEN}${CHECKS_PASSED}${NC}"
echo -e "失败: ${RED}${CHECKS_FAILED}${NC}"

# 清理临时文件 (可选)
if [ "${CLEANUP_TEMP_FILES:-false}" = "true" ]; then
    echo -e "${BLUE}🧹 清理临时文件...${NC}"
    # 清理超过1天的 xcresult 文件
    find . -name "Local-TestResults-*.xcresult" -type d -mtime +1 -exec rm -rf {} + 2>/dev/null || true
    echo "ℹ️ 已清理旧的测试结果文件"
fi

if [ $CHECKS_FAILED -gt 0 ]; then
    echo -e "${RED}❌ 质量门槛检查失败，请修复问题后重试${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 所有质量检查通过！代码质量良好${NC}"
    exit 0
fi
