//
//  UseCaseContainer.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义用例容器协议，作为 Features 层访问业务逻辑的统一入口。
//

import Foundation

/// 领域用例容器协议
@MainActor
public protocol UseCaseContainer: Sendable {
    var review: ReviewUseCaseProtocol { get }
    var taxonomy: TaxonomyUseCaseProtocol { get }
}
