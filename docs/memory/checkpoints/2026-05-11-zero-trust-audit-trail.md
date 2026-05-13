---
last_verified: 2026-05-12
layer: snapshot
---
# 2026-05-11 Zero Trust Audit Trail

## Audit Scope

| Scope | Command / operation | Actual result | Status |
|---|---|---:|---|
| Full STATUS.md read | `nl -ba STATUS.md` | 230 numbered lines read, including YAML frontmatter, tables, blockquotes, separators | Complete |
| Swift inventory, corrected | `find . -name '*.swift' -not -path './.build/*' -not -path '*/.build/*' -not -path './DerivedData/*' \| sort \| wc -l` | 231 | Complete |
| docs Markdown inventory | `find docs -name '*.md' \| sort \| wc -l` | 73 | Complete |
| Hidden governance inventory | `find .claude .github .agent-harness -type f \| sort \| wc -l` | 52 | Complete |
| Corrected in-scope file total | `231 + 73 + 52` | 356 | Complete |

Corrected scoped source/governance total from requested buckets: 231 Swift + 73 docs Markdown + 52 hidden governance files = **356 files**. `STATUS.md` remains separately listed in the File Coverage Ledger as the already-read claim source and is not included in that corrected bucket total.

## File Coverage Ledger

| # | 文件路径 | 行数 | 状态 | 阅读日期 | 备注 |
|---:|---|---:|---|---|---|
| 1 | `STATUS.md` | 230 | READ_VERIFIED | 2026-05-11 | Claim source read with `nl -ba STATUS.md`; outside corrected find buckets. |
| 2 | `./Packages/SnapDrillCore/Package.swift` | 40 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 3 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Capture/ImageStorage.swift` | 274 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 4 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Capture/OCRService.swift` | 96 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 5 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/DI/LiveServiceContainer.swift` | 46 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 6 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/DI/MockServiceContainer.swift` | 39 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 7 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/DI/ServiceContainer+Environment.swift` | 41 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 8 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/DI/ServiceContainer.swift` | 53 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 9 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Engine/ReviewRating.swift` | 25 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 10 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Engine/ReviewScheduler.swift` | 114 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 11 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Engine/SM2State.swift` | 55 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 12 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Model/Difficulty.swift` | 29 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 13 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Model/Profile.swift` | 42 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 14 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/AnalyticsService+Environment.swift` | 31 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 15 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/AnalyticsServiceMock.swift` | 74 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 16 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/AnalyticsServiceProtocol.swift` | 61 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 17 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/CaptureDraftService.swift` | 155 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 18 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/CaptureDraftServiceProtocol.swift` | 31 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 19 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/ContentTaggingService.swift` | 108 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 20 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/DeletionScheduler.swift` | 118 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 21 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/LiveNotificationService.swift` | 68 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 22 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/NotificationServiceMock.swift` | 68 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 23 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/NotificationServiceProtocol.swift` | 33 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 24 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/OCRServiceProtocol.swift` | 73 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 25 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PDFExportOptions.swift` | 45 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 26 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PDFExportService.swift` | 382 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 27 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PDFExportable.swift` | 43 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 28 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/PrivacyConsentService.swift` | 31 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 29 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Service/QuestionSplittingService.swift` | 131 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 30 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/SnapDrillLogger.swift` | 36 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 31 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/AppActivityTracker.swift` | 67 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 32 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/AppConfiguration.swift` | 123 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 33 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Accessibility.swift` | 201 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 34 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Capture.swift` | 141 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 35 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Errors.swift` | 111 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 36 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Foundation.swift` | 94 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 37 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Insights.swift` | 107 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 38 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Library.swift` | 190 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 39 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Onboarding.swift` | 61 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 40 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Policy.swift` | 312 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 41 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Review.swift` | 77 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 42 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n+Settings.swift` | 282 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 43 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/L10n/L10n.swift` | 19 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 44 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/LocalizationHelper.swift` | 60 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 45 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/ReviewDataNotification.swift` | 29 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 46 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/SnapDrillError.swift` | 38 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 47 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/SnapDrillTips.swift` | 104 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 48 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Support/UserDefaultsKeys.swift` | 96 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 49 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Utils/Collection+Safe.swift` | 23 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 50 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Utils/Color+Hex.swift` | 61 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 51 | `./Packages/SnapDrillCore/Sources/SnapDrillCore/Utils/Date+Extensions.swift` | 68 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 52 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/CaptureDraftServiceTests.swift` | 156 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 53 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/CollectionSafeTests.swift` | 50 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 54 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/ContentTaggingServiceTests.swift` | 71 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 55 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/DateExtensionsTests.swift` | 64 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 56 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/ImageStorageTests.swift` | 119 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 57 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/NotificationServiceTests.swift` | 97 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 58 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/OCRServiceTests.swift` | 114 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 59 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/PDFExportServiceTests.swift` | 201 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 60 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/QuestionSplittingServiceTests.swift` | 91 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 61 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/ReviewSchedulerTests.swift` | 156 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 62 | `./Packages/SnapDrillCore/Tests/SnapDrillCoreTests/ServiceContainerTests.swift` | 49 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 63 | `./Packages/SnapDrillData/Package.swift` | 46 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 64 | `./Packages/SnapDrillData/Sources/SnapDrillData/BackupDTO.swift` | 316 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 65 | `./Packages/SnapDrillData/Sources/SnapDrillData/BackupService.swift` | 313 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 66 | `./Packages/SnapDrillData/Sources/SnapDrillData/DataError.swift` | 39 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 67 | `./Packages/SnapDrillData/Sources/SnapDrillData/DataExecutor.swift` | 133 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 68 | `./Packages/SnapDrillData/Sources/SnapDrillData/DataSeeder.swift` | 355 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 69 | `./Packages/SnapDrillData/Sources/SnapDrillData/GradeModel.swift` | 46 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 70 | `./Packages/SnapDrillData/Sources/SnapDrillData/GradeRepository.swift` | 135 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 71 | `./Packages/SnapDrillData/Sources/SnapDrillData/MigrationPlan.swift` | 76 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 72 | `./Packages/SnapDrillData/Sources/SnapDrillData/Persistence.swift` | 92 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 73 | `./Packages/SnapDrillData/Sources/SnapDrillData/PersistenceError.swift` | 53 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 74 | `./Packages/SnapDrillData/Sources/SnapDrillData/ProfileManager+Environment.swift` | 31 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 75 | `./Packages/SnapDrillData/Sources/SnapDrillData/ProfileManager.swift` | 405 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 76 | `./Packages/SnapDrillData/Sources/SnapDrillData/ProfileMigration.swift` | 133 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 77 | `./Packages/SnapDrillData/Sources/SnapDrillData/RepositoryContainer+Environment.swift` | 46 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 78 | `./Packages/SnapDrillData/Sources/SnapDrillData/RepositoryContainer.swift` | 275 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 79 | `./Packages/SnapDrillData/Sources/SnapDrillData/ReviewExportSnapshot.swift` | 43 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 80 | `./Packages/SnapDrillData/Sources/SnapDrillData/ReviewItemModel.swift` | 185 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 81 | `./Packages/SnapDrillData/Sources/SnapDrillData/ReviewRepository.swift` | 357 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 82 | `./Packages/SnapDrillData/Sources/SnapDrillData/SourceModel.swift` | 55 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 83 | `./Packages/SnapDrillData/Sources/SnapDrillData/SourceRepository.swift` | 138 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 84 | `./Packages/SnapDrillData/Sources/SnapDrillData/SubjectModel.swift` | 58 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 85 | `./Packages/SnapDrillData/Sources/SnapDrillData/SubjectRepository.swift` | 145 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 86 | `./Packages/SnapDrillData/Sources/SnapDrillData/TagModel.swift` | 47 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 87 | `./Packages/SnapDrillData/Sources/SnapDrillData/TagRepository.swift` | 87 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 88 | `./Packages/SnapDrillData/Sources/SnapDrillData/ZIPArchiver.swift` | 62 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 89 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/BackupDTOTests.swift` | 200 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 90 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/BackupServiceTests.swift` | 282 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 91 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/DataConcurrencyTests.swift` | 212 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 92 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/GradeRepositoryTests.swift` | 110 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 93 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/MigrationTests.swift` | 98 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 94 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/ModelExecutorTests.swift` | 116 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 95 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/ModelTests.swift` | 200 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 96 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/PersistenceControllerTests.swift` | 76 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 97 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/ProfileTests.swift` | 147 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 98 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/RepositoryContainerBackupTests.swift` | 218 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 99 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/ReviewItemModelTests.swift` | 125 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 100 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/ReviewRepositoryTests.swift` | 238 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 101 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/SourceRepositoryTests.swift` | 110 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 102 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/SubjectRepositoryTests.swift` | 123 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 103 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/TagRepositoryTests.swift` | 93 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 104 | `./Packages/SnapDrillData/Tests/SnapDrillDataTests/TestHelpers.swift` | 127 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 105 | `./Packages/SnapDrillFeatures/Package.swift` | 88 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 106 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CameraSessionManager.swift` | 271 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 107 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureMethodCard.swift` | 79 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 108 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureResultView.swift` | 406 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 109 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureResultViewModel.swift` | 494 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 110 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureRouter.swift` | 80 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 111 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureView.swift` | 369 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 112 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CaptureViewModel.swift` | 347 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 113 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/CornerBracketShape.swift` | 44 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 114 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/DocumentScannerView.swift` | 138 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 115 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/PDFPagePickerView.swift` | 318 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 116 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/ScanPagePickerView.swift` | 144 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 117 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/SmartCameraView.swift` | 195 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 118 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureCapture/SmartCameraViewController.swift` | 79 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 119 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/BentoCard.swift` | 103 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 120 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardAnalyticsView.swift` | 187 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 121 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardAnalyticsViewModel.swift` | 194 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 122 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardRouter.swift` | 62 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 123 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardView.swift` | 242 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 124 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/DashboardViewModel.swift` | 150 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 125 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/HeaderView.swift` | 115 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 126 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureDashboard/ReviewHeroCard.swift` | 168 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 127 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/BatchTagSheet.swift` | 82 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 128 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditSourceView.swift` | 160 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 129 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/EditSubjectView.swift` | 158 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 130 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportOptionsSheet.swift` | 322 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 131 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ExportPreviewView.swift` | 129 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 132 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/FullScreenImageView.swift` | 91 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 133 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/GradeManagerView.swift` | 137 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 134 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/GradeManagerViewModel.swift` | 117 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 135 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryComponents.swift` | 56 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 136 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryDetailView.swift` | 340 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 137 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryEditView.swift` | 342 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 138 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryEditViewModel.swift` | 335 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 139 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryFilterSheet.swift` | 150 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 140 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryListView.swift` | 207 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 141 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryRouter.swift` | 50 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 142 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryView.swift` | 302 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 143 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/LibraryViewModel.swift` | 300 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 144 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ResolvedExportSheet.swift` | 39 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 145 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SFSymbolPickerView.swift` | 270 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 146 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/ShareCardView.swift` | 104 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 147 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SmartPaperView.swift` | 279 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 148 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SmartPaperViewModel.swift` | 103 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 149 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SourceManagerView.swift` | 83 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 150 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SourceManagerViewModel.swift` | 123 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 151 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SubjectManagerView.swift` | 84 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 152 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureLibrary/SubjectManagerViewModel.swift` | 126 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 153 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewActionButtons.swift` | 174 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 154 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardBack.swift` | 200 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 155 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardContent.swift` | 225 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 156 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewCardFactory.swift` | 32 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 157 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewDashboardView.swift` | 211 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 158 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewEmptyStateView.swift` | 73 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 159 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewProgressHeader.swift` | 77 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 160 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewRouter.swift` | 51 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 161 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewSessionSummaryView.swift` | 137 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 162 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewView.swift` | 346 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 163 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/ReviewViewModel.swift` | 291 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 164 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureReview/SwipeCard.swift` | 152 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 165 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/CSVParser.swift` | 117 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 166 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/DataAndSyncSettingsView.swift` | 339 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 167 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/DataExporter.swift` | 99 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 168 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/EditProfileView.swift` | 287 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 169 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/LanguageSettingsView.swift` | 111 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 170 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/LicenseView.swift` | 121 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 171 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/NotificationSettingsView.swift` | 149 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 172 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/NotificationSettingsViewModel.swift` | 75 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 173 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacyPolicyView.swift` | 133 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 174 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacySettingsView.swift` | 114 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 175 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/PrivacySettingsViewModel.swift` | 165 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 176 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListView.swift` | 138 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 177 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ProfileListViewModel.swift` | 118 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 178 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/ReviewAppearanceSettingsView.swift` | 118 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 179 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsRouter.swift` | 51 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 180 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsRow.swift` | 63 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 181 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsView.swift` | 411 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 182 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/SettingsViewModel.swift` | 432 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 183 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/StorageManagementView.swift` | 58 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 184 | `./Packages/SnapDrillFeatures/Sources/SnapDrillFeatureSettings/TermsOfServiceView.swift` | 139 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 185 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/CaptureResultViewModelTests.swift` | 346 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 186 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/CaptureViewModelTests.swift` | 157 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 187 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/DashboardAnalyticsViewModelTests.swift` | 331 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 188 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/DashboardViewModelTests.swift` | 232 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 189 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/FeatureSnapshotTests.swift` | 182 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 190 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/GradeManagerViewModelTests.swift` | 151 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 191 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/LibraryEditViewModelTests.swift` | 235 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 192 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/LibraryViewModelTests.swift` | 219 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 193 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/NotificationSettingsViewModelTests.swift` | 130 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 194 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/PerformanceTests.swift` | 122 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 195 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/PrivacySettingsViewModelTests.swift` | 210 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 196 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/ProfileListViewModelTests.swift` | 162 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 197 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/ReviewViewModelTests.swift` | 484 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 198 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/SettingsViewModelCSVTests.swift` | 413 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 199 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/SettingsViewModelTests.swift` | 337 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 200 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/SmartPaperViewModelTests.swift` | 220 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 201 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/SnapshotRegressionTests.swift` | 115 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 202 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/SourceManagerViewModelTests.swift` | 151 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 203 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/SubjectManagerViewModelTests.swift` | 156 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 204 | `./Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/TestHelpers.swift` | 93 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 205 | `./Packages/SnapDrillInfrastructure/Package.swift` | 43 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 206 | `./Packages/SnapDrillInfrastructure/Sources/SnapDrillInfrastructure/FirebaseAnalyticsService.swift` | 80 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 207 | `./Packages/SnapDrillInfrastructure/Sources/SnapDrillInfrastructure/FirebaseBootstrap.swift` | 48 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 208 | `./Packages/SnapDrillUI/Package.swift` | 46 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 209 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/AccessibilityExtensions.swift` | 217 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 210 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/AppError.swift` | 114 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 211 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/ContextualErrorView.swift` | 146 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 212 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/ErrorMessageView.swift` | 116 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 213 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/FlipView.swift` | 98 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 214 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/ImageCropperView.swift` | 101 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 215 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/Navigation.swift` | 75 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 216 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/Navigation/TabItem.swift` | 49 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 217 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/OnboardingView.swift` | 236 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 218 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/ProgressLoadingView.swift` | 138 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 219 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/SnapDrillButton.swift` | 61 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 220 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/TagInputView.swift` | 149 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 221 | `./Packages/SnapDrillUI/Sources/SnapDrillUI/TipPopoverContent.swift` | 51 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 222 | `./Packages/SnapDrillUI/Tests/SnapDrillUITests/SnapDrillUITests.swift` | 71 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 223 | `./SnapDrill/App/AppRootView.swift` | 116 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 224 | `./SnapDrill/App/AppRouter.swift` | 140 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 225 | `./SnapDrill/App/Composition/DependencyContainer.swift` | 123 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 226 | `./SnapDrill/App/SnapDrillApp.swift` | 130 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 227 | `./SnapDrillShare/ShareDeepLinkBuilder.swift` | 35 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 228 | `./SnapDrillShare/ShareImageDownsampler.swift` | 39 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 229 | `./SnapDrillShare/ShareViewController.swift` | 112 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 230 | `./SnapDrillShare/SharedContainerImageWriter.swift` | 114 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 231 | `./SnapDrillShareTests/ShareHelpersTests.swift` | 253 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 232 | `./SnapDrillUITests/SnapDrillUITests.swift` | 88 | UNREAD | - | Swift scope from corrected find command; content audit pending. |
| 233 | `docs/DOC_DEPENDENCY_MAP.md` | 125 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 234 | `docs/KNOWLEDGE_MAP.md` | 165 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 235 | `docs/archive/README.md` | 43 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 236 | `docs/archive/audit-report-20260409.md` | 80 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 237 | `docs/archive/phase-e-pr-e4-reflow-20260422.md` | 161 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 238 | `docs/archive/research/harness-engineering-study-20260418.md` | 243 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 239 | `docs/archive/research/hermes-agent-study-20260418.md` | 143 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 240 | `docs/archive/timeline.md` | 62 | UNREAD | - | Docs Markdown scope from corrected find command; content audit pending. |
| 241 | `docs/decisions/ADR-001-smart-paper-analytics-pricing.md` | 76 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；Hybrid 定价决策已纳入 Claim Ledger。 |
| 242 | `docs/decisions/ADR-002-remove-att-authorization.md` | 40 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；ATT 删除决策已纳入 Claim Ledger。 |
| 243 | `docs/decisions/ADR-003-yaml-frontmatter.md` | 121 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；YAML frontmatter 决策状态残留已纳入 Claim Ledger。 |
| 244 | `docs/decisions/ADR-TEMPLATE.md` | 31 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；ADR 模板 frontmatter 状态已纳入 Claim Ledger。 |
| 245 | `docs/memory/README.md` | 35 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；记忆目录职责和写回规则已纳入 Claim Ledger。 |
| 246 | `docs/memory/checkpoints/2026-04-17-phase4-p2-sprint.md` | 45 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；Phase 4 P2 完成项、决策、风险和 Next 已纳入 Claim Ledger。 |
| 247 | `docs/memory/checkpoints/2026-04-17-phase4-p3-sprint.md` | 52 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；Phase 4 P3 完成项、Open 和风险已纳入 Claim Ledger。 |
| 248 | `docs/memory/checkpoints/2026-04-17-phase4-tech-debt.md` | 48 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；tech-debt 完成/Open 项和后续状态已纳入 Claim Ledger。 |
| 249 | `docs/memory/checkpoints/2026-04-19-harness-stage-a-b.md` | 93 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；Harness Stage A+B 纪律违规、rubric 实战和反馈回流已纳入 Claim Ledger。 |
| 250 | `docs/memory/checkpoints/2026-04-19-harness-stage-c.md` | 105 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；SnapshotTesting、CI artifact 和机制例外说明已纳入 Claim Ledger。 |
| 251 | `docs/memory/checkpoints/2026-04-20-phase1-modernization-sprint.md` | 95 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；Phase 1 三件套和后续 Phase backlog 已纳入 Claim Ledger。 |
| 252 | `docs/memory/checkpoints/2026-04-22-phase-c-closeout.md` | 111 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；Phase C 基线清洁和 F 规则墓碑机制已纳入 Claim Ledger。 |
| 253 | `docs/memory/checkpoints/2026-04-22-phase-d-closeout.md` | 139 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；agent-harness 抽仓与 D-003 一致性已纳入 Claim Ledger。 |
| 254 | `docs/memory/checkpoints/2026-04-22-phase-e-closeout.md` | 121 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；反哺机制、public repo 和稳定期建议已纳入 Claim Ledger。 |
| 255 | `docs/memory/checkpoints/2026-05-08-baseline-audit.md` | 141 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；基线审计范围、结果和闭合状态已纳入 Claim Ledger。 |
| 256 | `docs/memory/checkpoints/2026-05-09-audit-step-0-boundary.md` | 93 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；归零审计边界与现状漂移已纳入 Claim Ledger。 |
| 257 | `docs/memory/checkpoints/2026-05-09-audit-step-1-product.md` | 126 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；产品运行体系发现和后续引用风险已纳入 Claim Ledger。 |
| 258 | `docs/memory/checkpoints/2026-05-09-audit-step-2-verification.md` | 92 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；验证体系发现和 disabled/snapshot 风险已纳入 Claim Ledger。 |
| 259 | `docs/memory/checkpoints/2026-05-09-audit-step-3-knowledge.md` | 65 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；知识体系发现和文档时效风险已纳入 Claim Ledger。 |
| 260 | `docs/memory/checkpoints/2026-05-09-audit-step-4-state-memory.md` | 60 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；状态/记忆审计的 checkpoint 计数漂移已纳入 Claim Ledger。 |
| 261 | `docs/memory/checkpoints/2026-05-09-audit-step-5-governance.md` | 94 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；治理体系发现、F-005 门禁和 overlay 风险已纳入 Claim Ledger。 |
| 262 | `docs/memory/checkpoints/2026-05-09-audit-step-6-pipeline.md` | 100 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；工程管道发现和 Next 顺序异常已纳入 Claim Ledger。 |
| 263 | `docs/memory/checkpoints/2026-05-09-audit-step-7-dependencies.md` | 81 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；依赖与供应链发现和 Next 顺序异常已纳入 Claim Ledger。 |
| 264 | `docs/memory/checkpoints/2026-05-09-audit-trace-vision-downstream.md` | 118 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；vision 下游追溯结论与后续 Step 1 风险差异已纳入 Claim Ledger。 |
| 265 | `docs/memory/checkpoints/2026-05-11-audit-architecture-verification.md` | 73 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；architecture 验证结论和后续 Step 2 深潜项差异已纳入 Claim Ledger。 |
| 266 | `docs/memory/checkpoints/2026-05-11-zero-trust-audit-closeout.md` | 188 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；归零审计收官自述、未完成项和过度断言风险已纳入 Claim Ledger。 |
| 267 | `docs/memory/checkpoints/2026-05-11-zero-trust-audit-trail.md` | 633 | OUT_OF_SCOPE | 2026-05-12 | 当前正在编辑的零信任审计 trail；按 Step 3 指令标记为 OUT_OF_SCOPE，不审计其内容。 |
| 268 | `docs/memory/codex-handoff-20260508.md` | 121 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；Codex 接手清单、环境与架构快照已纳入 Claim Ledger。 |
| 269 | `docs/memory/decisions.md` | 62 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；D-001~D-003 决策与 STATUS 引用已纳入 Claim Ledger。 |
| 270 | `docs/memory/feedback.md` | 297 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；F-001~F-020 纪律和 checkpoint 遵守情况已纳入 Claim Ledger。 |
| 271 | `docs/memory/handoff.md` | 139 | READ_VERIFIED | 2026-05-12 | Step 3 记忆/历史文档审计已用 `nl -ba` 逐行读取；接手状态、阻塞链、基线审计数字和 STATUS 引用一致性已纳入 Claim Ledger。 |
| 272 | `docs/standards/README.md` | 35 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; rules index and agent-agnostic governance checked. |
| 273 | `docs/standards/api-pitfalls.md` | 68 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; API pitfall scope checked against route pointer. |
| 274 | `docs/standards/apple-extension.md` | 32 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; Share Extension constraints checked against route pointer. |
| 275 | `docs/standards/apple-limits.md` | 44 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; Apple capability boundaries checked against route pointer. |
| 276 | `docs/standards/apple-native.md` | 90 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; native UI rules checked against route pointer. |
| 277 | `docs/standards/codex-delegation.md` | 56 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; shared-constraints canonical reference verified. |
| 278 | `docs/standards/coding.md` | 100 | READ_VERIFIED | 2026-05-12 | Step 4a core engineering principles audit read full content with `nl -ba`; pattern-level implementation claims marked for Step 5 verification. |
| 279 | `docs/standards/collaboration.md` | 140 | READ_VERIFIED | 2026-05-12 | Step 4a core engineering principles audit read full content with `nl -ba`; rating criteria checked against shared constraints. |
| 280 | `docs/standards/engineering.md` | 139 | READ_VERIFIED | 2026-05-12 | Step 4a core engineering principles audit read full content with `nl -ba`; seven principles checked against coding/testing follow-through. |
| 281 | `docs/standards/gemini-delegation.md` | 149 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; shared-constraints canonical reference verified. |
| 282 | `docs/standards/memory-routing.md` | 61 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; knowledge routing table checked against route pointer. |
| 283 | `docs/standards/permission-model.md` | 129 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; hook lifecycle table checked against `.claude/settings.json`. |
| 284 | `docs/standards/review-prompt-guide.md` | 176 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; review prompt discipline checked against route pointer. |
| 285 | `docs/standards/shared-constraints.md` | 19 | READ_VERIFIED | 2026-05-12 | Step 4a core engineering principles audit read full content with `nl -ba`; shared constraints checked against collaboration rating criteria. |
| 286 | `docs/standards/testing.md` | 111 | READ_VERIFIED | 2026-05-12 | Step 4a core engineering principles audit read full content with `nl -ba`; testing follow-through checked against engineering principles. |
| 287 | `docs/standards/ux-design.md` | 70 | READ_VERIFIED | 2026-05-12 | Step 4b agent governance + Apple reference audit read full content with `nl -ba`; UX checklist checked against route pointer. |
| 288 | `docs/product/appstore-metadata.md` | 133 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；ASO、Review Notes 与隐私/功能风险已纳入 Claim Ledger。 |
| 289 | `docs/product/product-analytics.md` | 93 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；事件字典和成功信号映射已纳入 Claim Ledger。 |
| 290 | `docs/product/product-business.md` | 261 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；商业化、隐私和 COPPA 姿态已纳入 Claim Ledger。 |
| 291 | `docs/product/product-cases.md` | 382 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；Use Case 与边界规格引用问题已纳入 Claim Ledger。 |
| 292 | `docs/product/product-competitive-analysis.md` | 74 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；竞品格局和定位表述已纳入 Claim Ledger。 |
| 293 | `docs/product/product-design.md` | 485 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；设计铁律、导出、SM-2、iCloud、设置/引导已纳入 Claim Ledger。 |
| 294 | `docs/product/product-glossary.md` | 90 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；术语与代码对应关系已纳入 Claim Ledger。 |
| 295 | `docs/product/product-journeys.md` | 427 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；旅程指标与引用问题已纳入 Claim Ledger。 |
| 296 | `docs/product/product-onboarding.md` | 96 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；Onboarding 隐私文案风险已纳入 Claim Ledger。 |
| 297 | `docs/product/product-requirements.md` | 390 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；功能规格、MoSCoW 与 v2.0 能力边界已纳入 Claim Ledger。 |
| 298 | `docs/product/product-vision.md` | 256 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；愿景、原则、成功信号和隐私边界已纳入 Claim Ledger。 |
| 299 | `docs/tech/api-reference.md` | 881 | READ_VERIFIED | 2026-05-12 | Step 2 技术规格文档审计已用 `nl -ba` 逐行读取；API 签名、公开类型和新增 API 已纳入 Claim Ledger / Deep Dive Queue。 |
| 300 | `docs/tech/architecture.md` | 207 | READ_VERIFIED | 2026-05-12 | Step 2 技术规格文档审计已用 `nl -ba` 逐行读取；架构、DI、数据流、多 Profile、删除机制和测试架构已纳入 Claim Ledger / Deep Dive Queue。 |
| 301 | `docs/tech/compliance.md` | 239 | READ_VERIFIED | 2026-05-12 | Step 2 技术规格文档审计已用 `nl -ba` 逐行读取；隐私、COPPA、GDPR/PIPL、数据生命周期和 SDK 风险已纳入 Claim Ledger / Deep Dive Queue。 |
| 302 | `docs/tech/deployment.md` | 131 | READ_VERIFIED | 2026-05-12 | Step 2 技术规格文档审计已用 `nl -ba` 逐行读取；版本、CI/CD、发版、监控和环境配置已纳入 Claim Ledger / Deep Dive Queue。 |
| 303 | `docs/tech/non-functional-requirements.md` | 85 | READ_VERIFIED | 2026-05-12 | Step 2 技术规格文档审计已用 `nl -ba` 逐行读取；性能、内存、存储、隐私、兼容性、无障碍和可靠性指标已纳入 Claim Ledger / Deep Dive Queue。 |
| 304 | `docs/tech/release-checklist.md` | 138 | READ_VERIFIED | 2026-05-12 | Step 2 技术规格文档审计已用 `nl -ba` 逐行读取；TestFlight 手工验收清单和发版核对项已纳入 Claim Ledger / Deep Dive Queue。 |
| 305 | `docs/workflow.md` | 186 | READ_VERIFIED | 2026-05-12 | Step 1 产品/决策文档审计已用 `nl -ba` 逐行读取；协作闭环、DoD、Review 和 docaudit 传播机制已纳入 Claim Ledger。 |
| 306 | `.agent-harness/README.md` | 78 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 307 | `.agent-harness/lock.json` | 6 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 308 | `.agent-harness/project.yaml` | 76 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 309 | `.agent-harness/proposals/_claude__skills__phase-closeout__SKILL_md__2026-04-22T12-47-28+00-00.md` | 136 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 310 | `.claude/.long-session-warned` | 0 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 311 | `.claude/compact-reminder.md` | 34 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 312 | `.claude/hooks/block-dangerous-bash.sh` | 33 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 313 | `.claude/hooks/docaudit-on-doc-edit.sh` | 42 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 314 | `.claude/hooks/docaudit-preflight.sh` | 34 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 315 | `.claude/hooks/log-file-change.sh` | 15 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 316 | `.claude/hooks/long-session-guard.sh` | 51 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 317 | `.claude/hooks/post-merge-checkpoint.sh` | 46 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 318 | `.claude/hooks/premerge-checklist.sh` | 31 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 319 | `.claude/hooks/prepush-lint.sh` | 33 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 320 | `.claude/hooks/session-metrics.sh` | 26 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 321 | `.claude/hooks/swift-autolint.sh` | 53 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 322 | `.claude/rules/api-pitfalls.md` | 7 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/api-pitfalls.md` consistently. |
| 323 | `.claude/rules/apple-extension.md` | 7 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/apple-extension.md` consistently. |
| 324 | `.claude/rules/apple-limits.md` | 7 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/apple-limits.md` consistently. |
| 325 | `.claude/rules/apple-native.md` | 7 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/apple-native.md` consistently. |
| 326 | `.claude/rules/codex-delegation.md` | 9 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/codex-delegation.md` consistently. |
| 327 | `.claude/rules/coding.md` | 7 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 328 | `.claude/rules/collaboration.md` | 8 | READ_VERIFIED | 2026-05-12 | Step 4a Group B pointer; route to `docs/standards/collaboration.md` verified with `nl -ba`. |
| 329 | `.claude/rules/engineering.md` | 8 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 330 | `.claude/rules/gemini-delegation.md` | 9 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/gemini-delegation.md` consistently. |
| 331 | `.claude/rules/memory-routing.md` | 8 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/memory-routing.md` consistently. |
| 332 | `.claude/rules/permission-model.md` | 9 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/permission-model.md` consistently. |
| 333 | `.claude/rules/review-prompt-guide.md` | 7 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/review-prompt-guide.md` consistently. |
| 334 | `.claude/rules/shared-constraints.md` | 8 | READ_VERIFIED | 2026-05-12 | Step 4a Group B pointer; route to `docs/standards/shared-constraints.md` verified with `nl -ba`. |
| 335 | `.claude/rules/testing.md` | 8 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 336 | `.claude/rules/ux-design.md` | 7 | READ_VERIFIED | 2026-05-12 | Step 4b pointer read with `nl -ba`; routes to `docs/standards/ux-design.md` consistently. |
| 337 | `.claude/session-log.txt` | 2704 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 338 | `.claude/session-metrics.tsv` | 5015 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 339 | `.claude/settings.json` | 79 | READ_VERIFIED | 2026-05-12 | Step 4b permission execution check read with `nl -ba`; 11 hook bindings match `docs/standards/permission-model.md` lifecycle table. |
| 340 | `.claude/settings.local.json` | 350 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 341 | `.claude/skills/cross-audit-consensus/SKILL.md` | 149 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 342 | `.claude/skills/cross-audit/SKILL.md` | 121 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 343 | `.claude/skills/developer/SKILL.md` | 85 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 344 | `.claude/skills/devops/SKILL.md` | 46 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 345 | `.claude/skills/knowledge-health/SKILL.md` | 131 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 346 | `.claude/skills/phase-closeout/SKILL.md` | 132 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 347 | `.claude/skills/pr-review-workflow/SKILL.md` | 56 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 348 | `.claude/skills/qa-engineer/SKILL.md` | 107 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 349 | `.claude/skills/resume-from-handoff/SKILL.md` | 84 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 350 | `.claude/skills/security-engineer/SKILL.md` | 97 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 351 | `.claude/skills/update-status/SKILL.md` | 74 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 352 | `.github/ISSUE_TEMPLATE/bug_report.md` | 53 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 353 | `.github/ISSUE_TEMPLATE/chore.md` | 49 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 354 | `.github/ISSUE_TEMPLATE/config.yml` | 2 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 355 | `.github/ISSUE_TEMPLATE/feature_request.md` | 70 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 356 | `.github/PULL_REQUEST_TEMPLATE.md` | 59 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |
| 357 | `.github/workflows/ci.yml` | 182 | UNREAD | - | Hidden governance scope from corrected find command; content audit pending. |

## Hidden Governance File Inventory

```text
.agent-harness/README.md
.agent-harness/lock.json
.agent-harness/project.yaml
.agent-harness/proposals/_claude__skills__phase-closeout__SKILL_md__2026-04-22T12-47-28+00-00.md
.claude/.long-session-warned
.claude/compact-reminder.md
.claude/hooks/block-dangerous-bash.sh
.claude/hooks/docaudit-on-doc-edit.sh
.claude/hooks/docaudit-preflight.sh
.claude/hooks/log-file-change.sh
.claude/hooks/long-session-guard.sh
.claude/hooks/post-merge-checkpoint.sh
.claude/hooks/premerge-checklist.sh
.claude/hooks/prepush-lint.sh
.claude/hooks/session-metrics.sh
.claude/hooks/swift-autolint.sh
.claude/rules/api-pitfalls.md
.claude/rules/apple-extension.md
.claude/rules/apple-limits.md
.claude/rules/apple-native.md
.claude/rules/codex-delegation.md
.claude/rules/coding.md
.claude/rules/collaboration.md
.claude/rules/engineering.md
.claude/rules/gemini-delegation.md
.claude/rules/memory-routing.md
.claude/rules/permission-model.md
.claude/rules/review-prompt-guide.md
.claude/rules/shared-constraints.md
.claude/rules/testing.md
.claude/rules/ux-design.md
.claude/session-log.txt
.claude/session-metrics.tsv
.claude/settings.json
.claude/settings.local.json
.claude/skills/cross-audit-consensus/SKILL.md
.claude/skills/cross-audit/SKILL.md
.claude/skills/developer/SKILL.md
.claude/skills/devops/SKILL.md
.claude/skills/knowledge-health/SKILL.md
.claude/skills/phase-closeout/SKILL.md
.claude/skills/pr-review-workflow/SKILL.md
.claude/skills/qa-engineer/SKILL.md
.claude/skills/resume-from-handoff/SKILL.md
.claude/skills/security-engineer/SKILL.md
.claude/skills/update-status/SKILL.md
.github/ISSUE_TEMPLATE/bug_report.md
.github/ISSUE_TEMPLATE/chore.md
.github/ISSUE_TEMPLATE/config.yml
.github/ISSUE_TEMPLATE/feature_request.md
.github/PULL_REQUEST_TEMPLATE.md
.github/workflows/ci.yml
```

## Claim Ledger

Format: `ID | Line(s) | Category | Verification status | Source quote | Verification method`. All 57 claims are `PENDING`; actual verification has not been performed in this Step 0 correction.

- C001 | line 2 | 元信息 | PENDING | "last_verified: 2026-05-10" | `sed -n '2p' STATUS.md`; compare to latest audit evidence date.
- C002 | line 3 | 元信息 | PENDING | "layer: snapshot" | `sed -n '3p' STATUS.md`; compare to docs frontmatter policy.
- C003 | lines 4-6 | 元信息 | PENDING | "freshness: / max_age_days: 7 / decay_trigger: [pr_merge]" | `sed -n '4,6p' STATUS.md`; verify policy in `docs/memory/README.md` or workflow rules.
- C004 | line 8 | 元信息 | PENDING | "# SnapDrill 项目状态看板" | `sed -n '8p' STATUS.md`; verify repository/product name from `Package.swift` and README.
- C005 | line 10 | 元信息 | PENDING | "> 最后更新：2026-05-10（**Phase 2 全链路收官 + Phase 2.N 收尾 + 三方基线审计**）" | `sed -n '10p' STATUS.md`; verify supporting checkpoints and PR timestamps.
- C006 | line 11 | 测试 | PENDING | "> 编译状态：✅ 0 errors · 0 lint violations · AllTests/CI 420 tests passed/skipped clean · docaudit exit 0" | Run the documented build/test/lint/docaudit commands; inspect latest CI run logs.
- C007 | line 12 | PR历史 | PENDING | "> Open PR：0 · Open Issue：8（#699 backlog + Apple 阻塞链 + #626 真机待验）" | `gh pr list --state open`; `gh issue list --state open`; `gh issue view 699`; `gh issue view 626`.
- C008 | line 13 | 产品 | PENDING | "> Phase 2 全部完成 · #599 死锁已根除 · 生产调用路径已迁移到 DataExecutor（PersistenceController 仅作兼容类型保留）" | Inspect Phase 2 checkpoints, `gh issue view 599`, and `rg -n "DataExecutor|PersistenceController" Packages`.
- C009 | line 14 | 元信息 | PENDING | "> F 规则：**15 活跃 + 5 退役** = F-001~F-020（退役 F-003/F-009/F-010/F-015/F-020）· D-003 抽仓决策入 `docs/memory/decisions.md`" | `rg -n "F-00|F-0|F-020|D-003" docs .claude`; `test -f docs/memory/decisions.md`.
- C010 | line 15 | 测试 | PENDING | "> **基线审计**：Claude DeepSeek v4 Pro 主审 + Codex GPT-5.5 + Gemini 3 Pro 三方交叉验证 → 0 Critical / 14 Warning / 8 Info · 评分 8.5/10 · 报告 `docs/memory/checkpoints/2026-05-08-baseline-audit.md`" | `test -f docs/memory/checkpoints/2026-05-08-baseline-audit.md`; read report; verify model notes and issue counts.
- C011 | line 17 | 外部状态 | PENDING | "> **公开仓库**：[NotBad-Labs/agent-harness](https://github.com/NotBad-Labs/agent-harness)（**public**, MIT, main）— snapdrill-ios 通过 `.agent-harness/` 契约声明 consumer 身份" | `gh repo view NotBad-Labs/agent-harness --json visibility,licenseInfo,defaultBranchRef`; inspect `.agent-harness/project.yaml`.
- C012 | line 18 | 外部状态 | PENDING | "> **智能体**：DeepSeek v4 Pro (Claude Code CLI) + Codex 0.121.0 + Gemini CLI 0.41.2（优先显式 `gemini-3-pro-preview`，不可用时退 `gemini-2.5-pro`）" | Check local CLI versions and current tool/model configuration.
- C013 | line 19 | 元信息 | PENDING | "> **下次接手**：读 `docs/memory/handoff.md` 顶部 → `docs/memory/checkpoints/2026-04-22-phase-e-closeout.md`" | `test -f docs/memory/handoff.md`; `test -f docs/memory/checkpoints/2026-04-22-phase-e-closeout.md`; inspect handoff top section.
- C014 | line 20 | 测试 | PENDING | "> 测试：420 tests（SnapDrill AllTests/CI 本地验证）+ 68 tests（agent-harness CI）· ViewModel 覆盖 16/16" | Run SnapDrill AllTests/CI; inspect agent-harness CI; enumerate ViewModel test targets.
- C015 | line 22 | PR历史 | PENDING | "## 本轮完成（2026-04-18→19，Harness Engineering Stage A+B 7 PR）" | Verify PRs #673-#679 merged dates and labels.
- C016 | lines 26-32 | PR历史 | PENDING | "#673 ... #679" table entries for 7 PRs | `for n in 673 674 675 676 677 678 679; do gh pr view $n --json number,state,mergedAt,title,body; done`.
- C017 | line 34 | 私有路径 | PENDING | "**本轮机制首次实战**：cross-audit rubric 一次性挡下 2 个 PR 合并（#677 Codex 6.8 / #678 Codex 5.5），Codex 两轮复核后通过。详见 `~/.claude/plans/harness-prs-cross-audit-20260418.md`。" | `test -f ~/.claude/plans/harness-prs-cross-audit-20260418.md`; inspect PR review comments for #677/#678.
- C018 | lines 36-39 | PR历史 | PENDING | "**方法论反思修复（PR #682 #681）**：checkpoint Risks 段 3 项未落地全部合并..." | `gh pr view 681`; `gh pr view 682`; inspect changed files for F-020, §2.5, Gemini prompt discipline.
- C019 | line 41 | PR历史 | PENDING | "**第二轮吃狗粮验证**：PR #682 首次 cross-audit 出现 Gemini 9.8 vs Codex 6.0（方差 3.8），按新 §2.5 硬阈值 retry；retry 后 Codex 8.5 通过。" | Inspect PR #682 audit artifacts and review history.
- C020 | line 43 | 私有路径 | PENDING | "**文档体系 v2 三方审计 + 收口 PR #685**（2026-04-19 晚）：Hermes + Harness 密集引入后用户担忧文档膨胀失真，三方全景审 49 md / 370KB。Codex 主锚点 8.0 / Claude Agent 次锚点 8.5 / Gemini 次锚点 8.75（方差 0.75）。归档 `~/.claude/plans/doc-audit-v2-20260419.md`。PR #685 落地 H 高 5 项 + 3 处 last_verified + M 中 6 项（共 14 文件 small diff，Closes #684）。首次三方审 Codex 6.8 发现阈值语义反转（方差 3.2 vs Gemini 10.0），retry 后 Codex 9.1 通过。**第三轮 rubric 吃狗粮成功：SSOT 闭环。**" | `test -f ~/.claude/plans/doc-audit-v2-20260419.md`; `gh pr view 685 --json state,mergedAt,closingIssuesReferences`; inspect audit notes.
- C021 | line 45 | 产品 | PENDING | "**Stage C 暂缓**：PR-6 SnapshotTesting + PR-7 CI 集成（~2-3 天）用户将另开单独会话推进。" | Verify later PR #690/#691 records and related planning notes.
- C022 | line 51 | 产品 | PENDING | "**文档已冻结，功能开发 + 测试补齐 + 工程治理阶段**（2026-04-14 冻结，2026-04-15-16 密集开发）。" | Inspect freeze checkpoint and PR dates #594 onward.
- C023 | lines 53-57 | PR历史 | PENDING | "**本周已完成（4 个 sprint）** ... PR #636 ... PR #640 ... Phase 1-3 ... Phase 4 P1 ... #642 ... #644 ... #646" | `gh pr view 636 640 642 644 646`; inspect doc audit summary path.
- C024 | lines 59-60 | PR历史 | PENDING | "**Phase 4 Step 1 完成**：- PR #648 .claude/rules/ux-design.md 补 YAML frontmatter（已合并，.claude/rules/ 12/12 全 YAML）" | `gh pr view 648`; run frontmatter check over `.claude/rules/*.md`.
- C025 | lines 62-68 | PR历史 | PENDING | "**Phase 4 P2 sprint 完成（2026-04-17 晚，6 PR 全合并）** ... PR #650-#655" | `for n in 650 651 652 653 654 655; do gh pr view $n --json state,mergedAt,files,title; done`.
- C026 | line 70 | CI | PENDING | "**Mac mini runner 事件**：CoreSimulator 1051.49→1051.50 过时导致 #651/#652/#653 首轮 CI FAILURE。用户系统更新 + 重启 Mac mini（macOS 26.4.1 / Xcode 26.4.1）后恢复，全部 CI 绿。" | Inspect GitHub Actions runs for PRs #651-#653 and runner environment logs.
- C027 | lines 72-80 | PR历史 | PENDING | "**Phase 4 P3 sprint 完成（2026-04-17 晚，8 PR 全合并）** ... PR #656-#663" | `for n in 656 657 658 659 660 661 662 663; do gh pr view $n --json state,mergedAt,files,title; done`.
- C028 | line 82 | 私有路径 | PENDING | "**对抗起草纪录**：9 个对抗任务（T-05/06/07/08/09/14a/14b/15a/15b）三方独立产出 27 份方案，汇总比对见 `~/.claude/plans/phase4-p1-adversarial-summary.md` + Claude 4 份独立方案 `~/.claude/plans/adversarial-*-claude.md`。" | `ls ~/.claude/plans/phase4-p1-adversarial-summary.md ~/.claude/plans/adversarial-*-claude.md`; count artifacts.
- C029 | line 84 | 私有路径 | PENDING | "**Gemini 幻觉事件**：T-07/08/09 Gemini 输出 OLD 原文全为虚构（编造章节号、Use Case 名称），已补充 `feedback_gemini_adversarial.md`：Gemini 引用仓库原文做 diff 不可信，仅作结构性建议参考。" | Locate `feedback_gemini_adversarial.md`; inspect T-07/T-08/T-09 artifacts and source diffs.
- C030 | lines 86-87 | 外部状态 | PENDING | "**遗留待真机验证**：- #626 PoC `QuestionSplittingService` Go/No-Go：边界准确率 >= 80%（10 份真实试卷），需 iOS 26 真机 + Apple Intelligence" | `gh issue view 626`; inspect service tests and device-validation plan.
- C031 | lines 89-92 | PR历史 | PENDING | "**Phase 4 收官后的 tech-debt 清理（2026-04-17→19，3 PR）** ... PR #664 ... #665 ... #667" | `gh pr view 664 665 667 --json state,mergedAt,title,files`.
- C032 | lines 94-95 | PR历史 | PENDING | "**本轮发现的 tech-debt（已记录）**：- Issue #666 swift-autolint 文件级 vs 行级 — 方案 A 修 hook 已合并；方案 B 拆 LocalizationKeys（1503 行）待独立 PR 排期" | `gh issue view 666`; inspect PR #667 and #688.
- C033 | lines 97-99 | 产品 | PENDING | "**下一候选**（用户排期）：- #626 PoC 真机验证... - Apple 账号缴费开闸 → #163/#479/#485/#486/#490/#161 六个解锁" | `gh issue view` for listed issues; verify account gating assumptions.
- C034 | lines 101-104 | PR历史 | PENDING | "**本轮新增完成**（2026-04-19 晚）：- **PR #688** ... - **PR #690** ... - **PR #691** ..." | `gh pr view 688 690 691 --json state,mergedAt,title,files`; inspect CI artifacts.
- C035 | lines 105-110 | PR历史 | PENDING | "**PR #694/#695/#696** Codex 3 PR 方案..." | `gh pr view 694 695 696 --json state,mergedAt,title,files`; inspect tests, parser changes, and snapshot coverage.
- C036 | line 112 | PR历史 | PENDING | "### 本轮完成（2026-04-15~16，24 个 PR）" | Count merged PRs listed in lines 116-139 and verify dates.
- C037 | lines 116-139 | PR历史 | PENDING | Table entries for PR #594, #595, #596, #597, #598, #600, #601, #602, #603, #604, #605, #606, #607, #609, #611, #613, #614, #616, #617, #619, #621, #623, #624 | `for n in 594 595 596 597 598 600 601 602 603 604 605 606 607 609 611 613 614 616 617 619 621 623 624; do gh pr view $n --json state,mergedAt,title,files; done`.
- C038 | line 140 | PR历史 | PENDING | "### 2026-04-16~17 晚间完成（13 个 PR + 1 研究 + 分支清理 + Gap 分析 + 中期审计 + 文档体系审计 + P2 sprint 启动）" | Verify listed PR count and non-PR artifacts in lines 144-177.
- C039 | lines 144-172 | PR历史 | PENDING | Table entries for PR #628, #629, #630, #631, #632, #633, #634, #636, #640, #642, #644, #646, #648, #650, #651, #652, #653, #654, #655, #656, #657, #658, #659, #660, #661, #662, #663, #664, #667 | `for n in 628 629 630 631 632 633 634 636 640 642 644 646 648 650 651 652 653 654 655 656 657 658 659 660 661 662 663 664 667; do gh pr view $n --json state,mergedAt,title,files; done`.
- C040 | line 173 | 外部状态 | PENDING | "| — | #626 FoundationModels 可行性研究完成（结论已发到 Issue） |" | `gh issue view 626 --comments`; search for FoundationModels conclusion.
- C041 | line 174 | 代码 | PENDING | "| — | 历史分支全量清理（113→0，本地+远程纯净） |" | `git branch --list`; `git branch -r`; compare historical cleanup evidence.
- C042 | line 175 | 测试 | PENDING | "| — | Gemini 对抗性审查：草稿恢复/删除撤销误判已验证，try? 残余已识别 |" | Inspect adversarial review notes and related issue/PR references.
- C043 | line 176 | 元信息 | PENDING | "| — | **2026-04-17 中期审计**：目标/约束/验收三维，发现 8 项脱轨点 + Scope 精化 |" | Locate 2026-04-17 mid-audit report; verify 8 findings.
- C044 | line 177 | 私有路径 | PENDING | "| — | **2026-04-17 文档体系三方独立审计**：56 文件五维度审计，三方独立报告（Claude + Codex exec + Gemini）→ 综合报告 `~/.claude/plans/doc-audit-summary.md` |" | `test -f ~/.claude/plans/doc-audit-summary.md`; verify file count and reports.
- C045 | line 179 | 元信息 | PENDING | "### 当前开发焦点（2026-05-10）" | Verify section date against latest project activity and `last_verified`.
- C046 | line 181 | 产品 | PENDING | "**Phase 2 + Phase 2.N 收尾完成**。软件内部零阻塞问题。" | Inspect Phase 2 / Phase 2.N closeout docs and open issue labels.
- C047 | line 183 | 测试 | PENDING | "**基线审计（2026-05-08→09）**：DeepSeek v4 Pro 全量逐字审计 ~45,500 行，Codex GPT-5.5 + Gemini 3 Pro 三方交叉验证。结果：**0 Critical / 14 Warning / 8 Info**，评分 8.5/10。详细报告 `docs/memory/checkpoints/2026-05-08-baseline-audit.md`。" | Read baseline audit report; verify line count methodology, model evidence, counts, and score.
- C048 | line 185 | PR历史 | PENDING | "**14 Warning 全部闭合**（PR #739 + #740）：13 修复 + 1 记录为有意设计（SnapDrillUITests 命名冲突）。X5 Share Extension EXIF 临时保留记录为设计级考虑，后续排期。" | `gh pr view 739`; `gh pr view 740`; inspect warning closure checklist and X5 note.
- C049 | lines 187-191 | 外部状态 | PENDING | External blockers table: Apple developer account, #626 QuestionSplittingService, TestFlight Build 6 (#161) | `gh issue view 163 626 161`; verify Apple account and TestFlight dependencies with account owner.
- C050 | line 193 | 外部状态 | PENDING | "### Apple 账号阻塞链（用户主动延迟至 5 月缴费）" | Verify with account owner and issue #163 notes.
- C051 | line 195 | 外部状态 | PENDING | "Enrollment ID 83VZW7VJKK **已通过 Apple 审核**，$99 年费用户主动延迟到 2026-05。不是\"等 Apple 审批\"，而是\"等用户决定何时缴费开闸\"。所有下游功能随时可启动，节奏由用户控制。" | Verify in Apple Developer enrollment portal or owner-provided receipt; inspect #163 comments.
- C052 | lines 197-204 | 外部状态 | PENDING | Issue blocker table for #163, #479, #485, #486, #490, #161 | `for n in 163 479 485 486 490 161; do gh issue view $n --json state,title,body,comments; done`; verify App Store Connect/CloudKit/StoreKit prerequisites.
- C053 | lines 206-208 | 代码 | PENDING | "### 待清理 / - ~~113 个历史分支待清理~~ 已全部清理（本地 1 + 远程 2 = 纯净状态）" | `git branch --list`; `git branch -r`; compare expected counts.
- C054 | line 212 | 元信息 | PENDING | "> 决策通过 ADR 管理（`docs/decisions/`），此表为索引。" | `find docs/decisions -name '*.md' | sort`; inspect ADR references.
- C055 | lines 214-217 | 产品 | PENDING | ADR table: 2026-04-10 ATT authorization removal and Smart Paper/advanced analytics Hybrid decisions | `test -f docs/decisions/ADR-002-remove-att-authorization.md`; `test -f docs/decisions/ADR-001-smart-paper-analytics-pricing.md`; inspect ADR dates.
- C056 | lines 221-226 | 元信息 | PENDING | Collaboration discipline bullets for Xcode Review, STATUS freshness, Codex/Gemini复核, CI fatality, and Apple docs lookup | Inspect `.claude/rules/*.md`, workflow docs, and F-016/F-017/F-007 rules.
- C057 | line 230 | 产品 | PENDING | "- **Milestone 1**「v1.0 架构与文档基线」已关闭。Git tag `v1.0-doc-baseline`" | `gh api repos/:owner/:repo/milestones`; `git tag --list v1.0-doc-baseline`.

## Deep Dive Queue

1. Re-run current build/test/lint/docaudit to verify C006 and C014 against present code, because STATUS.md test numbers are time-sensitive.
2. Query GitHub for all PR/issue claims in C007, C015-C039, C048-C052, and C057; record state, merge date, and closing references.
3. Verify external Apple account claims C049-C052 with account-owner-visible evidence; local repository commands cannot prove them.
4. Audit private-path claims C017, C020, C028, C029, and C044 from `~/.claude/plans/*`; these are outside the repository and may be unavailable to collaborators.
5. Verify code architecture claims C008, C030, C041, C053 by reading `Packages` source and running targeted tests.
6. Reconcile file-count claims embedded in STATUS.md, especially 40/49/56 docs and 45,500 audited lines, with current repository inventories.

## Audit Discipline

- This step used `nl -ba STATUS.md` and read all 230 numbered lines; no grep sampling, no head/tail shortcut, no skipped STATUS.md sections.
- This correction step did not modify `STATUS.md`, Swift code, CI configuration, hidden governance files, or any existing project document other than this audit trail file.
- This audit trail remains the only file created for the zero-trust audit trail; this correction directly edits it in place.
- Claims are marked `PENDING` until their listed verification command or operation has been executed and recorded in a later audit pass.
- Private-path and external-account assertions require explicit evidence capture because they cannot be proven from the repository alone.

## Step 1 产品/决策文档审计

### Claim Ledger

Format: `ID | Claim | Audit conclusion | Evidence`.

- P001 | 核心价值链是 `采集 -> 管理 -> 导出/打印`，复习是可选留存层，智能组卷是导出/打印 Pro 增值延伸。 | MOSTLY_SUPPORTED_WITH_MARKETING_DRIFT | Vision 明确定义于 `product-vision.md:40`；Design `product-design.md:36`、Glossary `product-glossary.md:24`、Competitive `product-competitive-analysis.md:41-43` 一致。App Store 文案把复习、AI、智能组卷列为核心卖点 `appstore-metadata.md:48-57,90-99`，有对外叙事重心漂移风险。 |
- P002 | 免费层必须是完整单设备闭环，不能限制录入数量，付费只解锁增值体验。 | SUPPORTED | Vision `product-vision.md:123-127`，Business `product-business.md:15-20,49-63`，Requirements Won't Have `product-requirements.md:255-263`，ADR-001 约束 `ADR-001-smart-paper-analytics-pricing.md:13-17` 一致。 |
- P003 | 隐私定位是不注册、不收集直接身份信息，Analytics/Crashlytics opt-in；但不能绝对宣称零 PII/零个人数据。 | CONTRADICTED_BY_DOWNSTREAM_COPY | Vision 已限定 app-scoped identifier 属于 persistent identifier / pseudonymous personal data，避免绝对化 `product-vision.md:134-137`。Requirements 说默认不采集且 opt-in `product-requirements.md:187-192`。Onboarding 写“零个人信息收集” `product-onboarding.md:53-61`，App Store Review Notes 写 “No personal data is collected or transmitted” `appstore-metadata.md:115-120`，与 Vision 边界冲突。 |
- P004 | Vision 成功信号应由 Analytics 事件字典具体承接。 | NOT_FULLY_IMPLEMENTED | Vision 有 8 个成功信号 `product-vision.md:170-179`。Analytics 声称映射 8 个 `product-analytics.md:69-72`，但表内只有 6 行 `product-analytics.md:73-80`，遗漏有机增长结构和 Multi-Profile 可用性；事件名也与 Vision 不一致，例如 Vision 的 `app_launch`/`item_saved`/`capture_start`/`share_card_generated`/`print_triggered` 对不上 Analytics 的 `app_launched`/`capture_saved`/`camera_opened`，且缺少 `print_triggered`、`share_card_generated`。 |
- P005 | 首次录入效率发布前不设阈值，待发布后测定。 | CONTRADICTED_BY_JOURNEY | Vision 明确两项首次录入效率均“待发布后测定，暂不设阈值” `product-vision.md:170-173`。Journey 0 写“从进入采集页到保存成功控制在 30 秒内，符合愿景中的成功信号” `product-journeys.md:38-42`，把无阈值校准信号固化成 30 秒验收口径。 |
- P006 | `product-cases.md` 的验收规格应可追溯到真实用户旅程。 | NEEDS_REFERENCE_FIX | Cases 多处引用 `product-requirements.md「用户旅程」` `product-cases.md:55-60,101-105,137-140,174-178,212-218,254-259,291-296`，但 requirements 只是转指完整旅程 `product-requirements.md:374-377`；真实来源是 `product-journeys.md`。这是 dangling/错误层级引用。 |
- P007 | App Store 对外定位应与 COPPA/儿童隐私姿态一致，避免把产品说成面向儿童教育内容 App。 | CONTRADICTED_BY_APPSTORE_NOTES | Business 明确 SnapDrill 是 utility tool，不是 educational tool `product-business.md:174-181`，并要求避免 children/kids/儿童教育触发措辞 `product-business.md:190-195`。App Store Review Notes 写 “educational productivity tool” 且来源包括 textbooks/exams/homework `appstore-metadata.md:104-120`，与合规姿态存在审核口径冲突。 |
- P008 | App Store 元数据应只承诺已实现或明确可提交的功能。 | NEEDS_DEEP_DIVE | Requirements 对 AI 辅助拆题、手写体、图片处理增强、Word、iCloud 标有 PoC/阻塞 `product-requirements.md:49-58,241-253,320-325,358-367`。App Store 文案把“结构化文档识别”“AI 智能标注”“智能组卷”作为 Key Features `appstore-metadata.md:48-57,70-78,90-99`，其中结构化整页解析/表格解析没有在 requirements 中作为已实现能力闭环，需提交前逐项核实现状。 |
- P009 | ADR-001 Hybrid 决策已传播到产品文档。 | SUPPORTED | ADR-001 决策 `ADR-001-smart-paper-analytics-pricing.md:60-69` 已被 Design `product-design.md:290-327`、Business `product-business.md:30-47`、Glossary `product-glossary.md:77-80`、Cases `product-cases.md:300-337` 承接。 |
- P010 | ADR-002 删除 ATT 后，Analytics opt-in 与 Privacy Manifest/App 文案需一致。 | PARTIALLY_SUPPORTED_WITH_COPY_RISK | ADR-002 说不追踪、不收集 IDFA，Analytics/Crashlytics opt-in 由设置开关管理 `ADR-002-remove-att-authorization.md:30-40`；Requirements/Analytics 支持 opt-in `product-requirements.md:187-192`, `product-analytics.md:11-16`。但 App Store Review Notes 的 “No personal data is collected or transmitted” `appstore-metadata.md:119` 与 Vision 的 identifier 边界不一致。 |
- P011 | ADR-003 是已批准的历史决策记录，模板和文档状态应一致。 | INTERNALLY_INCONSISTENT | ADR-003 header 写“状态：已决策 | 决策者：PO” `ADR-003-yaml-frontmatter.md:7`，但“决策”段仍写“待 PO 批准” `ADR-003-yaml-frontmatter.md:79-82`；后果写 ADR-TEMPLATE 暂不做 frontmatter `ADR-003-yaml-frontmatter.md:106-113`，而 `ADR-TEMPLATE.md:1-4` 已有 YAML frontmatter。 |
- P012 | Workflow 对产品/决策文档变更传播有机制保障。 | SUPPORTED | Workflow 要求产品决策变更后 grep 受影响下游文档、同步 requirements/design/cases/glossary/business/architecture/api-reference、必要时 ADR、合并后 STATUS `docs/workflow.md:143-151`；DoD 也要求 requirements、api-reference、术语与 glossary 同步 `docs/workflow.md:89-95`。当前发现说明机制存在，但部分历史文案未被完全收敛。 |
- P013 | “图片是真相”术语应覆盖手动录入例外。 | NEEDS_CLARIFICATION | Design 明确 Manual edit 纯文本录入可无图，Image is Truth 的核心是 OCR 与原图冲突时以原图为准 `product-design.md:110-115`。Glossary 写“原图是题目数据的唯一真相源” `product-glossary.md:32-35`，对纯文本题目例外表述不足。 |

### Deep Dive Queue

1. 修正 Analytics 成功信号映射：补齐 Vision 8 个信号，统一事件名，决定是否新增 `print_triggered`、`share_card_generated`、Multi-Profile 泄漏/可用性事件，或把对应信号明确改为非 Analytics 来源。
2. 收敛隐私文案：Onboarding、App Store 描述、Review Notes 需避免“零个人信息收集 / No personal data”绝对化，改成“不收集姓名/手机号/学校等直接身份信息；使用数据和崩溃报告默认关闭、用户 opt-in 后才发送匿名/假名事件”一类与 Vision/Compliance 一致的口径。
3. 提交 App Store 前重审 ASO/Review Notes：`Education` 主分类、`educational productivity tool`、`textbooks/exams/homework`、`提分`、`题库`、AI/结构化识别卖点都需对照 COPPA 姿态和当前实现状态。
4. 修复 `product-cases.md` 的旅程引用：将 `product-requirements.md「用户旅程」` 改为直接引用 `product-journeys.md` 对应旅程，避免验收来源层级错误。
5. 校准 Journey 0 的 30 秒指标：要么在 Vision 中恢复为明确阈值并同步成功信号，要么把 Journey 0 改为“目标方向/待发布后测定”，不把它声称为 Vision 既有阈值。
6. 对 `appstore-metadata.md` 中“结构化文档识别”“AI 智能标注”“智能组卷”等卖点逐项核实现状；未实现或未准备提交的能力不得进入首版对外元数据。
7. 清理 ADR-003 的历史残留：`待 PO 批准` 与已决策状态冲突，ADR-TEMPLATE frontmatter 状态也需要同步为已落地事实。
8. 澄清 Glossary 的 Image is Truth：补一句“纯文本手动录入无图片时，用户输入文本为真相源”，与 Design 例外一致。

### Audit Conclusion

产品/决策文档的核心产品架构总体自洽：主链路“采集 -> 管理 -> 导出/打印”、免费完整单设备闭环、Pro 作为 iCloud/智能增强增值层、复习作为可选留存层，在 Vision、Design、Requirements、Business、Glossary、Competitive 和 ADR-001 之间大体一致。

主要风险不在核心产品方向，而在下游可执行/对外文案的口径漂移：Analytics 没有兑现 Vision 的成功信号，隐私文案出现绝对化，App Store 元数据同时存在合规定位和功能实现状态风险，Cases 的旅程引用层级错误，ADR-003 留有历史状态残留。建议先收敛这些文案和映射问题，再进入 App Store 提交或把这些文档作为 Issue 验收依据。

## Step 2 技术规格文档审计

### Claim Ledger

Format: `ID | Claim | Audit conclusion | Evidence`.

- T001 | 技术文档的读取范围完整覆盖 `docs/tech/` 六个文件。 | READ_VERIFIED | 本步骤对 `api-reference.md` 881 行、`architecture.md` 207 行、`compliance.md` 239 行、`deployment.md` 131 行、`non-functional-requirements.md` 85 行、`release-checklist.md` 138 行均执行并读取了 `nl -ba <path>` 输出；主 File Coverage Ledger 已同步为 READ_VERIFIED。 |
- T002 | Remote Config 已移除、FeatureFlags 改为本地 UserDefaults 的文档口径一致。 | DOC_LEVEL_SUPPORTED; STEP5_CODE_VERIFICATION_REQUIRED | Architecture 写 Remote Config 已移除、FeatureFlags 仅读 UserDefaults `docs/tech/architecture.md:71-72`，Infrastructure 仅隔离 Analytics + Crashlytics `docs/tech/architecture.md:153-155`；Compliance 的 SDK 表和八方审计决策也写 Remote Config 已移除 `docs/tech/compliance.md:191-201,209-215`。是否已从代码和依赖中完全移除需 Step 5 验证。 |
- T003 | Analytics/Crashlytics 默认不采集、用户 opt-in 后启用的隐私口径在技术文档内一致。 | DOC_LEVEL_SUPPORTED; STEP5_CODE_VERIFICATION_REQUIRED | Compliance 的数据收集表和默认说明写首次启动默认不采集、设置页 opt-in `docs/tech/compliance.md:16-31,52-58`；GDPR/PIPL 表写 plist 预禁用与用户 opt-in/out `docs/tech/compliance.md:163-170`；Deployment 监控章节重复该口径 `docs/tech/deployment.md:98-111`；NFR 也要求两个独立开关 `docs/tech/non-functional-requirements.md:44-54`。plist、FirebaseBootstrap、设置页开关和持久化需 Step 5 验证。 |
- T004 | COPPA/儿童隐私评估结论在文档中有明确完成状态，但证据留存未闭环。 | DOC_LEVEL_EVIDENCE_GAP | Compliance 写 FTC 2025 Final Rule 截止日为 2026-04-22、合规状态已完成且最近复核 2026-04-10 `docs/tech/compliance.md:107-117`，又列出截图证据需留存到 `docs/tech/evidence/coppa/`，但 6 项仍是未勾选 checklist `docs/tech/compliance.md:126-135`。推断：在仓库证据层面，完成状态与证据留存状态尚未闭环。 |
- T005 | API Reference 是具体公开接口清单，绝大多数条目不能仅凭文档确认，必须与 Swift 声明逐项比对。 | STEP5_CODE_VERIFICATION_REQUIRED | 文档列出 Core Protocol/Service/类型 `docs/tech/api-reference.md:11-371`、DataExecutor/Repository/Model/Profile/Backup `docs/tech/api-reference.md:373-642`、UI/Infrastructure/错误类型 `docs/tech/api-reference.md:644-813`、2026-04-10 新增 API `docs/tech/api-reference.md:817-881`。这些是代码事实声明，需 Step 5 对照 Package 源码和访问控制。 |
- T006 | `ProfileError` 在 API Reference 内部存在同文档不一致。 | DOC_LEVEL_INCONSISTENT; STEP5_CODE_VERIFICATION_REQUIRED | `ProfileManager` 段落列出 `ProfileError.cannotDeleteLastProfile` 和 `ProfileError.switchBlocked(reason:)` `docs/tech/api-reference.md:616-639`，但错误类型汇总只列 `cannotDeleteLastProfile` `docs/tech/api-reference.md:797-799`。Step 5 需确认源码真实 public API，并修正文档其中一处。 |
- T007 | 架构文档的模块数量、依赖方向、Core 零外部依赖、Firebase 隔离层、测试方式等均属于实现结构声明。 | STEP5_CODE_VERIFICATION_REQUIRED | Architecture 的总览和依赖方向 `docs/tech/architecture.md:11-42`、模块职责 `docs/tech/architecture.md:107-155`、关键设计决策 `docs/tech/architecture.md:184-195`、测试架构和 `swift test` 不可用声明 `docs/tech/architecture.md:198-207` 都需要读取 Package.swift、Xcode project/test plan 和 CI 配置确认。 |
- T008 | DI、Repository 数据流、通知刷新机制和 save/rollback 规则在文档中描述具体，属于代码行为声明。 | STEP5_CODE_VERIFICATION_REQUIRED | Architecture 描述 DependencyContainer、Environment keys、Repository 数据流、Notification 发布/监听方和错误处理策略 `docs/tech/architecture.md:46-104`；API Reference 也列出 ServiceContainer、RepositoryContainer 与 Repository API `docs/tech/api-reference.md:108-117,396-524`。需 Step 5 对照实现和测试覆盖。 |
- T009 | Multi-Profile/Vault、切换保护、per-profile UserDefaults、TipKit 隔离在技术文档内互相呼应，但需要源码与 UI 流程验证。 | DOC_LEVEL_SUPPORTED; STEP5_CODE_VERIFICATION_REQUIRED | API Reference 列 `ProfileManager` public 属性/方法和 `perProfileKeys` 说明 `docs/tech/api-reference.md:616-642`；Architecture 写 Vault 模式、切换保护、per-profile UserDefaults 与 TipKit 隔离 `docs/tech/architecture.md:159-168`；Release Checklist 要求创建、切换、隔离、持久化、全 Profile 备份恢复 `docs/tech/release-checklist.md:99-105`。 |
- T010 | Soft Delete + Undo 的设计、API 与调用方声明需要代码验证。 | STEP5_CODE_VERIFICATION_REQUIRED | Architecture 写 `DeletionScheduler` 管理 5 秒撤销窗口且 `LibraryViewModel` 是调用方 `docs/tech/architecture.md:171-180`；API Reference 列 `DeletionScheduler` public API 并说明 5 秒撤销窗口 `docs/tech/api-reference.md:817-829`；NFR 可靠性也要求 5 秒撤销窗口 `docs/tech/non-functional-requirements.md:77-84`。 |
- T011 | OCR、整页文档识别、AI 标注/拆题是实现能力或 PoC 状态声明，不应在 Step 2 直接判定为已实现。 | STEP5_CODE_VERIFICATION_REQUIRED | API Reference 描述 FoundationModels 的 ContentTagging、QuestionSplitting PoC、Vision OCR 与 RecognizeDocumentsRequest `docs/tech/api-reference.md:44-96,221-249`；PoC 状态写骨架已实现但需 10 份真实试卷真机验证 `docs/tech/api-reference.md:59-73`；Release Checklist 要求拍照、相册、OCR、手动修正和草稿恢复流程 `docs/tech/release-checklist.md:27-40`；NFR 要求 OCR < 2 秒且图片不上传云端 `docs/tech/non-functional-requirements.md:11-23,44-54`。 |
- T012 | 版本号单一来源、CI/CD 命令、TestFlight/App Store 流程和环境配置是代码/配置/外部账号混合声明。 | STEP5_CODE_OR_EXTERNAL_VERIFICATION_REQUIRED | Deployment 写版本号只改 `Configs/Shared.xcconfig`，当前 `MARKETING_VERSION = 1.1.0`、`CURRENT_PROJECT_VERSION = 5` `docs/tech/deployment.md:12-29`；CI 使用 `.github/workflows/ci.yml`、AllTests test plan 和 iPhone 17 simulator `docs/tech/deployment.md:32-54`；Release Checklist 要求 Build Number 更新且只改 Shared.xcconfig `docs/tech/release-checklist.md:129-133`。Xcode archive/App Store Connect 事项 `docs/tech/deployment.md:63-95` 需外部或人工证据。 |
- T013 | NFR 的性能、内存、存储、兼容性、无障碍、可靠性阈值是验收标准，不是 Step 2 可从文档直接验证的事实。 | ACCEPTANCE_CRITERIA; STEP5_TEST_OR_MANUAL_VERIFICATION_REQUIRED | NFR 给出冷启动、OCR、列表、搜索、PDF、打印、备份、滚动帧率指标 `docs/tech/non-functional-requirements.md:11-23`，内存上限 `docs/tech/non-functional-requirements.md:24-32`，存储基准 `docs/tech/non-functional-requirements.md:33-42`，兼容性/无障碍/可靠性要求 `docs/tech/non-functional-requirements.md:56-85`。需 Instruments、UI 测试、真机/模拟器和手工验收。 |
- T014 | 备份/恢复、JSON/CSV 导出、数据生命周期与本地删除语义在技术文档内一致，但仍需功能验证。 | DOC_LEVEL_SUPPORTED; STEP5_CODE_VERIFICATION_REQUIRED | Compliance 写 JSON/CSV 数据可携带、删除权、本地生命周期、zip 备份和卸载删除 `docs/tech/compliance.md:161-187`；API Reference 列 BackupService 方法 `docs/tech/api-reference.md:592-613`；Release Checklist 要求备份、恢复、进度、JSON/CSV 导出可打开且含所有字段 `docs/tech/release-checklist.md:107-113`。 |
- T015 | Share Extension 架构声明需要 entitlement、URL scheme 和轻量文件 I/O 代码验证。 | STEP5_CODE_VERIFICATION_REQUIRED | Architecture 写 Share Extension 通过 App Groups 共享数据、保存到共享容器、URL Scheme 唤起主 App、不依赖 SnapDrillData `docs/tech/architecture.md:36-39`；Release Checklist 没有专门覆盖 Share Extension 流程，推断 Step 5 应补源代码/entitlement 检查。 |

### Deep Dive Queue

1. 对照 API Reference 全量签名与源码：从 `docs/tech/api-reference.md:11-371,373-642,644-813,817-881` 出发，核查 `Packages/SnapDrillCore`、`Packages/SnapDrillData`、`Packages/SnapDrillUI`、`Packages/SnapDrillInfrastructure`、`Packages/SnapDrillFeatures` 的 public/internal 访问控制、方法签名、默认参数和错误类型。
2. 解决 `ProfileError` 文档内冲突：以 `docs/tech/api-reference.md:616-639,797-799` 为证据，读取 `Packages/SnapDrillData/Sources/SnapDrillData/ProfileManager.swift` 和相关调用点，确认 `switchBlocked(reason:)` 是否真实存在且是否 public，并修正文档。
3. 验证 Remote Config 移除和 FeatureFlags 本地化：从 `docs/tech/architecture.md:71-72,153-155`、`docs/tech/compliance.md:191-201,209-215` 出发，检查 `Packages/SnapDrillInfrastructure`、`Packages/SnapDrillCore/Sources/SnapDrillCore/Support/AppConfiguration.swift`、`SnapDrill/App/Composition/DependencyContainer.swift`、Package 依赖和 Firebase 配置中是否仍有 Remote Config 初始化或依赖。
4. 验证 Analytics/Crashlytics 默认关闭与 opt-in：从 `docs/tech/compliance.md:16-31,52-58,163-170`、`docs/tech/deployment.md:98-111`、`docs/tech/non-functional-requirements.md:44-54` 出发，检查 `GoogleService-Info.plist`、`PrivacyInfo.xcprivacy`、`FirebaseBootstrap`、`AppConfiguration.FeatureFlags`、Settings 开关持久化和启动时配置顺序。
5. 补 COPPA/隐私证据闭环：从 `docs/tech/compliance.md:107-117,126-135` 出发，确认 `docs/tech/evidence/coppa/` 是否存在且包含 App Store 年龄分级、Privacy Manifest、GoogleService-Info、设置页开关、首页、隐私政策截图；缺失项应作为非代码证据任务处理。
6. 验证模块边界和依赖方向：从 `docs/tech/architecture.md:11-42,107-155,184-195` 出发，读取各 `Package.swift`、Xcode project、target dependencies 和 import 列表，确认 5 个 Feature Target、Core 零外部依赖、Firebase 仅在 Infrastructure、Share Extension 不依赖 SnapDrillData。
7. 验证 DI、Environment、Repository 数据流和通知刷新：从 `docs/tech/architecture.md:46-104`、`docs/tech/api-reference.md:108-117,396-524` 出发，检查 `DependencyContainer`、Environment keys、Repository save/rollback、`ReviewDataNotification` 发布方/监听方，并补/更新测试覆盖。
8. 验证 Multi-Profile/Vault 行为：从 `docs/tech/api-reference.md:616-642`、`docs/tech/architecture.md:159-168`、`docs/tech/release-checklist.md:99-105` 出发，检查 `ProfileManager`、`DataExecutor`、`ImageStorage`、`AppActivityTracker`、Settings/Dashboard Profile UI、备份恢复和 TipKit Profile 状态。
9. 验证 Soft Delete + Undo：从 `docs/tech/architecture.md:171-180`、`docs/tech/api-reference.md:817-829`、`docs/tech/non-functional-requirements.md:77-84` 出发，检查 `DeletionScheduler`、`LibraryViewModel`、后台立即提交逻辑、批量删除复用和 5 秒窗口测试。
10. 验证 OCR/AI 能力和 PoC 状态：从 `docs/tech/api-reference.md:44-96,221-249`、`docs/tech/release-checklist.md:27-40`、`docs/tech/non-functional-requirements.md:11-23,44-54` 出发，检查 `OCRService`、`ContentTaggingService`、`QuestionSplittingService`、FoundationModels 可用性分支、RecognizeDocumentsRequest iOS 26 gating、10 份真实试卷真机评估证据。
11. 验证版本、CI/CD 和测试架构：从 `docs/tech/deployment.md:12-54,124-131`、`docs/tech/release-checklist.md:129-133`、`docs/tech/architecture.md:198-207` 出发，检查 `Configs/Shared.xcconfig`、`.github/workflows/ci.yml`、`AllTests.xctestplan`、test targets、iPhone 17 destination、`swift test` 不可用声明和单一 `GoogleService-Info.plist`。
12. 验证 NFR 阈值：从 `docs/tech/non-functional-requirements.md:11-85` 出发，规划 Instruments/ETTrace、内存图、UI 自动化和手工验收，覆盖启动、OCR、列表、搜索、PDF、打印、备份、滚动、内存、存储、iPad 分屏、Dynamic Type、VoiceOver、CSV 注入和崩溃率。
13. 验证备份/恢复、JSON/CSV 导出和数据生命周期：从 `docs/tech/compliance.md:161-187`、`docs/tech/api-reference.md:592-613`、`docs/tech/release-checklist.md:107-113` 出发，检查 `BackupService`、DTO schema/version、图片恢复路径、隐私设置页导出入口、CSV 注入防护、卸载数据丢失提醒和恢复前自动备份。
14. 验证 Release Checklist 各功能路径：从 `docs/tech/release-checklist.md:19-126` 出发，按启动/首屏、Capture、Library、Review、Dashboard、Settings、Multi-Profile、数据同步、引导提醒、稳定性建立真机或模拟器验收记录；这些 checklist 项均为手工/自动化验收声明，Step 2 不直接判定通过。
15. 验证 Share Extension：从 `docs/tech/architecture.md:36-39` 出发，检查 `SnapDrillShare` 源码、App Groups entitlement、共享容器写入、URL scheme deep link、主 App 接收路径和 SnapDrillData 依赖缺失性；Release Checklist 未覆盖该路径，建议补验收项。

### Audit Conclusion

Step 2 已完成六个 `docs/tech/` 文件的逐行读取和主 File Coverage Ledger 更新。文档层面，技术规格总体围绕本地优先、Firebase opt-in、Remote Config 移除、模块化架构、多 Profile、备份/导出和发版流程形成了相对一致的叙事。

本步骤不能把 API、架构、隐私开关、CI、NFR 或发版 checklist 判定为实现正确；这些都已被转入 Deep Dive Queue，等待 Step 5 读取源码、配置、测试计划、隐私清单、entitlement 和必要的外部证据。当前已确认的文档级残留风险是：`ProfileError` 在 API Reference 内部不一致，COPPA 合规状态与未勾选证据清单之间存在证据闭环缺口，Share Extension 缺少 release checklist 覆盖项。

## Step 3 记忆/历史文档审计

### Claim Ledger

Format: `ID | Claim | Audit conclusion | Evidence`.

- M001 | Step 3 范围已覆盖 `docs/memory/` 根级 5 个文件和 in-scope checkpoint 文件；当前审计 trail 已按要求排除。 | READ_VERIFIED | 已用 `nl -ba` 逐行读取 `docs/memory/README.md`、`feedback.md`、`decisions.md`、`handoff.md`、`codex-handoff-20260508.md`，以及除当前 `2026-05-11-zero-trust-audit-trail.md` 外的 checkpoint 文件；主 File Coverage Ledger 已把这些文件标为 READ_VERIFIED，并把当前 trail 标为 OUT_OF_SCOPE。 |
- M002 | Memory README 的职责边界与部分 handoff/checkpoint 的实际写法存在张力：README 说 memory 不定义产品/技术事实，但 handoff/checkpoint 内包含大量当前技术状态断言。 | DOC_LEVEL_TENSION | README 明确“本目录仅记录执行状态与过程决策，不定义产品事实、技术事实或正式裁决” `docs/memory/README.md:7-9`；但 handoff 写 DataExecutor、Repository、ProfileManager、测试数、CI、版本号和架构要点 `docs/memory/handoff.md:51-60,76-85,111-126`，Codex handoff 也写 DataExecutor 使用模式和架构约束 `docs/memory/codex-handoff-20260508.md:33-47,79-102`。推断：这些应视为 snapshot claim，不能替代代码验证。 |
- M003 | STATUS.md 关于 D-003 抽仓决策的引用目标存在且包含所声称内容。 | SUPPORTED_BY_MEMORY_DOC | STATUS.md 写 D-003 抽仓决策入 `docs/memory/decisions.md` `STATUS.md:14`；`decisions.md` 确有 D-003 “抽出 agent-harness 独立仓库”，含战略锚、三方共识、Phase D 落地和下一步 `docs/memory/decisions.md:33-62`。 |
- M004 | STATUS.md 关于基线审计报告 `2026-05-08-baseline-audit.md` 的引用目标存在，且报告支持 0 Critical / 14 Warning / 8 Info、8.5/10、三方参与和约 45,500 行范围；但 handoff 同一主题写成 0 Critical / 3 Warning / 8 Info。 | STATUS_REFERENCE_SUPPORTED; MEMORY_INTERNAL_CONTRADICTION | STATUS.md 引用基线审计报告并声称 0/14/8、8.5/10 `STATUS.md:15,183`；报告本身列 DeepSeek/Codex/Gemini `docs/memory/checkpoints/2026-05-08-baseline-audit.md:14-20`、约 45,500 行 `docs/memory/checkpoints/2026-05-08-baseline-audit.md:22-29`、0/14/8 和 8.5/10 `docs/memory/checkpoints/2026-05-08-baseline-audit.md:31-33`。但 handoff 的基线审计段写 “0 Critical / 3 Warning / 8 Info” `docs/memory/handoff.md:120-126`，与报告和 STATUS 不一致。 |
- M005 | STATUS.md 的“下次接手”链路引用存在，且 handoff 顶部确有 boot 序列；Phase E closeout 也存在并记录 Phase E 收官。 | SUPPORTED | STATUS.md 写“读 `docs/memory/handoff.md` 顶部 → `docs/memory/checkpoints/2026-04-22-phase-e-closeout.md`” `STATUS.md:19`；handoff 顶部包含 Boot 序列 `docs/memory/handoff.md:18-32`；Phase E closeout 记录 Phase E 反哺机制、public repo、Done 和 Next `docs/memory/checkpoints/2026-04-22-phase-e-closeout.md:8-24,94-121`。 |
- M006 | checkpoint 之间大体按时间链承接 Open/Next，但不是所有 “Next” 都代表仍待办；后续 checkpoint 会关闭或改写前序 Open 项。 | SUPPORTED_WITH_STALE_SNAPSHOT_RISK | P2 Next 指向 P3 `docs/memory/checkpoints/2026-04-17-phase4-p2-sprint.md:42-45`；P3 Open 留 #626 和 #666 等 `docs/memory/checkpoints/2026-04-17-phase4-p3-sprint.md:27-31`；tech-debt checkpoint 关闭 #638/#666 方案 A、保留 #665 和 LocalizationKeys 拆分 `docs/memory/checkpoints/2026-04-17-phase4-tech-debt.md:14-47`；Stage C 后写 Harness 三阶段无紧接后续任务 `docs/memory/checkpoints/2026-04-19-harness-stage-c.md:45-57`。推断：checkpoint 是历史快照，Open/Next 必须按日期顺序解释。 |
- M007 | feedback.md 中的 F-005/F-008/F-016 等纪律并非历史上一直被遵守；违规被 checkpoint 明确记录，并在后续规则中回流。 | SUPPORTED | feedback.md 的 F-005 要求完成前必须对抗性审查，Auto mode 不豁免 `docs/memory/feedback.md:61-83`；Stage A+B checkpoint 记录“Claude 连续推 5 个 PR 没做 Codex/Gemini 对抗性审查”且本次未落地修复 `docs/memory/checkpoints/2026-04-19-harness-stage-a-b.md:48-56`；Phase C closeout 记录 PR #715 将 F-020 合并入 F-005 Auto mode 强化段 `docs/memory/checkpoints/2026-04-22-phase-c-closeout.md:14-22`。 |
- M008 | checkpoint 数量和体系边界在 2026-05-09 之后已经漂移；旧审计 Step 0/Step 4 的 “checkpoints(10)” 不应再作为当前事实。 | INFERENCE_FROM_CURRENT_INVENTORY_AND_READ_TEXT | Step 0 写状态与记忆体系含 checkpoints(10) `docs/memory/checkpoints/2026-05-09-audit-step-0-boundary.md:31-44`；Step 4 写 scope 为 checkpoints(10)，并称 checkpoints 目录 10 个文件 `docs/memory/checkpoints/2026-05-09-audit-step-4-state-memory.md:14-17,32-37`。本次 Step 3 当前 inventory 读到更多 checkpoint 文件，故这些数字是历史快照而非当前 ledger 事实。 |
- M009 | 2026-05-09 系列审计 checkpoint 的 “Next” 指针顺序不自洽，不能作为可靠执行路线图。 | DOC_LEVEL_INCONSISTENT | Step 0 Next 写进入 Step 6 `docs/memory/checkpoints/2026-05-09-audit-step-0-boundary.md:91-93`；Step 1 Next 写 Step 7 `docs/memory/checkpoints/2026-05-09-audit-step-1-product.md:124-126`；Step 2 Next 也写 Step 7 `docs/memory/checkpoints/2026-05-09-audit-step-2-verification.md:90-92`；Step 5 写全部 7 步完成 `docs/memory/checkpoints/2026-05-09-audit-step-5-governance.md:92-94`；Step 6 Next 写 Step 2 `docs/memory/checkpoints/2026-05-09-audit-step-6-pipeline.md:98-100`；Step 7 Next 写 Step 3 `docs/memory/checkpoints/2026-05-09-audit-step-7-dependencies.md:79-81`。 |
- M010 | `feedback.md` 的退役 F 规则墓碑机制与 checkpoints 中的历史引用保留需求一致。 | SUPPORTED | feedback.md 对 F-003/F-009/F-010/F-015/F-020 均保留编号墓碑并说明目标文档/合并去向 `docs/memory/feedback.md:37-45,147-162,215-220,292-297`；Phase C closeout 明确“墓碑 > 物理删除”，避免历史 checkpoints/handoff/api-pitfalls/STATUS 引用断链 `docs/memory/checkpoints/2026-04-22-phase-c-closeout.md:43-52,92-97`。 |
- M011 | 多个 memory 文件依赖私有路径 `~/.claude/plans/*` 作为完整证据来源，仓库内无法独立复验。 | PRIVATE_EVIDENCE_DEPENDENCY | decisions.md 的 D-003 完整 consensus 归档在 `~/.claude/plans/phase-de-consensus-20260422.md` `docs/memory/decisions.md:60-62`；P2/P3/Harness/Phase C/D 等 checkpoint 多处把 plan 或 consensus 放在 `~/.claude/plans/*` `docs/memory/checkpoints/2026-04-17-phase4-p2-sprint.md:10-13`, `docs/memory/checkpoints/2026-04-17-phase4-p3-sprint.md:10-13`, `docs/memory/checkpoints/2026-04-19-harness-stage-a-b.md:10-13`, `docs/memory/checkpoints/2026-04-22-phase-c-closeout.md:24-31`。 |
- M012 | Baseline/归零审计历史文件存在不同 scope 与计数口径，后续引用必须带日期和范围。 | SUPPORTED_WITH_SCOPE_DRIFT | baseline audit 写 Markdown 56、Swift 218、配置约 15，总约 290/45,500 行 `docs/memory/checkpoints/2026-05-08-baseline-audit.md:22-29`；Step 0 写 git 跟踪 440 文件、七体系分布 `docs/memory/checkpoints/2026-05-09-audit-step-0-boundary.md:14-44`；zero-trust closeout 写源代码 176 Swift 文件逐行阅读 `docs/memory/checkpoints/2026-05-11-zero-trust-audit-closeout.md:100-114`。这些不是同一 inventory 口径。 |
- M013 | zero-trust closeout 自身承认首次审计存在代码层过度断言和未覆盖项，因此不能把其“收官”当作无条件全量证明。 | SUPPORTED | closeout 记录 Codex 发现 S0 原子性问题、Claude 首次审计评分 4/10、修复后才验收 `docs/memory/checkpoints/2026-05-11-zero-trust-audit-closeout.md:116-139`；未完成工作包括 420 tests 逐条执行、NFR 50+ 声明、skills/hooks 深度审计、Share Extension E2E、性能/安全/依赖扫描等 `docs/memory/checkpoints/2026-05-11-zero-trust-audit-closeout.md:142-157`。 |
- M014 | 2026-05-09 product vision trace checkpoint 的若干“代码验证”是摘要式结论，按 feedback.md 的 F-006/F-012 标准仍需在后续代码审计中逐项深读。 | STEP5_CODE_VERIFICATION_REQUIRED | trace checkpoint 声称 Vision 原则、否定、用户画像、成功信号均被代码承接 `docs/memory/checkpoints/2026-05-09-audit-trace-vision-downstream.md:20-80`，但 feedback.md 要求事实性声明不仅 grep，还要读源码上下文确认行为，且禁止抽查后声称全量准确 `docs/memory/feedback.md:87-96,177-186`。 |
- M015 | architecture verification checkpoint 声称 architecture.md “无可挑剔/可以完全信任”，该结论是历史验证摘要；在当前零信任审计中仍需保持逐 claim 验证姿态。 | STEP5_CODE_VERIFICATION_REQUIRED | architecture verification 写模块结构、依赖方向、DI、状态管理均代码验证，并给 9.5/10 `docs/memory/checkpoints/2026-05-11-audit-architecture-verification.md:14-69`，结尾称 architecture.md 是“少数可以完全信任的文档” `docs/memory/checkpoints/2026-05-11-audit-architecture-verification.md:71-73`。这与 F-006/F-012 的深读和全量要求不冲突，但不能替代当前 Step 5 代码核验。 |

### Deep Dive Queue

1. 统一基线审计数字口径：以 `STATUS.md:15,183`、`docs/memory/checkpoints/2026-05-08-baseline-audit.md:14-33,125-141`、`docs/memory/handoff.md:120-126` 为起点，决定 handoff 的 0/3/8 是否应改为 0/14/8 或补“初版摘要/闭合后摘要”说明。
2. 刷新状态与记忆体系 inventory：以 `docs/memory/checkpoints/2026-05-09-audit-step-0-boundary.md:31-44`、`docs/memory/checkpoints/2026-05-09-audit-step-4-state-memory.md:14-17,32-37` 为起点，重新计算当前 `docs/memory/` 文件数和 checkpoint 数，避免旧的 checkpoints(10) 继续传播。
3. 修复或注记 2026-05-09 审计 step 的 Next 顺序错乱：以 `audit-step-0-boundary.md:91-93`、`audit-step-1-product.md:124-126`、`audit-step-2-verification.md:90-92`、`audit-step-5-governance.md:92-94`、`audit-step-6-pipeline.md:98-100`、`audit-step-7-dependencies.md:79-81` 为证据，决定是修正文案还是标为历史执行顺序非线性。
4. 私有路径证据归档策略：以 `docs/memory/decisions.md:60-62` 和多个 checkpoint 的 `~/.claude/plans/*` 引用为起点，决定是否将关键 consensus 摘要迁入仓库，或在文档中统一标注“私有路径不可由协作者复验”。
5. feedback 纪律遵守审计：以 F-005/F-006/F-008/F-011/F-012/F-016/F-017/F-018 `docs/memory/feedback.md:61-83,87-96,135-173,177-186,224-250,254-268` 为规则源，逐个后续 checkpoint/PR 检查是否还有未回流违规，而不是只依赖 checkpoint 自述。
6. 复核历史 “Open/Next” 是否已关闭：从 P3 的 #626/#666 `docs/memory/checkpoints/2026-04-17-phase4-p3-sprint.md:27-31`、tech-debt 的 #665/#637/LocalizationKeys `docs/memory/checkpoints/2026-04-17-phase4-tech-debt.md:21-47`、Phase D/E 的 Phase F/第二 consumer `docs/memory/checkpoints/2026-04-22-phase-d-closeout.md:73-83,115-135` 和 `docs/memory/checkpoints/2026-04-22-phase-e-closeout.md:64-73,94-117` 建立闭合状态表。
7. 将 memory snapshot claim 与代码/配置事实拆开：handoff/codex-handoff 的 DataExecutor、tests、CI、版本号、环境和架构断言 `docs/memory/handoff.md:51-60,76-85,111-126`、`docs/memory/codex-handoff-20260508.md:33-47,79-102` 全部转入 Step 5 代码/配置验证，不作为 Step 3 直接事实。
8. 复核 zero-trust closeout 未覆盖清单是否已补：以 `docs/memory/checkpoints/2026-05-11-zero-trust-audit-closeout.md:142-157` 为待办源，确认 420 tests 逐条审计、NFR、skills/hooks、Share Extension E2E、性能、安全、依赖 CVE、本地化逐 key 是否已有后续证据。

### 结论

Step 3 已完成 `docs/memory/` 根级 5 个文件和 in-scope checkpoint 文件的逐行读取；当前正在编辑的 audit trail 已按要求标为 OUT_OF_SCOPE。STATUS.md 指向的核心 memory 引用大多存在且包含相应主题，尤其 D-003、基线审计报告、handoff boot 链和 Phase E closeout。

主要残留风险是记忆层的“历史快照被当成当前事实”：handoff 与 baseline 报告的 warning 数字不一致，旧审计 checkpoint 的文件数量和 Next 顺序已经漂移，多个关键结论依赖私有 `~/.claude/plans/*`，且 closeout/architecture verification 等历史高分结论不能替代当前零信任 Step 5 的源码和配置核验。

## Step 4a: Core Engineering Principles Audit

### Scope And Read Trail

Group A full reads were performed with `nl -ba`:

- `docs/standards/engineering.md` — 139 lines.
- `docs/standards/coding.md` — 100 lines.
- `docs/standards/testing.md` — 111 lines.
- `docs/standards/collaboration.md` — 140 lines.
- `docs/standards/shared-constraints.md` — 19 lines.

Group B scan command used `.claude/rules/` source-reference search for `docs/standards/(engineering|coding|testing|collaboration|shared-constraints).md`. Direct source stubs exist for all five principle docs; for the requested seven-file scope, the two governance pointer files audited as Group B are:

- `.claude/rules/collaboration.md` — routes to `docs/standards/collaboration.md`.
- `.claude/rules/shared-constraints.md` — routes to `docs/standards/shared-constraints.md`.

The scan also found direct stubs for `.claude/rules/engineering.md`, `.claude/rules/coding.md`, and `.claude/rules/testing.md`; those three are noted here because they route to Group A docs, but they are outside this Step 4a seven-file ledger update.

### Group A Summaries And Issues

| File | Summary | Issues |
|---|---|---|
| `docs/standards/engineering.md` | Defines seven ordered engineering principles plus a higher-order safety/privacy/compliance/user-loss override. It explicitly points implementation specifics to coding, testing, architecture, NFR, compliance, workflow, product, and ADR docs. | No internal contradiction found. Principles 4, 5, and 6 contain implementation-structure claims or defer to implementation docs, so their actual enforcement needs Step 5 source/config validation. [NEEDS STEP 5 CODE VERIFICATION] |
| `docs/standards/coding.md` | Converts engineering principles into Swift patterns: View/ViewModel DI, default MainActor isolation, Task/NotificationCenter patterns, typed throws guidance, file organization, value types, and forbidden constructs. | Several statements are concrete codebase facts or count claims: default isolation, current `nonisolated(unsafe)` count, build-for-testing requirement, SwiftLint force unwrap policy, and architecture bans. [NEEDS STEP 5 CODE VERIFICATION] |
| `docs/standards/testing.md` | Defines testing layers, isolation, compiler-vs-runtime responsibility split, xcodebuild commands, SwiftData/XCUITest/snapshot workflows, and anti-flaky snapshot rules. | Commands, test-plan membership, simulator target, snapshot test counts, CI artifact behavior, and XCUITest launch behavior are implementation/config claims. [NEEDS STEP 5 CODE VERIFICATION] |
| `docs/standards/collaboration.md` | Defines multi-agent workflow, cross-audit protocol, AI-specific review anti-patterns, scoring dimensions, and human/evidence-based conflict resolution. | No contradiction found against shared constraints. Tool/model/version names and `.claude/skills/cross-audit-consensus/SKILL.md` SSOT path are environment/governance facts that need separate verification if treated as current truth. |
| `docs/standards/shared-constraints.md` | Provides canonical delegation-prompt constraints: product positioning, engineering philosophy, build/lint gates, data safety, development discipline, severity order, and stack baseline. | Build/lint gates, local-data guarantees, opt-in telemetry behavior, and stack baseline are implementation/config claims. [NEEDS STEP 5 CODE VERIFICATION] |

### Group B Routing Verification

| Pointer file | Expected source | Evidence | Routing correct? |
|---|---|---|---|
| `.claude/rules/collaboration.md` | `docs/standards/collaboration.md` | Pointer declares `<!-- 规范源：docs/standards/collaboration.md -->` and instructs agents to read that source `.claude/rules/collaboration.md:7-8`. | yes |
| `.claude/rules/shared-constraints.md` | `docs/standards/shared-constraints.md` | Pointer declares `<!-- 规范源：docs/standards/shared-constraints.md -->` and instructs agents to read that source `.claude/rules/shared-constraints.md:7-8`. | yes |

### Checks

- Routing correctness: PASS. Both audited Group B pointer files route to the expected `docs/standards/` source files `.claude/rules/collaboration.md:7-8`, `.claude/rules/shared-constraints.md:7-8`.
- Cross-file consistency: PASS with Step 5 verification required for implementation claims. `engineering.md` defines ordered principles and highest-priority safety/privacy/compliance/user-loss guardrails `docs/standards/engineering.md:7-12,16-118`. `coding.md` follows through on compiler-enforced correctness and concurrency `docs/standards/coding.md:16-47,54-61`, cross-boundary contracts and DI `docs/standards/coding.md:7-10`, simplicity/YAGNI via no premature layers and constrained file organization `docs/standards/coding.md:68-100`, and state ownership `docs/standards/coding.md:7-10`. `testing.md` follows through by making runtime tests complement compiler guarantees `docs/standards/testing.md:18-24`, enforcing isolated state `docs/standards/testing.md:20,44-49`, and checking UI/runtime paths the compiler cannot prove `docs/standards/testing.md:50-111`. Concrete build/test/lint enforcement still needs code/config validation. [NEEDS STEP 5 CODE VERIFICATION]
- Conflict scan: PASS. `collaboration.md` rating criteria score Scope Fidelity, Code Quality, Test Coverage, and Architecture Fit `docs/standards/collaboration.md:103-114`; `shared-constraints.md` requires product-position fit, engineering philosophy, lint/build gates, data safety, development discipline, priority severity, and stack baseline `docs/standards/shared-constraints.md:11-19`. These are compatible: Architecture Fit explicitly maps back to `engineering.md` seven principles, while shared constraints cite the same seven-principle source `docs/standards/collaboration.md:112`, `docs/standards/shared-constraints.md:14`. No contradiction found.

### Claim Ledger

Format: `ID | Claim | Audit conclusion | Evidence`.

- E001 | Step 4a Group A files were read in full with `nl -ba`. | READ_VERIFIED | Full numbered content for `engineering.md`, `coding.md`, `testing.md`, `collaboration.md`, and `shared-constraints.md` is recorded below; main File Coverage Ledger rows 278-280 and 285-286 are updated to READ_VERIFIED. |
- E002 | Group B governance pointers route to the intended source docs. | PASS | `.claude/rules/collaboration.md:7-8` points to `docs/standards/collaboration.md`; `.claude/rules/shared-constraints.md:7-8` points to `docs/standards/shared-constraints.md`; main File Coverage Ledger rows 328 and 334 are updated to READ_VERIFIED. |
- E003 | Engineering's seven principles are consistently followed through in coding/testing at the document level. | PASS_WITH_CODE_VERIFICATION_REQUIRED | Principle ordering and guardrail in `engineering.md:7-12,16-118`; coding follow-through in `coding.md:7-10,16-47,54-61,68-100`; testing follow-through in `testing.md:18-24,44-49,50-111`. Implementation enforcement remains Step 5 work. [NEEDS STEP 5 CODE VERIFICATION] |
- E004 | Collaboration scoring criteria do not contradict shared delegation constraints. | PASS | Collaboration scoring dimensions `collaboration.md:103-114` are compatible with shared constraints `shared-constraints.md:11-19`; both refer back to engineering principles rather than defining competing decision rules. |

### Full `nl -ba` Content: `docs/standards/engineering.md`

```text
     1	---
     2	last_verified: 2026-05-10
     3	layer: principle
     4	---
     5	# 工程哲学
     6	
     7	> 本文件定义工程决策的价值观和判断标准。不包含项目特定实现细节——那些在 `architecture.md`、`coding.md`、`testing.md` 和 ADR 中。
     8	>
     9	> 每条原则附带：适用范围、反例（何时不应遵守）、与其他原则的冲突裁决。
    10	> 原则之间按本节顺序裁决（编号靠前的优先）。
    11	>
    12	> **最高裁决**：数据安全、隐私合规、App Store 审核要求、不可逆用户损失——这四条优先于所有简化原则（原则 2、3）。简单性不能压过安全。
    13	
    14	---
    15	
    16	## 1. 先判断方向，再动手实现
    17	
    18	**不确定就先研究，禁止想当然写代码。**
    19	
    20	决策前先确认：要解决什么问题？用户是谁？有没有更简单的方案？
    21	
    22	- UI/UX：Apple 原生 App → 行业标杆 → HIG
    23	- 技术：Apple 文档 → WWDC → 现有代码库
    24	
    25	**适用范围**：所有非 trivial 的代码变更。trivial = 单行 typo 修复、注释修正、日志补充。
    26	
    27	**反例**：紧急线上修复可以跳过完整研究流程，但修复后必须补记录：为什么选这个方案、风险、回滚方式、后续是否需要重新研究。
    28	
    29	---
    30	
    31	## 2. 删掉比添加好
    32	
    33	**新增代码前先问：删掉方案的一半，还能解决问题吗？不改会怎样？**
    34	
    35	三行相似代码优于一个过早抽象。重复不一定是坏事，过早抽象才是。
    36	
    37	当看到模式重复出现 3 次以上时考虑抽象——但出现 3 次不必然该抽象，还要判断：抽象后是否真的降低了认知负担？是否引入了新的耦合？被抽象的代码是否可能向不同方向演化？
    38	
    39	**适用范围**：所有新增代码、新增文件、新增抽象层。
    40	
    41	**反例**：跨模块边界的 API 约定（包与包之间的接口）、安全边界、外部 API 的适配层——这些即使只出现 1 次也需要明确定义，因为修改成本远高于创建成本。
    42	
    43	**与原则 5（协议优先）的冲突裁决**：如果为"未来可能替换实现"而定义协议，但当前只有 1 个实现 → 原则 2 胜出，不定义协议。如果是为测试 mock 或跨包边界 → 原则 5 适用。
    44	
    45	---
    46	
    47	## 3. 不为假设性需求写代码
    48	
    49	**这个功能现在有真实需要吗？没有就不做。**
    50	
    51	守门标准（按优先级）：
    52	1. 发布后：Analytics 数据显示用户有此行为，或用户反馈直接要求
    53	2. 发布前：产品愿景/用户旅程中有明确场景支撑，或竞品已验证此需求
    54	3. 任何阶段：App Store 审核要求、平台合规要求、安全风险控制
    55	
    56	不符合以上任何一条 → 不做。
    57	
    58	**适用范围**：所有功能开发和架构决策。
    59	
    60	**反例**：技术债清理和基础设施升级（如 Swift 版本迁移、依赖更新、平台废弃 API 替换）不需要"用户需要"作为理由——但需要明确的工程信号：编译阻塞、安全风险、性能预算超限、维护成本显著上升、或 CI/review 中反复出现的摩擦。
    61	
    62	---
    63	
    64	## 4. 编译器能拦的，不留给运行时
    65	
    66	**零容忍警告，完整并发检查。**
    67	
    68	- 警告即错误，并发错误编译期暴露
    69	- 业务错误用 typed throws，禁止无差别 `catch` 吞错
    70	- 包边界依赖方向编译器强制
    71	
    72	如果一个 bug 能在编译期被发现却在运行时才暴露，说明约束不够强。具体 Swift flags、SPM 配置、lint 规则见 `coding.md`。
    73	
    74	**适用范围**：所有代码。无法在编译期拦截的约束用 lint、测试、CI 门禁补足。
    75	
    76	**反例**：运行时行为（性能、视觉回归、SwiftData 崩溃、Accessibility、Firebase/StoreKit 回调）无法编译期验证——这些用测试、NFR 基准、api-pitfalls 记录来覆盖，不依赖"编译器能拦"这个原则。
    77	
    78	---
    79	
    80	## 5. 跨边界先定义契约
    81	
    82	**包与包之间、模块与模块之间、Service 与调用方之间——用协议或明确的 public API 定义边界。**
    83	
    84	- 跨包边界的 Service（如 OCR、Analytics）→ 协议定义在 Core，实现在具体层
    85	- 需要测试 mock 的类型 → 协议先行
    86	- 单实现、同模块内部、无替换压力的类型 → 不需要协议
    87	
    88	**适用范围**：跨模块边界、需测试替身的依赖、可能被第三方替换的组件。
    89	
    90	**反例**：同模块内部的 ViewModel、Repository 实现类不需要协议——它们只有一个实现且没有跨边界调用需求。为它们定义协议是原则 2 和 3 意义上的过度工程。
    91	
    92	---
    93	
    94	## 6. 状态所有权明确，复杂业务集中编排
    95	
    96	**复杂业务状态由 ViewModel 持有和修改，View 通过观察自动刷新。跨模块状态同步走通知，不走共享可变状态。**
    97	
    98	具体架构模式（`@Observable`、`@Environment`、`NotificationCenter`、`@Query`）的落地细节见 `../tech/architecture.md`。
    99	
   100	**适用范围**：涉及用户数据的增删改查、复习进度、设置变更等业务状态。
   101	
   102	**反例**：轻量级操作（埋点、Haptic 反馈）允许 View 直接调用 Service。系统级只读状态（`@Environment`、`scenePhase`、`dismiss`）天然在 View 层响应。`@Query` 用于局部、只读的数据展示是合理的——但不应用它绕过 Repository 做业务规则判断或跨 View 共享可变查询结果。
   103	
   104	---
   105	
   106	## 7. 可逆决策成本低，不可逆决策门槛高
   107	
   108	**信息不完整时，优先选择可以撤回的方案。**
   109	
   110	- feature branch + PR → 代码变更可逆
   111	- ADR 可被新 ADR 废弃 → 架构决策可逆
   112	- 内测/未发布阶段数据模型可重建 → 数据结构可逆（发布后有用户数据后走 Schema 迁移）
   113	
   114	不可逆决策（App Store 发布、最低 iOS 版本选择、SwiftData 等持久化框架选择、核心数据模型设计）需要更高的审查门槛——但这些决策**不应该因为"不可逆"而被回避**。有时候早期锁定平台基线是正确的，换来一致性和更少的兼容负担。
   115	
   116	**适用范围**：信息不完整时的决策。信息充分时不适用此原则。
   117	
   118	**反例**：平台级基线、持久化技术栈、核心数据模型——这些早期决策往往应该是不可逆的，因为反复迁移的成本远超一开始就锁定。对于这些决策，关键是投入足够的研究和讨论，而不是保持可逆。
   119	
   120	---
   121	
   122	## 相关文档
   123	
   124	| 文档 | 说明 |
   125	|---|---|
   126	| `coding.md` | 编码规范（本哲学在 Swift/SPM 的具体落地） |
   127	| `testing.md` | 测试策略（编译期拦截的补充） |
   128	| `apple-native.md` | Apple 原生 UI 模式（原则 1 的 HIG 落地） |
   129	| `apple-limits.md` | Apple 技术能力边界（原则 1 的研究参考） |
   130	| `api-pitfalls.md` | 踩坑记录（工程哲学的实证反馈） |
   131	| `../tech/architecture.md` | 当前架构实现（包结构、DI、模块边界） |
   132	| `../tech/non-functional-requirements.md` | 性能预算、内存约束、启动时间 |
   133	| `../tech/compliance.md` | 隐私合规（原则 3 的合规例外、YAGNI 的审核约束） |
   134	| `../workflow.md` | 协作流程（原则如何落到 Issue、Scope、DoD、Review） |
   135	| `../product/product-vision.md` | 产品定位（原则 3 的"用户需要"判断依据） |
   136	| `../product/product-journeys.md` | 用户旅程（原则 3 的场景验证） |
   137	| `../KNOWLEDGE_MAP.md` | 知识分层索引 |
   138	| `../DOC_DEPENDENCY_MAP.md` | 文档上下游传播关系 |
   139	| `../decisions/` | ADR（不可逆决策的正式记录） |
```

### Full `nl -ba` Content: `docs/standards/coding.md`

```text
     1	---
     2	last_verified: 2026-04-16
     3	layer: pattern
     4	---
     5	# 编码规范（SwiftLint 管不到的规则）
     6	
     7	## View 层
     8	
     9	- View = 纯渲染，ViewModel 持有状态，View 通过 @Environment → ViewModel 注入依赖
    10	- DI 链路：协议在 Core → 实现在下游 → DependencyContainer 构造 → @Environment 注入 → View 传给 ViewModel
    11	
    12	## 日志
    13	
    14	- SnapDrillLogger 子系统：`.generic` / `.ui` / `.data` / `.network` / `.engine` / `.capture`
    15	
    16	## 并发
    17	
    18	- 启用 `defaultIsolation(MainActor.self)`：所有代码默认 MainActor 隔离
    19	- **禁止手写 `@MainActor`**（冗余），唯一例外：`Sendable` 协议 + 可变状态的类需显式标注
    20	- ViewModel 声明：`@Observable final class`（不需要 `@MainActor`）
    21	- 后台执行：`Task.detached`（文件 IO、图片压缩等确需脱离当前 actor 的场景）
    22	- 纯计算 struct/enum 跨 actor 使用：标记 `nonisolated`（如 ImageStorage、DTO、L10n）
    23	- Task 句柄：`@ObservationIgnored private var xxxTask: Task<Void, Never>?` + `cancelTasks()` 在 `.onDisappear`
    24	- **Task 闭包中禁止直接访问 MainActor 属性**：`Task {}` / `Task.detached {}` 内不得引用 `@Environment`、`@State`、computed property 等 MainActor 隔离属性。必须在进入 Task 前用 `let localVar = mainActorProp` 捕获到局部变量（要求类型为 `Sendable`）。原因：clean build 可能不报警告，但 Xcode 增量编译会捕获 actor isolation 违规
    25	- NotificationCenter：用 `for await` 替代 `addObserver`
    26	
    27	### Upcoming Features（已全包启用）
    28	
    29	- **InferIsolatedConformances**：当 MainActor 隔离类型遵循协议时，编译器自动推断遵循也是 MainActor 隔离的，减少显式 @MainActor 标注
    30	- **NonisolatedNonsendingByDefault**：函数和闭包默认为 nonisolated + nonsending（不继承调用方的 actor 隔离），需要隔离时显式标注
    31	
    32	### nonisolated(unsafe)
    33	
    34	仅用于第三方 SDK 类型未标注 Sendable 但实际线程安全的场景（当前 4 处）。每处必须附注释说明安全理由。
    35	
    36	| 允许 | 禁止 |
    37	|---|---|
    38	| Apple SDK 类型尚未审计 Sendable（AVCaptureSession、PDFPage） | 可变共享状态 |
    39	| 属性在 MainActor 上设置、在 nonisolated 回调中只读 | 自定义类型（应直接遵循 Sendable 或用 actor） |
    40	
    41	### @preconcurrency
    42	
    43	用于桥接未完成 Sendable 审计的 Apple 框架，两种用法：
    44	- `@preconcurrency import AVFoundation` — 抑制整个模块的并发警告
    45	- `@preconcurrency Animatable` — 协议遵循标注，抑制特定协议的并发警告
    46	
    47	随 SDK 更新逐步移除。
    48	
    49	## 接口变更
    50	
    51	- 修改 struct/class/protocol 的 init 或方法签名后，必须 `grep -rn "TypeName(" Packages/*/Tests/` 检查测试文件同步
    52	- 用 `xcodebuild build-for-testing` 验证（`build` 不编译测试 target）
    53	
    54	## 错误处理
    55	
    56	- 关键路径（save/init）：禁止 `try?`，必须 `do/catch`
    57	- 清理路径：允许 `try?` + `// best-effort: [原因]`
    58	- **Typed throws（SE-0413，Swift 6.0+）**：
    59	  - **业务验证方法**（查重、权限判断、格式校验）：使用 `throws(SpecificError)`，如 `throws(DataError)`、`throws(OCRError)`
    60	  - **纯 CRUD 代理方法**（直接包装 SwiftData `save`/`fetch`、`FileManager`、`URLSession`）：保持原生 `throws`，不做无意义包装
    61	  - **禁止**：在强类型错误枚举中定义 `case underlying(Error)` 逃生舱——这破坏 exhaustive 检查的意义
    62	
    63	## 注释
    64	
    65	- 简体中文，`public` API 用 DocC（`///`），内联注释说"为什么"
    66	- 公司名：`NotBad Labs L.L.C.`
    67	
    68	## 文件组织
    69	
    70	- **单文件单主类型**：每个 .swift 文件有且只有一个主要类型（struct/class/enum/actor）
    71	- **允许的附属类型**：与主类型强耦合、不超过 50 行、仅被主类型使用：
    72	  - Service + Error 枚举（如 BackupService + BackupError）
    73	  - Router + Destination 枚举（如 CaptureRouter + CaptureDestination）
    74	  - View + 小 helper view（UIViewControllerRepresentable + Coordinator）
    75	  - ViewModel + 小 supporting type（如 ReviewPhase 枚举 <20 行）
    76	- **禁止**：独立业务组件（>50 行或被其他文件引用）塞在别人文件里
    77	- **SwiftLint 守护**：`file_length` error 600，超限即需拆分
    78	
    79	## 值类型优先
    80	
    81	- DTO、配置、快照、纯值模型 → 默认 `struct` 或 `enum`
    82	- 需要 identity、生命周期、`@Observable`、SwiftData 持久化 → `class`
    83	- 守门问题：这个类型需要 identity 吗？不需要就用 struct。
    84	
    85	## 禁止
    86	
    87	### 并发安全
    88	- `@unchecked Sendable`（测试 Mock 除外，须注释说明）
    89	- `force unwrap !`（`swiftlint force_unwrapping: error`）
    90	
    91	### 调试
    92	- `print()` — 用 `SnapDrillLogger` 对应子系统
    93	
    94	### 类型系统
    95	- `any` existentials（三个例外：EnvironmentKey.Value 跨模块协议、无 associated type 协议集合如 `[any PDFExportable]`、Protocol 作为函数参数类型）
    96	
    97	### 架构
    98	- Domain 层 / UseCase 层 / Repository 协议（ViewModel 直调 Repository）
    99	- struct 领域对象（SwiftData @Model 须为 class）
   100	- 跨 ModelContext 写后立即读（须先 saveContext）
