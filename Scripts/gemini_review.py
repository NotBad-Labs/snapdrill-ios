#!/usr/bin/env python3
# 核心职责：读取 PR diff，调用 Gemini API 生成 code review，写入 review_comment.txt

import os
import sys
import urllib.error
from gemini_utils import call_gemini_with_fallback, MODELS_DEEP

pr_title = os.environ.get("PR_TITLE", "")
api_key  = os.environ.get("GEMINI_API_KEY", "")

# 可选：读取项目架构上下文（约束、例外规则等），减少 Gemini 假阳性
# 当前未实现 .claude/gemini-context.md 文件；如未来需要 inline 项目约束，
# 创建该文件即可被自动读取。否则保持空 context（不影响功能）。
gemini_context = ""
context_path = os.path.join(os.path.dirname(__file__), "..", ".claude", "gemini-context.md")
if os.path.exists(context_path):
    with open(context_path, "r", encoding="utf-8", errors="replace") as f:
        gemini_context = f.read()

with open("pr_diff.txt", "r", encoding="utf-8", errors="replace") as f:
    diff = f.read()

if not diff.strip():
    print("No reviewable file changes, skipping.")
    with open("review_comment.txt", "w") as f:
        f.write("## Gemini Code Review\n\n本次 PR 无可审查的文件变更，跳过自动审查。")
    sys.exit(0)

if len(diff) > 40000:
    diff = diff[:40000] + "\n\n[... diff 过长，已截断 ...]"

# 判断是否为非代码 PR（无 .swift 变更时使用文档审查 prompt）
has_swift_files = any(
    line.startswith("diff --git") and line.endswith(".swift")
    for line in diff.splitlines()
    if line.startswith("diff --git")
)
is_doc_only = not has_swift_files

# 读取全量 Swift 文件内容，让 Gemini 看到未变动的 ViewModel 声明等关键上下文，减少假阳性
full_files = ""
if os.path.exists("full_files.txt"):
    with open("full_files.txt", "r", encoding="utf-8", errors="replace") as f:
        full_files = f.read()
    if len(full_files) > 400000:
        full_files = full_files[:400000].rsplit('\n', 1)[0] + "\n\n[... 完整文件内容过长，已截断 ...]"

full_files_section = (
    "\n\n全量 Swift 文件内容（完整代码库上下文，用于避免因仅看 diff 产生的误报）：\n```\n"
    + full_files
    + "\n```"
) if full_files.strip() else ""

context_section = (
    "以下是本项目的架构约束与例外规则，审查时必须遵照执行：\n\n"
    + gemini_context
    + "\n\n---\n\n"
) if gemini_context.strip() else ""

if is_doc_only:
    prompt = (
        "你是一位资深产品经理和技术文档专家。请审查以下文档 PR。\n\n"
        f"PR 标题：{pr_title}\n\n"
        "审查重点：\n"
        "1. **内容完整性** — 是否有重要遗漏或自相矛盾的地方？\n"
        "2. **逻辑一致性** — 各章节之间的观点是否一致？用户旅程是否与产品原则对齐？\n"
        "3. **可操作性** — 文档中的原则和决策是否足够具体，能指导实际开发？\n"
        "4. **盲点** — 有没有文档没考虑到的重要场景、用户群体或风险？\n"
        "5. **表达质量** — 是否清晰易读？有无歧义或冗余？\n\n"
        "请用中文回复。格式：\n"
        "- 🔴 严重：内容有重大遗漏或逻辑错误\n"
        "- 🟡 建议：可以改进的地方\n"
        "- 🟢 亮点：值得肯定的设计决策\n"
        "- 如文档质量良好，明确说明「无问题」\n\n"
        "每个问题注明具体章节和修改建议。\n\n"
        "PR Diff:\n```\n"
        + diff
        + "\n```"
    )
else:
    prompt = (
        context_section
        + "你是一个经验丰富的 iOS Swift 代码审查专家。请审查以下 PR。\n\n"
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
        + full_files_section
    )

try:
    # PR diff review 使用深度审查链（注入全量文件后 prompt 可达 ~500K 字符，需要更强推理）
    review_text, used_model = call_gemini_with_fallback(prompt, api_key, timeout=300, models=MODELS_DEEP)
except Exception as e:
    review_text = f"⚠️ Gemini API 调用失败（所有模型均不可用）：{e}"
    used_model = "N/A"

comment = (
    "## Gemini Code Review\n\n"
    + review_text
    + f"\n\n---\n*由 Gemini 自动生成（模型：`{used_model}`）。合并前请人工确认。*"
)

with open("review_comment.txt", "w", encoding="utf-8") as f:
    f.write(comment)

print("Review generated.")
