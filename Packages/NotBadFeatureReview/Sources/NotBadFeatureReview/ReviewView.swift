import SwiftUI
import NotBadCore
import NotBadEngine
import NotBadUI
import NotBadData

/// 复习功能界面
public struct ReviewView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("复习会话")
                .font(.headline)
            
            Spacer()
            
            Text("今日待复习: 0")
        }
    }
}
