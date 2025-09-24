//
//  LibraryDetailViewModel.swift
//  NotBad
//
//  Created by GitHub Copilot on 9/22/25.
//

import Foundation
import SwiftUI

/// 题目详情视图模型
@MainActor
final class LibraryDetailViewModel: ObservableObject {
    // MARK: - Published UI State
    @Published var item: ReviewItem?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    private let reviewItemService: ReviewItemServicing
    private weak var coordinator: LibraryCoordinator?
    private weak var errorHandler: AppErrorHandler?
    private let itemIdString: String

    // MARK: - Init
    init(
    reviewItemService: ReviewItemServicing,
        itemId: String,
        coordinator: LibraryCoordinator,
        errorHandler: AppErrorHandler? = nil
    ) {
        self.reviewItemService = reviewItemService
        self.itemIdString = itemId
        self.coordinator = coordinator
        self.errorHandler = errorHandler
    }

    func configure(errorHandler: AppErrorHandler) {
        self.errorHandler = errorHandler
    }

    // MARK: - Intent
    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard let uuid = UUID(uuidString: itemIdString) else {
            errorHandler?.handle(DetailError.invalidID)
            self.item = nil
            return
        }

        do {
            let id = ReviewItemID(uuid)
            let fetched = try await reviewItemService.getReviewItem(id: id)
            self.item = fetched
            if fetched == nil {
                errorHandler?.handle(DetailError.itemNotFound)
            }
        } catch {
            errorHandler?.handle(error)
            self.item = nil
        }
    }

    func startPractice() {
        coordinator?.coordinate(to: .practiceMode)
    }

    func deleteCurrentItem() async {
        guard let item else { return }
        do {
            try await reviewItemService.deleteReviewItem(id: item.id)
            self.item = nil
        } catch {
            errorHandler?.handle(error)
        }
    }
}

// MARK: - Local Errors
enum DetailError: LocalizedError {
    case invalidID
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .invalidID:
            return "无效的题目ID"
        case .itemNotFound:
            return "未找到该题目"
        }
    }
}
