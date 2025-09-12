#!/bin/zsh

# 群晖存储测试脚本
# 目的：验证群晖NAS是否能作为Mac mini的存储，通过SMB挂载方式

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查必要的工具
check_prerequisites() {
    log_info "检查必要工具..."
    
    if ! command -v mount_smbfs &> /dev/null; then
        log_error "mount_smbfs 命令不可用，请确保在 macOS 上运行"
        exit 1
    fi
    
    if ! command -v ping &> /dev/null; then
        log_error "ping 命令不可用"
        exit 1
    fi
    
    log_success "必要工具检查通过"
}

# 测试网络连接
test_network_connectivity() {
    local smb_host="$1"
    
    log_info "测试网络连接到群晖: $smb_host"
    
    if ping -c 3 -W 3000 "$smb_host" > /dev/null 2>&1; then
        log_success "网络连接正常"
        return 0
    else
        log_error "无法连接到群晖 $smb_host"
        return 1
    fi
}

# 测试SMB服务
test_smb_service() {
    local smb_host="$1"
    local share_name="$2"
    
    log_info "测试SMB服务: //$smb_host/$share_name"
    
    # 尝试列出共享（不需要认证）
    if smbutil view //"$smb_host" 2>/dev/null | grep -q "$share_name"; then
        log_success "SMB服务正常，找到共享: $share_name"
        return 0
    else
        log_warning "无法访问SMB服务或未找到共享: $share_name"
        return 1
    fi
}

# 测试挂载
test_mount() {
    local smb_host="$1"
    local share_name="$2"
    local smb_user="$3"
    local mount_point="$4"
    
    log_info "测试挂载: //$smb_user@$smb_host/$share_name -> $mount_point"
    
    # 检查是否已经挂载
    if mount | grep -q "$mount_point"; then
        log_warning "挂载点 $mount_point 已被占用，先卸载..."
        sudo umount "$mount_point" 2>/dev/null || true
    fi
    
    # 创建挂载点
    echo "$SMB_PASSWORD" | sudo -S mkdir -p "$mount_point"
    
    # 尝试挂载
    if echo "$SMB_PASSWORD" | sudo -S mount_smbfs //"$smb_user"@"$smb_host"/"$share_name" "$mount_point" 2>/dev/null; then
        log_success "挂载成功"
        return 0
    else
        log_error "挂载失败"
        return 1
    fi
}

# 测试存储访问
test_storage_access() {
    local mount_point="$1"
    
    log_info "测试存储访问权限..."
    
    # 测试读取权限
    if [ -r "$mount_point" ]; then
        log_success "读取权限正常"
    else
        log_error "无法读取挂载点"
        return 1
    fi
    
    # 测试写入权限
    local test_file="$mount_point/test_write_$(date +%s).txt"
    if echo "测试写入 $(date)" > "$test_file" 2>/dev/null; then
        log_success "写入权限正常"
        rm -f "$test_file"
    else
        log_error "无法写入挂载点"
        return 1
    fi
    
    # 测试目录创建
    local test_dir="$mount_point/test_dir_$(date +%s)"
    if mkdir "$test_dir" 2>/dev/null; then
        log_success "目录创建权限正常"
        rmdir "$test_dir"
    else
        log_error "无法在挂载点创建目录"
        return 1
    fi
    
    # 显示存储信息
    log_info "存储信息:"
    df -h "$mount_point" | tail -1
}

# 测试CI相关目录结构
test_ci_directories() {
    local mount_point="$1"
    
    log_info "测试CI相关目录结构..."
    
    local dirs=(
        "$mount_point/artifacts"
        "$mount_point/test-results"
        "$mount_point/performance-results"
        "$mount_point/ui-test-results"
        "$mount_point/build-artifacts"
    )
    
    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            log_success "创建目录: $dir"
        else
            log_error "无法创建目录: $dir"
            return 1
        fi
    done
    
    # 测试在artifacts目录中创建文件
    local test_artifact="$mount_point/artifacts/test_artifact.txt"
    if echo "CI测试文件 $(date)" > "$test_artifact" 2>/dev/null; then
        log_success "artifacts目录写入测试通过"
        rm -f "$test_artifact"
    else
        log_error "artifacts目录写入测试失败"
        return 1
    fi
}

