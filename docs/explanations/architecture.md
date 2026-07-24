---
last_verified: 2026-07-24
layer: pattern
freshness:
  max_age_days: 90
  decay_trigger: [arch_change]
---
# SnapDrill 首发版目标架构

> “首发版”是仓库内部版本键 `Release 1` 的自然语言名称。本文定义其目标技术边界，
> 不描述或合法化旧实现。产品范围由
> [Product Constitution](vision.md) 与
> [Release 1 Product Contract](../reference/release-1-contract.md) 决定；本文只回答怎样实现。
> 当前代码与目标不一致时，按 Product Contract 的 M1-M10 结果 oracle 修复，不得反向修改产品目标。

## 1. 架构目标

首发版只有一条生产路径：

```text
SnapDrill.app
  └─ Composition Root
      ├─ LocalLibraryRuntime
      │   ├─ one active generation
      │   ├─ one ModelContainer + DataExecutor
      │   ├─ one RepositoryContainer
      │   └─ one generation-scoped ImageStorage
      ├─ ServiceContainer
      ├─ AppRouter
      └─ four public surfaces
          ├─ Dashboard
          ├─ Library
          ├─ Capture
          └─ Settings
```

必须成立：

1. 用户无需创建、选择或切换 Profile；生产代码中不存在第二个可用资料库。
2. App 根只创建一次 `LocalLibraryRuntime`，下游只消费同一 runtime 的 repository 与图片目录。
3. store 打不开时 fail closed，进入明确恢复流程；不得创建临时空库、静默隔离损坏 store 或回退测试替身。
4. Backup v3 是唯一对外完整备份 wire；development v1/v2 不参与生产读写。
5. Review、SmartPaper、Pro、CloudKit、Profile 和未纳入 manifest 的 optional 不进入首发候选构建
   （内部 audience：`public-candidate`）的运行图。
6. Core 保持零外部依赖，模块依赖保持单向向下。

## 2. 模块边界

```text
SnapDrill.app（Composition Root）
    │
    ├── SnapDrillFeatures（用户旅程与界面状态）
    │   ├── FeatureDashboard
    │   ├── FeatureLibrary
    │   ├── FeatureCapture
    │   └── FeatureSettings
    │
    ├── SnapDrillUI（无业务状态的公共 SwiftUI 组件与路由协议）
    │
    ├── SnapDrillData（资料库 runtime、SwiftData、repository、备份与恢复）
    │
    └── SnapDrillCore（稳定领域类型、服务协议、纯算法与日志）
```

依赖方向：

```text
App -> Features -> UI
App -> Features -> Data -> Core
UI -> Core
```

- `SnapDrillCore` 不依赖 Data、UI、Features 或第三方 SDK。
- `SnapDrillData` 拥有持久化、文件生命周期、完整操作和 Backup v3，不依赖 Feature。
- Feature 不直接持有 `ModelContext`，也不自行拼接资料库路径。
- App target 只做组合、生命周期和顶层路由，不承载业务规则。
- package 边界用于编译和所有权隔离，不为单一实现制造 pass-through protocol。
- 研究 / 可选模块可以保留为不可达源码或测试资产，但不得链接进首发候选运行图、启动任务或用户表面。

## 3. Runtime 与组合

### 3.1 唯一 runtime

`LocalLibraryRuntime` 是生产资料库的唯一 owner。它在成功打开 active generation 后一次性发布：

- `ModelContainer`
- actor-owned `DataExecutor`
- `RepositoryContainer`
- generation-scoped `ImageStorage`
- complete-operation coordinator
- 当前 generation identity

初始化必须 all-or-nothing。任一成员构造失败时不发布部分 runtime，不注入空 repository，不进入正常
Dashboard。

### 3.2 Composition Root

`SnapDrillApp` 负责：

1. 读取并校验 selector、transaction、incident 与 generation 布局。
2. 打开或创建唯一 active generation。
3. 构造 `LocalLibraryRuntime` 与稳定 service。
4. 根据启动结果呈现 normal shell 或 recovery shell。
5. 将显式依赖注入 AppRootView。

禁止：

- `ProfileManager`、`ProfileVault` 或 `activeProfile` 参与正常启动。
- EnvironmentKey 生产默认值创建内存 store 或 mock service。
- View、ViewModel 或 Settings 再次创建 runtime / repository / image storage。
- “先显示空库，再异步尝试恢复”的假成功路径。

### 3.3 启动状态

```text
preparing
  ├─ ready(LocalLibraryRuntime) -> public app shell
  ├─ recoveryRequired(incident) -> recovery shell
  └─ failed(stable error)       -> retry / restore / informed reset
```

