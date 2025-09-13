#!/bin/bash

# iOS 26 适配设置脚本
# 作者: NotBad Team
# 日期: 2025年9月13日

set -e

echo "🚀 开始iOS 26适配设置..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
        print_message "⚠️  当前Xcode版本: $xcode_version" $YELLOW
        print_message "   建议升级到Xcode 16.0+以支持iOS 26" $YELLOW
    else
        print_message "✅ Xcode版本: $xcode_version (支持iOS 26)" $GREEN
    fi
}

# 函数：备份当前配置
backup_config() {
    print_message "📦 备份当前配置..." $BLUE
    
    # 创建备份目录
    mkdir -p backups/$(date +%Y%m%d_%H%M%S)
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    # 备份项目文件
    cp -r NotBad.xcodeproj "$backup_dir/"
    cp -r NotBad "$backup_dir/"
    cp -r NotBadTests "$backup_dir/"
    cp -r NotBadUITests "$backup_dir/"
    cp Package.swift "$backup_dir/" 2>/dev/null || true
    cp .swiftlint.yml "$backup_dir/" 2>/dev/null || true
    
    print_message "✅ 配置已备份到: $backup_dir" $GREEN
}

# 函数：创建iOS 26适配分支
create_ios26_branch() {
    print_message "🌿 创建iOS 26适配分支..." $BLUE
    
    # 检查当前分支
    local current_branch=$(git branch --show-current)
    print_message "当前分支: $current_branch" $BLUE
    
    # 创建新分支
    git checkout -b feature/ios26-adaptation
    print_message "✅ 已创建分支: feature/ios26-adaptation" $GREEN
}

# 函数：更新项目配置
update_project_config() {
    print_message "⚙️  更新项目配置..." $BLUE
    
    # 更新Swift版本到6.0
    print_message "更新Swift版本到6.0..." $BLUE
    sed -i '' 's/SWIFT_VERSION = 5.0/SWIFT_VERSION = 6.0/g' NotBad.xcodeproj/project.pbxproj
    
    # 更新部署目标到iOS 18.0（iOS 26前置版本）
    print_message "更新部署目标到iOS 18.0（iOS 26前置版本）..." $BLUE
    sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 17.0/IPHONEOS_DEPLOYMENT_TARGET = 18.0/g' NotBad.xcodeproj/project.pbxproj
    
    print_message "✅ 项目配置已更新" $GREEN
}

# 函数：更新CI/CD配置
update_cicd_config() {
    print_message "🔄 更新CI/CD配置..." $BLUE
    
    # 更新GitHub Actions配置
    if [ -f ".github/workflows/ci-selfhosted.yml" ]; then
        # 更新Xcode版本
        sed -i '' 's/macos-15/macos-16/g' .github/workflows/ci-selfhosted.yml
        sed -i '' 's/xcode-16-4/xcode-16-5/g' .github/workflows/ci-selfhosted.yml
        
        print_message "✅ CI/CD配置已更新" $GREEN
    fi
}

# 函数：更新README
update_readme() {
    print_message "📝 更新README..." $BLUE
    
    # 更新版本信息
    sed -i '' 's/v1.0.0-beta/v1.0.0-ios26/g' README.md
    sed -i '' 's/Xcode-16.0%2B-blue/Xcode-16.5%2B-blue/g' README.md
    sed -i '' 's/iOS-17.0%2B-blue/iOS-18.0%2B-blue/g' README.md
    # 注意：iOS 18是iOS 26的前置版本，苹果跳过了iOS 19-25
    
    print_message "✅ README已更新" $GREEN
}

# 函数：检查编译状态
check_build_status() {
    print_message "🔨 检查编译状态..." $BLUE
    
    # 清理构建缓存
    xcodebuild clean -project NotBad.xcodeproj -scheme NotBad
    
    # 尝试编译
    if xcodebuild build -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet; then
        print_message "✅ 编译成功" $GREEN
    else
        print_message "❌ 编译失败，请检查错误信息" $RED
        return 1
    fi
}

# 函数：运行测试
run_tests() {
    print_message "🧪 运行测试..." $BLUE
    
    if xcodebuild test -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet; then
        print_message "✅ 所有测试通过" $GREEN
    else
        print_message "⚠️  部分测试失败，请检查" $YELLOW
    fi
}

# 函数：生成报告
generate_report() {
    print_message "📊 生成适配报告..." $BLUE
    
    local report_file="iOS26_ADAPTATION_REPORT_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# iOS 26 适配报告

## 基本信息
- **适配时间**: $(date)
- **分支**: feature/ios26-adaptation
- **Swift版本**: 6.0
- **部署目标**: iOS 18.0（iOS 26前置版本）
- **Xcode版本**: $(xcodebuild -version | head -n1)

## 配置更新
- [x] Swift版本升级到6.0
- [x] 部署目标升级到iOS 18.0（iOS 26前置版本）
- [x] CI/CD配置更新
- [x] README更新

## 编译状态
- **状态**: $(if xcodebuild build -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>/dev/null; then echo "✅ 成功"; else echo "❌ 失败"; fi)

## 测试状态
- **状态**: $(if xcodebuild test -project NotBad.xcodeproj -scheme NotBad -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet 2>/dev/null; then echo "✅ 通过"; else echo "⚠️  部分失败"; fi)

## 下一步
1. 修复编译错误（如有）
2. 修复测试失败（如有）
3. 集成iOS 26新特性
4. 性能优化
5. 全面测试

## 注意事项
- 确保所有依赖库支持iOS 18.0+
- 测试向后兼容性
- 关注iOS 26新特性

---
*报告生成时间: $(date)*
EOF

    print_message "✅ 报告已生成: $report_file" $GREEN
}

# 主函数
main() {
    print_message "🎯 iOS 26 适配设置开始" $BLUE
    print_message "================================" $BLUE
    
    # 检查环境
    check_command "xcodebuild"
    check_command "git"
    check_xcode_version
    
    # 执行步骤
    backup_config
    create_ios26_branch
    update_project_config
    update_cicd_config
    update_readme
    
    # 检查状态
    if check_build_status; then
        run_tests
    fi
    
    generate_report
    
    print_message "================================" $BLUE
    print_message "🎉 iOS 26 适配设置完成！" $GREEN
    print_message "下一步: 修复编译错误并集成新特性" $YELLOW
}

# 运行主函数
main "$@"
