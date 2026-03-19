---
id: ADR-008
status: Accepted
date: 2026-03-19
implementation: Partial
verified: 2026-03-19
---

# ADR-008: VoiceOver 全覆盖推迟到 v1.5

## 背景

v1.0 全链路终审（#305）中，三方审计发现 VoiceOver 无障碍覆盖率约 12%（仅 Review feature 7/36 个 View 文件），而 `product-requirements.md` 要求"所有可交互元素提供语义化描述"。PR #346 完成了 Review feature 的 VoiceOver 接入和共享基础设施（`AccessibilityHelper`、`AccessibilityAnnouncement`、5 个 View 扩展）。

短板审计计划中将剩余 ~29 个 View 的 VoiceOver 覆盖列为 Phase 2（4 个 PR）。

## 决策

**VoiceOver 全覆盖（Dashboard / Capture / Library / Settings）从 v1.0 推迟到 v1.5。**

v1.0 保留 PR #346 已完成的 Review feature 覆盖和共享基础设施。

### 理由

1. **产品与用户不匹配**：SnapDrill 是拍照+图片密集型错题存档工具，核心流程（拍试卷、裁剪题目、查看几何图形）天然依赖视觉。视障用户几乎不可能是目标用户（小学生家长、中学生）
2. **App Store 审核不强制**：Apple 不会因 VoiceOver 覆盖不完整拒审，仅影响 Accessibility 评分
3. **法律风险极低**：ADA 主要约束公共服务类 App，SnapDrill 是个人工具类，且无注册、无账号
4. **投入产出比差**：4 个 PR、~29 个 View 文件的改动，对 v1.0 目标用户几乎无价值
5. **基础设施已就绪**：v1.5 实施时成本更低，因为 `AccessibilityModifiers.swift` 和 `AccessibilityHelper` 已完成

## 被否决的方案

### 方案 A：v1.0 全覆盖（原计划）

- **为什么否决**：基于"100% VoiceOver = v1.0 必备"的前提假设。经审视，该前提不成立——产品核心流程对视障用户不可用，全覆盖是锦上添花而非必备
- **何时重新评估**：如果 App Store 审核因无障碍不足被拒，或收到视障用户的明确反馈

### 方案 B：完全不做 VoiceOver

- **为什么否决**：PR #346 已合并且代码质量良好，回滚无意义。Review feature 的覆盖可作为 v1.5 全覆盖的参考模板
- 不适用重新评估

## 后果

### 正面

- v1.0 减少 4 个 PR 的工作量，聚焦真正影响用户的短板（备份/恢复测试等）
- 基础设施已就绪，v1.5 实施成本低

### 负面

- App Store 无障碍评分可能较低（不影响审核通过）
- 如果有低视力（非全盲）用户使用，Dashboard/Capture/Library/Settings 的 VoiceOver 体验不佳

### 需同步更新

- `product-requirements.md`：无障碍章节 + v1.0/v1.5 路线图
- `workflow.md`：移除"VoiceOver 零覆盖"作为"v1.0 必备项"的引用
