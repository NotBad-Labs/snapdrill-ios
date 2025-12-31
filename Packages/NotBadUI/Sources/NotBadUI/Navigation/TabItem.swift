import Foundation

/// 定义应用中所有的 Tab 项
public enum TabItem: Hashable, CaseIterable {
    case dashboard
    case library
    case capture
    case review
    case settings
    
    public var title: String {
        switch self {
        case .dashboard: return "首页"
        case .library: return "题库"
        case .capture: return "采集"
        case .review: return "复习"
        case .settings: return "设置"
        }
    }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "house"
        case .library: return "books.vertical"
        case .capture: return "camera"
        case .review: return "clock.arrow.circlepath"
        case .settings: return "gear"
        }
    }
}
