---
last_verified: 2026-07-09
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [app_store_submission]
audit_note: VALID_WITH_GAP — 通用受众 ASO 草稿已替换旧教育化口径；App Store Connect 提交前仍需按 release binary 与实际 ASC 页面终审
gap_type: placeholder
gap_due: app_store_submission
gap_owner: product
gap_evidence_required: 真实 ASO 文案 / App Store Connect 元数据
review_gate: PO / legal / ASO final review required; do not treat last_verified as submission approval
---
# App Store 元数据（ASO 文案）

> 提交 App Store Connect 前的预备文案，提交前需重审；提交前必须确认 AccessibilityAuditUITests 强制门禁为 11 屏 AX 审计 0 警告。

---

## 基本信息

| 字段 | 值 |
|---|---|
| App 名称 | SnapDrill |
| 副标题 | 本地资料整理与复盘工具 |
| 类别（主） | Productivity |
| 类别（副） | Utilities |
| 年龄分级 | 4+（草稿；最终以 App Store Connect 年龄分级问卷为准） |
| 价格 | 免费（不要在此草稿中承诺尚未配置的付费功能） |
| 版权 | 2026 NotBad Labs L.L.C. |

---

## 关键词（100 字符以内）

### 中文（简体）
```
资料整理,文档扫描,OCR,本地存储,复盘,标签,归档,PDF导出,效率工具,知识管理,打印,隐私
```

### 英文
```
document,scanner,OCR,notes,archive,review,local,productivity,tags,PDF,export,privacy,organize
```

---

## 描述

### 中文（简体）

SnapDrill 是一个本地优先的资料采集、整理与复盘工具。你可以拍照、扫描或导入 PDF，把纸面资料、工作材料、培训内容、票据和个人笔记整理成可检索、可导出的资料库。

核心功能：
- 拍照、扫描、PDF 导入 — 快速保存纸面或电子资料
- OCR 文字识别 — 在设备本地提取可搜索文本
- 分类、来源与标签 — 按自己的方式整理资料
- 回顾与复盘 — 为需要反复查看的内容安排提醒
- PDF 导出与打印 — 把资料带入文件、纸张或其他工作流

隐私承诺：
- 零注册，打开即用
- 用户内容默认保存在设备本地
- 不向 NotBad Labs 服务器发送资料内容
- 不使用第三方分析、崩溃统计或广告 SDK

SnapDrill 不是内容平台，不提供题库、课程、教材或第三方资料。它只是一个安静、可靠的工具，帮助你管理自己提供的材料。

### 英文

SnapDrill is a local-first productivity tool for capturing, organizing, reviewing, and exporting your own materials. Use your camera, document scanner, or PDF import to turn paper documents, work materials, training notes, receipts, and personal references into a searchable personal archive.

Key Features:
- Photo, scan, and PDF import — Capture paper or digital materials quickly
- On-device OCR — Extract searchable text on your device
- Categories, sources, and tags — Organize materials your way
- Review workflow — Revisit important materials when needed
- PDF export and printing — Move your archive into files, paper, or other workflows

Privacy Promise:
- No account required
- User content is stored locally by default
- Material content is not sent to NotBad Labs servers
- No third-party analytics, crash-reporting, or advertising SDKs

SnapDrill is not a content platform and does not provide question banks, courses, textbooks, or third-party materials. It is a quiet, reliable tool for managing materials you provide yourself.

---

## 宣传文本（170 字符以内）

### 中文
```
扫描资料，OCR 识别，标签归档，本地优先。用 SnapDrill 管理自己的文档、笔记和参考材料。
```

### 英文
```
Scan, OCR, tag, review, and export your own materials. Local-first productivity for documents and notes.
```

---

## 审核备注（Review Notes）

```
SnapDrill is a general-audience productivity utility for capturing, organizing, reviewing, exporting, and printing user-provided materials such as documents, notes, receipts, work references, and training materials.

The app does not provide courses, textbooks, question banks, social features, user-generated public feeds, or third-party content. All materials are supplied by the user.

Core workflow:
1. Capture: photo capture, document scanner, PDF import, image import, manual entry, or clipboard input.
2. Organize: categories, sources, tags, search, and local workspaces.
3. Review: optional review workflow for user-saved materials.
4. Export: PDF export, printing, and user-controlled backup/export.

No account registration is required. User content is stored locally on the device using app-local storage. The production app does not use Firebase, third-party analytics, third-party crash reporting, advertising SDKs, or developer-operated content servers.

Camera permission is used for photo capture. Photo library permission is used for user-selected image import. Notification permission is optional and is used only for local reminders.
```

---

## 隐私政策 / 服务条款

| 文档 | URL | 状态 |
|---|---|---|
| 隐私政策 | https://notbadhq.com/privacy | App 内已有 PrivacyPolicyView |
| 服务条款 | https://notbadhq.com/terms | App 内已有 TermsOfServiceView |

> 公司网站已上线公开 URL，提交前需复核可访问性。
