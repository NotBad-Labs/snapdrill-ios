//
//  QuestionAttachment.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  QuestionAttachment.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 题目附件值对象
/// 代表题目可能包含的图片、音频、视频或文档等附件。
/// 这是一个不可变的值对象。
struct QuestionAttachment: Codable, Sendable, Hashable {
    let id: UUID // 附件的唯一标识符
    let type: AttachmentType // 附件类型
    let url: URL // 附件的URL（例如，存储在云端或本地文件系统）
    let description: String? // 附件的描述或标题

    /// 附件类型枚举
    enum AttachmentType: String, Codable, Sendable {
        case image = "image"
        case audio = "audio"
        case video = "video"
        case document = "document"
    }

    /// 初始化 QuestionAttachment
    /// - Parameters:
    ///   - id: 附件的唯一标识符，默认为新的UUID
    ///   - type: 附件的类型
    ///   - url: 附件的URL
    ///   - description: 附件的描述，可选
    init(id: UUID = UUID(), type: AttachmentType, url: URL, description: String? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.description = description
    }
}
