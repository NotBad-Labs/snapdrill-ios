# SnapDrill 组件审计清单

> 审计策略：自底向上，按依赖方向遍历。每个文件只出现一次。
>
> 总计：**131 个 Swift 源文件**，分 6 个 Phase、25 个批次。
>
> 最后更新：2026-03-25

---

## Phase 1: SnapDrillCore（31 文件）

### Batch 01 — Support（基础设施）

- [x] `SnapDrillLogger.swift` — PASS (1 S3: 多余 @available)
- [x] `Support/SnapDrillError.swift` — PASS
- [x] `Support/AppConfiguration.swift` — PASS (TD-2 已知)
- [x] `Support/UserDefaultsKeys.swift` — PASS
- [x] `Support/ReviewDataNotification.swift` — PASS
- [x] `Support/LocalizationKeys.swift` — PASS

### Batch 02 — Utils（纯工具）

- [x] `Utils/Collection+Safe.swift` — PASS
- [x] `Utils/Color+Hex.swift` — PASS (1 S3: 多余 @available)
- [x] `Utils/Date+Extensions.swift` — PASS

### Batch 03 — Engine（SM-2 复习算法）

- [x] `Engine/SM2State.swift` — PASS
- [x] `Engine/ReviewScheduler.swift` — PASS
- [x] `Engine/ReviewRating.swift` — PASS

### Batch 04 — Model（值类型）

- [x] `Model/Difficulty.swift` — PASS

### Batch 05 — Service Protocols（契约定义）

- [x] `Service/AnalyticsServiceProtocol.swift` — PASS
- [x] `Service/AnalyticsService+Environment.swift` — PASS
- [x] `Service/NotificationServiceProtocol.swift` — PASS
- [x] `Service/CaptureDraftServiceProtocol.swift` — PASS
- [x] `Service/OCRServiceProtocol.swift` — PASS
- [x] `Service/PDFExportable.swift` — PASS

### Batch 06 — Service Implementations（实现层）

- [x] `Service/CaptureDraftService.swift` — PASS (TD-2 已知)
- [x] `Service/LiveNotificationService.swift` — PASS
- [x] `Service/PDFExportService.swift` — PASS (1 S3: chunked 可见性)
- [x] `Service/PrivacyConsentService.swift` — PASS (2 S3: Logger+emoji)
- [x] `Capture/OCRService.swift` — PASS
- [x] `Capture/ImageStorage.swift` — PASS

### Batch 07 — Service Mocks（测试替身）

- [x] `Service/AnalyticsServiceMock.swift` — PASS
- [x] `Service/NotificationServiceMock.swift` — PASS

### Batch 08 — DI（依赖注入容器）

- [x] `DI/ServiceContainer.swift` — PASS
- [x] `DI/LiveServiceContainer.swift` — PASS
- [x] `DI/MockServiceContainer.swift` — PASS
- [x] `DI/ServiceContainer+Environment.swift` — PASS

---

## Phase 2: SnapDrillData（20 文件）

### Batch 09 — @Model 实体（SwiftData Schema）

- [x] `ReviewItemModel.swift` — PASS
- [x] `SubjectModel.swift` — PASS
- [x] `TagModel.swift` — PASS
- [x] `SourceModel.swift` — PASS
- [x] `GradeModel.swift` — PASS

### Batch 10 — Persistence（容器与迁移）

- [x] `Persistence.swift` — PASS (TD-2, 1 S3 emoji)
- [x] `MigrationPlan.swift` — PASS
- [x] `DataSeeder.swift` — PASS

### Batch 11 — Error Types

- [x] `DataError.swift` — PASS
- [x] `PersistenceError.swift` — PASS

### Batch 12 — Repositories（CRUD 逻辑）

- [x] `ReviewRepository.swift` — PASS
- [x] `SubjectRepository.swift` — PASS
- [x] `TagRepository.swift` — PASS
- [x] `SourceRepository.swift` — PASS
- [x] `GradeRepository.swift` — PASS

### Batch 13 — DI（Repository 容器）

- [x] `RepositoryContainer.swift` — PASS
- [x] `RepositoryContainer+Environment.swift` — PASS

### Batch 14 — DTOs & Backup（数据边界）

- [x] `ReviewExportSnapshot.swift` — PASS
- [x] `BackupDTO.swift` — PASS
- [x] `BackupService.swift` — PASS

---

## Phase 3: SnapDrillUI（12 文件）

### Batch 15 — Navigation

- [x] `Navigation.swift` — PASS
- [x] `Navigation/TabItem.swift` — PASS

### Batch 16 — 通用组件

- [x] `SnapDrillButton.swift` — PASS
- [x] `ErrorMessageView.swift` — PASS
- [x] `ContextualErrorView.swift` — PASS
- [x] `FlipView.swift` — PASS
- [x] `TagInputView.swift` — PASS (1 S3: 硬编码无障碍标签)
- [x] `ImageCropperView.swift` — PASS
- [x] `ProgressLoadingView.swift` — PASS

### Batch 17 — Onboarding & Privacy

- [x] `OnboardingView.swift` — PASS (TD-2)
- [x] `Privacy/PrivacyPrePromptView.swift` — PASS

### Batch 18 — Accessibility

