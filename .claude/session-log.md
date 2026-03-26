# SnapDrill 工作日志

> 每次对话结束时追加一条记录。保留最近 2-3 条，旧记录删除。
> 行为规则在 `memory/`，单个改动详情在 GitHub PR/Issue。

---

## 2026-03-26 Session（全天）

### 完成

**审计（3 层）**
- 技术审计 #428：131 文件逐个遍历，1 S0 + 6 S2 + 9 S3
- 产品审计 #430：隐私路径 / 用户旅程 / 设计铁律，2 VIOLATION + 6 CONCERN
- HIG 对标 #436：26 项 × 两方交叉验证（Claude + Xcode），0 VIOLATION + 8 MINOR_GAP

**合并 PR x6**
- #429：技术+产品修复（S0/S2/P0/P1 + 对齐默认值 + 图标 88 个 + 卸载警告 + GPS 剥离）
- #434：草稿提示细节 + 7 天过期（#431 #432）
- #435：题库全选按钮（#433）
- #427：字段配置引导集成（#425）
- #437：HIG 文档修订
- #439：VoiceOver 全模块 + P2 文档对齐（#438）

**横向研究 x4**：草稿箱模式 / 图标选择器 / 导出按钮 / HIG 对标

**产品决策 x6**：对齐三选项 / 图标 88 个 / 草稿箱不做 / 全选按钮 / VoiceOver 全覆盖 / 外观对标 Telegram

**协作模式确立**：Claude Code 统筹复核 + Xcode Intelligence 主力执行

### 关键发现

- 技术审计没碰产品文档是严重方法论缺陷——代码写得对不等于做的是产品要的
- Apple 提醒事项用 60 预设图标不开放全量 SF Symbol，验证了我们 88 个预设的决策
- Declared Age Range API 文档描述方向完全错误（App 声明 vs 请求用户年龄）
- COPPA "不收集即不违规" 过于简化——Firebase IDFV 在 COPPA 下可能算"个人信息"

### 下次接续

- 文档体系 × Apple 开发理念深层对齐
- PDFPagePickerView sending 参数编译错误修复
- TestFlight Build 6

---

## 2026-03-25 Session

### 完成

- WWDC 技术综述评估 + 文档 Diátaxis 重构 + Milestone 1 关闭
- 可追溯性审计 5 维度 + 三方审查 + S1 修复
