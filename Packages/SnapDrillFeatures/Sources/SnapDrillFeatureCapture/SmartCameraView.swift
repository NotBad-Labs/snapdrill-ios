//
//  SmartCameraView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  智能相机视图，集成实时 OCR 识别与矩形检测。
//

import SwiftUI
import SnapDrillCore
import SnapDrillUI

/// 智能相机 SwiftUI 视图
struct SmartCameraView: View {
    
    // MARK: - Properties
    
    var onCapture: (UIImage) -> Void
    var onCancel: () -> Void
    
    @State private var detectedRect: CGRect? // Normalised 0-1
    @State private var isStable: Bool = false
    @State private var shouldCapture: Bool = false
    @State private var isCapturing: Bool = false
    
    var body: some View {
        ZStack {
            SmartCameraRepresentable(
                detectedRect: $detectedRect,
                isStable: $isStable,
                shouldCapture: $shouldCapture
            ) { image, rect in
                    cropAndFinish(image: image, rect: rect)
                }
            .ignoresSafeArea()
            
            // MARK: - Body
            
            // 覆盖层 UI
            VStack {
                // 顶部栏
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .accessibleButton(label: L10n.Accessibility.cancelCamera)
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // 底部栏
                HStack {
                    Spacer()
                    
                    // 快门按钮
                    Button(action: takePhoto) {
                        ZStack {
                            Circle()
                                .stroke(.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            
                            Circle()
                                .fill(isStable ? Color.green : Color.white)
                                .frame(width: 60, height: 60)

                            if isCapturing {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(isStable ? .white : .black)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .accessibleButton(label: L10n.Accessibility.takePhoto)
                    .disabled(isCapturing)
                    .padding(.bottom, 40)
                    // HIG：快门按下用 medium impact 模拟物理反馈
                    .sensoryFeedback(.impact(weight: .medium), trigger: shouldCapture) { _, newValue in
                        newValue
                    }

                    Spacer()
                }
            }
            
            // 智能取景框覆盖层
            GeometryReader { geo in
                let targetRect = detectedRect ?? CGRect(x: 0.1, y: 0.4, width: 0.8, height: 0.2) // Default Search Area centered
                
                CornerBracketShape(cornerLength: 20)
                    .stroke(isStable ? Color.green : Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(
                        width: targetRect.width * geo.size.width,
                        height: targetRect.height * geo.size.height
                    )
                    .position(
                        x: targetRect.midX * geo.size.width,
                        y: (1 - targetRect.midY) * geo.size.height
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: targetRect)
                    // .opacity(0.8) // Keep it crisp
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            
            // 状态提示文字
            Text(cameraStatusText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(8)
                .background(isStable ? Color.green.opacity(0.6) : Color.black.opacity(0.4))
                .clipShape(Capsule())
                .padding(.top, 100)
                .animation(.easeInOut(duration: 0.3), value: isStable)
        }
    }

    private var cameraStatusText: String {
        if isCapturing { return L10n.Capture.cameraCapturingHint }
        return isStable ? L10n.Capture.cameraReadyHint : L10n.Capture.cameraScanningHint
    }
    
    func takePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        shouldCapture = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            guard isCapturing else { return }
            isCapturing = false
        }
    }
    
    func cropAndFinish(image: UIImage, rect: CGRect) {
        // 使用 Vision 检测到的矩形区域裁剪图片
        // 如果裁剪失败，则返回原始图片
        
        let crop = cropImage(image, to: rect)
        isCapturing = false
        onCapture(crop ?? image)
    }
    
    func cropImage(_ image: UIImage, to normalizedRect: CGRect) -> UIImage? {
        // 1. 标准化方向
        // Vision 坐标系 (0,0 左下角) 对应逻辑上正立的图片。
        // 如果 UIImage 方向是 .right（旋转 90 度），直接裁剪 CGImage 会出错。
        // 先将图片绘制为正立方向，确保坐标系匹配。
        
        // 使用 UIGraphicsImageRenderer 进行线程安全的绘制
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale // Keep original scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let normalizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        guard let sourceCGImage = normalizedImage.cgImage else { return nil }

        // 2. 将归一化矩形（左下角原点）转换为 CGImage 像素坐标（左上角原点）
        let width = CGFloat(sourceCGImage.width)
        let height = CGFloat(sourceCGImage.height)
        
        // Vision Y 轴从底部开始，Image Y 轴从顶部开始
        // rectY = (1 - visionY - visionHeight) * imageHeight
        let rectY = (1 - normalizedRect.origin.y - normalizedRect.height) * height
        let rectX = normalizedRect.origin.x * width
        let rectW = normalizedRect.width * width
        let rectH = normalizedRect.height * height
        
        let imageBounds = CGRect(x: 0, y: 0, width: width, height: height)
        let cropRect = CGRect(x: rectX, y: rectY, width: rectW, height: rectH)
            .intersection(imageBounds)
            .integral
        guard cropRect.width > 0, cropRect.height > 0 else { return nil }
        
        // 3. 裁剪
        guard let cgImage = sourceCGImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
}

struct SmartCameraRepresentable: UIViewControllerRepresentable {
    @Binding var detectedRect: CGRect?
    @Binding var isStable: Bool
    @Binding var shouldCapture: Bool
    var onCaptureResult: (UIImage, CGRect) -> Void
    
    func makeUIViewController(context: Context) -> SmartCameraViewController {
        let controller = SmartCameraViewController()
        controller.onRegionDetected = { rect, isStable in
            self.detectedRect = rect
            self.isStable = isStable
        }
        controller.onCapture = { image, rect in
            self.onCaptureResult(image, rect)
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SmartCameraViewController, context: Context) {
        if shouldCapture {
            uiViewController.capturePhoto()
            DispatchQueue.main.async {
                self.shouldCapture = false
            }
        }
    }
}

#Preview {
    SmartCameraView(onCapture: { _ in }, onCancel: {})
}
