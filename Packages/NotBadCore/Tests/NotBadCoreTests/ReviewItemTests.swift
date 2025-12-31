import Testing
@testable import NotBadCore
import Foundation

struct ReviewItemTests {
    @Test
    func testInitialization() {
        let id = UUID()
        let now = Date()
        let item = ReviewItem(
            id: id,
            content: "Test Content",
            createdAt: now,
            subject: .math,
            source: .textbook,
            tags: ["easy"]
        )
        
        #expect(item.id == id)
        #expect(item.content == "Test Content")
        #expect(item.subject == .math)
        #expect(item.tags.count == 1)
    }
}