```

### Full `nl -ba` Content: `docs/standards/testing.md`

```text
     1	---
     2	last_verified: 2026-04-21
     3	layer: pattern
     4	---
     5	# 测试策略与执行规则
     6	
     7	## 分层策略
     8	
     9	| 层 | 策略 |
    10	|---|---|
    11	| 纯算法 / Extension | TDD |
    12	| Service | Test-after，direct test；必要时用 controlled input / temp dir / mock boundary |
    13	| Repository | in-memory ModelContainer |
    14	| ViewModel | Test-after |
    15	| Data infrastructure（Migration / Backup / DTO / Persistence / Profile） | Test-after |
    16	| View / UI 组件 | Smoke test only |
    17	
    18	## 测试设计原则
    19	
    20	1. **测试隔离** — 每个测试创建自己的状态，不共享。Repository 测试用 in-memory `ModelContainer`，ViewModel 测试用 mock service。测试之间无隐式依赖
    21	2. **测试写给人看** — 用中文描述性命名：`@Test("fetchOrCreateModel 不存在时创建新标签")`。测试名描述业务场景，不描述实现细节
    22	3. **边界优先** — 优先测试已知会崩的边界（`#Predicate` many-to-many 运行时崩溃、`ModelContainer` 局部变量提前释放），不堆砌 happy path。FAILURE 模型见 QA 工程师 skill
    23	4. **编译器能拦的不写测试** — typed throws 保证 exhaustive error handling，strict concurrency 保证 actor 隔离，SPM 包边界保证依赖方向。这些由编译器强制，无需运行时测试验证
    24	
    25	## 运行方式
    26	
    27	CI 与本地统一走 `AllTests.xctestplan`，两步切分避免重复编译：
    28	
    29	- **编译测试**：`xcodebuild build-for-testing -scheme AllTests -testPlan AllTests -derivedDataPath ./DerivedData -destination 'platform=iOS Simulator,name=iPhone 17'`
    30	- **执行测试**：`xcodebuild test-without-building -xctestrun $(find ./DerivedData/Build/Products -name 'AllTests_*.xctestrun' | head -1) -only-test-configuration CI -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO`
    31	- **重录 baseline**：同上但 `-only-test-configuration SnapshotRecord`（对应 `SNAPSHOT_TESTING_RECORD=all`，swift-snapshot-testing 原生 env key）
    32	- **禁止**：`swift test`（SPM 仅声明 iOS 平台，macOS 环境不匹配会报错或 SIGTRAP）
    33	- **禁止**：`xcodebuild build`（不编译测试 target）
    34	- **禁止**：`xcodebuild test` 单步（替换为两步 build-for-testing + test-without-building，见 `docs/tech/deployment.md`）
    35	
    36	## async / MainActor 测试约束
    37	
    38	- 项目启用 `defaultIsolation(MainActor.self)`，测试代码也受此影响
    39	- 异步测试用 Swift Testing 的 `@Test` + `await`，不用 `XCTestExpectation`
    40	- 需要验证 MainActor 隔离行为时用 `MainActor.run {}`
    41	- Task 生命周期测试：验证 `cancelTasks()` 后 Task 确实停止，不泄漏
    42	- 详见 `coding.md` 并发段和 `api-pitfalls.md` defaultIsolation 陷阱段
    43	
    44	## SwiftData 测试约束
    45	
    46	- Repository 测试用 in-memory `ModelContainer`（`ModelConfiguration(isStoredInMemoryOnly: true)`）
    47	- `#Predicate` 中的 many-to-many 过滤会运行崩溃 → 测试也要覆盖这个边界（详见 `api-pitfalls.md`）
    48	- 跨 ModelContext 写后立即读 → 测试中同样禁止（详见 `coding.md` 禁止段）
    49	
    50	## XCUITest（端到端 UI 测试，PR #598 实现）
    51	
    52	### 测试隔离
    53	
    54	- `app.launchArguments = ["--uitesting"]` 触发 `DependencyContainer` in-memory 模式
    55	- `DependencyContainer.isUITesting` 为 true 时：跳过 Firebase、使用 `ProfileManager(inMemory: true)`、注入 `MockServiceContainer`
    56	- NSUserDefaults launch arguments 跳过引导和 Tip：`-hasCompletedOnboarding YES`、`-tip.fieldConfig.v1.seen YES`
    57	
    58	### Swift 6.3 并发兼容
    59	
    60	- UITests target 在 `project.pbxproj` 中覆盖 `OTHER_SWIFT_FLAGS`，移除 `-default-isolation MainActor`（XCTestCase 生命周期方法与 MainActor 隔离不兼容）
    61	- 测试类标注 `@MainActor`（XCUIElement API 需要 MainActor）
    62	- `app` 属性用 `nonisolated(unsafe)`（setUp 从 nonisolated 上下文访问）
    63	
    64	### 元素定位
    65	
    66	- 优先用 `accessibilityIdentifier`（不随语言变化）
    67	- Tab 可用 `app.tabBars.buttons.element(boundBy: index)`
    68	- identifier 通过 View 修饰符或组件参数传入，确保在 XCUITest 的 accessibility 层级中可见
    69	
    70	## 接口变更后测试同步
    71	
    72	- 修改 struct/class/protocol 的 init 或方法签名后：`grep -rn "TypeName(" Packages/*/Tests/` 检查测试同步
    73	- 详见 `coding.md` 接口变更段
    74	
    75	## Snapshot 视觉回归（PR #688 后 Stage C 引入）
    76	
    77	### 框架与位置
    78	
    79	- 依赖：`pointfreeco/swift-snapshot-testing`（SnapDrillFeatures/Package.swift 引入）
    80	- 测试文件：
    81	  - `SnapshotRegressionTests.swift` —— SnapDrillUI 层 **public** View（7 tests）
    82	  - `FeatureSnapshotTests.swift` —— Features 层 **internal** View（9 tests，通过 `@testable import` 访问）
    83	- 基线图：`Packages/SnapDrillFeatures/Tests/SnapDrillFeaturesTests/__Snapshots__/<Class>/*.png`（入 git）
    84	- 覆盖：16 个 View × 总计 ~1.4 MB baseline
    85	  - SnapDrillUI 层 7：SnapDrillButton / ProgressLoadingView×2 / ErrorMessageView×2 / ContextualErrorView / TipPopoverContent
    86	  - Features 层 9：ReviewHeroCard×3（空/有待复习/全完成）/ BentoCard×2 / CaptureMethodCard / CornerBracketShape / SettingsRow×2
    87	- 位置选择理由：Xcode 原生 `SnapDrillUITests` (XCUITest) 与 SPM `SnapDrillUITests` 命名冲突，且 AllTests scheme 只纳入 Core/Data/FeaturesTests，故放 FeaturesTests 以确保 CI 真实执行
    88	- nonisolated 标注：`nonisolated final class SnapshotRegressionTests: XCTestCase`，因 `defaultIsolation(MainActor)` 与 XCTestCase 基类 init nonisolated 要求冲突；单测试方法按需加 `@MainActor`
    89	
    90	### 新增/修改 View 的工作流
    91	
    92	1. **新增 public View**：DoD 一项是"同时加 snapshot 测试"（先写测试，首次跑会自动 record baseline + 失败，提交前再跑一次确认稳定）
    93	2. **修改现有 View**：
    94	   - Snapshot 失败时**先人眼审**差异图（xcresult bundle 内 `Attachments/*.png` 或 diff 工具）
    95	   - 若是**有意变更** → 删对应基线 `.png` 文件让它重新 record（不要全文件设 `isRecording = true`，那会盲目覆盖所有 baseline）
    96	   - 若是**非预期回归** → 修代码让 snapshot 与基线一致
    97	3. **禁止盲目 record** — 等同 test evasion（F-014 纪律），Review 见到一次性更新 >3 张 baseline 必须质询合理性
    98	
    99	### 稳定性与 flaky 防护
   100	
   101	- Snapshot 对 Xcode 版本敏感 → 项目固定 Xcode 26.4，CI 用 self-hosted Mac mini（已定）
   102	- 模拟器固定 `iPhone 17`（对齐 `STATUS.md` 执行门命令）
   103	- 用 `.image(layout: .sizeThatFits)` 或显式 `.frame(width:height:)`，避免依赖设备 config preset
   104	- 首次 record 后第二次跑必须 0 diff，否则该测试天然不稳定，不入基线
   105	
   106	### CI 集成（PR-7 已落地）
   107	
   108	- CI 跑 `xcodebuild build-for-testing -scheme AllTests -testPlan AllTests` + `xcodebuild test-without-building -xctestrun ... -only-test-configuration CI -resultBundlePath TestResults.xcresult` 两步自动执行 snapshot 测试
   109	- Test step 失败时 `Upload xcresult on failure` 把 `TestResults.xcresult` 打成 artifact，保留 7 天
   110	- Artifact 命名：`xcresult-<run_id>-<attempt>`
   111	- 下载与解包见 `docs/tech/deployment.md`
