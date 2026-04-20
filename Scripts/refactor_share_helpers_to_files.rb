#!/usr/bin/env ruby
# 一次性脚本：把 ShareHelpers.swift 引用替换为 3 个独立文件 + 删 Foundation.framework iPhoneOS18 冗余引用。
# 用法：ruby Scripts/refactor_share_helpers_to_files.rb

require 'xcodeproj'

PROJECT_PATH = 'SnapDrill.xcodeproj'
SHARE_TARGET_NAME = 'SnapDrillShare'
TESTS_TARGET_NAME = 'SnapDrillShareTests'
NEW_FILES = ['ShareImageDownsampler.swift', 'ShareDeepLinkBuilder.swift', 'SharedContainerImageWriter.swift']

project = Xcodeproj::Project.open(PROJECT_PATH)
share_target = project.targets.find { |t| t.name == SHARE_TARGET_NAME }
tests_target = project.targets.find { |t| t.name == TESTS_TARGET_NAME }
abort "找不到 #{SHARE_TARGET_NAME} target" unless share_target
abort "找不到 #{TESTS_TARGET_NAME} target" unless tests_target

share_group = project.main_group.find_subpath(SHARE_TARGET_NAME, false)
abort "找不到 SnapDrillShare PBXGroup" unless share_group

# === 1. 移除 ShareHelpers.swift 引用 ===
old_ref = share_group.files.find { |f| f.path == 'ShareHelpers.swift' }
if old_ref
  # 从两个 target 的 sources phase 移除
  [share_target, tests_target].each do |target|
    phase = target.source_build_phase
    phase.files.select { |f| f.file_ref == old_ref }.each do |bf|
      phase.remove_build_file(bf)
      puts "[-] ShareHelpers.swift 从 #{target.name} sources phase 移除"
    end
  end
  old_ref.remove_from_project
  puts "[-] ShareHelpers.swift 从 PBXFileReference 移除"
else
  puts "[=] ShareHelpers.swift 引用已不存在"
end

# === 2. 加 3 个新文件 ===
NEW_FILES.each do |fname|
  ref = share_group.files.find { |f| f.path == fname }
  if ref.nil?
    ref = share_group.new_reference(fname)
    ref.last_known_file_type = 'sourcecode.swift'
    puts "[+] 加入 PBXFileReference: #{fname}"
  else
    puts "[=] 已存在 PBXFileReference: #{fname}"
  end

  # 加进生产 target
  share_phase = share_target.source_build_phase
  unless share_phase.files_references.include?(ref)
    share_phase.add_file_reference(ref)
    puts "[+] #{fname} 加入 #{SHARE_TARGET_NAME} sources phase"
  end

  # 加进测试 target（共享源码编译）
  tests_phase = tests_target.source_build_phase
  unless tests_phase.files_references.include?(ref)
    tests_phase.add_file_reference(ref)
    puts "[+] #{fname} 加入 #{TESTS_TARGET_NAME} sources phase"
  end
end

# === 3. 删 Foundation.framework iPhoneOS18.0 硬编码引用 ===
# ruby xcodeproj 创建 unit_test_bundle 时默认加了 SDK 路径硬编码的 Foundation，
# Codex review Info：脆弱（Xcode 升级路径会失效），且 unit test 不需要显式 link。
foundation_ref = project.objects.find do |obj|
  obj.isa == 'PBXFileReference' &&
    obj.respond_to?(:path) &&
    obj.path&.include?('iPhoneOS18.0.sdk/System/Library/Frameworks/Foundation.framework')
end
if foundation_ref
  # 从 Frameworks build phase 移除
  project.targets.each do |target|
    target.frameworks_build_phase&.files&.select { |f| f.file_ref == foundation_ref }&.each do |bf|
      target.frameworks_build_phase.remove_build_file(bf)
      puts "[-] Foundation.framework 从 #{target.name} frameworks phase 移除"
    end
  end
  foundation_ref.remove_from_project
  puts "[-] Foundation.framework iPhoneOS18.0 硬编码引用删除"
else
  puts "[=] Foundation.framework iPhoneOS18.0 引用已不存在"
end

project.save
puts "\n[OK] pbxproj 已更新。"
