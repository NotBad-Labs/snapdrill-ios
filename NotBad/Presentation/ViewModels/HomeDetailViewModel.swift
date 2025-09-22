//
//  HomeDetailViewModel.swift
//  NotBad
//
//  Created by GitHub Copilot on 9/22/25.
//

import Foundation
import SwiftUI

/// 首页详情视图模型（复用题目详情的领域服务能力）
@MainActor
final class HomeDetailViewModel: ObservableObject {
    // MARK: - Published UI State
    @Published var item: ReviewItem?
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    private let reviewItemService: ReviewItemServicing
    private weak var coordinator: HomeCoordinator?
    private weak var errorHandler: AppErrorHandler?
    private let itemIdString: String

    // MARK: - Init
    init(
        reviewItemService: ReviewItemServicing,
        itemId: String,
        coordinator: HomeCoordinator,
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
        
        let timer = AppLogger.Timer("HomeDetailViewModel.load", domain: .viewModel)
        AppLogger.info(.viewModel, "HomeDetailViewModel starting load for item: \(itemIdString)")

        guard let uuid = UUID(uuidString: itemIdString) else {
            AppLogger.error(.viewModel, "HomeDetailViewModel invalid UUID: \(itemIdString)")
            errorHandler?.handle(DetailError.invalidID)
            self.item = nil
            return
        }

        do {
            let id = ReviewItemID(uuid)
            let fetched = try await reviewItemService.getReviewItem(id: id)
            self.item = fetched
            if fetched == nil {
                AppLogger.debug(.viewModel, "HomeDetailViewModel item not found for ID: \(id)")
                errorHandler?.handle(DetailError.itemNotFound)
            } else {
                timer.stop(extra: "loaded item successfully")
            }
        } catch {
            AppLogger.error(.viewModel, "HomeDetailViewModel load failed: \(error)")
            errorHandler?.handle(error)
            self.item = nil
        }
    }
}