```

### Full `nl -ba` Content: `docs/standards/collaboration.md`

```text
     1	---
     2	last_verified: 2026-05-10
     3	layer: pattern
     4	---
     5	# 智能体协作架构
     6	
     7	## 工具链总览
     8	
     9	| 工具 | 引擎 | 入口 | 上下文 | 适合场景 |
    10	|---|---|---|---|---|
    11	| **终端 Claude Code** | Opus 4.7 | CLI / 桌面 App | 1M token | 主力开发、协调、规划、重构、审计 |
    12	| **Claude 子 agent（Haiku）** | Haiku 4.5 | 终端内委派 | 200K token | 注释撰写、翻译、格式化、轻量生成 |
    13	| **Claude 子 agent（Sonnet）** | Sonnet 4.6 | 终端内委派 | 1M token | 中等复杂度代码生成、重构建议 |
    14	| **Codex 插件** | GPT-5.4 系列 | 终端内 | 1.1M token | 对抗性 Review、独立审计、深度研究 |
    15	| **Codex 桌面** | GPT-5.4 系列 | 独立 App | 1.1M token | 大型独立任务 |
    16	| **Xcode** | Claude + Codex | IDE | 200K token | UI Review、Apple 文档查询、SwiftUI Preview |
    17	| **Gemini CLI** | Gemini 3 (Auto) | 终端内 Bash | 1M+ token | 第三方独立审计、交叉验证 |
    18	| **Antigravity** | Gemini + 其他 | IDE | -- | 独立第三方视角（手动中转，Gemini CLI 的备选） |
    19	
    20	## 日常开发（终端内闭环）
    21	
    22	```
    23	Claude Opus（主力）
    24	  |-- Haiku 子 agent -- 注释、翻译、格式化（低成本高速）
    25	  |-- Sonnet 子 agent -- 中等复杂度代码生成、重构
    26	  |-- Codex 插件 ----- 对抗性 Review、独立验证（OpenAI 家族）
    27	  |-- Gemini CLI ------ 第三方审计、交叉验证（Google 家族）
    28	```
    29	
    30	选择原则：
    31	- **需要大上下文** → 终端 Claude Opus
    32	- **需要看 UI 或查 Apple 文档** → Xcode
    33	- **对抗性独立验证** → Codex（OpenAI 家族，盲区不重叠）
    34	- **第三方独立视角** → Gemini CLI（Google 家族，终端内自动化）
    35	- **轻量批量任务** → Haiku 子 agent（注释、翻译，节省成本和速度）
    36	- **Gemini CLI 不可用时** → Antigravity IDE（手动中转，作为 fallback）
    37	
    38	## 交叉审计
    39	
    40	文档审计、代码审查等质量验证任务采用**多 Agent 全量交叉审计**模式。
    41	
    42	### 三方审计组合（终端内全自动化）
    43	
    44	```
    45	Claude Opus --独立审计（主对话内）--+
    46	Codex GPT-5.4 --独立审计（插件委派）--+-- Claude 汇总比对 -- 统一修复 -- 各方独立 Review
    47	Gemini 3 --独立审计（Bash 调用）--+
    48	```
    49	
    50	三个模型家族（Anthropic / OpenAI / Google）全部在终端内闭环，零手动中转。
    51	
    52	### 核心原则
    53	
    54	**每个 Agent 独立审计完整集合，不是各审一半拼起来。**冗余是刻意的：正因为都看同样的东西，才能通过"你发现了我没发现的"暴露盲区。
    55	
    56	### 流程
    57	
    58	1. **并行委派**：Claude 在主对话内审计的同时，并行委派 Codex（Agent 工具）和 Gemini（Bash 调用 `gemini -p`），三方审计同一批完整文件
    59	2. **代码验证**：所有事实性声明（API 存在性、类型名、方法签名）必须用 grep/read 验证
    60	3. **汇总比对**：Claude 汇总三份报告，生成比对表格：共同发现 / 各方独有发现
    61	4. **统一修复**：合并所有发现后一次性修复，避免来回返工
    62	5. **修复 Review**：修复后由三方各自独立 Review 修复结果
    63	6. **回灌到约束体系**：每次 cross-audit 发现的问题，修复后评估根因并更新对应文档：
    64	   - 约束缺失 → 更新 `docs/standards/*.md` 或新增 `feedback.md` 规则
    65	   - 检查遗漏 → 更新 `docs/workflow.md` DoD 或 `.github/workflows/ci.yml`
    66	   - 反复出现（同类问题 3 次以上）→ 提升为自动化门禁（lint rule / CI step）
    67	   - 闭环验证：下一次同类任务中确认改进生效
    68	
    69	### 汇总表格模板
    70	
    71	```markdown
    72	| 发现 | Claude | Codex | Gemini | 共识 |
    73	|---|---|---|---|---|
    74	| [发现描述] | [严重度] | [严重度] | [严重度] | N/3 |
    75	```
    76	
    77	## AI 特有反模式检查
    78	
    79	Cross-audit 和 PR Review 时，除通用代码质量外，必须额外检查以下 AI 特有的缺陷模式。每项检查必须提供具体证据（grep/read/diff 结果），不得仅凭印象判断。
    80	
    81	| 反模式 | 检查方法 | 证据要求 |
    82	|---|---|---|
    83	| **Over-generation** — 添加未被要求的功能/代码 | 对照 Issue scope，diff 中是否有 scope 外的新增 | 列出 scope 外的具体文件/函数 |
    84	| **Assumption-filling** — 需求空白处做隐含假设 | 检查是否有未在 Issue 中定义的业务逻辑 | 指出假设内容及其在代码中的位置 |
    85	| **Brute-force fix** — 用 workaround 替代 root cause fix | 是否有 @ObservationIgnored / try? 等绕行 | grep 结果 + 根因分析 |
    86	| **Scope creep** — 小修改扩成大重写 | diff 行数是否远超预期，是否改了不相关文件 | 统计新增/删除行数对比 |
    87	| **Pattern divergence** — 新代码模式与项目既有模式不一致 | 对比同类文件的实现方式 | 贴出新旧模式对比 |
    88	| **Hallucinated API** — 使用不存在的 API/方法 | grep 验证每个新引入的外部调用确实存在 | grep 结果 |
    89	| **Test evasion** — 通过删除/跳过/绕过测试让 CI 变绿 | 检查 diff 中是否有 skipped/disabled/deleted 测试 | diff 截取 |
    90	
    91	来源：Fowler AI Autonomy 实验（2026）、Python Dev Guide AI 准则、Architecture drift 研究、AI bug 分类学（3864 bugs 论文）。
    92	
    93	## Review 流程
    94	
    95	| 阶段 | 执行者 | 触发条件 |
    96	|---|---|---|
    97	| 代码 Review | Codex 对抗性审查 | 每个 PR |
    98	| UI Review | Xcode | UI 改动 |
    99	| 第三方审计 | Gemini CLI（终端内） | 每次交叉审计 |
   100	| 架构/第三方视角 | Antigravity（fallback） | Gemini CLI 不可用时 |
   101	| 核实汇总 | Claude Opus | 汇总所有 finding，验证真实性 |
   102	
   103	## 量化评分门（PR 审查）
   104	
   105	三方对抗性审查的产出除定性分级（Critical/Warning/Info）外，必须给出 4 维量化评分（0-10 整数分）。详细评分规则见 `.claude/skills/cross-audit-consensus/SKILL.md` §2.5（SSOT）。
   106	
   107	| 维度 | 一句话 |
   108	|---|---|
   109	| **Scope Fidelity** | 与 Issue Sprint Contract（`docs/memory/feedback.md` F-018）Touches / No-Touch / Interface Delta 的吻合度 |
   110	| **Code Quality** | swiftlint / 复杂度 / 架构一致（人工审查维度，独立于 CI 二元通过） |
   111	| **Test Coverage** | 新增逻辑是否有测试、异常路径是否覆盖 |
   112	| **Architecture Fit** | 是否遵循 `engineering.md` 7 条原则（删减、YAGNI、编译拦截、边界契约、状态流、可逆性） |
   113	
   114	**Retry 阈值与具体动作**（建议 retry / 硬性 retry / 可进入待合并 / 冲突列表触发条件）以 `.claude/skills/cross-audit-consensus/SKILL.md` §2.5 为 SSOT。即使 §2.5 判定某 PR "可进入待合并状态"，最终合并由人类操作者确认或明确授权后执行（见 `docs/workflow.md`§Code Review）。
   115	
   116	**背景**：对标 Anthropic Harness Design 2026-03-24 的 Rubric 范式。详见 `docs/archive/research/harness-engineering-study-20260418.md`。
   117	
   118	## Agent 冲突裁决
   119	
   120	当三方审计结论矛盾时，使用标准化模板记录裁决过程：
   121	
   122	| 维度 | 内容 |
   123	|---|---|
   124	| 冲突描述 | [一句话描述分歧点] |
   125	| Claude 主张 | [观点 + 证据] |
   126	| Codex 主张 | [观点 + 证据] |
   127	| Gemini 主张 | [观点 + 证据] |
   128	| 裁决 | [采纳哪方] |
   129	| 理由 | [为什么采纳，排除方案的具体缺陷] |
   130	
   131	证据等级（高到低）：编译/测试/日志结果 > 官方文档引用 > 代码分析推断 > 经验性判断。
   132	
   133	裁决权归人类。无人类在场时，以高等级可验证证据为准，不以"多数投票"为准。冲突未解决时默认阻塞合并，升级至人类裁决。
   134	
   135	## 交流方式
   136	
   137	- 终端 <-> Xcode：GitHub Issue comment（两个入口都能读写）
   138	- 终端 <-> Codex：插件直接调用
   139	- 终端 <-> Gemini CLI：Bash 直接调用（`gemini -p`）
   140	- 终端 <-> Antigravity：用户手动中转（仅 fallback）
