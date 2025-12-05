# 技术债务清单 (Technical Debt)

本文档记录项目中已识别但暂未修复的架构问题和技术债务。

## 🔴 高优先级

### TD-002: UI 测试中使用 `sleep()` 硬等待

**状态**: ✅ 已修复  
**识别日期**: 2024-12-04  
**完成日期**: 2024-12-04  
**影响范围**: UI 测试稳定性

#### 问题描述

`DashboardUITests.swift` 中存在 `sleep(2)` 硬等待，这是 UI 测试的**红线问题**。

#### 修复方案

已将 `sleep(2)` 替换为显式等待：

```swift
// ✅ 修复后代码
let refreshIndicator = app.activityIndicators.firstMatch
if refreshIndicator.exists {
    _ = refreshIndicator.waitForNonExistence(timeout: 5)
}
_ = scrollView.waitForExistence(timeout: 3)
```

#### 受影响文件

- `NotBadUITests/DashboardUITests.swift` ✅ 已修复

---

### TD-001: Education 模块违反 DDD 分层原则

**状态**: ✅ 阶段1已完成  
**识别日期**: 2024-12-04  
**完成日期**: 2024-12-04  
**影响范围**: Domain 层 SPM 独立性

#### 已完成修复

**阶段 1: ✅ 已完成** - 将整个 Education 模块从 `Domain/Education/` 移到 `Infrastructure/Education/`

#### 遗留问题（低优先级）

模块仍包含 SwiftUI 依赖，但已位于正确的层级（Infrastructure）：

1. **协议包含 UI 类型**
   - `GradeLevelProtocol.color: Color`
   - `SubjectProtocol.color: Color`
   - `SubjectCategoryProtocol.color: Color`

2. **`SchoolLevelConfiguration` 包含 Color**
   ```swift
   public struct SchoolLevelConfiguration {
       public let color: Color
   }
   ```

3. **`EducationSystemManager` 是单例服务**
   - 使用 `@Observable` 宏
   - 包含 SwiftUI Environment 集成
   - 应该位于 Infrastructure 或 Application 层

4. **各国教育体系实现包含 Color**
   - `ChinaEducationSystem.swift`
   - `JapanEducationSystem.swift`
   - `KoreaEducationSystem.swift`
   - 等等

#### 当前文件位置

```
NotBad/Infrastructure/Education/   # ✅ 已移动到正确位置
├── EducationSystem.swift          # 协议定义
├── EducationSystemManager.swift   # 单例管理器
├── ChinaEducationSystem.swift     # 中国教育体系
├── JapanEducationSystem.swift     # 日本教育体系
├── KoreaEducationSystem.swift     # 韩国教育体系
├── SingaporeEducationSystem.swift # 新加坡教育体系
├── InternationalEducationSystem.swift # 国际通用体系
└── USEducationSystem.swift        # 美国教育体系
```

#### 后续优化方案（可选）

**阶段 1: 将整个 Education 模块移到 Infrastructure 层**

```
NotBad/Infrastructure/Education/
├── EducationSystem.swift
├── EducationSystemManager.swift
├── Systems/
│   ├── ChinaEducationSystem.swift
│   ├── JapanEducationSystem.swift
│   └── ...
```

**阶段 2: 在 Domain 层定义纯粹的协议**

```swift
// Domain/Protocols/EducationSystemProvider.swift
public protocol EducationSystemProvider: Sendable {
    func subjectDisplayName(for id: String) -> String
    func gradeDisplayName(for id: String) -> String
    var currentRegion: EducationRegion { get }
}
```

**阶段 3: 依赖注入**

将 `EducationSystemManager.shared` 替换为协议注入。

#### 临时解决方案

目前 `ReviewItem+UI.swift` 在 Presentation 层使用 `EducationSystemManager.shared`，
这是一个可接受的临时方案，因为调用点已经在 Presentation 层。

---

## 🟡 中优先级

### TD-004: L10n 本地化工具位置

**状态**: ✅ 已修复  
**识别日期**: 2024-12-04  
**完成日期**: 2024-12-04  
**影响范围**: Domain 层代码

