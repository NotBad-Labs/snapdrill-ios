import SwiftUI

// MARK: - StudyStatusCard
// 位置: Presentation/Features/StudyPractice/Components/StudyStatusCard.swift

/// 学习状态卡片组件
/// 单一职责：显示当前学习状态，包含时间显示、状态文字和控制按钮
/// 符合企业级开发标准：可复用、可测试、可维护
struct StudyStatusCard: View {
    
    // MARK: - Properties
    
    /// 是否正在学习
    let isStudying: Bool
    
    /// 学习时长（秒）
    let studyTimeSeconds: Int
    
    /// 开始学习回调
    let onStart: () -> Void
    
    /// 暂停学习回调
    let onPause: () -> Void
    
    /// 继续学习回调
    let onResume: () -> Void
    
    /// 结束学习回调
    let onEnd: () -> Void
    
    /// 重置学习回调
    let onReset: () -> Void
    
    // MARK: - Initialization
    
    init(
        isStudying: Bool,
        studyTimeSeconds: Int,
        onStart: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onResume: @escaping () -> Void,
        onEnd: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self.isStudying = isStudying
        self.studyTimeSeconds = studyTimeSeconds
        self.onStart = onStart
        self.onPause = onPause
        self.onResume = onResume
        self.onEnd = onEnd
        self.onReset = onReset
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // 时间显示区域
            timeDisplaySection
            
            // 状态文字区域
            statusTextSection
            
            // 控制按钮区域
            controlButtonsSection
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Private Views
    
    /// 时间显示区域
    private var timeDisplaySection: some View {
        Text(formatStudyTime(studyTimeSeconds))
            .font(.system(size: 48, weight: .bold, design: .monospaced))
            .foregroundColor(isStudying ? .blue : .secondary)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.3), value: studyTimeSeconds)
    }
    
    /// 状态文字区域
    private var statusTextSection: some View {
        VStack(spacing: 8) {
            Text(isStudying ? "学习进行中..." : studyTimeSeconds > 0 ? "学习已暂停" : "准备开始学习")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(statusDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    /// 状态描述文字
    private var statusDescription: String {
        if isStudying {
            return "保持专注，你正在进步！"
        } else if studyTimeSeconds > 0 {
            return "点击继续按钮恢复学习"
        } else {
            return "选择一个学习模式开始吧"
        }
    }
    
    /// 控制按钮区域
    private var controlButtonsSection: some View {
        HStack(spacing: 16) {
            if isStudying {
                // 学习中：显示暂停按钮
                pauseButton
            } else {
                // 未学习或已暂停：显示开始/继续按钮
                startOrResumeButton
            }
            
            // 如果有学习时间，显示结束和重置按钮
            if studyTimeSeconds > 0 {
                endButton
                resetButton
            }
        }
    }
    
    /// 暂停按钮
    private var pauseButton: some View {
        Button("暂停") {
            onPause()
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
    
    /// 开始/继续按钮
    private var startOrResumeButton: some View {
        Button(studyTimeSeconds > 0 ? "继续" : "开始") {
            if studyTimeSeconds > 0 {
                onResume()
            } else {
                onStart()
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    /// 结束按钮
    private var endButton: some View {
        Button("结束") {
            onEnd()
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
    
    /// 重置按钮
    private var resetButton: some View {
        Button("重置") {
            onReset()
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
        .foregroundColor(.red)
    }
    
    // MARK: - Private Methods
    
    /// 格式化学习时间
    private func formatStudyTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct StudyStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 初始状态
            StudyStatusCard(
                isStudying: false,
                studyTimeSeconds: 0,
                onStart: { print("开始学习") },
                onPause: { print("暂停学习") },
                onResume: { print("继续学习") },
                onEnd: { print("结束学习") },
                onReset: { print("重置学习") }
            )
            
            // 学习中状态
            StudyStatusCard(
                isStudying: true,
                studyTimeSeconds: 1847, // 30:47
                onStart: { print("开始学习") },
                onPause: { print("暂停学习") },
                onResume: { print("继续学习") },
                onEnd: { print("结束学习") },
                onReset: { print("重置学习") }
            )
            
            // 暂停状态
            StudyStatusCard(
                isStudying: false,
                studyTimeSeconds: 2435, // 40:35
                onStart: { print("开始学习") },
                onPause: { print("暂停学习") },
                onResume: { print("继续学习") },
                onEnd: { print("结束学习") },
                onReset: { print("重置学习") }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif