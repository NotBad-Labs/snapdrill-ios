//
//  SubjectManagerView.swift
//  NotBadFeatureDashboard
//
//  Created by NotBad Agent on 2025/12/31.
//

import SwiftUI
import SwiftData
import NotBadData
import NotBadUI

// Keep existing SubjectManagerView ...
struct SubjectManagerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \SubjectModel.sortOrder) var subjects: [SubjectModel]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(subjects) { subject in
                    HStack {
                        Image(systemName: subject.icon)
                            .foregroundStyle(Color(hex: subject.colorHex))
                        Text(subject.name)
                    }
                }
                .onDelete(perform: deleteSubject)
            }
            .navigationTitle("管理学科")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubjectView()
            }
        }
    }
    
    func deleteSubject(at offsets: IndexSet) {
        for index in offsets {
            let subject = subjects[index]
            modelContext.delete(subject)
        }
    }
}

struct AddSubjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "book"
    @State private var selectedColorHex: String = "#4FC3F7"
    
    let colors = ["#E57373", "#4FC3F7", "#AED581", "#7986CB", "#F06292", "#FFB74D", "#9575CD"]
    let icons = ["book", "text.book.closed", "function", "character.book.closed", "atom", "flask", "leaf", "scroll", "globe", "paintbrush"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("学科名称") {
                    TextField("例如：微积分", text: $name)
                }
                
                Section("选择图标") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .padding(8)
                                .background(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
                
                Section("选择颜色") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("添加学科")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveSubject()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    func saveSubject() {
        let repo = SubjectRepository(modelContext: modelContext)
        repo.add(name: name, icon: selectedIcon, colorHex: selectedColorHex)
    }
}
