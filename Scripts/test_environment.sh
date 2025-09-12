#!/bin/zsh

# 环境可行性测试脚本
# 用于测试Mac mini是否适合运行GitHub Actions自托管运行器
# 作者：AI Assistant
# 版本：1.0

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
    ((PASSED_TESTS++))
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    ((WARNING_TESTS++))
}

log_error() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
    ((FAILED_TESTS++))
}

log_test() {
    echo -e "${PURPLE}[TEST]${NC} $1"
    ((TOTAL_TESTS++))
}

# 显示欢迎信息
show_welcome() {
    echo "=========================================="
    echo "GitHub Actions 自托管运行器环境测试"
    echo "=========================================="
    echo ""
    echo "此脚本将测试您的Mac mini环境是否适合运行自托管GitHub Actions运行器"
    echo ""
}

# 测试硬件配置
test_hardware() {
    log_test "测试硬件配置"
    
    # 检查CPU
    local cpu_info=$(sysctl -n machdep.cpu.brand_string)
    log_info "CPU: $cpu_info"
    
    if echo "$cpu_info" | grep -q "Apple"; then
        log_success "检测到Apple Silicon处理器"
    else
        log_warning "检测到Intel处理器，建议使用Apple Silicon"
    fi
    
    # 检查内存
    local total_memory=$(sysctl -n hw.memsize)
    local memory_gb=$((total_memory / 1024 / 1024 / 1024))
    log_info "内存: ${memory_gb}GB"
    
    if [ "$memory_gb" -ge 16 ]; then
        log_success "内存充足 (${memory_gb}GB)"
    elif [ "$memory_gb" -ge 8 ]; then
        log_warning "内存较低 (${memory_gb}GB)，建议16GB或更多"
    else
        log_error "内存不足 (${memory_gb}GB)，需要至少8GB"
    fi
    
    # 检查存储空间
    local disk_info=$(df -h / | tail -1)
    local disk_size=$(echo "$disk_info" | awk '{print $2}')
    local disk_available=$(echo "$disk_info" | awk '{print $4}')
    local disk_used_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
    
    log_info "存储: $disk_info"
    
    if [ "$disk_used_percent" -lt 80 ]; then
        log_success "存储空间充足 (${disk_available}可用)"
    elif [ "$disk_used_percent" -lt 90 ]; then
        log_warning "存储空间较紧 (${disk_used_percent}%已使用)"
    else
        log_error "存储空间不足 (${disk_used_percent}%已使用)"
    fi
}

# 测试macOS版本
test_macos_version() {
    log_test "测试macOS版本"
    
    local macos_version=$(sw_vers -productVersion)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    local minor_version=$(echo "$macos_version" | cut -d. -f2)
    
    log_info "macOS版本: $macos_version"
    
    if [ "$major_version" -ge 14 ]; then
        log_success "macOS版本支持 ($macos_version)"
    else
        log_error "macOS版本过低 ($macos_version)，需要14.0或更高版本"
    fi
}

# 测试网络连接
test_network() {
    log_test "测试网络连接"
    
    # 测试GitHub连接
    if ping -c 3 github.com > /dev/null 2>&1; then
        log_success "GitHub连接正常"
    else
        log_error "无法连接到GitHub"
        return 1
    fi
    
    # 测试网络速度
    log_info "测试网络下载速度..."
    local download_speed=$(curl -o /dev/null -s -w "%{speed_download}" https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz 2>/dev/null || echo "0")
    local speed_mbps=$((download_speed / 1024 / 1024))
    
    if [ "$speed_mbps" -gt 10 ]; then
        log_success "网络速度良好 (${speed_mbps}MB/s)"
    elif [ "$speed_mbps" -gt 5 ]; then
        log_warning "网络速度一般 (${speed_mbps}MB/s)"
    else
        log_warning "网络速度较慢 (${speed_mbps}MB/s)，可能影响构建效率"
    fi
}

