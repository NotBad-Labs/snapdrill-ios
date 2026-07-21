//
//  CapturePageImportProcessor.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SnapDrillCore
import UIKit

enum CapturePageImportOutcome {
    case ready(content: String, token: CaptureDraftToken)
    case ocrUnavailable(token: CaptureDraftToken)
    case ocrEmpty(token: CaptureDraftToken)
    case enrichmentFailed(content: String, token: CaptureDraftToken)
    case checkpointFailed
    case cancelled
}

/// Shared durable-before-OCR state machine for PDF and document-scan pages.
@MainActor
struct CapturePageImportProcessor {
    let ocrService: OCRServiceProtocol
    let draftService: CaptureDraftServiceProtocol
    let activityTracker: AppActivityTracker

    func process(_ image: UIImage) async -> CapturePageImportOutcome {
        activityTracker.begin(.capturing)
        defer { activityTracker.end(.capturing) }

        let checkpointToken: CaptureDraftToken
        do {
            checkpointToken = try await draftService.saveDraft(
                image: image,
                content: "",
                category: nil,
                expectedToken: nil
            )
        } catch {
            SnapDrillLogger.capture.error(
                "Page import checkpoint failed: \(error.localizedDescription)"
            )
            return .checkpointFailed
        }

        guard !Task.isCancelled else { return .cancelled }
        guard let cgImage = image.cgImage else {
            return .ocrUnavailable(token: checkpointToken)
        }

        let content: String
        do {
            content = try await ocrService.recognizeDocument(from: cgImage).transcript
            try Task.checkCancellation()
        } catch is CancellationError {
            return .cancelled
        } catch {
            SnapDrillLogger.capture.error("Page import OCR failed: \(error.localizedDescription)")
            return .ocrUnavailable(token: checkpointToken)
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .ocrEmpty(token: checkpointToken)
        }

        do {
            let enrichedToken = try await draftService.saveDraft(
                image: image,
                content: content,
                category: nil,
                expectedToken: checkpointToken
            )
            return .ready(content: content, token: enrichedToken)
        } catch is CancellationError {
            return .cancelled
        } catch {
            SnapDrillLogger.capture.error(
                "Page import draft enrichment failed: \(error.localizedDescription)"
            )
            return .enrichmentFailed(content: content, token: checkpointToken)
        }
    }
}
