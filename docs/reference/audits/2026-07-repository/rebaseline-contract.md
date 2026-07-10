# 2026-07-10 Repository Rebaseline Contract

## 目的

本次再基线对仓库、产品和配套工具作系统性清理，但不以代码清零、历史改写或一次性全仓重写作为目标。审计先固定事实和契约，修复再按独立 slice 落地；每个 slice 都必须能与 `develop@d62fead87fb103708652ac5378eda8e2c03f8257` 比较，并能通过 Git 回退。

“无死角”表示所有受管对象都有结论，不表示所有对象都要修改。对象包括产品意图、正常/失败/取消/中断用户旅程、源码、测试、数据与 wire、依赖与许可证、资源、项目配置、脚本、CI、文档、设计证据、隐私、安全、签名和发布操作。

## 不可静默破坏的契约

以下边界只能在 finding 写明影响、迁移与回滚方案并取得 PO 明确授权后改变：

- Git 历史和现有 tags；禁止 orphan reset、force push 或为了“整洁”重写历史。
- Profile 隔离、用户本地数据、备份 wire / golden fixtures、图片路径与 EXIF 隐私边界。
- 采集、管理、导出/打印主旅程及其可访问性、本地化和数据恢复能力。
- Package 单向依赖和 Core 零外部依赖；改变边界必须用依赖图和调用链证明收益。
- 生产 Bundle、Team、App Group、Privacy Manifest、entitlements 和发布身份。

产品行为改变必须沿规范链裁决；实现替换必须沿实证链验证。当前代码不能反向定义产品意图，历史文档也不能覆盖 live behavior。

## 分类

每个受管对象最终只能进入一个主分类：

| 分类 | 判据 | 后续动作 |
|---|---|---|
| `keep` | 有当前 owner、用途和验证证据，复杂度与风险合理 | 保留；记录验证入口 |
| `repair` | 目标正确，但实现、测试、文档或工具存在局部缺陷 | 最小修复；补回归证据 |
| `replace` | 契约仍需要，当前实现的结构性成本高于受控替换 | 先 characterization，再切换实现 |
| `retire` | 当前不再使用，但仍承担兼容、迁移、恢复或历史解释责任 | 明确期限、owner 和删除触发条件 |
| `delete` | 无当前用途或契约责任，删除后 clean checkout 全门禁仍成立 | 独立删除 slice；附引用与行为证据 |
| `defer` | 事实成立但当前收益不足或受外部条件阻塞 | 写 owner、触发条件和复查日期 |

`freeze` 只是审计期间的临时状态，不是最终分类。未知用途不能推定为 `delete`，高 churn、低覆盖或旧日期也不能单独作为删除理由。

## 删除与替换门

删除前必须同时证明：

1. runtime、build、test、generator、CI、文档和发布流程没有有效引用；动态引用必须单独检查。
2. 不承担用户数据、迁移、backup wire、签名、隐私或应急恢复责任。
3. 不属于最新 PO 意图或仍有效的 feature / ADR 契约。
4. clean checkout 上相关测试、docs gates、lint 和 build 通过；用户可见面还要完成 dogfood / screenshot 对比。

替换前还必须有 characterization tests 或等价的可重复证据，明确 old/new 行为差异，并保留一个可回退 commit。不能用“新架构更整洁”代替可测收益。

## 覆盖与路由

| 对象面 | Primary phase | 完成证据 |
|---|---|---|
| 产品意图、术语、功能状态、SSOT、生成物 | 02 Truth | authority inventory、冲突表、dead pointer 清单 |
| Package、DI、并发、共享边界、依赖与废弃代码 | 03 Architecture | dependency graph、runtime flow、分类清单 |
| SwiftData、Profile、迁移、备份、图片 | 04 Data safety | fixtures、失败/回滚测试、兼容矩阵 |
| Capture 与 OCR 主链路 | 05 Capture | 自动化测试与真机/模拟器 dogfood |
| Library、SmartPaper、导出和分享 | 06 Library/export | 用户旅程、输出 golden、性能/内存证据 |
| Review、Dashboard、Settings、Onboarding | 07 Other features | feature contract 与端到端行为证据 |
| Shell、视觉、AX、Dynamic Type、本地化 | 08 UI quality | 关键 viewport 截图、AX gate、人工 dogfood |
| 单元/UI/snapshot oracle、CI、flake、耗时 | 09 Test/CI | 测试拓扑、失败分类、无假绿色入口 |
| 安全、隐私、依赖与供应链 | 10 Security/privacy | threat checks、manifest/data-flow 对账、依赖清单 |
| 构建、签名、metadata、支持、性能和诊断 | 11 Release | clean archive、安装/启动、发布 gap 清单 |
| 去重、成本、风险和最终取舍 | 12 Synthesis | 全对象分类、PO decision packet、go/no-go |

顶层目录、Xcode target、Package target、测试 target、CI workflow、可执行脚本、资源目录、build configuration 和第三方依赖必须全部进入 inventory；不能只按抽样文件宣告“全仓完成”。抽样用于发现问题，inventory 用于证明没有未路由对象。

## 审计到修复的循环

1. 审计分支在固定 base 产生 candidate，C1 现场复核后才能进入 finding ledger。
2. PO 对 verified finding 裁决分类、优先级和允许破坏的契约。
3. 修复在最新 `develop` 的独立 worktree / branch 中执行；审计分支不写产品代码。
4. 修复 PR 必须包含 before evidence、变更边界、验证结果、rollback point 和未解决风险。
5. 运维窗口按 PO 授权串行合并；合并后在 ledger 标记 `fixed` 并记录 commit / PR。
6. 每一轮重新对账 `develop`；后续 slice 不依赖私有记忆或未入仓 agent 报告。

## 再基线完成条件

只有同时满足以下条件，才能把 2026-07-10 审计宣布为已完成的工程再基线：

- 所有受管对象已 inventory 并有 primary phase 和分类，没有“未检查但默认保留/删除”。
- P0/P1 已修复或由 PO 明确接受风险；P2/P3 有 owner、优先级或 defer 条件。
- 主用户旅程具备需求来源、自动化 oracle 和至少一次可复核 dogfood 证据。
- clean checkout 的工具安装、生成器、docs gates、lint、测试和 archive 入口不存在假绿色。
- 最终报告能逐项说明相对固定 base 的保留、删除、替换、质量变化与剩余发布距离。

完成审计不等于追求零缺陷。停止条件是未知风险已显著收敛、剩余工作已被清楚分类，继续扫描不再带来足以改变产品或发布决策的新证据。
