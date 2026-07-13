---
last_verified: 2026-07-14
layer: snapshot
current_status: shaping_after_release_contract_when_effective
activation: effective_when_release_1_contract_is_on_develop
freshness:
  max_age_days: 30
  decay_trigger: [release_contract_change, app_store_submission]
audit_note: BLOCKED — Product Constitution and Release 1 scope are fixed, but final claims, screenshots and review notes wait for a conforming release build
gap_type: missing_release_build_evidence
gap_due: release_candidate
gap_owner: product-release
gap_evidence_required: conforming release build + privacy/signing evidence + PO/legal/ASO review
review_gate: PO / legal / ASO final review required; do not submit this shaping document
---
# App Store 元数据（待 Release build 实证）

> **不可提交**：本更新在分支 / PR 中仍等待 Release 1 Contract effective；同一更新合入 `develop` 后，产品范围 blocker 才转为 release-build evidence blocker。届时公开边界为：Dashboard 是默认任务枢纽，optional 默认隐藏，Review / SmartPaper 在 `public-candidate` 完全隐藏。关键词、完整描述、宣传文本、截图和审核备注仍须等待实际候选 build、隐私 / 签名实证与 PO / legal / ASO 复核，不能从合同直接生成发布事实。

## 已批准的公开边界

| 字段 | 当前边界 |
|---|---|
| App 名称 | SnapDrill |
| 产品类别 | 成人 Productivity / Utilities 工具，不以 Education 或儿童产品为主叙事 |
| 首个切口 | 处理结构化纸张 / PDF 的成年人 |
| 核心价值 | 把纸张、照片和 PDF 变成可搜索、可整理、可打印的个人资料库 |
| 核心价值链 | 采集 -> 整理 / 找回 -> 导出 / 打印 |
| 价格 | Release 1 免费、无广告、无 IAP |
| 设备 | iPhone-only |
| 产品语言 | 英文 + 简体中文 |
| 发布主体 | NotBad Labs L.L.C.（美国全球版） |
| 数据姿态 | local-first、无 SnapDrill 账户、永久可携带手动备份；发布前仍须用二进制与网络实证复核 |

年龄分级、类别、副标题和所有法律 / 隐私声明必须在提交前按真实构建与 App Store Connect 问卷再次确认；本表不替代 legal review。

## 候选价值表达（非最终 ASO）

### 简体中文

> SnapDrill 帮助你以最低摩擦，把纸张、照片和 PDF 变成可搜索、可整理、可打印的个人资料库。无需 SnapDrill 账户，资料默认保存在本机，并可通过手动备份带走。

### English

> SnapDrill helps you turn paper, photos, and PDFs into a searchable, organized, printable personal library with minimal friction. No SnapDrill account is required; your library stays local by default and remains portable through manual backup.

该表达只承接 B1-B4，不声明某个输入渠道、OCR 语言、分类字段、Review、SmartPaper 或输出格式一定进入 Release 1。

## 当前禁止的公开主张

- 不把产品描述为儿童教育 App、题库、搜题、解题或内容服务。
- 不把考试、认证、培训或家庭资料写成已经验证的唯一市场；它们只是首个切口示例。
- 不宣传 Pro、IAP、价格、Free Trial、Lifetime、CloudKit、Word 或“即将推出”的付费能力。
- 不声称支持 iPad 或中国大陆专项版本。
- 不把当前代码存在、feature-status、历史 ADR 或 Draft PR 当成发布功能证据。
- 不在未复核发布二进制、Privacy Manifest、entitlements 和网络流量前作绝对隐私声明。

## 最终候选 build 必须补齐

1. 副标题、关键词、完整描述与宣传文本。
2. 真实 Release 1 功能清单，不把 optional / hidden / backlog 写成已提供。
3. Dashboard 与所有 Must / manifest-included 可见能力的真实截图；Review / SmartPaper 只保留 public-candidate 不可达的负向证据，不得出现在公开截图或主张中。
4. 相机、相册、通知、Share Extension 等权限 / 能力的真实审核备注。
5. 隐私标签、Privacy Manifest、网络与数据流一致性说明。
6. iPhone 截图集、Dynamic Type / AX 证据和本地化复核。
7. 支持、隐私政策、服务条款 URL 的线上内容与可访问性。
8. PO、legal、ASO 和 release DRI 的最终 go / no-go。

## 已知公开 URL

| 文档 | URL | 当前用途 |
|---|---|---|
| 隐私政策 | https://notbadhq.com/privacy | 提交前与真实 Release 1 构建复核 |
| 服务条款 | https://notbadhq.com/terms | 提交前与免费、无 IAP 政策复核 |
