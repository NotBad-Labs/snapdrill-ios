import SwiftUI

/// AC-07 壳：版式与水印文案；Slice 6 接 `PDFExportService`。
struct PDFExportShellView: View {
    let mistakeCount: Int

    @State private var paperSize = "A4"
    @State private var includeAnswers = true
    @State private var isProPreview = false

    private let paperOptions = ["A4", "B5", "Letter"]

    var body: some View {
        Form {
            Section(String(localized: "Selection")) {
                LabeledContent(String(localized: "Questions"), value: "\(mistakeCount)")
            }

            Section(String(localized: "Layout (PRD §8.5)")) {
                Picker(String(localized: "Paper"), selection: $paperSize) {
                    ForEach(paperOptions, id: \.self) { size in
                        Text(size).tag(size)
                    }
                }
                Toggle(String(localized: "Answers on last page"), isOn: $includeAnswers)
            }

            Section(String(localized: "Preview")) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.richtext")
                                .font(.largeTitle)
                            Text(String(localized: "PDF preview · Slice 6"))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                if !isProPreview {
                    HStack {
                        Spacer()
                        Text("SnapDrill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            }

            Section(String(localized: "Watermark")) {
                Toggle(String(localized: "Preview as Pro (no footer)"), isOn: $isProPreview)
                Text(String(localized: "Free tier shows a light SnapDrill footer on each page."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(String(localized: "Export PDF")) {}
                    .disabled(true)
                Button(String(localized: "Print with AirPrint")) {}
                    .disabled(true)
            } footer: {
                Text(String(localized: "Export wires up in Slice 6."))
            }
        }
        .navigationTitle(String(localized: "Export PDF"))
        .paperBackground()
    }
}