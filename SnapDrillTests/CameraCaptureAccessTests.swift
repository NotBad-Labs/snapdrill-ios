import Testing
@testable import SnapDrill

@Test @MainActor
func cameraHardwareAvailabilityIsReported() {
    // Simulator / Mac 上可能无相机；只验证 API 可调、不崩溃。
    _ = CameraCaptureAccess.isHardwareAvailable
    _ = CameraCaptureAccess.authorizationStatus
}