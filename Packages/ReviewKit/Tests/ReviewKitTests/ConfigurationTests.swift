import Testing
import Foundation
@testable import ReviewKit

@Suite("ReviewKitConfiguration Tests")
@MainActor
struct ConfigurationTests {
    
    @Test("Default configuration uses standard app group")
    func testDefaultConfiguration() {
        let config = ReviewKitConfiguration()
        
        #expect(config.appGroupIdentifier == "group.com.notbad.shared")
        #expect(config.databaseFileName == "NotBad.sqlite")
        #expect(config.imagesDirectoryName == "Images")
    }
    
    @Test("Custom configuration with custom container URL")
    func testCustomContainerURL() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CustomTest")
        let config = ReviewKitConfiguration(customContainerURL: tempURL)
        
        #expect(config.sharedContainerURL == tempURL)
        #expect(config.databaseURL == tempURL.appendingPathComponent("NotBad.sqlite"))
        #expect(config.imagesDirectoryURL == tempURL.appendingPathComponent("Images"))
    }
    
    @Test("Configuration validation - success with writable directory")
    func testValidationSuccess() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ValidationTest")
        try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let config = ReviewKitConfiguration(customContainerURL: tempURL)
        let result = config.validate()
        
        guard case .success = result else {
            Issue.record("Expected validation success")
            return
        }
    }
    
    @Test("Configuration validation - failure with invalid app group")
    func testValidationFailureAppGroup() {
        // 使用不存在的 App Group
        let config = ReviewKitConfiguration(
            appGroupIdentifier: "group.invalid.nonexistent.test",
            customContainerURL: nil  // 强制使用 App Group
        )
        
        let result = config.validate()
        
        guard case .failure(let error) = result else {
            Issue.record("Expected validation failure")
            return
        }
        
        switch error {
        case .appGroupNotConfigured(let identifier):
            #expect(identifier == "group.invalid.nonexistent.test")
        case .directoryNotWritable:
            // 在某些系统上可能返回此错误
            break
        }
    }
    
    @Test("Shared configuration can be updated")
    func testSharedConfigurationUpdate() {
        let original = ReviewKitConfiguration.shared
        let customIdentifier = "group.test.custom"
        
        let custom = ReviewKitConfiguration(appGroupIdentifier: customIdentifier)
        ReviewKitConfiguration.configure(custom)
        
        #expect(ReviewKitConfiguration.shared.appGroupIdentifier == customIdentifier)
        
        // 恢复原配置
        ReviewKitConfiguration.configure(original)
        #expect(ReviewKitConfiguration.shared.appGroupIdentifier == original.appGroupIdentifier)
    }
    
    @Test("Configuration pre-calculates URLs to avoid repeated I/O")
    func testURLPrecalculation() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PrecalcTest")
        let config = ReviewKitConfiguration(
            databaseFileName: "Custom.sqlite",
            imagesDirectoryName: "CustomImages",
            customContainerURL: tempURL
        )
        
        // URL 应该已经计算好
        #expect(config.sharedContainerURL == tempURL)
        #expect(config.databaseURL == tempURL.appendingPathComponent("Custom.sqlite"))
        #expect(config.imagesDirectoryURL == tempURL.appendingPathComponent("CustomImages"))
    }
    
    @Test("Configuration error messages are localized")
    func testErrorLocalization() {
        let error1 = ConfigurationError.appGroupNotConfigured(identifier: "test")
        let error2 = ConfigurationError.directoryNotWritable(
            url: URL(fileURLWithPath: "/tmp/test"),
            error: NSError(domain: "test", code: 1)
        )
        
        #expect(error1.errorDescription != nil)
        #expect(error2.errorDescription != nil)
        #expect(error1.errorDescription!.contains("test"))
    }
}
