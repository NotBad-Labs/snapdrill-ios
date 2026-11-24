import Foundation
import Observation
import StoreKit

/// Snapshot of a verified StoreKit entitlement used for deterministic ranking & unit tests.
struct EntitlementSnapshot: Equatable, Sendable {
    let productID: String
    let expirationDate: Date?
    let isTrial: Bool
    let isRevoked: Bool
}

/// Manages StoreKit 2 Pro subscriptions, Family Sharing, restore purchases, and lossless degradation (PRD §6, §8.6, AC-08).
@Observable
@MainActor
final class ProEntitlementStore: ProEntitlementServing {
    private(set) var products: [Product] = []
    private(set) var statusState: SubscriptionStatusState = .free
    private(set) var isLoadingProducts: Bool = false
    private(set) var productsLoadFailed: Bool = false
    private(set) var purchaseInFlight: Bool = false
    private(set) var statusMessage: String?

    private let defaults: UserDefaults
    private let hadPriorEntitlementKey = "snapdrill.hadPriorProEntitlement"
    private let lastKnownProActiveKey = "snapdrill.lastKnownProActive"
    private var updatesTask: Task<Void, Never>?

    #if DEBUG
    var debugOverride: DebugSubscriptionOverride = .automatic {
        didSet {
            recomputeStateFromEntitlements(lastActiveEntitlement: cachedEntitlement, detectedPriorExpired: detectedPriorExpired)
        }
    }
    #endif

    private var cachedEntitlement: EntitlementSnapshot?
    private var detectedPriorExpired: Bool = false

    init(userDefaults: UserDefaults = .standard, startListeners: Bool = true) {
        self.defaults = userDefaults
        if startListeners {
            startTransactionUpdatesListener()
            Task {
                await refreshEntitlements()
                await loadProducts()
            }
        }
    }

    var isPro: Bool {
        if case .pro = statusState { return true }
        return false
    }

    var monthlyProduct: Product? {
        products.first { $0.id == SnapDrillProductID.monthly.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == SnapDrillProductID.yearly.rawValue }
    }

    /// Selects the highest-priority valid entitlement (non-revoked, non-expiring or latest expiration date).
    nonisolated static func selectBestEntitlement(from snapshots: [EntitlementSnapshot]) -> EntitlementSnapshot? {
        let valid = snapshots.filter { snapshot in
            !snapshot.isRevoked && SnapDrillProductID(rawValue: snapshot.productID) != nil
        }
        return valid.max { lhs, rhs in
            switch (lhs.expirationDate, rhs.expirationDate) {
            case (nil, _): return false
            case (_, nil): return true
            case let (l?, r?): return l < r
            }
        }
    }

    /// PRD §8.6 & AC-08: When Pro expires, keep all local data editable/printable/exportable,
    /// revert PDF to P0 watermark + end appendix layout, and lock Pro-only styling/features.
    nonisolated func effectivePDFOptions(requested: PDFExportOptions, isPro: Bool) -> PDFExportOptions {
        if isPro {
            return requested
        }
        return PDFExportOptions.p0Default(
            title: requested.title,
            paperSize: requested.paperSize,
            includeWatermark: true
        )
    }

    func effectivePDFOptions(requested: PDFExportOptions) -> PDFExportOptions {
        effectivePDFOptions(requested: requested, isPro: isPro)
    }

    // MARK: - StoreKit 2 Actions

    func loadProducts() async {
        isLoadingProducts = true
        productsLoadFailed = false
        defer { isLoadingProducts = false }
        do {
            let ids = SnapDrillProductID.allCases.map(\.rawValue)
            let loaded = try await Product.products(for: ids)
            self.products = loaded.sorted { $0.price < $1.price }
            self.productsLoadFailed = self.products.isEmpty
        } catch {
            self.productsLoadFailed = true
        }
    }

    func purchase(_ product: Product) async {
        purchaseInFlight = true
        statusMessage = nil
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    statusMessage = String(localized: "Welcome to SnapDrill Pro!")
                case .unverified:
                    statusMessage = String(localized: "Purchase could not be verified by the App Store.")
                }
            case .userCancelled:
                break
            case .pending:
                statusMessage = String(localized: "Purchase is pending approval.")
            @unknown default:
                break
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        purchaseInFlight = true
        statusMessage = nil
        defer { purchaseInFlight = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = isPro
                ? String(localized: "Your Pro subscription has been restored.")
                : String(localized: "No active Pro subscription was found for this Apple Account.")
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var activeSnapshots: [EntitlementSnapshot] = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               SnapDrillProductID(rawValue: transaction.productID) != nil {
                activeSnapshots.append(
                    EntitlementSnapshot(
                        productID: transaction.productID,
                        expirationDate: transaction.expirationDate,
                        isTrial: transaction.offer?.paymentMode == .freeTrial,
                        isRevoked: transaction.revocationDate != nil
                    )
                )
            }
        }

        let bestActive = Self.selectBestEntitlement(from: activeSnapshots)
        var foundPrior = defaults.bool(forKey: hadPriorEntitlementKey)

        if bestActive != nil {
            defaults.set(true, forKey: hadPriorEntitlementKey)
            foundPrior = true
        } else {
            // Query Transaction.latest(for:) so expired subscriptions are still detected accurately after reinstall
            for productID in SnapDrillProductID.allCases {
                if let latest = await Transaction.latest(for: productID.rawValue),
                   case .verified(let tx) = latest,
                   tx.revocationDate == nil {
                    foundPrior = true
                    defaults.set(true, forKey: hadPriorEntitlementKey)
                    break
                }
            }
        }

        cachedEntitlement = bestActive
        detectedPriorExpired = foundPrior
        recomputeStateFromEntitlements(lastActiveEntitlement: bestActive, detectedPriorExpired: foundPrior)
        defaults.set(isPro, forKey: lastKnownProActiveKey)
    }

    private func recomputeStateFromEntitlements(
        lastActiveEntitlement: EntitlementSnapshot?,
        detectedPriorExpired: Bool
    ) {
        #if DEBUG
        switch debugOverride {
        case .forcePro:
            statusState = .pro(productID: SnapDrillProductID.yearly.rawValue, isTrial: true)
            return
        case .forceExpired:
            statusState = .expiredFallback
            return
        case .automatic:
            break
        }
        #endif

        if let active = lastActiveEntitlement {
            statusState = .pro(productID: active.productID, isTrial: active.isTrial)
        } else if detectedPriorExpired {
            statusState = .expiredFallback
        } else {
            statusState = .free
        }
    }

    private func startTransactionUpdatesListener() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled, let self else { break }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }
}
