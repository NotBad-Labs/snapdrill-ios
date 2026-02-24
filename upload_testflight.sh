#!/bin/bash
# TestFlight 自动上传脚本
# 使用方法: ./upload_testflight.sh

set -e  # 遇到错误立即退出

echo "🚀 SnapDrill TestFlight 自动上传"
echo "================================"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 配置
SCHEME="SnapDrill"
ARCHIVE_PATH="$HOME/Desktop/SnapDrill.xcarchive"
EXPORT_PATH="$HOME/Desktop/SnapDrill_Export"
EXPORT_OPTIONS_PLIST="./ExportOptions.plist"

echo ""
echo "${YELLOW}步骤 1/5: 清理旧文件${NC}"
rm -rf "$ARCHIVE_PATH"
rm -rf "$EXPORT_PATH"
echo "✅ 清理完成"

echo ""
echo "${YELLOW}步骤 2/5: 创建 Archive${NC}"
xcodebuild clean archive \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  | xcpretty || true

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "${RED}❌ Archive 创建失败${NC}"
    exit 1
fi
echo "${GREEN}✅ Archive 创建成功${NC}"

echo ""
echo "${YELLOW}步骤 3/5: 导出 IPA${NC}"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -allowProvisioningUpdates \
  | xcpretty || true

if [ ! -f "$EXPORT_PATH/SnapDrill.ipa" ]; then
    echo "${RED}❌ IPA 导出失败${NC}"
    exit 1
fi
echo "${GREEN}✅ IPA 导出成功${NC}"

echo ""
echo "${YELLOW}步骤 4/5: 验证 IPA${NC}"
xcrun altool --validate-app \
  -f "$EXPORT_PATH/SnapDrill.ipa" \
  -t ios \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID

echo "${GREEN}✅ IPA 验证成功${NC}"

echo ""
echo "${YELLOW}步骤 5/5: 上传到 App Store Connect${NC}"
echo "${YELLOW}⚠️  需要你的 App Store Connect API 密钥${NC}"
echo ""
echo "请选择上传方式:"
echo "1) 使用 Xcode Organizer (推荐，图形界面)"
echo "2) 使用 altool 命令行 (需要 API Key)"
echo ""
read -p "请输入选项 (1 或 2): " choice

case $choice in
    1)
        echo ""
        echo "${GREEN}✅ Archive 已准备好！${NC}"
        echo ""
        echo "请按以下步骤操作:"
        echo "1. 打开 Xcode"
        echo "2. 菜单栏: Window → Organizer"
        echo "3. 选择 'SnapDrill' Archive"
        echo "4. 点击 'Distribute App'"
        echo "5. 选择 'TestFlight & App Store'"
        echo "6. 点击 'Upload'"
        echo ""
        open -a Xcode "$ARCHIVE_PATH"
        ;;
    2)
        echo ""
        echo "${YELLOW}请输入你的 App Store Connect API 信息:${NC}"
        read -p "API Key ID: " api_key
        read -p "Issuer ID: " issuer_id
        
        xcrun altool --upload-app \
          -f "$EXPORT_PATH/SnapDrill.ipa" \
          -t ios \
          --apiKey "$api_key" \
          --apiIssuer "$issuer_id"
        
        echo "${GREEN}✅ 上传成功！${NC}"
        ;;
    *)
        echo "${RED}无效选项${NC}"
        exit 1
        ;;
esac

echo ""
echo "${GREEN}🎉 完成！${NC}"
echo ""
echo "下一步:"
echo "1. 登录 App Store Connect"
echo "2. 进入 TestFlight 标签"
echo "3. 等待处理完成 (5-15分钟)"
echo "4. 添加测试人员"
