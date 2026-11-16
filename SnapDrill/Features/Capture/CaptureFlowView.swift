import PhotosUI
import SwiftUI

/// PRD §8.2 三步收录 — 当前为 Slice 1 占位，Slice 2 接相机/Vision
struct CaptureFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .pick
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var placeholderMessage = String(localized: "Camera & multi-box crop coming in Slice 2")

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                stepIndicator

                switch step {
                case .pick:
                    pickStep
                case .crop:
                    placeholderPanel(title: String(localized: "Step 1 · Crop & enhance"), detail: placeholderMessage)
                case .box:
                    placeholderPanel(title: String(localized: "Step 2 · Box questions"), detail: String(localized: "Up to 10 boxes per page"))
                case .save:
                    placeholderPanel(title: String(localized: "Step 3 · Remove ink & save"), detail: String(localized: "Subject required · Quick save"))
                }

                Spacer()
            }
            .padding()
            .navigationTitle(String(localized: "Capture"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) { dismiss() }
                }
                if step != .pick {
                    ToolbarItem(placement: .primaryAction) {
                        Button(String(localized: "Next")) { advance() }
                    }
                }
            }
            .paperBackground()
        }
    }

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.self) { s in
                Capsule()
                    .fill(s == step ? SnapDrillTheme.inkBlue : Color.secondary.opacity(0.25))
                    .frame(height: 4)
            }
        }
    }

    private var pickStep: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Import up to 10 photos"))
                .font(.headline)
            PhotosPicker(selection: $pickerItems, maxSelectionCount: 10, matching: .images) {
                Label(String(localized: "Photo library"), systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SnapDrillTheme.inkBlue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button {
                step = .crop
            } label: {
                Label(String(localized: "Open camera (TODO)"), systemImage: "camera")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
    }

    private func placeholderPanel(title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
            Text(detail)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func advance() {
        guard let next = Step(rawValue: step.rawValue + 1) else {
            dismiss()
            return
        }
        step = next
    }

    private enum Step: Int, CaseIterable {
        case pick = 0
        case crop = 1
        case box = 2
        case save = 3
    }
}