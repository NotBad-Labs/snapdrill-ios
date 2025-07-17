//
//  AnimationPresets.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

extension Animation {
    // MARK: - 基础动画
    static let gentle: Animation = .easeInOut(duration: 0.3)
    static let quick: Animation = .easeInOut(duration: 0.2)
    static let smooth: Animation = .easeInOut(duration: 0.4)
    
    // MARK: - 弹性动画
    static let bouncy: Animation = .spring(response: 0.5, dampingFraction: 0.7)
    static let springy: Animation = .spring(response: 0.6, dampingFraction: 0.8)
    
    // MARK: - 特殊效果
    static let cardAppear: Animation = .spring(response: 0.4, dampingFraction: 0.8)
    static let buttonPress: Animation = .easeInOut(duration: 0.1)
    static let searchTransition: Animation = .easeInOut(duration: 0.25)
    
    // MARK: - 延迟动画
    static func delayedAppear(delay: Double) -> Animation {
        return .easeInOut(duration: 0.4).delay(delay)
    }
}
