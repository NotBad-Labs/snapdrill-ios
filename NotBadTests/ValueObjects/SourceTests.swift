//
//  SourceTests.swift
//  NotBadTests
//
//  来源值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("Source 值对象测试")
struct SourceTests {

    // MARK: - 基础测试

    @Test("Source 有11种来源")
    func sourceCount() {
        #expect(Source.allCases.count == 11)
    }

    @Test("所有来源都有显示名称")
    func allSourcesHaveDisplayNames() {
        for source in Source.allCases {
            #expect(!source.displayName.isEmpty)
        }
    }

    @Test("所有来源都有简短标签")
    func allSourcesHaveShortLabels() {
        for source in Source.allCases {
            #expect(!source.shortLabel.isEmpty)
        }
    }

    @Test("所有来源都有图标")
    func allSourcesHaveIcons() {
        for source in Source.allCases {
            #expect(!source.icon.isEmpty)
        }
    }

    // MARK: - 分类测试

    @Test("SourceCategory 有4种分类")
    func categoryCount() {
        #expect(SourceCategory.allCases.count == 4)
    }

    @Test("官方来源归类正确")
    func officialSourcesCategory() {
        #expect(Source.textbook.category == .official)
        #expect(Source.pastExam.category == .official)
    }

    @Test("学校来源归类正确")
    func schoolSourcesCategory() {
        #expect(Source.exam.category == .school)
        #expect(Source.mock.category == .school)
        #expect(Source.homework.category == .school)
    }

    @Test("课外来源归类正确")
    func extraSourcesCategory() {
        #expect(Source.workbook.category == .extra)
        #expect(Source.tutor.category == .extra)
        #expect(Source.competition.category == .extra)
    }

    @Test("其他来源归类正确")
    func otherSourcesCategory() {
        #expect(Source.online.category == .other)
        #expect(Source.selfTest.category == .other)
        #expect(Source.other.category == .other)
    }

    @Test("sources(in:) 返回正确数量")
    func sourcesInCategory() {
        #expect(Source.sources(in: .official).count == 2)
        #expect(Source.sources(in: .school).count == 3)
        #expect(Source.sources(in: .extra).count == 3)
        #expect(Source.sources(in: .other).count == 3)
    }

    // MARK: - 分类便捷属性测试

    @Test("isOfficial 正确判断")
    func isOfficialProperty() {
        #expect(Source.textbook.isOfficial == true)
        #expect(Source.pastExam.isOfficial == true)
        #expect(Source.homework.isOfficial == false)
    }

    @Test("isSchool 正确判断")
    func isSchoolProperty() {
        #expect(Source.exam.isSchool == true)
        #expect(Source.mock.isSchool == true)
        #expect(Source.textbook.isSchool == false)
    }

    @Test("isExtra 正确判断")
    func isExtraProperty() {
        #expect(Source.workbook.isExtra == true)
        #expect(Source.competition.isExtra == true)
        #expect(Source.exam.isExtra == false)
    }

    // MARK: - 重要程度测试

    @Test("importance 在1-5范围内")
    func importanceRange() {
        for source in Source.allCases {
            #expect(source.importance >= 1)
            #expect(source.importance <= 5)
        }
    }

    @Test("历年真题和考试重要程度最高")
    func pastExamAndExamHighestImportance() {
        #expect(Source.pastExam.importance == 5)
        #expect(Source.exam.importance == 5)
    }

    @Test("自测和其他重要程度最低")
    func selfTestAndOtherLowestImportance() {
        #expect(Source.selfTest.importance == 1)
        #expect(Source.other.importance == 1)
    }

    @Test("importanceDescription 返回非空字符串")
    func importanceDescriptionNotEmpty() {
        for source in Source.allCases {
            #expect(!source.importanceDescription.isEmpty)
        }
    }

    @Test("isHighImportance 正确判断")
    func isHighImportanceProperty() {
        #expect(Source.pastExam.isHighImportance == true)
        #expect(Source.competition.isHighImportance == true)
        #expect(Source.homework.isHighImportance == false)
    }

    // MARK: - 权威性和考试相关测试

    @Test("isAuthoritative 正确判断")
    func isAuthoritativeProperty() {
        #expect(Source.pastExam.isAuthoritative == true)
        #expect(Source.textbook.isAuthoritative == true)
        #expect(Source.exam.isAuthoritative == true)
        #expect(Source.homework.isAuthoritative == false)
    }

    @Test("isExamRelated 正确判断")
    func isExamRelatedProperty() {
        #expect(Source.pastExam.isExamRelated == true)
        #expect(Source.exam.isExamRelated == true)
        #expect(Source.mock.isExamRelated == true)
        #expect(Source.homework.isExamRelated == false)
    }

    @Test("isAdvanced 正确判断")
    func isAdvancedProperty() {
        #expect(Source.competition.isAdvanced == true)
        #expect(Source.tutor.isAdvanced == true)
        #expect(Source.homework.isAdvanced == false)
    }

    // MARK: - 静态集合测试

    @Test("officialSources 包含正确来源")
    func officialSourcesCollection() {
        #expect(Source.officialSources.contains(.textbook))
        #expect(Source.officialSources.contains(.pastExam))
        #expect(Source.officialSources.count == 2)
    }

    @Test("schoolSources 包含正确来源")
    func schoolSourcesCollection() {
        #expect(Source.schoolSources.contains(.exam))
        #expect(Source.schoolSources.contains(.mock))
        #expect(Source.schoolSources.contains(.homework))
        #expect(Source.schoolSources.count == 3)
    }

    @Test("examRelatedSources 包含正确来源")
    func examRelatedSourcesCollection() {
        #expect(Source.examRelatedSources.contains(.pastExam))
        #expect(Source.examRelatedSources.contains(.exam))
        #expect(Source.examRelatedSources.contains(.mock))
        #expect(Source.examRelatedSources.count == 3)
    }

    @Test("highImportanceSources 只包含重要程度>=4的来源")
    func highImportanceSourcesCollection() {
        for source in Source.highImportanceSources {
            #expect(source.importance >= 4)
        }
    }

    @Test("sortedByImportance 正确排序")
    func sortedByImportanceOrder() {
        let sorted = Source.sortedByImportance

        for i in 1..<sorted.count {
            #expect(sorted[i-1].importance >= sorted[i].importance)
        }
    }

    // MARK: - 查询方法测试

    @Test("sources(withImportance:) 返回正确来源")
    func sourcesWithImportance() {
        let level5 = Source.sources(withImportance: 5)

        #expect(level5.contains(.pastExam))
        #expect(level5.contains(.exam))

        for source in level5 {
            #expect(source.importance == 5)
        }
    }

    @Test("sources(withMinImportance:) 返回正确来源")
    func sourcesWithMinImportance() {
        let minLevel4 = Source.sources(withMinImportance: 4)

        for source in minLevel4 {
            #expect(source.importance >= 4)
        }
    }

    // MARK: - Codable 测试

    @Test("Codable 正确编解码")
    func codableRoundTrip() throws {
        let original = Source.pastExam

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Source.self, from: data)

        #expect(decoded == original)
    }
}
