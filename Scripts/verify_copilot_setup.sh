#!/bin/bash

# GitHub Copilot for Xcode 配置验证脚本
# 验证GitHub Copilot是否正确安装和配置

echo "🔍 GitHub Copilot for Xcode 配置验证"
echo "=================================="
echo

# 检查Homebrew版本
echo "1. 检查Homebrew..."
if command -v brew &> /dev/null; then
    brew_version=$(brew --version | head -n1)
    echo "   ✅ $brew_version"
else
    echo "   ❌ Homebrew未安装"
    exit 1
fi

# 检查Copilot for Xcode应用
echo "2. 检查Copilot for Xcode应用..."
if [ -d "/Applications/Copilot for Xcode.app" ]; then
    echo "   ✅ Copilot for Xcode已安装"

    # 检查应用是否正在运行
    if pgrep -f "Copilot for Xcode" > /dev/null; then
        echo "   ✅ Copilot for Xcode正在运行"
    else
        echo "   ⚠️  Copilot for Xcode未运行，正在启动..."
        open "/Applications/Copilot for Xcode.app"
    fi
else
    echo "   ❌ Copilot for Xcode未安装"
    exit 1
fi

# 检查Xcode扩展
echo "3. 检查Xcode扩展..."
if pluginkit -m | grep -q "com.intii.CopilotForXcode.EditorExtension"; then
    extension_version=$(pluginkit -m | grep "com.intii.CopilotForXcode.EditorExtension" | grep -o '([0-9.]*)')
    echo "   ✅ Copilot Xcode扩展已注册 $extension_version"
else
    echo "   ❌ Copilot Xcode扩展未注册"
fi

# 检查Xcode是否运行
echo "4. 检查Xcode状态..."
if pgrep -f "Xcode" > /dev/null; then
    echo "   ✅ Xcode正在运行"
else
    echo "   ⚠️  Xcode未运行，建议打开Xcode验证扩展"
fi

# 检查配置文件
echo "5. 检查项目配置..."
if [ -f "/Users/yimingliao/Developer/NotBad/.copilot-instructions.md" ]; then
    echo "   ✅ Copilot配置文件已创建"
else
    echo "   ❌ Copilot配置文件缺失"
fi

if [ -f "/Users/yimingliao/Developer/NotBad/CopilotTestFile.swift" ]; then
    echo "   ✅ Copilot测试文件已创建"
else
    echo "   ❌ Copilot测试文件缺失"
fi

if [ -f "/Users/yimingliao/Developer/NotBad/COPILOT_SETUP_GUIDE.md" ]; then
    echo "   ✅ Copilot设置指南已创建"
else
    echo "   ❌ Copilot设置指南缺失"
fi

echo
echo "🎯 下一步操作："
echo "1. 在Xcode中前往 Settings > Extensions，确保启用Copilot扩展"
echo "2. 在Copilot for Xcode应用中登录您的GitHub账户"
echo "3. 打开CopilotTestFile.swift测试代码建议功能"
echo "4. 参考COPILOT_SETUP_GUIDE.md完成最终配置"
echo
echo "✨ 配置完成后，您就可以享受AI辅助的Swift 6.2开发体验了！"
