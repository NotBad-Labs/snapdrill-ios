import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @State private var demoStatus = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProSubscriptionShellView()
                    } label: {
                        Label(String(localized: "SnapDrill Pro"), systemImage: "star.circle")
                    }
                } footer: {
                    Text(String(localized: "Pro: iCloud sync, watermark-free PDF, search, themes."))
                }

                Section(String(localized: "Organize")) {
                    NavigationLink {
                        SubjectManagementShellView()
                    } label: {
                        Text(String(localized: "Subjects & causes"))
                    }
                }

                Section {
                    Button(String(localized: "Load UI demo mistakes")) {
                        loadDemo()
                    }
                    Button(String(localized: "Remove demo mistakes"), role: .destructive) {
                        clearDemo()
                    }
                } header: {
                    Text(String(localized: "UI demo (方案 A)"))
                } footer: {
                    Text(String(localized: "Placeholder images for layout review. Real capture stays separate."))
                    if !demoStatus.isEmpty {
                        Text(demoStatus)
                    }
                }

                Section(String(localized: "About")) {
                    LabeledContent(String(localized: "Version"), value: "0.1.0-ui-shell")
                }
            }
            .navigationTitle(String(localized: "Settings"))
            .paperBackground()
        }
    }

    private func loadDemo() {
        do {
            let count = try UIDemoDataService.loadDemoDataset(context: context)
            demoStatus = String(localized: "Loaded \(count) demo mistake(s).")
        } catch {
            demoStatus = error.localizedDescription
        }
    }

    private func clearDemo() {
        do {
            let count = try UIDemoDataService.clearDemoSamples(context: context)
            demoStatus = String(localized: "Removed \(count) demo mistake(s).")
        } catch {
            demoStatus = error.localizedDescription
        }
    }
}

struct ProSubscriptionShellView: View {
    @State private var selectedPlan = "year"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(String(localized: "SnapDrill Pro"))
                    .font(.title2.weight(.semibold))

                VStack(spacing: 12) {
                    planCard(
                        id: "month",
                        title: String(localized: "Monthly"),
                        price: "$1.99/mo",
                        subtitle: String(localized: "7-day free trial")
                    )
                    planCard(
                        id: "year",
                        title: String(localized: "Yearly (recommended)"),
                        price: "$14.99/yr",
                        subtitle: String(localized: "Best value")
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label(String(localized: "iCloud sync across devices"), systemImage: "icloud")
                    Label(String(localized: "Watermark-free PDF export"), systemImage: "doc.richtext")
                    Label(String(localized: "Smart split & search (v1.1)"), systemImage: "magnifyingglass")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Button(String(localized: "Start free trial")) {}
                    .buttonStyle(.borderedProminent)
                    .tint(SnapDrillTheme.inkBlue)
                    .frame(maxWidth: .infinity)
                    .disabled(true)

                Button(String(localized: "Restore purchases")) {}
                    .frame(maxWidth: .infinity)
                    .disabled(true)

                Text(String(localized: "StoreKit 2 · Slice 7"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .paperBackground()
        .navigationTitle(String(localized: "Pro"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func planCard(id: String, title: String, price: String, subtitle: String) -> some View {
        Button {
            selectedPlan = id
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(price).font(.subheadline.weight(.medium))
                Image(systemName: selectedPlan == id ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedPlan == id ? SnapDrillTheme.inkBlue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedPlan == id ? SnapDrillTheme.inkBlue : Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}