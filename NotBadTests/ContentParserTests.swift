//
//  ContentParserTests.swift
//  NotBadTests
//
//  Created by Yiming Liao on 9/21/25.
//

import XCTest
@testable import NotBad

final class ContentParserTests: XCTestCase {
    
    func testParsedContent_isValid_withValidContent() {
        // Given
        let parsedContent = ParsedContent(
            question: "什么是Swift？",
            answer: "Swift是苹果开发的编程语言"
        )
        
        // When & Then
        XCTAssertTrue(parsedContent.isValid)
    }
    
    func testParsedContent_isValid_withEmptyQuestion() {
        // Given
        let parsedContent = ParsedContent(
            question: "",
            answer: "这是答案"
        )
        
        // When & Then
        XCTAssertFalse(parsedContent.isValid)
    }
    
    func testParsedContent_isValid_withEmptyAnswer() {
        // Given
        let parsedContent = ParsedContent(
            question: "这是问题",
            answer: ""
        )
        
        // When & Then
        XCTAssertFalse(parsedContent.isValid)
    }
    
    func testParsedContent_isValid_withWhitespaceOnly() {
        // Given
        let parsedContent = ParsedContent(
            question: "   \n  ",
            answer: "  \t  "
        )
        
        // When & Then
        XCTAssertFalse(parsedContent.isValid)
    }
}