# NotBad 扫描流程规范（Scan Flow Specification）

> **文档版本**: 1.0  
> **创建日期**: 2025-12-12  
> **状态**: 权威文档（Authoritative）  
> **适用架构**: CaptureKit / ProcessKit / ReviewKit（3-Kit 架构）

---

## 📋 概述

本文档定义 NotBad 的**C 混合模式**（Mixed-Mode Capture）扫描流程，这是一种结合了**强引导扫描**和**手动回退**的用户体验设计。

### 核心理念

- **相机优先执行**（Camera-First Execution）：扫描入口是主要的录入方式
- **领域优先架构**（Domain-First Architecture）：ReviewKit 是核心业务价值所在
- **防腐层设计**（Anti-Corruption Layer）：DraftScan 防止脏数据污染持久层

---

## 🔄 状态机（State Machine）

### 完整状态流转

```
   [用户启动扫描]
         │
         ▼
   ┌──────────┐
   │searching │ ←─────────────┐
   │ (寻找)   │                │
   └──────────┘                │
         │                     │
         │ 检测到文档            │ 未检测到/
         ▼                     │ 用户取消
   ┌──────────┐                │
   │ detected │                │
   │ (已检测) │ ───────────────┘
   └──────────┘
         │
         │ 用户确认拍摄
         ▼
   ┌──────────┐
   │capturing │
   │ (拍摄中) │
   └──────────┘
         │
         │ 拍摄完成
         ▼
   ┌──────────┐
   │processing│
   │ (处理中) │
   └──────────┘
         │
         ├─────────────┬─────────────┐
         │             │             │
    AI增强成功      AI增强失败     验证失败
         │             │             │
         ▼             ▼             ▼
   ┌──────────┐  ┌──────────┐  ┌──────────┐
   │reviewing │  │reviewing │  │  failed  │
   │  (草稿)  │  │(降级版本)│  │ (失败)   │
   └──────────┘  └──────────┘  └──────────┘
         │             │             │
    用户确认        用户确认       显示错误
         │             │             │
         ▼             ▼             │
   ┌──────────┐  ┌──────────┐       │
   │ archived │  │ archived │       │
   │(已归档)  │  │(已归档)  │       │
   └──────────┘  └──────────┘       │
                                     │
                                     ▼
                              [返回 searching]
```

### 状态定义

```swift
// CaptureKit/Scanner/ScanState.swift
public enum ScanState: Sendable {
    case searching                           // 正在寻找文档
    case detected(rect: CGRect, confidence: Float)  // 检测到文档
    case capturing                           // 正在拍摄
    case processing(progress: Float)         // 正在处理（0.0-1.0）
    case reviewing(draft: DraftScan)         // 等待用户确认
    case failed(error: ScanError)            // 扫描失败
}
```

---

## 🚪 两种入口路径（Entry Paths）

### 路径 A：引导式扫描（Guided Capture）- 推荐路径

**触发条件**：用户点击"拍照"按钮

**流程**：
1. **进入 `searching` 状态**
   - 相机界面显示实时取景框
   - VisionKit 实时检测文档边界
   - 显示提示："对准试卷/作业本"

2. **过渡到 `detected` 状态**（仅在此状态可拍摄）
   - 检测到矩形且 `confidence >= 0.6`
   - 高亮文档边界（绿色框）
   - 显示"拍摄"按钮（之前隐藏）
   - 震动反馈（haptic feedback）

3. **用户点击拍摄 → `capturing`**
   - 快门动画
   - 捕获当前帧

4. **自动进入 `processing`**
   - 进度指示器：0% → 100%
   - 后台任务：OCR + 图像增强

5. **生成 DraftScan → `reviewing`**
   - 显示预览界面
   - 用户可以：
     - ✅ 确认保存 → `archived`
     - ❌ 重新拍摄 → 返回 `searching`
     - ✏️ 编辑文本

**护栏（Guardrails）**：
- ✅ 只有在 `detected` 状态才能拍摄（强制引导）
- ✅ 置信度 < 0.6 不显示拍摄按钮
- ✅ 用户无法拍到"猫"或其他非文档物体

---

### 路径 B：手动回退（Manual Fallback）

