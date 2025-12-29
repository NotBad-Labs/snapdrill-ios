import SwiftUI
import NotBadCore
import NotBadUI
import NotBadData

/// 题库功能界面
public struct LibraryView: View {
    public init() {}
    
    public var body: some View {
        List {
            Text("题库列表")
        }
        .navigationTitle("我的题库")
    }
}
