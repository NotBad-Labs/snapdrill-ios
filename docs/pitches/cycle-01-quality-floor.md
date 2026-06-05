# Pitch · Cycle 1：核心闭环 dogfood 到质量地板 + TestFlight 就绪

> 状态：**已 shape，已 bet（进行中）** · 模式：Production/Cleanup · 开始：2026-06-05
> 格式遵循 Shape Up Ch.6（Problem / Appetite / Solution / Rabbit holes / No-gos）。

## ① Problem（一个具体故事）

我有一个 ~90% 完成、能跑的核心闭环（拍照→OCR→多维管理→导出打印），但**零用户、零真实信号**——我从没让一个真实家长用过，也没自己密集 dogfood 过。这种不确定下，无论"加功能"还是"推倒重写"都是在猜。
当前版本 `1.1.0 (6)`，PrivacyInfo 就位，CI 绿（含 7 个 XCUITest 真机通过），启动崩溃已修。**离 TestFlight 差的不是合规**（ADR-004：内测不被 RC 队列阻塞），**是"我还没把它当真用过、不知道哪里坏/哪里像模像样"。**

## ② Appetite（时间预算，不是估算）

**2–3 周。到期不延期**（circuit breaker）。塞不进就砍 scope，不加时间。

## ③ Solution（核心元素）

把现有核心闭环打磨到**质量地板**（不崩 / 核心路径可靠 / 像模像样 / EXIF·隐私扎实）+ **TestFlight 可分发**，并埋一个**最小、隐私安全（本地·零出境）的学习探针**。**不加任何新功能。**

### Scopes（按产品结构竖切 · 你的"步骤"在这）

| Scope | 内容 | 谁主 | hill |
|---|---|---|---|
| **S1 · 主路径 dogfood** | 你密集走一遍：拍照/扫描/导入 → OCR → 编辑/分类 → 筛选 → 导出 PDF/CSV → 打印。**记下每一处卡顿/迷惑/丑/坏**。 | **你**（dogfood 是你的活） | uphill |
| **S2 · 稳定性 pass** | 修 S1 暴露的崩溃/错误；核心路径零强解包复查；空态/错误态不白屏。 | 你+AI | uphill |
| **S3 · 像模像样 pass** | 核心路径的文案/空态/加载态/图标到"不丢人"；非核心边角**不碰**。 | 你判断 + AI 改 | uphill |
| **S4 · 学习探针** | 最小埋点：①关键动作完成（录入一题/导出一次）②一个反馈入口。**必须本地·零出境**（隐私铁律），不接 Firebase。 | 你定义信号 + AI 实现 | uphill |
| **S5 · TF 分发管线** | Archive → 上传 App Store Connect → 内测组 → 自测安装跑通。版本/签名（个人账号 `W5A8THDKW8` 已 active）。 | 你（ASC 点击）+ AI 指南 | uphill |

> **第 1 周内必须有一个端到端可点 slice**（原书 Ch.11）：建议 = S5 先打通"能 archive + 装到你自己手机/TestFlight"，再回头填 S1–S4。这样"能发布"这块风险最早下山。

## ④ Rabbit holes（提前标的坑）

- **S4 埋点别违反隐私铁律**：本地/零出境，绝不接 Firebase（国内版 Firebase-Free，ADR-004）。
- **TF 分发**：个人账号内测无账号阻塞，但首次 archive 签名/Provisioning 可能卡——AI 给逐步指南，卡了贴报错。
- **dogfood 易滑成"重写冲动"**：发现 jank ≠ 代码烂（代码价值评估已证 17/17 KEEP）。修 jank，别重写。
- **崩溃监控**：公开上架要 MetricKit（RC-4），但**内测先不做**，靠 dogfood + Xcode Organizer 崩溃日志即可。

## ⑤ No-gos（明确不做）

- ❌ 不重写、不删能跑的代码、不优化架构。
- ❌ 不加新功能；不碰复习/SM-2、SmartPaper、Pro、订阅。
- ❌ 不做公开商店上架、不碰 RC-1~12 合规队列（延后）。
- ❌ 不邀真实家长（那是 **Cycle 2**：过了质量地板再邀 + 收 PMF 信号）。
- ❌ 不接 MetricKit / Firebase / 任何出境埋点。

---

## 学习目标（PMF 前不可省）

本 bet 成功 = 不只"能发 TF"，而是**你密集 dogfood 后，对两件事有了第一手判断**：(a) 核心闭环哪里真坏/真糙（→修）；(b) **哪些功能你自己真会点、哪些从不开**（→喂给下一轮 betting，决定 Parked 清单要不要动）。这条把"做错产品"的风险，绑进了 Shape Up 的交付循环。

## Hill chart（AI 每 2-3 天更新）

```
S1 dogfood     ●uphill  （等你跑一遍核心路径，记 jank）
S2 稳定性      ●uphill
S3 像模像样    ●uphill
S4 学习探针    ●uphill
S5 TF 分发     ●uphill  （建议先打通，最早下山）
```
