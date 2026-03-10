//
//  CollectionSafeTests.swift
//  SnapDrillCoreTests
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Collection+Safe 安全下标扩展测试。

import Testing
@testable import SnapDrillCore

@Suite("Collection+Safe 单元测试")
struct CollectionSafeTests {

    @Test("有效索引返回对应元素")
    func validIndex_returnsElement() {
        let array = ["a", "b", "c"]
        #expect(array[safe: 0] == "a")
        #expect(array[safe: 1] == "b")
        #expect(array[safe: 2] == "c")
    }

    @Test("负索引返回 nil")
    func negativeIndex_returnsNil() {
        let array = [1, 2, 3]
        #expect(array[safe: -1] == nil)
    }

    @Test("越界索引返回 nil")
    func outOfBoundsIndex_returnsNil() {
        let array = [1, 2, 3]
        #expect(array[safe: 3] == nil)
        #expect(array[safe: 100] == nil)
    }

    @Test("空数组任何索引返回 nil")
    func emptyArray_returnsNil() {
        let array: [String] = []
        #expect(array[safe: 0] == nil)
    }

    @Test("适用于其他 Collection 类型")
    func worksWithOtherCollections() {
        // ArraySlice
        let slice = [10, 20, 30, 40][1...2]
        #expect(slice[safe: 1] == 20)
        #expect(slice[safe: 0] == nil) // slice 起始 index 是 1
    }
}
