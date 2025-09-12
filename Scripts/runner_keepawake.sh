#!/bin/zsh

# 目的：在 Runner 作业运行时强制保持唤醒，避免显示器/系统睡眠导致的中断。
# 为什么：CI 可能长时间无用户交互，系统若进入睡眠会中断模拟器与构建。

set -euo pipefail

# 使用 caffeinate 保持唤醒；-d 防止显示器睡眠，-i 防止系统空闲睡眠，-m 防止磁盘睡眠
echo "[keepawake] 保持唤醒中，按 Ctrl+C 退出..."
caffeinate -dim


