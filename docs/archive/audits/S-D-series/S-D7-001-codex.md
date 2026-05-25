---
last_verified: 2026-05-21
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [pr_merge]
---
# S-D7-001 Codex 独立修复提案

## 结论

`rule-usage` 的 declared 提取逻辑应改为识别 `docs/memory/feedback.md` 的 active 声明位点，而不是只识别 Markdown 标题。

当前 bug 根因在 `Scripts/audit/docaudit.py:591-595`：

```python
declared = set()
for line in fb_text.splitlines():
    m = re.match(r"^#{1,4}\s+F-(\d{3})\b", line)
    if m:
        declared.add(m.group(1))
```

这段只会抓 `### F-004`，但当前 active F-rule 主要声明在 `## 规则路由` 表格第一列，所以实际只识别 1 条。

## 语义判定

`rule-usage` 是 dead rule candidate 检查，应只统计 active F-rule：

- active rule：`feedback.md` 中 `## 规则路由` 表格行，外加退役段之前的标题/列表声明。
- retired rule：`## 退役记录` 之后的 F-rule，只保留历史溯源，不应作为 dead candidate。
- 行内引用：例如正文 `见 F-001` 或 `` `F-001` ``，不是声明位点，不应纳入 declared。

当前 `feedback.md` active 实际数量是 14，不是任务定义书中的 13：

`F-001 F-004 F-005 F-006 F-007 F-008 F-011 F-012 F-013 F-014 F-016 F-017 F-018 F-019`

## 修复 patch

建议 patch：