- [x] `AccessibilityExtensions.swift` — PASS

---

## Phase 4: SnapDrillInfrastructure（3 文件）

### Batch 19 — Firebase

- [x] `FirebaseBootstrap.swift` — PASS
- [x] `FirebaseAnalyticsService.swift` — PASS (TD-2)
- [x] `FirebaseRemoteConfigService.swift` — PASS (1 S3: 多余 @available)

---

## Phase 5: SnapDrillFeatures（61 文件）

### Batch 20 — Capture（拍照录入，10 文件）

- [x] `CaptureRouter.swift` — PASS
- [x] `CaptureViewModel.swift` — PASS
- [x] `CaptureView.swift` — PASS
- [x] `SmartCameraView.swift` — PASS
- [x] `SmartCameraViewController.swift` — PASS
- [x] `DocumentScannerView.swift` — PASS
- [x] `PDFPagePickerView.swift` — PASS
- [x] `CornerBracketShape.swift` — PASS
- [x] `CaptureResultViewModel.swift` — PASS
- [x] `CaptureResultView.swift` — PASS

### Batch 21 — Library（题库管理，20 文件）

- [x] `LibraryRouter.swift` — PASS
- [x] `LibraryViewModel.swift` — PASS
- [x] `LibraryView.swift` — PASS
- [x] `LibraryListView.swift` — PASS
- [x] `LibraryComponents.swift` — PASS
- [x] `LibraryDetailView.swift` — PASS
- [x] `LibraryEditViewModel.swift` — PASS
- [x] `LibraryEditView.swift` — PASS
- [x] `LibraryFilterSheet.swift` — PASS
- [x] `FullScreenImageView.swift` — PASS
- [x] `SubjectManagerViewModel.swift` — PASS
- [x] `SubjectManagerView.swift` — PASS
- [x] `SourceManagerViewModel.swift` — PASS
- [x] `SourceManagerView.swift` — PASS
- [x] `GradeManagerViewModel.swift` — PASS
- [x] `GradeManagerView.swift` — PASS
- [x] `SFSymbolPickerView.swift` — PASS
- [x] `ExportOptionsSheet.swift` — PASS
- [x] `ExportPreviewView.swift` — PASS
- [x] `ResolvedExportSheet.swift` — PASS

### Batch 22 — Review（复习，11 文件）

- [x] `ReviewRouter.swift` — PASS
- [x] `ReviewViewModel.swift` — PASS
- [x] `ReviewView.swift` — PASS
- [x] `ReviewDashboardView.swift` — PASS
- [x] `ReviewProgressHeader.swift` — PASS
- [x] `ReviewEmptyStateView.swift` — PASS
- [x] `SwipeCard.swift` — PASS
- [x] `ReviewCardContent.swift` — PASS (Preview force-try, acceptable)
- [x] `ReviewCardFactory.swift` — PASS
- [x] `ReviewActionButtons.swift` — PASS
- [x] `ReviewSessionSummaryView.swift` — PASS

### Batch 23 — Dashboard（首页，6 文件）

- [x] `DashboardRouter.swift` — PASS
- [x] `DashboardViewModel.swift` — PASS
- [x] `DashboardView.swift` — PASS
- [x] `HeaderView.swift` — **S0: 同步 loadImage() 阻塞主线程**
- [x] `ReviewHeroCard.swift` — PASS
- [x] `BentoCard.swift` — PASS

### Batch 24 — Settings（设置，14 文件）

- [x] `SettingsRouter.swift` — PASS
- [x] `SettingsViewModel.swift` — PASS
- [x] `SettingsView.swift` — PASS
- [x] `SettingsRow.swift` — PASS
- [x] `EditProfileView.swift` — PASS (1 S2: logger level)
- [x] `PrivacySettingsView.swift` — PASS
- [x] `DataAndSyncSettingsView.swift` — PASS (1 S2: logger level)
- [x] `NotificationSettingsViewModel.swift` — PASS
- [x] `NotificationSettingsView.swift` — PASS
- [x] `LanguageSettingsView.swift` — PASS
- [x] `ReviewAppearanceSettingsView.swift` — PASS
- [x] `PrivacyPolicyView.swift` — PASS
- [x] `TermsOfServiceView.swift` — PASS
- [x] `LicenseView.swift` — PASS

---

## Phase 6: App（4 文件）

### Batch 25 — App Shell

- [x] `SnapDrillApp.swift` — PASS
- [x] `AppRootView.swift` — PASS (1 S3: singleton 直接访问)
- [x] `AppRouter.swift` — PASS (1 S2: try? 缺注释)
- [x] `Composition/DependencyContainer.swift` — PASS (1 S2: remoteConfig try?)

---

## 审计进度

| Phase | 范围 | 文件数 | 完成 |
|-------|------|--------|------|
| 1 | SnapDrillCore | 31 | **31/31** |
| 2 | SnapDrillData | 20 | **20/20** |
| 3 | SnapDrillUI | 12 | **12/12** |
| 4 | SnapDrillInfrastructure | 3 | **3/3** |
| 5 | SnapDrillFeatures | 61 | **61/61** |
| 6 | App | 4 | **4/4** |
| **Total** | | **131** | **131/131** |
