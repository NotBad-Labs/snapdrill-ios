//
//  MockRepositories.swift
//  SnapDrillDomainTests
//
//  Created by SnapDrill Labs on 2026/02/28.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  Domain 层单测用内存 Mock 仓库。
//

import Foundation
@testable import SnapDrillDomain

// MARK: - MockReviewRepository

@MainActor
final class MockReviewRepository: ReviewRepositoryProtocol {
    var items: [UUID: ReviewItem] = [:]
    var saveCallCount = 0
    var deleteCallCount = 0

    func save(_ item: ReviewItem) throws {
        items[item.id] = item
        saveCallCount += 1
    }

    func fetchById(_ id: UUID) throws -> ReviewItem? { items[id] }

    func fetchByIds(_ ids: Set<UUID>) throws -> [ReviewItem] {
        ids.compactMap { items[$0] }
    }

    func fetchAll() throws -> [ReviewItem] { Array(items.values) }

    func fetchFiltered(
        searchText: String,
        subjects: Set<String>,
        tags: Set<String>,
        limit: Int,
        offset: Int
    ) throws -> [ReviewItem] {
        Array(items.values)
    }

    func totalCount() throws -> Int { items.count }

    func delete(id: UUID) throws {
        items.removeValue(forKey: id)
        deleteCallCount += 1
    }

    func countBySubject(name: String) throws -> Int {
        items.values.filter { $0.subject == name }.count
    }

    func updateSubjectUsage(from oldName: String, to newName: String) throws {
        for key in items.keys where items[key]?.subject == oldName {
            items[key]?.subject = newName
        }
    }

    func countBySource(name: String) throws -> Int {
        items.values.filter { $0.source == name }.count
    }

    func updateSourceUsage(from oldName: String, to newName: String) throws {
        for key in items.keys where items[key]?.source == oldName {
            items[key]?.source = newName
        }
    }

    func countByGrade(name: String) throws -> Int {
        items.values.filter { $0.grade == name }.count
    }

    func updateGradeUsage(from oldName: String, to newName: String) throws {
        for key in items.keys where items[key]?.grade == oldName {
            items[key]?.grade = newName
        }
    }

    func deleteAll() throws { items.removeAll() }

    func fetchDueItems() throws -> [ReviewItem] {
        let now = Date.now
        return items.values.filter { ($0.nextReviewAt ?? Date.distantPast) <= now }
    }

    func fetchDueCount() throws -> Int {
        try fetchDueItems().count
    }

    func fetchTodayCount() throws -> Int {
        let startOfToday = Calendar.current.startOfDay(for: Date.now)
        return items.values.filter { $0.createdAt >= startOfToday }.count
    }

    func fetchTodayReviewedCount() throws -> Int {
        let startOfToday = Calendar.current.startOfDay(for: Date.now)
        return items.values.filter {
            if let reviewed = $0.lastReviewedAt { return reviewed >= startOfToday }
            return false
        }.count
    }

    func totalItemCount() throws -> Int { items.count }
}

// MARK: - MockSubjectRepository

@MainActor
final class MockSubjectRepository: SubjectRepositoryProtocol {
    var subjects: [String: Subject] = [:]
    private var count: Int = 0

    func fetchAll() throws -> [Subject] { Array(subjects.values) }
    func fetchByName(_ name: String) throws -> Subject? { subjects[name] }
    func save(_ subject: Subject) throws { subjects[subject.name] = subject }
    func delete(id: UUID) throws { subjects = subjects.filter { $0.value.id != id } }
    func totalCount() throws -> Int { subjects.count }
    func initializeDefaultsIfNeeded() {}
    func deleteAll() throws { subjects.removeAll() }
}

// MARK: - MockSourceRepository

@MainActor
final class MockSourceRepository: SourceRepositoryProtocol {
    var sources: [String: Source] = [:]

    func fetchAll() throws -> [Source] { Array(sources.values) }
    func fetchByName(_ name: String) throws -> Source? { sources[name] }
    func save(_ source: Source) throws { sources[source.name] = source }
    func delete(id: UUID) throws { sources = sources.filter { $0.value.id != id } }
    func totalCount() throws -> Int { sources.count }
    func seedDefaultsIfNeeded() {}
    func deleteAll() throws { sources.removeAll() }
}

// MARK: - MockGradeRepository

@MainActor
final class MockGradeRepository: GradeRepositoryProtocol {
    var grades: [String: Grade] = [:]

    func fetchAll() throws -> [Grade] { Array(grades.values) }
    func fetchByName(_ name: String) throws -> Grade? { grades[name] }
    func save(_ grade: Grade) throws { grades[grade.name] = grade }
    func delete(id: UUID) throws { grades = grades.filter { $0.value.id != id } }
    func totalCount() throws -> Int { grades.count }
    func seedDefaultsIfNeeded() {}
    func deleteAll() throws { grades.removeAll() }
}

// MARK: - MockTagRepository

@MainActor
final class MockTagRepository: TagRepositoryProtocol {
    var tags: [String: Tag] = [:]

    func fetchAll() throws -> [Tag] { Array(tags.values) }
    func fetchByName(_ name: String) throws -> Tag? { tags[name] }
    func save(_ tag: Tag) throws { tags[tag.name] = tag }
    func delete(id: UUID) throws { tags = tags.filter { $0.value.id != id } }
    func deleteAll() throws { tags.removeAll() }
}