**触发条件**：用户在 `searching` 状态等待超过 5 秒

**流程**：
1. **显示手动拍摄选项**
   - Toast 提示："无法自动检测？点击此处手动拍摄"
   - 或在界面底部显示"手动拍摄"按钮

2. **用户选择手动拍摄**
   - 直接从 `searching` → `capturing`（跳过 `detected`）
   - 拍摄整个相机视野（无边界裁剪）

3. **进入 `processing` + 额外验证**
   - 运行相同的 OCR + 增强流程
   - **关键差异**：在 DraftScan 验证时更严格
     - 必须检测到 ≥ 20 个字符
     - 文档面积 ≥ 30% 画面

4. **验证结果**
   - **通过** → `reviewing`（用户确认）
   - **失败** → `failed`（显示错误："未检测到有效内容，请重试"）

**护栏（Guardrails）**：
- ⚠️ 手动模式增加验证门槛（防止"拍到猫"）
- ⚠️ 失败时给出明确反馈和重试建议
- ⚠️ 记录手动拍摄使用率（用于 UX 改进）

---

## 🛡️ 三层防护（Three-Layer Protection）

### 第一层：实时感知（Live Perception）
**责任方**: CaptureKit  
**对象**: `ScanState`（易失性，永不持久化）

```swift
// CaptureKit 实时检测
let state = await detector.processFrame(pixelBuffer)

switch state {
case .detected(let rect, let confidence):
    // UI 层响应：显示绿框 + 拍摄按钮
    showCaptureButton()
case .searching:
    // UI 层响应：隐藏拍摄按钮，显示引导
    showGuidance("对准文档")
}
```

**特性**：
- ✅ 每秒 30+ 帧检测
- ✅ 不保存任何数据
- ✅ 纯 UI 状态驱动

---

### 第二层：采集清洗（Capture & Sanitize）
**责任方**: CaptureKit  
**对象**: `DraftScan`（临时对象，用户确认前可取消）

```swift
// CaptureKit/Scanner/DraftScan.swift
public struct DraftScan: Sendable {
    // 事实（Facts）- CaptureKit 输出
    public let originalImage: Data
    public let documentRect: CGRect?      // nil 表示手动拍摄
    public let confidence: Float          // 0.0-1.0
    
    // 工件（Artifacts）- ProcessKit 输出
    public let processedImage: Data?      // AI 增强后的图像（可能失败）
    public let extractedText: String      // OCR 文本
    public let textBoundingBoxes: [CGRect]
    
    // 决策提示（Decision Hints）
    public let detectedSubject: String?   // "数学" / "英语"（AI 分析）
    public let suggestedTitle: String     // 前 50 字符
    
    // 验证逻辑（Validation）
    public var isValid: Bool {
        // 规则 1：置信度检查
        guard confidence >= 0.6 else { return false }
        
        // 规则 2：文本长度检查
        guard extractedText.count >= 20 else { return false }
        
        // 规则 3：文档面积检查（手动模式）
        if let rect = documentRect {
            let area = rect.width * rect.height
            guard area >= 0.3 else { return false }  // 至少 30% 画面
        }
        
        return true
    }
    
    // 错误诊断
    public var invalidReason: String? {
        if confidence < 0.6 {
            return "文档检测不清晰（置信度: \(Int(confidence * 100))%）"
        }
        if extractedText.count < 20 {
            return "识别到的文字太少（\(extractedText.count) 字符）"
        }
        if let rect = documentRect, rect.width * rect.height < 0.3 {
            return "文档在画面中占比过小"
        }
        return nil
    }
}
```

**特性**：
- ✅ **永不直接持久化**（防腐层）
- ✅ 包含所有验证逻辑
- ✅ 可取消（用户点击"重新拍摄"）
- ✅ 明确区分"事实"和"提示"

**生命周期**：
```
创建 → 验证 → 用户预览 → [确认 OR 取消]
                           ↓           ↓
                      转换为        丢弃
                      ReviewItem
```

---

### 第三层：确认归档（Review & Archive）
**责任方**: ReviewKit  
**对象**: `ReviewItem`（持久化实体）

