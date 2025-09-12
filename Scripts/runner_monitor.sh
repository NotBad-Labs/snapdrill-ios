#!/bin/zsh

# GitHub Actions 自托管运行器监控脚本
# 用于监控运行器状态、存储空间、系统资源等
# 作者：AI Assistant
# 版本：1.0

set -euo pipefail

# 配置变量
RUNNER_USER="runner"
RUNNER_DIR="/Users/${RUNNER_USER}/actions-runner"
MOUNT_POINT="/Volumes/runner_data"
LOG_FILE="/var/log/runner_monitor.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 检查运行器状态
check_runner_status() {
    log_info "检查GitHub Actions运行器状态..."
    
    if [ -f "$RUNNER_DIR/svc.sh" ]; then
        if sudo -u "$RUNNER_USER" "$RUNNER_DIR/svc.sh" status | grep -q "running"; then
            log_success "运行器服务正在运行"
            return 0
        else
            log_error "运行器服务未运行"
            return 1
        fi
    else
        log_error "运行器目录不存在: $RUNNER_DIR"
        return 1
    fi
}

# 检查存储挂载状态
check_storage_mount() {
    log_info "检查群晖存储挂载状态..."
    
    if mount | grep -q "$MOUNT_POINT"; then
        # 获取存储空间信息
        local storage_info=$(df -h "$MOUNT_POINT" | tail -1)
        local used_percent=$(echo "$storage_info" | awk '{print $5}' | sed 's/%//')
        
        log_success "存储已挂载: $storage_info"
        
        if [ "$used_percent" -gt 90 ]; then
            log_warning "存储空间使用率过高: ${used_percent}%"
            return 1
        elif [ "$used_percent" -gt 80 ]; then
            log_warning "存储空间使用率较高: ${used_percent}%"
            return 0
        else
            log_success "存储空间充足: ${used_percent}%"
            return 0
        fi
    else
        log_error "存储未挂载: $MOUNT_POINT"
        return 1
    fi
}

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源..."
    
    # CPU使用率
    local cpu_usage=$(top -l 1 -s 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    log_info "CPU使用率: ${cpu_usage}%"
    
    # 内存使用率
    local memory_info=$(vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+):\s+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);')
    local memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
    log_info "内存可用率: ${memory_pressure}%"
    
    # 磁盘空间（本地）
    local disk_info=$(df -h / | tail -1)
    local disk_used_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
    log_info "本地磁盘使用率: ${disk_used_percent}% - $disk_info"
    
    if [ "$disk_used_percent" -gt 90 ]; then
        log_warning "本地磁盘空间不足: ${disk_used_percent}%"
        return 1
    fi
    
    return 0
}

# 检查Xcode和模拟器状态
check_xcode_simulators() {
    log_info "检查Xcode和模拟器状态..."
    
    # 检查Xcode版本
    if command -v xcodebuild &> /dev/null; then
        local xcode_version=$(xcodebuild -version | head -n 1)
        log_info "Xcode版本: $xcode_version"
    else
        log_error "Xcode未安装或不在PATH中"
        return 1
    fi
    
    # 检查可用模拟器
    local simulator_count=$(xcrun simctl list devices available | grep -c "iPhone\|iPad")
    log_info "可用模拟器数量: $simulator_count"
    
    if [ "$simulator_count" -lt 2 ]; then
        log_warning "可用模拟器数量较少"
        return 1
    fi
    
    return 0
}

