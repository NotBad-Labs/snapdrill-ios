//
//  TaxonomyUseCase.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2026/02/27.
//

import Foundation

@MainActor
public final class TaxonomyUseCase: TaxonomyUseCaseProtocol {
    private let subjectRepo: SubjectRepositoryProtocol
    private let sourceRepo: SourceRepositoryProtocol
    private let tagRepo: TagRepositoryProtocol
    private let gradeRepo: GradeRepositoryProtocol
    private let reviewRepo: ReviewRepositoryProtocol

    public init(
        subjectRepo: SubjectRepositoryProtocol,
        sourceRepo: SourceRepositoryProtocol,
        tagRepo: TagRepositoryProtocol,
        gradeRepo: GradeRepositoryProtocol,
        reviewRepo: ReviewRepositoryProtocol
    ) {
        self.subjectRepo = subjectRepo
        self.sourceRepo = sourceRepo
        self.tagRepo = tagRepo
        self.gradeRepo = gradeRepo
        self.reviewRepo = reviewRepo
    }
    
    public func getSubjects() throws -> [Subject] {
        try subjectRepo.fetchAll()
    }
    
    public func getSources() throws -> [Source] {
        try sourceRepo.fetchAll()
    }
    
    public func getAllTags() throws -> [Tag] {
        try tagRepo.fetchAll()
    }
    
    public func getOrCreateTag(name: String, colorHex: String) throws -> Tag {
        if let existing = try tagRepo.fetchByName(name) {
            return existing
        }
        let newTag = Tag(name: name, colorHex: colorHex)
        try tagRepo.save(newTag)
        return newTag
    }
    
    public func addSubject(name: String, icon: String, colorHex: String) throws {
        let subject = Subject(name: name, icon: icon, colorHex: colorHex, sortOrder: try subjectRepo.totalCount())
        try subjectRepo.save(subject)
    }
    
    public func updateSubject(oldName: String, newName: String, icon: String, colorHex: String) throws {
        guard var existing = try subjectRepo.fetchByName(oldName) else { return }
        
        if oldName != newName {
            // 级联更新 ReviewItems 中的学科名称
            try reviewRepo.updateSubjectUsage(from: oldName, to: newName)
        }
        
        existing.name = newName
        existing.icon = icon
        existing.colorHex = colorHex
        try subjectRepo.save(existing)
    }
    
    public func deleteSubject(name: String) throws {
        guard try canDeleteSubject(name: name) else {
            throw DomainError.entityInUse(entityName: name)
        }
        if let subject = try subjectRepo.fetchByName(name) {
            try subjectRepo.delete(id: subject.id)
        }
    }
    
    public func canDeleteSubject(name: String) throws -> Bool {
        let count = try reviewRepo.countBySubject(name: name)
        return count == 0
    }
    
    public func addSource(name: String, icon: String, colorHex: String) throws {
        let source = Source(name: name, icon: icon, colorHex: colorHex, sortOrder: try sourceRepo.totalCount())
        try sourceRepo.save(source)
    }
    
    public func updateSource(oldName: String, newName: String, icon: String, colorHex: String) throws {
        guard var existing = try sourceRepo.fetchByName(oldName) else { return }
        
        if oldName != newName {
            // 级联更新 ReviewItems 中的来源名称
            try reviewRepo.updateSourceUsage(from: oldName, to: newName)
        }
        
        existing.name = newName
        existing.icon = icon
        existing.colorHex = colorHex
        try sourceRepo.save(existing)
    }
    
    public func deleteSource(name: String) throws {
        guard try canDeleteSource(name: name) else {
            throw DomainError.entityInUse(entityName: name)
        }
        if let source = try sourceRepo.fetchByName(name) {
            try sourceRepo.delete(id: source.id)
        }
    }
    
    public func canDeleteSource(name: String) throws -> Bool {
        let count = try reviewRepo.countBySource(name: name)
        return count == 0
    }
    
    // MARK: - Grade

    public func getGrades() throws -> [Grade] {
        try gradeRepo.fetchAll()
    }

    public func addGrade(name: String) throws {
        let grade = Grade(name: name, sortOrder: try gradeRepo.totalCount())
        try gradeRepo.save(grade)
    }

    public func updateGrade(oldName: String, newName: String) throws {
        guard var existing = try gradeRepo.fetchByName(oldName) else { return }

        if oldName != newName {
            // 级联更新 ReviewItems 中的年级名称
            try reviewRepo.updateGradeUsage(from: oldName, to: newName)
        }

        existing.name = newName
        try gradeRepo.save(existing)
    }

    public func deleteGrade(name: String) throws {
        guard try canDeleteGrade(name: name) else {
            throw DomainError.entityInUse(entityName: name)
        }
        if let grade = try gradeRepo.fetchByName(name) {
            try gradeRepo.delete(id: grade.id)
        }
    }

    public func canDeleteGrade(name: String) throws -> Bool {
        let count = try reviewRepo.countByGrade(name: name)
        return count == 0
    }

    public func deleteAllTaxonomy() throws {
        try subjectRepo.deleteAll()
        try sourceRepo.deleteAll()
        try tagRepo.deleteAll()
        try gradeRepo.deleteAll()
    }
}

public enum DomainError: Error, LocalizedError {
    /// 实体被引用，无法删除
    case entityInUse(entityName: String)
    /// 题目文字和图片不能同时为空
    case invalidContent

    public var errorDescription: String? {
        switch self {
        case .entityInUse(let name):
            return "无法删除「\(name)」，因为它正在被使用。"
        case .invalidContent:
            return "题目文字和图片至少需要填写一项。"
        }
    }
}