```diff
diff --git a/Scripts/audit/docaudit.py b/Scripts/audit/docaudit.py
--- a/Scripts/audit/docaudit.py
+++ b/Scripts/audit/docaudit.py
@@
 F_RULE_RE = re.compile(r"\bF-(\d{3})\b")
+F_RULE_DECL_RE = re.compile(r"""
+    ^\s*(?:
+        \|\s*`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\s*\|      # feedback.md active table first cell
+      | \#{1,6}\s+`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\b    # heading declaration
+      | [-*+]\s+`?(?:\*\*)?F-(\d{3})(?!\d)(?:\*\*)?`?\s*[:：-] # list declaration
+    )
+""", re.VERBOSE)
+F_RULE_RETIRED_HEADING_RE = re.compile(r"^##\s+退役记录\b")
@@
 def check_rule_usage(policy: dict) -> CheckResult:
@@
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
+        # Only declaration sites count: active table rows, headings, or list-definition rows.
+        m = F_RULE_DECL_RE.match(line)
         if m:
-            declared.add(m.group(1))
+            declared.add(next(group for group in m.groups() if group))
```

意图：把 declared 限定为 active declaration site，并在退役记录段停止收集，避免 retired rule 重新进入 dead candidate。

## 测试 patch

建议新增/调整 `Scripts/audit/tests/test_docaudit.py`：

```diff
diff --git a/Scripts/audit/tests/test_docaudit.py b/Scripts/audit/tests/test_docaudit.py
--- a/Scripts/audit/tests/test_docaudit.py
+++ b/Scripts/audit/tests/test_docaudit.py
@@
     (repo / "docs" / "memory" / "feedback.md").write_text(
-        "## F-001\nrule 1\n\n## F-002\nrule 2\n", encoding="utf-8"
+        "## 规则路由\n\n"
+        "| 编号 | 规则 | 权威源 | 触发方式 |\n"
+        "|---|---|---|---|\n"
+        "| F-001 | rule 1 | workflow | git |\n"
+        "| F-002 | rule 2 | workflow | audit |\n"
+        "\n## 退役记录\n\n"
+        "| 编号 | 退役日期 | 去向 |\n"
+        "|---|---|---|\n"
+        "| F-003 | 2026-01-01 | merged |\n",
+        encoding="utf-8",
     )
@@
     def test_rule_usage_referenced(self) -> None:
@@
         self.assertEqual(code, 0, out)
         self.assertIn("clean", out)
+
+    def test_rule_usage_declares_active_table_rows_only(self) -> None:
+        (self.repo / "docs" / "workflow.md").write_text("remember F-001 and F-002\n", encoding="utf-8")
+        policy = _write_policy(self.tmp)
+        code, out, _ = self._run(["--policy", str(policy), "rule-usage", "--verbose"])
+        self.assertEqual(code, 0, out)
+        self.assertIn("clean", out)
+        self.assertNotIn("F-003", out)
+
+    def test_rule_usage_supports_declaration_shapes(self) -> None:
+        (self.repo / "docs" / "memory" / "feedback.md").write_text(
+            "## 规则路由\n\n"
+            "| **F-001** | table |\n"
+            "### **F-099** — heading\n"
+            "- F-999: list declaration\n"
+            "See `F-010` inline only.\n"
+            "| F-1234 | too long |\n"
+            "| F-1 | too short |\n"
+            "| F-FOO | not numeric |\n"
+            "\n## 退役记录\n"
+            "| F-020 | retired |\n",
+            encoding="utf-8",
+        )
+        (self.repo / "docs" / "workflow.md").write_text("F-001 F-099 F-999\n", encoding="utf-8")
+        policy = _write_policy(self.tmp)
+        code, out, _ = self._run(["--policy", str(policy), "rule-usage", "--verbose"])
+        self.assertEqual(code, 0, out)
+        self.assertIn("clean", out)
+        self.assertNotIn("F-010", out)
+        self.assertNotIn("F-020", out)
+        self.assertNotIn("F-1234", out)
```

显式断言覆盖：

1. active 表格行全部识别。
2. retired 表格行不识别。
3. `**F-099**` 标题声明识别。
4. `- F-999:` 列表声明识别。
5. 普通行内 `` `F-010` `` 不识别。
6. `F-001 / F-099 / F-999` 三位边界识别。
7. `F-1 / F-1234 / F-FOO` 不识别。

## 本地验证记录

复现旧逻辑：

```text
old declared size 1
old declared ['F-004']
```

模拟修复后 declared：

```text
proposed declared size 14
proposed declared ['F-001', 'F-004', 'F-005', 'F-006', 'F-007', 'F-008', 'F-011', 'F-012', 'F-013', 'F-014', 'F-016', 'F-017', 'F-018', 'F-019']
```

边界验证 dump：

```text
current active table: PASS
retired table excluded: PASS
bold heading declaration: PASS
list declaration: PASS
inline backtick mention excluded: PASS
three-digit boundaries: PASS
non rules rejected: PASS
```

用 proposed declared 集合模拟当前仓库外部引用计数：

```text
F-001 19
F-004 16
F-005 13
F-006 5
F-007 8
F-008 30
F-011 5
F-012 5
F-013 5
F-014 9
F-016 4
F-017 4
F-018 17
F-019 12
simulated rule-usage findings []
```

当前未应用 patch 的基线门禁：

```text
python3 Scripts/audit/docaudit.py all --strict --baseline
docaudit: 11 checks, 0 categories with findings
Exit: 0
```

由于本任务禁止直接修改 `Scripts/audit/docaudit.py`，我没有在 worktree 应用 patch 后重跑完整 `docaudit all --strict --baseline`。但模拟结果显示修复后新增 declared 都已有外部引用，不会引入新的 `rule-usage` finding。

## 已知盲区

1. 本方案不把普通段落中的 `F-001` 或 `` `F-001` `` 当声明位点。理由：那是 reference site，不是 declaration site；否则 `feedback.md` 自身的解释文字会污染 declared 集合。
2. 本方案只按 `## 退役记录` 中文标题切断 retired 段。若未来标题改为英文 `Retired` 或移动退役表，需要同步更新 `F_RULE_RETIRED_HEADING_RE` 或改成 frontmatter/结构化 YAML。
3. 本方案假设 active 表格的编号在第一列。若未来 `feedback.md` 把编号移到第二列，表格声明解析需要重审。
4. 本方案支持 heading/table/list 三种声明格式，不支持 blockquote 中的声明。理由：blockquote 更像引用历史文本，不应默认成为 active declaration。
5. 本方案仍只支持 `F-001` 三位编号。若未来编号超过 `F-999`，需要同步调整 `F_RULE_RE`、声明解析、feedback 编号规则和测试。
