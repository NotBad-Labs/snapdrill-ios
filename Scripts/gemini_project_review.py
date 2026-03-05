#!/usr/bin/env python3
# 核心职责：读取指定模块的所有 Swift 文件，调用 Gemini API 生成全项目审查报告

import os
import json
import urllib.request
import sys
import glob

module     = os.environ.get("MODULE", "all")
api_key    = os.environ.get("GEMINI_API_KEY", "")
phase      = os.environ.get("REVIEW_PHASE", "architecture")  # architecture | tests | both

# 模块路径映射
MODULE_PATHS = {
    "core":          "Packages/SnapDrillCore/Sources",
    "data":          "Packages/SnapDrillData/Sources",
    "ui":            "Packages/SnapDrillUI/Sources",
    "features":      "Packages/SnapDrillFeatures/Sources",
    "infrastructure":"Packages/SnapDrillInfrastructure/Sources",
    "tests":         "Packages",           # 扫描所有包下的 Tests 目录
}

def collect_swift_files(module_key: str) -> list[str]:
    """收集指定模块的 Swift 文件路径列表"""
    if module_key == "all":
        paths = list(MODULE_PATHS.values())
    elif module_key in MODULE_PATHS:
        paths = [MODULE_PATHS[module_key]]
    else:
        print(f"未知模块: {module_key}，可选值: {list(MODULE_PATHS.keys()) + ['all']}")
        sys.exit(1)

    files = []
    for base in paths:
        pattern_src   = f"{base}/**/*.swift"
        pattern_tests = f"{base}/**/*Tests*.swift"
        # tests 模块只收集 Tests 目录；其他模块排除 Tests 目录
        if module_key == "tests":
            matches = [f for f in glob.glob(pattern_tests, recursive=True)]
        else:
            matches = [f for f in glob.glob(pattern_src, recursive=True)
                       if "Tests" not in f]
        files.extend(matches)

    return sorted(set(files))

def read_files(file_paths: list[str], char_limit: int = 300_000) -> tuple[str, int]:
    """拼接文件内容，超出 char_limit 时截断，返回 (内容, 实际文件数)"""
    parts = []
    total = 0
    included = 0
    for path in file_paths:
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
            header = f"\n\n// {'='*60}\n// 文件：{path}\n// {'='*60}\n"
            chunk = header + content
            if total + len(chunk) > char_limit:
                parts.append(f"\n\n// [... 剩余文件因上下文限制已省略，共 {len(file_paths) - included} 个文件未展示 ...]")
                break
            parts.append(chunk)
            total += len(chunk)
            included += 1
        except Exception as e:
            parts.append(f"\n// 读取失败：{path} — {e}")
    return "".join(parts), included

# 读取 Gemini 审查上下文
context_path = ".claude/gemini-context.md"
try:
    with open(context_path, "r", encoding="utf-8") as f:
        project_context = f.read()
except FileNotFoundError:
    project_context = "（未找到 .claude/gemini-context.md，请确保文件存在）"

# 收集文件
if phase == "tests":
    files = collect_swift_files("tests")
    review_target = "测试文件"
elif phase == "architecture":
    files = collect_swift_files(module)
    review_target = f"生产代码（模块：{module}）"
else:  # both
    prod_files  = collect_swift_files(module)
    test_files  = collect_swift_files("tests")
    files = prod_files + test_files
    review_target = f"生产代码 + 测试（模块：{module}）"

if not files:
    print(f"未找到任何 Swift 文件（模块={module}，phase={phase}）")
    sys.exit(1)

print(f"收集到 {len(files)} 个文件，开始读取...")
code_content, included_count = read_files(files)
print(f"实际纳入 {included_count}/{len(files)} 个文件，内容长度 {len(code_content)} 字符")

# 构建 Prompt
phase_instructions = {
    "architecture": (
        "## 本次审查重点：架构合规性 + 代码质量\n\n"
        "请按以下顺序审查：\n"
        "1. **逻辑错误和边界情况** — 崩溃、数据丢失、状态不一致\n"
        "2. **Swift 6 并发安全** — @MainActor 隔离、Task 句柄、禁止 @unchecked Sendable\n"
        "3. **SwiftData 使用** — ModelContext 操作是否在正确 actor、跨 context 竞态\n"
        "4. **架构约束合规** — 参考上方项目上下文中的约束清单，"
        "若发现约束的触发条件已成立，请用 🔵 单独标注\n"
        "5. **代码质量** — 冗余逻辑、不必要复杂度\n"
    ),
    "tests": (
        "## 本次审查重点：测试质量\n\n"
        "请按以下顺序审查：\n"
        "1. **假测试检测** — 断言恒真、空 test body、永远通过的测试\n"
        "2. **覆盖率缺口** — 哪些核心路径缺少测试（SM-2 调度、saveContext 失败、分页边界等）\n"
        "3. **测试行为 vs 实现** — 测试是否验证行为而非内部状态\n"
        "4. **测试隔离** — 是否使用 in-memory ModelContainer，是否有磁盘副作用\n"
        "5. **测试命名** — 名称是否清晰描述被测场景\n"
    ),
    "both": (
        "## 本次审查重点：架构合规 + 测试质量（综合审查）\n\n"
        "请分两节输出：\n"
        "### 一、生产代码审查\n"
        "（逻辑错误、并发安全、SwiftData、架构约束）\n\n"
        "### 二、测试质量审查\n"
        "（假测试、覆盖率缺口、测试行为 vs 实现、隔离性）\n\n"
        "最后输出：\n"
        "### 三、规模评估\n"
        "（哪些约束的触发条件已接近成立，用 🔵 标注并附证据）\n"
    ),
}

