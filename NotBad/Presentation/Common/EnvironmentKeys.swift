//
//  EnvironmentKeys.swift
//  NotBad
//
//  SwiftUI 环境键定义
//  Phase 5: View 层环境注入
//

import SwiftUI
import SwiftData

// MARK: - DataProvider Environment Key

/// ReviewItemDataProviding 环境键
///
/// 用于通过 SwiftUI Environment 注入数据提供者
private struct DataProviderKey: EnvironmentKey {
    static let defaultValue: (any ReviewItemDataProviding)? = nil
}

extension EnvironmentValues {
    /// 错题数据提供者
    ///
    /// 使用示例:
    /// ```swift
    /// // 注入
    /// ContentView()
    ///     .environment(\.dataProvider, provider)
    ///
    /// // 读取
    /// @Environment(\.dataProvider) var dataProvider
    /// ```
    var dataProvider: (any ReviewItemDataProviding)? {
        get { self[DataProviderKey.self] }
        set { self[DataProviderKey.self] = newValue }
    }
}

// MARK: - OCR Service Environment Key

/// OCRServiceProtocol 环境键
private struct OCRServiceKey: EnvironmentKey {
    static let defaultValue: (any OCRServiceProtocol)? = nil
}

extension EnvironmentValues {
    /// OCR 服务
    ///
    /// 使用示例:
    /// ```swift
    /// // 注入 Mock
    /// CaptureView()
    ///     .environment(\.ocrService, MockOCRService())
    ///
    /// // 读取
    /// @Environment(\.ocrService) var ocrService
    /// ```
    var ocrService: (any OCRServiceProtocol)? {
        get { self[OCRServiceKey.self] }
        set { self[OCRServiceKey.self] = newValue }
    }
}

// MARK: - PDF Export Service Environment Key

/// PDFExportServiceProtocol 环境键
private struct PDFExportServiceKey: EnvironmentKey {
    static let defaultValue: (any PDFExportServiceProtocol)? = nil
}

extension EnvironmentValues {
    /// PDF 导出服务
    ///
    /// 使用示例:
    /// ```swift
    /// // 注入 Mock
    /// ExportView()
    ///     .environment(\.pdfExportService, MockPDFExportService())
    ///
    /// // 读取
    /// @Environment(\.pdfExportService) var pdfExportService
    /// ```
    var pdfExportService: (any PDFExportServiceProtocol)? {
        get { self[PDFExportServiceKey.self] }
        set { self[PDFExportServiceKey.self] = newValue }
    }
}

// MARK: - Repository Environment Key

/// ReviewItemRepositoryProtocol 环境键
private struct RepositoryKey: EnvironmentKey {
    static let defaultValue: (any ReviewItemRepositoryProtocol)? = nil
}

extension EnvironmentValues {
    /// 错题仓库
    ///
    /// 使用示例:
    /// ```swift
    /// // 注入
    /// ContentView()
    ///     .environment(\.repository, repository)
    ///
    /// // 读取
    /// @Environment(\.repository) var repository
    /// ```
    var repository: (any ReviewItemRepositoryProtocol)? {
        get { self[RepositoryKey.self] }
        set { self[RepositoryKey.self] = newValue }
    }
}

// MARK: - Analytics Service Environment Key

/// AnalyticsServiceProtocol 环境键
private struct AnalyticsServiceKey: EnvironmentKey {
    static let defaultValue: (any AnalyticsServiceProtocol)? = nil
}

extension EnvironmentValues {
    /// 埋点服务
    ///
    /// 使用示例:
    /// ```swift
    /// // 注入 Mock
    /// ContentView()
    ///     .environment(\.analyticsService, MockAnalyticsService())
    ///
    /// // 读取
    /// @Environment(\.analyticsService) var analytics
    /// ```
    var analyticsService: (any AnalyticsServiceProtocol)? {
        get { self[AnalyticsServiceKey.self] }
        set { self[AnalyticsServiceKey.self] = newValue }
    }
}

// MARK: - View Modifiers for Convenience

extension View {
    /// 注入数据提供者
    ///
    /// - Parameter provider: 数据提供者实例
    /// - Returns: 修改后的视图
    func dataProvider(_ provider: any ReviewItemDataProviding) -> some View {
        environment(\.dataProvider, provider)
    }
    
