#!/bin/zsh

# 设置GitHub Actions自托管运行器的定时任务
# 用于自动化监控、维护和清理任务
# 作者：AI Assistant
# 版本：1.0

set -euo pipefail

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_USER="runner"
RUNNER_HOME="/Users/${RUNNER_USER}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 创建定时任务文件
create_cron_jobs() {
    log_info "创建定时任务配置..."
    
    # 为runner用户创建crontab
    cat > /tmp/runner_crontab << 'EOF'
# GitHub Actions 自托管运行器定时任务
# 监控任务 - 每15分钟检查一次
*/15 * * * * /Users/runner/Developer/NotBad/Scripts/runner_monitor.sh --auto-restart >> /var/log/runner_monitor.log 2>&1

# 日常维护 - 每天凌晨2点执行
0 2 * * * /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh daily >> /var/log/runner_maintenance.log 2>&1

# 周度维护 - 每周日凌晨3点执行
0 3 * * 0 /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh weekly >> /var/log/runner_maintenance.log 2>&1

# 月度维护 - 每月1号凌晨4点执行
0 4 1 * * /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh monthly >> /var/log/runner_maintenance.log 2>&1

# 存储空间检查 - 每6小时检查一次
0 */6 * * * /Users/runner/Developer/NotBad/Scripts/check_storage.sh >> /var/log/runner_storage.log 2>&1

# 系统健康检查 - 每小时执行
0 * * * * /Users/runner/Developer/NotBad/Scripts/health_check.sh >> /var/log/runner_health.log 2>&1

# 清理日志文件 - 每周清理一次旧日志
0 1 * * 0 find /var/log/runner_*.log -mtime +30 -delete 2>/dev/null || true
EOF
    
    # 安装crontab
    sudo -u "$RUNNER_USER" crontab /tmp/runner_crontab
    rm /tmp/runner_crontab
    
    log_success "定时任务创建完成"
}

# 创建存储检查脚本
create_storage_check_script() {
    log_info "创建存储检查脚本..."
    
    cat > "$SCRIPT_DIR/check_storage.sh" << 'EOF'
#!/bin/zsh

# 存储空间检查脚本
# 检查群晖存储挂载状态和空间使用情况

set -euo pipefail

MOUNT_POINT="/Volumes/runner_data"
LOG_FILE="/var/log/runner_storage.log"

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 检查挂载状态
if ! mount | grep -q "$MOUNT_POINT"; then
    log_error "群晖存储未挂载: $MOUNT_POINT"
    # 尝试重新挂载
    /usr/local/bin/automount_runner_data.sh 2>/dev/null || true
    exit 1
fi

# 检查存储空间
STORAGE_INFO=$(df -h "$MOUNT_POINT" | tail -1)
USED_PERCENT=$(echo "$STORAGE_INFO" | awk '{print $5}' | sed 's/%//')

if [ "$USED_PERCENT" -gt 95 ]; then
    log_error "存储空间严重不足: ${USED_PERCENT}% - $STORAGE_INFO"
    # 触发紧急清理
    /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh deep >> /var/log/runner_emergency_cleanup.log 2>&1
elif [ "$USED_PERCENT" -gt 85 ]; then
    log_warning "存储空间不足: ${USED_PERCENT}% - $STORAGE_INFO"
    # 触发常规清理
    /Users/runner/Developer/NotBad/Scripts/runner_maintenance.sh weekly >> /var/log/runner_storage_cleanup.log 2>&1
fi

echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - 存储检查完成: ${USED_PERCENT}% - $STORAGE_INFO" >> "$LOG_FILE"
EOF
    
    chmod +x "$SCRIPT_DIR/check_storage.sh"
    log_success "存储检查脚本创建完成"
}

