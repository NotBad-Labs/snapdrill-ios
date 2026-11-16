import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProSubscriptionPlaceholderView()
                    } label: {
                        Label(String(localized: "SnapDrill Pro"), systemImage: "star.circle")
                    }
                } footer: {
                    Text(String(localized: "Pro: iCloud sync, watermark-free PDF, search, themes."))
                }

                Section(String(localized: "Organize")) {
                    NavigationLink(String(localized: "Subjects & causes")) {
                        Text(String(localized: "Subject management · Slice 4"))
                    }
                }

                Section(String(localized: "About")) {
                    LabeledContent(String(localized: "Version"), value: "0.1.0-slice1")
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .paperBackground()
        }
    }
}

private struct ProSubscriptionPlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "SnapDrill Pro"))
                .font(.title2.weight(.semibold))
            Text(String(localized: "$1.99/mo · $14.99/yr · 7-day trial (PRD §6)"))
                .foregroundStyle(.secondary)
            Text(String(localized: "StoreKit 2 wiring lands in Slice 7."))
            Spacer()
        }
        .padding()
        .paperBackground()
        .navigationTitle(String(localized: "Pro"))
        .navigationBarTitleDisplayMode(.inline)
    }
}