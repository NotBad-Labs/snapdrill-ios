import SwiftUI
import UIKit

enum MistakeImagePresentation {
    case cleaned
    case original
}

struct MistakeThumbnail: View {
    let item: MistakeItem
    var presentation: MistakeImagePresentation = .cleaned

    var body: some View {
        Group {
            if let image = UIImage.mistakeImage(for: item, presentation: presentation) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
        }
        .clipped()
        .accessibilityLabel(accessibilityLabel)
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            Image(systemName: "doc.text.image")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityLabel: String {
        switch presentation {
        case .cleaned:
            String(localized: "Cleaned question image")
        case .original:
            String(localized: "Original question image")
        }
    }
}

extension UIImage {
    static func mistakeImage(for item: MistakeItem, presentation: MistakeImagePresentation) -> UIImage? {
        let path: String?
        switch presentation {
        case .cleaned:
            path = item.cleanedImagePath
        case .original:
            path = item.originalImagePath
        }
        guard let path else { return nil }
        return MistakeImageStore.loadImage(relativePath: path)
    }
}