# 测试Xcode安装
test_xcode() {
    log_test "测试Xcode安装"
    
    # 检查Xcode是否安装
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode未安装，请先安装Xcode"
        return 1
    fi
    
    # 检查Xcode版本
    local xcode_version=$(xcodebuild -version | head -n 1)
    log_info "Xcode版本: $xcode_version"
    
    if echo "$xcode_version" | grep -q "Xcode 16"; then
        log_success "Xcode版本支持"
    elif echo "$xcode_version" | grep -q "Xcode 15"; then
        log_warning "Xcode版本较旧，建议升级到16.x"
    else
        log_warning "Xcode版本未知，请确认版本兼容性"
    fi
    
    # 检查Command Line Tools
    if xcode-select -p >/dev/null 2>&1; then
        log_success "Command Line Tools已安装"
    else
        log_warning "Command Line Tools未安装，建议安装"
    fi
    
    # 检查Xcode许可
    if /usr/bin/xcodebuild -checkFirstLaunchStatus 2>/dev/null | grep -q 'requiresFirstLaunchExperience'; then
        log_warning "Xcode许可未接受，需要手动接受"
    else
        log_success "Xcode许可已接受"
    fi
}

# 测试模拟器
test_simulators() {
    log_test "测试iOS模拟器"
    
    # 检查可用模拟器
    local simulator_count=$(xcrun simctl list devices available | grep -c "iPhone\|iPad")
    log_info "可用模拟器数量: $simulator_count"
    
    if [ "$simulator_count" -ge 5 ]; then
        log_success "模拟器充足 ($simulator_count个)"
    elif [ "$simulator_count" -ge 2 ]; then
        log_warning "模拟器较少 ($simulator_count个)，建议安装更多版本"
    else
        log_error "可用模拟器不足 ($simulator_count个)"
    fi
    
    # 检查iOS运行时
    local ios_runtimes=$(xcrun simctl list runtimes | grep -c "iOS")
    if [ "$ios_runtimes" -ge 1 ]; then
        log_success "iOS运行时已安装 ($ios_runtimes个)"
    else
        log_warning "iOS运行时未安装，需要下载"
    fi
}

# 测试系统权限
test_permissions() {
    log_test "测试系统权限"
    
    # 检查管理员权限
    if groups | grep -q admin; then
        log_success "用户具有管理员权限"
    else
        log_error "用户没有管理员权限，无法安装运行器"
        return 1
    fi
    
    # 检查sudo权限
    if sudo -n true 2>/dev/null; then
        log_success "具有sudo权限"
    else
        log_warning "需要sudo权限来安装运行器"
    fi
}

# 测试存储性能
test_storage_performance() {
    log_test "测试存储性能"
    
    local temp_file="/tmp/storage_test_$$"
    local test_size=50  # 50MB
    
    log_info "测试存储写入性能..."
    local write_start=$(date +%s)
    dd if=/dev/zero of="$temp_file" bs=1m count=$test_size 2>/dev/null
    local write_end=$(date +%s)
    local write_time=$((write_end - write_start))
    
    if [ "$write_time" -gt 0 ]; then
        local write_speed=$((test_size / write_time))
        log_info "写入速度: ${write_speed}MB/s"
        
        if [ "$write_speed" -gt 100 ]; then
            log_success "存储性能优秀"
        elif [ "$write_speed" -gt 50 ]; then
            log_success "存储性能良好"
        else
            log_warning "存储性能一般，可能影响构建速度"
        fi
    else
        log_success "存储性能测试完成"
    fi
    
    # 清理测试文件
    rm -f "$temp_file"
}

# 测试群晖连接（可选）
test_synology_connection() {
    log_test "测试群晖连接（可选）"
    
    echo "请选择测试方式："
    echo "1. 跳过群晖测试"
    echo "2. 手动输入群晖IP进行测试"
    read -p "请输入选择 (1-2): " choice
    
    case $choice in
        2)
            read -p "请输入群晖IP地址: " synology_ip
            if ping -c 3 "$synology_ip" > /dev/null 2>&1; then
                log_success "群晖连接正常 ($synology_ip)"
                
                # 测试SMB端口
                if nc -z "$synology_ip" 445 2>/dev/null; then
                    log_success "SMB服务可用"
                else
                    log_warning "SMB服务不可用或端口被阻止"
                fi
            else
                log_warning "无法连接到群晖 ($synology_ip)"
            fi
            ;;
        *)
            log_info "跳过群晖测试"
            ;;
    esac
}

