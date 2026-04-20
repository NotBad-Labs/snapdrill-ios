#!/usr/bin/env ruby
# 为 SnapDrillShareTests target 创建独立 shared scheme。
# 用法：ruby scripts/create_share_tests_scheme.rb
# 幂等：scheme 已存在则覆盖。

require 'xcodeproj'

PROJECT_PATH = 'SnapDrill.xcodeproj'
TESTS_TARGET_NAME = 'SnapDrillShareTests'
APP_TARGET_NAME = 'SnapDrill'
SCHEME_NAME = 'SnapDrillShareTests'

project = Xcodeproj::Project.open(PROJECT_PATH)
tests_target = project.targets.find { |t| t.name == TESTS_TARGET_NAME }
app_target = project.targets.find { |t| t.name == APP_TARGET_NAME }
abort "找不到 #{TESTS_TARGET_NAME} target" unless tests_target
abort "找不到 #{APP_TARGET_NAME} target" unless app_target

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(tests_target)
scheme.add_test_target(tests_target)

# 测试运行需要 host app
scheme.test_action.code_coverage_enabled = true

scheme.save_as(PROJECT_PATH, SCHEME_NAME, true)
puts "[OK] scheme 已写入：#{PROJECT_PATH}/xcshareddata/xcschemes/#{SCHEME_NAME}.xcscheme"
