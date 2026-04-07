#!/bin/bash
# Coze Bot 产品文档对抗性审查脚本
#
# 用法:
#   审查 PR diff:     ./Scripts/coze-review.sh <分支名>
#   审查完整文件:     ./Scripts/coze-review.sh --file <文件路径>
#   审查多个文件:     ./Scripts/coze-review.sh --files <文件1> <文件2> ...
#
# 示例:
#   ./Scripts/coze-review.sh docs/549-hidden-competitors
#   ./Scripts/coze-review.sh --file docs/product/product-vision.md
#   ./Scripts/coze-review.sh --files docs/product/product-vision.md docs/product/product-design.md
#
# 环境变量:
#   COZE_PAT    - Coze Personal Access Token (必须)
#   COZE_BOT_ID - Coze Bot ID (默认: 7625854713786974260)

set -euo pipefail

COZE_BOT_ID="${COZE_BOT_ID:-7625854713786974260}"

if [ -z "${COZE_PAT:-}" ]; then
  echo "错误: 请设置 COZE_PAT 环境变量"
  echo "export COZE_PAT='pat_xxx'"
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "用法:"
  echo "  $0 <分支名|diff文件路径>        审查 diff"
  echo "  $0 --file <文件路径>             审查完整文件"
  echo "  $0 --files <文件1> [文件2] ...   审查多个完整文件"
  exit 1
fi

# 项目基线上下文（消除因预训练知识过时导致的假阳性）
BASELINE_CONTEXT="## 项目基线（必须接受，不质疑；如有疑问请先用网络搜索验证）
- 本项目基于 iOS 26.0+（Xcode 26.4, Swift 6.3）— iOS 26 是 Apple 在 WWDC 2025 发布的版本，2026 年当前主力版本。如果你对此有疑问，请先搜索 'WWDC 2025 iOS 26' 验证
- 产品定位：效率工具，不是教育平台。价值链：采集 → 管理 → 导出/打印（复习是独立附加值）
- 数据安全：零注册、纯本地、图片是真相、Profile 隔离
- 中国区定价 ¥8/月、美区 \$1.99/月 是刻意的分市场定价策略
- Analytics 默认开启是产品决策（vision.md 明确规定）

## 重要提示
- 遇到不确定的事实性声明（版本号、API 存在性、行业数据等），请先通过网络搜索验证，不要基于预训练知识直接判定为错误
- 如果搜索后仍无法确认，标注为「需人工确认」而不是判定为错误"

# 解析模式
MODE="diff"
INPUT=""
FILES=()