# 检查网络连接
check_network_connectivity() {
    log_info "检查网络连接..."
    
    # 检查GitHub连接
    if ping -c 3 github.com > /dev/null 2>&1; then
        log_success "GitHub连接正常"
    else
        log_error "无法连接到GitHub"
        return 1
    fi
    
    # 检查群晖连接
    if ping -c 3 $(echo "$MOUNT_POINT" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+') > /dev/null 2>&1; then
        log_success "群晖连接正常"
    else
        log_error "无法连接到群晖"
        return 1
    fi
    
    return 0
}

# 清理缓存和临时文件
cleanup_system() {
    log_info "执行系统清理..."
    
    # 清理DerivedData
    local derived_data_size=$(du -sh "$MOUNT_POINT/DerivedData" 2>/dev/null | awk '{print $1}' || echo "0")
    log_info "DerivedData大小: $derived_data_size"
    
    # 清理旧的模拟器设备
    local old_devices=$(xcrun simctl list devices | grep "Shutdown" | wc -l)
    if [ "$old_devices" -gt 10 ]; then
        log_info "清理旧模拟器设备..."
        xcrun simctl delete unavailable 2>/dev/null || true
        log_success "已清理旧模拟器设备"
    fi
    
    # 清理系统日志
    local log_size=$(du -sh /var/log | awk '{print $1}')
    log_info "系统日志大小: $log_size"
    
    # 清理临时文件
    sudo rm -rf /tmp/com.apple.dt.Xcode.* 2>/dev/null || true
    sudo rm -rf /tmp/org.swift.swiftpm.* 2>/dev/null || true
    
    log_success "系统清理完成"
}

# 重启运行器服务
restart_runner() {
    log_info "重启GitHub Actions运行器服务..."
    
    if [ -f "$RUNNER_DIR/svc.sh" ]; then
        sudo "$RUNNER_DIR/svc.sh" restart
        sleep 5
        
        if check_runner_status; then
            log_success "运行器服务重启成功"
            return 0
        else
            log_error "运行器服务重启失败"
            return 1
        fi
    else
        log_error "运行器服务脚本不存在"
        return 1
    fi
}

# 生成监控报告
generate_report() {
    log_info "生成监控报告..."
    
    local report_file="/tmp/runner_monitor_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
GitHub Actions 自托管运行器监控报告
生成时间: $(date)
主机名: $(hostname)
系统版本: $(sw_vers -productName) $(sw_vers -productVersion)

=== 运行器状态 ===
EOF
    
    if check_runner_status; then
        echo "✅ 运行器服务: 正常" >> "$report_file"
    else
        echo "❌ 运行器服务: 异常" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

=== 存储状态 ===
EOF
    
    if check_storage_mount; then
        echo "✅ 群晖存储: 正常" >> "$report_file"
    else
        echo "❌ 群晖存储: 异常" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

=== 系统资源 ===
CPU使用率: $(top -l 1 -s 0 | grep "CPU usage" | awk '{print $3}')
内存可用率: $(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}')
本地磁盘: $(df -h / | tail -1)

=== Xcode和模拟器 ===
Xcode版本: $(xcodebuild -version | head -n 1)
可用模拟器数量: $(xcrun simctl list devices available | grep -c "iPhone\|iPad")

=== 网络连接 ===
GitHub连接: $(ping -c 1 github.com > /dev/null 2>&1 && echo "正常" || echo "异常")
群晖连接: $(ping -c 1 $(mount | grep "$MOUNT_POINT" | awk '{print $1}' | sed 's|//.*@||; s|/.*||') > /dev/null 2>&1 && echo "正常" || echo "异常")

=== 最近运行记录 ===
EOF
    
    if [ -f "$LOG_FILE" ]; then
        tail -20 "$LOG_FILE" >> "$report_file"
    fi
    
    echo "监控报告已生成: $report_file"
    cat "$report_file"
}

# 主监控函数
main() {
    local exit_code=0
    
    echo "=== GitHub Actions 自托管运行器监控 ==="
    echo "监控时间: $(date)"
    echo ""
    
    # 检查各项状态
    check_runner_status || exit_code=1
    check_storage_mount || exit_code=1
    check_system_resources || exit_code=1
    check_xcode_simulators || exit_code=1
    check_network_connectivity || exit_code=1
    
    echo ""
    echo "=== 监控完成 ==="
    
    if [ $exit_code -eq 0 ]; then
        log_success "所有检查项正常"
    else
        log_error "发现异常项目，请检查日志"
        
        # 询问是否重启运行器
        if [ "$1" = "--auto-restart" ]; then
            log_info "自动重启运行器服务..."
            restart_runner
        fi
    fi
    
    # 生成报告
    generate_report
    
    return $exit_code
}

# 处理命令行参数
case "${1:-}" in
    --cleanup)
        cleanup_system
        ;;
    --restart)
        restart_runner
        ;;
    --report)
        generate_report
        ;;
    --auto-restart)
        main --auto-restart
        ;;
    --help)
        echo "用法: $0 [选项]"
        echo "选项:"
        echo "  --cleanup      执行系统清理"
        echo "  --restart      重启运行器服务"
        echo "  --report       生成监控报告"
        echo "  --auto-restart 监控并自动重启（如果异常）"
        echo "  --help         显示此帮助信息"
        ;;
    *)
        main
        ;;
esac