    /// 注入 OCR 服务
    ///
    /// - Parameter service: OCR 服务实例
    /// - Returns: 修改后的视图
    func ocrService(_ service: any OCRServiceProtocol) -> some View {
        environment(\.ocrService, service)
    }
    
    /// 注入 PDF 导出服务
    ///
    /// - Parameter service: PDF 导出服务实例
    /// - Returns: 修改后的视图
    func pdfExportService(_ service: any PDFExportServiceProtocol) -> some View {
        environment(\.pdfExportService, service)
    }
    
    /// 注入错题仓库
    ///
    /// - Parameter repository: 仓库实例
    /// - Returns: 修改后的视图
    func repository(_ repository: any ReviewItemRepositoryProtocol) -> some View {
        environment(\.repository, repository)
    }
    
    /// 注入埋点服务
    ///
    /// - Parameter service: 埋点服务实例
    /// - Returns: 修改后的视图
    func analyticsService(_ service: any AnalyticsServiceProtocol) -> some View {
        environment(\.analyticsService, service)
    }
}

// MARK: - Dependencies Container View Modifier

/// 依赖容器视图修饰器
///
/// 一次性注入所有依赖，简化应用入口配置
struct DependenciesModifier: ViewModifier {
    let dataProvider: (any ReviewItemDataProviding)?
    let ocrService: (any OCRServiceProtocol)?
    let pdfExportService: (any PDFExportServiceProtocol)?
    let repository: (any ReviewItemRepositoryProtocol)?
    
    func body(content: Content) -> some View {
        var result = AnyView(content)
        
        if let provider = dataProvider {
            result = AnyView(result.environment(\.dataProvider, provider))
        }
        if let ocr = ocrService {
            result = AnyView(result.environment(\.ocrService, ocr))
        }
        if let pdf = pdfExportService {
            result = AnyView(result.environment(\.pdfExportService, pdf))
        }
        if let repo = repository {
            result = AnyView(result.environment(\.repository, repo))
        }
        
        return result
    }
}

extension View {
    /// 注入所有依赖
    ///
    /// - Parameters:
    ///   - dataProvider: 数据提供者（可选）
    ///   - ocrService: OCR 服务（可选）
    ///   - pdfExportService: PDF 导出服务（可选）
    ///   - repository: 仓库（可选）
    /// - Returns: 修改后的视图
    func withDependencies(
        dataProvider: (any ReviewItemDataProviding)? = nil,
        ocrService: (any OCRServiceProtocol)? = nil,
        pdfExportService: (any PDFExportServiceProtocol)? = nil,
        repository: (any ReviewItemRepositoryProtocol)? = nil
    ) -> some View {
        modifier(DependenciesModifier(
            dataProvider: dataProvider,
            ocrService: ocrService,
            pdfExportService: pdfExportService,
            repository: repository
        ))
    }
}

// MARK: - DependencyFactory Environment Key

/// 依赖工厂环境键
///
/// 用于通过 SwiftUI Environment 注入完整的依赖工厂
private struct DependencyFactoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: DependencyFactory? = nil
}

extension EnvironmentValues {
    /// 依赖工厂
    ///
    /// 使用示例:
    /// ```swift
    /// // 注入
    /// ContentView()
    ///     .environment(\.dependencyFactory, factory)
    ///
    /// // 读取
    /// @Environment(\.dependencyFactory) var factory
    /// ```
    var dependencyFactory: DependencyFactory? {
        get { self[DependencyFactoryKey.self] }
        set { self[DependencyFactoryKey.self] = newValue }
    }
}

// MARK: - DependencyFactory View Modifier

/// 依赖工厂注入修饰符
struct WithDependencyFactory: ViewModifier {
    let factory: DependencyFactory
    
    func body(content: Content) -> some View {
        content.environment(\.dependencyFactory, factory)
    }
}

extension View {
    /// 注入依赖工厂
    ///
    /// - Parameter factory: 依赖工厂实例
    /// - Returns: 修改后的视图
    func withDependencyFactory(_ factory: DependencyFactory) -> some View {
        modifier(WithDependencyFactory(factory: factory))
    }
    
    /// 注入依赖工厂（简写版本）
    ///
    /// - Parameter factory: 依赖工厂实例
    /// - Returns: 修改后的视图
    func withDependencies(_ factory: DependencyFactory) -> some View {
        modifier(WithDependencyFactory(factory: factory))
    }
}
