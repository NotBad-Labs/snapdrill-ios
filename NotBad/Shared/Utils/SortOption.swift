//
//  SortOption.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  SortOption.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation

enum SortOption: String, CaseIterable {
    // 时间排序
    case newest = "最新创建"
    case oldest = "最早创建"
    
    // 难度排序
    case easiest = "难度从低到高"
    case hardest = "难度从高到低"
    
    // 复习状态排序
    case reviewedFirst = "已复习优先"
    case unreviewedFirst = "未复习优先"
    
    // 内容长度排序
    case shortestContent = "题目最短"
    case longestContent = "题目最长"
    
    // 复习次数排序
    case mostReviewed = "复习次数最多"
    case leastReviewed = "复习次数最少"
    
    // 标签数量排序
    case mostTags = "标签最多"
    case leastTags = "标签最少"
    
    var systemImage: String {
        switch self {
        case .newest: return "clock.arrow.trianglehead.counterclockwise"
        case .oldest: return "clock"
        case .easiest: return "arrow.up"
        case .hardest: return "arrow.down"
        case .reviewedFirst: return "checkmark.circle"
        case .unreviewedFirst: return "circle"
        case .shortestContent: return "textformat.size.smaller"
        case .longestContent: return "textformat.size.larger"
        case .mostReviewed: return "repeat.circle"
        case .leastReviewed: return "repeat.circle.fill"
        case .mostTags: return "tag.circle.fill"
        case .leastTags: return "tag.circle"
        }
    }
    
    var category: SortCategory {
        switch self {
        case .newest, .oldest:
            return .time
        case .easiest, .hardest:
            return .difficulty
        case .reviewedFirst, .unreviewedFirst:
            return .reviewStatus
        case .shortestContent, .longestContent:
            return .content
        case .mostReviewed, .leastReviewed:
            return .reviewCount
        case .mostTags, .leastTags:
            return .tags
        }
    }
}

enum SortCategory: String, CaseIterable {
    case time = "时间"
    case difficulty = "难度"
    case reviewStatus = "复习状态"
    case content = "内容长度"
    case reviewCount = "复习次数"
    case tags = "标签数量"
    
    var systemImage: String {
        switch self {
        case .time: return "clock"
        case .difficulty: return "chart.bar"
        case .reviewStatus: return "checkmark.circle"
        case .content: return "textformat"
        case .reviewCount: return "repeat"
        case .tags: return "tag"
        }
    }
}