`ready` 是进入正常 UI 的唯一入口。恢复语义、generation 与稳定错误类别由
[Local Library Data Contract](../reference/local-library-data-contract.md) 唯一拥有。

## 4. 数据与文件边界

### 4.1 数据流

```text
View
  -> View state / workflow owner
  -> RepositoryContainer
  -> DataExecutor actor
  -> SwiftData models
```

- View 只呈现状态并发出意图。
- 简单短流程可由 View 的 `@State` 与注入服务承担；跨步骤写操作、错误恢复和通知监听使用明确 workflow owner。
- Repository 负责持久化规则；写失败必须 rollback，不向上报告成功。
- `Notification.Name.reviewDataDidChange` 等历史广播不能成为首发版核心一致性的唯一机制；核心写入完成后由明确依赖刷新。

### 4.2 图片真相

- 保存真相是用户确认裁剪和方向后的 App-managed canonical JPEG。
- `ImageStorage` 只接收 generation 根目录，不接收 Profile scope。
- 图片保存剥离 EXIF GPS；读取、删除与恢复全部校验安全相对路径。
- 数据行与必需图片必须按 owning contract 原子提交；不可读主图不得报告成功。

### 4.3 完整操作

完整备份、恢复和清空资料库消费同一个 complete-operation barrier：

1. 关闭新的 mutation / snapshot admission。
2. 等待已准入操作收敛。
3. 固定可验证 prestate。
4. 在隔离工作区执行。
5. 原子发布结果或完整回滚。

selected PDF / CSV 是 partial export，只消费稳定选择快照，不冒充完整资料库备份。

### 4.4 Backup v3

[Backup Wire Format](../reference/backup-wire-format.md) 是对外 wire 的唯一 owner：

- writer 与 reader 必须 round-trip 同一 exact contract。
- 逐 entry 与总量按实际提取字节限制。
- 路径、ID、引用闭包、canonical image 与 taxonomy 先验证，后 mutation。
- 恢复失败保留原库与可诊断 incident；不得 salvage 后静默报告完整成功。
- v1/v2 只允许保留最小拒绝 fixture 或历史解析证据，不进入生产入口。

## 5. Service 与 DI

跨 Feature、持有状态、依赖系统 API 或测试需要替换的稳定能力进入 `ServiceContainer`。新增服务必须同时满足：

1. 至少两个真实消费者，或位于外部系统边界。
2. 接口比实现更稳定，且能形成可验证 contract。
3. 不只是对单个 concrete type 的透传。

Profile-scoped service 分类被目标架构删除。资料库相关能力归 `LocalLibraryRuntime`；通用系统能力归
`ServiceContainer`。允许的静态 facade 必须无持久业务状态并有明确理由。

## 6. 用户表面与 Feature 边界

| 表面 | 目标职责 | 不得拥有 |
|---|---|---|
| Dashboard | 默认首屏、资料库状态、Capture / Library 快速入口 | Profile、Review cue、Pro、课程或学习统计 |
| Capture | 相机 / 文扫、相册、PDF、OCR 辅助、草稿与保存 | 独立 store、教育领域字段、保存后第二份图片真相 |
| Library | 搜索、查看、编辑、分类 / 标签、选择、撤销删除 | 多资料空间、SmartPaper 主入口、按 Review 状态驱动 |
| Settings | 语言、外观、备份 / 恢复、清库、隐私与法律 | 身份装饰、Profile、Review 设置、Pro / CloudKit 预告 |

Feature 可以复用 Data/Core contract，但不能把当前实现存在的能力升级为产品范围。

## 7. 测试架构

测试 oracle 必须来自 Product Contract、owning feature / Data contract 或 NFR，不从现有实现倒推。

| 层级 | 证明内容 |
|---|---|
| Core unit | 纯规则、路径 grammar、限制值、错误分类 |
| Data contract | generation、事务、incident、repository、图片、Backup v3 原子性 |
| Composition integration | App 根只发布一个 runtime；正常、损坏、恢复与重置路径无 fallback |
| Feature integration | M1-M9 的输入、状态、错误与输出结果 |
| UI / AX | M10、中英文、Dynamic Type、VoiceOver、viewport 与系统面板入口 |
| Device evidence | 相机 / 文扫、签名安装启动、真实打印及物理输出 |

保留旧实现的测试只能证明 legacy 行为，不能计入首发版完成度。删除 legacy production path 时，
与该路径绑定且无安全 / wire 价值的测试一并删除；拒绝旧 wire、迁移边界或回归攻击样本可保留为
quarantine fixture。
