import SwiftUI

/// Displayed when SwiftData fails to open on launch instead of falsely rendering an empty notebook (PRD §8.6, AC-09).
struct DatabaseRecoveryView: View {
    let errorDescription: String
    let imageStore: MistakeImageStore

    @State private var exportedImageFolderURL: URL?
    @State private var showingShareSheet = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(SnapDrillTheme.gradingRed)
                    .padding(18)
                    .background(SnapDrillTheme.gradingRedSoft, in: Circle())

                Text("Unable to Open Mistake Library")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                    .multilineTextAlignment(.center)

                Text("Your local database encountered an unexpected storage issue. SnapDrill has paused opening to protect your existing records from being overwritten.")
                    .font(.subheadline)
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                PaperCard {
                    Text(errorDescription)
                        .font(.caption.monospaced())
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    exportRawImagesArchive()
                } label: {
                    Label("Export Saved Photos Archive", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }

                Spacer()
            }
            .padding(24)
            .paperBackground()
            .navigationTitle("Storage Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                if let exportedImageFolderURL {
                    ActivityShareSheet(items: [exportedImageFolderURL])
                }
            }
        }
    }

    private func exportRawImagesArchive() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: imageStore.rootDirectory.path) else {
            statusMessage = String(localized: "No stored image folder was found on this device.")
            return
        }

        let targetURL = fm.temporaryDirectory.appendingPathComponent("SnapDrill-Recovery-Images.zip")
        try? fm.removeItem(at: targetURL)

        var coordError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(readingItemAt: imageStore.rootDirectory, options: .forUploading, error: &coordError) { url in
            do {
                try fm.copyItem(at: url, to: targetURL)
            } catch {
                copyError = error
            }
        }

        if let err = coordError ?? copyError {
            statusMessage = err.localizedDescription
        } else {
            exportedImageFolderURL = targetURL
            showingShareSheet = true
        }
    }
}

/// Shared UIActivityViewController bridge for exporting PDFs, images, and ZIP backups.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