```swift
// 主 App 层代码（组合逻辑）
func handleDraftScanConfirmation(_ draft: DraftScan) async throws {
    // 验证通过才允许保存
    guard draft.isValid else {
        showError(draft.invalidReason ?? "无效扫描")
        return
    }
    
    // 转换为领域模型
    let reviewItem = ReviewItem(
        title: draft.suggestedTitle,
        subject: Subject(from: draft.detectedSubject),
        originalImageData: draft.originalImage,
        processedImageData: draft.processedImage,
        extractedText: draft.extractedText,
        createdAt: Date()
    )
    
    // 持久化（ReviewKit）
    try await reviewService.save(reviewItem)
    
    // 通知用户
    showSuccess("错题已保存")
}
```

**特性**：
- ✅ 只有用户确认后才持久化
- ✅ 数据库中不存在"无效"的扫描
- ✅ ReviewItem 是不可变的（Immutable）

---

## 📦 Kit 职责边界（Responsibilities）

### CaptureKit - 输入质量层

#### ✅ 责任（Responsibilities）
1. **实时文档检测**
   - 使用 VisionKit/Vision 框架
   - 输出 `ScanState`（状态机驱动）
   
2. **OCR 文字识别**
   - 使用 Vision 框架
   - 输出结构化文本 + 边界框

3. **生成 DraftScan**
   - 输出**事实**（facts）：rect, confidence, text
   - 输出**工件**（artifacts）：originalImage, extractedText
   - 输出**决策提示**（hints）：suggestedTitle, detectedSubject

4. **图片存储**
   - 保存到 App Groups 共享目录
   - 压缩/缓存管理

#### ❌ 非责任（Non-Responsibilities）
- ❌ **不决定业务策略**：例如"什么是合格的错题"
- ❌ **不持久化 ReviewItem**：只负责临时的 DraftScan
- ❌ **不实现复习算法**：纯粹的输入层

#### 对外接口
```swift
// CaptureKit 公开 API
public protocol DocumentScanner {
    func startScanning() async -> AsyncStream<ScanState>
    func capture() async throws -> DraftScan
}

public struct DraftScan {
    public let originalImage: Data
    public let confidence: Float
    public let extractedText: String
    public var isValid: Bool { get }
}
```

---

### ProcessKit - 图像增强层

#### ✅ 责任（Responsibilities）
1. **AI 手写擦除**
   - Core ML 模型推理
   - 输出处理后的图像

2. **图像增强**
   - 去噪、锐化、对比度调整
   - 透视校正

3. **颜色过滤**
   - 擦除蓝/红笔迹（ColorBasedEraser）

#### ❌ 非责任（Non-Responsibilities）
- ❌ **不决定是否增强**：由主 App 决定是否调用
- ❌ **不验证输入有效性**：接收任意图像
- ❌ **不持久化任何数据**

#### 对外接口
```swift
// ProcessKit 公开 API
public protocol ImageProcessor {
    func removeHandwriting(_ image: Data) async throws -> Data
    func enhance(_ image: Data, options: EnhanceOptions) async throws -> Data
}
```

---

### ReviewKit - 领域核心层

#### ✅ 责任（Responsibilities）
1. **领域模型定义**
   - `ReviewItem` SwiftData 模型
   - 值对象：`Subject`, `Grade`, `MasteryLevel`, `Difficulty`

2. **业务逻辑**
   - 复习调度算法（ReviewScheduler）
   - 掌握度计算
   - 间隔重复（Spaced Repetition）

3. **持久化**
   - SwiftData 容器管理
   - App Groups 共享数据库
   - 数据迁移

#### ❌ 非责任（Non-Responsibilities）
- ❌ **不了解扫描细节**：不知道什么是 DraftScan
- ❌ **不处理图像**：只存储 Data 类型
- ❌ **不实现 UI**：纯业务逻辑

#### 对外接口
```swift
// ReviewKit 公开 API
public protocol ReviewService {
    func save(_ item: ReviewItem) async throws
    func itemsDueToday() async throws -> [ReviewItem]
    func recordReview(for item: ReviewItem, mastery: MasteryLevel)
}
```

---

## 🎯 "拍到猫" 场景验证（Acceptance Criteria）

### 场景描述
用户误操作，将相机对准了家里的猫，而不是作业本。

