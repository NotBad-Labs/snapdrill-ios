---
last_verified: 2026-05-25
layer: pattern
---
# 文档审计 Rubric（Phase 1 产物）

> 本文件定义"有效 / 无效过时 / 需要修订"的统一判定标准。
> 所有裁决必须绑定证据，禁止凭感觉判断。

## 判定标签

### VALID（有效）
**必要条件（全部满足）：**
1. 内容与当前代码、流程、产品状态一致
2. 仍被其他文档/流程/skill/CI/hook/人工协作使用 或 作为独立入口具有保留价值
3. 文档承担明确职责，无明显重复或漂移

**排除条件（任一命中则不能判 VALID）：**
- last_verified 超过 freshness max_age_days 且内容有明显过时事实
- 描述的功能/流程/规则已被废弃或从未实现
- 与其他文档存在实质性冲突

### STALE_OR_INVALID（无效/过时）
**必要条件（至少满足一条）：**
1. 内容描述与当前项目事实冲突
2. 所属流程/规则/产品方向/技术方案已经废弃
3. 对应的功能/模块/流程已从代码库中物理删除，且无其他文档覆盖

**排除条件（任一命中则不能判 STALE_OR_INVALID）：**
- 作为 ADR/历史决策记录具有溯源价值（即使内容已过时）
- 被其他活跃文档明确引用为约束来源
- 内容虽旧但描述的是尚未改变的底层原则
- 属于"愿景/规划/路线图"类文档——其本质是描述未来态，与当前事实冲突是正常的
- 内容虽无引用链但通过搜索仍可被发现的独立参考文档

### NEEDS_REVISION（需要修订）
**必要条件（至少满足一条）：**
1. 文档仍有价值，但存在事实错误
2. 范围过宽或过窄
3. 引用过时
4. 与其他文档重复或冲突
5. 术语漂移或与 glossary 不一致
6. TestFlight/未上架状态不匹配
7. 与其他同样 VALID 的文档存在职责重叠（冗余）

### VALID_WITH_GAP（有效但有外部缺口）

文档本身内容正确且仍被使用（满足 VALID 条件），但**含 EXTERNAL_GAP**（声明的某些事实必须靠外部账号/权限/真机/Apple/CI 才能验证，当前 audit 工具链无法 100% 闭环）。

**典型场景**：
- 描述 Apple 平台行为，需真机 / WWDC 信息验证
- 描述 CI 行为，需访问 GitHub Actions / Mac mini runner
- 描述 App Store 行为，需 App Store Connect 账号
- 描述用户行为，需 TestFlight 反馈

**处置**：保留为 VALID_WITH_GAP，在 audit-ledger 标注 EXTERNAL_GAP 类型，约 2 个审计周期补齐证据；超过 2 周期未补齐 → 归档而非保留为 VALID。

## 证据类型

| 类型 | 说明 | 示例 |
|---|---|---|
| `DOC_EVIDENCE` | 文档内原文 | 某段描述的具体措辞 |
| `CROSS_DOC_EVIDENCE` | 其他文档引用、依赖图、知识地图 | DOC_DEPENDENCY_MAP 中的上下游关系 |
| `CODE_EVIDENCE` | 源码、测试、配置、CI、hook、skill 实现 | grep 代码确认 API 是否存在 |
| `PROCESS_EVIDENCE` | workflow、DoD、execution gates、review 规范 | 实际执行的命令 vs 文档描述 |
| `PRODUCT_EVIDENCE` | 当前 TestFlight 阶段、产品愿景、需求、App Store 文案 | 内测未上架 vs 文档中的发布描述 |
| `EXTERNAL_GAP` | 需要外部账号/权限才能验证 | Apple 账号、App Store Connect、GitHub Actions |

## 置信度

| 级别 | 条件 |
|---|---|
| `high` | 至少两类证据支撑，无 contradictory 证据 |
| `medium` | 至少一类证据支撑，或有多类但存在 minor contradiction |
| `low` | 无直接证据，或证据之间存在显著矛盾 |

## 建议动作

| 动作 | 条件 |
|---|---|
| `keep` | VALID，无需改动 |
| `revise` | NEEDS_REVISION，修订成本低于重写 |
| `merge` | 与其他文档内容重复，合并到一个文档 |
| `archive` | STALE_OR_INVALID，但有历史溯源价值 |
| `delete` | STALE_OR_INVALID，无历史价值，无引用链 |

## 裁决规则

1. 不允许只用"感觉过时""看起来重复"作为裁决依据——必须绑定具体证据
2. 任何存在 EXTERNAL_GAP 的文档不得直接判 `delete`，最多判 `NEEDS_REVISION` 或 `VALID_WITH_GAP`
3. ADR、feedback、handoff 类历史/流程文档，判 `delete` 前必须人工确认
4. low 置信度裁决必须说明缺口，并在 Phase 6 重新审核
5. 标注 EXTERNAL_GAP 的文档，若连续 2 个审计周期无法补全证据，应归档而非保留为 VALID
6. 文档不得包含 secrets/API keys/凭证——审计时如发现此类内容，直接判 NEEDS_REVISION
