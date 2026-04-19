//
//  SettingsViewModelCSVTests.swift
//  SnapDrillFeaturesTests
//
//  Created by NotBad Labs on 2026/04/19.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  importCSV 与 parseCSV/parseCSVLine 的行为锁定测试。
//
//  目的：在 PR2 修正 parser RFC 4180 偏差之前，先锁定当前实现的行为
//  （含已知 bug），防止修 parser 时意外破坏其他正常路径。
//
//  CSV 字面量全部用单行 `\n` 拼接表示（而非 `"""..."""` 多行），
//  避免 swiftlint 多行字符串解析误扫 CSV 数据里的 `,` 与 `+`。
//
//  测试命名约定：
//  - `importCSV_<scenario>_<expected>` 描述当前实现实际行为
//  - `__currentBehavior_` 前缀标记已知 bug 状态的 lock-in 测试
//    （PR2 修 bug 时这些测试会转为期望行为断言）
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillFeatureSettings
@testable import SnapDrillData
@testable import SnapDrillCore

@Suite("SettingsViewModel CSV 导入测试", .serialized)
final class SettingsViewModelCSVTests {

    private let container: ModelContainer
    private let repos: RepositoryContainer
    private let tmpDir: URL

    init() throws {
        let schema = Schema([
            ReviewItemModel.self,
            TagModel.self,
            SubjectModel.self,
            SourceModel.self,
            GradeModel.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        repos = RepositoryContainer(modelContext: container.mainContext)
        tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("csv-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: tmpDir)
    }

    // MARK: - Helpers

    /// 写 CSV 字符串到临时文件，返回 URL 供 importCSV 消费
    private func writeCSV(_ content: String, name: String = "test.csv") throws -> URL {
        let url = tmpDir.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Happy path

    @Test("happy path：标准 CSV 导入 3 道题")
    func importCSV_standardFormat_imports3Items() async throws {
        let csv = "Content,Subject,Difficulty\na+b=?,数学,1\nc+d=?,数学,2\ne+f=?,数学,3"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        #expect(vm.backupError == nil)
        #expect(vm.isBackupInProgress == false)
        let items = try repos.review.fetchAllModels()
        #expect(items.count == 3)
        #expect(items.contains { $0.content == "a+b=?" && $0.subject == "数学" && $0.difficulty == 1 })
        #expect(items.contains { $0.content == "c+d=?" && $0.difficulty == 2 })
        #expect(items.contains { $0.content == "e+f=?" && $0.difficulty == 3 })
    }

    // MARK: - 空文件与无效输入

    @Test("空文件：backupError 设为 importNoValidRows")
    func importCSV_emptyFile_setsNoValidRowsError() async throws {
        let url = try writeCSV("")
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        #expect(vm.backupError == L10n.Settings.importNoValidRows)
        #expect(try repos.review.fetchAllModels().isEmpty)
    }

    @Test("只有 header 无数据行：backupError 设为 importNoValidRows")
    func importCSV_onlyHeader_setsNoValidRowsError() async throws {
        let csv = "Content,Subject,Difficulty"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        #expect(vm.backupError == L10n.Settings.importNoValidRows)
        #expect(try repos.review.fetchAllModels().isEmpty)
    }

    @Test("content 与 subject 均为空的行被丢弃")
    func importCSV_rowWithNoContentOrSubject_isDiscarded() async throws {
        let csv = "Content,Subject,Difficulty\n,,1\n有内容的题,,2\n,数学,3"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        #expect(vm.backupError == nil)
        let items = try repos.review.fetchAllModels()
        #expect(items.count == 2)
    }

    // MARK: - 列名处理

    @Test("列名大小写不敏感：CONTENT = Content = content")
    func importCSV_columnNamesCaseInsensitive() async throws {
        let csv = "CONTENT,SUBJECT,DIFFICULTY\n题目,数学,3"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == "题目")
        #expect(items.first?.subject == "数学")
        #expect(items.first?.difficulty == 3)
    }

    // MARK: - RFC 4180 引号转义（当前 parseCSVLine 行级正确）

    @Test("RFC 4180：引号内逗号不切分字段")
    func importCSV_quotedCommaInField_preservedAsOneField() async throws {
        let csv = "Content,Subject\n\"含,逗号的题\",数学"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == "含,逗号的题")
    }

    @Test("RFC 4180：双引号转义 双引双引 转 单引号")
    func importCSV_escapedDoubleQuote_producesSingleQuote() async throws {
        let csv = "Content,Subject\n\"他说\"\"hello\"\"\",英语"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == "他说\"hello\"")
    }

    // MARK: - RFC 4180 字段内嵌换行（PR2 修复后期望行为）

    @Test("RFC 4180：字段内嵌换行不切分行，content 保留原始换行")
    func importCSV_embeddedNewlineInQuotedField_preservedAsOneRow() async throws {
        // RFC 4180 标准：带引号字段可含换行。新的状态机 parser 正确处理。
        let csv = "Content,Subject\n\"第一行\n第二行\",数学"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == "第一行\n第二行")
        #expect(items.first?.subject == "数学")
    }