```

### Full `nl -ba` Content: `docs/standards/shared-constraints.md`

```text
     1	---
     2	last_verified: 2026-05-10
     3	layer: pattern
     4	---
     5	# 委派共享约束（Canonical Source）
     6	
     7	> 本文件是智能体委派 prompt 中"关键约束摘要"的唯一来源。
     8	> 构造委派 prompt 时，必须先读取本文件并将以下约束全文内联到 prompt 中。
     9	> 修改约束时只改本文件，各智能体的委派配置不再硬编码。
    10	
    11	## 关键约束
    12	
    13	- **产品定位**：效率工具，不是教育平台。核心价值链：采集 → 管理 → 导出/打印（复习是可选留存层，智能组卷是 Pro 增值延伸）
    14	- **工程哲学**：见 `engineering.md` 7 条核心原则（先判断方向、删减优先、YAGNI、编译拦截、边界契约、状态流、可逆性）
    15	- **编码铁律**：swiftlint --strict 0 violations + xcodebuild build-for-testing 0 errors
    16	- **数据安全**：零注册、核心内容数据纯本地、图片是真相、Profile 隔离；匿名 usage/crash telemetry 默认不采集，用户可 opt-in
    17	- **开发纪律**：**修改代码前必须先读相关产品文档确认需求**；改接口签名后必须 grep 测试同步；UI 改动必须经 Xcode Review；PR 未合并前禁止推进下一任务；Review 结论必须留痕
    18	- **优先级**：S0（数据丢失）> S1（流程阻断）> S2（有摩擦）> S3（不紧急）
    19	- **技术栈**：iOS 26.0+ / SwiftUI / SwiftData / Swift 6.3 / defaultIsolation(MainActor)