# 清理测试
cleanup() {
    local mount_point="$1"
    
    log_info "清理测试环境..."
    
    # 卸载挂载点
    if mount | grep -q "$mount_point"; then
        echo "$SMB_PASSWORD" | sudo -S umount "$mount_point" 2>/dev/null || true
        log_info "已卸载: $mount_point"
    fi
    
    # 清理测试文件
    find "$mount_point" -name "test_*" -type f -delete 2>/dev/null || true
    find "$mount_point" -name "test_*" -type d -exec rmdir {} + 2>/dev/null || true
}

# 主函数
main() {
    echo "=========================================="
    echo "群晖存储挂载测试脚本"
    echo "=========================================="
    
    # 从环境变量或用户输入获取配置
    local smb_host="${SMB_HOST:-}"
    local share_name="${SHARE_NAME:-}"
    local smb_user="${SMB_USER:-}"
    local smb_password="${SMB_PASSWORD:-}"
    local mount_point="/Volumes/runner_data"
    
    # 如果环境变量未设置，提示用户输入
    if [ -z "$smb_host" ]; then
        echo -n "请输入群晖IP地址 (默认: 192.168.1.211): "
        read smb_host
        smb_host="${smb_host:-192.168.1.211}"
    fi
    
    if [ -z "$share_name" ]; then
        echo -n "请输入共享名称 (默认: runner_data): "
        read share_name
        share_name="${share_name:-runner_data}"
    fi
    
    if [ -z "$smb_user" ]; then
        echo -n "请输入SMB用户名 (默认: chbearxiong): "
        read smb_user
        smb_user="${smb_user:-chbearxiong}"
    fi
    
    if [ -z "$smb_password" ]; then
        echo -n "请输入SMB密码: "
        read -s smb_password
        echo
    fi
    
    # 设置环境变量
    export SMB_PASSWORD="$smb_password"
    
    echo
    log_info "测试配置:"
    echo "  群晖IP: $smb_host"
    echo "  共享名称: $share_name"
    echo "  用户名: $smb_user"
    echo "  挂载点: $mount_point"
    echo
    
    # 执行测试
    local test_passed=0
    
    check_prerequisites || test_passed=1
    
    if [ $test_passed -eq 0 ]; then
        test_network_connectivity "$smb_host" || test_passed=1
    fi
    
    if [ $test_passed -eq 0 ]; then
        test_smb_service "$smb_host" "$share_name" || test_passed=1
    fi
    
    if [ $test_passed -eq 0 ]; then
        test_mount "$smb_host" "$share_name" "$smb_user" "$mount_point" || test_passed=1
    fi
    
    if [ $test_passed -eq 0 ]; then
        test_storage_access "$mount_point" || test_passed=1
    fi
    
    if [ $test_passed -eq 0 ]; then
        test_ci_directories "$mount_point" || test_passed=1
    fi
    
    # 清理
    cleanup "$mount_point"
    
    echo
    echo "=========================================="
    if [ $test_passed -eq 0 ]; then
        log_success "所有测试通过！群晖存储可以正常作为Mac mini的存储使用。"
        echo
        log_info "建议的下一步操作:"
        echo "1. 在GitHub Secrets中配置以下变量:"
        echo "   - SMB_HOST: $smb_host"
        echo "   - SHARE_NAME: $share_name"
        echo "   - SMB_USER: $smb_user"
        echo "   - SMB_PASSWORD: [您的密码]"
        echo
        echo "2. 在Mac mini上设置开机自动挂载:"
        echo "   - 将挂载脚本添加到登录项"
        echo "   - 或使用cron定时任务"
        echo
        echo "3. 运行CI测试验证完整流程"
    else
        log_error "测试失败！请检查网络连接和群晖配置。"
        echo
        log_info "常见问题排查:"
        echo "1. 检查群晖SMB服务是否启用"
        echo "2. 检查用户权限设置"
        echo "3. 检查防火墙设置"
        echo "4. 检查网络连接"
    fi
    echo "=========================================="
    
    exit $test_passed
}

# 运行主函数
main "$@"
