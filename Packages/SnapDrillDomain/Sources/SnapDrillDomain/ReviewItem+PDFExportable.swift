//
//  ReviewItem+PDFExportable.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  让 ReviewItem 遵守 SnapDrillCore.PDFExportable，使 PDFExportService
//  无需直接依赖领域实体。
//

import SnapDrillCore

extension ReviewItem: PDFExportable {}