# 创建健康检查脚本
create_health_check_script() {
    log_info "创建健康检查脚本..."
    
    cat > "$SCRIPT_DIR/health_check.sh" << 'EOF'
#!/bin/zsh

# 系统健康检查脚本
# 检查系统资源、服务状态等

set -euo pipefail

LOG_FILE="/var/log/runner_health.log"

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 检查CPU使用率
CPU_USAGE=$(top -l 1 -s 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
if [ "$CPU_USAGE" -gt 90 ]; then
    log_warning "CPU使用率过高: ${CPU_USAGE}%"
fi

# 检查内存使用率
MEMORY_PRESSURE=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
if [ "$MEMORY_PRESSURE" -lt 10 ]; then
    log_warning "内存可用率过低: ${MEMORY_PRESSURE}%"
fi

# 检查本地磁盘空间
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log_error "本地磁盘空间不足: ${DISK_USAGE}%"
fi

# 检查运行器服务状态
if ! sudo -u runner /Users/runner/actions-runner/svc.sh status | grep -q "running"; then
    log_error "GitHub Actions运行器服务未运行"
fi

# 检查网络连接
if ! ping -c 1 github.com > /dev/null 2>&1; then
    log_error "无法连接到GitHub"
fi

echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - 健康检查完成" >> "$LOG_FILE"
EOF
    
    chmod +x "$SCRIPT_DIR/health_check.sh"
    log_success "健康检查脚本创建完成"
}

# 创建LaunchAgent配置文件
create_launch_agents() {
    log_info "创建LaunchAgent配置文件..."
    
    # 创建自动挂载的LaunchAgent
    cat > /tmp/com.github.actions.runner.automount.plist << 'EOF'
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
    <key>StandardOutPath</key>
    <string>/var/log/automount.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/automount_error.log</string>
</dict>
</plist>
EOF
    
    sudo mv /tmp/com.github.actions.runner.automount.plist /Library/LaunchDaemons/
    sudo chown root:wheel /Library/LaunchDaemons/com.github.actions.runner.automount.plist
    sudo chmod 644 /Library/LaunchDaemons/com.github.actions.runner.automount.plist
    
    # 创建运行器监控的LaunchAgent
    cat > /tmp/com.github.actions.runner.monitor.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.github.actions.runner.monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/runner/Developer/NotBad/Scripts/runner_monitor.sh</string>
        <string>--auto-restart</string>
    </array>
    <key>StartInterval</key>
    <integer>900</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/runner_monitor.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/runner_monitor_error.log</string>
</dict>
</plist>
EOF
    
    sudo mv /tmp/com.github.actions.runner.monitor.plist /Library/LaunchDaemons/
    sudo chown root:wheel /Library/LaunchDaemons/com.github.actions.runner.monitor.plist
    sudo chmod 644 /Library/LaunchDaemons/com.github.actions.runner.monitor.plist
    
    log_success "LaunchAgent配置文件创建完成"
}

# 设置日志轮转
setup_log_rotation() {
    log_info "设置日志轮转..."
    
    cat > /tmp/runner_logrotate.conf << 'EOF'
/var/log/runner_*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    create 644 root wheel
}
EOF
    
    sudo mv /tmp/runner_logrotate.conf /etc/logrotate.d/runner
    log_success "日志轮转设置完成"
}

# 设置脚本权限
set_script_permissions() {
    log_info "设置脚本权限..."
    
    # 设置脚本执行权限
    chmod +x "$SCRIPT_DIR"/*.sh
    
    # 设置日志文件权限
    sudo touch /var/log/runner_monitor.log
    sudo touch /var/log/runner_maintenance.log
    sudo touch /var/log/runner_storage.log
    sudo touch /var/log/runner_health.log
    sudo chown root:wheel /var/log/runner_*.log
    sudo chmod 644 /var/log/runner_*.log
    
    log_success "脚本权限设置完成"
}

# 加载LaunchAgents
load_launch_agents() {
    log_info "加载LaunchAgents..."
    
    sudo launchctl load /Library/LaunchDaemons/com.github.actions.runner.automount.plist
    sudo launchctl load /Library/LaunchDaemons/com.github.actions.runner.monitor.plist
    
    log_success "LaunchAgents加载完成"
}

# 验证定时任务
verify_cron_jobs() {
    log_info "验证定时任务..."
    
    echo "当前runner用户的定时任务："
    sudo -u "$RUNNER_USER" crontab -l
    
    echo ""
    echo "当前系统的LaunchDaemons："
    sudo launchctl list | grep -E "(automount|monitor)" || true
    
    log_success "定时任务验证完成"
}

# 主函数
main() {
    echo "=== GitHub Actions 自托管运行器定时任务设置 ==="
    echo ""
    
    create_storage_check_script
    create_health_check_script
    create_cron_jobs
    create_launch_agents
    setup_log_rotation
    set_script_permissions
    load_launch_agents
    verify_cron_jobs
    
    echo ""
    log_success "定时任务设置完成！"
    echo ""
    echo "=== 已设置的定时任务 ==="
    echo "• 监控任务：每15分钟检查运行器状态"
    echo "• 日常维护：每天凌晨2点执行"
    echo "• 周度维护：每周日凌晨3点执行"
    echo "• 月度维护：每月1号凌晨4点执行"
    echo "• 存储检查：每6小时检查一次"
    echo "• 健康检查：每小时执行"
    echo "• 日志清理：每周清理一次旧日志"
    echo ""
    echo "=== 日志文件位置 ==="
    echo "• 监控日志：/var/log/runner_monitor.log"
    echo "• 维护日志：/var/log/runner_maintenance.log"
    echo "• 存储日志：/var/log/runner_storage.log"
    echo "• 健康日志：/var/log/runner_health.log"
}

# 运行主函数
main "$@"
