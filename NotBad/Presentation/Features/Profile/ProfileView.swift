import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.gray)
                    .padding()
                
                Text("我的")
                    .font(.title)
                    .bold()
                
                Text("这里将展示用户设置和个人信息")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("我的")
        }
    }
}

#Preview {
    ProfileView()
}
