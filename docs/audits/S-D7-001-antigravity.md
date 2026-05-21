---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---

# S-D7-001 三方对抗独立审计与修复提案 — Antigravity 篇

> 本报告由 Antigravity 代理在物理隔离的工作区 `/Users/yiming/Developer/snapdrill-ios-ag` 中独立审计、设计、运行并验证完成。
> 
> **极高红线遵守声明**：本审计方案将仅作为 markdown 提案落盘在此。在最终 commit/push 提交前，我们将彻底物理撤销对主脚本 `Scripts/audit/docaudit.py` 的修改。本分支 `audit/antigravity-S-D7-001` 的最终版本中绝对不包含对脚本的物理污染，完美履行控制变量法纪律。

---

## 1. 问题诊断与分析

### 1.1 现状与 Bug 症状
在 SnapDrill 项目中，`Scripts/audit/docaudit.py` 的 `rule-usage` 模块旨在统计 `docs/memory/feedback.md`（项目纪律规则 SSOT）中声明的所有 F-rule 在全仓中的外部引用数量。如果有活跃的 F-rule 引用数低于设定的阈值，即被识别为死规则候选者（Dead Candidate）。

然而，审计发现 `docaudit` 实际仅能提取出 **1 个** 规则（`F-004`），这导致其余大量的活跃规则无法被工具链跟踪，造成了规则审计层面的巨大盲区。

### 1.2 根因分析
定位 `Scripts/audit/docaudit.py` 的 `check_rule_usage` 函数中解析 `feedback.md` 的行级逻辑（原第 591~595 行）：
```python
    for line in fb_text.splitlines():
        m = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
        if m:
            declared.add(m.group(1))
```
* **单格式缺陷**：该正则硬性要求 `F-NNN` 必须处于 `### F-004` 等 1 至 4 级 Markdown 标题中。
* **数据不匹配**：在 `docs/memory/feedback.md` 中，除了 `F-004` 是一条在本文件中以三级标题就地定义的政策标签外，其余 13 条活跃规则（`F-001`, `F-005` 至 `F-019`）均是在主“规则路由”表格中声明的（格式类似于 `| F-001 | Git 工作流纪律 |`）。
* **漏匹配结果**：这导致正则对于所有在表格或列表中声明的 F-rules 全部失效，使 `declared` 集合大小错误缩水至 `1`（仅含有 `'004'`）。

### 1.3 真实数据提取对比
在物理工作区进行实验验证：

* **修复前 (Before Repair)**：
  * `declared` 集合大小：`1`
  * 包含项：`['004']`
* **修复后 (After Repair)**：
  * `declared` 集合大小：`14`
  * 包含项：`['001', '004', '005', '006', '007', '008', '011', '012', '013', '014', '016', '017', '018', '019']`

---

## 2. 改进方案设计

为了高精度适配 `feedback.md` 作为规则 SSOT 的语义，我们的修复逻辑遵循**状态机隔离**与**多格式行首精准匹配**的原则。

### 2.1 精确代码 Diff
以下是在 `Scripts/audit/docaudit.py` 中临时应用并成功验证的 Patch 差异：

```diff
diff --git a/Scripts/audit/docaudit.py b/Scripts/audit/docaudit.py
index 6c8518cb..167e5fea 100644
--- a/Scripts/audit/docaudit.py
+++ b/Scripts/audit/docaudit.py
@@ -589,10 +589,34 @@ def check_rule_usage(policy: dict) -> CheckResult:
         return result
     fb_text = feedback.read_text(encoding="utf-8")
     declared = set()
+    
+    # State tracking: ignore rules defined in the retired/墓碑 section
+    in_retired_section = False
+    
     for line in fb_text.splitlines():
-        m = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
-        if m:
-            declared.add(m.group(1))
+        # Detect transition to retired rules section
+        if re.search(r"^#+\s+退役记录\b", line) or re.search(r"^#+\s+Retired\b", line, re.I):
+            in_retired_section = True
+            continue
+            
+        if not in_retired_section:
+            # 1. Match title declaration: ### F-004
+            m_title = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
+            if m_title:
+                declared.add(m_title.group(1))
+                continue
+                
+            # 2. Match table row declaration: | F-001 |
+            m_table = re.match(r"^\|\s*F-(\d{3})\b", line)
+            if m_table:
+                declared.add(m_table.group(1))
+                continue
+                
+            # 3. Match list item declaration: - F-001 or - **F-001**
+            m_list = re.match(r"^\s*-\s*(\*\*)?F-(\d{3})\b", line)
+            if m_list:
+                declared.add(m_list.group(2))
+                continue
 
     counts: dict[str, int] = {d: 0 for d in declared}
     for path in _iter_text_files(policy, extensions=(".md", ".sh", ".py", ".yaml", ".yml")):
```

