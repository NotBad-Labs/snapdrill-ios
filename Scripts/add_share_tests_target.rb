#!/usr/bin/env ruby
# 一次性脚本：为 SnapDrillShare 增加 ShareHelpers.swift + 创建 SnapDrillShareTests unit test target
# 用法：ruby scripts/add_share_tests_target.rb
# 幂等：重复运行会跳过已存在的 target/file。

require 'xcodeproj'

PROJECT_PATH = 'SnapDrill.xcodeproj'
SHARE_TARGET_NAME = 'SnapDrillShare'
TESTS_TARGET_NAME = 'SnapDrillShareTests'
APP_TARGET_NAME = 'SnapDrill'
HELPER_FILE = 'SnapDrillShare/ShareHelpers.swift'
TEST_FILE = 'SnapDrillShareTests/ShareHelpersTests.swift'

project = Xcodeproj::Project.open(PROJECT_PATH)

share_target = project.targets.find { |t| t.name == SHARE_TARGET_NAME }
app_target = project.targets.find { |t| t.name == APP_TARGET_NAME }
abort "找不到 #{SHARE_TARGET_NAME} target" unless share_target
abort "找不到 #{APP_TARGET_NAME} target" unless app_target

# === 1. ShareHelpers.swift 加入 SnapDrillShare target ===
share_group = project.main_group.find_subpath(SHARE_TARGET_NAME, false)
abort "找不到 SnapDrillShare PBXGroup" unless share_group

helper_ref = share_group.files.find { |f| f.path == 'ShareHelpers.swift' }
if helper_ref.nil?
  helper_ref = share_group.new_reference('ShareHelpers.swift')
  helper_ref.last_known_file_type = 'sourcecode.swift'
  puts "[+] 加入 PBXFileReference: ShareHelpers.swift"
else
  puts "[=] 已存在 PBXFileReference: ShareHelpers.swift"
end

share_sources_phase = share_target.source_build_phase
unless share_sources_phase.files_references.include?(helper_ref)
  share_sources_phase.add_file_reference(helper_ref)
  puts "[+] ShareHelpers.swift 加入 SnapDrillShare sources phase"
else
  puts "[=] ShareHelpers.swift 已在 SnapDrillShare sources phase"
end

# === 2. 创建 SnapDrillShareTests target（unit test bundle）===
tests_target = project.targets.find { |t| t.name == TESTS_TARGET_NAME }
if tests_target.nil?
  tests_target = project.new_target(
    :unit_test_bundle,
    TESTS_TARGET_NAME,
    :ios,
    '26.0'
  )
  puts "[+] 创建 unit test target: #{TESTS_TARGET_NAME}"
else
  puts "[=] target 已存在: #{TESTS_TARGET_NAME}"
end

# 测试 target 配置：host 在 SnapDrill app
tests_target.build_configurations.each do |config|
  bs = config.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.snapdrill.app.sharetests'
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['SWIFT_VERSION'] = '6.3'
  bs['SWIFT_STRICT_CONCURRENCY'] = 'complete'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '26.0'
  bs['SUPPORTED_PLATFORMS'] = 'iphonesimulator iphoneos'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['SWIFT_EMIT_LOC_STRINGS'] = 'NO'
  bs['GENERATE_INFOPLIST_FILE'] = 'YES'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['DEVELOPMENT_TEAM'] = 'W5A8THDKW8'
  bs['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/SnapDrill.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/SnapDrill'
  bs['BUNDLE_LOADER'] = '$(TEST_HOST)'
end

# 测试 target 依赖 SnapDrill app
unless tests_target.dependencies.any? { |d| d.target == app_target }
  tests_target.add_dependency(app_target)
  puts "[+] #{TESTS_TARGET_NAME} 依赖 #{APP_TARGET_NAME}"
end

# === 3. 加测试源码 + helper（共享编译）===
tests_group = project.main_group.find_subpath(TESTS_TARGET_NAME, true)
tests_group.set_source_tree('<group>')
tests_group.set_path(TESTS_TARGET_NAME)

test_ref = tests_group.files.find { |f| f.path == 'ShareHelpersTests.swift' }
if test_ref.nil?
  test_ref = tests_group.new_reference('ShareHelpersTests.swift')
  test_ref.last_known_file_type = 'sourcecode.swift'
  puts "[+] 加入 PBXFileReference: ShareHelpersTests.swift"
else
  puts "[=] 已存在 PBXFileReference: ShareHelpersTests.swift"
end

tests_sources_phase = tests_target.source_build_phase
unless tests_sources_phase.files_references.include?(test_ref)
  tests_sources_phase.add_file_reference(test_ref)
  puts "[+] ShareHelpersTests.swift 加入 #{TESTS_TARGET_NAME} sources phase"
else
  puts "[=] ShareHelpersTests.swift 已在 #{TESTS_TARGET_NAME} sources phase"
end

# ShareHelpers.swift 也加进测试 target sources（让测试能直接 import 类型）
unless tests_sources_phase.files_references.include?(helper_ref)
  tests_sources_phase.add_file_reference(helper_ref)
  puts "[+] ShareHelpers.swift 加入 #{TESTS_TARGET_NAME} sources phase（共享源码编译）"
else
  puts "[=] ShareHelpers.swift 已在 #{TESTS_TARGET_NAME} sources phase"
end

# === 4. 保存 ===
project.save
puts "\n[OK] pbxproj 已更新。请手动验证 Xcode 中 target/scheme 配置。"
