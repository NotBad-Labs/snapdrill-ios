import SwiftUI

public struct PrivacyPolicyView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("隐私政策")
                    .font(.largeTitle)
                    .bold()
                
                Text("最后更新日期：2025年12月31日")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Group {
                    Text("1. 我们收集的信息")
                        .font(.headline)
                    Text("NotBad 需要使用您的**相机权限**来拍摄错题。拍摄的照片仅保存在您的本地设备上（通过 SwiftData 和文件系统）。我们**不会**将您的照片、题目内容或任何个人信息上传到我们的服务器。")
                    
                    Text("2. 数据安全")
                        .font(.headline)
                    Text("您的所有数据均存储在设备本地。如果您删除了应用，数据将一同被删除（除非您进行了 iCloud 备份）。")
                    
                    Text("3. 第三方服务")
                        .font(.headline)
                    Text("本应用不包含广告，也不使用任何第三方追踪器来收集您的个人身份信息。我们可能会收集匿名的崩溃日志（如 Apple Crash Reports）以改进应用稳定性。")
                    
                    Text("4. 联系我们")
                        .font(.headline)
                    Text("如果您对本隐私政策有任何疑问，请通过 App Store 支持链接联系我们。")
                }
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
