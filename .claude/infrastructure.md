# API 易错点速查

> 修改代码前用 `Grep` / `Read` 确认 API 真实存在，禁止凭名称推测。
> 本文件只记录**实际踩过的坑**，不重复代码中能直接读到的信息。

## 常见错误防范

| 错误写法 | 正确写法 | 为什么错 |
|---|---|---|
| `repository.save(model)` | `repository.insertAndSave(model)` | 没有 save() 方法 |
| `repository.fetch(id:)` | `reviewRepository.fetchModel(by: id)`；其他 Repository 用 `fetchModel(byName:)` | 方法名不同，且各 Repository 签名不同 |
| `ReviewItemModel.save()` | 通过 Repository 保存 | @Model 没有 save() |
| `SM2State.update(...)` | `scheduler.scheduleNextReview()` 返回新值 | SM2State 是值类型，不原地修改 |
| `SnapDrillLogger.log("...")` | `SnapDrillLogger.generic.error("...")` | 没有 .log()，用子系统 |
| `ReviewDataNotification.post()` | `NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)` | 没有静态 post() |
| `repository.insert()` 后以为已存盘 | 必须调 `saveContext()` 或用 `insertAndSave()` | insert() 只做内存操作 |
| `saveContext()` 失败后继续操作 | 失败后调 `rollbackContext()` 回滚（目前仅 ReviewRepository 实现） | 不回滚则内存脏状态污染后续写入（S0） |
| `ImageStorage.loadImage()` 在 View 中用 | 用 `loadImageAsync()` 或 `loadDownsampledImage()` | loadImage() 是同步的，阻塞主线程 |
| PDF 批量渲染不加 autoreleasepool | `for chunk in items { try autoreleasepool { ... } }` | 批量图片渲染会 OOM |

## SwiftData 陷阱（防崩溃）

| 陷阱 | 后果 | 正确做法 |
|---|---|---|
| ModelContainer 作局部变量 | `x0 = nil, brk #1` 崩溃（ModelContext 弱引用 container） | container 必须作为实例属性保活 |
| `#Predicate` 中写 many-to-many 过滤 | 编译通过但运行崩溃 | fetch 全量后内存端过滤（TD-1） |
| macOS `swift test` 跑 #Predicate 测试 | SIGTRAP 崩溃 | 必须通过 Xcode iOS Simulator 运行 |
| 新增 @Model 字段不加默认值 | 迁移失败 | 字段带默认值 + 新建 Schema 版本 + MigrationStage |
