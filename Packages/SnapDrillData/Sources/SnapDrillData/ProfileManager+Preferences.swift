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
}
