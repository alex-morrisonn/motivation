import Foundation

/// Shared App Group identifier used for communication between main app and widgets
let appGroupIdentifier = "group.com.alexmorrison.moti.shared"

/// Extension to easily access shared UserDefaults
extension UserDefaults {
    /// Shared UserDefaults that persists data between app and widget
    static var shared: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
