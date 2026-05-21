---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-001 修复提案 — Claude CLI 独立产出

> Phase 11 worktree 物理隔离任务，三家独立产出之一。
> 本提案在主 worktree `/Users/yiming/Developer/snapdrill-ios` 独立完成，全程未读 antigravity / codex 产出。

## 1. Bug 复现与根因定位

### 1.1 修复前 declared 集合实测

```
OLD declared (n=1): ['004']
```

只有 `### F-004 —`（feedback.md line 33）被识别。`docs/memory/feedback.md` 当前 14 条 active F-rule 全部漏识别。

### 1.2 根因

`Scripts/audit/docaudit.py:591-595`：

```python
declared = set()
for line in fb_text.splitlines():
    m = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
    if m:
        declared.add(m.group(1))
```

正则 `^#{1,4}\s+F-(\d{3})\b` 只匹配「Markdown 标题行」形式的声明。但 feedback.md 的 SSOT 设计是「规则路由表」——14 条 active F-rule 都在 line 14-27 的**表格行**声明（`| F-001 | ... |`），不是标题。

### 1.3 二次盲区：退役表

`docs/memory/feedback.md:49-60` 还有「退役记录」段，里面 6 条 F-rule（F-002/003/009/010/015/020）也是表格行。如果只做「表格行兼容」修复，退役 F-rule 会被错误地纳入 declared 集合 → rule-usage check 把它们误报为 dead_rule_candidate。

**必须用状态机识别「退役记录」段并排除之**。

## 2. 修复方案

### 2.1 Diff

```diff
--- a/Scripts/audit/docaudit.py
+++ b/Scripts/audit/docaudit.py
@@ -127,6 +127,12 @@
 # F-NNN 规则 ID
 F_RULE_RE = re.compile(r"\bF-(\d{3})\b")

+# rule-usage check 用：feedback.md 声明点格式
+# 同时支持: ### F-NNN 标题 / | F-NNN | 表格行
+_FRULE_DECL_HEADING_RE = re.compile(r"^#{1,4}\s+F-(\d{3})\b")
+_FRULE_DECL_TABLE_RE = re.compile(r"^\|\s*F-(\d{3})\b")
+_FRULE_RETIRED_HEADING_RE = re.compile(r"^#{1,4}\s+(?:退役|Retired)", re.IGNORECASE)
+
 # ---------- check: links ----------

@@ -588,11 +594,16 @@
     if not feedback.is_file():
         return result
     fb_text = feedback.read_text(encoding="utf-8")
     declared = set()
+    in_retired_section = False
     for line in fb_text.splitlines():
-        m = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
+        if _FRULE_RETIRED_HEADING_RE.match(line):
+            in_retired_section = True
+            continue
+        if in_retired_section:
+            continue
+        m = _FRULE_DECL_HEADING_RE.match(line) or _FRULE_DECL_TABLE_RE.match(line)
         if m:
             declared.add(m.group(1))
```

### 2.2 设计决策

| 决策 | 理由 |
|---|---|
| 双正则（标题 + 表格）而非合并成一条 | 可读性 + 后续若需要单独调整某格式可独立改 |
| `^` 行首锚定 + `\b` 词边界 | 防御行内引用（`` `F-001` ``）和超长数字（F-1234）误匹配 |
| 状态机识别 retired 段，单向不退出 | 当前 feedback.md 中 `## 退役记录` 是文末段，进入后无需退出。Future-proof 性留作下一次修复 |
| `re.IGNORECASE` for `退役\|Retired` | 兼容未来若改 i18n 命名 |
| **不**识别 list item `- F-001:` | YAGNI——feedback.md 当前 SSOT 不用此格式；若未来格式变化触发本测试套件失败再补 |
| **不**识别加粗 `**F-001**` | 同上 YAGNI + 加粗在行内既可作 reference 也可作 declaration，语义模糊 |

### 2.3 副作用与回归

- 修改文件：仅 `Scripts/audit/docaudit.py`
- 新增模块级常量 3 个（命名空间 `_FRULE_*`），不影响其他 check
- `F_RULE_RE`（line 131，用于扫 reference site）**不动**——它的语义是 reference 计数，正则保持原状
- 风险：修复后 declared 从 1 → 14，rule-usage check 实际会重新计算 dead candidate 报告。需重跑 `docaudit all --strict` 验证。

## 3. declared 集合完整性验证

### 3.1 修复前后对比

| 状态 | declared 集合大小 | 内容 |
|---|---|---|
| 修复前 | 1 | `['004']` |
| 修复后 | 14 | `['001','004','005','006','007','008','011','012','013','014','016','017','018','019']` |

与 `docs/memory/feedback.md` line 14-27 路由表「规则」列实际行数一致。

### 3.2 实测命令

```bash
python3 << 'EOF'
import re, pathlib
fb = pathlib.Path("docs/memory/feedback.md").read_text(encoding="utf-8")

HEADING_RE = re.compile(r"^#{1,4}\s+F-(\d{3})\b")
TABLE_RE   = re.compile(r"^\|\s*F-(\d{3})\b")
RETIRED_HEADING = re.compile(r"^#{1,4}\s+(?:退役|Retired)", re.IGNORECASE)

declared = set()
in_retired = False
for line in fb.splitlines():
    if RETIRED_HEADING.match(line):
        in_retired = True; continue
    if in_retired: continue
    m = HEADING_RE.match(line) or TABLE_RE.match(line)
    if m: declared.add(m.group(1))
print(f"declared (n={len(declared)}): {sorted(declared)}")
EOF
```

