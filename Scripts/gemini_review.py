#!/usr/bin/env python3
# 核心职责：读取 PR diff，调用 Gemini API 生成 code review，写入 review_comment.txt

import os
import json
import urllib.request
import sys

pr_title = os.environ.get("PR_TITLE", "")
api_key  = os.environ.get("GEMINI_API_KEY", "")

with open("pr_diff.txt", "r", encoding="utf-8", errors="replace") as f:
    diff = f.read()

if not diff.strip():
    print("No reviewable file changes, skipping.")
    with open("review_comment.txt", "w") as f:
        f.write("## Gemini Code Review\n\n本次 PR 无 Swift/配置文件变更，跳过自动审查。")
    sys.exit(0)

if len(diff) > 40000:
    diff = diff[:40000] + "\n\n[... diff 过长，已截断 ...]"

prompt = (
    "你是一个经验丰富的 iOS Swift 代码审查专家。请审查以下 PR。\n\n"
    f"PR 标题：{pr_title}\n\n"
    "审查重点（按优先级）：\n"
    "1. **逻辑错误和边界情况** — 潜在崩溃、空指针、数组越界\n"
    "2. **Swift 6 并发安全性** — @MainActor 隔离是否正确？Task 是否保存了句柄？禁止 @unchecked Sendable\n"
    "3. **SwiftData 使用** — ModelContext 操作是否在正确 actor？是否有跨 context 竞态？\n"
    "4. **架构符合性** — 违反以下规范时必须指出：\n"
    "   - 禁止新增 Domain 层、UseCase 层、Repository 协议\n"
    "   - ViewModel 必须是 @Observable @MainActor final class\n"
    "   - 禁止 force unwrap !、any existentials\n"
    "   - 禁止 print()，必须用 SnapDrillLogger\n"
    "5. **代码质量** — 是否存在不必要的复杂度？\n\n"
    "请用中文回复。格式：\n"
    "- 🔴 严重：必须修复才能合并\n"
    "- 🟡 警告：强烈建议修复\n"
    "- 🟢 建议：可选优化\n"
    "- 如代码质量良好，明确说明「无问题」\n\n"
    "每个问题注明具体文件/位置和修改建议。\n\n"
    "PR Diff:\n```\n"
    + diff
    + "\n```"
)

payload = {
    "contents": [{"parts": [{"text": prompt}]}],
    "generationConfig": {"temperature": 0.1},
}

url = (
    "https://generativelanguage.googleapis.com/v1beta"
    f"/models/gemini-3.1-pro-preview:generateContent?key={api_key}"
)

try:
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        result = json.loads(resp.read())
        review_text = result["candidates"][0]["content"]["parts"][0]["text"]
except Exception as e:
    review_text = f"⚠️ Gemini API 调用失败：{e}"

comment = (
    "## Gemini Code Review\n\n"
    + review_text
    + "\n\n---\n*由 Gemini 自动生成。合并前请人工确认。*"
)

with open("review_comment.txt", "w", encoding="utf-8") as f:
    f.write(comment)

print("Review generated.")
