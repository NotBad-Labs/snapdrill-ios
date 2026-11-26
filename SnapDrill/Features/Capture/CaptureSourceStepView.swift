import PhotosUI
import SwiftUI

/// Step 0: Camera / album source selection card (zero Vision/AVFoundation imports).
struct CaptureSourceStepView: View {
    let cameraAuthState: CameraAuthorizationState
    let maxPhotoCount: Int
    @Binding var selectedPhotoItems: [PhotosPickerItem]
    let onOpenCamera: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PaperCard(padding: 20) {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .frame(width: 78, height: 78)
                            .background(SnapDrillTheme.inkBlueSoft, in: Circle())
                            .accessibilityHidden(true)

                        Text("Photograph Homework or Exam Pages")
                            .font(.headline)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                            .multilineTextAlignment(.center)

                        Text("Capture up to 10 pages in one batch. Scan, straighten, clean colored marks, and erase spots privately on your iPhone.")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                            .multilineTextAlignment(.center)

                        if cameraAuthState == .denied || cameraAuthState == .restricted {
                            VStack(spacing: 10) {
                                Text("Camera access is currently disabled. You can enable it in Settings or import photos directly from your album.")
                                    .font(.caption)
                                    .foregroundStyle(SnapDrillTheme.gradingRed)
                                    .multilineTextAlignment(.center)

                                Button("Open System Settings", action: onOpenSettings)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(SnapDrillTheme.inkBlue)
                                    .frame(minHeight: 44)
                            }
                            .padding(.top, 4)
                        } else if cameraAuthState == .unavailable {
                            Text("Camera hardware is unavailable on this simulator; use Photos Import below.")
                                .font(.caption)
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                        } else {
                            Button(action: onOpenCamera) {
                                Label("Open Camera", systemImage: "camera.fill")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 13)
                                    .padding(.horizontal, 16)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: maxPhotoCount,
                            matching: .images
                        ) {
                            Label("Import from Photos (Up to 10)", systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(SnapDrillTheme.inkBlueSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
            .padding(SnapDrillTheme.screenPadding)
        }
    }
}
