import Testing
@testable import SnapDrill

@Test func japaneseLocaleSubjects() {
    let locale = Locale(identifier: "ja_JP")
    let names = SubjectCatalog.defaultSubjects(for: locale).map(\.name)
    #expect(names.contains("国語"))
    #expect(names.contains("数学"))
}

@Test func simplifiedChineseSubjects() {
    let locale = Locale(identifier: "zh_CN")
    let names = SubjectCatalog.defaultSubjects(for: locale).map(\.name)
    #expect(names.contains("语文"))
    #expect(names.contains("数学"))
}