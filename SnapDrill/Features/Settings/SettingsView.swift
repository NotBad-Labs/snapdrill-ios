import StoreKit
import SwiftData
import SwiftUI

/// Tab 3: Pro status, iCloud sync toggle + live status, organization managers, preferences, storage, backup ZIP, and privacy policy links.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \MistakeItem.createdAt, order: .reverse) private var mistakes: [MistakeItem]

    @State private var showingPaywall = false
    @State private var showingManageSubs = false
    @State private var storageBytes: Int64 = 0
    @State private var backupArchiveURL: URL?
    @State private var statusAlertMessage: String?
    @State private var isPopulatingDemo = false

    var body: some View {
        @Bindable var prefs = environment.preferences

        NavigationStack {
            Form {
                proSection(prefs: prefs)
                    .listRowBackground(SnapDrillTheme.cardSurface)
                organizationSection
                    .listRowBackground(SnapDrillTheme.cardSurface)
                preferencesSection(prefs: prefs)
                    .listRowBackground(SnapDrillTheme.cardSurface)
                dataAndBackupSection
                    .listRowBackground(SnapDrillTheme.cardSurface)
                privacySection
                    .listRowBackground(SnapDrillTheme.cardSurface)

                #if DEBUG
                debugTestingSection
                    .listRowBackground(SnapDrillTheme.cardSurface)
                #endif
            }
            .scrollContentBackground(.hidden)
            .paperBackground()
            .navigationTitle(String(localized: "Settings"))
            .onAppear {
                refreshStorageFootprint()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .manageSubscriptionsSheet(isPresented: $showingManageSubs)
            .sheet(isPresented: Binding(
                get: { backupArchiveURL != nil },
                set: { if !$0 { cleanUpBackupURL() } }
            )) {
                if let backupArchiveURL {
                    ActivityShareSheet(items: [backupArchiveURL])
                }
            }
            .alert("Notice", isPresented: Binding(
                get: { statusAlertMessage != nil },
                set: { if !$0 { statusAlertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusAlertMessage ?? "")
            }
        }
    }

    // MARK: - Sections

    private func proSection(prefs: AppPreferencesStore) -> some View {
        Section("SnapDrill Pro") {
            Button {
                if environment.proStore.isPro {
                    showingManageSubs = true
                } else {
                    showingPaywall = true
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: environment.proStore.isPro ? "checkmark.seal.fill" : "sparkles")
                        .font(.title3)
                        .foregroundStyle(environment.proStore.isPro ? SnapDrillTheme.masteryGreen : SnapDrillTheme.inkBlue)
                        .frame(width: 36, height: 36)
                        .background(
                            (environment.proStore.isPro ? SnapDrillTheme.masteryGreenSoft : SnapDrillTheme.inkBlueSoft),
                            in: Circle()
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(proStatusTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                        Text(proStatusSubtitle)
                            .font(.caption)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: Binding(
                    get: { environment.proStore.isPro && prefs.iCloudSyncEnabled },
                    set: { newValue in
                        if environment.proStore.isPro {
                            prefs.iCloudSyncEnabled = newValue
                        } else {
                            showingPaywall = true
                        }
                    }
                )) {
                    HStack {
                        Label("iCloud Sync", systemImage: "icloud")
                        if !environment.proStore.isPro {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                        }
                    }
                }
                .tint(SnapDrillTheme.inkBlue)

                if environment.proStore.isPro && prefs.iCloudSyncEnabled {
                    Text(syncStatusDescription)
                        .font(.caption2)
                        .foregroundStyle(SnapDrillTheme.inkSecondary)
                }
            }
        }
    }

    private var organizationSection: some View {
        Section("Notebook Organization") {
            NavigationLink {
                SubjectManagementView()
            } label: {
                Label("Subjects", systemImage: "folder.fill")
            }

            NavigationLink {
                CauseAndTagManagementView()
            } label: {
                Label("Error Causes & Tags", systemImage: "tag.fill")
            }
        }
    }

    private func preferencesSection(prefs: AppPreferencesStore) -> some View {
        @Bindable var bindablePrefs = prefs
        return Section("Preferences") {
            Picker("Default Paper Size", selection: $bindablePrefs.preferredPaperSize) {
                ForEach(PaperSize.allCases) { size in
                    Text(size.localizedTitle).tag(size)
                }
            }

            Picker("Default Ink Removal", selection: $bindablePrefs.defaultInkRemovalMode) {
                ForEach(InkRemovalMode.allCases) { mode in
                    Text(mode.localizedTitle).tag(mode)
                }
            }

            Picker("Appearance", selection: $bindablePrefs.appearanceMode) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.localizedTitle).tag(mode)
                }
            }
        }
    }

    private var dataAndBackupSection: some View {
        Section {
            HStack {
                Label("Local Storage Used", systemImage: "internaldrive")
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: storageBytes, countStyle: .file))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
            }

            Button {
                pruneOrphanedCache()
            } label: {
                Label("Clean Orphaned Image Cache", systemImage: "sparkles.rectangle.stack")
            }

            Button {
                exportFullBackup()
            } label: {
                Label("Export Full Backup (.zip)", systemImage: "archivebox")
            }
        } header: {
            Text("Data & Backup (Always Free)")
        } footer: {
            Text("Your mistakes and images always remain editable, printable, and exportable even without a subscription.")
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            VStack(alignment: .leading, spacing: 6) {
                Label("100% On-Device Processing", systemImage: "hand.raised.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlue)
                Text("No account required. No ads, no analytics SDKs, and no images are ever uploaded to external servers. EXIF GPS coordinates are stripped locally before saving.")
                    .font(.caption)
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
            }
            .padding(.vertical, 4)

            Link(destination: AppConfig.privacyPolicyURL()) {
                Label("Privacy Policy", systemImage: "hand.raised.square")
            }

            Link(destination: AppConfig.termsOfUseURL()) {
                Label("Terms of Use (EULA)", systemImage: "doc.text")
            }
        }
    }

    #if DEBUG
    private var debugTestingSection: some View {
        Section("Developer Diagnostics") {
            LabeledContent {
                Text(verbatim: CoreMLCapableInkRemover.isCoreMLModelBundled ? "Core ML segmentation" : "Heuristic fallback")
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
            } label: {
                Text(verbatim: "Ink Removal Engine")
            }

            Picker(
                "Subscription Simulation",
                selection: Binding(
                    get: { environment.proStore.debugOverride },
                    set: { environment.proStore.debugOverride = $0 }
                )
            ) {
                ForEach(DebugSubscriptionOverride.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }

            Button {
                loadDemoMistakes()
            } label: {
                HStack {
                    Label("Load Sample Mistakes", systemImage: "wand.and.stars")
                    if isPopulatingDemo {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(isPopulatingDemo)
        }
    }
    #endif

    // MARK: - Helpers

    private var syncStatusDescription: String {
        switch environment.storeSyncStatus {
        case .cloudKitPrivate:
            return String(localized: "Private iCloud CloudKit sync active")
        case .cloudKitFallbackToLocal:
            return String(localized: "CloudKit unavailable on this build; using local storage safely")
        case .localOnly:
            return String(localized: "Local storage only")
        }
    }

    private var proStatusTitle: String {
        switch environment.proStore.statusState {
        case .free:
            return String(localized: "Upgrade to SnapDrill Pro")
        case .pro(_, let isTrial):
            return isTrial ? String(localized: "SnapDrill Pro (Free Trial)") : String(localized: "SnapDrill Pro Active")
        case .expiredFallback:
            return String(localized: "Pro Expired · Local Data Preserved")
        }
    }

    private var proStatusSubtitle: String {
        switch environment.proStore.statusState {
        case .free:
            return String(localized: "iCloud sync, watermark-free PDFs, OCR search & smart framing")
        case .pro:
            return String(localized: "Tap to manage your subscription or Family Sharing")
        case .expiredFallback:
            return String(localized: "All existing mistakes stay unlocked; tap to renew Pro")
        }
    }

    private func refreshStorageFootprint() {
        storageBytes = environment.imageStore.totalStorageBytes()
    }

    private func pruneOrphanedCache() {
        var validPaths = Set<String>()
        for m in mistakes {
            if let orig = m.originalImagePath { validPaths.insert(orig) }
            if let clean = m.cleanedImagePath { validPaths.insert(clean) }
            if let page = m.pageImagePath { validPaths.insert(page) }
            for ans in m.answerImagePaths { validPaths.insert(ans) }
        }
        let removed = environment.imageStore.pruneOrphanedFiles(keepingRelativePaths: validPaths)
        refreshStorageFootprint()
        statusAlertMessage = String(localized: "Cleaned \(removed) unused image files.")
    }

    private func exportFullBackup() {
        do {
            let url = try BackupExportService.createBackupArchive(
                in: modelContext,
                imageStore: environment.imageStore
            )
            backupArchiveURL = url
        } catch {
            statusAlertMessage = error.localizedDescription
        }
    }

    #if DEBUG
    private func loadDemoMistakes() {
        isPopulatingDemo = true
        Task {
            defer { isPopulatingDemo = false }
            do {
                try await DemoNotebookSeeder.populateDemoMistakes(
                    in: modelContext,
                    imageStore: environment.imageStore
                )
                refreshStorageFootprint()
                statusAlertMessage = String(localized: "Sample mistakes added to your notebook.")
            } catch {
                statusAlertMessage = error.localizedDescription
            }
        }
    }
    #endif

    private func cleanUpBackupURL() {
        if let url = backupArchiveURL {
            try? FileManager.default.removeItem(at: url)
        }
        backupArchiveURL = nil
    }
}
