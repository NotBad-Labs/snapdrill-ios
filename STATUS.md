# SnapDrill 项目状态看板

> 最后更新：2026-03-26（iOS 26 技术栈对齐完成，0 open PR，编译错误全部修复）
>
> 每次新对话必读此文件恢复上下文。

---

## 当前状态

**Milestone 1「v1.0 架构与文档基线」已关闭。** Git tag `v1.0-doc-baseline`。

### 本轮完成（2026-03-26 全天）

**审计（3 层）**
- 技术审计 #428：131 文件逐个遍历，1 S0 + 6 S2 + 9 S3
- 产品审计 #430：隐私路径 / 用户旅程 / 设计铁律
- HIG 对标 #436：26 项 × 两方交叉验证

**合并 PR x8**
- #427：字段配置引导集成
- #429：技术+产品修复（图标 88 个 + 卸载警告 + GPS 剥离等）
- #434：草稿提示细节 + 7 天过期
- #435：题库全选按钮
- #437：HIG 文档修订
- #439：VoiceOver 全模块补齐（31 文件 + 61 个 L10n 键）
- #441：SwiftData SchemaV4 @Unique + PDFPagePickerView 编译修复

**iOS 26 技术栈研究 #440**
- Claude Code + Xcode Intelligence 交叉研究 9 个框架
- Vision API：已是最新，RecognizeDocumentsRequest 不适用（单题图片）
- Liquid Glass：无冲突，自动适配
- SwiftData @Unique：已实施（SchemaV4）
- PDFPagePickerView pre-existing 编译错误：已修复
- Foundation Models / App Intents / TipKit：v1.5 规划

**产品决策 x7 + 协作模式确立**
- Claude Code 统筹复核 + Xcode Intelligence 主力执行

### 优先级

1. 文档体系 × Apple 开发理念深层对齐（维度 3+4 待研究）
2. TestFlight Build 6（编译错误已全部修复）

### 编译状态

✅ `swiftlint --strict`：0 violations
✅ `xcodebuild build`：0 errors（PDFPagePickerView 已修复）

## 外部阻塞

| Issue | 内容 | 阻塞 |
|---|---|---|
| #161 | TestFlight Build 6 | DocC 策略确定 |
| #162 | GitHub Pro Branch Protection | 4 月 1 日 |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |
