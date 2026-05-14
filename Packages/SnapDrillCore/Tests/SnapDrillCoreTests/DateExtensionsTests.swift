//
//  DateExtensionsTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Date+Extensions 日期格式化与相对描述测试。

import Testing
import Foundation
@testable import SnapDrillCore

@Suite("Date+Extensions 单元测试")
struct DateExtensionsTests {

    // MARK: - iso8601DateString

    @Test("iso8601DateString 格式正确")
    func iso8601DateString_correctFormat() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        let components = DateComponents(year: 2026, month: 3, day: 10)
        let date = try #require(calendar.date(from: components))

        #expect(date.iso8601DateString == "2026-03-10")
    }

    // MARK: - relativeDescription

    @Test("今天返回「今天」")
    func relativeDescription_today() {
        let now = Date()
        #expect(now.relativeDescription(relativeTo: now) == "今天")
    }

    @Test("明天返回「明天」")
    func relativeDescription_tomorrow() throws {
        let now = Date()
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: now))
        #expect(tomorrow.relativeDescription(relativeTo: now) == "明天")
    }

    @Test("昨天返回「昨天」")
    func relativeDescription_yesterday() throws {
        let now = Date()
        let yesterday = try #require(Calendar.current.date(byAdding: .day, value: -1, to: now))
        #expect(yesterday.relativeDescription(relativeTo: now) == "昨天")
    }

    @Test("未来多天返回「N天后」")
    func relativeDescription_futureDays() throws {
        let now = Date()
        let future = try #require(Calendar.current.date(byAdding: .day, value: 5, to: now))
        #expect(future.relativeDescription(relativeTo: now) == "5天后")
    }

    @Test("过去多天返回「N天前」")
    func relativeDescription_pastDays() throws {
        let now = Date()
        let past = try #require(Calendar.current.date(byAdding: .day, value: -3, to: now))
        #expect(past.relativeDescription(relativeTo: now) == "3天前")
    }
}
