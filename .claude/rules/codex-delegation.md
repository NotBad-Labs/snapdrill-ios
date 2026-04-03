<!-- last verified: 2026-04-03 -->
# Codex 子 agent 委派规范

Codex 作为 Claude Code 的子 agent 运行，不自动继承 `CLAUDE.md`、`.claude/rules/`、产品文档体系。
委派 prompt 的质量直接决定 Codex 输出是否符合项目约束。

## 委派 prompt 必须包含

### 1. 文件读取指令

根据任务类型，在 prompt 中明确要求 Codex 先读取：

| 任务类型 | 必读文件 |
|---|---|
| 全部任务 | `STATUS.md`、`docs/workflow.md`（DoD + S0-S3 + Git 工作流） |
| 产品/设计相关 | `docs/product/product-vision.md`、`docs/product/product-design.md`、`docs/product/product-requirements.md`、`docs/product/product-cases.md`（按需选读） |
| 代码实现 | `CLAUDE.md`（执行铁律）、相关 `.claude/rules/*.md`（coding/testing/apple-native 等） |
| 审计/Review | 被审对象的全部上下文 + 上游依赖文档 |

### 2. 关键约束摘要

即使指定了文件读取，也应在 prompt 中内联关键约束，防止 Codex 跳过或遗漏：

- **产品定位**：效率工具，不是教育平台。采集/录入 > 管理 > 导出/打印 > 复习
- **工程哲学**：奥卡姆剃刀，先研究再动手，N > 3 是警告
- **编码铁律**：swiftlint --strict 0 violations + xcodebuild build-for-testing 0 errors
- **数据安全**：零注册、纯本地、图片是真相、Profile 隔离
- **开发纪律**：修改代码前必须先读产品文档；改接口签名后必须 grep 测试同步；UI 改动必须经 Xcode Review；PR 未合并前禁止推进下一任务；Review 结论必须留痕
- **优先级**：S0（数据丢失）> S1（流程阻断）> S2（有摩擦）> S3（不紧急）

### 3. 输出约束

- 语言：中文，技术术语保留英文
- 不加 emoji
- 明确要求输出格式（结构化报告 / 完整文件内容 / 简短结论）
- 明确说明是"只研究"还是"写代码"

## 反模式

- 只说"审计一下这个文件"而不给上下文 — Codex 会缺少项目约束做出泛泛判断
- 把 10 个文件路径丢过去不说目的 — Codex 不知道要验证什么
- 假设 Codex 了解之前对话的上下文 — 每次 Agent 调用都是全新会话
