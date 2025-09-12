#!/bin/zsh

# GitHub Actions 自托管运行器安装脚本
# 适用于 M4 Mac mini 16GB/256GB + 群晖存储
# 作者：AI Assistant
# 版本：1.0

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
RUNNER_USER="runner"
RUNNER_HOME="/Users/${RUNNER_USER}"
RUNNER_DIR="${RUNNER_HOME}/actions-runner"
MOUNT_POINT="/Volumes/runner_data"
GITHUB_TOKEN=""
GITHUB_REPO=""
RUNNER_LABELS="self-hosted,macos,m4,xcode-16-4,ios-18-6"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root身份运行
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要以root身份运行此脚本"
        exit 1
    fi
}

# 获取用户输入
get_user_input() {
    echo "=== GitHub Actions 自托管运行器安装程序 ==="
    echo "适用于 M4 Mac mini + 群晖存储环境"
    echo ""
    
    read -p "请输入GitHub仓库（格式：owner/repo，如：username/NotBad）: " GITHUB_REPO
    if [[ -z "$GITHUB_REPO" ]]; then
        log_error "GitHub仓库不能为空"
        exit 1
    fi
    
    read -s -p "请输入GitHub Personal Access Token（需要repo和admin权限）: " GITHUB_TOKEN
    echo ""
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GitHub Token不能为空"
        exit 1
    fi
    
    read -p "请输入群晖SMB主机地址（如：192.168.1.100）: " SMB_HOST
    if [[ -z "$SMB_HOST" ]]; then
        log_error "SMB主机地址不能为空"
        exit 1
    fi
    
    read -p "请输入SMB共享名称（如：runner_data）: " SHARE_NAME
    if [[ -z "$SHARE_NAME" ]]; then
        log_error "SMB共享名称不能为空"
        exit 1
    fi
    
    read -p "请输入SMB用户名: " SMB_USER
    if [[ -z "$SMB_USER" ]]; then
        log_error "SMB用户名不能为空"
        exit 1
    fi
}

# 创建runner用户
create_runner_user() {
    log_info "创建专用runner用户..."
    
    if id "$RUNNER_USER" &>/dev/null; then
        log_warning "用户 $RUNNER_USER 已存在"
    else
        # 创建用户
        sudo dscl . -create "/Users/$RUNNER_USER"
        sudo dscl . -create "/Users/$RUNNER_USER" UserShell /bin/zsh
        sudo dscl . -create "/Users/$RUNNER_USER" RealName "GitHub Actions Runner"
        sudo dscl . -create "/Users/$RUNNER_USER" UniqueID 502
        sudo dscl . -create "/Users/$RUNNER_USER" PrimaryGroupID 20
        sudo dscl . -create "/Users/$RUNNER_USER" NFSHomeDirectory "$RUNNER_HOME"
        sudo dscl . -passwd "/Users/$RUNNER_USER" ""
        
        # 创建主目录
        sudo createhomedir -c -u "$RUNNER_USER"
        
        # 添加到admin组
        sudo dscl . -append "/Groups/admin" GroupMembership "$RUNNER_USER"
        
        log_success "用户 $RUNNER_USER 创建成功"
    fi
}

# 设置系统环境
setup_system() {
    log_info "配置系统环境..."
    
    # 关闭睡眠
    sudo systemsetup -setcomputersleep Never 2>/dev/null || true
    sudo systemsetup -setdisplaysleep Never 2>/dev/null || true
    sudo systemsetup -setharddisksleep Never 2>/dev/null || true
    
    # 设置电源管理
    sudo pmset -a sleep 0
    sudo pmset -a disksleep 0
    sudo pmset -a displaysleep 0
    
    log_success "系统环境配置完成"
}

# 安装Xcode和工具
install_xcode_tools() {
    log_info "检查并安装Xcode工具..."
    
    # 检查Command Line Tools
    if ! xcode-select -p >/dev/null 2>&1; then
        log_info "安装Command Line Tools..."
        xcode-select --install
        echo "请等待Command Line Tools安装完成后按回车继续..."
        read
    fi
    
    # 检查Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "请先安装Xcode 16.4"
        exit 1
    fi
    
    # 接受Xcode许可
    if /usr/bin/xcodebuild -checkFirstLaunchStatus 2>/dev/null | grep -q 'requiresFirstLaunchExperience'; then
        log_info "接受Xcode许可..."
        sudo xcodebuild -license accept
    fi
    
    # 下载iOS运行时
    log_info "下载iOS 18.6运行时..."
    xcodebuild -downloadPlatform iOS || true
    
    log_success "Xcode工具配置完成"
}

# 挂载群晖存储
mount_storage() {
    log_info "配置群晖存储挂载..."
    
    # 创建挂载点
    sudo mkdir -p "$MOUNT_POINT"
    
    # 挂载SMB共享
    log_info "挂载SMB共享 //${SMB_HOST}/${SHARE_NAME} 到 $MOUNT_POINT"
    sudo mount_smbfs "//${SMB_USER}@${SMB_HOST}/${SHARE_NAME}" "$MOUNT_POINT"
    
    # 设置权限
    sudo chown -R "$RUNNER_USER:staff" "$MOUNT_POINT"
    
    log_success "群晖存储挂载完成"
}

