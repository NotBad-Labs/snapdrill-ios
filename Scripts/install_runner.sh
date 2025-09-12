#!/bin/zsh

# GitHub Actions自托管运行器安装脚本
# 通过环境变量传递配置参数

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "GitHub Actions 自托管运行器安装"
echo "适用于 M4 Mac mini"
echo "=========================================="
echo ""

# 检查必需的环境变量
if [[ -z "${GITHUB_REPO:-}" ]]; then
    echo -e "${RED}错误：请设置环境变量 GITHUB_REPO${NC}"
    echo "示例：export GITHUB_REPO=username/repository"
    exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo -e "${RED}错误：请设置环境变量 GITHUB_TOKEN${NC}"
    echo "示例：export GITHUB_TOKEN=ghp_xxxxxxxxxxxx"
    exit 1
fi

# 设置默认值
RUNNER_NAME="${RUNNER_NAME:-mac-mini-m4}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,macos,m4,xcode-16-4}"
SMB_HOST="${SMB_HOST:-}"
SHARE_NAME="${SHARE_NAME:-}"
SMB_USER="${SMB_USER:-}"

echo "配置信息："
echo "• GitHub仓库：$GITHUB_REPO"
echo "• 运行器名称：$RUNNER_NAME"
echo "• 运行器标签：$RUNNER_LABELS"
if [[ -n "$SMB_HOST" ]]; then
    echo "• 群晖配置：$SMB_HOST/$SHARE_NAME ($SMB_USER)"
else
    echo "• 群晖配置：未配置"
fi
echo ""

# 确认继续
echo "按回车键继续安装，或按Ctrl+C取消..."
read

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

# 4. 配置群晖存储（如果启用）
if [[ -n "$SMB_HOST" ]]; then
    echo -e "${BLUE}[4/6]${NC} 配置群晖存储..."
    
    MOUNT_POINT="/Volumes/runner_data"
    sudo mkdir -p "$MOUNT_POINT"
    
    echo "挂载SMB共享..."
    sudo mount_smbfs "//${SMB_USER}@${SMB_HOST}/${SHARE_NAME}" "$MOUNT_POINT"
    sudo chown -R runner:staff "$MOUNT_POINT"
    
    # 创建缓存目录
    sudo -u runner mkdir -p "$MOUNT_POINT"/{swiftpm,DerivedData,artifacts}
    
    # 创建符号链接
    sudo -u runner mkdir -p /Users/runner/.cache
    sudo -u runner mkdir -p /Users/runner/Library/Developer/Xcode
    
    if [[ ! -L "/Users/runner/.cache/org.swift.swiftpm" ]]; then
        sudo -u runner rm -rf /Users/runner/.cache/org.swift.swiftpm 2>/dev/null || true
        sudo -u runner ln -s "$MOUNT_POINT/swiftpm" /Users/runner/.cache/org.swift.swiftpm
    fi
    
    if [[ ! -L "/Users/runner/Library/Developer/Xcode/DerivedData" ]]; then
        sudo -u runner rm -rf /Users/runner/Library/Developer/Xcode/DerivedData 2>/dev/null || true
        sudo -u runner ln -s "$MOUNT_POINT/DerivedData" /Users/runner/Library/Developer/Xcode/DerivedData
    fi
    
    echo -e "${GREEN}群晖存储配置完成${NC}"
else
    echo -e "${BLUE}[4/6]${NC} 跳过群晖存储配置"
fi

# 5. 安装GitHub Actions运行器
echo -e "${BLUE}[5/6]${NC} 安装GitHub Actions运行器..."
cd /Users/runner

# 下载运行器
echo "下载GitHub Actions运行器..."
curl -o actions-runner-osx-x64-2.328.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.328.0/actions-runner-osx-x64-2.328.0.tar.gz

# 验证下载
echo "验证下载文件..."
echo "90c32dc6f292855339563148f3859dc5d402f237ecdf57010c841df3c8d12cc8  actions-runner-osx-x64-2.328.0.tar.gz" | shasum -a 256 -c

# 解压
echo "解压运行器文件..."
tar xzf ./actions-runner-osx-x64-2.328.0.tar.gz

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
echo "• 名称：$RUNNER_NAME"
echo "• 标签：$RUNNER_LABELS"
echo "• 目录：/Users/runner/actions-runner"
if [[ -n "$SMB_HOST" ]]; then
    echo "• 存储：/Volumes/runner_data"
fi
echo ""
echo "下一步："
echo "1. 访问 GitHub仓库 → Settings → Actions → Runners"
echo "2. 确认运行器显示为 'Online' 状态"
echo "3. 推送代码测试CI/CD流程"
echo ""
echo "常用命令："
echo "• 查看状态：sudo -u runner /Users/runner/actions-runner/svc.sh status"
echo "• 重启服务：sudo /Users/runner/actions-runner/svc.sh restart"
echo "• 查看日志：sudo tail -f /Users/runner/actions-runner/_diag/Runner_*.log"
echo ""
echo "祝您使用愉快！🚀"
