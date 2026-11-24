import Foundation
import Observation

/// Stores non-sensitive user preferences (last used subject, paper size, appearance, sync toggle) in UserDefaults.
@Observable
@MainActor
final class AppPreferencesStore {
    private enum Keys {
        static let lastSubjectID = "snapdrill.lastSubjectID"
        static let preferredPaperSize = "snapdrill.preferredPaperSize"
        static let appearanceMode = "snapdrill.appearanceMode"
        static let defaultInkRemovalMode = "snapdrill.defaultInkRemovalMode"
        static let iCloudSyncEnabled = "snapdrill.iCloudSyncEnabled"
        static let lastKnownProActive = "snapdrill.lastKnownProActive"
    }

    private let defaults: UserDefaults

    var lastSubjectID: UUID? {
        didSet {
            defaults.set(lastSubjectID?.uuidString, forKey: Keys.lastSubjectID)
        }
    }

    var preferredPaperSize: PaperSize {
        didSet {
            defaults.set(preferredPaperSize.rawValue, forKey: Keys.preferredPaperSize)
        }
    }

    var appearanceMode: AppAppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        }
    }

    var defaultInkRemovalMode: InkRemovalMode {
        didSet {
            defaults.set(defaultInkRemovalMode.rawValue, forKey: Keys.defaultInkRemovalMode)
        }
    }

    var iCloudSyncEnabled: Bool {
        didSet {
            defaults.set(iCloudSyncEnabled, forKey: Keys.iCloudSyncEnabled)
        }
    }

    /// Cached hint used only on synchronous launch before StoreKit finishes verifying currentEntitlements.
    var lastKnownProActive: Bool {
        didSet {
            defaults.set(lastKnownProActive, forKey: Keys.lastKnownProActive)
        }
    }

    init(userDefaults: UserDefaults = .standard, locale: Locale = .current) {
        self.defaults = userDefaults

        if let rawID = userDefaults.string(forKey: Keys.lastSubjectID) {
            self.lastSubjectID = UUID(uuidString: rawID)
        } else {
            self.lastSubjectID = nil
        }

        if let rawPaper = userDefaults.string(forKey: Keys.preferredPaperSize),
           let parsedPaper = PaperSize(rawValue: rawPaper) {
            self.preferredPaperSize = parsedPaper
        } else {
            self.preferredPaperSize = PaperSize.defaultForLocale(locale)
        }

        if let rawAppearance = userDefaults.string(forKey: Keys.appearanceMode),
           let parsedAppearance = AppAppearanceMode(rawValue: rawAppearance) {
            self.appearanceMode = parsedAppearance
        } else {
            self.appearanceMode = .system
        }

        if let rawInk = userDefaults.string(forKey: Keys.defaultInkRemovalMode),
           let parsedInk = InkRemovalMode(rawValue: rawInk) {
            self.defaultInkRemovalMode = parsedInk
        } else {
            self.defaultInkRemovalMode = .autoAll
        }

        self.iCloudSyncEnabled = userDefaults.bool(forKey: Keys.iCloudSyncEnabled)
        self.lastKnownProActive = userDefaults.bool(forKey: Keys.lastKnownProActive)
    }

    func shouldEnableCloudKit(isPro: Bool) -> Bool {
        isPro && iCloudSyncEnabled
    }
}
