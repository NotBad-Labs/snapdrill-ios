# SnapDrill 项目状态看板

> 最后更新：2026-03-26（全量组件审计 + 产品审计 + 全部修复已合并）
>
> 每次新对话必读此文件恢复上下文。

---

## 当前状态

**Milestone 1「v1.0 架构与文档基线」已关闭。** Git tag `v1.0-doc-baseline`。

### 本轮完成

1. **技术审计** (#428)：131 文件逐个遍历，1 S0 + 6 S2 + 9 S3
2. **产品审计** (#430)：以产品文档为锚点交叉验证（隐私路径 / 用户旅程 / 设计铁律），2 VIOLATION + 6 CONCERN
3. **修复 PR #429**（已合并）：S0 HeaderView 异步加载 + S2 logger level + best-effort 注释 + 卡片对齐默认值 + 图标选择器 88 个 + 卸载警告 + Analytics 默认值 + 草稿 GPS 剥离
4. **修复 PR #434**（已合并）：草稿恢复提示增加细节（学科+时间）+ 7 天过期清理
5. **修复 PR #435**（已合并）：题库编辑模式「全选/取消全选」按钮

### 产品决策记录

- D-7：卡片对齐 → 三选项（左/中/右），默认左对齐（PRD 已更新）
- D-8：图标选择器 → 88 个教育图标按 14 类分组，移除手动输入（PRD 已更新）
- 草稿箱：不需要，当前隐式单草稿恢复模式正确（横向研究结论）

### 优先级

1. PDFPagePickerView sending 参数编译错误修复（pre-existing）
2. Apple 原生对标研究（下一轮对话）
3. TestFlight Build 6

注：Xcode 26.4 引入 pre-existing 编译错误（PDFPagePickerView sending 参数），需单独修复。

## 外部阻塞

| Issue | 内容 | 阻塞 |
|---|---|---|
| #161 | TestFlight Build 6 | DocC 策略确定 |
| #162 | GitHub Pro Branch Protection | 4 月 1 日 |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |
