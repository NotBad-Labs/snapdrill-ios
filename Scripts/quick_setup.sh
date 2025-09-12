#!/bin/zsh

# GitHub Actions 自托管运行器快速安装脚本
# 一键完成所有配置和安装
# 作者：AI Assistant
# 版本：1.0

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# 显示欢迎信息
show_welcome() {
    echo "=========================================="
    echo "GitHub Actions 自托管运行器快速安装"
    echo "适用于 M4 Mac mini + 群晖存储"
    echo "=========================================="
    echo ""
    echo "此脚本将完成以下操作："
    echo "1. 创建专用runner用户"
    echo "2. 安装和配置GitHub Actions运行器"
    echo "3. 设置群晖存储挂载和缓存目录"
    echo "4. 配置自动监控和维护任务"
    echo "5. 优化GitHub Actions工作流"
    echo ""
}

# 检查系统要求
check_system_requirements() {
    log_info "检查系统要求..."
    
    # 检查macOS版本
    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    local minor_version=$(echo "$macos_version" | cut -d. -f2)
    
    if [ "$major_version" -lt 14 ]; then
        log_error "需要macOS 14.0或更高版本，当前版本：$macos_version"
        exit 1
    fi
    
    log_success "macOS版本检查通过：$macos_version"
    
    # 检查内存
    local total_memory=$(sysctl -n hw.memsize)
    local memory_gb=$((total_memory / 1024 / 1024 / 1024))
    
    if [ "$memory_gb" -lt 16 ]; then
        log_warning "推荐16GB或更多内存，当前内存：${memory_gb}GB"
    else
        log_success "内存检查通过：${memory_gb}GB"
    fi
    
    # 检查磁盘空间
    local disk_space=$(df -h / | tail -1 | awk '{print $4}')
    log_info "可用磁盘空间：$disk_space"
    
    # 检查网络连接
    if ping -c 3 github.com > /dev/null 2>&1; then
        log_success "网络连接检查通过"
    else
        log_error "无法连接到GitHub，请检查网络连接"
        exit 1
    fi
}

# 获取用户输入
get_user_input() {
    echo ""
    echo "=== 配置信息输入 ==="
    
    # GitHub配置
    echo ""
    echo "GitHub配置："
    read -p "GitHub仓库地址（格式：owner/repo）: " GITHUB_REPO
    if [[ -z "$GITHUB_REPO" ]]; then
        log_error "GitHub仓库地址不能为空"
        exit 1
    fi
    
    read -s -p "GitHub Personal Access Token: " GITHUB_TOKEN
    echo ""
    if [[ -z "$GITHUB_TOKEN" ]]; then
        log_error "GitHub Token不能为空"
        exit 1
    fi
    
    # 群晖配置
    echo ""
    echo "群晖存储配置："
    read -p "群晖IP地址: " SMB_HOST
    if [[ -z "$SMB_HOST" ]]; then
        log_error "群晖IP地址不能为空"
        exit 1
    fi
    
    read -p "SMB共享名称: " SHARE_NAME
    if [[ -z "$SHARE_NAME" ]]; then
        log_error "SMB共享名称不能为空"
        exit 1
    fi
    
    read -p "SMB用户名: " SMB_USER
    if [[ -z "$SMB_USER" ]]; then
        log_error "SMB用户名不能为空"
        exit 1
    fi
    
    # 运行器配置
    echo ""
    echo "运行器配置："
    read -p "运行器名称（默认：mac-mini-m4）: " RUNNER_NAME
    RUNNER_NAME=${RUNNER_NAME:-mac-mini-m4}
    
    read -p "运行器标签（默认：self-hosted,macos,m4,xcode-16-4）: " RUNNER_LABELS
    RUNNER_LABELS=${RUNNER_LABELS:-self-hosted,macos,m4,xcode-16-4}
}

# 确认安装
confirm_installation() {
    echo ""
    echo "=== 安装确认 ==="
    echo "GitHub仓库：$GITHUB_REPO"
    echo "群晖地址：$SMB_HOST"
    echo "SMB共享：$SHARE_NAME"
    echo "SMB用户：$SMB_USER"
    echo "运行器名称：$RUNNER_NAME"
    echo "运行器标签：$RUNNER_LABELS"
    echo ""
    
    read -p "确认开始安装？(y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "安装已取消"
        exit 0
    fi
}

# 执行安装步骤
run_installation() {
    log_info "开始安装GitHub Actions自托管运行器..."
    
    # 1. 设置脚本权限
    log_info "设置脚本权限..."
    chmod +x "$SCRIPT_DIR"/*.sh
    
    # 2. 运行安装脚本
    log_info "运行主安装脚本..."
    export GITHUB_REPO GITHUB_TOKEN SMB_HOST SHARE_NAME SMB_USER RUNNER_NAME RUNNER_LABELS
    "$SCRIPT_DIR/install_self_hosted_runner.sh"
    
    # 3. 设置定时任务
    log_info "配置定时任务..."
    "$SCRIPT_DIR/setup_cron_jobs.sh"
    
    log_success "安装完成！"
}

# 验证安装
verify_installation() {
    log_info "验证安装结果..."
    
    # 检查运行器状态
    if sudo -u runner /Users/runner/actions-runner/svc.sh status | grep -q "running"; then
        log_success "运行器服务正在运行"
    else
        log_error "运行器服务未运行"
        return 1
    fi
    
    # 检查存储挂载
    if mount | grep -q "/Volumes/runner_data"; then
        log_success "群晖存储已挂载"
    else
        log_error "群晖存储未挂载"
        return 1
    fi
    
    # 检查定时任务
    if sudo -u runner crontab -l | grep -q "runner_monitor.sh"; then
        log_success "定时任务已配置"
    else
        log_warning "定时任务未配置"
    fi
    
    # 检查LaunchAgents
    if sudo launchctl list | grep -q "automount"; then
        log_success "LaunchAgents已配置"
    else
        log_warning "LaunchAgents未配置"
    fi
    
    return 0
}

# 显示后续步骤
show_next_steps() {
    echo ""
    echo "=== 安装完成 ==="
    echo ""
    echo "✅ GitHub Actions自托管运行器已成功安装！"
    echo ""
    echo "=== 下一步操作 ==="
    echo ""
    echo "1. 验证运行器状态："
    echo "   访问 GitHub仓库 → Settings → Actions → Runners"
    echo "   确认运行器显示为 'Online' 状态"
    echo ""
    echo "2. 测试工作流："
    echo "   推送代码到仓库，观察CI/CD流程是否正常"
    echo ""
    echo "3. 配置GitHub Secrets（如需要）："
    echo "   - BUILD_CERTIFICATE_BASE64"
    echo "   - P12_PASSWORD"
    echo "   - KEYCHAIN_PASSWORD"
    echo "   - PROVISIONING_PROFILE_BASE64"
    echo "   - APPLEID_USERNAME"
    echo "   - APPLEID_PASSWORD"
    echo ""
    echo "4. 监控和维护："
    echo "   - 监控日志：tail -f /var/log/runner_monitor.log"
    echo "   - 手动维护：sudo $SCRIPT_DIR/runner_maintenance.sh daily"
    echo "   - 生成报告：sudo $SCRIPT_DIR/runner_monitor.sh --report"
    echo ""
    echo "=== 重要文件位置 ==="
    echo "• 运行器目录：/Users/runner/actions-runner"
    echo "• 存储挂载点：/Volumes/runner_data"
    echo "• 日志文件：/var/log/runner_*.log"
    echo "• 配置文档：$SCRIPT_DIR/../docs/ci-cd/self-hosted-runner-setup-guide.md"
    echo ""
    echo "=== 技术支持 ==="
    echo "如遇到问题，请："
    echo "1. 查看相关日志文件"
    echo "2. 运行诊断脚本"
    echo "3. 参考完整文档"
    echo ""
    echo "祝您使用愉快！🚀"
}

# 错误处理
handle_error() {
    log_error "安装过程中发生错误"
    echo ""
    echo "请检查以下项目："
    echo "1. 网络连接是否正常"
    echo "2. GitHub Token是否有足够权限"
    echo "3. 群晖SMB服务是否正常"
    echo "4. 系统是否有足够权限"
    echo ""
    echo "可以查看日志文件获取更多信息："
    echo "• 安装日志：/var/log/install.log"
    echo "• 运行器日志：/Users/runner/actions-runner/_diag/Runner_*.log"
    exit 1
}

# 主函数
main() {
    # 设置错误处理
    trap handle_error ERR
    
    show_welcome
    check_system_requirements
    get_user_input
    confirm_installation
    run_installation
    
    if verify_installation; then
        show_next_steps
    else
        log_error "安装验证失败，请检查日志"
        exit 1
    fi
}

# 处理命令行参数
case "${1:-}" in
    --help)
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --help    显示此帮助信息"
        echo ""
        echo "此脚本将交互式地引导您完成GitHub Actions自托管运行器的安装。"
        ;;
    *)
        main
        ;;
esac
