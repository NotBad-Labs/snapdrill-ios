#!/bin/bash
# Scripts/setup_ci.sh
# 设置CI环境的脚本

set -e

echo "🚀 设置 NotBad CI/CD 环境..."

# 1. 创建必要的目录
mkdir -p .github/workflows
mkdir -p Scripts
mkdir -p TestPlans

# 2. 设置脚本权限
find Scripts -name "*.py" -exec chmod +x {} \;
find Scripts -name "*.sh" -exec chmod +x {} \;

# 3. 创建 ExportOptions.plist
cat > ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>\${TEAM_ID}</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>destination</key>
    <string>upload</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
EOF

# 4. 验证Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

# 5. 检查Xcode版本
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode 未安装"
    exit 1
fi

xcode_version=$(xcodebuild -version | head -n 1)
echo "📱 检测到 Xcode: $xcode_version"

# 6. 验证必要的测试计划文件
required_files=(
    "UnitTestPlan.xctestplan"
    "IntegrationTestPlan.xctestplan"
    "UITestPlan.xctestplan"
    "PerformanceTestPlan.xctestplan"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "⚠️  警告: 缺少测试计划文件 $file"
    else
        echo "✅ 找到测试计划: $file"
    fi
done

# 7. 创建性能基线文件（如果不存在）
if [ ! -f "performance_baseline.json" ]; then
    echo "{}" > performance_baseline.json
    echo "📊 创建了性能基线文件"
fi

echo "✅ CI/CD 环境设置完成！"
echo ""
echo "下一步:"
echo "1. 在 GitHub Secrets 中配置 TEAM_ID"
echo "2. 配置 App Store Connect API 密钥"
echo "3. 运行 'git push' 触发 CI 流水线"
