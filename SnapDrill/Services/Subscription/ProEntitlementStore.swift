import Foundation
import Observation
import StoreKit

/// Manages StoreKit 2 Pro subscriptions, Family Sharing, restore purchases, and lossless degradation (PRD §6, §8.6, AC-08).
@Observable
@MainActor
final class ProEntitlementStore: ProEntitlementServing {
    private(set) var products: [Product] = []
    private(set) var statusState: SubscriptionStatusState = .free
    private(set) var isLoadingProducts: Bool = false
    private(set) var purchaseInFlight: Bool = false
    private(set) var statusMessage: String?

    private let defaults: UserDefaults
    private let hadPriorEntitlementKey = "snapdrill.hadPriorProEntitlement"
    private var updatesTask: Task<Void, Never>?

    #if DEBUG
    var debugOverride: DebugSubscriptionOverride = .automatic {
        didSet {
            recomputeStateFromEntitlements(lastActiveEntitlement: cachedEntitlement)
        }
    }
    #endif

    private var cachedEntitlement: (productID: String, isTrial: Bool)?

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
        defer { isLoadingProducts = false }
        do {
            let ids = SnapDrillProductID.allCases.map(\.rawValue)
            let loaded = try await Product.products(for: ids)
            self.products = loaded.sorted { $0.price < $1.price }
        } catch {
            // Silently tolerate offline / missing StoreKit config in Simulator while showing clear fallback pricing labels
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
        var found: (productID: String, isTrial: Bool)?

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               SnapDrillProductID(rawValue: transaction.productID) != nil,
               transaction.revocationDate == nil {
                let isTrial = transaction.offer?.paymentMode == .freeTrial
                found = (transaction.productID, isTrial)
                defaults.set(true, forKey: hadPriorEntitlementKey)
                break
            }
        }

        cachedEntitlement = found
        recomputeStateFromEntitlements(lastActiveEntitlement: found)
    }

    private func recomputeStateFromEntitlements(lastActiveEntitlement: (productID: String, isTrial: Bool)?) {
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
        } else if defaults.bool(forKey: hadPriorEntitlementKey) {
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