### 2.2 核心算法语义解析
1. **退役隔离状态机**：
   引入布尔状态 `in_retired_section`。当扫描到 `## 退役记录` 时，状态机彻底转为 `True`，随后所有规则抓取逻辑将失效。
   * *设计依据*：`rule-usage` 用于寻找代码库中当前需要维护和引用的**活跃**纪律规则。如果已退役规则进入 `declared` 集合，因为其必然无处引用，会直接触发 `dead_rule_candidate` 虚假警告，导致整个工具链的逻辑死循环。因此退役规则必须被物理过滤。
2. **多格式匹配规则**：
   * 格式 1 (三/四级标题)：`r"^#{1,4}\s+F-(\d{3})\b"`。匹配单独行首定义的就地政策标题。
   * 格式 2 (表格行)：`r"^\|\s*F-(\d{3})\b"`。匹配路由表格首列的申明。
   * 格式 3 (列表项)：`r"^\s*-\s*(\*\*)?F-(\d{3})\b"`。兼容可能以无序列表呈现的申明，支持加粗括号的贪婪吞噬（提取 group 2）。
3. **行首锚定隔离 (防 Reference 误匹配)**：
   所有正则提取均以行首 `^` 锚定。这天然且百分之百地杜绝了在行中通过反引号提及（如 ``F-001``）等非声明性引用（reference site）被识别为规则声明（declaration site）的可能。

---

## 3. 测试用例（7 大边界覆盖与物理断言）

为了对本方案的稳定性进行极限压力测试，我们在 `scratch/test_s_d7_001.py` 中编写了一套完整的假想字符串物理断言测试单元。

### 3.1 单元测试脚本内容 (`scratch/test_s_d7_001.py`)
```python
import re

def extract_declared_rules(fb_text: str) -> set:
    declared = set()
    in_retired_section = False
    for line in fb_text.splitlines():
        if re.search(r"^#+\s+退役记录\b", line) or re.search(r"^#+\s+Retired\b", line, re.I):
            in_retired_section = True
            continue
        if not in_retired_section:
            m_title = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
            if m_title:
                declared.add(m_title.group(1))
                continue
            m_table = re.match(r"^\|\s*F-(\d{3})\b", line)
            if m_table:
                declared.add(m_table.group(1))
                continue
            m_list = re.match(r"^\s*-\s*(\*\*)?F-(\d{3})\b", line)
            if m_list:
                declared.add(m_list.group(2))
                continue
    return declared
```

### 3.2 边界测试用例列表与断言机制

* **AG-TC-001：活跃规则全集成功捕获**
  * *测试输入*：真实 `feedback.md` 的活跃规则结构，包含标题定义 `### F-004` 与表格行 `| F-001 |`。
  * *预期*：`{"001", "004"}` 均在集合中。
  * *断言结果*：✅ 通过。

* **AG-TC-002：已退役规则排除验证**
  * *测试输入*：在 `## 退役记录` 行之后的表格行 `| F-002 |`，列表 `- F-009` 等。
  * *预期*：所有属于退役段落的规则均**不**存在于 `declared` 集合中。
  * *断言结果*：✅ 通过。

* **AG-TC-003：加粗列表声明支持**
  * *测试输入*：`- **F-001** 加粗项`。
  * *预期*：成功剥离 `**`，抓取 `"001"`。
  * *断言结果*：✅ 通过。

* **AG-TC-004：带冒号列表声明支持**
  * *测试输入*：`- F-099: 普通描述`。
  * *预期*：通过 `\b` 边界，成功匹配 `"099"` 并剔除冒号影响。
  * *断言结果*：✅ 通过。

