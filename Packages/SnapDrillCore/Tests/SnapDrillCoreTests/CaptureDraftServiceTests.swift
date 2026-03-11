//
//  CaptureDraftServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CaptureDraftService 草稿生命周期测试（UIKit 平台专用）。

#if canImport(UIKit)
import Testing
import UIKit
@testable import SnapDrillCore

@Suite("CaptureDraftService 单元测试", .serialized)
@MainActor
struct CaptureDraftServiceTests {

    private let service = CaptureDraftService.shared

    // 每个测试前后清理，避免状态污染
    private func cleanup() {
        service.clearDraft()
    }

    // MARK: - 基础生命周期

    @Test("初始状态或清理后 hasDraft 为 false")
    func initialState_noDraft() {
        cleanup()
        #expect(service.hasDraft == false)
        #expect(service.loadDraft() == nil)
    }

    @Test("saveDraft 后 hasDraft 为 true")
    func saveDraft_setsHasDraft() async {
        cleanup()
        let image = createTestImage()
        await service.saveDraft(image: image, content: "测试内容")

        #expect(service.hasDraft == true)
        cleanup()
    }

    @Test("saveDraft → loadDraft 内容完整")
    func saveDraft_thenLoad_contentPreserved() async {
        cleanup()
        let image = createTestImage()
        let content = "OCR 识别文本"
        await service.saveDraft(image: image, content: content)

        let draft = service.loadDraft()
        #expect(draft != nil)
        #expect(draft?.content == content)
        #expect(draft?.image.size.width > 0)
        cleanup()
    }

    @Test("saveDraft → loadDraft 时间戳合理")
    func saveDraft_thenLoad_timestampReasonable() async {
        cleanup()
        let beforeSave = Date()
        await service.saveDraft(image: createTestImage(), content: "")
        let afterSave = Date()

        let draft = service.loadDraft()
        #expect(draft != nil)
        if let date = draft?.date {
            #expect(date >= beforeSave.addingTimeInterval(-1))
            #expect(date <= afterSave.addingTimeInterval(1))
        }
        cleanup()
    }

    @Test("clearDraft 后 hasDraft 恢复 false")
    func clearDraft_resetsState() async {
        cleanup()
        await service.saveDraft(image: createTestImage(), content: "临时")
        #expect(service.hasDraft == true)

        service.clearDraft()
        #expect(service.hasDraft == false)
        #expect(service.loadDraft() == nil)
    }

    @Test("saveDraft 空字符串 content 可正常存取")
    func saveDraft_emptyContent_roundTrip() async {
        cleanup()
        await service.saveDraft(image: createTestImage(), content: "")

        let draft = service.loadDraft()
        #expect(draft?.content == "")
        cleanup()
    }

    @Test("连续 saveDraft 覆盖旧草稿")
    func saveDraft_twice_overwritesPrevious() async {
        cleanup()
        await service.saveDraft(image: createTestImage(), content: "第一次")
        await service.saveDraft(image: createTestImage(), content: "第二次")

        let draft = service.loadDraft()
        #expect(draft?.content == "第二次")
        cleanup()
    }

    @Test("saveDraft 含 Unicode 特殊字符")
    func saveDraft_unicodeContent_preserved() async {
        cleanup()
        let content = "∫₀^∞ e⁻ˣ dx = 1\n👨‍👩‍👧‍👦"
        await service.saveDraft(image: createTestImage(), content: content)

        let draft = service.loadDraft()
        #expect(draft?.content == content)
        cleanup()
    }

    // MARK: - 错误路径

    @Test("loadDraft 元数据损坏时返回 nil 而非崩溃")
    func loadDraft_whenMetadataCorrupted_shouldReturnNil() {
        cleanup()
        // 写入无法解码为 DraftMetadata 的垃圾数据
        let corruptedData = Data("not-valid-json".utf8)
        UserDefaults.standard.set(corruptedData, forKey: "com.snapdrill.captureDraftMetadata")

        let draft = service.loadDraft()
        #expect(draft == nil, "元数据损坏时应返回 nil")
        cleanup()
    }

    @Test("clearDraft 草稿文件已不存在时不抛出异常")
    func clearDraft_whenFileAlreadyDeleted_shouldNotThrow() async {
        cleanup()
        // 先保存再手动删除图片文件，模拟文件已被系统清理
        await service.saveDraft(image: createTestImage(), content: "将被删除")
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let imagePath = cacheDir.appendingPathComponent("draft_capture.jpg")
            try? FileManager.default.removeItem(at: imagePath)
        }
        // clearDraft 不应崩溃
        service.clearDraft()
        #expect(service.hasDraft == false)
    }

    @Test("loadDraft 图片文件不存在但元数据有效时返回 nil")
    func loadDraft_whenImageMissing_shouldReturnNil() async {
        cleanup()
        await service.saveDraft(image: createTestImage(), content: "有元数据无图片")
        // 手动删除图片文件
        if let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let imagePath = cacheDir.appendingPathComponent("draft_capture.jpg")
            try? FileManager.default.removeItem(at: imagePath)
        }
        let draft = service.loadDraft()
        #expect(draft == nil, "图片文件丢失时应返回 nil")
        cleanup()
    }

    // MARK: - Private Helpers

    private func createTestImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10), format: format)
        return renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }
}
#endif
