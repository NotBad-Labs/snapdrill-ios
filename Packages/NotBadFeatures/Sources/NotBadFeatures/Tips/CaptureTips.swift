//
//  CaptureTips.swift
//  NotBadFeatures
//
//  Created by NotBad Architect on 2025/12/31.
//

import SwiftUI
import TipKit

/// 拍照识题功能的提示
public struct ScannerTip: Tip {
    public init() {}
    
    // Parameter into the Tip to track state
    @Parameter
    public static var hasUsedScanner: Bool = false
    
    public var rules: [Rule] {
        // Only show if the user hasn't used the scanner yet
        #Rule(Self.$hasUsedScanner) {
            $0 == false
        }
    }
    
    public var title: Text {
        Text("自动对焦与拍摄")
    }
    
    public var message: Text? {
        Text("保持手机平稳，当对焦框变绿时会自动拍摄。")
    }
    
    public var image: Image? {
        Image(systemName: "camera.viewfinder")
    }
}
