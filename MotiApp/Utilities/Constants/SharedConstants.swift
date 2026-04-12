import Foundation

// MARK: - Shared Constants

/// Shared App Group identifier used for communication between main app and widgets
public let appGroupIdentifier = "group.com.alexmorrison.moti.shared"

enum AppDefaultsKey {
    static let analyticsConsentState = "analyticsConsentState"
    static let shouldPromptAnalyticsConsent = "shouldPromptAnalyticsConsent"
    static let analyticsConsentEligibleOpenCount = "analyticsConsentEligibleOpenCount"
}

enum AppMetadata {
    static let name = "Motii"
    static let supportEmail = "motii.team@gmail.com"
    static let deepLinkScheme = "moti"
    static let websiteBaseURL = URL(string: "https://alex-morrisonn.github.io/motivation")!
    static let supportURL = websiteBaseURL.appending(path: "support")
    static let privacyPolicyURL = websiteBaseURL.appending(path: "privacy-policy")
    static let termsOfServiceURL = websiteBaseURL.appending(path: "terms-of-service")
    static let appStoreShareText = "Check out Motii, the daily motivation app I use for quotes, reminders, and streaks."
    static let copyrightNotice = "© 2026 Motii Team"
    static let legalLastUpdated = "January 1, 2026"

    static var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

enum AnalyticsConsentState: String {
    case unknown
    case allowed
    case declined
}

enum AppNotification {
    static let selectedTabUserInfoKey = "selectedTab"
    static let quoteTaskTitleUserInfoKey = "quoteTaskTitle"
    static let plannerDateUserInfoKey = "plannerDate"
    static let plannerTitleUserInfoKey = "plannerTitle"
    static let plannerNotesUserInfoKey = "plannerNotes"
    static let plannerIconUserInfoKey = "plannerIcon"
    static let plannerTintHexUserInfoKey = "plannerTintHex"
    static let plannerAllDayUserInfoKey = "plannerAllDay"
}

// MARK: - UserDefaults Extension

/// Extension to easily access shared UserDefaults
public extension UserDefaults {
    /// Shared UserDefaults that persists data between app and widget
    static var shared: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("DeepLinkReceived")
    static let openQuotesTab = Notification.Name("OpenQuotesTab")
    static let openStreakDetails = Notification.Name("OpenStreakDetails")
    static let openPlannerComposer = Notification.Name("OpenPlannerComposer")
    static let quoteAppliedToToday = Notification.Name("QuoteAppliedToToday")
    static let premiumStatusChanged = Notification.Name("PremiumStatusChanged")
    static let showPremiumView = Notification.Name("ShowPremiumView")
    static let streakUpdated = Notification.Name("StreakUpdated")
    static let tabSelectionChanged = Notification.Name("TabSelectionChanged")
    static let themeChanged = Notification.Name("ThemeChanged")
    static let weeklyQuestCompleted = Notification.Name("WeeklyQuestCompleted")
}

// MARK: - Formatters

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let eventTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    static let disciplineDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    static let dayStorageKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
