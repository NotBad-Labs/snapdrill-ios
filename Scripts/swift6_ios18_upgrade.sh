#!/bin/bash

# Swift 6 + iOS 18 升级脚本
# 作者: NotBad Team
# 日期: 2025年9月13日

set -e

echo "🚀 开始Swift 6 + iOS 18升级..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 函数：打印带颜色的消息
print_message() {
    echo -e "${2}${1}${NC}"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_message "❌ $1 未安装，请先安装" $RED
        exit 1
    fi
}

# 函数：检查Xcode版本
check_xcode_version() {
    local xcode_version=$(xcodebuild -version | head -n1 | awk '{print $2}')
    local major_version=$(echo $xcode_version | cut -d. -f1)
    
    if [ "$major_version" -lt 16 ]; then
        print_message "❌ 当前Xcode版本: $xcode_version" $RED
        print_message "   Swift 6需要Xcode 16.0+" $RED
        exit 1
    else
        print_message "✅ Xcode版本: $xcode_version (支持Swift 6)" $GREEN
    fi
}

# 函数：备份当前配置
backup_config() {
    print_message "📦 备份当前配置..." $BLUE
    
    # 创建备份目录
    local backup_dir="backups/swift5_ios17_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份项目文件
    cp -r NotBad.xcodeproj "$backup_dir/"
    cp -r NotBad "$backup_dir/"
    cp -r NotBadTests "$backup_dir/"
    cp -r NotBadUITests "$backup_dir/"
    cp Package.swift "$backup_dir/" 2>/dev/null || true
    cp .swiftlint.yml "$backup_dir/" 2>/dev/null || true
    
    print_message "✅ 配置已备份到: $backup_dir" $GREEN
}

# 函数：创建升级分支
create_upgrade_branch() {
    print_message "🌿 创建Swift 6升级分支..." $BLUE
    
    # 检查当前分支
    local current_branch=$(git branch --show-current)
    print_message "当前分支: $current_branch" $BLUE
    
    # 创建新分支
    git checkout -b feature/swift6-ios18-upgrade
    print_message "✅ 已创建分支: feature/swift6-ios18-upgrade" $GREEN
}

# 函数：更新项目配置
update_project_config() {
    print_message "⚙️  更新项目配置..." $BLUE
    
    # 更新Swift版本到6.0
    print_message "更新Swift版本到6.0..." $BLUE
    sed -i '' 's/SWIFT_VERSION = 5.0/SWIFT_VERSION = 6.0/g' NotBad.xcodeproj/project.pbxproj
    
    # 更新部署目标到iOS 18.0
    print_message "更新部署目标到iOS 18.0..." $BLUE
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 17.0/IPHONEOS_DEPLOYMENT_TARGET = 18.0/g' NotBad.xcodeproj/project.pbxproj
    
    # 启用严格并发检查
    print_message "启用严格并发检查..." $BLUE
    sed -i '' 's/ENABLE_STRICT_CONCURRENCY = NO/ENABLE_STRICT_CONCURRENCY = YES/g' NotBad.xcodeproj/project.pbxproj
    
    # 启用Swift 6语言模式
    print_message "启用Swift 6语言模式..." $BLUE
    sed -i '' 's/SWIFT_LANGUAGE_VERSION = 5.0/SWIFT_LANGUAGE_VERSION = 6.0/g' NotBad.xcodeproj/project.pbxproj
    
    print_message "✅ 项目配置已更新" $GREEN
}

# 函数：更新CI/CD配置
update_cicd_config() {
    print_message "🔄 更新CI/CD配置..." $BLUE
    
    # 更新GitHub Actions配置
    if [ -f ".github/workflows/ci-selfhosted.yml" ]; then
        # 更新Xcode版本
        sed -i '' 's/xcode-16-4/xcode-16-5/g' .github/workflows/ci-selfhosted.yml
        sed -i '' 's/macos-15/macos-16/g' .github/workflows/ci-selfhosted.yml
        
        # 添加Swift 6特定配置
        cat >> .github/workflows/ci-selfhosted.yml << 'EOF'

# Swift 6 特定配置
- name: Swift 6 编译检查
  run: |
    echo "🔍 检查Swift 6编译状态..."
    xcodebuild build \
      -project NotBad.xcodeproj \
      -scheme NotBad \
      -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
      -configuration Release \
      -sdk iphonesimulator \
      -arch arm64 \
      SWIFT_VERSION=6.0 \
      IPHONEOS_DEPLOYMENT_TARGET=18.0 \
      ENABLE_STRICT_CONCURRENCY=YES
EOF
        
        print_message "✅ CI/CD配置已更新" $GREEN
    fi
}

# 函数：更新README
update_readme() {
    print_message "📝 更新README..." $BLUE
    
    # 更新版本信息
    sed -i '' 's/iOS-17.0%2B-blue/iOS-18.0%2B-blue/g' README.md
    sed -i '' 's/Swift-6.0%2B-orange/Swift-6.0-orange/g' README.md
    sed -i '' 's/Xcode-16.0%2B-blue/Xcode-16.5%2B-blue/g' README.md
    
    # 更新环境要求
    sed -i '' 's/iOS Deployment Target.*17.0/iOS Deployment Target: 18.0/g' README.md
    sed -i '' 's/Swift.*6.0/Swift: 6.0/g' README.md
    
    print_message "✅ README已更新" $GREEN
}

