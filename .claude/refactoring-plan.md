# SnapDrill 重构计划（已完结）

**状态：全部阶段已完成，2026-03-03 commit `aa5e1de`**

## 完成的阶段

| 阶段 | 内容 | 状态 |
|---|---|---|
| Phase 1 | 迁移 Core 内容（SM2State、ReviewScheduler、Difficulty、ReviewDataNotification）| ✅ |
| Phase 4 | Repository 层去协议化 | ✅ |
| Phase 3+5 | 删除 UseCase 层，Features ViewModel 直接用 Repository | ✅ |
| Phase 2 | 新建 ReviewExportSnapshot，删除 toEntity() 映射层 | ✅ |
| Phase 6 | 删除 SnapDrillDomain 整包，更新 pbxproj | ✅ |

## 最终架构

```
SnapDrillFeatures ──► SnapDrillData ──► SnapDrillCore (0 deps)
        │                                      ▲
        └──────────► SnapDrillUI ──────────────┘
```

详见 `.claude/architecture.md`。

## 后续注意事项

- 禁止新增 Domain 层、UseCase 层、Repository 协议（已证明不需要）
- 禁止新增 Domain struct + toEntity() 映射（@Model 直接作领域对象）
- 新功能参考现有 ViewModel 直接注入 Repository 的模式
