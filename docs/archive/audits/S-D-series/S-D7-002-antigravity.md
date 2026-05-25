---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

# S-D7-002 三方对抗流程治理审计与机械化提案 — Antigravity 篇

> **核心红线声明**：本审计方案及脚本完全以**独立对抗提案**形式落盘于工作区相对路径 `docs/audits/S-D7-002-antigravity.md`。为严格执行控制变量法物理隔离，我们**没有**在主代码库分支中直接应用任何真实 hook 配置或 CI 变动。本分支 `audit/antigravity-S-D7-002` 最终仅提交本 Markdown 方案文件，保持工作区绝对洁净。
> 
> **中文回复承诺**：根据项目最高级别宪法要求，本报告采用**中文简体**撰写。

---

## 1. 问题背景与实证分析

在 SnapDrill 协作体系中，`F-005`（对抗性审查）是保障核心产品逻辑和技术规范不受 AI 幻觉污染的最高级别纪律防线。`docs/workflow.md:108-120` 明确规定：“所有 PR 必须完成 review 后合并，且 Review 结论必须留痕”。

然而，实证抽样暴露出人性和纯人工纪律在项目维护中的天然退化趋势：
* **违规案例（PR #742「docs: 归零审计」）**：
  * **reviews 数量**：`0`
  * **comments 数量**：`0`
  * **PR Body**：完全没有 Codex / Gemini / Xcode review 的留痕签名。
  * **结果**：该 PR 依然被成功合并到了核心开发分支 `develop` 中。

**根本原因**：目前的 `F-005` 防线完全依赖开发者和 AI Agent 的“自觉性”。无任何机械化、强隔离的阻断机制，形成了极易导致纪律漂移的“纸面法规”。

为了终结这种“纸面纪律 vs 实际执行漂移”的现象，Antigravity 提出了基于 **本地 Git Hook + CI 双重刚性阻断 + 智能豁免判定** 的高维治理设计。

---

## 2. 7 项设计决策独立表态

针对任务定义书要求的 7 项核心决策，Antigravity 站在彻底消灭漂移的流程安全视角，独立表态并进行系统性论证：

