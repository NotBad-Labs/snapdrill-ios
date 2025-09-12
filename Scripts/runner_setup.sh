#!/bin/zsh
# 初始化自托管 runner 的缓存与产物目录到外部挂载存储
# 用法：在 Mac mini 上执行本脚本，确保 NAS 已挂载到 /Volumes/runner_data

set -euo pipefail

MOUNT_POINT="/Volumes/runner_data"

echo "[runner_setup] 使用挂载点: $MOUNT_POINT"

if [ ! -d "$MOUNT_POINT" ]; then
  echo "[runner_setup] 挂载点不存在，请先将 NAS/外置盘挂载到 $MOUNT_POINT"
  exit 1
fi

mkdir -p "$MOUNT_POINT/swiftpm" "$MOUNT_POINT/DerivedData" "$MOUNT_POINT/artifacts"

# SPM 缓存
mkdir -p ~/.cache
if [ ! -L ~/.cache/org.swift.swiftpm ]; then
  rm -rf ~/.cache/org.swift.swiftpm 2>/dev/null || true
  ln -s "$MOUNT_POINT/swiftpm" ~/.cache/org.swift.swiftpm
  echo "[runner_setup] 已链接 SPM 缓存到 $MOUNT_POINT/swiftpm"
fi

# Xcode DerivedData
mkdir -p ~/Library/Developer/Xcode
if [ ! -L ~/Library/Developer/Xcode/DerivedData ]; then
  rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true
  ln -s "$MOUNT_POINT/DerivedData" ~/Library/Developer/Xcode/DerivedData
  echo "[runner_setup] 已链接 DerivedData 到 $MOUNT_POINT/DerivedData"
fi

mkdir -p "$MOUNT_POINT/artifacts"
echo "[runner_setup] 初始化完成。Artifacts 可输出到: $MOUNT_POINT/artifacts"


