---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-001 三方修复方案 — Cross-Fix-Consensus

> Phase 11 worktree 物理隔离首战收尾。Claude CLI 主笔，融合三家最强点。
>
> 单家产出：[claude](S-D7-001-claude.md) · [codex](S-D7-001-codex.md) · [antigravity](S-D7-001-antigravity.md)
> 任务定义书：[S-D7-001-fix-task-definition.md](S-D7-001-fix-task-definition.md)

## 1. 三家共识（3/3 命中）

| 共识点 | 内容 |
|---|---|
| 根因定位 | `Scripts/audit/docaudit.py:591-595` 正则只匹配 markdown 标题，漏 feedback.md 路由表格行 |
| 修复前 declared | `n=1, ['004']` |
| 修复后 declared | `n=14, ['001','004','005','006','007','008','011','012','013','014','016','017','018','019']` |
| 必备机制 1 | 状态机识别「退役记录」段并排除其 F-rule（否则 retired 误报 dead candidate）|
| 必备机制 2 | 行首 `^` 锚定 + `\b` 词边界（防 `F-1234` 误吃前三位 / 防行内反引号 reference 误抓）|
| 三位编号 | `\d{3}` 严格三位，与 feedback.md 编号规则一致 |

## 2. 三家差异点对比

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| 正则组织 | 双正则（heading + table）模块级常量 | 单 VERBOSE 正则 3 分支（heading + table + list）| 三正则函数内联 |
| 退役段识别 | `^#{1,4}\s+(?:退役\|Retired)` IGNORECASE | `^##\s+退役记录\b`（仅中文）| `^#+\s+退役记录\b` 或 `^#+\s+Retired\b` IGNORECASE |
| 加粗 `**F-001**` 支持 | ❌ YAGNI 排除 | ✅ 全格式覆盖 | ✅ 仅 list 项支持 |
| 列表 `- F-001` 支持 | ❌ YAGNI 排除 | ✅ 含冒号变体 | ✅ |
| 反引号 `` `F-001` `` 在行首 | 未显式覆盖 | ✅ `` `?(?:\*\*)?F-`` 兼容 | 不覆盖 |
| 测试落档位置 | inline assert（一次性脚本）| `Scripts/audit/tests/test_docaudit.py` 单元测试 | `scratch/test_s_d7_001.py` 临时脚本 |
| 是否临时 apply 验证 | ❌ 纯模拟 | ❌ 纯模拟 + 引用计数预演 | ✅ 临时 apply + git restore |
| 引用计数预演 | 未做 | ✅ 14 个 declared 全有 reference（无新 finding 预测） | 未做 |
| 已知盲区条数 | 7 | 5 | 3 + 重审触发 |
| 编程风格 | 模块级常量 + 短函数 | VERBOSE 正则 + 单行抓取 | 函数内多段 if + continue |

## 3. 综合裁决

### 评分矩阵（1-5 分）

| 维度 | Claude | Codex | Antigravity |
|---|---|---|---|
| 正确性（declared = 14）| 5 | 5 | 5 |
| 覆盖率（未来格式宽容度）| 3（YAGNI 保守）| **5** | 4 |
| 测试规范度 | 3（inline）| **5**（unit test 嵌入正式测试套件）| 3（scratch）|
| 实证强度 | 2（纯模拟）| 4（引用计数预演）| **5**（临时 apply + 全工具链验证）|
| 简洁度 / 可维护性 | 4 | **5**（单 regex）| 3 |
| 防御性（边界 / retired 双语）| **5** | 4（中文 only）| 4（中英文）|
| 自检诚实度 | **5**（7 条 future-proof 触发器）| 4 | 3 |
| **总分** | 27 | **32** | 27 |

### 最强方案：**Codex 为基础 + Claude/Antigravity 增强点**

**Codex 胜出**理由：
- 单 VERBOSE 正则可维护性最高
- 测试嵌入 `Scripts/audit/tests/test_docaudit.py` 正式套件（CI 可重复执行）
- 引用计数预演实证修复后无新 dead finding
- 格式覆盖最广（table + heading + list + bold + backtick）

**采纳 Claude/Antigravity 增强**：
- 退役段识别支持中英文 `(?:退役|Retired)` IGNORECASE（防 i18n 漂移）
- Claude 7 条自检盲区表完整搬入 docaudit.py 模块注释（future-proof 触发器存档）

### Antigravity 实证价值

虽然总分并列 Claude，**Antigravity 是 Phase 10 S-D7-001 finding 的原始发现者**——撕破 docaudit.py 工具底层 bug。本任务的存在本身就是它独家发现的延续。

## 4. 融合方案（最终 apply）

### 4.1 Diff

```diff
--- a/Scripts/audit/docaudit.py
+++ b/Scripts/audit/docaudit.py
@@ -127,6 +127,30 @@
 # F-NNN 规则 ID
 F_RULE_RE = re.compile(r"\bF-(\d{3})\b")