prompt = (
    "你是一个经验丰富的 iOS Swift 代码审查专家。\n"
    "以下是本项目的架构背景和约束说明，**请在审查前完整阅读**：\n\n"
    f"```\n{project_context}\n```\n\n"
    "---\n\n"
    f"{phase_instructions.get(phase, phase_instructions['architecture'])}\n"
    "**输出格式**：\n"
    "- 🔴 严重：必须修复\n"
    "- 🟡 警告：强烈建议修复\n"
    "- 🟢 建议：可选优化\n"
    "- 🔵 规模评估：某约束的触发条件已接近或已满足（附证据）\n"
    "- 如无问题，明确说明「无问题」\n\n"
    "每个问题注明具体文件/行号和修改建议。请用中文回复。\n\n"
    f"---\n\n## 待审查代码（{review_target}）\n\n"
    f"```swift\n{code_content}\n```"
)

# 模型降级链（2026-03 实际可用模型，按代码审查能力 + 稳定性排序）
# 来源：https://ai.google.dev/gemini-api/docs/models
# - gemini-3.1-pro-preview：最强，但 Preview 阶段持续 503
# - gemini-2.5-pro：GA 稳定版，能力接近 3.1-pro，首选备用
# - gemini-2.5-flash：GA 稳定快，兜底保证审查能完成
# 已排除：gemini-3-pro-preview（3月9日下线）、gemini-2.0-flash（弃用中）
GEMINI_MODELS = [
    "gemini-3.1-pro-preview",
    "gemini-2.5-pro",
    "gemini-2.5-flash",
]

import urllib.error

def call_gemini_with_fallback(prompt_text: str, api_key: str, timeout: int = 300) -> tuple[str, str]:
    """
    依次尝试 GEMINI_MODELS 中的模型，遇到 503/超时/连接错误自动降级。
    返回 (响应文本, 实际使用的模型名)。
    4xx 错误（认证失败等）不重试，直接抛出。
    """
    payload = {
        "contents": [{"parts": [{"text": prompt_text}]}],
        "generationConfig": {"temperature": 0.1},
    }
    last_error = None
    for model in GEMINI_MODELS:
        url = (
            "https://generativelanguage.googleapis.com/v1beta"
            f"/models/{model}:generateContent?key={api_key}"
        )
        print(f"尝试模型：{model}...")
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                result = json.loads(resp.read())
                text = result["candidates"][0]["content"]["parts"][0]["text"]
                print(f"✅ 成功（模型：{model}）")
                return text, model
        except urllib.error.HTTPError as e:
            if e.code in (429, 503):
                print(f"⚠️ {model} 返回 HTTP {e.code}，降级到下一个模型...")
                last_error = e
                continue
            else:
                # 4xx（401/403 等）不重试
                raise
        except Exception as e:
            print(f"⚠️ {model} 调用失败（{e}），降级到下一个模型...")
            last_error = e
            continue
    raise RuntimeError(f"所有模型均不可用，最后错误：{last_error}")

print(f"调用 Gemini API（含自动降级）...")
try:
    review_text, used_model = call_gemini_with_fallback(prompt, api_key)
except Exception as e:
    review_text = f"⚠️ Gemini API 调用失败（所有模型均不可用）：{e}"
    used_model = "N/A"

module_label = module.upper()
phase_label  = {"architecture": "架构审查", "tests": "测试审查", "both": "综合审查"}.get(phase, phase)

comment = (
    f"## Gemini 全项目审查 — {module_label} / {phase_label}\n\n"
    f"**审查范围**：{review_target}（{included_count} 个文件）\n\n"
    "---\n\n"
    + review_text
    + f"\n\n---\n*由 Gemini 自动生成（模型：`{used_model}`）。结论仅供参考，最终决策由团队确认。*"
)

output_file = f"review_{module}_{phase}.txt"
with open(output_file, "w", encoding="utf-8") as f:
    f.write(comment)

print(f"审查完成，结果已写入 {output_file}")
