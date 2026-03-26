# SnapDrill 项目状态看板

> 最后更新：2026-03-26（P2 全部完成 + VoiceOver 全模块补齐 + HIG 对标文档修订）
>
> 每次新对话必读此文件恢复上下文。

---

## 当前状态

**Milestone 1「v1.0 架构与文档基线」已关闭。** Git tag `v1.0-doc-baseline`。

### 本轮完成（2026-03-26 全天）

**审计**
- 技术审计 (#428)：131 文件逐个遍历
- 产品审计 (#430)：6 份产品文档 × HIG 交叉验证
- Apple HIG 对标研究 (#436)：26 项检查 + Xcode 独立复核

**修复与功能**
- PR #429：技术+产品修复（S0/S2/P0/P1 + 对齐默认值 + 图标 88 个 + 卸载警告 + GPS 剥离）
- PR #434：草稿提示细节 + 7 天过期清理
- PR #435：题库全选/取消全选按钮
- PR #437：HIG 对标文档修订（原图铁律→图片策略、Declared API 重写、复习按钮 fallback 等）
- PR #439：VoiceOver 全模块补齐（31 文件 + 61 个 L10n 键）+ P2 文档对齐

**产品决策**
- 卡片对齐三选项默认左对齐
- 图标选择器 88 个教育图标，14 类分组
- 草稿箱不做（隐式恢复正确）
- 导出加全选按钮
- VoiceOver v1.0 全模块
- 外观模式保留三选项对标 Telegram

**协作模式确立**
- Claude Code（1M 上下文）：主 agent，统筹规划 + 复核
- Xcode Intelligence：主力执行，利用 Apple 生态 MCP

### 优先级

1. 文档体系 × Apple 开发理念深层对齐（进行中）
2. PDFPagePickerView sending 参数编译错误修复（pre-existing）
3. TestFlight Build 6

## 外部阻塞

| Issue | 内容 | 阻塞 |
|---|---|---|
| #161 | TestFlight Build 6 | DocC 策略确定 |
| #162 | GitHub Pro Branch Protection | 4 月 1 日 |
| #163 | 公司 Apple 开发者账号 | DUNS 就绪后 |
