import AVFoundation

/// Encapsulates AVCaptureDevice checks so UI code never imports AVFoundation directly.
struct CameraAccessService: CameraAccessChecking {
    private var hasCameraHardware: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    func authorizationState() -> CameraAuthorizationState {
        guard hasCameraHardware else {
            return .unavailable
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    func requestAccess() async -> CameraAuthorizationState {
        guard hasCameraHardware else {
            return .unavailable
        }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        return granted ? .authorized : authorizationState()
    }
}
