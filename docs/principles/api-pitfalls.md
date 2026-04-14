<!-- last_verified: 2026-04-14 -->
<!-- layer: snapshot -->
<!-- freshness: max_age_days=60, decay_trigger=[code_change] -->
# API 易错点速查

> 修改代码前用 `Grep` / `Read` 确认 API 真实存在，禁止凭名称推测。
> 本文件只记录实际踩过的坑。

## 常见错误防范

| 错误写法 | 正确写法 | 为什么错 |
|---|---|---|
| `repository.save(model)` | `repository.insertAndSave(model)` | 没有 save() 方法 |
| `repository.fetch(id:)` | `reviewRepository.fetchModel(by: id)`；其他 Repository 用 `fetchModel(byName:)` | 方法名不同 |
| `ReviewItemModel.save()` | 通过 Repository 保存 | @Model 没有 save() |
| `SM2State.update(...)` | `scheduler.scheduleNextReview()` 返回新值 | SM2State 是值类型 |
| `SnapDrillLogger.log("...")` | `SnapDrillLogger.generic.error("...")` | 没有 .log()，用子系统 |
| `ReviewDataNotification.post()` | `NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)` | 没有静态 post() |
| `repository.insert()` 后以为已存盘 | 必须调 `saveContext()` 或用 `insertAndSave()` | insert() 只做内存操作 |
| `saveContext()` 失败后继续操作 | 失败后调 `rollbackContext()` 回滚 | 内存脏状态污染后续写入 |
| `ImageStorage.loadImage()` 在 View 中用 | 用 `loadImageAsync()` 或 `loadDownsampledImage()` | loadImage() 同步阻塞主线程 |
| PDF 批量渲染不加 autoreleasepool | `for chunk in items { try autoreleasepool { ... } }` | 批量图片渲染会 OOM |

## defaultIsolation 陷阱

| 陷阱 | 后果 | 正确做法 |
|---|---|---|
| 纯数据 struct 未标 `nonisolated` | 跨 actor 边界编译失败 | DTO/Snapshot/L10n 等标 `nonisolated` |
| `Sendable` 类有可变状态但无显式 `@MainActor` | "mutable stored property" 编译错误 | 此类保留显式 `@MainActor` |
| `static let` Logger 常量未标 `nonisolated` | nonisolated 上下文无法访问 | 用 `nonisolated`（Logger 是 Sendable，不需要 unsafe） |
| AVFoundation 回调属性默认 MainActor | nonisolated delegate 无法读取 | 用 `nonisolated(unsafe)` |
| `Task {}` 内直接访问 `@Environment`/computed property | clean build 不报，IDE 增量编译黄色警告 | 进入 Task 前 `let local = prop` 捕获（类型须 Sendable） |

## SwiftData 陷阱

| 陷阱 | 后果 | 正确做法 |
|---|---|---|
| ModelContainer 作局部变量 | 崩溃 | container 必须作为实例属性保活 |
| `#Predicate` 中写 many-to-many 过滤 | 运行崩溃 | fetch 全量后内存端过滤 |
| macOS `swift test` 跑 #Predicate 测试 | SIGTRAP | 必须通过 Xcode iOS Simulator 运行 |
| 新增 @Model 字段不加默认值 | 迁移失败 | 字段带默认值 + 新建 Schema 版本 |
| `#Unique<Model>([\.field])` + CloudKit entitlement | 真机 fatalError（Simulator 不崩） | **禁止使用 `#Unique`**（PR #454 已全量删除）— 在 Repository 层用 `fetchOrCreateModel` + `DataError.duplicateName` 保证业务唯一性 |

## 删除撤销陷阱

| 陷阱 | 后果 | 正确做法 |
|---|---|---|
| Toast 倒计时 Task 未在 View 消失时取消 | 内存泄漏或对已释放对象操作 | 在 `.onDisappear` 中取消 Task，或将 Task 句柄保存为实例属性 |
| 软删除后立即查询未排除待删除项 | 已标记删除的题目仍出现在列表中 | 当前实现为 ViewModel 级 5 秒待提交删除（非模型级 isDeleted 字段），从列表临时移除后延时执行真实删除 |

## 多 Profile 陷阱

| 陷阱 | 后果 | 正确做法 |
|---|---|---|
| Profile 切换后 ViewModel 持有旧 Profile 的数据 | 显示错误 Profile 的题目 | 切换 Profile 时重建 ViewModel 或刷新数据源 |
