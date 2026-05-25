---
name: phase-closeout
description: 长任务（多 PR / 跨多天的 phase）收官时，将阶段状态写入 docs/memory/handoff.md。当用户说"收官 / 阶段总结 / 写 checkpoint"或单个 phase 合并 ≥ 3 PR 时触发。
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Write
context: fork
disable-model-invocation: false
user-invocable: true
derived_from: [M-003 §11.1]
---
# /phase-closeout — 长任务 checkpoint 生成

## 触发场景

- 用户说："phase 结束 / 收官 / 写 checkpoint / 阶段总结"
- 单个 phase / sprint 合并 ≥ 3 PR 后（参考 `docs/protocol.md` Phase Compaction 规则）
- 接手前发现 STATUS.md 落后多个 PR

## 标准输出

```markdown
---
last_verified: <YYYY-MM-DD>
layer: snapshot
freshness:
  max_age_days: 30
  decay_trigger: [phase_change]
---
# Phase Checkpoint <YYYY-MM-DD> <主题>

## Goal
本 phase 想解决的问题（一句话；引用 Issue/ADR）

## Done
- PR #N <主题>（关键改动 + 受影响 layer + 测试增量）
- ...

## Open
- 待合并 PR
- 待解决子任务（指针到 Issue）

## Decisions
- 关键技术/产品决策（指针到 ADR / discussion / 三方研究）
- 拒绝的方案 + 理由

## Risks
- 已知风险（如 Gemini 幻觉、Mac mini runner 事件）
- 待真机验证项（如 #626 PoC）
- 阻塞链（如 Apple 账号 6 个 issue）

## Next
- 下一组工作清单（可执行优先级排序）
- 阻塞解除后的解锁顺序

## Metrics（可选，若 `.claude/session-metrics.tsv` 存在则填充）
- 本 phase tool call 总数：N
- 调用最频繁的 tool（top-3）：Edit × N1 / Bash × N2 / Read × N3
- session 起止时间（UTC）：YYYY-MM-DDTHH:MM → YYYY-MM-DDTHH:MM
- session 时长：~X.X 小时
```

### Metrics 段填充方法

若 `.claude/session-metrics.tsv` 存在（由 `session-metrics.sh` hook 记录 PostToolUse 的**所有 tool**，matcher `.*`），在 checkpoint Metrics 段填充：

```bash
# 总数
wc -l .claude/session-metrics.tsv

# top-3 tool
cut -f2 .claude/session-metrics.tsv | sort | uniq -c | sort -rn | head -3

# 起止时间 + 时长（小时，保留 1 位小数）
FIRST=$(head -1 .claude/session-metrics.tsv | cut -f1)
LAST=$(tail -1 .claude/session-metrics.tsv | cut -f1)
FS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$FIRST" "+%s")
LS=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST" "+%s")
echo "起: $FIRST  止: $LAST"
echo "时长: $(echo "scale=1; ($LS - $FS) / 3600" | bc) 小时"
```

**限制**：
- 覆盖**所有** tool（PR-5 retry 后 matcher 扩为 `.*`，见 `docs/standards/permission-model.md` §3）
- 不含 token 成本（Claude Code hook 当前不暴露该数据；需自建 HTTPS 代理，ROI 不匹配暂不做）
- 跨 session 累计：hook 追加模式写入，不主动轮转。phase-closeout 完成后用户可手动 `truncate -s 0 .claude/session-metrics.tsv` 重置
- tsv 可能膨胀（一次活跃 session 数百-千行）；如 phase 结束后不清空，后续统计耗时会线性增长

## 位置

写入 `docs/memory/handoff.md`，在 Risks 段下方追加 Phase 状态块。

## 启动 checklist

- [ ] grep `git log --since="<phase 开始>" --oneline` 收集本 phase 所有 commit
- [ ] grep `gh pr list --state merged --search "merged:<日期范围>"` 收集 merged PR
- [ ] Read 当前 STATUS.md 找未固化的 OPEN
- [ ] Read 私有记忆（如 `~/.claude/plans/`）找本 phase 决策记录
- [ ] 三方对抗起草 → 引用 `cross-audit-consensus` skill 产出的汇总文件
- [ ] **Harness Recall**（`docs/standards/harness-recall.md`）：扫描近期 checkpoints Risks 段 + handoff.md，检查重复问题模式。同类 ≥3 次 → propose 新 F-0XX 规则供用户裁决
- [ ] **/knowledge-health 体检（必做，零例外）**：扫 `~/.claude/plans/` + `~/.claude/projects/.../memory/` 找已收官 PR 对应的 stale plan、被 F-0XX 覆盖的 dead memory、过期/重复 checkpoint。skill 只产 plan 不动文件，看完后按计划归档/删除。**跳过此步会让私有空间无限膨胀**——CI/docaudit 看不见，只能靠 closeout 触发

## 与 STATUS.md / handoff.md 的分工

| 文件 | 内容 | 频率 |
|---|---|---|
| `STATUS.md` | 项目当前快照（当前 PR 数 / 测试基线 / 焦点） | 每次 PR 合并 |
| `docs/memory/handoff.md` | 智能体接手状态 / 待合并 PR / 待审批 / 阻塞 | 每次接手 |
Phase 状态块不替代 STATUS / handoff，而是在 handoff.md 内补充阶段细节。

## 反模式

- ❌ 把 phase 状态写到 STATUS.md（污染快照层）
- ❌ 只罗列 PR 不写 Decisions/Risks（失去复盘价值）
