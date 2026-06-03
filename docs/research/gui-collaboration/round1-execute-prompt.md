# 任务：执行 SnapDrill iOS Round 1 Boot 序列重构（落地实现）

请尽可能开启深度思考。

## 你的角色

**你是 Codex 主笔执行人**。本次任务**不是设计** — 方案已经四家智能体（Claude / Codex / DeepSeek / Gemini）独立提议 + 异源 sanity check 后由用户拍板。你的任务是**忠实落地已拍板方案**，生产具体文件内容。

## 已拍板方案（不要质疑、不要修改、忠实执行）

| # | 议题 | 已拍板 |
|---|---|---|
| A | Boot 必读 | `docs/meta/M-000-meta-vision.md` + `docs/meta/user-decision-log.md`（2 项）|
| B | STATUS.md | **精简为 minimal stub**（明示等 sync-status skill），保留路径与文件本身 |
| C | workflow.md → **protocol.md** | **路径迁移** `docs/workflow.md` → `docs/protocol.md`，内容重写为声明式协议（≤ 200 nwc）；所有引用级联替换 |
| D | feedback.md | 移出 Boot → 仅出现在 Context Map 索引位 |
| E | AGENTS.md | 整档 ≤ 1500 nwc，Boot 段 ≤ 500 nwc，代码块独立预算 ≤ 400 nwc，三段架构（Boot / Action Gate / Context Map）|

## 异源 sanity 关键裁定（影响 protocol.md 重写）

DeepSeek + Gemini 异源否决「workflow 完全删除」的核心理由：
- **范畴错误**：Skill 解决 "How"，workflow/DoD 解决 "When & What"
- **常驻可见性**：文件根目录显式存在 ≠ skill 被动加载
- **冷启动屏障**：新 Agent 不知道有哪些 skill
- **人机协同**：人类需要极简入口调整工作流

所以新 `protocol.md` 是「声明式状态机触发器」 — **不包含 skill 内容本身，只声明何时进入哪个状态、应调用哪个 skill**。

## 交付产物（7 项，全部以 git diff/新内容形式输出）

### 产物 1：`AGENTS.md`（完整重写）

骨架（按顺序）：
1. 标题 + 一句话项目定位（≤ 80 nwc）
2. `## Boot`（≤ 500 nwc）：仅 2 项必读
   1. `docs/meta/M-000-meta-vision.md` — 最高协作宪法
   2. `docs/meta/user-decision-log.md` — 已生效用户裁决与 Overrule
3. `## Action Gate`：触发动作时必读项 → `docs/protocol.md`（改代码/提 PR/跑 lint-test 前）
4. `## Context Map`：表格「需要 → 去读」，覆盖：standards / feedback / KNOWLEDGE_MAP / DOC_DEPENDENCY_MAP / meta/README / M-001~M-006 backlog / STATUS / 起草模板
5. `## 执行门`命令块（≤ 400 nwc 独立预算）：保留 swiftlint --strict + xcodebuild AllTests + AllTests scheme 说明
6. **总字数 ≤ 1500 non-whitespace chars**（不含空白和换行），代码块独立预算 ≤ 400 nwc

旧 `AGENTS.md` 参考：`/Users/yiming/Developer/snapdrill-ios/AGENTS.md`。

### 产物 2：`docs/protocol.md`（新建）

要求：
- ≤ 200 non-whitespace chars（主体，不含 frontmatter）
- 形式：声明式状态机触发器（Plan / Code / DoD / Review / Merge 阶段）
- 每条形如「[阶段] 触发条件 → 必读/必调用 skill 或文档名」
- frontmatter 完整：
  ```yaml
  last_verified: 2026-05-22
  layer: pattern
  scope: workflow
  freshness:
    max_age_days: 365
    decay_trigger: [meta_vision_change]
  ```
- 顶部 1 行指针：声明该文件由 M-000 §3 默认多方原则派生，是 Action Gate 入口

### 产物 3：`docs/workflow.md` 删除 + 全仓引用级联替换

