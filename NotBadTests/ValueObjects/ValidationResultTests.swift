//
//  ValidationResultTests.swift
//  NotBadTests
//
//  验证结果值对象单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("ValidationResult 值对象测试")
struct ValidationResultTests {
    
    // MARK: - ValidationIssue 测试
    
    @Test("ValidationIssue 错误类型正确分类")
    func issueErrorClassification() {
        // 错误类型
        #expect(ValidationIssue.titleRequired.isError == true, "titleRequired 应该是错误")
        #expect(ValidationIssue.imageRequired.isError == true, "imageRequired 应该是错误")
        
        // 警告类型
        #expect(ValidationIssue.contentSuggested.isError == false, "contentSuggested 不应该是错误")
        #expect(ValidationIssue.knowledgePointsSuggested.isError == false, "knowledgePointsSuggested 不应该是错误")
    }
    
    @Test("ValidationIssue 警告类型正确分类")
    func issueWarningClassification() {
        // 错误不是警告
        #expect(ValidationIssue.titleRequired.isWarning == false, "titleRequired 不应该是警告")
        #expect(ValidationIssue.imageRequired.isWarning == false, "imageRequired 不应该是警告")
        
        // 警告类型
        #expect(ValidationIssue.contentSuggested.isWarning == true, "contentSuggested 应该是警告")
        #expect(ValidationIssue.knowledgePointsSuggested.isWarning == true, "knowledgePointsSuggested 应该是警告")
    }
    
    @Test("ValidationIssue isError 和 isWarning 互斥")
    func issueErrorWarningMutuallyExclusive() {
        let allIssues: [ValidationIssue] = [
            .titleRequired,
            .imageRequired,
            .contentSuggested,
            .knowledgePointsSuggested
        ]
        
        for issue in allIssues {
            #expect(issue.isError != issue.isWarning, "\(issue) 的 isError 和 isWarning 应该互斥")
        }
    }
    
    @Test("ValidationIssue 本地化消息非空")
    func issueLocalizedMessageNotEmpty() {
        let allIssues: [ValidationIssue] = [
            .titleRequired,
            .imageRequired,
            .contentSuggested,
            .knowledgePointsSuggested
        ]
        
        for issue in allIssues {
            #expect(!issue.localizedMessage.isEmpty, "\(issue) 应该有本地化消息")
        }
    }
    
    // MARK: - ValidationResult 初始化测试
    
    @Test("空 issues 创建有效结果")
    func emptyIssuesCreatesValidResult() {
        let result = ValidationResult(issues: [])
        
        #expect(result.isValid == true, "无 issues 应该是有效的")
        #expect(result.isPerfect == true, "无 issues 应该是完美的")
        #expect(result.errors.isEmpty, "应该没有错误")
        #expect(result.warnings.isEmpty, "应该没有警告")
    }
    
    @Test("只有警告时仍然有效")
    func warningsOnlyIsStillValid() {
        let result = ValidationResult(issues: [.contentSuggested, .knowledgePointsSuggested])
        
        #expect(result.isValid == true, "只有警告时应该是有效的")
        #expect(result.isPerfect == false, "有警告时不应该是完美的")
        #expect(result.errors.isEmpty, "不应该有错误")
        #expect(result.warnings.count == 2, "应该有 2 个警告")
    }
    
    @Test("有错误时无效")
    func errorsAreInvalid() {
        let result = ValidationResult(issues: [.titleRequired])
        
        #expect(result.isValid == false, "有错误时应该是无效的")
        #expect(result.isPerfect == false, "有错误时不应该是完美的")
        #expect(result.errors.count == 1, "应该有 1 个错误")
    }
    
    @Test("混合错误和警告")
    func mixedErrorsAndWarnings() {
        let result = ValidationResult(issues: [
            .titleRequired,
            .imageRequired,
            .contentSuggested
        ])
        
        #expect(result.isValid == false, "有错误时应该是无效的")
        #expect(result.errors.count == 2, "应该有 2 个错误")
        #expect(result.warnings.count == 1, "应该有 1 个警告")
    }
    
    // MARK: - 错误/警告过滤测试
    
