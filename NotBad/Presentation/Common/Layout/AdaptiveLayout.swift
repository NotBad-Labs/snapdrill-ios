//
//  AdaptiveLayout.swift
//  NotBad
//
//  自适应布局工具
//

import SwiftUI

// MARK: - Device Environment

/// 设备环境信息
struct DeviceEnvironment {
    
    /// 当前设备是否为 iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// 当前设备是否为 iPhone
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// 当前是否为横屏
    static var isLandscape: Bool {
        UIDevice.current.orientation.isLandscape
    }
    
    /// 获取推荐的列数
    static func recommendedColumns(for width: CGFloat) -> Int {
        switch width {
        case ..<400:
            return 1
        case 400..<700:
            return 2
        case 700..<1000:
            return 3
        default:
            return 4
        }
    }
}

// MARK: - Adaptive Grid

/// 自适应网格布局
struct AdaptiveGrid<Content: View, Item: Identifiable>: View {
    
    let items: [Item]
    let content: (Item) -> Content
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            let columns = DeviceEnvironment.recommendedColumns(for: geometry.size.width)
            
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.md), count: columns),
                    spacing: DesignTokens.Spacing.md
                ) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
        }
    }
}

// MARK: - Sidebar Adaptive View

/// 侧边栏自适应视图
///
/// 在 iPad 上显示侧边栏，在 iPhone 上显示 Tab 栏
struct SidebarAdaptiveView<Sidebar: View, Content: View>: View {
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    let sidebar: () -> Sidebar
    let content: () -> Content
    
    init(
        @ViewBuilder sidebar: @escaping () -> Sidebar,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.sidebar = sidebar
        self.content = content
    }
    
    var body: some View {
        if sizeClass == .regular {
            NavigationSplitView {
                sidebar()
            } detail: {
                content()
            }
        } else {
            content()
        }
    }
}

// MARK: - Adaptive Spacing

/// 自适应间距
struct AdaptiveSpacing {
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    /// 获取自适应间距
    static func spacing(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch sizeClass {
        case .regular:
            return DesignTokens.Spacing.lg
        default:
            return DesignTokens.Spacing.md
        }
    }
    
    /// 获取自适应 Padding
    static func padding(for sizeClass: UserInterfaceSizeClass?) -> EdgeInsets {
        switch sizeClass {
        case .regular:
            return EdgeInsets(
                top: DesignTokens.Spacing.lg,
                leading: DesignTokens.Spacing.xl,
                bottom: DesignTokens.Spacing.lg,
                trailing: DesignTokens.Spacing.xl
            )
        default:
            return EdgeInsets(
                top: DesignTokens.Spacing.md,
                leading: DesignTokens.Spacing.md,
                bottom: DesignTokens.Spacing.md,
                trailing: DesignTokens.Spacing.md
            )
        }
    }
}

// MARK: - Adaptive Width Modifier

/// 自适应最大宽度修饰器
struct AdaptiveWidthModifier: ViewModifier {
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    let maxWidth: CGFloat
    
    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
        } else {
            content
        }
    }
}

extension View {
    
    /// 应用自适应最大宽度
    func adaptiveMaxWidth(_ maxWidth: CGFloat = 700) -> some View {
        modifier(AdaptiveWidthModifier(maxWidth: maxWidth))
    }
}

// MARK: - Responsive Font

/// 响应式字体
extension Font {
    
    /// 自适应标题字体
    static func adaptiveTitle(for sizeClass: UserInterfaceSizeClass?) -> Font {
        switch sizeClass {
        case .regular:
            return .largeTitle
        default:
            return .title
        }
    }
    
    /// 自适应正文字体
    static func adaptiveBody(for sizeClass: UserInterfaceSizeClass?) -> Font {
        switch sizeClass {
        case .regular:
            return .title3
        default:
            return .body
        }
    }
}

// MARK: - iPad Optimized List Style

/// iPad 优化的列表样式
struct IPadOptimizedListStyle: ViewModifier {
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    func body(content: Content) -> some View {
        if sizeClass == .regular {
            content
                .listStyle(.insetGrouped)
        } else {
            content
                .listStyle(.plain)
        }
    }
}

extension View {
    
    /// 应用 iPad 优化的列表样式
    func iPadOptimizedListStyle() -> some View {
        modifier(IPadOptimizedListStyle())
    }
}

// MARK: - Preview

#Preview("Adaptive Grid") {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let title: String
    }
    
    let items = (1...12).map { PreviewItem(title: "Item \($0)") }
    
    return AdaptiveGrid(items: items) { item in
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.blue.opacity(0.2))
            .frame(height: 100)
            .overlay {
                Text(item.title)
            }
    }
}
