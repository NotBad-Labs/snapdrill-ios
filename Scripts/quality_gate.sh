#!/bin/bash
# Scripts/quality_gate.sh
# 质量门槛检查脚本

# Note: We don't use 'set -e' to allow individual checks to fail and continue

echo "🚀 NotBad 质量门槛检查开始..."

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
        lychee --config .lychee.toml README.md docs/**/*.md
    else
        # 兼容回退：直接扫描常见文档
        lychee README.md docs/**/*.md
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
xcodebuild -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' clean build
check_result "项目编译"

echo "🧪 6. 单元测试运行..."
if [ "$CI_PARITY" = true ]; then
    # 与 CI 保持一致：指定 UnitTestPlan，并收集 result bundle
    LOCAL_XCRESULT="./Local-TestResults-$(date +%s).xcresult"
    xcodebuild test \
        -project NotBad.xcodeproj \
        -scheme NotBad \
        -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
        -testPlan UnitTestPlan \
        -enableCodeCoverage YES \
        -resultBundlePath "$LOCAL_XCRESULT"
    TEST_STATUS=$?
    if [ $TEST_STATUS -eq 0 ] && command -v xcrun &> /dev/null; then
        mkdir -p ./local_artifacts
        xcrun xccov view --report --json "$LOCAL_XCRESULT" > ./local_artifacts/coverage-local.json || true
    fi
    if [ $TEST_STATUS -eq 0 ]; then
        echo -e "${GREEN}✅ 单元测试 通过${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ 单元测试 失败${NC}"
        ((CHECKS_FAILED++))
    fi
else
    xcodebuild test -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' -enableCodeCoverage YES
    check_result "单元测试"
fi

echo "📊 7. 测试覆盖率检查..."
if [ "$CI_PARITY" = true ]; then
    if [ -f ./local_artifacts/coverage-local.json ]; then
        echo "已生成覆盖率 JSON (./local_artifacts/coverage-local.json)，与 CI 方式一致"
        echo -e "${GREEN}✅ 覆盖率收集 通过${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}⚠️ 未能生成覆盖率 JSON，跳过阈值判断（CI 对齐模式）${NC}"
    fi
else
    # 查找最新的覆盖率报告文件
    COVERAGE_FILE=$(find ~/Library/Developer/Xcode/DerivedData -name "*.xccovarchive" -type f -exec ls -lt {} + 2>/dev/null | head -1 | awk '{print $NF}')
    if [ -f "Scripts/check_coverage.py" ] && [ -n "$COVERAGE_FILE" ]; then
            python3 Scripts/check_coverage.py "$COVERAGE_FILE" 80
            check_result "测试覆盖率"
    else
            echo -e "${YELLOW}⚠️ 覆盖率检查脚本或覆盖率文件未找到${NC}"
    fi
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

if [ $CHECKS_FAILED -gt 0 ]; then
    echo -e "${RED}❌ 质量门槛检查失败，请修复问题后重试${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 所有质量检查通过！代码质量良好${NC}"
    exit 0
fi
