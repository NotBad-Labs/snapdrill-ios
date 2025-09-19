# NotBad 设计规范（UX Spec）v6.0 - Swift 6.2 + iOS 26

> **版本**: v6.0
> **技术栈**: Swift 6.2 + iOS 26 + Xcode 26
> **最后更新**: 2025年9月19日

本规范承载视觉与交互细节，作为PRD v6.0的技术实现补充。PRD保留信息架构、关键任务与可追踪性，像素级实现、设计令牌与SwiftUI组件规范在此维护。

## 1. 视觉系统（Visual System）- iOS 26 现代化

### 1.1 色彩系统 (Color System)

基于iOS 26语义色彩和Swift 6.2类型安全设计：

**主色彩 (Primary Colors)**:

```swift
// Swift 6.2 类型安全色彩定义
extension Color {
    static let notBadPrimary = Color("NotBadPrimary") // #007AFF → iOS 26 动态色彩
    static let notBadSecondary = Color("NotBadSecondary") // #34C759
    static let notBadAccent = Color("NotBadAccent") // #FF9500
}

// Enhanced Actor模式下的色彩管理
@globalActor
actor ColorThemeActor {
    static let shared = ColorThemeActor()

    private var currentTheme: ColorTheme = .system

    func updateTheme(_ theme: ColorTheme) {
        currentTheme = theme
    }
}
```

**语义色彩 (Semantic Colors)**:

