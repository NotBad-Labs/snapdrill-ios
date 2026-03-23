# API 易错点速查

> 修改代码前用 `Grep` / `Read` 确认 API 真实存在，禁止凭名称推测。
> 本文件只记录**实际踩过的坑**，不重复代码中能直接读到的信息。

## 常见错误防范

| 错误写法 | 正确写法 | 为什么错 |
|---|---|---|
| `repository.save(model)` | `repository.insertAndSave(model)` | 没有 save() 方法 |
| `repository.fetch(id:)` | `repository.fetchModel(by: id)` | 方法名不同 |
| `ReviewItemModel.save()` | 通过 Repository 保存 | @Model 没有 save() |
| `SM2State.update(...)` | `scheduler.scheduleNextReview()` 返回新值 | SM2State 是值类型，不原地修改 |
| `SnapDrillLogger.log("...")` | `SnapDrillLogger.generic.error("...")` | 没有 .log()，用子系统 |
| `ReviewDataNotification.post()` | `NotificationCenter.default.post(name: .reviewDataDidChange, object: nil)` | 没有静态 post() |
| `repository.insert()` 后以为已存盘 | 必须调 `saveContext()` 或用 `insertAndSave()` | insert() 只做内存操作 |
| `ImageStorage.loadImage()` 在 View 中用 | 用 `loadImageAsync()` 或 `loadDownsampledImage()` | loadImage() 是同步的，阻塞主线程 |
