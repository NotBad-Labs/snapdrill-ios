import AVFoundation
import UIKit

/// 采集入口的相机可用性（权限与硬件）；图像数据仍经 `CapturePipelineServing.beginSession`。
@MainActor
enum CameraCaptureAccess {
    static var isHardwareAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    static var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    static var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized:
            return true
        case .notDetermined, .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    static var isDeniedOrRestricted: Bool {
        switch authorizationStatus {
        case .denied, .restricted:
            return true
        default:
            return false
        }
    }

    @MainActor
    static func requestAccessIfNeeded() async -> Bool {
        guard isHardwareAvailable else { return false }
        switch authorizationStatus {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}