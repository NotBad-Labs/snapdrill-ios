---
last_verified: 2026-07-25
layer: architecture-decision
decision_id: ADR-002
status: accepted
decided_at: 2026-04-10
decay_trigger: [tracking_added, advertising_attribution_added, privacy_contract_changed]
---
# ADR-002: 不引入 App Tracking Transparency 授权链路

## 背景（Context）

SnapDrill 当前不跨其他公司的 App、网站或线下属性关联用户或设备数据，不访问 IDFA，也不包含
广告归因。Privacy Manifest 声明不追踪，工程配置中不存在
`NSUserTrackingUsageDescription`，代码和依赖中不存在 AppTrackingTransparency。

Apple 将 ATT 用于请求追踪许可和访问广告标识符；没有追踪行为时增加预提示或系统授权链路，
会制造一个产品并不需要的权限状态和额外首启摩擦。

## 决策（Decision）

生产 App 不引入 ATT framework、预提示、系统授权请求或 tracking usage description。诊断偏好、
本地 MetricKit 和普通隐私说明不得复用或模拟 ATT 状态。

只有当新的 effective 产品与隐私 contract 明确引入 Apple 定义的 tracking 或广告归因后，才能
重新评估 ATT；技术实现不能以“未来可能需要”为由提前恢复。

## 备选方案（Alternatives）

- **保留一条默认不触发的 ATT 链路**：拒绝。它没有当前用户价值，会增加死代码、测试面和声明
  漂移风险。
- **启动时防御性请求 ATT**：拒绝。当前没有需要该权限的行为，也不应让核心功能依赖追踪许可。
- **按需重新引入**：接受为未来路径，但必须先有新的产品、隐私和发布权威。

## 后果（Consequences）

- Onboarding 和 Settings 不展示追踪授权或诱导性预提示；
- `PrivacyConsentService` 只管理当前存在的本地偏好，不包装 ATT；
- Privacy Manifest、Info.plist、App Store Connect 隐私回答和运行时行为必须保持一致；
- 将来引入 tracking 会成为独立的产品、隐私、实现和发布变更，不能由本 ADR 自动授权。

## 验证与复议触发器（Validation）

- 配置与源码中不得出现 `NSUserTrackingUsageDescription`、`ATTrackingManager` 或
  AppTrackingTransparency 依赖；
- Privacy Manifest 必须继续声明 `NSPrivacyTracking=false`；
- 若新增第三方广告/归因 SDK、跨公司数据关联或 tracking 产品需求，本 ADR 立即进入复议。

## 关联权威（Related authorities）

- [Product Vision & Principles](../product/vision.md)：local-first 与无开发者内容云边界；
- [隐私与合规](../explanations/privacy-compliance.md)：当前隐私承诺与发布核验；
- [Apple User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/)：
  ATT 的平台适用范围；
- [NSUserTrackingUsageDescription](https://developer.apple.com/documentation/bundleresources/information-property-list/nsusertrackingusagedescription)：
  调用 ATT API 时的配置要求。
