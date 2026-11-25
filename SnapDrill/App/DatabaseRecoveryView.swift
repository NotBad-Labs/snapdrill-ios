import SwiftUI

/// Displayed when SwiftData fails to open on launch instead of falsely rendering an empty notebook (PRD §8.6, AC-09).
struct DatabaseRecoveryView: View {
    let errorDescription: String
    let storeURL: URL
    let imageStore: MistakeImageStore
    let onRebuildLibrary: () -> Void

    @State private var exportedPackageURL: URL?
    @State private var showingShareSheet = false
    @State private var showingRebuildConfirmation = false
    @State private var hasExportedArchive = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(SnapDrillTheme.gradingRed)
                    .padding(18)
                    .background(SnapDrillTheme.gradingRedSoft, in: Circle())
                    .accessibilityHidden(true)

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

                VStack(spacing: 10) {
                    Button {
                        exportFullRecoveryArchive()
                    } label: {
                        Label("Export Recovery Package (.zip)", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.vertical, 13)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Export Recovery Package"))

                    Button {
                        showingRebuildConfirmation = true
                    } label: {
                        Label("Archive Old Store & Rebuild Empty Library", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Archive Old Store & Rebuild Empty Library"))
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(24)
            .paperBackground()
            .navigationTitle(String(localized: "Storage Recovery"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShareSheet) {
                if let exportedPackageURL {
                    ActivityShareSheet(items: [exportedPackageURL])
                }
            }
            .alert(String(localized: "Rebuild Mistake Library?"), isPresented: $showingRebuildConfirmation) {
                Button(String(localized: "Archive & Rebuild"), role: .destructive) {
                    archiveAndRebuildStore()
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: {
                Text(
                    hasExportedArchive
                        ? String(localized: "Your unreadable database files will be archived safely inside Application Support (not deleted) before opening a fresh empty notebook.")
                        : String(localized: "We recommend exporting the recovery ZIP first. Continuing will move the unreadable database files to an archive folder (not deleted) and create a new empty notebook.")
                )
            }
        }
    }

    private func exportFullRecoveryArchive() {
        do {
            let archiveURL = try ModelContainerFactory.createRecoveryPackageArchive(
                storeURL: storeURL,
                imageStore: imageStore,
                errorSummary: errorDescription
            )
            exportedPackageURL = archiveURL
            hasExportedArchive = true
            statusMessage = String(localized: "Recovery archive prepared with database files and saved images.")
            showingShareSheet = true
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func archiveAndRebuildStore() {
        do {
            _ = try ModelContainerFactory.archiveCorruptedStoreFiles(storeURL: storeURL)
            onRebuildLibrary()
        } catch {
            statusMessage = error.localizedDescription
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
