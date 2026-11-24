import Foundation

/// Centralized runtime identifiers and compliance URLs.
/// Replace the domain URLs below before submitting to App Store Connect if hosting under a custom domain.
enum AppConfig {
    static let cloudKitContainerIdentifier = "iCloud.com.notbadlabs.snapdrill"

    static func privacyPolicyURL(for locale: Locale = .current) -> URL {
        let lang = locale.language.languageCode?.identifier ?? "en"
        let script = locale.language.script?.identifier ?? ""
        let region = locale.region?.identifier.uppercased() ?? ""

        let path: String
        if lang == "ja" {
            path = "https://snapdrill.app/ja/privacy"
        } else if lang == "ko" {
            path = "https://snapdrill.app/ko/privacy"
        } else if lang == "zh" && (script == "Hant" || region == "TW" || region == "HK" || region == "MO") {
            path = "https://snapdrill.app/zh-hant/privacy"
        } else if lang == "zh" {
            path = "https://snapdrill.app/zh-hans/privacy"
        } else {
            path = "https://snapdrill.app/privacy"
        }
        return URL(string: path)!
    }

    static func termsOfUseURL() -> URL {
        URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    }
}
