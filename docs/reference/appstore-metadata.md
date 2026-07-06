---
last_verified: 2026-06-13
layer: snapshot
freshness:
  max_age_days: 60
  decay_trigger: [app_store_submission]
audit_note: VALID_WITH_GAP — Apple 账号与公开 URL 已就绪；真实 ASO 文案 / App Store Connect 元数据仍待提交前重审
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
| 副标题 | 练习题数字化效率工具 |
| 类别（主） | Productivity |
| 类别（副） | Utilities |
| 年龄分级 | 4+ |
| 价格 | 免费（含 App 内购买） |
| 版权 | 2026 NotBad Labs L.L.C. |

---

## 关键词（100 字符以内）

### 中文（简体）
```
错题本,练习题,拍照录入,OCR,试卷,复习,间隔重复,效率工具,文档,归档,PDF导出,扫描,整理,打印
```

### 英文
```
wrong,answers,practice,OCR,exam,review,spaced,repetition,productivity,homework,archive,organize,PDF,export,scan
```

---

## 描述

### 中文（简体）

SnapDrill 让练习题数字化变得简单。拍照、扫描或导入 PDF，自动识别文字，一键归档到题库。

核心功能：
- 拍照/扫描/PDF 导入 — 多种采集方式，灵活高效
- OCR 文字识别 — 自动提取题目内容，支持中英文混合
- 学科/来源/标签/年级 — 多维分类，快速检索
- 间隔重复复习 — SM-2 算法科学安排复习计划
- PDF 导出 — 一键生成可打印的练习卷

隐私承诺：
- 零注册，打开即用
- 不收集姓名、手机号、学校等直接身份信息
- 练习内容与图片仅本地存储
- 无第三方分析与崩溃统计，全部数据保留在设备本地

SnapDrill 专注一件事：让你用最少的时间，把纸上的练习题变成可管理、可复习的数字资产。

### 英文

SnapDrill makes digitizing practice problems effortless. Snap a photo, scan a document, or import a PDF — text is recognized automatically and archived into your personal question bank.

Key Features:
- Photo/Scan/PDF Import — Multiple capture methods for maximum flexibility
- OCR Text Recognition — Automatically extracts question content with Chinese-English support
- Multi-dimensional Organization — Subject, source, tags, and grade classification
- Spaced Repetition Review — SM-2 algorithm for scientifically scheduled reviews
- PDF Export — One-tap printable practice sheets

Privacy Promise:
- Zero registration required
- We do not collect direct identifiers such as your name, phone number, or school
- Practice content and images stored locally on your device
- No third-party analytics or crash reporting; all data stays on-device

SnapDrill does one thing well: turn paper-based practice problems into manageable, reviewable digital assets with minimal effort.

---

## 宣传文本（170 字符以内）

### 中文
```
拍照录入练习题，OCR 自动识别文字，间隔重复科学复习。零注册，数据纯本地。
```

### 英文
```
Snap practice problems, OCR extracts text, spaced repetition supports review. Zero signup, local-first.
```

---

## 审核备注（Review Notes）

```
SnapDrill is a productivity utility for digitizing user-provided practice materials (notebooks, printouts, homework). Content is supplied entirely by the user; the app does not provide any question bank, course content, or third-party material.

Core workflow:
1. Capture: Photo / Document Scanner / PDF Import
2. Organize: Subject, Source, Tags, Grade classification
3. Review: SM-2 spaced repetition algorithm
4. Export: PDF generation for printing

No account registration is required. All data is stored locally on the device using SwiftData.

SnapDrill does not collect direct identifiers such as name, phone number, email, or school. The production app does not use Firebase or third-party analytics/crash reporting. User content remains on-device; device diagnostics use on-device MetricKit and Apple-provided aggregated diagnostics.

The app requires camera permission for photo capture and photo library permission for image import. Notification permission is optional for daily review reminders.
```

---

## 隐私政策 / 服务条款

| 文档 | URL | 状态 |
|---|---|---|
| 隐私政策 | https://notbadhq.com/privacy | App 内已有 PrivacyPolicyView |
| 服务条款 | https://notbadhq.com/terms | App 内已有 TermsOfServiceView |

> 公司网站已上线公开 URL，提交前需复核可访问性。
