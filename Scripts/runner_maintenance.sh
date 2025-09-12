#!/bin/zsh

# GitHub Actions 自托管运行器维护脚本
# 用于定期维护、清理和优化运行器环境
# 作者：AI Assistant
# 版本：1.0

set -euo pipefail

# 配置变量
RUNNER_USER="runner"
RUNNER_DIR="/Users/${RUNNER_USER}/actions-runner"
MOUNT_POINT="/Volumes/runner_data"
BACKUP_DIR="$MOUNT_POINT/backups"
LOG_FILE="/var/log/runner_maintenance.log"

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

# 清理DerivedData
cleanup_derived_data() {
    log_info "清理DerivedData缓存..."
    
    local derived_data_dir="$MOUNT_POINT/DerivedData"
    local before_size=$(du -sh "$derived_data_dir" 2>/dev/null | awk '{print $1}' || echo "0")
    
    # 清理30天前的DerivedData
    find "$derived_data_dir" -type d -name "*.xcodebuild" -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    
    local after_size=$(du -sh "$derived_data_dir" 2>/dev/null | awk '{print $1}' || echo "0")
    log_success "DerivedData清理完成: $before_size -> $after_size"
}

# 清理Swift Package Manager缓存
cleanup_swiftpm_cache() {
    log_info "清理Swift Package Manager缓存..."
    
    local swiftpm_cache_dir="$MOUNT_POINT/swiftpm"
    local before_size=$(du -sh "$swiftpm_cache_dir" 2>/dev/null | awk '{print $1}' || echo "0")
    
    # 清理30天前的SPM缓存
    find "$swiftpm_cache_dir" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    
    local after_size=$(du -sh "$swiftpm_cache_dir" 2>/dev/null | awk '{print $1}' || echo "0")
    log_success "SwiftPM缓存清理完成: $before_size -> $after_size"
}

# 清理模拟器数据
cleanup_simulators() {
    log_info "清理模拟器数据..."
    
    # 删除不可用的模拟器
    xcrun simctl delete unavailable 2>/dev/null || true
    
    # 清理模拟器日志
    local simulator_logs_dir="$HOME/Library/Logs/CoreSimulator"
    if [ -d "$simulator_logs_dir" ]; then
        find "$simulator_logs_dir" -type f -mtime +7 -delete 2>/dev/null || true
    fi
    
    # 清理模拟器设备数据（保留最近10个）
    local device_count=$(xcrun simctl list devices | grep -c "Shutdown")
    if [ "$device_count" -gt 10 ]; then
        log_info "清理多余的模拟器设备..."
        xcrun simctl list devices | grep "Shutdown" | head -n -10 | awk '{print $NF}' | while read device_id; do
            xcrun simctl delete "$device_id" 2>/dev/null || true
        done
    fi
    
    log_success "模拟器数据清理完成"
}

# 清理测试结果和构建产物
cleanup_artifacts() {
    log_info "清理测试结果和构建产物..."
    
    # 清理30天前的测试结果
    find "$MOUNT_POINT/test-results" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    
    # 清理30天前的性能测试结果
    find "$MOUNT_POINT/performance-results" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    
    # 清理30天前的UI测试结果
    find "$MOUNT_POINT/ui-test-results" -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true
    
    # 清理60天前的构建产物（保留更长时间）
    find "$MOUNT_POINT/build-artifacts" -type d -mtime +60 -exec rm -rf {} + 2>/dev/null || true
    
    log_success "测试结果和构建产物清理完成"
}

# 清理系统临时文件
cleanup_system_temp() {
    log_info "清理系统临时文件..."
    
    # 清理Xcode临时文件
    sudo rm -rf /tmp/com.apple.dt.Xcode.* 2>/dev/null || true
    sudo rm -rf /tmp/org.swift.swiftpm.* 2>/dev/null || true
    
    # 清理用户临时文件
    rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/Archives 2>/dev/null || true
    
    # 清理系统日志（保留最近7天）
    sudo find /var/log -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    log_success "系统临时文件清理完成"
}

# 备份重要配置
backup_configurations() {
    log_info "备份重要配置..."
    
    mkdir -p "$BACKUP_DIR"
    local backup_timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_DIR/backup_$backup_timestamp"
    
    mkdir -p "$backup_dir"
    
    # 备份运行器配置
    if [ -d "$RUNNER_DIR" ]; then
        cp -r "$RUNNER_DIR" "$backup_dir/actions-runner" 2>/dev/null || true
    fi
    
    # 备份系统配置
    sudo cp /etc/hosts "$backup_dir/hosts" 2>/dev/null || true
    sudo cp /etc/pf.conf "$backup_dir/pf.conf" 2>/dev/null || true
    
    # 备份用户配置
    cp -r ~/.zshrc "$backup_dir/zshrc" 2>/dev/null || true
    cp -r ~/.gitconfig "$backup_dir/gitconfig" 2>/dev/null || true
    
    # 压缩备份
    tar -czf "$backup_dir.tar.gz" -C "$BACKUP_DIR" "backup_$backup_timestamp"
    rm -rf "$backup_dir"
    
    log_success "配置备份完成: $backup_dir.tar.gz"
}

