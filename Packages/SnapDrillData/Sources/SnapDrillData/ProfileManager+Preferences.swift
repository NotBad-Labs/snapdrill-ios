import Foundation

extension ProfileManager {
    static func clearPerProfileValues(in defaults: UserDefaults) {
        for key in Self.perProfileKeys {
            defaults.removeObject(forKey: key)
        }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(CategoryDimensionModel.visibilityKeyPrefix) {
            defaults.removeObject(forKey: key)
        }
    }

    /// 过滤出可安全交给 JSONSerialization 的偏好值。
    ///
    /// per-profile 偏好可能含非 JSON 类型值（如 `captureDraftMetadata` 是 `JSONEncoder` 编码的 `Data`）。
    /// `JSONSerialization` 遇 `Data` / `Date` 会抛 `NSInvalidArgumentException`——ObjC 异常无法被
    /// Swift `do/catch` 捕获，会直接进程闪退（带未保存草稿切换 Profile 时必崩）。
    /// 逐值校验，只保留 JSON 合法值；返回被剔除的键供调用方记日志。
    static func jsonSafePreferences(_ dict: [String: Any]) -> (safe: [String: Any], dropped: [String]) {
        var safe: [String: Any] = [:]
        var dropped: [String] = []
        for (key, value) in dict {
            if JSONSerialization.isValidJSONObject([key: value]) {
                safe[key] = value
            } else {
                dropped.append(key)
            }
        }
        return (safe, dropped)
    }
}
