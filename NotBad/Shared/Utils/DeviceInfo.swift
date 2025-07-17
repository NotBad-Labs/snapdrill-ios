//
//  DeviceInfo.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct DeviceInfo {
    // MARK: - Screen Dimensions
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    
    // MARK: - Device Types
    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isCompact: Bool {
        screenWidth < 400
    }
    
    static var isRegular: Bool {
        screenWidth >= 400
    }
    
    // MARK: - Layout Helpers
    static var cardPadding: CGFloat {
        if isPhone {
            return isCompact ? .spacingS : .spacingM
        } else {
            return .spacingL
        }
    }
    
    static var listPadding: CGFloat {
        isPhone ? .spacingM : .spacingL
    }
    
    static var maxContentWidth: CGFloat {
        isPad ? 600 : .infinity
    }
}
