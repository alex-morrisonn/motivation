import Foundation

// MARK: - Shared Constants

/// Shared App Group identifier used for communication between main app and widgets
public let appGroupIdentifier = "group.com.alexmorrison.moti.shared"

// MARK: - UserDefaults Extension

/// Extension to easily access shared UserDefaults
public extension UserDefaults {
    /// Shared UserDefaults that persists data between app and widget
    static var shared: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
