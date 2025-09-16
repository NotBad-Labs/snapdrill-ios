# Observability 指标与告警阈值 v1.0

本文件定义 NotBad 的指标口径、聚合方式、分层维度、告警阈值与看板布局，服务产品/工程/运营的一致观测。

## 1. 数据源与采集
- 事件埋点：AnalyticsServiceImpl（本地缓冲、批量上传、重试与采样）
- 崩溃：App Store Connect / 第三方 Crash SDK（如引入需在隐私章节登记）
- 性能：App 内指标（冷启动、首帧、OCR 用时）、系统日志采样
- 云同步：CloudKit 调用耗时/错误码/冲突率/配额使用

采样与上报策略：核心 L1 事件 100% 采集；L2/L3 事件 10%-50% 采样（可按需调整）；离线上报合并批次。

## 2. 事件分层
- L1（漏斗）：photo_start, ocr_succeeded, edit_committed, save_succeeded, study_started, study_completed
- L2（质量）：ocr_duration_ms, ocr_confidence, re_ocr_triggered, sync_conflict_count, sync_roundtrip_ms
- L3（调试）：error_code, error_context, device_model, os_version, network_type

## 3. KPI 与口径（Aggregation）
- 冷启动时长：冷启动场景下 app_start→first_interaction 的时间，P50/P95，窗口=1d，维度：app_version, device_tier, os_version（iOS 26 为主口径）
- 核心链路成功率：从 photo_start 到 save_succeeded 的会话级成功占比，P95 目标≥98%，窗口=1d
- OCR 用时：photo_capture→ocr_succeeded，P50/P95；维度：lighting_bucket（明/暗/逆光），device_tier
- OCR 质量：ocr_confidence 的均值与 <0.8 confidence 的占比
- 重识别触发率：re_ocr_triggered / photo_start
- 同步延迟：save_succeeded→另一设备可见的端到端，P95；维度：network_type
- Crash-Free Users：ASC 或 CrashSDK 口径，窗口=1d/7d
- 资源：峰值内存 P95、10 分钟学习会话平均电量消耗

设备分层建议：
- T0：iPhone 15 Pro（A17 Pro）及以上（性能基线，用于 SLO 验收）
- T1：iPhone 14 Pro / 15（A16/A17）
- T2：iPhone 13 Pro / 14（A15/A16）
- T3：iPhone 12 Pro / 13（A14/A15）

## 4. 告警配置

### 4.1 红线告警（P0，立即响应）
- Crash-Free Users < 99.5%（1h 窗口）
- 核心链路成功率 < 95%（15min 窗口，连续 2 个点）
- 冷启动 P95 > 2000ms（30min 窗口，基线机型）

### 4.2 黄线告警（P1，工作时间响应）
- OCR 准确率（confidence > 0.8）< 80%（1h 窗口）
- 重识别触发率 > 20%（1h 窗口）
- 同步延迟 P95 > 60s（30min 窗口）
- 峰值内存 P95 > 800MB（1h 窗口）

### 4.3 趋势告警（P2，日常监控）
- 7 日留存率 week-over-week 下降 > 5%
- 学习会话时长 P50 < 4min（24h 滚动）
- CloudKit 配额使用率 > 80%

## 5. 看板布局（Dashboard）

### 5.1 核心业务看板
- 漏斗转化：拍照→识别→编辑→保存→复习→完成
- 留存：D1/D7/D30，按 cohort 切片
- 使用：DAU/WAU，学习会话数/时长，复习完成率

### 5.2 技术质量看板
- 性能：冷启动/OCR/卡片切换的 P50/P95
- 稳定性：Crash-Free Users，ANR 率，错误率
- 资源：内存/电量/网络，包体积趋势

### 5.3 运营监控看板
- 设备分布：iOS 版本，机型分层，地域
- 功能使用：家长模式激活率，Pro 转化，导入导出
- 同步状态：CloudKit 成功率，冲突处理，配额监控

## 6. 数据保留与访问
- 原始事件：30 天（详细调试用）
- 聚合指标：1 年（趋势分析用）
- 关键 KPI：永久保留（历史对比用）
- 访问权限：产品/工程/数据团队；敏感数据脱敏

## 7. 隐私与合规
- 用户 ID：使用 UUID 或 hash，不关联个人信息
- 设备指纹：最小化采集，仅用于去重与分层
- 地理位置：仅采集国家/地区级别，不采集精确坐标
- 内容数据：不上报用户题目内容、图片或个人学习记录

---

**版本历史**
| 版本 | 日期 | 变更说明 | 作者 |
| :-- | :-- | :-- | :-- |
| v1.0 | 2025-09-16 | 初版指标与告警定义，对齐 PRD v4.1 | chramboliao |