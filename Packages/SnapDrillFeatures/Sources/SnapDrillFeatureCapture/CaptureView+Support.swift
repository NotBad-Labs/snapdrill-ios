//
//  CaptureView+Support.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SnapDrillCore
import SwiftUI

enum CaptureMethod {
    case camera
    case clipboard
    case documentScan
    case pdf
}

#Preview {
    @Bindable var router = CaptureRouter()
    return CaptureView(
        router: router,
        ocrService: OCRServiceMock(),
        draftService: CaptureDraftServiceMock(),
        activityTracker: AppActivityTracker()
    )
}
