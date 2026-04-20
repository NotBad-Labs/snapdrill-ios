#!/usr/bin/env ruby
# 一次性迁移：SnapDrillShare 与 SnapDrillShareTests 从传统 PBXGroup 转为
# PBXFileSystemSynchronizedRootGroup，并通过 exception 机制把 3 个 helper
# 跨 target 共享给 SnapDrillShareTests 编译。

require 'xcodeproj'

PROJECT_PATH = 'SnapDrill.xcodeproj'
SHARE_TARGET = 'SnapDrillShare'
TESTS_TARGET = 'SnapDrillShareTests'
SHARE_DIR = 'SnapDrillShare'
TESTS_DIR = 'SnapDrillShareTests'
SHARED_HELPERS = ['ShareImageDownsampler.swift', 'ShareDeepLinkBuilder.swift', 'SharedContainerImageWriter.swift']

project = Xcodeproj::Project.open(PROJECT_PATH)
share_target = project.targets.find { |t| t.name == SHARE_TARGET }
tests_target = project.targets.find { |t| t.name == TESTS_TARGET }
abort "找不到 #{SHARE_TARGET}" unless share_target
abort "找不到 #{TESTS_TARGET}" unless tests_target

share_group = project.main_group.find_subpath(SHARE_DIR, false)
tests_group = project.main_group.find_subpath(TESTS_DIR, false)

# 收集所有要清理的 PBXFileReference UUIDs
file_ref_uuids = []
[share_group, tests_group].each do |g|
  next unless g
  g.children.each { |c| file_ref_uuids << c.uuid if c.isa == 'PBXFileReference' }
end
puts "[info] 待清理 PBXFileReference 共 #{file_ref_uuids.length} 个"

# === 1. 移除引用了这些 file ref 的 PBXBuildFile，从 sources phase + project ===
build_file_uuids_to_remove = []
project.objects.each do |obj|
  next unless obj.isa == 'PBXBuildFile'
  if obj.file_ref && file_ref_uuids.include?(obj.file_ref.uuid)
    build_file_uuids_to_remove << obj.uuid
  end
end

# 从所有 sources phase 的 files 列表中移除
project.objects.each do |obj|
  next unless obj.isa == 'PBXSourcesBuildPhase'
  obj.files.dup.each do |bf|
    if build_file_uuids_to_remove.include?(bf.uuid)
      obj.files.delete(bf)
      puts "[-] 从 sources phase 移除 PBXBuildFile #{bf.uuid}"
    end
  end
end

# 删除 PBXBuildFile 对象本身
build_file_uuids_to_remove.each do |uuid|
  obj = project.objects_by_uuid[uuid]
  obj.remove_from_project if obj
end
puts "[-] 删除 #{build_file_uuids_to_remove.length} 个 PBXBuildFile 对象"

# === 2. 删除 PBXFileReference 对象 ===
file_ref_uuids.each do |uuid|
  obj = project.objects_by_uuid[uuid]
  next unless obj
  # 先从所有 group 的 children 中移除
  project.objects.each do |g|
    next unless g.isa == 'PBXGroup' || g.isa == 'PBXVariantGroup'
    g.children.delete(obj) if g.children.include?(obj)
  end
  # 直接 GC
  project.objects_by_uuid.delete(uuid)
end
puts "[-] 删除 #{file_ref_uuids.length} 个 PBXFileReference 对象"

# === 3. 删除旧 PBXGroup ===
[share_group, tests_group].each do |g|
  next unless g
  name = g.path || g.name
  project.main_group.children.delete(g)
  project.objects_by_uuid.delete(g.uuid)
  puts "[-] 删除 PBXGroup #{name}"
end

# === 4. 创建 SnapDrillShare 同步组 ===
share_sync = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
share_sync.path = SHARE_DIR
share_sync.source_tree = '<group>'
project.main_group.children << share_sync
share_target.file_system_synchronized_groups ||= []
share_target.file_system_synchronized_groups << share_sync
puts "[+] PBXFileSystemSynchronizedRootGroup #{SHARE_DIR} → #{SHARE_TARGET}"

# === 4a. Exception：把 Info.plist + .entitlements 排除出 SnapDrillShare target 自动成员
# （它们由 INFOPLIST_FILE / CODE_SIGN_ENTITLEMENTS 显式引用，不应再进 Resources phase 触发重复处理）
exclude_set = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
exclude_set.target = share_target
exclude_set.membership_exceptions = ['Info.plist', 'SnapDrillShare.entitlements']
share_sync.exceptions ||= []
share_sync.exceptions << exclude_set
puts "[+] Exception: Info.plist + entitlements 排除出 #{SHARE_TARGET} 自动成员"

# === 5. 创建 SnapDrillShareTests 同步组 ===
tests_sync = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
tests_sync.path = TESTS_DIR
tests_sync.source_tree = '<group>'
project.main_group.children << tests_sync
tests_target.file_system_synchronized_groups ||= []
tests_target.file_system_synchronized_groups << tests_sync
puts "[+] PBXFileSystemSynchronizedRootGroup #{TESTS_DIR} → #{TESTS_TARGET}"

# === 6. Exception set：3 个 helper 也编译进 tests target ===
exception_set = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
exception_set.target = tests_target
exception_set.membership_exceptions = SHARED_HELPERS
share_sync.exceptions ||= []
share_sync.exceptions << exception_set
puts "[+] Exception set: #{SHARE_DIR}/{#{SHARED_HELPERS.join(',')}} → #{TESTS_TARGET}"

project.save
puts "\n[OK] 迁移完成。"
