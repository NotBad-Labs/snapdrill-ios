#!/bin/zsh

# 目的：一键在“runner”专用账户下完成基本加固与自托管 Runner 安装前置工作。
# 为什么：减少手工点选，保证每次安装一致，避免因睡眠/未接受许可/未创建目录导致的 CI 失败。

set -euo pipefail

echo "[bootstrap] 开始执行基础设置..."

# 1) 接受 Xcode 许可（若未接受会导致 xcodebuild 报错）
if /usr/bin/xcodebuild -checkFirstLaunchStatus 2>/dev/null | grep -q 'requiresFirstLaunchExperience'; then
  echo "[bootstrap] 首次启动 Xcode 许可..."
  sudo xcodebuild -license accept || true
fi

# 2) 安装命令行工具（某些系统可能未装）
if ! xcode-select -p >/dev/null 2>&1; then
  echo "[bootstrap] 安装 Command Line Tools..."
  xcode-select --install || true
fi

# 3) 关闭睡眠（防止作业中断）。注意：台式机推荐；若是笔记本请接电并谨慎使用。
echo "[bootstrap] 关闭系统睡眠/显示器睡眠..."
sudo systemsetup -setcomputersleep Never 2>/dev/null || true
sudo systemsetup -setdisplaysleep Never 2>/dev/null || true
sudo systemsetup -setharddisksleep Never 2>/dev/null || true

# 4) 创建常用目录
mkdir -p ~/.cache ~/Library/Developer/Xcode ~/bin

echo "[bootstrap] 完成。下一步：运行 runner_mount_smb.sh 挂载群晖，并执行 runner_setup.sh 建立缓存链接。"


