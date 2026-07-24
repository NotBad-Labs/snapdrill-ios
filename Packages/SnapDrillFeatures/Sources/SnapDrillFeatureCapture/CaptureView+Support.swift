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

extension CaptureView {
    var exposesOptionalSurfacesForUITesting: Bool {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("--uitesting")
            && arguments.contains("--ui-test-optional-surface")
            && !arguments.contains("--ui-test-core-surface")
#else
        return false
#endif
    }
}

#if DEBUG
#Preview {
    @Bindable var router = CaptureRouter()
    return CaptureView(
        router: router,
        ocrService: OCRServiceMock(),
        draftService: CaptureDraftServiceMock(),
        activityTracker: AppActivityTracker()
    )
    .environment(\.services, MockServiceContainer())
}
#endif
