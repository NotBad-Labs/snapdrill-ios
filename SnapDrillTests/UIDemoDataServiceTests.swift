import SwiftData
import Testing
@testable import SnapDrill

@Test @MainActor
func uiDemoDatasetRoundTrip() throws {
    let schema = Schema([Subject.self, MistakeItem.self, MistakeTag.self, CaptureDraft.self])
    let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let context = container.mainContext
  let subject = Subject(name: "Math", colorHex: "3B82F6", sortOrder: 0, isBuiltin: true)
    context.insert(subject)

    let loaded = try UIDemoDataService.loadDemoDataset(context: context)
    #expect(loaded > 0)

    let again = try UIDemoDataService.loadDemoDataset(context: context)
    #expect(again == loaded)

    let removed = try UIDemoDataService.clearDemoSamples(context: context)
    #expect(removed == loaded)
}