//
//  PDFExportServiceTests.swift
//  NotBadTests
//
//  PDF 导出服务测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("PDFExportService 测试")
@MainActor
struct PDFExportServiceTests {
    
    @Test("单例存在")
    func singletonExists() {
        let service = PDFExportService.shared
        #expect(service != nil)
    }
    
    @Test("生成空列表返回有效 PDF")
    func generateEmptyList() {
        let service = PDFExportService.shared
        let result = service.exportToPDF(items: [])
        
        // 即使空列表也应该生成有效的 PDF
        #expect(result.count > 0)
    }
    
    @Test("导出带自定义标题")
    func exportWithCustomTitle() {
        let service = PDFExportService.shared
        let result = service.exportToPDF(items: [], title: "测试错题本")
        
        #expect(result.count > 0)
    }
    
    @Test("导出选项正确工作")
    func exportWithOptions() {
        let service = PDFExportService.shared
        
        let result1 = service.exportToPDF(items: [], includeImages: true, includeNotes: true)
        let result2 = service.exportToPDF(items: [], includeImages: false, includeNotes: false)
        
        // 两种配置都应该生成有效 PDF
        #expect(result1.count > 0)
        #expect(result2.count > 0)
    }
}