if [ "$1" = "--file" ]; then
  MODE="file"
  shift
  if [ $# -lt 1 ]; then
    echo "错误: --file 需要指定文件路径"
    exit 1
  fi
  FILES=("$1")
elif [ "$1" = "--files" ]; then
  MODE="files"
  shift
  if [ $# -lt 1 ]; then
    echo "错误: --files 需要指定至少一个文件路径"
    exit 1
  fi
  FILES=("$@")
else
  MODE="diff"
  INPUT="$1"
fi

# 构造内容
if [ "$MODE" = "diff" ]; then
  # Diff 模式（兼容旧用法）
  if [ -f "$INPUT" ]; then
    CONTENT=$(cat "$INPUT")
    echo "读取文件: $INPUT"
  else
    CONTENT=$(git diff "develop...$INPUT" 2>/dev/null || git diff "$INPUT" 2>/dev/null)
    echo "获取 diff: develop...$INPUT"
  fi

  if [ -z "$CONTENT" ]; then
    echo "错误: 没有 diff 内容"
    exit 1
  fi

  PROMPT="请对以下产品文档变更进行对抗性审查。

${BASELINE_CONTEXT}

## 审查维度
A. 修复准确性 — 每处修改是否真正解决了问题？
B. 完整性 — 同一个问题在多处出现时，是否全部修复？
C. 副作用 — 修改是否引入了新的矛盾或不一致？
D. 措辞质量 — 修改后的文案是否清晰、准确？

## Diff 内容

\`\`\`diff
$CONTENT
\`\`\`

## 输出要求
- 中文回复，技术术语保留英文，不加 emoji
- 每个发现标注严重度（阻塞/建议/无问题）
- 最后明确给出结论：LGTM（可合并）或 需修改（列出阻塞项）"

elif [ "$MODE" = "file" ] || [ "$MODE" = "files" ]; then
  # 完整文件模式（推荐：消除截断导致的假阳性）
  CONTENT=""
  for f in "${FILES[@]}"; do
    if [ ! -f "$f" ]; then
      echo "警告: 文件不存在: $f，跳过"
      continue
    fi
    FNAME=$(basename "$f")
    FCONTENT=$(cat "$f")
    CONTENT="${CONTENT}
### ${FNAME}

\`\`\`markdown
${FCONTENT}
\`\`\`

"
    echo "读取文件: $f"
  done

  if [ -z "$CONTENT" ]; then
    echo "错误: 没有可审查的文件内容"
    exit 1
  fi

  PROMPT="请对以下产品文档进行全量审查。

${BASELINE_CONTEXT}

## 审查维度
A. 事实性 — 类型名、方法名、模块名是否可能存在幽灵引用？行为描述是否自洽？
B. 文档间一致性 — 与其他产品文档是否有矛盾？
C. 完整性 — 是否有遗漏的重要内容？功能状态标注是否准确？
D. 过时内容 — 是否有已过时的描述、日期、版本号？
E. 结构与可维护性 — 信息是否有不必要的重复？职责边界是否清晰？

## 文档内容

${CONTENT}

## 输出要求
- 中文回复，技术术语保留英文，不加 emoji
- 每个发现标注严重度（严重/中等/轻微）
- 按维度 A-E 分组输出
- 如果某个维度没有发现问题，明确说明「无问题」"
fi

# 截断保护（Coze token 限制）
PROMPT_LENGTH=${#PROMPT}
MAX_LENGTH=50000
if [ "$PROMPT_LENGTH" -gt "$MAX_LENGTH" ]; then
  echo "警告: 内容超过 ${MAX_LENGTH} 字符（当前 ${PROMPT_LENGTH}），建议拆分文件逐个审查"
  echo "继续发送截断版本..."
  PROMPT="${PROMPT:0:$MAX_LENGTH}

... (内容被截断，原始长度 $PROMPT_LENGTH 字符。建议拆分文件逐个审查以获得完整分析)"
fi

# 转义 JSON 特殊字符
PROMPT_ESCAPED=$(echo "$PROMPT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")

# 调用 Coze API
echo "正在调用 Coze Bot 审查..."
echo "---"

RESPONSE=$(curl -s --max-time 300 --location --request POST 'https://api.coze.cn/v3/chat' \
  --header "Authorization: Bearer $COZE_PAT" \
  --header 'Content-Type: application/json' \
  --data-raw "{
    \"bot_id\": \"$COZE_BOT_ID\",
    \"user_id\": \"claude-code\",
    \"stream\": true,
    \"auto_save_history\": false,
    \"additional_messages\": [
      {
        \"role\": \"user\",
        \"content\": $PROMPT_ESCAPED,
        \"content_type\": \"text\"
      }
    ]
  }" 2>&1)

# 提取最终回复（SSE 格式：event: 和 data: 在不同行）
ANSWER=$(echo "$RESPONSE" | grep 'conversation.message.completed' -A1 | grep '"type":"answer"' | sed 's/^data://' | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content',''))" 2>/dev/null)

if [ -z "$ANSWER" ]; then
  # 检查是否有错误
  ERROR=$(echo "$RESPONSE" | grep '^event:' | tail -5)
  echo "Coze API 调用失败或无回复:"
  echo "$ERROR"
  exit 1
fi

echo "$ANSWER"
echo "---"
echo "Coze 审查完成。"
