//
//  TaxonomyUseCaseProtocol.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2026/02/27.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：定义分类元数据（学科/来源/标签/年级）的业务用例协议。
//

import Foundation

/// 元数据业务用例协议
@MainActor
public protocol TaxonomyUseCaseProtocol: Sendable {
    func getSubjects() throws -> [Subject]
    func getSources() throws -> [Source]
    func getAllTags() throws -> [Tag]
    
    /// 获取或创建标签
    func getOrCreateTag(name: String, colorHex: String) throws -> Tag
    
    /// 添加学科
    func addSubject(name: String, icon: String, colorHex: String) throws
    
    /// 更新学科
    func updateSubject(oldName: String, newName: String, icon: String, colorHex: String) throws
    
    /// 删除学科
    func deleteSubject(name: String) throws
    
    /// 检查学科是否可以删除（无引用）
    func canDeleteSubject(name: String) throws -> Bool
    
    /// 添加来源
    func addSource(name: String, icon: String, colorHex: String) throws
    
    /// 更新来源
    func updateSource(oldName: String, newName: String, icon: String, colorHex: String) throws
    
    /// 删除来源
    func deleteSource(name: String) throws
    
    /// 检查来源是否可以删除（无引用）
    func canDeleteSource(name: String) throws -> Bool
    
    // MARK: - Grade

    /// 获取所有年级
    func getGrades() throws -> [Grade]

    /// 添加年级
    func addGrade(name: String) throws

    /// 更新年级（级联更新 ReviewItem.grade）
    func updateGrade(oldName: String, newName: String) throws

    /// 删除年级
    func deleteGrade(name: String) throws

    /// 检查年级是否可以删除（无引用）
    func canDeleteGrade(name: String) throws -> Bool

    /// 清空所有学科、来源与年级数据
    func deleteAllTaxonomy() throws
}
