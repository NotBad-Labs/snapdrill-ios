# NotBad 架构哲学：回应"Camera-First"讨论

**日期**: 2025年12月11日  
**背景**: 资深苹果开发者提出"NotBad 应该以 CaptureKit 为核心"的建议

---

## 🤔 核心分歧：什么是 NotBad 的本质？

### 开发者观点：Camera-First Application
> "您的核心不是 ReviewItem，而是从现实光影到结构化数据的转化引擎"

**论据**：
- 用户打开 App 就是为了拍照
- "拍到猫"的问题必须在采集层解决
- 扫描质量决定产品体验

**建议架构**：
```
CaptureKit (核心) → 信号处理管道
ProcessingKit → AI 处理
DataKit → 存储层
```

### 我的观点：Domain-First Application

**反驳**：
- 用户打开 App 是为了**管理错题**，拍照只是输入手段之一
- NotBad 不是"扫描全能王"，而是"Anki + OCR"
- 核心价值在**复习算法**，不在扫描质量

**坚持架构**：
```
ReviewKit (核心) → 领域逻辑 + 复习算法
CaptureKit → 输入层（多种方式之一）
ProcessKit → 增强层
```

---

## ✅ 但我完全采纳的建议

### 1. 三层漏斗模型（集成到 CaptureKit）

**第一层：实时感知**（Live Perception）
```swift
// CaptureKit/Scanner/ScanState.swift
enum ScanState {
    case searching                    // 寻找文档
    case detected(rect, confidence)   // 检测到试卷
    case capturing                    // 拍摄中
    case processing(progress)         // AI 处理中
}
```

**第二层：采集清洗**（Capture & Sanitize）
```swift
// 临时对象，避免"拍到猫"污染数据库
struct DraftScan {
    let originalImage: Data
    let processedImage: Data
    let extractedText: String
    let confidence: Float
    
    // 验证逻辑
    var isValid: Bool {
        confidence >= 0.6 &&
        extractedText.count >= 20
    }
}
```

**第三层：确认归档**（Review & Archive）
```swift
// App 层代码
if draftScan.isValid {
    let reviewItem = ReviewItem(from: draftScan)
    await reviewService.save(reviewItem)
} else {
    showAlert("未检测到试卷，请重新拍摄")
}
```

### 2. VisionKit 实时检测

**采纳理由**：用户体验提升显著

```swift
// CaptureKit 集成 VNDocumentCameraViewController
import VisionKit

@available(iOS 17.0, *)
public class DocumentScanner: NSObject, VNDocumentCameraViewControllerDelegate {
    func startScanning() {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = self
        // VisionKit 已经处理了"第一层漏斗"
        // 如果不是文档，用户根本无法完成扫描
    }
}
```

---

## 🎯 最终架构（整合两种观点）

### 层次结构

```
┌─────────────────────────────────────────┐
│  App Layer (NotBad 主应用)              │
│  ┌─────────────────────────────────┐   │
│  │ 主界面：错题列表（核心场景）     │   │
│  │ 拍照入口：调用 CaptureKit        │   │
│  │ 复习界面：调用 ReviewKit         │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
            │                │
    ┌───────┴────┐      ┌───┴──────┐
    │            │      │          │
    ▼            ▼      ▼          │
CaptureKit   ProcessKit  ReviewKit │ ← 领域核心
  (输入层)    (增强层)   (业务层)  │
  │                                 │
  ├─ ScanState (状态机) ←─ 采纳    │
  ├─ DraftScan (临时对象) ←─ 采纳  │
  ├─ LiveDetection ←─ 采纳         │
  └─ VisionKit 集成 ←─ 采纳        │
                                    │
    数据流向：                      │
    Camera → DraftScan → 用户确认 → ReviewItem
    (不合格的 DraftScan 被丢弃，永远不会污染 ReviewKit)
```

### 职责划分

| Kit | 职责 | 核心价值 | 是否核心 |
|-----|------|----------|---------|
| **ReviewKit** | 错题管理 + 复习算法 | **业务价值** | ✅ 是 |
| **CaptureKit** | 扫描 + 验证 + 状态管理 | 输入质量 | ⚠️ 重要但非核心 |
| **ProcessKit** | AI 去手写 + OCR | 体验优化 | ⚠️ 竞争优势 |

---

## 📊 用户旅程对比

### 扫描全能王（Camera-First）
1. 打开 App → **直接进相机**
2. 拍文档 → 处理 → 导出 PDF
3. ❌ 没有复习系统
4. ❌ 没有间隔重复算法

### NotBad（Domain-First + Smart Capture）
1. 打开 App → **错题列表**（主界面）
2. 点击"添加"→ 选择：
   - 📷 拍照（CaptureKit）
   - ✍️ 手动输入
   - 📂 导入图片
3. **如果选择拍照**：
   - 实时检测（VisionKit）
   - 生成 DraftScan
   - 用户确认 → 保存到 ReviewKit
4. ✅ 核心价值：复习管理（ReviewScheduler）

---

## 🏆 为什么 ReviewKit 必须是核心？

### 场景 1：用户已经有大量手写笔记
- 不需要 CaptureKit
- 直接手动创建 ReviewItem
- **核心价值**：ReviewScheduler 安排复习

### 场景 2：用户从其他 App 导入
- 不需要 CaptureKit
- 批量导入 CSV / JSON
- **核心价值**：ReviewKit 的数据模型

### 场景 3：未来支持 Web 版
- Web 端没有相机
- 用户上传图片
- **核心价值**：ReviewKit 的跨平台存储

**结论**：CaptureKit 只在"拍照录入"场景有用，但 ReviewKit 在所有场景都需要。

---

## ✨ 开发者建议的宝贵之处

### ✅ 完全采纳的部分
1. **三层漏斗模型**（已实现：ScanState.swift）
2. **DraftScan 临时对象**（已实现）
3. **实时感知**（计划集成 VisionKit）
4. **验证逻辑**（DraftScan.isValid）

### ⚠️ 部分采纳的部分
- **CaptureKit 作为核心**：不同意
- **信号处理管道**：同意作为 CaptureKit 内部实现
- **状态机**：同意，但不影响整体架构层次

### ❌ 不采纳的部分
- 将 ReviewKit 降级为"DataKit"（存储层）
- 认为"扫描"比"复习算法"更重要

---

## 🎯 最终结论

**NotBad 的本质**：
> 一个以**间隔重复算法**为核心的错题管理工具，  
> 附带**智能扫描**功能来降低录入成本。

**不是**：
> 一个以扫描为核心的 OCR 工具，  
> 附带复习功能。

**类比**：
- ✅ Anki (记忆卡片) + 相机扫描 = NotBad
- ❌ 扫描全能王 + 复习功能 ≠ NotBad

**架构决策**：
- ReviewKit = 核心（业务逻辑）
- CaptureKit = 重要但非核心（输入质量）
- ProcessKit = 竞争优势（AI 去手写）

**但完全采纳开发者的工程建议**：
- 在 CaptureKit 内部实现三层漏斗
- 使用 VisionKit 实时检测
- DraftScan 验证机制
- 避免"拍到猫"污染数据库

---

## 📚 参考架构对比

| 应用 | 核心 Kit | 定位 |
|------|---------|------|
| **扫描全能王** | CaptureKit | Camera-First |
| **Anki** | ReviewKit | Domain-First |
| **NotBad** | ReviewKit + 智能 CaptureKit | **Domain-First with Smart Capture** |

---

**总结**：开发者的工程建议非常宝贵（已全部采纳到 CaptureKit 设计），但产品定位我坚持 Domain-First 架构。