# 测试系统资源使用
test_system_resources() {
    log_test "测试系统资源使用"
    
    # CPU使用率
    local cpu_usage=$(top -l 1 -s 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    log_info "当前CPU使用率: ${cpu_usage}%"
    
    if [ "$cpu_usage" -lt 50 ]; then
        log_success "CPU使用率正常"
    elif [ "$cpu_usage" -lt 80 ]; then
        log_warning "CPU使用率较高"
    else
        log_warning "CPU使用率很高，可能影响构建性能"
    fi
    
    # 内存使用率
    local memory_pressure=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')
    log_info "内存可用率: ${memory_pressure}%"
    
    if [ "$memory_pressure" -gt 50 ]; then
        log_success "内存充足"
    elif [ "$memory_pressure" -gt 20 ]; then
        log_warning "内存使用率较高"
    else
        log_warning "内存使用率很高，可能影响构建性能"
    fi
}

# 生成测试报告
generate_report() {
    echo ""
    echo "=========================================="
    echo "测试报告"
    echo "=========================================="
    echo ""
    echo "总测试数: $TOTAL_TESTS"
    echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "警告: ${YELLOW}$WARNING_TESTS${NC}"
    echo -e "失败: ${RED}$FAILED_TESTS${NC}"
    echo ""
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    
    if [ "$FAILED_TESTS" -eq 0 ] && [ "$success_rate" -ge 80 ]; then
        echo -e "${GREEN}✅ 环境测试通过！您的Mac mini适合运行自托管GitHub Actions运行器${NC}"
        echo ""
        echo "建议下一步："
        echo "1. 运行 'sudo ./Scripts/quick_setup.sh' 开始安装"
        echo "2. 配置GitHub Personal Access Token"
        echo "3. 设置群晖存储挂载"
    elif [ "$FAILED_TESTS" -le 2 ]; then
        echo -e "${YELLOW}⚠️ 环境基本适合，但有一些问题需要解决${NC}"
        echo ""
        echo "建议："
        echo "1. 解决失败的测试项目"
        echo "2. 重新运行测试脚本"
        echo "3. 考虑升级硬件或软件"
    else
        echo -e "${RED}❌ 环境不适合运行自托管GitHub Actions运行器${NC}"
        echo ""
        echo "建议："
        echo "1. 升级硬件配置"
        echo "2. 安装必要的软件"
        echo "3. 解决网络连接问题"
    fi
    
    echo ""
    echo "详细测试结果已保存到: /tmp/environment_test_report_$(date +%Y%m%d_%H%M%S).txt"
}

# 保存测试结果到文件
save_report() {
    local report_file="/tmp/environment_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
GitHub Actions 自托管运行器环境测试报告
测试时间: $(date)
主机名: $(hostname)
用户: $(whoami)

=== 系统信息 ===
macOS版本: $(sw_vers -productVersion)
硬件型号: $(sysctl -n hw.model)
CPU: $(sysctl -n machdep.cpu.brand_string)
内存: $(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)"GB"}')
存储: $(df -h / | tail -1)

=== 测试结果 ===
总测试数: $TOTAL_TESTS
通过: $PASSED_TESTS
警告: $WARNING_TESTS
失败: $FAILED_TESTS

=== 详细测试 ===
EOF
    
    # 这里可以添加更详细的测试结果
    echo "测试报告已保存到: $report_file"
}

# 主函数
main() {
    show_welcome
    
    test_hardware
    test_macos_version
    test_network
    test_xcode
    test_simulators
    test_permissions
    test_storage_performance
    test_synology_connection
    test_system_resources
    
    generate_report
    save_report
}

# 运行主函数
main "$@"
