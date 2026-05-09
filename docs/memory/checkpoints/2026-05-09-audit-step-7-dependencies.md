---
last_verified: 2026-05-09
layer: snapshot
freshness:
  max_age_days: 90
  decay_trigger: [next_audit]
---
# Step 7: 依赖与供应链审计

## Goal

审计外部依赖的版本锁定、安全公告、隐私声明和 license 合规。

## Scope

12 文件：Package.swift(5) + Package.resolved(5) + GoogleService-Info.plist(1) + GoogleService-Info.plist.example(1)

## Findings

### Warning (1)

**W1: GoogleService-Info.plist 与 .example 的 ANALYTICS_COLLECTION_DEACTIVATED 值相同**
- 两文件 `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED` 均为 `<true/>`
- 基线审计 X6（Codex 发现）指出 `.example` 缺少默认禁采集 keys
- 经验证，当前 `.example` 已包含 `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED = true`
- **降级为 Info**：X6 实际上已修复，但在基线报告闭合后未更新状态
- 当前 `IS_ADS_ENABLED = false` ✅、`IS_SIGNIN_ENABLED = true`（Firebase Auth 未被使用，可优化但不关键）

### Info (1)

**I1: IS_SIGNIN_ENABLED = true 但项目不使用 Firebase Auth**
- GoogleService-Info.plist 中 `IS_SIGNIN_ENABLED = true`
- SnapDrill 是零注册纯本地架构，不接入 Firebase Auth
- 风险极低（代码中无 FirebaseAuth import）
- 建议：设为 `false` 以减少 Firebase 后台初始化开销

## Positive Findings

**✅ 依赖版本约束全部合理**

| 依赖 | 约束 | 当前解析版本 | 范围 |
|---|---|---|---|
| Firebase iOS SDK | `from: "11.0.0"` | 11.15.0 | 11.0.0..<12.0.0 ✅ |
| ZIPFoundation | `from: "0.9.19"` | 0.9.20 | 0.9.19..<1.0.0 ✅ |
| Mantis | `from: "2.23.0"` | 2.28.2 | 2.23.0..<3.0.0 ✅ |
| swift-snapshot-testing | `from: "1.17.0"` | 1.19.2 | 1.17.0..<2.0.0 ✅ |

**✅ 5 个 Package.resolved 版本一致**
- ZIPFoundation: 0.9.20（SnapDrillData、SnapDrillFeatures、swiftpm 三个 resolved 均一致）
- Mantis: 2.28.2（SnapDrillFeatures、SnapDrillUI、swiftpm 三个 resolved 均一致）

**✅ Firebase 隐私配置正确**
- `FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED = true`（默认不采集）
- `IS_ADS_ENABLED = false`
- 应用层双重 opt-in 守卫：`FirebaseBootstrap` 默认 off + `DependencyContainer.FeatureFlags.analyticsEnabled`

**✅ License 合规**
- Firebase: Apache 2.0
- ZIPFoundation: MIT
- Mantis: MIT
- swift-snapshot-testing: MIT
- 全部与项目兼容

**✅ 无已知 CVE**（基于 2026-05-09 检查）：
- Firebase 11.15.0 — 当前稳定版，无公开 CVE
- ZIPFoundation 0.9.20 — 无公开 CVE
- Mantis 2.28.2 — 无公开 CVE

## Score

| 维度 | 得分 | 说明 |
|---|---|---|
| 正确性 | 9/10 | 版本约束全部合理，解析一致 |
| 完整性 | 8/10 | 隐私配置良好，IS_SIGNIN 可优化 |
| 一致性 | 9/10 | 多 resolved 版本一致 |
| 可维护性 | 8/10 | 版本约束使用 from: 有一定范围弹性 |
| **综合** | **8.5/10** | |

## Next

Step 3: 知识体系审计
