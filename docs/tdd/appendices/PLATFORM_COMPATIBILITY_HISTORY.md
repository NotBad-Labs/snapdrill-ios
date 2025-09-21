# 平台兼容性历史（Historical Platform Compatibility)

本附录用于保留 v6.0 之前关于多 iOS 版本（iOS 16/17/18/26）分层兼容与降级策略的历史记录，便于回顾早期设计决策与迁移方案。自 v6.0 起，项目统一到 iOS 26+ 平台基线，以下内容仅作参考，不再作为实现要求。

## 1. 历史分层矩阵（概述）

- iOS 16：Core Data 为主，基础相机、基础通知、云同步为私有数据库；App Intents 基础支持
- iOS 17：SwiftData 启用（基础级），Vision OCR 优化；多设备同步增强
- iOS 18：AR/visionOS 基础、Core ML 优化、Proactive 能力起步
- iOS 26：Vision AI、Proactive Intelligence、智能冲突解决、深度链接增强等前沿能力

## 2. 历史降级策略要点

- 数据层：SwiftData 不可用时回退 Core Data；运行时基于 `#available` 与 `canImport`
- AI 能力：设备与系统版本不满足时使用静态/云端方案兜底
- 通知：深度体验不可用时回退到基础定时通知
- AR/visionOS：不支持时采用 2D 界面替代

## 3. 迁移结论（v6.0）

- 统一 Deployment Target 到 iOS 26+，显著简化条件编译与测试矩阵
- 仅保留必要的 API 可用性守卫以避免意外回退路径

---

维护备注：如需恢复对更低平台的支持，请在新版本 TDD 中重建矩阵并配套测试用例，而非修改本附录。
