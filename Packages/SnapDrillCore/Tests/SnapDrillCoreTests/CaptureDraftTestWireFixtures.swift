//
//  CaptureDraftTestWireFixtures.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import CryptoKit
import Foundation

struct TestEnvelope: Codable {
    let schemaVersion: Int
    let payloadByteCount: Int
    let payload: Data
    let payloadSHA256: Data

    init(
        schemaVersion: Int,
        payload: Data,
        payloadByteCount: Int? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.payloadByteCount = payloadByteCount ?? payload.count
        self.payload = payload
        payloadSHA256 = Data(SHA256.hash(data: payload))
    }
}

struct TestPayload: Codable {
    let captureID: UUID
    let generationID: UUID
    let timestampMilliseconds: Int64
    let content: String
    let contentUTF8ByteCount: Int
    let category: String?
    let imageJPEG: Data?
    let imageByteCount: Int

    init(
        captureID: UUID,
        generationID: UUID,
        timestampMilliseconds: Int64,
        content: String,
        contentUTF8ByteCount: Int? = nil,
        category: String?,
        imageJPEG: Data?,
        imageByteCount: Int? = nil
    ) {
        self.captureID = captureID
        self.generationID = generationID
        self.timestampMilliseconds = timestampMilliseconds
        self.content = content
        self.contentUTF8ByteCount = contentUTF8ByteCount ?? content.utf8.count
        self.category = category
        self.imageJPEG = imageJPEG
        self.imageByteCount = imageByteCount ?? imageJPEG?.count ?? 0
    }
}

extension JSONEncoder {
    static var sorted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
