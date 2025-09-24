#!/bin/bash
# Scripts/quality_gate.sh (Deprecated)
# 兼容旧入口：转发到 Scripts/check-quality.sh（双阈值 + 快照）

set -euo pipefail

SELF_DIR=$(cd "$(dirname "$0")" && pwd)
TARGET="$SELF_DIR/check-quality.sh"

echo "⚠️  Deprecated: Scripts/quality_gate.sh 已被替代，将转发到 check-quality.sh"
echo "   ↳ 建议直接使用：zsh Scripts/check-quality.sh 或 zsh Scripts/local-ci.sh"

if [[ ! -x "$TARGET" ]]; then
  echo "❌ 找不到 $TARGET，请检查仓库脚本"
  exit 127
fi

# 兼容旧参数：--ci-parity（新脚本无该选项，此处仅提示并忽略）
NEW_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--ci-parity" ]]; then
    echo "ℹ️ 提示：check-quality.sh 无 --ci-parity 选项，将忽略该参数"
  else
    NEW_ARGS+=("$arg")
  fi
done

exec zsh "$TARGET" "${NEW_ARGS[@]}"
