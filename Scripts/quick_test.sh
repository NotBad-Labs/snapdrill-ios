#!/bin/zsh

# 快速环境测试脚本
# 简单检查Mac mini是否适合运行自托管GitHub Actions运行器

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "GitHub Actions 自托管运行器快速测试"
echo "=========================================="
echo ""

# 检查macOS版本
echo -e "${BLUE}[检查]${NC} macOS版本..."
macos_version=$(sw_vers -productVersion)
echo "   版本: $macos_version"
if [[ "$macos_version" =~ ^1[4-9]\. ]]; then
    echo -e "   ${GREEN}✓ 版本支持${NC}"
else
    echo -e "   ${RED}✗ 版本过低，需要14.0+${NC}"
fi
echo ""

# 检查硬件
echo -e "${BLUE}[检查]${NC} 硬件配置..."
cpu_info=$(sysctl -n machdep.cpu.brand_string)
memory_gb=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
echo "   CPU: $cpu_info"
echo "   内存: ${memory_gb}GB"

if [[ "$cpu_info" =~ "Apple" ]]; then
    echo -e "   ${GREEN}✓ Apple Silicon处理器${NC}"
else
    echo -e "   ${YELLOW}⚠ Intel处理器（建议Apple Silicon）${NC}"
fi

if [ "$memory_gb" -ge 16 ]; then
    echo -e "   ${GREEN}✓ 内存充足${NC}"
elif [ "$memory_gb" -ge 8 ]; then
    echo -e "   ${YELLOW}⚠ 内存较低，建议16GB+${NC}"
else
    echo -e "   ${RED}✗ 内存不足，需要8GB+${NC}"
fi
echo ""

# 检查存储空间
echo -e "${BLUE}[检查]${NC} 存储空间..."
disk_info=$(df -h / | tail -1)
disk_used=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
echo "   使用情况: $disk_info"

if [ "$disk_used" -lt 80 ]; then
    echo -e "   ${GREEN}✓ 存储空间充足${NC}"
elif [ "$disk_used" -lt 90 ]; then
    echo -e "   ${YELLOW}⚠ 存储空间较紧${NC}"
else
    echo -e "   ${RED}✗ 存储空间不足${NC}"
fi
echo ""

# 检查网络连接
echo -e "${BLUE}[检查]${NC} 网络连接..."
if ping -c 2 github.com > /dev/null 2>&1; then
    echo -e "   ${GREEN}✓ GitHub连接正常${NC}"
else
    echo -e "   ${RED}✗ 无法连接GitHub${NC}"
fi
echo ""

# 检查Xcode
echo -e "${BLUE}[检查]${NC} Xcode安装..."
if command -v xcodebuild &> /dev/null; then
    xcode_version=$(xcodebuild -version | head -n 1)
    echo "   版本: $xcode_version"
    if echo "$xcode_version" | grep -q "Xcode 1[5-6]"; then
        echo -e "   ${GREEN}✓ Xcode版本支持${NC}"
    else
        echo -e "   ${YELLOW}⚠ Xcode版本较旧${NC}"
    fi
else
    echo -e "   ${RED}✗ Xcode未安装${NC}"
fi
echo ""

# 检查模拟器
echo -e "${BLUE}[检查]${NC} iOS模拟器..."
simulator_count=$(xcrun simctl list devices available 2>/dev/null | grep -c "iPhone\|iPad" || echo "0")
echo "   可用模拟器: ${simulator_count}个"

if [ "$simulator_count" -ge 3 ]; then
    echo -e "   ${GREEN}✓ 模拟器充足${NC}"
elif [ "$simulator_count" -ge 1 ]; then
    echo -e "   ${YELLOW}⚠ 模拟器较少${NC}"
else
    echo -e "   ${RED}✗ 模拟器不足${NC}"
fi
echo ""

# 检查权限
echo -e "${BLUE}[检查]${NC} 系统权限..."
if groups | grep -q admin; then
    echo -e "   ${GREEN}✓ 管理员权限${NC}"
else
    echo -e "   ${RED}✗ 无管理员权限${NC}"
fi

if sudo -n true 2>/dev/null; then
    echo -e "   ${GREEN}✓ sudo权限${NC}"
else
    echo -e "   ${YELLOW}⚠ 需要sudo权限${NC}"
fi
echo ""

# 总结
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo ""
echo "如果大部分项目都显示 ✓ 或 ⚠，您的Mac mini适合运行自托管GitHub Actions运行器。"
echo ""
echo "下一步："
echo "1. 运行 'sudo ./Scripts/quick_setup.sh' 开始安装"
echo "2. 或运行 'sudo ./Scripts/test_environment.sh' 进行详细测试"
echo ""