    @Test("RFC 4180：CRLF 与 CR 行终止符归一化为 LF")
    func importCSV_crlfAndCrLineEndings_normalized() async throws {
        let csv = "Content,Subject\r\n题目1,数学\r题目2,英语"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 2)
        #expect(items.contains { $0.content == "题目1" && $0.subject == "数学" })
        #expect(items.contains { $0.content == "题目2" && $0.subject == "英语" })
    }

    // MARK: - Codex Review 🔴/🟡 边界补测（追加）

    @Test("RFC 4180：UTF-8 BOM 前缀剥离，首列 header 映射正确")
    func importCSV_utf8BOM_stripped() async throws {
        // Excel 导出 CSV 常带 BOM。不剥会让 headers[0] = "\uFEFFcontent" 导致字段映射失败。
        let csv = "\u{FEFF}Content,Subject,Difficulty\n题目,数学,3"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect(items.first?.content == "题目")
        #expect(items.first?.subject == "数学")
        #expect(items.first?.difficulty == 3)
    }

    @Test("trailing newline：尾随换行不产生空行")
    func importCSV_trailingNewline_noEmptyRow() async throws {
        let csv = "Content,Subject\n题目1,数学\n题目2,英语\n"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 2)
    }

    @Test("奇数引号（未闭合）：宽松吞入，剩余内容成为同字段一部分")
    func importCSV_unclosedQuote_lenientAbsorb() async throws {
        // 当前状态机对格式错误输入采用宽松容错策略（Codex 🟡 指出可能静默误拼接）。
        // 锁定此行为：奇数引号被视为开始一个引号字段，剩余所有字符直到 EOF 都被吞入。
        let csv = "Content,Subject\n\"未闭合的引号,数学"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        // 宽松吞入：content 含逗号+后续字段全部，subject 不设
        #expect(items.count == 1)
        #expect(items.first?.content == "未闭合的引号,数学")
    }

    @Test("空引号字段：trimming 后为空不写入 dict")
    func importCSV_emptyQuotedField_treatedAsEmpty() async throws {
        let csv = "Content,Subject\n\"\",数学"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        // content 为空，但 subject 有值 → 仍算有效行（parseCSV 要求 content 或 subject 至少一个）
        #expect(items.count == 1)
        #expect(items.first?.subject == "数学")
        // content 为空时 ReviewItemModel.content 应为 nil（init 参数 content: String? 对空过滤）
        #expect(items.first?.content == nil || items.first?.content?.isEmpty == true)
    }

    // MARK: - Tags 字段处理（分号分隔）

    @Test("Tags 字段按分号分隔并创建多个 tag")
    func importCSV_tagsFieldSemicolonSplit_createsMultipleTags() async throws {
        let csv = "Content,Subject,Tags\n题目,数学,代数;方程;初中"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        let tagNames = (items.first?.tags ?? []).map { $0.name }.sorted()
        #expect(tagNames == ["代数", "初中", "方程"])
    }

    @Test("Tags 字段为空不创建 tag")
    func importCSV_emptyTagsField_noTagsCreated() async throws {
        let csv = "Content,Subject,Tags\n题目,数学,"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.count == 1)
        #expect((items.first?.tags ?? []).isEmpty)
    }

    // MARK: - Difficulty clamp

    @Test("Difficulty 越界低值（0）clamp 到 1")
    func importCSV_difficultyBelow1_clampedTo1() async throws {
        let csv = "Content,Subject,Difficulty\n题目,数学,0"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.first?.difficulty == 1)
    }

    @Test("Difficulty 越界高值（99）clamp 到 5")
    func importCSV_difficultyAbove5_clampedTo5() async throws {
        let csv = "Content,Subject,Difficulty\n题目,数学,99"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.first?.difficulty == 5)
    }

    @Test("Difficulty 非数字 fallback 到 1")
    func importCSV_difficultyNonNumeric_fallsBackTo1() async throws {
        let csv = "Content,Subject,Difficulty\n题目,数学,abc"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.first?.difficulty == 1)
    }

    @Test("缺失 Difficulty 列 fallback 到 1")
    func importCSV_missingDifficultyColumn_fallsBackTo1() async throws {
        let csv = "Content,Subject\n题目,数学"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.first?.difficulty == 1)
    }

    // MARK: - 可选列默认值

    @Test("缺失 Subject 列时 subject 为空串")
    func importCSV_missingSubjectColumn_subjectEmpty() async throws {
        let csv = "Content,Difficulty\n题目,3"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.first?.subject == "")
    }

    @Test("Answer 列非空时写入 answerText")
    func importCSV_answerColumn_populatesAnswerText() async throws {
        let csv = "Content,Subject,Answer\na+b=?,数学,答案文本"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        let items = try repos.review.fetchAllModels()
        #expect(items.first?.answerText == "答案文本")
    }

    // MARK: - 状态机

    @Test("isBackupInProgress 导入前后恢复为 false")
    func importCSV_stateMachine_resetsInProgress() async throws {
        let csv = "Content,Subject,Difficulty\n题目,数学,1"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        await vm.importCSV(fileURL: url)

        #expect(vm.isBackupInProgress == false)
    }

    @Test("importCSV 与 createBackup 互斥：isBackupInProgress 时直接返回")
    func importCSV_whenAlreadyInProgress_skipsExecution() async throws {
        let csv = "Content,Subject,Difficulty\n题目,数学,1"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        vm.isBackupInProgress = true

        await vm.importCSV(fileURL: url)

        #expect(try repos.review.fetchAllModels().isEmpty)
    }

    // MARK: - 通知

    @Test("导入成功后发送 reviewDataDidChange 通知")
    func importCSV_successful_postsNotification() async throws {
        let csv = "Content,Subject,Difficulty\n题目,数学,1"
        let url = try writeCSV(csv)
        let vm = SettingsViewModel(repositories: repos)

        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .reviewDataDidChange,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        await vm.importCSV(fileURL: url)

        #expect(notificationReceived == true)
    }
}