执行步骤：
1. `git rm docs/workflow.md`
2. `grep -rl "docs/workflow\.md\|workflow\.md" --include="*.md" --include="*.py" --include="*.sh" --include="*.json" --include="*.yml"` 锁定所有引用文件（约 30+ 处）
3. 全部替换为 `docs/protocol.md`
4. **排除目录**：`.git/`、`docs/archive/`（archive 是历史快照,不应改）
5. 在最后报告中列出所有被改的文件路径,便于复审

### 产物 4：`STATUS.md`（精简为 stub）

完整新内容（替换全部）：
```markdown
---
last_verified: 2026-05-22
layer: snapshot
scope: status
freshness:
  max_age_days: 7
  decay_trigger: [pr_merge, decision_recorded]
---
# 状态看板

> 本文件待由 `sync-status` skill 双向自动维护（user-decision-log #006 backlog）。skill 落地前，权威状态请见下列来源；本文件**只保留极简手动条目**。

## 当前焦点（手动维护）

- M-000 Meta-Vision v1.2 已 ratified（user-decision-log #004）
- Round 1 Boot 序列重构落地中（user-decision-log #006）
- 下游 M-001 ~ M-006 起草待启动（顺序：M-005 → M-002 → M-006 → M-001 → M-004 → M-003）

## 权威状态源

- 已生效裁决与 Overrule：[docs/meta/user-decision-log.md](docs/meta/user-decision-log.md)
- 下游派生 backlog：[docs/meta/M-001-to-M-006-followup-backlog.md](docs/meta/M-001-to-M-006-followup-backlog.md)
- 文件级变更：`git log --oneline -20`
- 进行中工作：`gh issue list --state open`、`gh pr list --state open`
```

### 产物 5：`CLAUDE.md`（微调同步）

只调整与 Boot 相关的部分，与新 AGENTS.md Boot 段一致。保留 `@AGENTS.md` 继承，不复述清单（避免双源）。

### 产物 6：`docs/meta/user-decision-log.md`（append #006）

新增 `### #006 Round 1 Boot 序列重构 + 异源 sanity check 价值实证`

字段完整（参照 #001-#005 同结构）：时间 / 冲突描述 / 裁决 / 理由 / 是否触发元规则修订 / Overrule 关系 / 元层级注记

**裁决字段必须列出**全部 5 项落地结果（A/B/C/D/E 议题分别拍板了什么）。

**元层级注记必须包含**：M-000 §7.2「结构性同源」预测被实战验证 — Claude+Codex 同向激进方案（删 workflow / 删 STATUS）被 DeepSeek+Gemini 异源独立否决，两家给出几乎一致的「范畴错误 + 常驻可见性 + 软状态丢失（Dark Matter）+ Save-Game O(1) vs Reconstruction O(N)」反对论证。证明异源 sanity check 不是冗余流程,而是必要纠错机制。

### 产物 7：`docs/meta/M-001-to-M-006-followup-backlog.md`（append backlog 条目）

追加 `sync-status` skill backlog 条目：
- 来源：user-decision-log #006
- 描述：STATUS.md 由静态文档改造为 sync-status skill 双向自动维护（read on session start; write on session end）
- 归入哪个 M-XXX 派生项下：自行判断合适位置（建议 M-002 或 M-005，列出理由）

## 工作纪律

1. **不要修改 `docs/memory/feedback.md` / `docs/standards/*` / `docs/meta/M-000-meta-vision.md` 内容**（但可在引用替换中改路径字符串）
2. **不要删除任何文件，除了 `docs/workflow.md`**
3. **nwc 字数自检必须给出**：AGENTS.md 和 protocol.md 末尾各附 `<!-- nwc: NNNN -->`（不含空白和换行的字符数；可用 `python3 -c "import sys,re; print(len(re.sub(r'\s', '', sys.stdin.read())))"` 计算）
4. **diff 必须可直接 git apply**：unified diff 或完整新文件内容
5. **archive 目录绝不修改**

## 输出格式

按产物编号 1-7 顺序输出 7 段，每段前 1 行标题。
最后一段输出「批量替换文件清单」列出所有被改路径。

## 禁止

- 不要质疑已拍板方案
- 不要新增方案讨论
- 不要超 nwc 上限（超出立即重写,不要交付超限版本）
- 不要遗漏 frontmatter
- 不要触碰 `docs/archive/`
- 中文输出,技术术语保留英文
