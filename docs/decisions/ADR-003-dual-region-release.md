---
last_verified: 2026-07-12
layer: decision
current_status: suspended
historical_record: true
current_authority: docs/explanations/positioning-and-audience.md
freshness:
  max_age_days: 365
  decay_trigger: [decision_reverted, dual_region_launch]
---
# ADR-003: 双账号双地区发布架构

> 状态：**已挂起（历史区域发布路线，非当前生产架构）** | 原决策日期：2026-05-28 | 挂起决策：2026-06-09 | 决策者：PO
>
> **🔁 状态更新 2026-06-09（PO 决策）**：**暂时挂起（非删除）国内大陆路线**，改用**美国公司账号 NotBad Labs L.L.C.（Team `J58U72W335`，Organization）做全球版生产**。工程已迁移到 `com.snapdrill.global` + 美国 Team，签名、真机安装运行与 TestFlight / App Store distribution signing 实证状态以根 `README.md` / `AGENTS.md` 为准。本 ADR 的“国内 first / 先用个人账号验 PMF”前提已被取代；下文整体保留为**历史区域发布路线 + 未来国内路线复活蓝图**，**不代表当前生产架构**。当前生产事实见根 `README.md` / `AGENTS.md`，分析与隐私现行决策见 [[ADR-005]]。下文出现的“国内版无 Firebase / 海外版 Firebase”“儿童隐私横切主线”等表述均为该挂起路线的历史决策内容，不是当前定位（当前为通用受众效率工具，见 `../explanations/positioning-and-audience.md`）。
>
> **2026-07-12 B7-A 确认**：Release 1 只维护美国主体的 iPhone 全球版，产品语言为英文与简体中文。中国大陆专项发行与 iPad 均须新的明确重入决策；保留本 ADR 和挂起资源不代表 roadmap 承诺。

## 背景

SnapDrill 是**一个产品**，计划两区域发布：
- 中国大陆 — 中文名"小本本-智能错题本"
- 海外 — 英文名"SnapDrill"

**辨析**：这不是 TikTok/抖音的"两个独立产品"关系，而是"一个产品 + 两区域发行版"（类似 WeChat/Weixin，但更轻 —— 单人 + AI 团队无法负担两套独立基础设施）。

账号现状：
- 中国大陆：个人 Apple Developer 账号（YIMING LIAO，Team `W5A8THDKW8`），已 active
- 美国：NotBad Labs L.L.C.（有 D-U-N-S，Apple Developer 待注册）
- 公司官网：`notbadhq.com`（SnapDrill 子页面未做）

## 决策

### C 路径：同代码双发行版

| 维度 | 国内版 | 海外版（未来）|
|---|---|---|
| Bundle ID | `com.snapdrill.app` | `com.snapdrill.global`（待定；`com.notbadhq.snapdrill` 已被国内 Team 占用）|
| Team | 个人 `W5A8THDKW8` | 美国 NotBad Labs 公司 |
| App 名 | 小本本-智能错题本 | SnapDrill |
| Analytics | 无 Firebase（Apple Crash + 端上）| Firebase |
| iCloud Container | `iCloud.com.snapdrill.app` | `iCloud.com.snapdrill.global` |

### 官网：子目录而非子域名

`notbadhq.com/snapdrill`（子目录），不用 `snapdrill.notbadhq.com`（子域名），不用 ccTLD。
- 依据：Nike 用子目录；行业共识"子域名对小团队是 overkill"；单人维护子目录最省
- 反例辨析：Apple `.com.cn` / WeChat-Weixin 两套基础设施都是巨头资源奢侈，非正确性标杆

### 隐私政策：统一框架 + 区域附录

参考 Apple 模式：一份主体 + 中国大陆（PIPL）附录 + 海外（CCPA/GDPR）附录。维护一份文档，按区域合规。

### 区域差异 = build / 运行时 / 文档分层，不是仓库分裂（2026-05-29 澄清）

隐私法律差异在**运行时行为 + 法律文档**层解决，**不分多仓库**（多仓库违背本 ADR"一套代码"原则，单人 + AI 团队 3× 维护不可持续；曾考虑"CN/EU/加州 三仓库"，已否决）。

- **分发 = 2 个 build**：国内版（唯一有硬技术理由 fork —— Google 服务不可达 + 数据本地化）/ 海外 Global（美 + 欧 + 英 + 其余全球**一个 build**，靠区域检测 + 同意流 + 隐私政策区域附录覆盖 GDPR / CCPA / CPRA / 各州法 / UK-GDPR / LGPD…）。
- **"加州 build"不成立**：美国是一个 App Store storefront，受联邦 COPPA + 多州法（CA/VA/CO/CT/UT/TX…）约束，不按州分包。
- **横切主线 = 儿童隐私**（COPPA / GDPR-K 16 岁以下 / UK 年龄适配设计准则 / PIPL 未成年人特殊规则）：本 app 存孩子练习题，此条跨所有区域，比 CCPA-vs-GDPR 更关键，是真正要设计的合规主线。

## 后果

### 不可逆资源（已 Dev Portal 锁定，PMF 验证前勿改）

- Bundle ID `com.snapdrill.app`（5 年锁定国内 Team，跨 Team 不可转移）
- iCloud Container `iCloud.com.snapdrill.app`
- App Group `group.com.snapdrill.app`

### 大公司对照

| 借鉴对象 | 学 | 不学 |
|---|---|---|
| WeChat/Weixin | 同产品双名双区域框架 | 两套独立基础设施（我们一套代码）|
| Apple | 隐私统一框架 + 区域合规节 | `.com.cn` ccTLD + GCBD 数据中心 |
| Nike | 子目录而非子域名 | — |

### C 路径工程量（PMF 验证成功后启动）

约 1 周：拆 `CN.xcconfig` / `Global.xcconfig` + Build Configuration（Release-CN / Release-Global）+ `AnalyticsServiceProtocol` 分流（`NoOpAnalyticsService` vs Firebase）+ ASC 双 App + Privacy Manifest 双版本。

### 3 个盲点

1. **中国大陆访问可达性**：`notbadhq.com` 海外服务器 → Apple 中国审核员可达性需实测
2. **ICP 备案**：`notbadhq.com` 美国域名不能 ICP 备案 → 只能走海外服务器路线
3. **隐私政策合规分歧**：PIPL 数据本地化 ≠ CCPA/GDPR，需分区域合规（不是一份翻译）

### 当前阶段

美国公司全球版 `com.snapdrill.global` 是当前生产与 TestFlight 基线；国内账号与标识符仅保留，不参与当前构建。