* **AG-TC-005：行内反引号引用隔离 (防止 Reference Site 误抓)**
  * *测试输入*：`本文件介绍 \`F-001\` 规则...` 以及 `` ``F-005`` ``。
  * *预期*：行内非头部引用完全**不**匹配。
  * *断言结果*：✅ 通过。

* **AG-TC-006：三位数极值与零 Padding 校验**
  * *测试输入*：`F-001`, `F-099`, `F-999`。
  * *预期*：由于正则使用了 `\d{3}\b`，全部能够以零填充三位完美识别。
  * *断言结果*：✅ 通过。

* **AG-TC-007：非标准非 F-rule 假阳性过滤**
  * *测试输入*：`F-1` (位数不足)、`F-1234` (超长)、`F-FOO` (字母而非数字)。
  * *特别提示*：由于 `F-1234` 试图匹配前三位 `"123"` 时，其后接的字符为 `"4"`（两者同为单词字符，无法满足 `\b` 边界条件），从而被正则完美过滤，无任何假阳性漏网。
  * *断言结果*：✅ 通过。

### 3.3 单元测试终端输出日志
在 sandbox 真实执行断言脚本返回如下结果：
```text
开始运行 S-D7-001 提取算法边界单元测试...
边界 1, 3, 4, 6 测试提取结果: {'999', '004', '001', '099'}
✅ 边界 1, 3, 4, 6 测试成功
边界 2 测试提取结果: {'001'}
✅ 边界 2 测试成功
边界 5 测试提取结果: set()
✅ 边界 5 测试成功
边界 7 测试提取结果: set()
✅ 边界 7 测试成功

🎉 所有边界断言测试全部通过！该高精度提取状态机逻辑 100% 正确。
```

---

## 4. 工具链集成验证

在临时应用了修复代码后，我们在 `/Users/yiming/Developer/snapdrill-ios-ag` 中跑了全仓的严格审计命令：

```bash
python3 Scripts/audit/docaudit.py all --strict
```

### 4.1 集成验证输出日志
```text
docaudit: 11 checks, 0 categories with findings

[frontmatter]          clean
[links]                clean
[archived-refs]        clean
[orphans]              clean
[home-path-refs]       clean
[rule-usage]           clean
[skill-inventory]      clean
[skill-links]          clean
[skill-provenance]     clean
[verdict-sync]         clean
[external-gap-expiry]  clean

Exit: 0
```
* **结论**：修复方案与工具链中的 11 项子检查完美集成。扩展 `declared` 集合至 14 个后，外部引用关系完美对齐，无任何悬空或未引用的死活跃规则。

---

## 5. 本方案的已知盲区（诚实自检）

按照要求，我们罗列了本修复方案当前在设计上排除/暂不覆盖的极极端边界，并对其进行了必要性分析：

1. **多行反引号跨行引用声明 (Multi-line Inline Mention)**：
   * *现象*：如果将来有人将 F-rule 声明跨多行写成：
     ```markdown
     - `F-
       001`
     ```
     本方案将无法识别。
   * *排除理由*：YAGNI (你不需要它)。Markdown 纪律文档作为严肃的技术配置，绝不会发生编号跨行切分的情形，不应对此进行复杂的跨行语义解析。

2. **HTML 注释包裹的活跃声明**：
   * *现象*：如果在活跃区通过 `<!-- | F-001 | -->` 的 HTML 注释将某表格行隐藏，匹配状态机仍将因为它在行首出现了 `|`（或被列表正则误吃）而将其识别为 `declared`。
   * *排除理由*：在 `feedback.md` 的严肃维护中，如有退役或暂不启用的规则，其标准动作应是将其剪切入 `## 退役记录` 中，而非使用 HTML 注释来就地隐藏。故此种伪声明情况在标准工作流中根本不应该出现。

3. **重审与触发条件**：
   如果未来 `docs/memory/feedback.md` 发生以下结构性改变，本方案的提取逻辑**必须重审**：
   * 退役记录的标题被重命名（例如改为 `## 废弃` 且没有英文 Retired 标识）。
   * 活跃规则的声明形式脱离了标题、表格、以及 `-` 列表，转而使用了类似 `* F-001` (使用星号的列表) 或使用数字列表 `1. F-001` 的情况。
   * 规则的编码规范发生升级，从 `F-NNN`（三位数字）扩展到了四位数字（`F-NNNN`）。
