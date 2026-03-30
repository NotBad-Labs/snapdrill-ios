---
paths:
  - "**/*.swift"
---

<!-- last verified: 2026-03-30 -->
# Apple 技术能力边界（防止 AI 错误假设）

## Vision / OCR

- Vision OCR 强项是**印刷体**，无独立中文手写识别模型
- RecognizeDocumentsRequest 适合整页文档结构识别，**不适合裁剪后的单题图片**

## Foundation Models

- 擅长文本理解（分类/摘要），**不擅长数学推理**
- contentTagging 适合自动标签，不适合解题

## 不存在的 API

- Math Notes 是 Calculator App 私有能力，**无公开 API**
- Smart Script 是屏幕手写输入，**不是照片 OCR**
- 无 Apple 原生数理化公式识别 API（LaTeX/MathML 需第三方方案）
