//
//  CaptureDraftServiceTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  CaptureDraftService 草稿生命周期测试（UIKit 平台专用）。

import Testing
import UIKit
@testable import SnapDrillCore

@Suite("CaptureDraftService 单元测试", .serialized)
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
        #expect(draft?.image?.size.width ?? 0 > 0)
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

    // MARK: - 纯文字草稿

    @Test("纯文字草稿（无图片）round-trip 正常")
    func saveDraft_textOnly_roundTrip() async {
        cleanup()
        await service.saveDraft(image: nil, content: "手动输入的文字内容")

        let draft = service.loadDraft()
        #expect(draft != nil)
        #expect(draft?.content == "手动输入的文字内容")
        #expect(draft?.image == nil)
        cleanup()
    }

    @Test("纯文字草稿覆盖带图草稿后，图片文件被清理")
    func saveDraft_textOverwritesImage_imageFileRemoved() async {
        cleanup()
        // 先保存带图草稿
        await service.saveDraft(image: createTestImage(), content: "有图")
        #expect(service.loadDraft()?.image != nil)

        // 再保存纯文字草稿，应覆盖图片
        await service.saveDraft(image: nil, content: "纯文字")
        let draft = service.loadDraft()
        #expect(draft?.content == "纯文字")
        #expect(draft?.image == nil)
        cleanup()
    }

    // MARK: - 数据隔离：草稿图按 Profile 隔离（防敏感数据串档，撞儿童隐私隔离根基）

    @Test("草稿图按 Profile 隔离：切换档案后读不到另一档案的草稿图（防串档）")
    func draftImage_isolatedByProfile() async {
        let originalProfile = UserDefaults.standard.string(forKey: UDKey.activeProfileId)
        defer {
            // 清理两个测试档案的草稿图 + 恢复原 activeProfileId
            UserDefaults.standard.set("profile-iso-A", forKey: UDKey.activeProfileId)
            service.clearDraft()
            UserDefaults.standard.set("profile-iso-B", forKey: UDKey.activeProfileId)
            service.clearDraft()
            if let originalProfile {
                UserDefaults.standard.set(originalProfile, forKey: UDKey.activeProfileId)
            } else {
                UserDefaults.standard.removeObject(forKey: UDKey.activeProfileId)
            }
        }

        // 档案 A 存带图草稿
        UserDefaults.standard.set("profile-iso-A", forKey: UDKey.activeProfileId)
        await service.saveDraft(image: createTestImage(), content: "A 的题")
        #expect(service.loadDraft()?.image != nil, "档案 A 应能读回自己的草稿图")

        // 切到档案 B：草稿图路径按 profileId 隔离，B 读不到 A 的图
        UserDefaults.standard.set("profile-iso-B", forKey: UDKey.activeProfileId)
        #expect(service.loadDraft()?.image == nil, "切换档案后不应读到另一档案的草稿图（防敏感数据串档）")
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
