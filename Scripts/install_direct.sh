#!/bin/zsh

# 直接安装GitHub Actions自托管运行器
# 专门为 chramboliao/NotBad 仓库

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置信息
GITHUB_REPO="chramboliao/NotBad"
GITHUB_TOKEN="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"
RUNNER_NAME="mac-mini-m4"
RUNNER_LABELS="self-hosted,macos,m4,xcode-16-4"

echo "=========================================="
echo "GitHub Actions 自托管运行器安装"
echo "仓库: chramboliao/NotBad"
echo "=========================================="
echo ""

echo "配置信息："
echo "• GitHub仓库：$GITHUB_REPO"
echo "• 运行器名称：$RUNNER_NAME"
echo "• 运行器标签：$RUNNER_LABELS"
echo ""

echo "开始安装..."

# 1. 创建runner用户
echo -e "${BLUE}[1/6]${NC} 创建runner用户..."
if id "runner" &>/dev/null; then
    echo -e "${GREEN}用户runner已存在${NC}"
else
    sudo dscl . -create "/Users/runner"
    sudo dscl . -create "/Users/runner" UserShell /bin/zsh
    sudo dscl . -create "/Users/runner" RealName "GitHub Actions Runner"
    sudo dscl . -create "/Users/runner" UniqueID 502
    sudo dscl . -create "/Users/runner" PrimaryGroupID 20
    sudo dscl . -create "/Users/runner" NFSHomeDirectory "/Users/runner"
    sudo dscl . -passwd "/Users/runner" ""
    sudo createhomedir -c -u "runner"
    sudo dscl . -append "/Groups/admin" GroupMembership "runner"
    echo -e "${GREEN}用户runner创建成功${NC}"
fi

# 2. 设置系统环境
echo -e "${BLUE}[2/6]${NC} 配置系统环境..."
sudo systemsetup -setcomputersleep Never 2>/dev/null || true
sudo systemsetup -setdisplaysleep Never 2>/dev/null || true
sudo systemsetup -setharddisksleep Never 2>/dev/null || true
echo -e "${GREEN}系统环境配置完成${NC}"

# 3. 检查Xcode
echo -e "${BLUE}[3/6]${NC} 检查Xcode配置..."
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Xcode未安装，请先安装Xcode${NC}"
    exit 1
fi

# 接受Xcode许可
if /usr/bin/xcodebuild -checkFirstLaunchStatus 2>/dev/null | grep -q 'requiresFirstLaunchExperience'; then
    echo "接受Xcode许可..."
    sudo xcodebuild -license accept
fi

# 下载iOS运行时
echo "下载iOS运行时..."
xcodebuild -downloadPlatform iOS | cat || true
echo -e "${GREEN}Xcode配置完成${NC}"

# 4. 跳过群晖存储配置（简化版本）
echo -e "${BLUE}[4/6]${NC} 跳过群晖存储配置（使用本地存储）"

# 5. 安装GitHub Actions运行器
echo -e "${BLUE}[5/6]${NC} 安装GitHub Actions运行器..."
cd /Users/runner

# 创建运行器目录
echo "创建运行器目录..."
sudo -u runner mkdir -p actions-runner
cd actions-runner

# 下载最新版本的运行器
echo "下载GitHub Actions运行器 (v2.328.0)..."
sudo -u runner curl -o actions-runner-osx-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-osx-x64-2.328.0.tar.gz

# 验证下载
echo "验证下载文件..."
echo "90c32dc6f292855339563148f3859dc5d402f237ecdf57010c841df3c8d12cc8  actions-runner-osx-x64-2.328.0.tar.gz" | sudo -u runner shasum -a 256 -c

# 解压
echo "解压运行器文件..."
sudo -u runner tar xzf ./actions-runner-osx-x64-2.328.0.tar.gz

# 配置运行器
echo "配置运行器..."
sudo -u runner ./config.sh \
    --url "https://github.com/${GITHUB_REPO}" \
    --token "$GITHUB_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --work "_work" \
    --replace \
    --unattended

# 安装为服务
echo "安装运行器服务..."
sudo ./svc install runner
sudo ./svc start

echo -e "${GREEN}GitHub Actions运行器安装完成${NC}"

# 6. 设置基本监控
echo -e "${BLUE}[6/6]${NC} 设置基本监控..."
sudo touch /var/log/runner_monitor.log
sudo chown root:wheel /var/log/runner_monitor.log

# 创建简单的监控脚本
sudo tee /usr/local/bin/check_runner.sh > /dev/null << 'EOF'
#!/bin/bash
if ! sudo -u runner /Users/runner/actions-runner/svc.sh status | grep -q "running"; then
    echo "$(date): Runner service not running, restarting..." >> /var/log/runner_monitor.log
    sudo /Users/runner/actions-runner/svc.sh restart
fi
EOF

sudo chmod +x /usr/local/bin/check_runner.sh

# 添加到crontab
(sudo -u runner crontab -l 2>/dev/null; echo "*/15 * * * * /usr/local/bin/check_runner.sh") | sudo -u runner crontab -

echo -e "${GREEN}基本监控设置完成${NC}"

# 完成
echo ""
echo "=========================================="
echo -e "${GREEN}✅ 安装完成！${NC}"
echo "=========================================="
echo ""
echo "运行器信息："
echo "• 仓库：chramboliao/NotBad"
echo "• 名称：$RUNNER_NAME"
echo "• 标签：$RUNNER_LABELS"
echo "• 目录：/Users/runner/actions-runner"
echo ""
echo "下一步："
echo "1. 访问 https://github.com/chramboliao/NotBad/settings/actions/runners"
echo "2. 确认运行器显示为 'Online' 状态"
echo "3. 在 .github/workflows/ 中使用 runs-on: [self-hosted, macos, m4, xcode-16-4]"
echo ""
echo "常用命令："
echo "• 查看状态：sudo -u runner /Users/runner/actions-runner/svc.sh status"
echo "• 重启服务：sudo /Users/runner/actions-runner/svc.sh restart"
echo "• 查看日志：sudo tail -f /Users/runner/actions-runner/_diag/Runner_*.log"
echo ""
echo "祝您使用愉快！🚀"
