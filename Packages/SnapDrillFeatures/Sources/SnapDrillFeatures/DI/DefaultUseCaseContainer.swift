//
//  DefaultUseCaseContainer.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  UseCaseContainer 的生产环境实现，组合所有 UseCase 实例。
//

import Foundation
import SnapDrillDomain
import SnapDrillData

/// 默认 UseCase 容器实现
///
/// 负责将 Repositories 包装为具体的 UseCases
@MainActor
public final class DefaultUseCaseContainer: UseCaseContainer {
    public let review: ReviewUseCaseProtocol
    public let taxonomy: TaxonomyUseCaseProtocol
    
    public init(repositories: RepositoryContainer) {
        self.review = ReviewUseCase(repository: repositories.review)
        self.taxonomy = TaxonomyUseCase(
            subjectRepo: repositories.subject,
            sourceRepo: repositories.source,
            tagRepo: repositories.tag,
            gradeRepo: repositories.grade,
            reviewRepo: repositories.review
        )
    }
}
