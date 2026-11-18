import Foundation
import SwiftData
import UIKit

/// 方案 A：可清除的 UI 演示数据（非生产 F-10 / 真拍摄）。
@MainActor
enum UIDemoDataService {
    private static let demoTagNames = ["Midterm", "Chapter 3", "Needs review"]

    static func loadDemoDataset(context: ModelContext) throws -> Int {
        var demoCheck = FetchDescriptor<MistakeItem>(predicate: #Predicate { $0.isDemoSample == true })
        demoCheck.fetchLimit = 1
        if try !context.fetch(demoCheck).isEmpty {
            return try context.fetch(FetchDescriptor<MistakeItem>(predicate: #Predicate { $0.isDemoSample == true })).count
        }

        let subjects = try context.fetch(FetchDescriptor<Subject>(sortBy: [SortDescriptor(\.sortOrder)]))
            .filter { !$0.isUncategorizedBucket }
        guard !subjects.isEmpty else { return 0 }

        let tags = demoTagNames.map { MistakeTag(name: $0) }
        tags.forEach { context.insert($0) }

        var created = 0
        let samples: [(Int, String, String, [MistakeCause], String)] = [
            (0, "Sample · quadratic", "x = 2 or x = -3", [.calculationError], "Forgot ± under root."),
            (0, "Sample · fraction", "3/8", [.careless], ""),
            (1, "Sample · verb tense", "went", [.conceptUnclear], "Past simple vs present."),
            (1, "Sample · spelling", "necessary", [.careless], "One c, two s."),
            (2, "Sample · photosynthesis", "Light → chemical energy", [.methodUnknown], ""),
            (2, "Sample · lab result", "pH ≈ 7", [.misreadQuestion], "Misread scale."),
        ]

        for (index, title, answer, causes, notes) in samples {
            let subject = subjects[index % subjects.count]
            let item = MistakeItem(subject: subject)
            item.isDemoSample = true
            item.answerText = answer
            item.notes = notes.isEmpty ? title : "\(title)\n\(notes)"
            item.causes = causes
            item.mastery = index.isMultiple(of: 3) ? .fuzzy : .unknown
            item.createdAt = Date().addingTimeInterval(TimeInterval(-86400 * index))
            item.handwritingRemovalSucceeded = index.isMultiple(of: 2)

            let jpeg = placeholderJPEG(label: title, index: index)
            let original = "\(item.id.uuidString)_demo_original.jpg"
            let cleaned = "\(item.id.uuidString)_demo_cleaned.jpg"
            item.originalImagePath = try MistakeImageStore.writeJPEG(jpeg, fileName: original)
            item.cleanedImagePath = try MistakeImageStore.writeJPEG(jpeg, fileName: cleaned)

            if index % 2 == 0 {
                item.tags = [tags[index % tags.count]]
            }
            context.insert(item)
            created += 1
        }

        try context.save()
        return created
    }

    static func clearDemoSamples(context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<MistakeItem>(predicate: #Predicate { $0.isDemoSample == true })
        let items = try context.fetch(descriptor)
        for item in items {
            removeStoredImages(for: item)
            context.delete(item)
        }
        try context.save()
        return items.count
    }

    private static func removeStoredImages(for item: MistakeItem) {
        for path in [item.originalImagePath, item.cleanedImagePath].compactMap({ $0 }) {
            if let url = try? MistakeImageStore.fileURL(relativePath: path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private static func placeholderJPEG(label: String, index: Int) -> Data {
        let hues: [UIColor] = [
            SnapDrillTheme.inkBlueUIColor,
            .systemTeal,
            .systemOrange,
            .systemPurple,
        ]
        let color = hues[index % hues.count]
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 420))
        let image = renderer.image { ctx in
            color.withAlphaComponent(0.15).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 320, height: 420))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraph,
            ]
            let rect = CGRect(x: 24, y: 180, width: 272, height: 80)
            (label as NSString).draw(in: rect, withAttributes: attrs)
        }
        return image.jpegData(compressionQuality: 0.85) ?? Data()
    }
}

private extension SnapDrillTheme {
    static var inkBlueUIColor: UIColor {
        UIColor(red: 0.18, green: 0.35, blue: 0.55, alpha: 1)
    }
}