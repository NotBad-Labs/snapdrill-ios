import StoreKit
import SwiftUI

/// Bear-inspired calm, transparent Pro subscription screen ($1.99/mo, $14.99/yr, 7-day trial, Family Sharing) (PRD §6, AC-08, AC-10).
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment

    @State private var selectedPlan: SnapDrillProductID = .yearly

    private var selectedProduct: Product? {
        switch selectedPlan {
        case .monthly: return environment.proStore.monthlyProduct
        case .yearly: return environment.proStore.yearlyProduct
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Hero
                    VStack(spacing: 10) {
                        PandaMascotView(mood: .welcoming, size: 88)

                        Text("SnapDrill Pro")
                            .font(.title.weight(.bold))
                            .foregroundStyle(SnapDrillTheme.inkBlack)

                        Text("Core capture, handwriting removal, review, and backup stay free forever. Upgrade for multi-device sync & polished printables.")
                            .font(.subheadline)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)

                    // Benefits list
                    PaperCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            benefitRow(
                                symbol: "icloud.fill",
                                title: String(localized: "iCloud Sync"),
                                detail: String(localized: "Sync your mistake library automatically across your Apple devices")
                            )
                            RuledDivider()
                            benefitRow(
                                symbol: "doc.richtext.fill",
                                title: String(localized: "Watermark-Free PDFs & Layouts"),
                                detail: String(localized: "Customize answer placement and blank practice space")
                            )
                            RuledDivider()
                            benefitRow(
                                symbol: "sparkles",
                                title: String(localized: "Smart Question Framing"),
                                detail: String(localized: "Auto-detect question boxes on dense exam sheets")
                            )
                            RuledDivider()
                            benefitRow(
                                symbol: "text.magnifyingglass",
                                title: String(localized: "On-Device OCR Search"),
                                detail: String(localized: "Search inside photographed question text in 5 languages")
                            )
                        }
                    }

                    // Plan picker cards
                    VStack(spacing: 10) {
                        planCard(
                            plan: .yearly,
                            title: String(localized: "Annual"),
                            badge: String(localized: "Best Value · Save 37%"),
                            priceText: environment.proStore.yearlyProduct?.displayPrice ?? "$14.99",
                            periodText: String(localized: "/ year · 7-day free trial")
                        )

                        planCard(
                            plan: .monthly,
                            title: String(localized: "Monthly"),
                            badge: nil,
                            priceText: environment.proStore.monthlyProduct?.displayPrice ?? "$1.99",
                            periodText: String(localized: "/ month · 7-day free trial")
                        )
                    }

                    if let statusMessage = environment.proStore.statusMessage {
                        Text(statusMessage)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(SnapDrillTheme.inkBlue)
                            .multilineTextAlignment(.center)
                    }

                    // Primary CTA
                    Button {
                        Task {
                            if let product = selectedProduct {
                                await environment.proStore.purchase(product)
                            } else {
                                await environment.proStore.loadProducts()
                            }
                        }
                    } label: {
                        HStack {
                            if environment.proStore.purchaseInFlight {
                                ProgressView().tint(.white)
                            } else {
                                Text("Start 7-Day Free Trial")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(environment.proStore.purchaseInFlight)
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "Start 7-Day Free Trial"))

                    // Restore + Family Sharing disclosure
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task { await environment.proStore.restorePurchases() }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(SnapDrillTheme.inkBlue)
                        .accessibilityLabel(String(localized: "Restore Purchases"))

                        Label("Supports Apple Family Sharing · Cancel anytime", systemImage: "person.2.fill")
                            .font(.caption2)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)

                        Text("Payment is charged to your Apple Account after the 7-day free trial unless canceled at least 24 hours before renewal. Even if Pro expires, all your existing mistakes and backups remain accessible.")
                            .font(.caption2)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 2)
                    }
                }
                .padding(SnapDrillTheme.screenPadding)
            }
            .paperBackground()
            .navigationTitle(String(localized: "SnapDrill Pro"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityLabel(String(localized: "Close Subscription Page"))
                }
            }
            .task {
                if environment.proStore.products.isEmpty {
                    await environment.proStore.loadProducts()
                }
            }
        }
    }

    private func benefitRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SnapDrillTheme.inkBlue)
                .frame(width: 28, height: 28)
                .background(SnapDrillTheme.inkBlueSoft, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapDrillTheme.inkBlack)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(SnapDrillTheme.inkSecondary)
            }
        }
    }

    private func planCard(
        plan: SnapDrillProductID,
        title: String,
        badge: String?,
        priceText: String,
        periodText: String
    ) -> some View {
        let isSelected = selectedPlan == plan

        return Button {
            selectedPlan = plan
        } label: {
            PaperCard(padding: 14, background: isSelected ? SnapDrillTheme.inkBlueSoft : SnapDrillTheme.cardSurface) {
                HStack(spacing: 12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? SnapDrillTheme.inkBlue : SnapDrillTheme.inkSecondary)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(SnapDrillTheme.inkBlack)
                            if let badge {
                                Text(badge)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(SnapDrillTheme.inkBlue, in: Capsule())
                            }
                        }
                        Text(priceText + " " + periodText)
                            .font(.caption)
                            .foregroundStyle(SnapDrillTheme.inkSecondary)
                    }

                    Spacer()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: SnapDrillTheme.cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? SnapDrillTheme.inkBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