    @Test("errors 只返回错误类型")
    func errorsFilterCorrectly() {
        let result = ValidationResult(issues: [
            .titleRequired,
            .contentSuggested,
            .imageRequired
        ])
        
        let errors = result.errors
        #expect(errors.count == 2, "应该有 2 个错误")
        #expect(errors.contains(.titleRequired), "应该包含 titleRequired")
        #expect(errors.contains(.imageRequired), "应该包含 imageRequired")
        #expect(!errors.contains(.contentSuggested), "不应该包含警告")
    }
    
    @Test("warnings 只返回警告类型")
    func warningsFilterCorrectly() {
        let result = ValidationResult(issues: [
            .titleRequired,
            .contentSuggested,
            .knowledgePointsSuggested
        ])
        
        let warnings = result.warnings
        #expect(warnings.count == 2, "应该有 2 个警告")
        #expect(warnings.contains(.contentSuggested), "应该包含 contentSuggested")
        #expect(warnings.contains(.knowledgePointsSuggested), "应该包含 knowledgePointsSuggested")
        #expect(!warnings.contains(.titleRequired), "不应该包含错误")
    }
    
    // MARK: - 消息列表测试
    
    @Test("errorMessages 返回错误的本地化消息")
    func errorMessagesCorrect() {
        let result = ValidationResult(issues: [.titleRequired, .contentSuggested])
        
        let messages = result.errorMessages
        #expect(messages.count == 1, "应该只有 1 个错误消息")
        #expect(messages.first == ValidationIssue.titleRequired.localizedMessage, "消息应该匹配")
    }
    
    @Test("allMessages 返回所有本地化消息")
    func allMessagesCorrect() {
        let result = ValidationResult(issues: [.titleRequired, .contentSuggested])
        
        let messages = result.allMessages
        #expect(messages.count == 2, "应该有 2 个消息")
    }
    
    // MARK: - 工厂方法测试
    
    @Test("valid 静态属性创建有效结果")
    func validFactoryMethod() {
        let result = ValidationResult.valid
        
        #expect(result.isValid == true, "valid 应该是有效的")
        #expect(result.isPerfect == true, "valid 应该是完美的")
        #expect(result.issues.isEmpty, "valid 应该没有 issues")
    }
    
    @Test("invalid 工厂方法创建无效结果")
    func invalidFactoryMethod() {
        let result = ValidationResult.invalid([.titleRequired, .imageRequired])
        
        #expect(result.isValid == false, "invalid 应该是无效的")
        #expect(result.errors.count == 2, "应该有 2 个错误")
    }
    
    // MARK: - CustomStringConvertible 测试
    
    @Test("description 完美结果")
    func descriptionPerfect() {
        let result = ValidationResult.valid
        
        #expect(result.description.contains("Perfect"), "完美结果描述应该包含 'Perfect'")
    }
    
    @Test("description 有警告但有效")
    func descriptionValidWithWarnings() {
        let result = ValidationResult(issues: [.contentSuggested])
        
        #expect(result.description.contains("Valid"), "有效结果描述应该包含 'Valid'")
        #expect(result.description.contains("1 warning"), "应该显示警告数量")
    }
    
    @Test("description 无效")
    func descriptionInvalid() {
        let result = ValidationResult(issues: [.titleRequired, .contentSuggested])
        
        #expect(result.description.contains("Invalid"), "无效结果描述应该包含 'Invalid'")
        #expect(result.description.contains("1 error"), "应该显示错误数量")
    }
    
    // MARK: - Sendable 测试
    
    @Test("ValidationIssue 是 Sendable")
    func issueIsSendable() async {
        let issue = ValidationIssue.titleRequired
        
        await Task {
            _ = issue.isError
        }.value
    }
    
    @Test("ValidationResult 是 Sendable")
    func resultIsSendable() async {
        let result = ValidationResult(issues: [.titleRequired])
        
        await Task {
            _ = result.isValid
        }.value
    }
    
    // MARK: - Equatable 测试
    
    @Test("ValidationIssue Equatable 正确实现")
    func issueEquatable() {
        #expect(ValidationIssue.titleRequired == ValidationIssue.titleRequired)
        #expect(ValidationIssue.titleRequired != ValidationIssue.imageRequired)
    }
}
