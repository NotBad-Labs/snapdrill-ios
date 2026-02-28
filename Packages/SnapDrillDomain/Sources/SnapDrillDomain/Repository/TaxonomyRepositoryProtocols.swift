//
//  TaxonomyRepositoryProtocols.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2026/02/27.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：定义分类数据（学科/来源/标签/年级）的仓库层协议。
//

import Foundation

@MainActor
public protocol SubjectRepositoryProtocol: Sendable {
    func fetchAll() throws -> [Subject]
    func fetchByName(_ name: String) throws -> Subject?
    func save(_ subject: Subject) throws
    func delete(id: UUID) throws
    func totalCount() throws -> Int
    func seedDefaultsIfNeeded()
    func deleteAll() throws
}

@MainActor
public protocol SourceRepositoryProtocol: Sendable {
    func fetchAll() throws -> [Source]
    func fetchByName(_ name: String) throws -> Source?
    func save(_ source: Source) throws
    func delete(id: UUID) throws
    func totalCount() throws -> Int
    func seedDefaultsIfNeeded()
    func deleteAll() throws
}

@MainActor
public protocol TagRepositoryProtocol: Sendable {
    func fetchAll() throws -> [Tag]
    func fetchByName(_ name: String) throws -> Tag?
    func save(_ tag: Tag) throws
    func delete(id: UUID) throws
    func deleteAll() throws
}

@MainActor
public protocol GradeRepositoryProtocol: Sendable {
    func fetchAll() throws -> [Grade]
    func fetchByName(_ name: String) throws -> Grade?
    func save(_ grade: Grade) throws
    func delete(id: UUID) throws
    func totalCount() throws -> Int
    func seedDefaultsIfNeeded()
    func deleteAll() throws
}