实跑输出：

```
declared (n=14): ['001', '004', '005', '006', '007', '008', '011', '012', '013', '014', '016', '017', '018', '019']
```

## 4. 测试用例（10 条边界断言全过）

```python
def declared_from(text):
    HEADING_RE = re.compile(r"^#{1,4}\s+F-(\d{3})\b")
    TABLE_RE   = re.compile(r"^\|\s*F-(\d{3})\b")
    RETIRED_HEADING = re.compile(r"^#{1,4}\s+(?:退役|Retired)", re.IGNORECASE)
    out, in_retired = set(), False
    for line in text.splitlines():
        if RETIRED_HEADING.match(line):
            in_retired = True; continue
        if in_retired: continue
        m = HEADING_RE.match(line) or TABLE_RE.match(line)
        if m: out.add(m.group(1))
    return out

# B1 表格行 active F-rule 识别
assert declared_from("| F-001 | x |\n| F-019 | y |") == {"001","019"}
# B2 retired 段必须排除
assert declared_from("| F-001 | x |\n## 退役记录\n| F-002 | x |") == {"001"}
# B3 行内加粗引用不识别（reference site）
assert declared_from("**F-099** 见下方") == set()
# B4 list item 当前 SSOT 不用此格式 → 不识别
assert declared_from("- F-001: 说明") == set()
# B5 行内反引号引用不识别
assert declared_from("提到 `F-001` 时...") == set()
# B6 三位数边界 F-001 / F-099 / F-999 全识别
assert declared_from("| F-001 |\n| F-099 |\n| F-999 |") == {"001","099","999"}
# B7 非 F-rule 误匹配防御（散文 + 表格行）
assert declared_from("F-1\nF-1234\nF-FOO") == set()
assert declared_from("| F-1 |\n| F-1234 |") == set()
# B8 heading 形式（F-004 政策标签段）识别
assert declared_from("### F-004 — 内测") == {"004"}
# B9 表格 separator `|---|---|` 不误匹配
assert declared_from("|---|---|---|") == set()
# B10 \b 词边界防御
assert re.match(r"^\|\s*F-(\d{3})\b", "| F-1234 |") is None
```

实跑结果：**ALL 10 BOUNDARY TESTS PASS**。

## 5. 已知盲区（自检）

| 盲区 | 当前处理 | 重审触发条件 |
|---|---|---|
| feedback.md 未来引入 list item 格式 `- F-001:` | 不识别 → 漏报 | 路由表迁移到列表格式时 |
| feedback.md 未来用加粗 `**F-001**` 作 declaration site | 不识别 → 漏报 | 同上格式变更 |
| `## 退役记录` 标题文字变更 | 状态机不识别 → retired 误纳入 declared | feedback.md 改标题文案时 |
| retired 段不在文末，后续还有 active 段 | 状态机不退出 → 漏报 retired 之后的 active | 文件结构调整时 |
| `F-NNNN`（四位）出现 | `\b` 防御不识别 | 编号规则突破三位时（feedback.md line 45 规定三位）|
| 跨多个 .md 文件分散声明 | 当前只扫 feedback.md，一致 | feedback.md SSOT 性质改变 |
| `_FRULE_DECL_TABLE_RE` 误抓非声明性表格列（如「最近触发 F-001 的 PR」表格）| 当前 feedback.md 中不存在此类表格 | 若 feedback.md 引入新表格类型 |

**核心防御立场**：feedback.md 是 SSOT，工具适配 SSOT 而非反过来。盲区清单作为 future-proof 触发器存档，**不做预防性扩展**，符合工程哲学「YAGNI / 不引入对假设性需求的支持」。

## 6. 工具链集成验证（待 consensus 阶段 apply 时再跑）

预期：

```bash
python3 Scripts/audit/docaudit.py all --strict
# Exit 0（修复前后均期望 0，但修复后 declared 集合从 1 升到 14，rule-usage check 实际工作）
```

**重大下游影响**：修复后 rule-usage check 真实工作，可能新增 dead_rule_candidate finding（即 declared 但 0 references 的 F-rule）。若新增 finding 触发 strict 失败：

1. 不要回退本修复——失败是工具复活后暴露的真实问题
2. 按 dead rule 处理：要么 retire，要么补 reference

预期 dead candidate：根据 Phase 10 S-D5-013（**注意：S-D5-013 结论本身被 S-D7-001 推翻基础，需要重审**）。**本提案不预判 dead candidate 集合**，留待 apply 后实跑披露。

## 7. 不变性声明

本提案完成期间：

- ✅ 仅修改 / 新增本文件 `docs/audits/S-D7-001-claude.md`
- ✅ 未触动 `Scripts/audit/docaudit.py` / `docs/memory/feedback.md`
- ✅ 未读 antigravity / codex 在各自 worktree 的产出
- ✅ 不直接 apply 到代码（产出仅是方案）——apply 由 cross-fix-consensus 阶段统一做

## 8. 关联

- [任务定义书](S-D7-001-fix-task-definition.md)
- [worktree-audit-workflow](../standards/worktree-audit-workflow.md) Phase 11+ 标准
- [F-008](../memory/feedback.md) 「相同完整任务、不分工」
- [ADR-005](../decisions/ADR-005-doc-semantic-layer-audit.md) §Phase 10 全局收官
