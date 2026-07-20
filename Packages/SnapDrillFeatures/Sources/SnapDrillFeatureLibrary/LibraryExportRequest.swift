//
//  LibraryExportRequest.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import SnapDrillCore

struct LibraryExportRequest: Identifiable, Equatable {
    let id: UUID
    let orderedIDs: [UUID]

    var idSet: Set<UUID> {
        Set(orderedIDs)
    }

    init(
        visibleIDs: [UUID],
        selectedIDs: Set<UUID>,
        id: UUID = UUID()
    ) throws {
        guard !selectedIDs.isEmpty else {
            throw LibraryExportRequestError.emptySelection
        }

        let orderedIDs = visibleIDs.filter(selectedIDs.contains)
        guard orderedIDs.count == Set(orderedIDs).count else {
            throw LibraryExportRequestError.duplicateRequestID
        }
        guard Set(orderedIDs) == selectedIDs else {
            throw LibraryExportRequestError.selectionChanged
        }

        self.id = id
        self.orderedIDs = orderedIDs
    }

    func resolve<Element: Identifiable>(_ elements: [Element]) throws -> [Element]
    where Element.ID == UUID {
        let resolvedIDs = elements.map(\.id)
        guard resolvedIDs.count == Set(resolvedIDs).count else {
            throw LibraryExportRequestError.duplicateResolvedID
        }
        guard Set(resolvedIDs) == idSet else {
            throw LibraryExportRequestError.resolvedSelectionMismatch
        }

        let elementsByID = Dictionary(uniqueKeysWithValues: elements.map { ($0.id, $0) })
        return try orderedIDs.map { id in
            guard let element = elementsByID[id] else {
                throw LibraryExportRequestError.resolvedSelectionMismatch
            }
            return element
        }
    }
}

enum LibraryExportRequestError: Error, Equatable, LocalizedError {
    case emptySelection
    case duplicateRequestID
    case selectionChanged
    case duplicateResolvedID
    case resolvedSelectionMismatch

    var errorDescription: String? {
        switch self {
        case .emptySelection:
            return L10n.Errors.pdfEmptyInput
        case .duplicateRequestID,
             .selectionChanged,
             .duplicateResolvedID,
             .resolvedSelectionMismatch:
            return L10n.Errors.exportSelectionChanged
        }
    }
}
