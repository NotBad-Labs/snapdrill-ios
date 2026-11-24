import PDFKit
import SwiftUI
import UIKit

/// Live PDF preview, paper format switcher (A4/B5/Letter), Pro layout options, Share, and AirPrint (PRD §8.5, AC-07).
struct PDFExportPreviewView: View {
    let mistakes: [MistakeItem]
    let defaultTitle: String

    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var environment

    @State private var title: String
    @State private var paperSize: PaperSize = .a4
    @State private var useCleanedImages: Bool = true
    @State private var answerPlacement: AnswerPlacement = .endAppendix
    @State private var blankSpace: BlankSpaceSize = .standard

    @State private var renderedPDFData: Data?
    @State private var sharePDFURL: URL?
    @State private var showingPaywall = false
    @State private var errorMessage: String?

    init(mistakes: [MistakeItem], defaultTitle: String) {
        self.mistakes = mistakes
        self.defaultTitle = defaultTitle
        _title = State(initialValue: defaultTitle)
    }

    private var effectiveOptions: PDFExportOptions {
        let requested = PDFExportOptions(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "SnapDrill" : title,
            paperSize: paperSize,
            useCleanedImages: useCleanedImages,
            answerPlacement: answerPlacement,
            blankSpace: blankSpace,
            includeFooterWatermark: !environment.proStore.isPro
        )
        return environment.proStore.effectivePDFOptions(requested: requested)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Live embedded PDFKit preview
                if let renderedPDFData {
                    PDFKitPreviewRepresentable(data: renderedPDFData)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1)
                        )
                        .padding(.horizontal, SnapDrillTheme.screenPadding)
                } else {
                    Spacer()
                    ProgressView("Generating PDF...")
                    Spacer()
                }

                // Controls card
                PaperCard(padding: 12) {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Title")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(SnapDrillTheme.inkSecondary)
                            TextField("Practice Sheet Title", text: $title)
                                .textFieldStyle(.roundedBorder)
                                .font(.subheadline)
                        }

                        Picker("Paper Size", selection: $paperSize) {
                            ForEach(PaperSize.allCases) { size in
                                Text(size.shortLabel).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Use Handwriting-Removed Images", isOn: $useCleanedImages)
                            .font(.caption.weight(.medium))
                            .tint(SnapDrillTheme.inkBlue)

                        RuledDivider()

                        // Pro-gated F-51 layout options (revert cleanly to P0 defaults on Free / Expired)
                        HStack {
                            Label("Layout Options", systemImage: environment.proStore.isPro ? "slider.horizontal.3" : "lock.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(environment.proStore.isPro ? SnapDrillTheme.inkBlack : SnapDrillTheme.inkSecondary)
                            Spacer()
                            if !environment.proStore.isPro {
                                Button("Unlock Watermark-Free & Layouts") {
                                    showingPaywall = true
                                }
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(SnapDrillTheme.inkBlue)
                            }
                        }

                        if environment.proStore.isPro {
                            Picker("Answers", selection: $answerPlacement) {
                                ForEach(AnswerPlacement.allCases) { placement in
                                    Text(placement.localizedTitle).tag(placement)
                                }
                            }
                            .pickerStyle(.segmented)

                            Picker("Writing Space", selection: $blankSpace) {
                                ForEach(BlankSpaceSize.allCases) { space in
                                    Text(space.localizedTitle).tag(space)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(.horizontal, SnapDrillTheme.screenPadding)

                // Export / AirPrint buttons (PRD §8.5)
                HStack(spacing: 12) {
                    Button {
                        exportPDFFile()
                    } label: {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(SnapDrillTheme.inkBlue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        presentAirPrint()
                    } label: {
                        Label("Print", systemImage: "printer.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SnapDrillTheme.inkBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(SnapDrillTheme.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(SnapDrillTheme.ruledLine, lineWidth: 1))
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, SnapDrillTheme.screenPadding)
                .padding(.bottom, 12)
            }
            .paperBackground()
            .navigationTitle(String(localized: "PDF Export (\(mistakes.count))"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                paperSize = environment.preferences.preferredPaperSize
                regeneratePreview()
            }
            .onChange(of: paperSize) { _, _ in regeneratePreview() }
            .onChange(of: useCleanedImages) { _, _ in regeneratePreview() }
            .onChange(of: answerPlacement) { _, _ in regeneratePreview() }
            .onChange(of: blankSpace) { _, _ in regeneratePreview() }
            .onChange(of: title) { _, _ in regeneratePreview() }
            .onChange(of: environment.proStore.statusState) { _, _ in regeneratePreview() }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: Binding(
                get: { sharePDFURL != nil },
                set: { if !$0 { cleanUpTemporaryShareFile() } }
            )) {
                if let sharePDFURL {
                    ActivityShareSheet(items: [sharePDFURL])
                }
            }
            .alert("Export Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Helpers

    private func buildPayloads() -> [PDFQuestionPayload] {
        mistakes.enumerated().map { idx, item in
            let imgData = useCleanedImages
                ? item.resolvedCleanedImageData(imageStore: environment.imageStore)
                : item.resolvedOriginalImageData(imageStore: environment.imageStore)
            let ansDatas = item.resolvedAnswerImageDatas(imageStore: environment.imageStore)
            let causes = item.causes.map(\.localizedTitle) + item.customCauseNames

            return PDFQuestionPayload(
                id: item.id,
                index: idx + 1,
                subjectName: item.subject?.name ?? String(localized: "Mistake"),
                imageData: imgData,
                answerText: item.answerText,
                answerImageDatas: ansDatas,
                causeLabels: causes,
                notes: item.notes,
                createdAt: item.createdAt
            )
        }
    }

    private func regeneratePreview() {
        do {
            renderedPDFData = try environment.pdfService.renderPDFData(
                questions: buildPayloads(),
                options: effectiveOptions
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func exportPDFFile() {
        do {
            sharePDFURL = try environment.pdfService.writeTemporaryPDF(
                questions: buildPayloads(),
                options: effectiveOptions
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func presentAirPrint() {
        guard let data = renderedPDFData, UIPrintInteractionController.canPrint(data) else {
            errorMessage = String(localized: "AirPrint is not available for this document.")
            return
        }
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = effectiveOptions.title
        controller.printInfo = info
        controller.printingItem = data
        controller.present(animated: true)
    }

    private func cleanUpTemporaryShareFile() {
        if let url = sharePDFURL {
            try? FileManager.default.removeItem(at: url)
        }
        sharePDFURL = nil
    }
}

private struct PDFKitPreviewRepresentable: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = .clear
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = PDFDocument(data: data)
    }
}
