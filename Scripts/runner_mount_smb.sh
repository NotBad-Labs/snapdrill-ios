#!/bin/zsh

# 目的：将群晖 SMB 共享自动挂载到 /Volumes/runner_data。
# 为什么：让缓存与产物写入高速网络盘，释放本机 256G 空间，且便于集中清理与备份。

set -euo pipefail

if [ $# -lt 3 ]; then
  echo "用法: $0 <smb_host> <share_name> <username> [mount_point=/Volumes/runner_data]"
  echo "示例: $0 192.168.1.10 runner_data ci-user"
  exit 1
fi

SMB_HOST="$1"
SHARE_NAME="$2"
SMB_USER="$3"
MOUNT_POINT="${4:-/Volumes/runner_data}"

mkdir -p "$MOUNT_POINT"

echo "[mount] 即将挂载 //${SMB_HOST}/${SHARE_NAME} 到 $MOUNT_POINT"
echo "[mount] 系统将提示输入 SMB 用户 ${SMB_USER} 的密码"

# 使用 Apple 的 mount_smbfs 进行挂载
mount_smbfs //${SMB_USER}@${SMB_HOST}/${SHARE_NAME} "$MOUNT_POINT"

echo "[mount] 挂载完成。可在登录项中加入 Automator/脚本实现开机自动挂载。"


