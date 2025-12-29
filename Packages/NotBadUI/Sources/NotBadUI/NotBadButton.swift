import SwiftUI

/// 全局设计系统组件
public struct NotBadButton: View {
    let title: String
    let action: () -> Void
    
    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    public var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
    }
}
