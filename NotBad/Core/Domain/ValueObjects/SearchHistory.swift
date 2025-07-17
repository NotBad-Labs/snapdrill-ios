//
//  SearchHistory.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  SearchHistory.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import Foundation

struct SearchHistory: Codable, Identifiable, Equatable {
    let id: UUID
    let term: String
    let searchedAt: Date
    let resultCount: Int
    
    init(term: String, resultCount: Int) {
        self.id = UUID()
        self.term = term
        self.searchedAt = Date()
        self.resultCount = resultCount
    }
}

// MARK: - Comparable for sorting
extension SearchHistory: Comparable {
    static func < (lhs: SearchHistory, rhs: SearchHistory) -> Bool {
        lhs.searchedAt > rhs.searchedAt // 最新的在前
    }
}