| 决策点 | 独立表态与论证 |
| :--- | :--- |
| **1. 强化路径** | **GitHub Actions CI PR Linter 强阻断 + Git Hook 双重防线**。<br>1) 在 CI 中运行独立 Linter 工作流拦截未留痕的 PR，作为**第一权威合并门禁**；<br>2) 在本地配置 `pre-push` Hook 作为**第二辅助防线**，防患于未然，避免非标代码推送到远程仓造成 CI 资源浪费。 |
| **2. 豁免条件设计** | **高精度、机器可读（Machine-readable）的自动文件白名单 + 紧急手动覆盖**。<br>1) **自动豁免**：PR 中仅包含 Markdown 文档变更（如 `docs/**/*.md` / `*.md`）及 docaudit 豁免文件（如 `Scripts/audit/policy.yaml`）时，由检测引擎自动识别并豁免 review 留痕校验。<br>2) **禁止豁免（黑名单）**：一旦变更文件中包含任何 `.swift`、`.swiftlint.yml`、`.xctestplan`、`.xcodeproj/` 或非审计 Python 脚本，则自动豁免机制彻底失效，必须强制校验留痕。<br>3) **紧急逃逸**：允许在极端紧急情况下在 PR Body 中写 `[skip review] 理由: <紧急理由>`，但理由必须通过长度与有效内容校验。 |
| **3. 留痕格式标准化** | **HTML 注释边界包裹的标准化 Markdown 签名段**。<br>PR Body 中必须包含被以下注释包裹的块结构：<br>`<!-- F-005-REVIEW-SIGNATURE-START -->`<br>`## 🤖 对抗性审查留痕 (F-005)`<br>`- [x] **Codex Review**: [链接或记录]`<br>`- [x] **Gemini Review**: [链接或记录]`<br>`- [ ] **Xcode Review**: [N/A]`<br>`<!-- F-005-REVIEW-SIGNATURE-END -->`<br>使用打勾状态 `[x]` 进行符号级抓取，严禁使用非标准的前缀或随意空置。 |
| **4. 检测时机** | **Shift-Left 前置阻断（Push 时 + PR 合并前双时点）**。<br>在本地 push 触发时进行轻量快检，在 PR Pipeline 阶段进行全量严检并阻断 Merge，确保不留痕 PR 绝对无法合入 `develop`/`main`。 |
| **5. 历史 PR 处理** | **立足当下，新增 PR 强阻断，不作历史追溯**。<br>历史 PR（如 #742）不再强制打补丁 review（避免大量无效 commit 阻塞开发速度），而是从本机制部署后的第一个 PR 开始，全面实施 100% 刚性校验。 |
| **6. 直推 develop 场景** | **利用本地 `pre-push` Hook 进行 Commit 标记扫描**。<br>即使存在 `ALLOW_DIRECT_PUSH=1` 紧急直推，如果改动中包含了非文档类代码变更，本地 `pre-push` 仍会强制校验最近的 Commit Message，要求必须包含 `[review-by: codex & gemini]` 强标签，否则物理阻断推送。 |
| **7. 与 Sprint Contract 联动** | **在 S-D7-003 中无缝共享 Hook 框架**。<br>1) 当 `sprint-contract` 执行 closeout 步骤时，将自动校验 PR 描述中的 F-005 签名块状态；<br>2) 简述与 S-D7-003（sprint contract 校验）的协作预期：未来两者共享统一的 Hook 底层逻辑（如统一由 `Scripts/audit/pre-push-validator.py` 承载），统一对 PR 及 Commit 状态进行强契约校验，实现高内聚低耦合。 |

---

## 3. 机械化拦截方案具体实现

Antigravity 设计的拦截方案覆盖了 **CI Linter 检测层**、**本地 Git Hook 防御层**、**PR 模板展示层** 和 **Skill 规范改进** 四大维度，构筑坚不可摧的立体防御。

### 3.1 CI 检查机制：PR Body 校验脚本与 Workflow 配置

