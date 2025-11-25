//
//  LibraryViewModel.swift
//  NotBad
//
//  题库 ViewModel
//

import SwiftUI
import SwiftData

/// 题库 ViewModel
@MainActor
@Observable
final class LibraryViewModel {
    
    // MARK: - State
    
    var searchText = ""
    var selectedSubject: Subject?
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Filtering
    
    func filteredItems(from items: [ReviewItem]) -> [ReviewItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty ||
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.knowledgePoints.matches(searchText)
            
            let matchesSubject = selectedSubject == nil || item.subject == selectedSubject
            
            return matchesSearch && matchesSubject
        }
    }
    
    // MARK: - Actions
    
    func deleteItems(from items: [ReviewItem], at offsets: IndexSet) {
        guard let modelContext = modelContext else { return }
        
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
    
    func selectSubject(_ subject: Subject?) {
        selectedSubject = subject
    }
}
