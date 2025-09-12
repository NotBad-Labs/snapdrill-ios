#!/bin/bash

# 脚本：修复iOS部署目标版本不匹配问题
# 目标：将所有目标的部署版本统一为iOS 17.0以确保CI兼容性

PROJECT_FILE="NotBad.xcodeproj/project.pbxproj"

echo "开始修复iOS部署目标..."

# 使用更精确的替换，避免破坏文件结构
# 只替换明确的部署目标行，避免影响其他配置

# 替换主应用目标的iOS 18.0为17.0
sed -i '' '/IPHONEOS_DEPLOYMENT_TARGET = 18\.0;/s/18\.0/17.0/' "$PROJECT_FILE"

# 替换测试目标的iOS 18.5为17.0  
sed -i '' '/IPHONEOS_DEPLOYMENT_TARGET = 18\.5;/s/18\.5/17.0/' "$PROJECT_FILE"

echo "验证修改结果..."
grep "IPHONEOS_DEPLOYMENT_TARGET" "$PROJECT_FILE"

echo "修复完成！"
