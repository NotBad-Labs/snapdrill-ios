#!/bin/zsh

set -euo pipefail

echo "# Project Structure Analysis"
echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "## 📊 文件统计"
echo "- Swift 文件: $(find . -name "*.swift" | wc -l | tr -d ' ')"
echo "- 测试文件: $(find . -name "*Test*.swift" | wc -l | tr -d ' ')"
echo "- 配置文件: $(find . -name "*.yml" -o -name "*.yaml" -o -name "*.json" | wc -l | tr -d ' ')"
echo "- 文档文件: $(find . -name "*.md" | wc -l | tr -d ' ')"
echo ""

echo "## 📦 大文件 TOP 10"
find . -type f -not -path "*/.git/*" -exec ls -lh {} \; 2>/dev/null | sort -k5 -rh | head -10

echo ""
echo "## 🗑️ 潜在清理目标"
echo "### 临时文件"
find . -name "*.tmp" -o -name "*.bak" -o -name ".DS_Store" 2>/dev/null | head -20

echo ""
echo "### 构建产物"
find . -path "*/DerivedData/*" -o -path "*/build/*" 2>/dev/null | head -20

echo ""
echo "### 重复文件 (按 MD5 指纹)"
if command -v md5 >/dev/null 2>&1; then
  find . -type f -not -path "*/.git/*" -exec md5 {} \; 2>/dev/null | sort | uniq -d -w32 || true
else
  echo "md5 命令不可用，跳过"
fi
