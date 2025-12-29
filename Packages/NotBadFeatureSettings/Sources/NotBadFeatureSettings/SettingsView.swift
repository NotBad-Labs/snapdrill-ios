import SwiftUI
import NotBadCore
import NotBadUI
import NotBadService

/// 设置功能界面
public struct SettingsView: View {
    public init() {}
    
    public var body: some View {
        Form {
            Section("通用") {
                Text("版本: 1.0.0")
            }
        }
        .navigationTitle("设置")
    }
}
