import Foundation

/// StoreKit product identifiers matching SnapDrill.storekit (PRD §6.3: $1.99/mo, $14.99/yr).
enum SnapDrillProductID: String, CaseIterable, Sendable {
    case monthly = "com.notbadlabs.snapdrill.pro.monthly"
    case yearly = "com.notbadlabs.snapdrill.pro.yearly"
}

enum SubscriptionStatusState: Equatable, Sendable {
    case free
    case pro(productID: String, isTrial: Bool)
    case expiredFallback
}

#if DEBUG
enum DebugSubscriptionOverride: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case forcePro
    case forceExpired

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: return String(localized: "System StoreKit")
        case .forcePro: return String(localized: "Simulate Pro")
        case .forceExpired: return String(localized: "Simulate Expired Fallback")
        }
    }
}
#endif

/// Protocol-first subscription entitlement service enforcing lossless degradation rules (PRD §8.6).
@MainActor
protocol ProEntitlementServing: AnyObject {
    var isPro: Bool { get }
    var statusState: SubscriptionStatusState { get }
    func effectivePDFOptions(requested: PDFExportOptions) -> PDFExportOptions
}
