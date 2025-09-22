//
//  CameraView.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI
import AVFoundation
import Photos

/// 相机视图
/// 使用AVFoundation捕获照片
struct CameraView: View {
    @ObservedObject var viewModel: CaptureViewModel
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 相机预览背景
            Color.black.ignoresSafeArea()
            
            // 相机预览
            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()
            
            // 控制界面
            VStack {
                // 顶部控制栏
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    // 闪光灯控制
                    Button(action: {
                        cameraManager.toggleFlashlight()
                    }) {
                        Image(systemName: cameraManager.isFlashlightOn ? "bolt.fill" : "bolt.slash.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .padding()
                }
                
                Spacer()
                
                // 底部拍照控制
                HStack {
                    Spacer()
                    
                    // 拍照按钮
                    Button(action: {
                        cameraManager.capturePhoto { result in
                            switch result {
                            case .success(let imageData):
                                // 拍照成功，处理图片
                                handleCapturedImage(imageData)
                            case .failure(let error):
                                print("拍照失败: \(error)")
                            }
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                    .disabled(!cameraManager.isSessionRunning)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            cameraManager.requestCameraPermission { granted in
                if granted {
                    cameraManager.startSession()
                } else {
                    // 权限被拒绝，显示设置提示
                    dismiss()
                }
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    /// 处理拍摄的图片
    private func handleCapturedImage(_ imageData: Data) {
        // 保存到相册（可选）
        saveImageToPhotoLibrary(imageData)
        
        // 关闭相机界面
        dismiss()
        
        // 交给ViewModel处理OCR流程
        if let image = UIImage(data: imageData) {
            viewModel.handleCapturedImage(image)
        }
    }
    
    /// 保存图片到相册
    private func saveImageToPhotoLibrary(_ imageData: Data) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges {
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: imageData, options: nil)
            }
        }
    }
}

/// 相机预览视图
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // 更新UI如果需要
    }
}

/// 相机管理器
class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isFlashlightOn = false
    
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureDevice: AVCaptureDevice?
    private var photoCompletion: ((Result<Data, Error>) -> Void)?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    override init() {
        super.init()
        // 在独立队列上配置相机会话，避免阻塞主线程
        sessionQueue.sync {
            setupCamera()
        }
    }
    
    /// 设置相机
    private func setupCamera() {
        session.beginConfiguration()
        
        // 设置会话质量
        session.sessionPreset = .photo
        
        // 添加视频输入
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            captureDevice = camera
        }
        
        // 添加照片输出
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        session.commitConfiguration()
    }
    
    /// 请求相机权限
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// 开始会话
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    /// 停止会话
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    /// 拍照
    func capturePhoto(completion: @escaping (Result<Data, Error>) -> Void) {
        self.photoCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashlightOn ? .on : .off
        
        // 在会话队列上触发拍照，序列化与会话的交互
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    /// 切换闪光灯
    func toggleFlashlight() {
        guard let device = captureDevice, device.hasTorch else { return }
        
        sessionQueue.async { [weak self] in
            guard let self else { return }
            do {
                try device.lockForConfiguration()
                var torchOn = false
                if device.torchMode == .on {
                    device.torchMode = .off
                    torchOn = false
                } else {
                    try device.setTorchModeOn(level: 1.0)
                    torchOn = true
                }
                device.unlockForConfiguration()
                DispatchQueue.main.async {
                    self.isFlashlightOn = torchOn
                }
            } catch {
                print("闪光灯切换失败: \(error)")
            }
        }
    }
}

/// 照片捕获代理
extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            Task { @MainActor in
                photoCompletion?(.failure(error))
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            Task { @MainActor in
                photoCompletion?(.failure(CameraError.noImageData))
            }
            return
        }
        
        Task { @MainActor in
            photoCompletion?(.success(imageData))
            photoCompletion = nil
        }
    }
}

/// 相机错误
enum CameraError: Error {
    case noImageData
    case permissionDenied
    case sessionSetupFailed
}

#Preview {
    let coordinator = CaptureCoordinator()
    let vm = CaptureViewModel(captureUseCase: ServiceContainer.shared.captureReviewItemUseCase, coordinator: coordinator)
    CameraView(viewModel: vm)
}