- `notBadCorrect`: 正确答案 (#34C759)
- `notBadError`: 错误标识 (#FF3B30)
- `notBadWarning`: 警告提示 (#FF9500)
- `notBadDiscovery`: Discovery社区 (#5856D6)

### 1.2 字体系统 (Typography System)

支持iOS 26 Advanced Dynamic Type和无障碍：

```swift
// Swift 6.2 字体定义
extension Font {
    static let notBadTitle1 = Font.largeTitle.weight(.bold) // 34pt
    static let notBadTitle2 = Font.title.weight(.semibold) // 28pt
    static let notBadHeadline = Font.headline.weight(.medium) // 17pt
    static let notBadBody = Font.body // 17pt，支持动态字体
    static let notBadCaption = Font.caption.weight(.medium) // 12pt
}
```

**字体层级 (Typography Hierarchy)**:

1. **大标题**: 34pt/Bold - 页面主标题
2. **标题**: 28pt/Semibold - 章节标题
3. **副标题**: 22pt/Medium - 卡片标题
4. **正文**: 17pt/Regular - 主要内容（支持Dynamic Type）
5. **说明文字**: 12pt/Medium - 辅助信息

### 1.3 间距与栅格 (Spacing & Grid)

基于iOS 26设计规范的8pt栅格系统：

**间距定义**:

```swift
extension CGFloat {
    static let spacing4: CGFloat = 4    // 最小间距
    static let spacing8: CGFloat = 8    // 基础间距
    static let spacing12: CGFloat = 12  // 小间距
    static let spacing16: CGFloat = 16  // 标准间距
    static let spacing24: CGFloat = 24  // 大间距
    static let spacing32: CGFloat = 32  // 超大间距
}
```

## 2. 组件库（Design System Components）- SwiftUI + Swift 6.2

### 2.1 基础控件 (Basic Components)

#### 2.1.1 按钮系统 (Button System)

```swift
// Swift 6.2 Enhanced Actor模式的按钮组件
struct NotBadButton: View {
    let title: String
    let style: ButtonStyle
    let action: @MainActor () async -> Void

    var body: some View {
        Button(title) {
            Task { @MainActor in
                await action()
            }
        }
        .buttonStyle(style)
        .background(.regularMaterial) // iOS 26 Material效果
    }
}

enum ButtonStyle: CaseIterable {
    case primary    // 主要操作
    case secondary  // 次要操作
    case destructive // 危险操作
    case discovery  // Discovery社区专用
}
```

#### 2.1.2 输入控件 (Input Components)

- **文本输入**: 支持实时验证和错误提示
- **OCR校对输入**: 专用于OCR结果编辑的组件
- **标签选择器**: 支持多选的知识点标签组件

### 2.2 复合组件 (Complex Components)

#### 2.2.1 Discovery社区组件

```swift
// Discovery社区卡片组件 - Swift 6.2 设计
struct DiscoveryPostCard: View {
    let post: DiscoveryPost
    @State private var isLiked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 匿名化内容展示
            Text(post.anonymizedContent.problemDescription)
                .font(.notBadBody)
                .foregroundStyle(.primary)

            // 知识点标签
            LazyHGrid(rows: [GridItem(.adaptive(minimum: 30))]) {
                ForEach(post.anonymizedContent.keyKnowledgePoints, id: \.self) { point in
                    Text(point)
                        .font(.notBadCaption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.notBadDiscovery.opacity(0.1))
                        .foregroundStyle(.notBadDiscovery)
                        .clipShape(Capsule())
                }
            }

            // 交互按钮
            HStack {
                Button("有帮助") {
                    Task { @MainActor in
                        await handleHelpfulAction()
                    }
                }
                .buttonStyle(.discovery)

                Spacer()

                Text("\(post.helpfulnessScore, specifier: "%.1f")分")
                    .font(.notBadCaption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial) // iOS 26 Material
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func handleHelpfulAction() async {
        // Enhanced Actor模式的异步操作
    }
}
```

#### 2.2.2 OCR预览组件

```swift
// OCR结果预览和编辑组件
struct OCRPreviewCard: View {
    @Binding var ocrResult: OCRResult
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 16) {
            // 原图预览
            AsyncImage(url: ocrResult.originalImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(maxHeight: 200)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // OCR文本编辑
            if isEditing {
                TextEditor(text: $ocrResult.recognizedText)
                    .font(.notBadBody)
                    .padding(12)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(ocrResult.recognizedText)
                    .font(.notBadBody)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        isEditing = true
                    }
            }

            // 操作按钮
            HStack {
                Button(isEditing ? "完成" : "编辑") {
                    isEditing.toggle()
                }
                .buttonStyle(.secondary)

                Spacer()

                Button("保存") {
                    Task { @MainActor in
                        await saveOCRResult()
                    }
                }
                .buttonStyle(.primary)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func saveOCRResult() async {
        // 保存逻辑
    }
}
```

### 2.3 状态规范 (State Specifications)

#### 2.3.1 加载状态 (Loading States)

```swift
// iOS 26 现代加载动画
struct NotBadLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0.25, to: 1.0)
            .stroke(.notBadPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}
```

#### 2.3.2 错误状态 (Error States)

- **网络错误**: 支持重试和离线模式切换
- **OCR错误**: 提供重新拍照和手动输入选项
- **同步冲突**: 清晰的冲突解决界面

## 3. 动效与过渡（Motion）- ProMotion Max支持

### 3.1 页面转场 (Page Transitions)

利用iOS 26和ProMotion Max 120fps特性：

```swift
// 自定义转场动画 - 120fps优化
extension AnyTransition {
    static let notBadSlide = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .leading).combined(with: .opacity)
    )

    static let notBadDiscoveryModal = AnyTransition.scale(scale: 0.9)
        .combined(with: .opacity)
        .animation(.spring(duration: 0.4, bounce: 0.15))
}
```

### 3.2 微交互 (Micro-interactions)

- **按钮反馈**: 120fps的精确触觉反馈
- **卡片点击**: 优雅的缩放和阴影变化
- **滑动删除**: 流畅的物理动画

### 3.3 物理参数 (Physics Parameters)

```swift
// 标准动画参数
extension Animation {
    static let notBadStandard = Animation.spring(duration: 0.3, bounce: 0.1)
    static let notBadQuick = Animation.spring(duration: 0.2, bounce: 0.05)
    static let notBadGentle = Animation.spring(duration: 0.5, bounce: 0.15)
}
```

## 4. 无障碍（Accessibility）- iOS 26增强

### 4.1 语义标注 (Semantic Annotations)

```swift
// VoiceOver支持示例
Text("错题数量: \(count)")
    .accessibilityLabel("您有\(count)道错题需要复习")
    .accessibilityHint("点击进入错题列表")
    .accessibilityAddTraits(.isButton)
```

### 4.2 对比度与可达性

- **最小对比度**: 4.5:1 (WCAG AA标准)
- **最小点击区域**: 44x44pt
- **焦点指示器**: 清晰的焦点环
- **动效减弱**: 支持系统减少动效设置

### 4.3 Discovery社区无障碍

- **匿名内容**: 确保屏幕阅读器能理解匿名化内容
- **内容审核**: 无障碍友好的内容审核状态提示

## 5. 规格与标注（Specs）- 多平台支持

### 5.1 iPhone适配

- **iPhone 17 Pro Max**: 430x932pt (主要优化目标)
- **iPhone 17**: 393x852pt
- **iPhone SE**: 375x667pt (最小支持)

### 5.2 iPad适配 (vNext)

- **iPad Pro 12.9"**: 1024x1366pt
- **iPad Pro 11-inch (M4)**: 820x1180pt
- **分屏支持**: Slide Over, Split View

### 5.3 visionOS适配规划 (vNext)

- **空间计算**: Discovery社区3D浏览体验
- **眼动追踪**: 视线导航和选择

## 6. 资产与链接（Assets & Links）

### 6.1 设计资源

- **Figma设计稿**: [NotBad v6.0 Design System](TBD)
- **SF Symbols**: 使用iOS 26最新符号集
- **图标库**: 256x256@3x规格，支持动态着色

### 6.2 设计令牌 (Design Tokens)

```json
{
  "spacing": {
    "xs": "4pt",
    "sm": "8pt",
    "md": "16pt",
    "lg": "24pt",
    "xl": "32pt"
  },
  "colors": {
    "primary": "#007AFF",
    "discovery": "#5856D6",
    "success": "#34C759",
    "warning": "#FF9500",
    "error": "#FF3B30"
  },
  "typography": {
    "title1": "34pt/Bold",
    "body": "17pt/Regular",
    "caption": "12pt/Medium"
  }
}
```

## 附录：与PRD v6.0的对应关系

- **PRD v6.0**: 信息架构、关键任务、验收准则、埋点事件规范
- **本规范**: 视觉系统、SwiftUI组件、动效参数、无障碍实现、iOS 26特性应用
- **TDD v6.0**: Discovery社区技术架构、Enhanced Actor模式、Swift 6.2代码实现

**版本一致性保证**: 本设计规范严格遵循PRD v6.0的功能需求和TDD v6.0的技术架构，确保设计-开发一致性。
