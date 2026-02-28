//
//  CaptureService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  采集服务 Actor，负责图像处理和 OCR 识别
//

import Foundation

/// 采集服务 Actor
///
/// 负责处理图像采集、OCR 识别等耗时任务。
/// 此 Actor 作为采集流程的调度中心。
public actor CaptureService {
    
    // MARK: - Initialization
    
    /// 初始化采集服务
    public init() {}
    
    // MARK: - Public API
    
    // TODO: UI Integration Pending - 多图识别与批处理逻辑待从此 Actor 导出
}
