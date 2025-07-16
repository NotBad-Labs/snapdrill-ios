//
//  SortOption.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation

enum SortOption: String, CaseIterable {
    case newest = "最新创建"
    case oldest = "最早创建"
    case easiest = "难度从低到高"
    case hardest = "难度从高到低"
    
    var systemImage: String {
        switch self {
        case .newest: return "clock.arrow.trianglehead.counterclockwise"
        case .oldest: return "clock"
        case .easiest: return "arrow.up"
        case .hardest: return "arrow.down"
        }
    }
}