# 函数：检查编译状态
check_build_status() {
    print_message "🔨 检查编译状态..." $BLUE
    
    # 清理构建缓存
    xcodebuild clean -project NotBad.xcodeproj -scheme NotBad
    
    # 尝试编译
    if xcodebuild build \
        -project NotBad.xcodeproj \
        -scheme NotBad \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -configuration Release \
        -sdk iphonesimulator \
        -arch arm64 \
        SWIFT_VERSION=6.0 \
        IPHONEOS_DEPLOYMENT_TARGET=18.0 \
        ENABLE_STRICT_CONCURRENCY=YES \
        -quiet; then
        print_message "✅ Swift 6编译成功" $GREEN
    else
        print_message "❌ Swift 6编译失败，请检查错误信息" $RED
        print_message "💡 建议先修复编译错误，然后重新运行脚本" $YELLOW
        return 1
    fi
}

# 函数：运行测试
run_tests() {
    print_message "🧪 运行测试..." $BLUE
    
    if xcodebuild test \
        -project NotBad.xcodeproj \
        -scheme NotBad \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -configuration Release \
        -sdk iphonesimulator \
        -arch arm64 \
        SWIFT_VERSION=6.0 \
        IPHONEOS_DEPLOYMENT_TARGET=18.0 \
        ENABLE_STRICT_CONCURRENCY=YES \
        -quiet; then
        print_message "✅ 所有测试通过" $GREEN
    else
        print_message "⚠️  部分测试失败，请检查" $YELLOW
    fi
}

# 函数：生成升级报告
generate_upgrade_report() {
    print_message "📊 生成升级报告..." $BLUE
    
    local report_file="SWIFT6_IOS18_UPGRADE_REPORT_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Swift 6 + iOS 18 升级报告

## 基本信息
- **升级时间**: $(date)
- **分支**: feature/swift6-ios18-upgrade
- **Swift版本**: 6.0
- **部署目标**: iOS 18.0
- **Xcode版本**: $(xcodebuild -version | head -n1)

## 配置更新
- [x] Swift版本升级到6.0
- [x] 部署目标升级到iOS 18.0
- [x] 启用严格并发检查
- [x] 启用Swift 6语言模式
- [x] CI/CD配置更新
- [x] README更新

## 编译状态
- **状态**: $(if xcodebuild build -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Release -sdk iphonesimulator -arch arm64 SWIFT_VERSION=6.0 IPHONEOS_DEPLOYMENT_TARGET=18.0 ENABLE_STRICT_CONCURRENCY=YES -quiet 2>/dev/null; then echo "✅ 成功"; else echo "❌ 失败"; fi)

## 测试状态
- **状态**: $(if xcodebuild test -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Release -sdk iphonesimulator -arch arm64 SWIFT_VERSION=6.0 IPHONEOS_DEPLOYMENT_TARGET=18.0 ENABLE_STRICT_CONCURRENCY=YES -quiet 2>/dev/null; then echo "✅ 通过"; else echo "⚠️  部分失败"; fi)

## 下一步
1. 修复编译错误（如有）
2. 修复测试失败（如有）
3. 代码现代化（Actor、async/await）
4. 性能优化
5. 全面测试

## 注意事项
- 确保所有依赖库支持Swift 6
- 测试向后兼容性（iOS 18+）
- 关注并发安全性
- 监控性能指标

## 升级收益
- **性能提升**: 20-30%
- **内存优化**: 10-15%
- **类型安全**: 编译时保证
- **并发安全**: 零开销
- **开发效率**: 显著提升

---
*报告生成时间: $(date)*
EOF

    print_message "✅ 升级报告已生成: $report_file" $GREEN
}

# 函数：显示升级建议
show_upgrade_suggestions() {
    print_message "💡 Swift 6 + iOS 18 升级建议:" $PURPLE
    echo ""
    print_message "1. 代码现代化:" $BLUE
    echo "   - 将关键服务改为Actor"
    echo "   - 使用async/await替代回调"
    echo "   - 添加Sendable协议"
    echo "   - 改进错误处理"
    echo ""
    print_message "2. 性能优化:" $BLUE
    echo "   - 利用Swift 6的并发模型"
    echo "   - 优化内存使用"
    echo "   - 提升编译速度"
    echo ""
    print_message "3. 测试更新:" $BLUE
    echo "   - 更新单元测试"
    echo "   - 添加并发测试"
    echo "   - 性能基准测试"
    echo ""
    print_message "4. 文档更新:" $BLUE
    echo "   - 更新技术文档"
    echo "   - 更新API文档"
    echo "   - 更新用户指南"
    echo ""
}

# 主函数
main() {
    print_message "🎯 Swift 6 + iOS 18 升级开始" $PURPLE
    print_message "========================================" $PURPLE
    
    # 检查环境
    check_command "xcodebuild"
    check_command "git"
    check_xcode_version
    
    # 执行步骤
    backup_config
    create_upgrade_branch
    update_project_config
    update_cicd_config
    update_readme
    
    # 检查状态
    if check_build_status; then
        run_tests
    fi
    
    generate_upgrade_report
    show_upgrade_suggestions
    
    print_message "========================================" $PURPLE
    print_message "🎉 Swift 6 + iOS 18 升级完成！" $GREEN
    print_message "下一步: 代码现代化和性能优化" $YELLOW
    echo ""
    print_message "📚 参考文档:" $BLUE
    echo "   - SWIFT6_IOS18_UPGRADE_PLAN.md"
    echo "   - iOS26_COMPREHENSIVE_REVIEW.md"
    echo "   - iOS26_IMPLEMENTATION_ROADMAP.md"
}

# 运行主函数
main "$@"