### 预期行为（混合模式）

#### 路径 A：引导模式
1. **进入 `searching` 状态**
   - VisionKit 检测到猫（非矩形文档）
   - `confidence < 0.6`（因为不是文档）

2. **结果**
   - ✅ **拍摄按钮保持隐藏**
   - ✅ 显示引导："未检测到文档，请对准作业本"
   - ✅ 用户**无法拍摄**

3. **验收标准**
   - ✅ 永远不会进入 `detected` 状态
   - ✅ 不会生成 DraftScan
   - ✅ 数据库不受污染

---

#### 路径 B：手动模式（用户强制拍摄）
1. **用户等待 5 秒 → 显示手动拍摄选项**
2. **用户点击"手动拍摄"→ 拍到猫**
3. **进入 `processing`**
   - OCR 识别："喵喵喵"（假设猫叫声被识别）
   - `extractedText.count = 3`（< 20 字符）

4. **DraftScan 验证失败**
   ```swift
   draft.isValid  // false
   draft.invalidReason  // "识别到的文字太少（3 字符）"
   ```

5. **进入 `failed` 状态**
   - 显示错误："未检测到有效内容，请重试"
   - 提供按钮："重新拍摄"

6. **验收标准**
   - ✅ DraftScan 被丢弃（不持久化）
   - ✅ 数据库不受污染
   - ✅ 用户得到明确反馈

---

### 边界条件测试

| 测试用例 | 引导模式 | 手动模式 |
|---------|---------|---------|
| **拍到猫** | ❌ 无法拍摄（按钮隐藏） | ⚠️ 可拍但验证失败 |
| **拍到空白墙** | ❌ 无法拍摄 | ⚠️ 可拍但验证失败 |
| **拍到手指** | ❌ 无法拍摄 | ⚠️ 可拍但验证失败 |
| **拍到模糊作业本** | ⚠️ confidence < 0.6 → 无法拍摄 | ⚠️ 可拍但验证失败 |
| **拍到清晰作业本** | ✅ 正常流程 | ✅ 正常流程 |

---

## 🔗 架构集成（Integration）

### 完整数据流

```
┌─────────────────────────────────────────────────────────┐
│                      主 App（NotBad）                    │
│                                                          │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐      │
│  │ CameraView │──▶│ ReviewView │──▶│ LibraryView│      │
│  │  (扫描)    │   │  (预览)    │   │  (列表)    │      │
│  └────────────┘   └────────────┘   └────────────┘      │
│         │               │                │              │
└─────────│───────────────│────────────────│──────────────┘
          │               │                │
          ▼               ▼                ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │CaptureKit│    │ProcessKit│    │ReviewKit │
    │          │    │          │    │          │
    │ ScanState│───▶│ enhance()│───▶│ReviewItem│
    │ DraftScan│    │          │    │  (持久化)│
    └──────────┘    └──────────┘    └──────────┘
         │                                 │
         └─────────────┬───────────────────┘
                       ▼
              ┌─────────────────┐
              │  App Groups     │
              │  - 图片存储      │
              │  - SwiftData DB │
              └─────────────────┘
```

### 代码示例（主 App 组合逻辑）

```swift
// NotBad/Views/Capture/CameraView.swift
import CaptureKit
import ProcessKit
import ReviewKit

struct CameraView: View {
    @State private var scanner: DocumentScanner
    @State private var processor: ImageProcessor
    @State private var reviewService: ReviewService
    
    var body: some View {
        ZStack {
            // 相机预览层
            CameraPreview(scanner: scanner)
                .task {
                    // 订阅状态流
                    for await state in scanner.stateStream {
                        handleScanState(state)
                    }
                }
            
            // UI 叠加层
            ScanOverlay(state: $scanState)
        }
    }
    
    func handleScanState(_ state: ScanState) {
        switch state {
        case .detected(let rect, let confidence):
            // 显示绿色边框 + 拍摄按钮
            showCaptureButton = true
            documentRect = rect
            
        case .reviewing(let draft):
            // 验证
            guard draft.isValid else {
                showError(draft.invalidReason ?? "无效扫描")
                return
            }
            
            // 显示预览界面
            showReviewSheet(draft)
            
        case .failed(let error):
            // 显示错误
            showError(error.localizedDescription)
            
        default:
            break
        }
    }
    
    func confirmDraft(_ draft: DraftScan) async {
        do {
            // 可选：AI 增强
            let processedImage = try? await processor.removeHandwriting(
                draft.originalImage
            )
            
            // 创建 ReviewItem
            let item = ReviewItem(
                title: draft.suggestedTitle,
                subject: Subject(from: draft.detectedSubject),
                originalImageData: draft.originalImage,
                processedImageData: processedImage ?? draft.originalImage,
                extractedText: draft.extractedText,
                createdAt: Date()
            )
            
            // 持久化
            try await reviewService.save(item)
            
            // 关闭界面
            dismiss()
            
        } catch {
            showError("保存失败：\(error.localizedDescription)")
        }
    }
}
```

