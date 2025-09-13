//
//  CameraView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import AVFoundation
import SwiftUI
import UIKit

/// 相机视图 - Phase 1实现
struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var capturedImage: UIImage?
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // 更新逻辑
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage) {
            Task { @MainActor [parent] in
                parent.capturedImage = image
                parent.isPresented = false
            }
        }
        
        func cameraViewControllerDidCancel(_ controller: CameraViewController) {
            Task { @MainActor [parent] in
                parent.isPresented = false
            }
        }
    }
}

/// 相机视图控制器
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureOutput: AVCapturePhotoOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            captureOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(captureOutput) {
                captureSession.addOutput(captureOutput)
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            
            view.layer.addSublayer(previewLayer)
            
        } catch {
            print("相机设置失败: \(error)")
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // 顶部工具栏
        let topToolbar = UIView()
        topToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        topToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topToolbar)
        
        // 取消按钮
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.addSubview(cancelButton)
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.text = "拍摄错题"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.addSubview(titleLabel)
        
        // 底部工具栏
        let bottomToolbar = UIView()
        bottomToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomToolbar)
        
        // 拍照按钮
        let captureButton = UIButton(type: .system)
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.borderWidth = 4
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(captureButton)
        
        // 约束设置
        NSLayoutConstraint.activate([
            // 顶部工具栏
            topToolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topToolbar.heightAnchor.constraint(equalToConstant: 60),
            
            // 取消按钮
            cancelButton.leadingAnchor.constraint(equalTo: topToolbar.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            
            // 标题
            titleLabel.centerXAnchor.constraint(equalTo: topToolbar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            
            // 底部工具栏
            bottomToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 120),
            
            // 拍照按钮
            captureButton.centerXAnchor.constraint(equalTo: bottomToolbar.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    @objc private func cancelButtonTapped() {
        Task { @MainActor [weak self] in
            self?.delegate?.cameraViewControllerDidCancel(self!)
        }
    }
    
    @objc private func captureButtonTapped() {
        let settings = AVCapturePhotoSettings()
        captureOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("拍照失败: \(error?.localizedDescription ?? "未知错误")")
            return
        }
        
        Task { @MainActor [weak self] in
            self?.delegate?.cameraViewController(self!, didCaptureImage: image)
        }
    }
}

// MARK: - CameraViewControllerDelegate
protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCaptureImage image: UIImage)
    func cameraViewControllerDidCancel(_ controller: CameraViewController)
}