#### A. 提案脚本 `Scripts/audit/check_f005_review.py`
本脚本是实现**豁免条件机器可读**与**签名体例高精度解析**的业务核心。

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Scripts/audit/check_f005_review.py
Antigravity 独立设计：F-005 对抗性审查 PR 留痕机械化校验脚本
"""
import sys
import re
import os
import subprocess

def get_changed_files():
    """获取当前 PR 相比于基线分支的变更文件列表"""
    base_ref = os.getenv("GITHUB_BASE_REF", "develop")
    try:
        # 在 CI 环境中提取分支变更 diff
        cmd = ["git", "diff", "--name-only", f"origin/{base_ref}...HEAD"]
        res = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return [f.strip() for f in res.stdout.splitlines() if f.strip()]
    except Exception:
        try:
            cmd = ["git", "diff", "--name-only", f"{base_ref}...HEAD"]
            res = subprocess.run(cmd, capture_output=True, text=True, check=True)
            return [f.strip() for f in res.stdout.splitlines() if f.strip()]
        except Exception:
            # 降级：不触发豁免，走强制留痕校验
            return []

def is_pr_exempted(changed_files):
    """机器可读判定：PR 是否符合自动豁免 review 留痕的条件"""
    if not changed_files:
        return False
    
    # 豁免白名单正则匹配模式
    exempt_patterns = [
        r"^docs/.*\.md$",
        r"^docs/.*\.tsv$",
        r"^.*\.md$",
        r"^Scripts/audit/policy\.yaml$"
    ]
    
    # 绝对禁止豁免的黑名单正则匹配模式（Swift代码、构建计划、CI 流程、核心脚本）
    blacklist_patterns = [
        r"\.swift$",
        r"\.swiftlint\.yml$",
        r"\.xctestplan$",
        r"\.xcodeproj/",
        r"^.github/workflows/",
        r"^Scripts/(?!audit/policy\.yaml)" # 禁止改动任何非豁免的 Scripts 脚本
    ]
    
    # 1. 检查是否存在黑名单文件
    for file in changed_files:
        for pattern in blacklist_patterns:
            if re.search(pattern, file):
                return False
                
    # 2. 检查是否所有文件都在白名单内
    for file in changed_files:
        matched = False
        for pattern in exempt_patterns:
            if re.match(pattern, file):
                matched = True
                break
        if not matched:
            return False # 存在任何非白名单文件，拒绝自动豁免
            
    return True

def validate_pr_body(pr_body, changed_files):
    """高精度校验 PR Body 留痕内容的合规性"""
    # 1. 检查手动逃逸标记
    bypass_match = re.search(r"\[skip review\]\s*理由\s*:\s*([^\n\r]+)", pr_body, re.I)
    if bypass_match:
        reason = bypass_match.group(1).strip()
        # 必须提供超过 5 个字符的具体理由，不能使用默认括弧或空白
        if len(reason) > 5 and not reason.startswith("["):
            print(f"ℹ️ 检测到合法手动紧急避险标记 [skip review]！逃逸理由: '{reason}'。予以通过。")
            return True, "Manual bypass approved."
        else:
            return False, "❌ 校验拒绝：使用 [skip review] 紧急逃逸标记时，必须在冒号后填写详细合法的避险理由！"

    # 2. 匹配标准留痕标签块
    block_match = re.search(
        r"<!-- F-005-REVIEW-SIGNATURE-START -->([\s\S]*?)<!-- F-005-REVIEW-SIGNATURE-END -->",
        pr_body
    )
    if not block_match:
        return False, (
            "❌ 校验失败：在 PR 描述中未检测到合规的 F-005 对抗性审查留痕签名块！\n"
            "请确保您的 PR 包含以下完整闭环标记：\n"
            "<!-- F-005-REVIEW-SIGNATURE-START -->\n"
            "## 🤖 对抗性审查留痕 (F-005)\n"
            "- [x] **Codex Review**: [链接或审查记录]\n"
            "- [x] **Gemini Review**: [链接或审查记录]\n"
            "- [ ] **Xcode Review**: [N/A]\n"
            "<!-- F-005-REVIEW-SIGNATURE-END -->"
        )
        
    block_content = block_match.group(1)
    
    # 3. 提取 Codex / Gemini / Xcode 各行打勾状态与填写的说明
    codex_match = re.search(r"-\s*\[([\sxX])\]\s*\*\*Codex\s*Review\*\*:\s*([^\n\r]+)", block_content)
    gemini_match = re.search(r"-\s*\[([\sxX])\]\s*\*\*Gemini\s*Review\*\*:\s*([^\n\r]+)", block_content)
    xcode_match = re.search(r"-\s*\[([\sxX])\]\s*\*\*Xcode\s*Review\*\*:\s*([^\n\r]+)", block_content)
    
    if not codex_match or not gemini_match:
        return False, "❌ 校验失败：对抗性审查留痕块中必须完整包含 Codex Review 和 Gemini Review 两行！"
        
    codex_checked = codex_match.group(1).lower() == 'x'
    codex_desc = codex_match.group(2).strip()
    
    gemini_checked = gemini_match.group(1).lower() == 'x'
    gemini_desc = gemini_match.group(2).strip()
    
    # 防止空模板或默认占位符绕过
    placeholder_pattern = re.compile(r"\[填写|\[填入|\[证据|placeholder|tbd|\.\.\.", re.I)
    
    if not codex_checked or not gemini_checked:
        return False, "❌ 校验失败：Codex Review 和 Gemini Review 必须均标记为 [x] 已完成状态！"
        
    if placeholder_pattern.search(codex_desc) or len(codex_desc) < 5:
        return False, f"❌ 校验失败：Codex Review 的审查记录 '{codex_desc}' 无效或包含了占位符，请补充真实的审计证据！"
        
    if placeholder_pattern.search(gemini_desc) or len(gemini_desc) < 5:
        return False, f"❌ 校验失败：Gemini Review 的审查记录 '{gemini_desc}' 无效或包含了占位符，请补充真实的审计证据！"
        
    # 4. 强类型 UI 变更检测与 Xcode Review 联动校验
    has_ui_changes = any(re.search(r"View\.swift|Assets\.xcassets", f) for f in changed_files)
    if has_ui_changes:
        if not xcode_match:
            return False, "❌ 校验失败：检测到项目包含 UI 文件的修改，必须提供 Xcode Review 行！"
        xcode_checked = xcode_match.group(1).lower() == 'x'
        xcode_desc = xcode_match.group(2).strip()
        if not xcode_checked:
            return False, "❌ 校验失败：检测到 UI 变更，Xcode Review 必须打勾 [x] 并附带验证截图/说明！"
        if placeholder_pattern.search(xcode_desc) or len(xcode_desc) < 5:
            return False, f"❌ 校验失败：Xcode Review 的审查记录 '{xcode_desc}' 无效或包含了占位符！"
            
    return True, "✅ 恭喜！F-005 对抗性审查留痕校验通过。"

def main():
    # 从环境变量或 GitHub Pull Request Event JSON 中获取 PR body
    pr_body_path = os.getenv("GITHUB_EVENT_PATH")
    pr_body = ""
    
    if pr_body_path and os.path.exists(pr_body_path):
        import json
        try:
            with open(pr_body_path, "r", encoding="utf-8") as f:
                event_data = json.load(f)
                pr_body = event_data.get("pull_request", {}).get("body", "")
        except Exception:
            pass
            
    if not pr_body:
        # 本地降级：从临时文件或命令行读取，默认读取标准输入
        pr_body = sys.stdin.read()
        
    changed_files = get_changed_files()
    
    # 自动豁免检查
    if is_pr_exempted(changed_files):
        print("ℹ️ 自动豁免启动：本 PR 仅包含文档/配置修改，符合自动豁免 F-005 留痕规则。自动放行。")
        sys.exit(0)
        
    success, message = validate_pr_body(pr_body, changed_files)
    print(message)
    if not success:
        sys.exit(1)
        
    sys.exit(0)

if __name__ == "__main__":
    main()
```

#### B. 提案 Workflow 配置 `.github/workflows/review-linter.yml`
作为 CI 刚性门禁的入口：

```yaml
name: Antigravity PR Review Linter

on:
  pull_request:
    types: [opened, edited, synchronized]
    branches: [ "develop", "main" ]

jobs:
  check-review-signature:
    name: Check F-005 Review Signature
    runs-on: ubuntu-latest
    timeout-minutes: 5

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0 # 完整拉取以提取精准的 changed files diff

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Run Antigravity F-005 Linter
        env:
          GITHUB_BASE_REF: ${{ github.base_ref }}
          GITHUB_EVENT_PATH: ${{ github.event_path }}
        run: |
          python3 Scripts/audit/check_f005_review.py
```

---

### 3.2 本地 Git Hook 拦截层：`pre-push` 升级

我们将对仓库的 `Scripts/hooks/pre-push` 机制进行升级。当用户进行 `git push` 时，除了限制直接向受保护分支直推外，若设置了 `ALLOW_DIRECT_PUSH=1`，也将针对非文档变更文件校验其本地 commit messages：

#### 升级提案补丁：`Scripts/hooks/pre-push` 扩展

```bash
# ...（保留原有 PROTECTED_BRANCHES 检查）

# 扩展检查：对于 ALLOW_DIRECT_PUSH=1 的情况，若涉及代码变更，必须有 commit msg 标记
if [[ "${ALLOW_DIRECT_PUSH:-0}" == "1" ]]; then
  echo "⚠️ 正在检查直推提交的对抗性审查留痕标记..."
  
  # 获取本次推送所涉及的 commit 列表
  COMMITS=$(git log origin/develop..HEAD --oneline 2>/dev/null || git log -n 5 --oneline)
  
  # 检查是否包含非文档文件
  HAS_CODE_CHANGES=0
  CHANGED_FILES=$(git diff --name-only origin/develop..HEAD 2>/dev/null || echo "")
  for file in $CHANGED_FILES; do
    if [[ ! "$file" =~ ^docs/ ]] && [[ ! "$file" =~ \.md$ ]]; then
      HAS_CODE_CHANGES=1
      break
    fi
  done
  
  if [ $HAS_CODE_CHANGES -eq 1 ]; then
    # 代码修改直推 develop，强制验证 commit messages 中是否含有 [review-by]
    if ! echo "$COMMITS" | grep -qiE '\[review-by:\s*(codex|gemini|both|ai)\]'; then
      echo "❌ pre-push 拦截失败：检测到在直推 develop 分支中包含 Swift 代码/配置改动，" >&2
      echo "但 Commit 消息中未包含审查标记 '[review-by: codex & gemini]'！" >&2
      echo "当前推送 commits 摘要如下：" >&2
      echo "$COMMITS" >&2
      echo "请使用包含审查标记的 commit 重新推送，或走标准 PR 工作流。" >&2
      exit 1
    fi
  fi
fi
```

---

### 3.3 PR 模板升级：更新 `.github/PULL_REQUEST_TEMPLATE.md`

将以下格式完美嵌入到 `.github/PULL_REQUEST_TEMPLATE.md` 模板底部，作为开发者在提交 PR 时被自动强制展示的引导容器：

```markdown
<!-- 请勿删除或移出以下 HTML 包裹段落，CI PR Linter 将进行正则解析校验 -->
<!-- F-005-REVIEW-SIGNATURE-START -->
## 🤖 对抗性审查留痕 (F-005)

- [ ] **Codex Review**: [填写审查证据或审查历史链接。例如：local-run-sha / PR comment #N]
- [ ] **Gemini Review**: [填写审查证据或审查历史链接。例如：local-run-sha]
- [ ] **Xcode Review**: [N/A 仅逻辑修改 | 填写 UI 验证截图/证据]

<!-- 紧急逃逸：如因 CI 崩溃等极端原因不得不跳过 review，请删除上方留痕块并使用下方格式 -->
<!-- [skip review] 理由: [在此填入详细合法的紧急避险理由，如“GitHub Actions self-hosted 离线且紧急修复上线”] -->
<!-- F-005-REVIEW-SIGNATURE-END -->
```

---

### 3.4 Skill 规范改进

#### A. `sprint-contract` Skill 改进提案 (`.claude/skills/sprint-contract/SKILL.md`)
在 `sprint-contract` closeout 逻辑段中，注入 F-005 的刚性校验责任：
* **要求**：在 closeout 结束并生成 PR 提交前，AI Agent 必须主动调用本地对抗性审查工具（如运行 Codex/Gemini review 并输出 SHA 指纹），并在 PR body 中**自动生成并填妥** `F-005-REVIEW-SIGNATURE` 段的打勾和内容，彻底消除人类开发者的认知负担。

#### B. `cross-audit` Skill 改进提案 (`.claude/skills/cross-audit/SKILL.md`)
* **要求**：`cross-audit` 的最终验证结果被设计为**一键 attach 到 PR**。在生成报告后，自动提取审查指纹，作为 PR Body 填充的首要来源。

---

## 4. 豁免条件文档化

为确立豁免逻辑的机械化可靠度，我们制订了极其详尽的白名单自动豁免模式及强硬黑名单阻断。

### 4.1 自动豁免触发条件 (Automatic Exemption)
* **判定方式 (Machine-Readable)**：PR 提交的所有变更文件（`git diff --name-only`）完全被以下白名单规则模式覆盖，**且没有任何一个**匹配黑名单模式。
* **可豁免文件路径模式 (Exempt Patterns)**：
  - `docs/**/*.md`（所有的产品、设计、协作规范文档）
  - `docs/**/*.tsv`（审计台账等表格类数据）
  - `*.md`（根目录下的 `README.md`、`STATUS.md`、`AGENTS.md`、`CLAUDE.md`）
  - `Scripts/audit/policy.yaml`（仅用于配置 docaudit 例外白名单登记，无动作性逻辑）

### 4.2 反例：绝对禁止豁免的黑名单 (Strict Blacklist)
若 PR 中含有以下任何一类文件改动，**绝不能豁免**留痕校验，自动白名单判定直接退回 `False`：
* **核心业务代码**：`Packages/**/*.swift`、`SnapDrill/**/*.swift`
* **工程质量约束**：`.swiftlint.yml`、`AllTests.xctestplan`
* **架构配置文件**：`SnapDrill.xcodeproj/`、`*.xcconfig`
* **CI/CD 配置流**：`.github/workflows/**/*.yml`、`fastlane/**/*`
* **功能性/运行脚本**：`Scripts/`（除 `policy.yaml` 外的所有 Python/Bash/Ruby 辅助/运行脚本）

---

## 5. 测试用例（4 大场景全覆盖）

Antigravity 针对流程拦截器的四个核心运行场景，定义了精准的输入、期望输出与系统断言。

### 5.1 场景 1：普通代码 PR 无 review 留痕而被拦截
* **PR 变更文件**：`Packages/SnapDrillCore/Sources/SnapDrillCore/Service/CaptureDraftService.swift`
* **PR Body**：不包含 `<!-- F-005-REVIEW-SIGNATURE-START -->` 段落。
* **执行命令**：`python3 Scripts/audit/check_f005_review.py`
* **断言行为**：校验器读取文件判定不符合自动豁免，进而解析 PR Body 失败，控制台抛出 `❌ 校验失败：未在 PR Body 中找到对抗性审查留痕签名块！`，以 `exit 1` 物理阻断 CI 合并。

### 5.2 场景 2：纯文档 PR 被自动放行 (豁免路径)
* **PR 变更文件**：`docs/product/product-requirements.md` 与 `STATUS.md`
* **PR Body**：完全空白或未填任何 review 信息。
* **执行命令**：`python3 Scripts/audit/check_f005_review.py`
* **断言行为**：变更文件检测全部匹配 `r"^docs/.*\.md$"` 与 `r"^.*\.md$"`，未命中任何黑名单规则。触发自动豁免，控制台打印 `ℹ️ 自动豁免启动...` 并以 `exit 0` 绿灯放行。

### 5.3 场景 3：有 review 留痕但格式不合规被精准拦截
* **PR 变更文件**：`Packages/SnapDrillCore/Sources/SnapDrillCore/DI/ServiceContainer.swift`
* **PR Body**：
  ```markdown
  <!-- F-005-REVIEW-SIGNATURE-START -->
  ## 🤖 对抗性审查留痕 (F-005)
  - [ ] **Codex Review**: [填写具体审查证据]
  - [x] **Gemini Review**: verified by antigravity-S-D7-001
  - [ ] **Xcode Review**: [N/A]
  <!-- F-005-REVIEW-SIGNATURE-END -->
  ```
* **执行命令**：`python3 Scripts/audit/check_f005_review.py`
* **断言行为**：
  - 判定含有 Swift 文件，不适用豁免；
  - 提取签名块内容，发现 Codex Review 仍是 `[ ]` 未打勾，且包含占位符 `[填写...]`；
  - 校验器强力阻断，控制台报错：`❌ 校验失败：Codex Review 和 Gemini Review 必须均标记为 [x] 已完成状态！` 以及 `❌ 校验失败：Codex Review 的审查记录 '...' 无效或包含了占位符！`，以 `exit 1` 坚决拦截。

### 5.4 场景 4：直推 develop 场景的等价拦截路径
* **变更操作**：通过 `ALLOW_DIRECT_PUSH=1 git push origin develop` 紧急推送。
* **包含文件**：修改了 `Packages/SnapDrillCore/Sources/SnapDrillCore/Service/CaptureDraftService.swift`
* **期望行为**：
  - 本地 `pre-push` Hook 捕捉到当前推送的分支属于 `develop`，且检测到包含代码修改；
  - 自动调用 `git log` 提取待推送的 commit message；
  - 若 commit 消息中缺少 `[review-by: codex & gemini]` 标记，则打印 `❌ pre-push 拦截失败...` 并中断 git 传输，确保绕过 PR 的灰色区域被完美堵死。

---

## 6. 本方案的已知盲区与已知局限性

按照最高级别的工程诚实性要求，Antigravity 对本设计提案的已知边缘漏洞和局限性进行了自我盘点：

1. **“流氓打勾但内容注水”的假阴性校验漏网**：
   * *漏洞描述*：校验脚本可以强力拦截带有“占位符”和“未勾选”的 PR，但若开发者使用完全无实际内容的随机字符串（如 `- [x] **Codex Review**: passed 123456`），正则与长度校验将被绕过，引发假阴性。
   * *避险设计*：通过扩展 Python 校验器，匹配“已提交的 commit SHA”等特定哈希模式进行证据真实性审查；但在前期，仍需人工与 CI 日志在 Code Review 阶段二次监督。
2. **`ALLOW_DIRECT_PUSH=1` 恶意伪造 commit tags 漏洞**：
   * *漏洞描述*：在紧急直推场景中，`pre-push` Hook 仅扫描 commit header 是否含有 `[review-by: ...]` 字眼。如果人为恶意捏造标记而未进行实际 review，本地 Hook 无法鉴别。
   * *避险设计*：这是 client-side 软防护的固有上限。长远来看，必须在 GitHub 服务端通过强制 PR 和真正的 server-side branch protection rule 予以终极根治。
3. **GitHub Pull Request API 改版与环境变化兼容性**：
   * *漏洞描述*：脚本强依赖 `GITHUB_EVENT_PATH` 来提取 PR 的 Body 信息。若未来 GitHub Enterprise 调整了 Event JSON 的 schema 或环境变量暴露策略，可能导致 `pr_body` 读取为空，从而引发误判拦截。
   * *避险设计*：在脚本中嵌入了回退机制。若 JSON 读取失败，可从标准输入（stdin）或本地临时文件兜底读取。

---

## 7. 与 S-D7-003（Sprint Contract 校验）联动与预期

在未来的治理规划（S-D7-003 任务）中，我们将彻底把 **F-005（对抗审查校验）** 和 **F-018（编码前契约校验）** 合并为一个高度一体化的统一控制面板。

* **共享 Hook 校验引擎的预期设计**：
  - 本次任务中，我们通过 `Scripts/audit/check_f005_review.py` 为 PR 和变更树建立了卓越的 Python 解析逻辑。
  - 在后续任务中，该校验器将平滑扩展为 `Scripts/audit/contract_and_review_gate.py`。
  - **一体化流程**：
    - **Step 1 (F-018 校验)**：在 CI 和本地 commit 时，检验 Issue 对应的 Sprint Contract 是否已落盘，touches 列表与当前修改的文件列表是否存在偏离。
    - **Step 2 (F-005 校验)**：在 PR 合并时，校验 Codex 和 Gemini 对该 Contract touches 中提及的每一个文件都完成了对抗审计并妥善勾选留痕。
  - 这种双星联动，将使 SnapDrill 的流程治理跨入“机器绝对可信”的高维秩序时代。