#### 问题描述

部分 Domain 层代码曾直接依赖 `L10n` 工具类（Infrastructure 层）。

#### 已完成修复

- ✅ `ReviewItem+Display.swift` - 移除 L10n 依赖，显示属性移至 `ReviewItem+UI.swift`
- ✅ `EducationRegion.displayName` 使用 `String(localized:)` 是 Swift 原生 API，可接受
- ✅ Education 模块已移至 Infrastructure 层，不再违反分层原则

---

## 🟢 低优先级

### TD-003: ValueObjects deprecated 属性

**状态**: 已修复（保留向后兼容）  
**识别日期**: 2024-12-04

#### 问题描述

为保持向后兼容性，ValueObjects 中保留了 deprecated 的 `color` 属性包装器。

#### 解决方案

在 `ValueObjects+UI.swift` 中提供 deprecated 包装器：

```swift
@available(*, deprecated, message: "Use uiColor instead")
var color: Color { uiColor }
```

将在未来版本中移除。

---

### TD-005: Source 和 ErrorType 使用中文 rawValue

**状态**: ✅ 已修复  
**识别日期**: 2024-12-05  
**完成日期**: 2024-12-05  
**影响范围**: 数据序列化兼容性

#### 问题描述

`Source.swift` 和 `ErrorType.swift` 中的 enum rawValue 曾使用中文字符串。

#### 已完成修复

将所有 rawValue 改为英文标识符：

```swift
// Source.swift - 修复后
enum Source: String {
    case textbook = "textbook"
    case pastExam = "past_exam"
    case exam = "exam"
    // ...
}

// ErrorType.swift - 修复后
enum ErrorType: String {
    case concept = "concept"
    case careless = "careless"
    case wrongDirection = "wrong_direction"
    // ...
}
```

#### 受影响文件

- ✅ `NotBad/Domain/ValueObjects/Source.swift`
- ✅ `NotBad/Domain/ValueObjects/ErrorType.swift`

#### 备注

由于处于内部测试阶段，无需数据迁移。直接修改 rawValue 即可。

---

## 审计进度

### 已完成

- [x] ReviewItem 聚合根审计
- [x] ReviewItem 扩展文件审计
- [x] ValueObjects SwiftUI 依赖移除
- [x] L10n 依赖从 ReviewItem+Display 移除
- [x] Education 模块移至 Infrastructure 层
- [x] UI 测试 sleep() 硬等待修复
- [x] ValueObjects 审计 (15 个值对象)
- [x] ValidationResultTests.swift 创建
- [x] Source/ErrorType rawValue 改为英文
- [x] **Domain 层完整审计** ✅
  - Protocols: 移动 3 个涉及 UIKit/SwiftData 的协议到 Infrastructure
  - Queries: 移动 ReviewItemQueries 到 Data 层
  - Errors: AppError.swift 合规
  - Notification+Names.swift 合规

### 进行中

- [ ] Data 层审计

### 待开始

- [ ] Infrastructure 层审计
- [ ] Presentation 层审计

---

## 变更日志

| 日期 | 操作 | 描述 |
|------|------|------|
| 2024-12-04 | 创建 | 初始技术债务清单 |
| 2024-12-04 | 修复 | TD-003 ValueObjects 重构完成 |
| 2024-12-04 | 修复 | TD-004 L10n 依赖问题修复 |
| 2024-12-04 | 修复 | TD-001 Education 模块移至 Infrastructure |
| 2024-12-04 | 修复 | TD-002 UI 测试 sleep() 问题修复 |
| 2024-12-05 | 修复 | TD-005 Source/ErrorType rawValue 改为英文 |
| 2024-12-05 | 创建 | ValidationResultTests.swift 补全测试覆盖 |
| 2024-12-05 | 重构 | MasteryLevelTests.swift 移除 SwiftUI 依赖 |
| 2024-12-05 | 重构 | Domain 层协议重组：OCR/PDF/ImageCompressor 移至 Infrastructure |
| 2024-12-05 | 重构 | ReviewItemQueries 移至 Data 层 |
