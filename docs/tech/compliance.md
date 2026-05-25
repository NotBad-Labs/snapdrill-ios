---
last_verified: 2026-05-25
layer: pattern
freshness:
  max_age_days: 180
  decay_trigger: [privacy_policy_change, app_review_change]
audit_note: 2026-05-19 验证 — 本文件已 skill 化为指针；权威执行在 privacy-manifests skill + app-store-rejection skill
---
# 隐私合规

> 本文件为合规口径索引，**不是权威实现**：
>
> - 隐私清单（PrivacyInfo.xcprivacy）实现详见 `privacy-manifests` skill
> - App Review 拒审处理详见 `app-store-rejection` skill
> - ATT 移除决策详见 `docs/decisions/ADR-002-remove-att-authorization.md`

## 核心口径

- 数据最小化：仅收集功能必需的数据
- 用户控制：数据导出/删除由用户自主
- 透明：PrivacyInfo.xcprivacy 声明所有 API 使用理由
- Declared Age Range API（iOS 26+）：后续评估

## 关联文档

- `docs/product/product-vision.md` — 产品定位与数据伦理
- `docs/product/product-business.md` — 商业模式与隐私承诺
- `docs/decisions/ADR-002-remove-att-authorization.md` — ATT 移除决策
