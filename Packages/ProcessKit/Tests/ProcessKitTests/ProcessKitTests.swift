import Testing
@testable import ProcessKit

@Suite("ProcessKit Tests")
struct ProcessKitTests {
    
    @Test("ProcessKit 版本信息")
    func testVersion() {
        #expect(ProcessKit.version == "0.1.0")
        #expect(ProcessKit.name == "ProcessKit")
    }
}
