import SwiftUI

struct AddMethodSelector: View {
    @Binding var selectedMethod: AddMethod
    
    var body: some View {
        VStack(spacing: 16) {
            Text("选择添加方式")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AddMethod.allCases, id: \.self) { method in
                    AddMethodCard(
                        method: method,
                        isSelected: selectedMethod == method
                    ) {
                        selectedMethod = method
                    }
                }
            }
        }
        .padding()
    }
}

struct AddMethodCard: View {
    let method: AddMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: method.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(method.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(method.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum AddMethod: String, CaseIterable {
    case manual = "manual"
    case photo = "photo"
    case import = "import"
    case ai = "ai"
    
    var title: String {
        switch self {
        case .manual:
            return "手动输入"
        case .photo:
            return "拍照识别"
        case .import:
            return "文件导入"
        case .ai:
            return "AI生成"
        }
    }
    
    var description: String {
        switch self {
        case .manual:
            return "手动创建题目"
        case .photo:
            return "拍照识别文字"
        case .import:
            return "导入题目文件"
        case .ai:
            return "AI智能生成"
        }
    }
    
    var iconName: String {
        switch self {
        case .manual:
            return "pencil"
        case .photo:
            return "camera"
        case .import:
            return "folder"
        case .ai:
            return "brain.head.profile"
        }
    }
}

// MARK: - Preview
struct AddMethodSelector_Previews: PreviewProvider {
    static var previews: some View {
        AddMethodSelector(selectedMethod: .constant(.manual))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