```

## Step 4b 智能体治理 + Apple 参考审计

Date: 2026-05-12

### Scope

This step read the requested 11 `docs/standards/` files in full with `nl -ba`:

- `docs/standards/codex-delegation.md` (56 lines)
- `docs/standards/gemini-delegation.md` (149 lines)
- `docs/standards/permission-model.md` (129 lines)
- `docs/standards/memory-routing.md` (61 lines)
- `docs/standards/review-prompt-guide.md` (176 lines)
- `docs/standards/api-pitfalls.md` (68 lines)
- `docs/standards/apple-native.md` (90 lines)
- `docs/standards/apple-limits.md` (44 lines)
- `docs/standards/apple-extension.md` (32 lines)
- `docs/standards/ux-design.md` (70 lines)
- `docs/standards/README.md` (35 lines)

This step also read the 10 requested `.claude/rules/` pointer files in full with `nl -ba`, plus `docs/standards/shared-constraints.md` for the delegation-constraint question and `.claude/settings.json` for the permission execution question.

### Pointer Consistency

| Pointer | Source routed to | Result |
|---|---|---|
| `.claude/rules/codex-delegation.md` | `docs/standards/codex-delegation.md` | CONSISTENT |
| `.claude/rules/gemini-delegation.md` | `docs/standards/gemini-delegation.md` | CONSISTENT |
| `.claude/rules/permission-model.md` | `docs/standards/permission-model.md` | CONSISTENT |
| `.claude/rules/memory-routing.md` | `docs/standards/memory-routing.md` | CONSISTENT |
| `.claude/rules/review-prompt-guide.md` | `docs/standards/review-prompt-guide.md` | CONSISTENT |
| `.claude/rules/api-pitfalls.md` | `docs/standards/api-pitfalls.md` | CONSISTENT |
| `.claude/rules/apple-native.md` | `docs/standards/apple-native.md` | CONSISTENT |
| `.claude/rules/apple-limits.md` | `docs/standards/apple-limits.md` | CONSISTENT |
| `.claude/rules/apple-extension.md` | `docs/standards/apple-extension.md` | CONSISTENT |
| `.claude/rules/ux-design.md` | `docs/standards/ux-design.md` | CONSISTENT |

Note: `memory-routing.md` and `review-prompt-guide.md` pointers do not include the same `<!-- 规范源：... -->` HTML comment style used by most other pointer files, but their executable routing text still points to the correct source file.

### Claim Ledger

| ID | Claim | Status | Evidence |
|---|---|---|---|
| G001 | The 11 requested `docs/standards/` files were read in full with `nl -ba`. | READ_VERIFIED | Main File Coverage Ledger rows 272-277, 281-284, and 287 are updated to READ_VERIFIED for Step 4b. |
| G002 | The 10 requested `.claude/rules/` pointer files route to the corresponding `docs/standards/` source files. | READ_VERIFIED | Pointer files were read with `nl -ba`; main File Coverage Ledger rows 322-326, 330-333, and 336 are updated to READ_VERIFIED. |
| G003 | `codex-delegation.md` and `gemini-delegation.md` share the same `shared-constraints.md` canonical constraints. | READ_VERIFIED | `codex-delegation.md:42-43` and `gemini-delegation.md:68-69` both require reading `docs/standards/shared-constraints.md`, inlining it into delegation prompts, and avoiding hardcoded duplicate constraints. `shared-constraints.md:7-9` defines itself as the canonical source. |
| G004 | `permission-model.md` hook lifecycle model is represented in `.claude/settings.json`. | READ_VERIFIED_WITH_SCOPE_LIMIT | `permission-model.md:57-75` lists 11 active hook bindings. `.claude/settings.json:2-78` contains the same 11 bindings: 1 SessionStart hook, 5 PostToolUse hooks, and 5 PreToolUse Bash hooks. This verifies configuration binding, not the runtime behavior of each hook script. |
| G005 | Apple reference docs are routed through `.claude/rules/` without source mismatch. | READ_VERIFIED | `apple-native`, `apple-limits`, `apple-extension`, and `ux-design` source docs and pointers were read with `nl -ba`; all four pointers target their matching source files. |

### Permission Execution Check

`docs/standards/permission-model.md` defines three permission layers: tool tiers, dangerous Bash hard blocks, and hook lifecycle gates. The part that can be verified from `.claude/settings.json` is the hook lifecycle gate. The settings file does execute the documented hook table at the configuration level:

- `SessionStart` / `compact`: `cat .claude/compact-reminder.md`
- `PostToolUse` / `Edit|Write`: `log-file-change.sh`, `swift-autolint.sh`, `docaudit-on-doc-edit.sh`
- `PostToolUse` / `Bash`: `post-merge-checkpoint.sh`
- `PostToolUse` / `.*`: `session-metrics.sh`
- `PreToolUse` / `Bash`: `block-dangerous-bash.sh`, `premerge-checklist.sh`, `prepush-lint.sh`, `long-session-guard.sh`, `docaudit-preflight.sh`

Therefore the permission model's hook lifecycle claims are configuration-verified. Full enforcement of the dangerous-command regex and each hook's internal behavior remains outside this Step 4b read scope unless the hook scripts themselves are audited in a later step.

## Step 5a-1 Data 核心源码审计

Date: 2026-05-12

### Scope

逐行读取（nl -ba）8 个文件，962 行：

- `Packages/SnapDrillData/Sources/SnapDrillData/DataExecutor.swift` (133 lines)
- `Packages/SnapDrillData/Sources/SnapDrillData/Persistence.swift` (92 lines)
- `Packages/SnapDrillData/Sources/SnapDrillData/PersistenceError.swift` (53 lines)
- `Packages/SnapDrillData/Sources/SnapDrillData/DataError.swift` (39 lines)
- `Packages/SnapDrillData/Sources/SnapDrillData/MigrationPlan.swift` (76 lines)
- `Packages/SnapDrillData/Sources/SnapDrillData/ProfileMigration.swift` (133 lines)
- `Packages/SnapDrillData/Sources/SnapDrillData/ProfileManager.swift` (405 lines)
- `Packages/SnapDrillData/Sources/SnapDrillData/ProfileManager+Environment.swift` (31 lines)

### Findings

| ID | Finding | Status | Evidence |
|---|---|---|---|
| DCORE001 | DataExecutor owns ModelContainer，但"唯一持有者"声称需限定范围：ProfileManager 也存 activeContainer，废弃的 PersistenceController 仍持有 container，且 DataExecutor.init(container:) 接受外部注入。 | CLAIM_NEEDS_SCOPE | DataExecutor.swift:34-46,60-94; Persistence.swift:15-33; ProfileManager.swift:32-40,135-139,177-182 |
| DCORE002 | createOffMainActor 工厂存在，但生产代码 ProfileManager 初始化和切换 Profile 时仍调用同步 DataExecutor(storeURL:)，未使用 createOffMainActor。死锁规避覆盖需验证调用点。 | NEEDS_DEEP_DIVE | DataExecutor.swift:98-114; ProfileManager.swift:134-139,175-182 |
| DCORE003 | 磁盘 SwiftData 配置在活跃路径和废弃路径中均显式禁用 CloudKit。 | READ_VERIFIED | DataExecutor.swift:67-70; Persistence.swift:49-55 |
| DCORE004 | SwiftData schema 为 V1-only，迁移阶段为空；模型列表：ReviewItemModel, SubjectModel, TagModel, SourceModel, GradeModel。 | READ_VERIFIED | MigrationPlan.swift:18-31,68-75 |
| DCORE005 | ProfileError.switchBlocked(reason:) 在源码中真实存在且为 public enum 成员；API Reference 冲突应以包含此 case 为准。 | READ_VERIFIED | ProfileManager.swift:156-169,391-405 |
| DCORE006 | 首次启动 Profile 迁移仅以 profiles.json 存在性为门控。若迁移失败且 fallback 写入了 profiles.json，后续启动将跳过重试旧 default.store/images 迁移。 | NEEDS_DEEP_DIVE | ProfileMigration.swift:26-50,120-132 |
| DCORE007 | ProfileManager 在 profiles.json 缺失/为空时创建 fallback 默认 Profile，但未在构造 store URL 前创建 Profile 目录。Container 可能在目录缺失时退化为 in-memory。 | NEEDS_DEEP_DIVE | ProfileManager.swift:111-140 |
| DCORE008 | Environment default 通过 MainActor.assumeIsolated 在 nonisolated static let 内创建 ProfileManager()；安全性依赖实际 SwiftUI 访问上下文。 | NEEDS_DEEP_DIVE | ProfileManager+Environment.swift:15-20 |

### Deep Dive Queue

1. 验证所有生产 DataExecutor 调用点，决定 ProfileManager 在 App 启动和 Profile 切换时是否应使用 `await DataExecutor.createOffMainActor(storeURL:)`。
2. 审计 PersistenceController.shared 残留引用；若无生产引用则记录为兼容保留或标记废弃。
3. 补充迁移失败部分测试：旧 default.store 存在，fallback profile 写入 profiles.json 后，下次启动不应静默丢弃旧数据。
4. 验证 profiles.json 缺失/为空/损坏/指向不存在目录时 ProfileManager 的目录创建与 Container 初始化行为。
5. 检查 ProfileManager.perProfileKeys 各值类型的 JSON 序列化，特别是时间/日期类型。
6. 解决 ProfileError API 文档矛盾：在摘要段补充 switchBlocked(reason:)。
7. 验证 ProfileManager+Environment 在 SwiftUI Previews/Tests/运行时 的默认访问，确保 MainActor.assumeIsolated 不会在非主线程触发 trap。

## Step 5a-2a Data Models

Date: 2026-05-12

### Scope

逐行读取（nl -ba）5 个 SwiftData @Model 文件。

### 核心发现

**5 个 Model 全都没有 profileID 字段：**

| Model | profileID | 关联 |
|---|---|---|
| SourceModel | 无 | - |
| SubjectModel | 无 | - |
| TagModel | 无 | items → ReviewItemModel（多对多反向） |
| GradeModel | 无 | - |
| ReviewItemModel | 无 | tags → TagModel（多对多）, source, subject |

Profile 隔离机制完全依赖每个 Profile 使用独立的 `profiles/<id>/default.store` 文件，在 Profile 初始化/切换时重建 DataExecutor、ModelContainer、RepositoryContainer。模型层没有 Profile 谓词过滤——这意味着如果任何代码路径绕过了 ProfileManager 使用共享/default store，数据会跨 Profile 混合。

### Deep Dive

- 审计 DataExecutor/ProfileManager/Repository 的 store 创建路径，确认不存在共享 store 的使用场景
- 验证 Profile 切换时旧 Container 是否被完全销毁（无残留引用可能导致写入旧 store）

## Step 5a-2b DTO + Repository Container

Date: 2026-05-12

### Scope

逐行读取（nl -ba）4 个文件：ReviewExportSnapshot.swift, BackupDTO.swift, RepositoryContainer.swift, RepositoryContainer+Environment.swift

### 核心发现

1. **ReviewExportSnapshot 无 profileID**：仅包含导出所需字段，toExportSnapshot() 也不注入 profile 信息。隔离依赖当前 RepositoryContainer 绑定正确的 per-profile ModelContainer。

2. **BackupDTO 有 Profile 级分组但无条目级 profileID**：ProfileBackupData 含 profileName/profileId，但 ReviewItemBackupDTO 自身无 profile 字段。BackupPayload 是 `[ProfileBackupData]` 数组。collectProfileBackupData 从当前仓库 fetchAllModels() 后包装为传入的 profileId——如果传错 container 会错误归属。

3. **RepositoryContainer 被动接受 executor**：不自己寻找 Profile 的 ModelContainer，由外部（ProfileManager）传入 DataExecutor。向后兼容路径也只接受外部 ModelContext。

4. **无硬编码 store 路径**：Environment 默认值仅创建内存 ModelContainer（预览/测试 fallback），生产路径由 ProfileManager 构造 `profiles/<profileId>/default.store` 后传入。

### Deep Dive

- 验证 BackupService.restore 方法是否逐 Profile 恢复，避免将 Profile A 的数据恢复到 Profile B 的 store
- 检查是否有任何代码路径向 RepositoryContainer 传入了非当前 Profile 的 ModelContext

## Step 5a-2c Repositories

Date: 2026-05-12

### 逐行读取 5 个 Repository 文件

| Repository | 结论 | 备注 |
|---|---|---|
| SourceRepository | PASS | ModelContext 从外部注入，无 try? 吞错 |
| SubjectRepository | PASS | 同上 |
| TagRepository | PASS | 同上 |
| GradeRepository | PASS | 同上 |
| ReviewRepository | ISSUE | `delete(id:)` 内部构造 `ImageStorage()` 而非从外部接收 profile-scoped storage |

### 核心发现

**ReviewRepository.delete 存在 Profile 隔离隐患**：L58 处 `let imageStorage = ImageStorage()` 在删除操作中内部构造 ImageStorage，而非从外部注入 profile-scoped 实例。如果 ImageStorage 依赖 Profile 路径，此处的默认构造可能使用错误的存储位置。

4 个 Repository PASS，无自行创建 ModelContext、无 try? 吞错、无 force unwrap。

### Deep Dive

- 验证 ImageStorage() 默认构造是否绑定到正确的 Profile 图片目录
- 确认 ReviewRepository 是否应通过 DI 接收 ImageStorage 实例

## Step 5a-2d Backup + ZIP + Seeder

Date: 2026-05-12

### 逐行读取 3 个文件

### 核心发现

| ID | 严重度 | 发现 | 证据 |
|---|---|---|---|
| BKP001 | **S0** | **多 Profile 恢复不是全局原子**：restoreAllProfiles 逐个 Profile 执行 restoreFromProfileData，每个独立 commit。第 N 个 Profile 或后续图片恢复失败时，前面已恢复的 Profile 不回滚。图片失败时 rollbackFromAutoBackup 只回滚活跃 Profile。 | SettingsViewModel.swift:317,369,392 |
| BKP002 | **S0/S1** | **图片恢复无原子性**：restoreImages 直接写目标路径，无 staging 目录、无文件清单、无回滚机制。DB 在图片恢复前已提交，失败后"题目记录已恢复但图片缺失"。 | BackupService.swift:231,258; RepositoryContainer.swift:181 |
| BKP003 | **FIXED** | 单 Profile DB restore 的 delete/insert 原子性已修复：先写 recovery JSON，内存中 delete+insert，单次 saveContext()，失败 rollbackContext()。 | RepositoryContainer.swift:119,177,190 |
| BKP004 | S2 | ZIPArchiver.createArchive 非原子：先删旧 ZIP 再直接写目标，中途失败丢失旧文件留下残缺。 | ZIPArchiver.swift:43 |
| BKP005 | S2 | DataSeeder.seedReviewItems(count:) 忽略 count 参数——即使传 count:10 也会插入全部 mockData。 | DataSeeder.swift:290 |

### 关键结论

STATUS.md 声称"#599 死锁已根除"和"14 Warning 全部闭合"，但 BKP001 和 BKP002 是之前审计未覆盖的 S0 级原子性缺口。单 Profile 层已修，多 Profile 跨恢复 + 图片恢复的全局原子性仍未成立。

### Deep Dive

- 实现 restoreAllProfiles 的全局事务：所有 Profile DB 恢复在 staging 中完成，最后一次性切换
- 实现 restoreImages 的 staging 目录模式：先恢复到临时目录，校验完成后原子 rename
- ZIPArchiver 改为写临时文件 + rename 模式
- 修复 DataSeeder count 参数

## Step 5a-3a Data 测试审计 (1/4)

Date: 2026-05-12

逐行读取 4 个文件：TestHelpers, ModelTests, ProfileTests, MigrationTests

### 发现

| ID | 发现 | 严重度 |
|---|---|---|
| DT001 | **无多 Profile 隔离测试**：ProfileTests 只测了模型属性/Codable/Equatable，没有任何测试验证 Profile A 的数据不会被 Profile B 查到 | S1 |
| DT002 | **无迁移失败回滚测试**：MigrationTests 只覆盖正常路径，没有模拟破损存储/schema 不兼容/迁移异常并验证回滚 | S1 |
| DT003 | ModelTests.testTagModel_Relationship 断言太弱——只检查 items != nil 和 count==0，不插入关联数据验证反向关系 | S3 |
| DT004 | MigrationTests 硬编码 schemas.count==1 和 V1 快照——新增 V2 时必须手动更新，可能静默遗漏 | S3 |
| DT005 | dataExecutorUsesMigrationPlan 只验证容器非 nil 能写入，不验证传入了正确的 MigrationPlan | S3 |
| DT006 | ProfileTests.deleteProfile 依赖 ProfileManager 初始化自动创建默认 Profile 的内部约定，逻辑变化时静默退化 | S3 |

### 正面

- 测试类型均为 struct，逐 test 创建新实例，无共享状态污染风险
- TestHelpers 的 inMemory ModelContainer 封装安全，无全局状态
- typed throws pattern match 写法规范

## Step 5a-3b Data Repository 测试 (2/4)

### 发现

| ID | 发现 | 严重度 |
|---|---|---|
| DT007 | **ReviewRepository.delete 测试不覆盖图片删除**：test helper makeDummyModel 设 `imagePath: nil`，delete 后只断言 `totalItemCount() == 0`，完全不验证图片文件是否被删除 | S1 |
| DT008 | **无 Profile 图片目录验证**：所有 Repository 测试使用 inMemory ModelContainer，没有测试验证图片操作使用了正确的 Profile 隔离目录 | S1 |
| DT009 | Source/Subject/Tag 三个 Repository 测试不涉及 ReviewRepository.delete 路径，该 bug 的测试覆盖为 0 | S2

## Step 5a-3c Data 备份/并发测试 (3/4)

### 发现

| ID | 发现 | 严重度 |
|---|---|---|
| DT010 | **S0 多 Profile 原子性零测试覆盖**：BackupServiceTests/BackupDTOTests/RepositoryContainerBackupTests 全部使用 `profileCount: 1`，没有任何多 Profile 恢复的原子性测试 | **S0** |
| DT011 | **图片恢复测试严重不足**：所有备份测试中 answerImagePath 均为 nil，imagePath 即使非 nil 也不在 decode 后断言。restoreImages 没有端到端测试 | **S0** |
| DT012 | 路径遍历测试可能无效：payload 引用 `../evil.jpg` 但未创建该文件，恢复后仅断言不存在 | S2 |
| DT013 | 并发测试无 bounded timeout——真实死锁会挂起整个 suite 而非 clean fail | S2 |
| DT014 | DataConcurrencyTests 的 Repository 并发测试全是 @MainActor，测试的是线程安全而非死锁规避 | S2 |
| DT015 | GradeRepositoryTests/ReviewItemModelTests 完全不含备份/恢复/图片测试 | S3 |

## Step 5a-3d Data 剩余测试 (4/4)

| ID | 发现 |
|---|---|
| DT016 | PersistenceControllerTests 无废弃状态验证——未测试 shared 访问被禁用或生产路径已不使用 |
| DT017 | ModelExecutorTests 无初始化失败 fallback 测试——只验证了成功路径的 fallback==false |

### Data 层审计小结

Data 层 41 文件全部逐行阅读完毕。

**源码层发现**：
- BKP001/BKP002：两个 S0 原子性缺口（多 Profile 恢复、图片恢复）
- DCORE001：DataExecutor 不是 ModelContainer 唯一持有者
- DCORE006/007：Profile 迁移失败回滚 + 目录创建问题
- ReviewRepository.delete 绕过 Profile ImageStorage

**测试层发现**：
- S0 原子性问题零测试覆盖
- 无多 Profile 隔离测试
- 无迁移失败回滚测试
- 备份测试全部单 Profile，图片恢复未端到端验证
- 并发测试无超时保护

## Step 5b-1 Core Model + DI + Engine

逐行读取 10 个文件。

### 发现

| ID | 发现 |
|---|---|
| CORE001 | Profile 模型定义 `id: UUID` 作为标识，目录名使用该 UUID。但隔离语义完全不在模型层——`nonisolated struct Profile: Sendable`，无 actor 边界。注释说"独立数据库和图片目录"，但代码层依赖外部 store 分离来保证隔离。 |
| CORE002 | ServiceContainer DI 模式与 architecture.md 一致：protocol-based + @Environment + live/mock containers，无偏差。 |
| CORE003 | SM2State/ReviewScheduler/ReviewRating 引擎代码纯计算，无副作用，无全局状态。 |

Core 层前 10 个文件无严重问题。DI 设计规范，引擎纯函数。

## Step 5b-2a Core Services (1/2)

### 发现

| ID | 发现 | 严重度 |
|---|---|---|
| CORE004 | **Analytics opt-in 默认值与文档矛盾**：FeatureFlags.analyticsEnabled 默认 `true`，`@AppStorage` 默认 `true`。文档（compliance.md、privacy）声称"默认关闭、用户 opt-in"。容器层用"key 不存在则不启动 SDK"兜底，但一旦 key 以任何方式存在（即使非用户显式 opt-in），Analytics 就启动。 | **S1** |
| CORE005 | AnalyticsServiceProtocol 不定义 enabled/opt-in 门控——实现在协议外 FirebaseAnalyticsService 内部 guard。如果未来换实现，容易遗漏 opt-in 逻辑。 | S2 |
| CORE006 | DeletionScheduler 5 秒撤销窗口代码正确实现：`Task.sleep(.seconds(5))` + `undoDeletion()` cancel。 | OK |
| CORE007 | ContentTaggingService 使用 FoundationModels，端侧执行，无网络调用。 | OK |
| CORE008 | CaptureDraftService 7 天草稿自动清理，符合 NFR。 | OK |
| CT001 | ServiceContainerTests 覆盖不全——声称测"所有 Mock 服务"但只断言 analytics 和 notification | S3 |
| CT002 | CaptureDraftServiceTests 使用 shared 单例（跨测试污染风险），subject 参数未测试 | S2 |
| CT003 | NotificationServiceTests 中非致命 #expect 后访问数组可能越界崩溃 | S3 |
| CT004 | ReviewSchedulerTests SM2 公式测试不区分旧 EF=2.5 和新 EF=2.36，形同虚设 | S3 |

## Step 5d Infrastructure + UI

### Infrastructure

| ID | 发现 | 严重度 |
|---|---|---|
| INFRA001 | FirebaseBootstrap.isConfigured 是未隔离 static var，并发 configure() 存在竞态 | S2 |
| INFRA002 | FirebaseBootstrap.configure() 无 FeatureFlags 门控——SDK 启动在 opt-in 检查之前 | S2 |
| INFRA003 | FirebaseAnalyticsService 结合 FeatureFlags 默认 true，残留"默认允许"行为 | S1 |

### UI

| ID | 发现 | 严重度 |
|---|---|---|
| UI001 | FeatureRouter 协议未要求 @MainActor，但默认实现直接变更 NavigationPath | S2 |
| UI002 | AccessibilityAnnouncement.announce 未标注 @MainActor 但调用 UIAccessibility.post | S2 |
| UI003 | OnboardingView pages.count-1 未校验空数组——空 pages 导致无效 currentPage 递增 | S3 |
| UI004 | OnboardingManager @Observable 但未 @MainActor，跨线程读写有并发风险 | S2 |
| UI005 | TagInputView 硬编码中文已修复 ✅ | OK |
| UI006 | AccessibilityExtensions.dynamicTypeSize 与 SwiftUI 同名 modifier 混淆 | S3 |

## Step 5e-1 Features Capture + Dashboard

### Capture 发现

| ID | 发现 | 严重度 |
|---|---|---|
| CAP001 | CameraSessionManager 无显式 stop API，相机生命周期依赖对象销毁而非显式关闭 | S2 |
| CAP002 | CameraSessionManager callback 属性标记 nonisolated(unsafe)，与 capture delegate 路径存在数据竞争风险 | S2 |
| CAP003 | CaptureView 文档扫描路径无权限预检（相机路径有），直接 present | S2 |
| CAP004 | CaptureViewModel 相册导入用 UIImage(data:) 全量解码，不像相机路径做降采样——大图内存峰值 | S2 |
| CAP005 | CaptureViewModel 不是 @MainActor，但多个 Task 路径直接修改 Observable UI 状态 | S2 |
| CAP006 | SmartCameraView 裁剪用 point 坐标而非 pixel 坐标构建 CGImage.cropping rect——scale>1 时裁剪错误 | S2 |
| CAP007 | SmartCameraView 快门无防抖——重复点击触发多次拍照 | S3 |
| CAP008 | SmartCameraViewController 无 viewWillDisappear/deinit 停止相机 | S2 |

### Dashboard 发现

| ID | 发现 | 严重度 |
|---|---|---|
| DASH001 | DashboardViewModel 的 cancelTasks() 永久停止 observer，reappear 时 observer 不重建——数据过期 | S2 |
| DASH002 | DashboardAnalyticsViewModel 用 fetchAllModels() + 内存聚合，大数据量可扩展性风险 | S3 |
| DASH003 | DashboardAnalyticsViewModel Pro 状态硬编码 false——分析内容不可达 | S3 |

### 跨模块

- 多个 ViewModel 在 Task 中修改 @Observable 状态但未标注 @MainActor（Capture/Dashboard/Analytics）
- 相机/observer 资源生命周期以 cancel 为主，缺少显式 cleanup

## Step 5e-2 Library 核心

| ID | 发现 | 严重度 |
|---|---|---|
| LIB001 | LibraryView "Select All" 只操作当前分页窗口（limit/offset），不是真正的全选——批量删除/导出遗漏未加载项 | S2 |
| LIB002 | LibraryViewModel 的 subjects/tags 用 fetchAllModels() 无分页——大数据集时 metadata 加载无界 | S2 |
| LIB003 | pendingDeletionItems 每次删除批次被覆盖——多批次删除时较早批次的恢复缓冲区丢失 | S2 |
| LIB004 | LibraryListView 无限滚动无 hasMore 守卫——最后一页后持续触发空加载 | S3 |
| LIB005 | LibraryDetailView 单条导出不验证 item 属于当前 Profile——可能跨 Profile 导出 | S2 |
| LIB006 | PDF 导出固定临时文件名 SnapDrill_Print.pdf——并发导出会覆盖 | S3 |
| LIB007 | ResolvedExportSheet 无 Profile ID 校验——传入不属于当前 Profile 的 ID 也能导出 | S2 |
| LIB008 | SmartPaperView Pro 权限硬编码 false（TODO），与 DashboardAnalytics 同模式 | S2 |
| LIB009 | GradeManager/SourceManager 用 `offsets.map { arr[$0] }` 删除——越界 IndexSet 会崩溃 | S2 |
| LIB010 | GradeManager/SourceManager 的 rollbackContext 只回滚 review repo，不回滚实际被 mutate 的 grade/source repo | S2 |
| LIB011 | GradeManagerView viewModel 是 optional——nil 时 Save 静默无操作，用户困惑 | S3 |
| LIB012 | ShareCardView tags.prefix(5) 可能产生重复 SwiftUI ID（重复 tag 时） | S3 |
| LIB013 | SubjectManagerViewModel 保存失败只记日志不设 UI 错误状态——用户静默卡在编辑页 | S2 |
| LIB014 | BatchTagSheet 无防重复提交——异步完成前可多次触发批量打标签 | S3 |
| LIB015 | EditSourceView/EditSubjectView 空 colorHex 处理有 bug——空值被误判为自定义颜色 | S3 |
| REV001 | ReviewView L298 滑动判断恒等式恒为 0——左右滑动印章分支永远不会触发（死代码） | S2 |
| REV002 | ReviewViewModel 保存失败后 workingItems 未恢复——卡片已被动画移走，用户数据丢失 | **S1** |
| REV003 | ReviewCardContent 图片加载未关联 imagePath key——编辑图片后 View 持续渲染旧图 | S2 |
| REV004 | ReviewCardBack 答案文本忽略用户字体/对齐设置——硬编码 .title3/.leading | S3 |
| REV005 | ReviewCardBack answerImagePath 变更后旧图持续显示——加载逻辑不响应路径变化 | S2 |
| REV006 | SwipeCard hasFired 在移除确认前设置——移除失败时卡片卡在屏幕外且不可再次滑动 | S2 |
| REV007 | ReviewDashboardView "全部完成"状态不管 reviewedCount 是否为 0——"没复习"误显示为"已完成" | S3 |
| REV008 | ReviewRouter placeholder destination 未使用，onNavigateToLibrary 在当前 Review 流程是死代码 | S3 |

## Step 5e-3 Settings 入口 + 备份恢复调用链

### SettingsViewModel 关键发现

| ID | 发现 | 严重度 |
|---|---|---|
| SET001 | **restoreAllProfiles 非原子在调用方恶化**：restoreFromBackup 把正常返回当完全成功。每个 Profile 独立恢复，图片独立恢复，后续失败时前面已恢复的 Profile 不回滚 | **S0** |
| SET002 | **Profile 创建失败静默跳过**：restore 循环中创建失败只记日志 continue，恢复"成功"但静默丢失 Profile | **S0** |
| SET003 | **恢复后不还原原始活跃 Profile ID**：成功恢复后留在最后恢复的 Profile，失败后留在失败的 Profile | S1 |
| SET004 | **Profile 按名称匹配而非 backup profileId**：名称碰撞时错误覆盖已有 Profile 数据 | **S0** |
| SET005 | **DB 与图片回滚目标不一致**：rollback DB 通过 repositories，rollback 图片用 activeProfileDirectory()——恢复中途切换 Profile 后两者指向不同 Profile | S1 |
| SET006 | SettingsViewModel 是 @Observable UI 状态但非 @MainActor——async public 方法跨 await 修改 observable 属性无 actor 隔离 | S2 |
| SET007 | userAvatarColorIndex 只检查上界不检查负值——负数索引崩溃 | S2 |
| SET008 | SettingsView .licenses destination 在 switch 中处理但无导航入口可达 | S3 |
| SET009 | PrivacySettingsView @AppStorage 默认 true——UI 显示 Analytics 已开启，但实际 Firebase 只在 key 存在时启动。UI 与实际隐私状态不一致 | S2 |
| SET010 | NotificationSettingsViewModel enable() 在 scheduleDaily 失败时仍返回 true——UI 显示提醒开启但实际无通知 | S2 |
| SET011 | 通知时间变更先持久化再异步 reschedule——失败时不回滚已持久化时间，新旧不一致 | S2 |
| SET012 | soundEnabled/badgeEnabled 写入 @AppStorage 但 scheduleDaily 不消费——切换声音/角标对实际通知无影响 | S3 |
| SET013 | LanguageSettings 用已废弃的 AppleLanguages + synchronize() 方式切换语言，不稳定 | S2 |
| SET014 | LicenseView 遗漏 ZIPFoundation 许可证，Apache 2.0 文本不完整 | S2 |

## Step 5e-4 Features 测试审计

### 1/4: Capture + Dashboard + Review ViewModel 测试

| ID | 发现 | 严重度 |
|---|---|---|
| FT001 | CaptureViewModel/@MainActor 零测试覆盖——源码缺少隔离但测试也未验证 | S2 |
| FT002 | ReviewViewModel 保存失败数据丢失路径零测试——测试刻意避免调 save 以绕开 SwiftData 崩溃（L43-45 注释） | **S1** |
| FT003 | ReviewViewModel.quitSession 声称清空 workingItems/undoStack 但断言只检查 phase==.idle | S2 |
| FT004 | DashboardViewModel fetch 失败路径零测试——只测成功加载 | S3 |
| FT005 | CaptureResultViewModel 保存失败只测业务校验（空内容），不测持久化 save 抛错后的数据保全 | S2 |
| FT006 | LibraryViewModel tag 过滤零测试，softDelete 不验证模型状态 | S2 |
| FT007 | SmartPaperViewModel 错误处理路径明确未覆盖——注释说"无法注入失败" | S2 |
| FT008 | Grade/Source/Subject Manager 测试创建/编辑只断言数量和名称，不验证 icon/color/sortOrder 持久化 | S3 |
| FT009 | 所有 Manager 测试删除后不从 repository 重新读取验证——删没删干净不知道 | S3 |
| FT010 | SettingsViewModel 备份/恢复测试用默认 ProfileManager() 而非 inMemory——不 hermetic | S2 |
| FT011 | SettingsViewModelCSV 通知断言可能 race——.main queue 在 await 后未必已投递 | S3 |
| FT012 | PrivacySettingsViewModel 并发导出测试 race——waitUntilExportDone 可能观察到被取消的 CSV 结果 | S2 |
| FT013 | NotificationSettingsViewModel @MainActor mock 从非 @MainActor 测试访问——并发隔离违规 | S2 |
| FT014 | ProfileListViewModel 永远不测真实 Profile 切换——只测 no-op 路径和其余边界缺失 | S2 |
| FT015 | TestHelpers MockOCRServiceShared @unchecked Sendable 但内部可变状态无同步保护 | S3 |

## Step 5f App + Share 入口

| ID | 发现 | 严重度 |
|---|---|---|
| APP001 | AppRouter share URL 文件名只检查非空——snapdrill://share 是外部可触达的 URL，文件名验证不足 | S2 |
| APP002 | DependencyContainer 隐私监听器与启动行为不一致——启动用 `bool(forKey:)`，后续变更用 key presence 检查 | S2 |
| APP003 | ShareViewController 即使打开主 App 失败也调 completeRequest——静默结束分享流程 | S2 |
| APP004 | SharedContainerImageWriter 只对 UIImage fallback 降采样，URL/Data 路径直接写原始数据——OOM 防护不一致 | S2 |
| APP005 | SnapDrillApp/DependencyContainer/AppRootView 结构正确，无其他问题 | OK |

## Step 6 Agent 治理层审计

### Hooks 审计（10 个脚本）

| ID | 发现 | 严重度 |
|---|---|---|
| HOK001 | block-dangerous-bash DANGEROUS_RE 漏检 `git push -f` 和 `rm -rf /`——精确匹配正则不覆盖 | **S1** |
| HOK002 | docaudit-on-doc-edit + docaudit-preflight：docaudit.py 缺失时静默 exit 0——文档检查门完全消失 | S2 |
| HOK003 | log-file-change：git rev-parse 失败时 PROJECT_ROOT 为空，写入 `/.claude/session-log.txt` | S3 |
| HOK004 | long-session-guard：.long-session-warned 是持久文件——一旦创建，后续会话永不警告 | S3 |
| HOK005 | post-merge-checkpoint：只计 merge commit，squash/rebase PR 不被计入 checkpoint 阈值 | S2 |
| HOK006 | swift-autolint + prepush-lint：swiftlint 缺失时静默 exit 0——lint 门完全消失 | S2 |
| HOK007 | 多个 hook 的通用模式：依赖缺失 → exit 0。应改为 exit 1 或至少 warn 后继续 | S2 |

### 剩余审计范围

- .claude/skills/ 11 个 SKILL.md
- .claude/settings.json, settings.local.json
- .github/ CI 文件
- .agent-harness/ 文件

## Step 7 Skills + CI + Harness 审计

| ID | 发现 | 严重度 |
|---|---|---|
| GOV001 | **settings.local.json 包含明文 GitHub token**——应迁移到 Keychain 或 macOS 钥匙串 | **CRITICAL** |
| GOV002 | settings.json bypassPermissions 模式启用——绕过权限提示的安全影响需评估 | S1 |
| GOV003 | update-status skill 可能推送到 develop 分支而未检查 untracked 文件 | S1 |
| GOV004 | cross-audit skill 声明的只读模式与实际 write-capable 调用冲突 | S2 |
| GOV005 | hook triggers 可能缺少 MultiEdit 事件匹配 | S3 |
| GOV006 | CI dependency 检查、checkbox 格式等小问题 | S3 |

## Step 8 机械验证

| 检查项 | 结果 |
|---|---|
| swiftlint --strict | ✅ 0 violations, 0 serious (219 files) |
| docaudit all --strict --baseline | ✅ Exit 0, all clean |
| xcodebuild build-for-testing | ✅ 0 errors |

---

# 零信任审计最终报告

## 审计范围

| 类别 | 文件数 | 状态 |
|---|---|---|
| STATUS.md | 1 | ✅ 全读 |
| docs/product/ + decisions/ | 15 | ✅ 全读 |
| docs/tech/ | 6 | ✅ 全读 |
| docs/memory/ + checkpoints/ | 27 | ✅ 全读 |
| docs/standards/ | 16 | ✅ 全读 |
| docs/workflow.md | 1 | ✅ 全读 |
| .claude/rules/ (指针) | 15 | ✅ 全读 |
| Packages/SnapDrillData/ (Sources + Tests) | 41 | ✅ 全读 |
| Packages/SnapDrillCore/ (Sources + Tests) | 60 | ✅ 全读 |
| Packages/SnapDrillFeatures/ (Sources + Tests) | 97 | ✅ 全读 |
| Packages/SnapDrillInfrastructure/ | 3 | ✅ 全读 |
| Packages/SnapDrillUI/ (Sources + Tests) | 16 | ✅ 全读 |
| SnapDrill/App/ | 4 | ✅ 全读 |
| SnapDrillShare/ + Tests | 5 | ✅ 全读 |
| SnapDrillUITests/ | 1 | ✅ 全读 |
| .claude/hooks/ | 10 | ✅ 全读 |
| .claude/skills/ | 11 | ✅ 全读 |
| .claude/settings/ | 2 | ✅ 全读 |
| .github/ | 6 | ✅ 全读 |
| .agent-harness/ | 4 | ✅ 全读 |
| **总计** | **~357** | **✅ 全部完成** |

## 发现问题按严重度汇总

### CRITICAL (1)
- GOV001: settings.local.json 明文 GitHub token

### S0 — 数据不可逆丢失 (4)
- BKP001: 多 Profile 恢复非全局原子
- BKP002: 图片恢复无原子性
- SET001: restoreAllProfiles 在调用方恶化
- SET002: Profile 创建失败静默跳过
- SET004: Profile 按名称匹配而非 backup profileId

### S1 — 流程阻断/数据安全 (7)
- CORE004: Analytics FeatureFlags 默认 true 与文档"默认关闭"矛盾
- INFRA003: FirebaseAnalyticsService 残留"默认允许"
- DT001: 无多 Profile 隔离测试
- DT002: 无迁移失败回滚测试
- DT007: ReviewRepository.delete 图片删除零测试
- DT010: S0 多 Profile 原子性零测试覆盖
- DT011: 图片恢复测试严重不足
- REV002: ReviewViewModel 保存失败致数据丢失
- HOK001: block-dangerous-bash 漏检危险命令
- GOV002: bypassPermissions 模式
- GOV003: update-status 推送到 develop 分支风险

### S2 — 有摩擦 (30+)
包括：L10n key 缺失(~40个)、多个 ViewModel 缺 @MainActor、Profile 隔离依赖 store 无代码级强制、备份恢复非原子、多个 hook 静默失败、导出无 Profile 校验等

### S3 — 不紧急 (20+)
包括：测试断言弱、硬编码 Pro 状态、死代码、死引用、过期注释等

## 与 STATUS.md 声称的差异

| STATUS.md 声称 | 审计结论 |
|---|---|
| "Phase 2 全部完成" | 基本成立，但恢复原子性不完整 |
| "#599 死锁已根除" | 成立，并发测试覆盖了死锁规避 |
| "14 Warning 全部闭合" | 需重新评估——发现 4 个新 S0 |
| "编译 0 errors" | ✅ swiftlint + xcodebuild 验证通过 |
| "ViewModel 覆盖 16/16" | 数量成立，但多数测试断言弱、异常路径缺 |
| "基线审计 8.5/10" | 过度乐观——遗漏了 S0 原子性缺口 |

## 修复优先级建议

1. **立即修**：GOV001 明文 token + BKP001-SET004 S0 原子性
2. **发布前修**：CORE004 Analytics 默认值 + HOK001 危险命令漏检 + S1 数据安全问题
3. **发布后修**：S2 摩擦性问题 + S3 小问题
4. **长期演进**：Profile 隔离从 store 级提升为代码级强制、恢复原子性重构、@MainActor 统一、测试补齐

## Step 5b-2b Core Services (2/2)

### 发现

| ID | 发现 | 严重度 |
|---|---|---|
| CORE009 | OCR 使用 Vision（端侧），但协议未将"不上传云端"写入接口契约。OCRError.invalidImage 定义但从未被抛出——死代码。 | S2 |
| CORE010 | PDFExportService 注释声明支持"本地或远程图片"——"远程"含义需澄清。如果 imageProvider 可加载网络 URL，用户数据可能通过图片 URL 外泄。 | S2 |
| CORE011 | PrivacyConsentService 是空类——Analytics/Crashlytics opt-in 不经过此服务，ATT 已按 ADR-002 移除。opt-in 逻辑散落在 FeatureFlags + FirebaseBootstrap 两处，无统一门控。 | S2 |
| CORE012 | QuestionSplittingService 使用 SystemLanguageModel（端侧），有 `SystemLanguageModel.default.isAvailable` 能力检测和异常降级为空数组，离线可用。实现正确。 | OK |
| CORE013 | PDFExportOptions.itemsPerPage 无上限校验——极端值可能导致内存问题。 | S3 |

## Step 5b-3a Core L10n 审计

逐行读取全部 12 个 L10n 文件 + LocalizationHelper.swift，并交叉验证 en/zh-Hans Localizable.strings。

### 发现

**P1（双语言均缺失——运行时显示原始 key）**：
- smart_paper.* keys (6个)
- statistics.* keys (6个)
- settings.help_center
- settings.switch_learner, add_learner, delete_learner_confirm, learner_name, current_learner (5个)
- settings.card_front_preview, card_back_preview (2个)
- edit_profile.avatar_save_failed
- library.select_all, deselect_all (2个)
- accessibility.* 大批 keys (约20+个)

**P2（仅 zh-Hans 缺失）**：
- settings.import_* CSV 导入相关
- library.export_images 系列
- library.share, share_card_title

**其他**：
- `errors.image_load_failed` 在 en 和 zh-Hans 两处重复定义
- 未发现硬编码字符串绕过本地化系统
- key 命名风格一致（点分隔小写）

## Step 5b-3b Core Support + Utils

逐行读取 9 个文件。AppConfiguration.FeatureFlags 内部一致——analyticsEnabled 默认 true 与 crashReportingEnabled 一致。但与 compliance.md "默认关闭"的矛盾仍存在（CORE004）。其余 Support/Utils 无问题。
