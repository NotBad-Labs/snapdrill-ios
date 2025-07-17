//
//  SortPicker.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//


//
//  SortPicker.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/16/25.
//

import SwiftUI

struct SortPicker: View {
    @Binding var selectedOption: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SortCategory.allCases, id: \.self) { category in
                    Section(header: sectionHeader(for: category)) {
                        ForEach(optionsForCategory(category), id: \.self) { option in
                            sortOptionRow(option: option)
                        }
                    }
                }
            }
            .navigationTitle("排序方式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func sectionHeader(for category: SortCategory) -> some View {
        HStack {
            Image(systemName: category.systemImage)
                .foregroundColor(.blue)
                .font(.caption)
            Text(category.rawValue)
                .font(.labelMedium)
        }
    }
    
    @ViewBuilder
    private func sortOptionRow(option: SortOption) -> some View {
        HStack {
            Image(systemName: option.systemImage)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(option.rawValue)
                .font(.bodyMedium)
            
            Spacer()
            
            if selectedOption == option {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.bodyMedium)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedOption = option
            dismiss()
        }
    }
    
    private func optionsForCategory(_ category: SortCategory) -> [SortOption] {
        SortOption.allCases.filter { $0.category == category }
    }
}

#Preview {
    SortPicker(selectedOption: .constant(.newest))
}