# 优化系统性能
optimize_system() {
    log_info "优化系统性能..."
    
    # 重建Spotlight索引（如果需要）
    if [ "$1" = "--rebuild-spotlight" ]; then
        log_info "重建Spotlight索引..."
        sudo mdutil -E / 2>/dev/null || true
    fi
    
    # 清理DNS缓存
    sudo dscacheutil -flushcache 2>/dev/null || true
    
    # 优化虚拟内存
    sudo sysctl vm.swappiness=10 2>/dev/null || true
    
    log_success "系统性能优化完成"
}

# 检查并修复权限
fix_permissions() {
    log_info "检查并修复权限..."
    
    # 修复运行器目录权限
    if [ -d "$RUNNER_DIR" ]; then
        sudo chown -R "$RUNNER_USER:staff" "$RUNNER_DIR"
        sudo chmod -R 755 "$RUNNER_DIR"
    fi
    
    # 修复挂载点权限
    if [ -d "$MOUNT_POINT" ]; then
        sudo chown -R "$RUNNER_USER:staff" "$MOUNT_POINT"
        sudo chmod -R 755 "$MOUNT_POINT"
    fi
    
    log_success "权限修复完成"
}

# 更新运行器
update_runner() {
    log_info "检查运行器更新..."
    
    local current_version=$(cat "$RUNNER_DIR/run.sh" | grep "GitHub Actions Runner" | head -1 | sed 's/.*v//' | awk '{print $1}')
    log_info "当前运行器版本: $current_version"
    
    # 这里可以添加自动更新逻辑
    # 目前手动更新，避免意外中断服务
    log_warning "如需更新运行器，请手动下载最新版本并替换"
}

# 生成维护报告
generate_maintenance_report() {
    log_info "生成维护报告..."
    
    local report_file="/tmp/runner_maintenance_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
GitHub Actions 自托管运行器维护报告
维护时间: $(date)
主机名: $(hostname)

=== 存储使用情况 ===
总存储: $(df -h "$MOUNT_POINT" | tail -1)
DerivedData: $(du -sh "$MOUNT_POINT/DerivedData" 2>/dev/null | awk '{print $1}' || echo "0")
SwiftPM缓存: $(du -sh "$MOUNT_POINT/swiftpm" 2>/dev/null | awk '{print $1}' || echo "0")
测试结果: $(du -sh "$MOUNT_POINT/test-results" 2>/dev/null | awk '{print $1}' || echo "0")
构建产物: $(du -sh "$MOUNT_POINT/build-artifacts" 2>/dev/null | awk '{print $1}' || echo "0")

=== 系统资源 ===
CPU使用率: $(top -l 1 -s 0 | grep "CPU usage" | awk '{print $3}')
内存可用率: $(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}')
本地磁盘: $(df -h / | tail -1)

=== 模拟器状态 ===
可用模拟器数量: $(xcrun simctl list devices available | grep -c "iPhone\|iPad")
设备总数: $(xcrun simctl list devices | grep -c "iPhone\|iPad")

=== 维护操作 ===
EOF
    
    if [ -f "$LOG_FILE" ]; then
        grep "$(date +%Y-%m-%d)" "$LOG_FILE" >> "$report_file"
    fi
    
    echo "维护报告已生成: $report_file"
    cat "$report_file"
}

# 主维护函数
main() {
    local maintenance_type="${1:-daily}"
    
    echo "=== GitHub Actions 自托管运行器维护 ==="
    echo "维护类型: $maintenance_type"
    echo "维护时间: $(date)"
    echo ""
    
    case "$maintenance_type" in
        "daily")
            log_info "执行日常维护..."
            cleanup_derived_data
            cleanup_swiftpm_cache
            cleanup_simulators
            cleanup_system_temp
            fix_permissions
            ;;
        "weekly")
            log_info "执行周度维护..."
            cleanup_derived_data
            cleanup_swiftpm_cache
            cleanup_simulators
            cleanup_artifacts
            cleanup_system_temp
            backup_configurations
            fix_permissions
            ;;
        "monthly")
            log_info "执行月度维护..."
            cleanup_derived_data
            cleanup_swiftpm_cache
            cleanup_simulators
            cleanup_artifacts
            cleanup_system_temp
            backup_configurations
            optimize_system
            fix_permissions
            update_runner
            ;;
        "deep")
            log_info "执行深度维护..."
            cleanup_derived_data
            cleanup_swiftpm_cache
            cleanup_simulators
            cleanup_artifacts
            cleanup_system_temp
            backup_configurations
            optimize_system --rebuild-spotlight
            fix_permissions
            update_runner
            ;;
        *)
            echo "未知的维护类型: $maintenance_type"
            echo "可用类型: daily, weekly, monthly, deep"
            exit 1
            ;;
    esac
    
    echo ""
    echo "=== 维护完成 ==="
    generate_maintenance_report
    
    log_success "维护操作完成"
}

# 处理命令行参数
case "${1:-daily}" in
    --help)
        echo "用法: $0 [维护类型]"
        echo "维护类型:"
        echo "  daily    日常维护（清理缓存、临时文件）"
        echo "  weekly   周度维护（包含备份）"
        echo "  monthly  月度维护（包含优化和更新检查）"
        echo "  deep     深度维护（重建索引等）"
        echo "  --help   显示此帮助信息"
        ;;
    *)
        main "$1"
        ;;
esac