# 下载并安装GitHub Actions运行器
install_runner() {
    log_info "下载并安装GitHub Actions运行器..."
    
    # 切换到runner用户目录
    cd "$RUNNER_HOME"
    
    # 下载运行器
    curl -o actions-runner-osx-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz
    
    # 验证下载
    echo "34a8f34956cd546d27e7734ad0b37652b9f9791887edfc4ec6dc8ff376d17f49  actions-runner-osx-x64-2.311.0.tar.gz" | shasum -a 256 -c
    
    # 解压
    tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
    
    # 配置运行器
    sudo -u "$RUNNER_USER" ./config.sh \
        --url "https://github.com/${GITHUB_REPO}" \
        --token "$GITHUB_TOKEN" \
        --name "mac-mini-m4-$(hostname)" \
        --labels "$RUNNER_LABELS" \
        --work "_work" \
        --replace \
        --unattended
    
    log_success "GitHub Actions运行器安装完成"
}

# 设置缓存目录
setup_cache_directories() {
    log_info "设置缓存目录..."
    
    # 在群晖存储上创建目录
    sudo -u "$RUNNER_USER" mkdir -p "$MOUNT_POINT"/{swiftpm,DerivedData,artifacts,logs}
    
    # 创建符号链接
    sudo -u "$RUNNER_USER" mkdir -p "$RUNNER_HOME"/.cache
    sudo -u "$RUNNER_USER" mkdir -p "$RUNNER_HOME"/Library/Developer/Xcode
    
    # 链接SPM缓存
    if [[ ! -L "$RUNNER_HOME/.cache/org.swift.swiftpm" ]]; then
        sudo -u "$RUNNER_USER" rm -rf "$RUNNER_HOME/.cache/org.swift.swiftpm" 2>/dev/null || true
        sudo -u "$RUNNER_USER" ln -s "$MOUNT_POINT/swiftpm" "$RUNNER_HOME/.cache/org.swift.swiftpm"
    fi
    
    # 链接DerivedData
    if [[ ! -L "$RUNNER_HOME/Library/Developer/Xcode/DerivedData" ]]; then
        sudo -u "$RUNNER_USER" rm -rf "$RUNNER_HOME/Library/Developer/Xcode/DerivedData" 2>/dev/null || true
        sudo -u "$RUNNER_USER" ln -s "$MOUNT_POINT/DerivedData" "$RUNNER_HOME/Library/Developer/Xcode/DerivedData"
    fi
    
    log_success "缓存目录设置完成"
}

# 安装为系统服务
install_service() {
    log_info "安装运行器服务..."
    
    cd "$RUNNER_DIR"
    sudo ./svc install "$RUNNER_USER"
    sudo ./svc start
    
    log_success "运行器服务安装并启动完成"
}

# 创建自动挂载脚本
create_automount_script() {
    log_info "创建自动挂载脚本..."
    
    cat > /tmp/automount_runner_data.sh << EOF
#!/bin/zsh
# 自动挂载群晖存储脚本

SMB_HOST="${SMB_HOST}"
SHARE_NAME="${SHARE_NAME}"
SMB_USER="${SMB_USER}"
MOUNT_POINT="${MOUNT_POINT}"

if [[ ! -d "\$MOUNT_POINT" ]]; then
    mkdir -p "\$MOUNT_POINT"
fi

if ! mount | grep -q "\$MOUNT_POINT"; then
    mount_smbfs "//\${SMB_USER}@\${SMB_HOST}/\${SHARE_NAME}" "\$MOUNT_POINT"
    chown -R runner:staff "\$MOUNT_POINT"
fi
EOF
    
    sudo mv /tmp/automount_runner_data.sh /usr/local/bin/automount_runner_data.sh
    sudo chmod +x /usr/local/bin/automount_runner_data.sh
    
    # 创建LaunchAgent
    cat > /tmp/com.github.actions.runner.automount.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.actions.runner.automount</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/automount_runner_data.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
    
    sudo mv /tmp/com.github.actions.runner.automount.plist /Library/LaunchDaemons/
    sudo launchctl load /Library/LaunchDaemons/com.github.actions.runner.automount.plist
    
    log_success "自动挂载脚本创建完成"
}

# 主函数
main() {
    log_info "开始安装GitHub Actions自托管运行器..."
    
    check_root
    get_user_input
    create_runner_user
    setup_system
    install_xcode_tools
    mount_storage
    install_runner
    setup_cache_directories
    install_service
    create_automount_script
    
    log_success "GitHub Actions自托管运行器安装完成！"
    echo ""
    echo "=== 安装摘要 ==="
    echo "• 运行器用户: $RUNNER_USER"
    echo "• 运行器目录: $RUNNER_DIR"
    echo "• 存储挂载点: $MOUNT_POINT"
    echo "• 运行器标签: $RUNNER_LABELS"
    echo ""
    echo "=== 下一步操作 ==="
    echo "1. 在GitHub仓库设置中验证运行器状态"
    echo "2. 运行测试工作流验证配置"
    echo "3. 配置GitHub Secrets（证书、描述文件等）"
    echo ""
    echo "=== 常用命令 ==="
    echo "• 查看运行器状态: sudo -u $RUNNER_USER $RUNNER_DIR/run.sh --check"
    echo "• 重启服务: sudo $RUNNER_DIR/svc restart"
    echo "• 停止服务: sudo $RUNNER_DIR/svc stop"
    echo "• 查看日志: sudo tail -f $RUNNER_DIR/_diag/Runner_*.log"
}

# 运行主函数
main "$@"
