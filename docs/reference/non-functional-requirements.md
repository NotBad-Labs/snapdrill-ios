---
last_verified: 2026-07-20
layer: pattern
freshness:
  max_age_days: 180
  decay_trigger: [perf_budget_change]
---
# SnapDrill 非功能需求（NFR）

> 性能、隐私、存储、兼容性的量化标准。单功能行为见 feature spec；本次发布范围与验收见当前 Release Product Contract，`scope-and-roadmap.md` 只维护候选与重入边界。

---

## 性能

| 指标 | 目标 | 测量方式 |
|---|---|---|
| **App 启动（冷启动）** | < 2 秒到首屏可交互 | Xcode Instruments Time Profiler |
| **OCR 识别响应** | < 2 秒（印刷体中英文） | 拍照后到文字出现在编辑区 |
| **资料库列表加载** | < 500ms（200 条） | 从 Dashboard 进入 Library 到列表渲染完成 |
| **搜索响应** | < 300ms | 输入关键词到结果更新 |
| **PDF 导出** | < 5 秒（50 条） | 点击导出到预览页显示 |
| **快速打印（Candidate optional）** | < 3 秒（4 条）；仅冻结 manifest 纳入后适用 | 选中资料到系统打印面板弹出 |
| **备份打包** | < 30 秒（500 条 + 图片） | 点击备份到 ShareSheet 弹出 |
| **CSV 导入（Candidate optional）** | < 5 秒（1000 行）；GAP-R6 修复且冻结 manifest 纳入后才适用 | 选择文件到资料入库完成 |
| **滚动帧率** | 60fps（无掉帧） | 资料库列表快速滚动 |

## 内存

| 场景 | 上限 | 防护措施 |
|---|---|---|
| 资料库浏览（200 条） | < 150MB | 图片按需加载 + 下采样 |
| PDF 批量导出 | < 200MB | autoreleasepool 逐页释放 |
| 备份/恢复 | < 200MB | `.snapdrillbackup` image BLOB 增量读写；不把单图、全库图片或整个数据库物化为一个 `Data` |
| 图片裁剪 | < 300MB | Mantis 内部管理 |
| CSV 导入（1000 行，Candidate optional）| < 80MB；GAP-R6 修复且冻结 manifest 纳入后才适用 | 解析流逐行处理，不全文加载到内存 |

## 存储

| 指标 | 基准 |
|---|---|
| **单题均值** | OCR 文字 ~5KB + 压缩图片 ~200KB ≈ **205KB** |
| **200 题** | ~40MB |
| **2000 题** | ~400MB |
| **图片压缩** | normalized JPEG 的产品接受边界只见 [S1-A](local-library-data-contract.md#21-release-1-内容与图片接受边界s1-a)；JPEG quality 0.8 是当前实现基准，不是第二份产品上限 |
| **草稿** | 数量与生命周期只见 [Capture feature spec](../features/active/feat-capture.md#2-需求规则-what)；本表不另设过期或容量预算 |
| **缓存** | 临时文件 + OCR 中间产物；Release 1 用户可见手动清理入口隐藏，内部清理不得触碰 App-managed 主图或资料数据 |

## 隐私与安全

| 需求 | 标准 |
|---|---|
| **零注册** | 不要求手机号、邮箱、学校年级 |
| **零后端行为采集** | 生产注入 `NoOpAnalyticsService`，不上传用户内容、持久设备标识或逐事件行为 |
| **端上处理** | OCR 在设备上执行，图片不上传云端 |
| **EXIF 剥离** | 保存图片前清除 GPS 等位置信息 |
| **Apple 原生诊断** | 仅使用 App Store Connect 聚合与端侧 MetricKit；不包含 Firebase 或第三方分析/崩溃 SDK |
| **Not Tracking** | Privacy Manifest 声明 NSPrivacyTracking = false，不使用 IDFA |
| **CSV 注入防护（导出）** | 导出 CSV 时以 `=+\-@` 开头的值前加 tab |
| **CSV 解析（导入）** | 严格 RFC 4180 合规：引号转义、CRLF/LF 兼容、字段数不匹配则整行拒绝并提示用户；解析层在 `SnapDrillFeatureSettings/CSVParser.swift` |

## 兼容性

| 维度 | 要求 |
|---|---|
| **最低 iOS** | 26.0 |
| **设备** | Release 1 仅支持可运行 iOS 26 的 iPhone；退出 Apple Silicon Mac / Apple Vision Pro compatibility distribution；iPad 或兼容平台重入需新裁决 |
| **屏幕尺寸** | Release 1 iPhone viewport 集合；现有 regular-size 代码不构成 iPad 支持声明 |
| **方向** | 只消费 [Release 1 Contract ORI-A](release-1-contract.md#7-明确非目标与隐藏能力)；本表不另定义 shell 或媒体方向 |
| **分屏** | 不属于 Release 1；iPad 重入时重新定义 |
| **国际化** | 英文 + 简体中文，App 内可切换 |
| **深色模式** | 跟随系统 / 浅色 / 深色 三选项 |

## 无障碍

| 需求 | 标准 |
|---|---|
| **VoiceOver** | 全模块所有常见任务可完成 |
| **Dynamic Type** | 所有可见文案、操作和可执行本地事实随系统 Dynamic Type 缩放且保持可达；不据此要求保留任何统计表面 |
| **手势替代** | 滑动操作必须有对应按钮 fallback |
| **色彩对比度** | 文字与背景对比度 ≥ 4.5:1（WCAG AA） |

### Review 实验排版

| 需求 | 标准 |
|---|---|
| **可见范围** | C4-D 只允许非公开实验从 Library 单一入口进入；Settings 中字号 / 对齐等 Review 控件必须隐藏 |
| **默认可读性** | 正反面内容与全部操作在受支持 Dynamic Type / VoiceOver 矩阵中可读、可达，不依赖用户先配置字号 |
| **当前实现偏差** | `cardFrontFontSize` / `cardContextFontSize` 的 Per-Profile 设置只作迁移证据，不是 Release 1 产品要求 |

## 可靠性

| 场景 | 要求 |
|---|---|
| **数据持久性** | 保存操作后数据不丢失（saveContext 失败必须 rollback） |
| **草稿恢复** | 意外退出后可恢复（S0 级防护） |
| **删除安全** | 持久化五秒绝对撤销期限；后台 / 重启不缩短，期限后幂等硬删除 |
| **备份完整性** | 恢复前按 [Local Library Data Contract](local-library-data-contract.md) 冻结并验证 D3-B prestate；失败时零 active mutation |
| **完整操作隔离** | 只消费 [D4S-A complete-operation barrier](local-library-data-contract.md#43-complete-operation-与-mutation-barrierd4s-a)；partial export 不升级为完整资料库快照 |
| **崩溃率** | < 0.1%（Xcode Organizer / MetricKit / App Store Connect） |

## 同步与网络

> **占位**：当前 MVP 为端上处理 + 本地存储，无跨设备同步、无网络依赖。
> Apple 私有同步只是候选。新的 Product / Data / Privacy / Release Contract 生效时，再补同步延迟、冲突策略和离线降级 SLO；旧 #485 不构成重入授权。