+# rule-usage check 用：feedback.md 中的 F-rule declaration site
+# 同时支持: ### F-NNN 标题 / | F-NNN | 表格行 / - F-NNN: 列表项
+# 兼容前缀加粗 **F-NNN** 与反引号 `F-NNN`
+# 行首 ^ 锚 + \b 词边界确保不误吃 F-1234 或行内 reference site
+# 已知盲区（future-proof 触发器，feedback.md SSOT 变更时重审本正则）:
+#   1. 退役记录标题改名（非中文「退役」/ 非「Retired」前缀）
+#   2. retired 段中间夹 active 段（状态机单向不退出）
+#   3. F-NNNN 四位编号（编号规则升级时）
+#   4. blockquote / HTML 注释包裹声明
+#   5. 跨多行折断声明
+#   6. 表格编号列从第一列移位
+#   7. list 改用 `*` / `+` / 数字而非 `-`
+F_RULE_DECL_RE = re.compile(r"""
+    ^\s*(?:
+        \|\s*`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\s*\|        # 表格首列声明
+      | \#{1,6}\s+`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\b      # 标题声明
+      | [-*+]\s+`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\s*[:：-] # 列表声明（含冒号变体）
+    )
+""", re.VERBOSE)
+# 退役段标题识别（中英文双语）— Claude/Antigravity 增强
+F_RULE_RETIRED_HEADING_RE = re.compile(r"^#{1,4}\s+(?:退役|Retired)", re.IGNORECASE)
+
 # ---------- check: links ----------

@@ -588,12 +612,17 @@ def check_rule_usage(policy: dict) -> CheckResult:
     if not feedback.is_file():
         return result
     fb_text = feedback.read_text(encoding="utf-8")
     declared = set()
+    in_retired_section = False
     for line in fb_text.splitlines():
-        m = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
+        if F_RULE_RETIRED_HEADING_RE.match(line):
+            in_retired_section = True
+            continue
+        if in_retired_section:
+            continue
+        m = F_RULE_DECL_RE.match(line)
         if m:
-            declared.add(m.group(1))
+            declared.add(next(g for g in m.groups() if g))
```

### 4.2 测试套件扩展（采纳 Codex pattern）

更新 `Scripts/audit/tests/test_docaudit.py`：

- 修复测试 fixture（line 104）的 feedback.md 内容：从 `## F-001\nrule 1\n` 改为真实 SSOT 表格结构
- 新增 `test_rule_usage_declares_active_table_rows_only`：active 表格 + retired 表格区分
- 新增 `test_rule_usage_supports_declaration_shapes`：bold / list / inline reference / 边界 F-NNN

## 5. Apply 计划

1. ✅ 写本 consensus 文件
2. apply patch 到 `Scripts/audit/docaudit.py`
3. 扩展 `Scripts/audit/tests/test_docaudit.py`
4. 跑单元测试：`python3 -m unittest Scripts.audit.tests.test_docaudit`
5. 跑全工具链：`python3 Scripts/audit/docaudit.py all --strict`
6. dump 实际 dead_rule_candidate 集合（修复后真实情况）
7. 重审 S-D5-013（F-004 references 真实计数）
8. 更新 ledger：S-D7-001 status OPEN → RESOLVED
9. commit + push

## 6. Phase 11 worktree 工作流首战观察

| 观察项 | 评价 |
|---|---|
| 物理隔离效果 | ✅ 三家产出无串扰，编号体系无抄袭（与 Phase 10 维度 7 Antigravity 抄 C7.x 形成鲜明对比）|
| 净化提示词效果 | ✅ 无「Claude 已抓」分工指令，三家独立发挥 |
| 实证强度差异 | ⚠️ Antigravity 临时 apply 验证最严谨 / Codex 引用计数预演最巧 / Claude 最保守 |
| 三家差异化能力暴露 | ✅ Codex 简洁工程化 / Antigravity 状态机白话 / Claude 防御性盲区清单——三种风格清晰可辨 |
| 控制变量法纪律 | ✅ 三家**3/3** 共识根因 + 修复策略，差异只在具体实现细节，污染风险极低 |
| 工作流缺陷 | ⚠️ Antigravity 汇报层用 `file:///` 绝对路径（产出文件内无此问题），下次提示词强化 |

## 7. 关联

- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准（本次首战）
- [ADR-005](../decisions/ADR-005-doc-semantic-layer-audit.md) §Phase 10 全局收官（S-D7-001 起源）
- [audit-ledger-semantic-2026-05.tsv](audit-ledger-semantic-2026-05.tsv) S-D7-001 待翻面 OPEN → RESOLVED
- S-D5-013 待重审（rule-usage 工具复活后的真实 dead candidate 状况）
