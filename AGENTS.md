# AGENTS.md

> SnapDrill 编码 Agent 的最小入口。先读根 `README.md`，再按任务读取对应 owner。
> `CLAUDE.md` 和 `.github/copilot-instructions.md` 是本文件的兼容软链接。

## 当前 owner

- 产品需求：`docs/PRD.md`
- 架构与实现偏差：`docs/ARCHITECTURE.md`
- 数据、图片、删除、备份与恢复：`docs/DATA.md`
- 开工、协作、验证与合并：`docs/DEVELOPMENT.md`
- 候选构建、签名与发布：`docs/RELEASE.md`

代码、测试、配置和设备证据证明当前状态，不能反向改写产品需求。旧 issue、PR、Git 历史、
聊天摘要和 Agent 记忆默认只作线索。

## 执行要求

写入前完整执行 `docs/DEVELOPMENT.md` 的开工顺序和 T0。所有 worktree、WIP、验证等级、PR 与
merge 规则只在该文件维护，本文件不复制。

默认行为：

1. 先读 owner、live 实现和调用方；平台事实优先查官方资料。
2. 选择满足验收的最简单完整方案，不增加未要求功能或投机抽象。
3. 每行改动追溯到结果、根因、验收或保持一致所必需的工作。
4. 不覆盖、不回滚、不格式化其他 lane 或用户的无关改动。
5. 先定义 pass / fail，再按 `docs/DEVELOPMENT.md` 运行证据；build 不等于 tests。

## 必须询问 PO

- 修改产品身份、目标用户、PRD、公开承诺或需求优先级；
- 商业模式、平台、区域、账号、同步、隐私或对外数据兼容政策；
- 生产账号、密钥、证书、签名和不可逆外部动作；
- 上传、TestFlight 开放、go / no-go 和发布。

已确认 PRD / DATA 边界内的分析、实现、测试、客观事实修正和 Draft PR 不重复询问。

## 工程不变量

- iOS 26+、Swift 6.3 strict concurrency、SwiftUI、SwiftData。
- App 是 composition root；依赖向 Core 收敛，Core 零第三方依赖。
- 目标是单一资料库；不得继续扩展 legacy Profile 架构。
- 用户图片入库前移除 EXIF 位置；图片路径在读、写、删和恢复边界校验。
- 生产不上传用户内容，不使用第三方行为分析。
- View 不持有 `ModelContext`；写入经 Repository 和 `DataExecutor`，失败必须 rollback。
- 简单异步使用 `async/await` 和 `.task`；错误显式处理，禁止 silent `try?` 吞错。
- accessibilityIdentifier、wire key、schema、Bundle ID、Team 和 App Group 不是普通文案。

## 文档

当前事实只进入五个 owner、根 README 或本文件。审计报告、截图、运行日志和临时计划留在 PR、
CI artifact 或临时目录；Git 历史负责回滚。新增长期文档前必须先证明现有 owner 无法承载，并
同步更新 `Scripts/validate_docs.py`。
