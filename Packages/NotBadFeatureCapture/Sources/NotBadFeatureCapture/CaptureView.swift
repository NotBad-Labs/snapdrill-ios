import SwiftUI
import NotBadCore
import NotBadUI
import NotBadService

/// 采集功能界面
public struct CaptureView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Text("题目采集")
                .font(.title)
            
            NotBadButton(title: "开始拍照") {
                print("Start capturing...")
            }
        }
    }
}