---

## 📊 性能指标（Performance Metrics）

| 指标 | 目标 | 测量方法 |
|------|------|---------|
| **引导模式成功率** | ≥ 85% | 用户首次拍摄成功进入 `reviewing` 的比例 |
| **手动模式使用率** | ≤ 15% | 使用手动拍摄的用户占比 |
| **DraftScan 验证失败率** | ≤ 10% | 手动模式下验证失败的比例 |
| **文档检测延迟** | < 100ms | 从 `searching` 到 `detected` 的平均时间 |
| **处理总时长** | < 3s | 从 `capturing` 到 `reviewing` 的时间 |

---

## 🧪 测试策略（Testing Strategy）

### 单元测试（Unit Tests）

```swift
// CaptureKitTests/DraftScanTests.swift
@Test("DraftScan - 验证失败：置信度不足")
func testDraftScan_lowConfidence() {
    let draft = DraftScan(
        originalImage: mockImageData,
        documentRect: CGRect(x: 0, y: 0, width: 100, height: 100),
        confidence: 0.5,  // < 0.6
        extractedText: "足够的文字内容用于测试"
    )
    
    #expect(!draft.isValid)
    #expect(draft.invalidReason == "文档检测不清晰（置信度: 50%）")
}

@Test("DraftScan - 验证失败：文字太少")
func testDraftScan_insufficientText() {
    let draft = DraftScan(
        originalImage: mockImageData,
        documentRect: nil,  // 手动模式
        confidence: 0.9,
        extractedText: "少于20字符"  // 只有 7 个字符
    )
    
    #expect(!draft.isValid)
    #expect(draft.invalidReason?.contains("文字太少"))
}
```

### 集成测试（Integration Tests）

```swift
@Test("完整扫描流程 - 引导模式成功")
func testGuidedScanWorkflow() async throws {
    let scanner = DocumentScanner()
    
    // 1. 启动扫描
    let stateStream = await scanner.startScanning()
    
    // 2. 模拟检测到文档
    let testImage = loadTestImage("clear_homework.png")
    let state = await scanner.processFrame(testImage)
    
    #expect(state == .detected)
    
    // 3. 拍摄
    let draft = try await scanner.capture()
    
    #expect(draft.isValid)
    #expect(draft.confidence >= 0.6)
    #expect(draft.extractedText.count >= 20)
}

@Test("完整扫描流程 - 手动模式验证失败")
func testManualScanWorkflow_invalidContent() async throws {
    let scanner = DocumentScanner()
    
    // 模拟拍到猫
    let catImage = loadTestImage("cat.png")
    let draft = try await scanner.captureManually(catImage)
    
    #expect(!draft.isValid)
    #expect(draft.invalidReason?.contains("文字太少"))
}
```

---

## 📚 相关文档

- [架构哲学](ARCHITECTURE_PHILOSOPHY.md) - 为什么选择 Domain-First + Camera-First 混合架构
- [3Kit 验证报告](3KIT_VALIDATION_REPORT.md) - CaptureKit/ProcessKit/ReviewKit 架构验证
- [项目架构](ARCHITECTURE.md) - 整体技术架构
- [术语表](GLOSSARY.md) - DraftScan, ScanState 等术语定义

---

## 🔄 变更历史

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| 1.0 | 2025-12-12 | 初始版本，定义混合模式扫描流程 |
