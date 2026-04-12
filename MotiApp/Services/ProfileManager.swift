import Foundation

enum MotivationFocus: String, CaseIterable, Codable, Identifiable {
    case discipline
    case confidence
    case focus
    case consistency
    case reset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .discipline:
            return "Discipline"
        case .confidence:
            return "Confidence"
        case .focus:
            return "Focus"
        case .consistency:
            return "Consistency"
        case .reset:
            return "Reset"
        }
    }

    var subtitle: String {
        switch self {
        case .discipline:
            return "Build a stronger standard for your day."
        case .confidence:
            return "Stack small wins that make action easier."
        case .focus:
            return "Protect attention and finish meaningful work."
        case .consistency:
            return "Stay steady even when motivation drops."
        case .reset:
            return "Lower friction and get back on track."
        }
    }

    var recommendedCategory: DisciplineCategory {
        switch self {
        case .discipline, .focus:
            return .focus
        case .confidence:
            return .body
        case .consistency, .reset:
            return .mind
        }
    }

    var defaultTaskOptionID: String {
        switch self {
        case .discipline:
            return "focus_priority"
        case .confidence:
            return "body_workout"
        case .focus:
            return "focus_deep_work"
        case .consistency:
            return "mind_journal"
        case .reset:
            return "mind_meditate"
        }
    }
}

enum SevenDayGoal: Int, CaseIterable, Codable, Identifiable {
    case steady = 4
    case strong = 5
    case lockedIn = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .steady:
            return "4 days"
        case .strong:
            return "5 days"
        case .lockedIn:
            return "6 days"
        }
    }

    var subtitle: String {
        switch self {
        case .steady:
            return "Solid baseline without overcommitting."
        case .strong:
            return "Good pressure with room for one miss."
        case .lockedIn:
            return "Aggressive target for a serious week."
        }
    }
}

final class ProfileManager: ObservableObject {
    static let shared = ProfileManager()

    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var focus: MotivationFocus
    @Published private(set) var preferredStartHour: Int
    @Published private(set) var sevenDayGoal: SevenDayGoal

    private let defaults: UserDefaults
    private let hasCompletedOnboardingKey = "profile_hasCompletedOnboarding"
    private let focusKey = "profile_focus"
    private let preferredStartHourKey = "profile_preferredStartHour"
    private let sevenDayGoalKey = "profile_sevenDayGoal"

    private init(defaults: UserDefaults = .shared) {
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: hasCompletedOnboardingKey)
        self.focus = MotivationFocus(rawValue: defaults.string(forKey: focusKey) ?? "") ?? .discipline

        let storedStartHour = defaults.integer(forKey: preferredStartHourKey)
        self.preferredStartHour = (6...22).contains(storedStartHour) ? storedStartHour : 8

        let storedGoal = defaults.integer(forKey: sevenDayGoalKey)
        self.sevenDayGoal = SevenDayGoal(rawValue: storedGoal) ?? .strong
    }

    var welcomeTitle: String {
        switch focus {
        case .discipline:
            return "Build your standard"
        case .confidence:
            return "Stack visible wins"
        case .focus:
            return "Protect your attention"
        case .consistency:
            return "Keep the streak alive"
        case .reset:
            return "Regain control"
        }
    }

    var reminderDate: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = preferredStartHour
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    var todayPrompt: String {
        switch focus {
        case .discipline:
            return "The goal is not intensity. It is keeping promises."
        case .confidence:
            return "Make today feel winnable, then finish the win."
        case .focus:
            return "One protected block is worth more than scattered effort."
        case .consistency:
            return "Two completed tasks is momentum. Three is a statement."
        case .reset:
            return "Shrink the task until you can start cleanly."
        }
    }

    var suggestedSelections: [DisciplineCategory: String] {
        switch focus {
        case .discipline:
            return [.mind: "mind_read", .body: "body_workout", .focus: "focus_priority"]
        case .confidence:
            return [.mind: "mind_journal", .body: "body_workout", .focus: "focus_priority"]
        case .focus:
            return [.mind: "mind_meditate", .body: "body_walk", .focus: "focus_deep_work"]
        case .consistency:
            return [.mind: "mind_journal", .body: "body_walk", .focus: "focus_tidy"]
        case .reset:
            return [.mind: "mind_meditate", .body: "body_stretch", .focus: "focus_tidy"]
        }
    }

    func completeOnboarding(
        focus: MotivationFocus,
        preferredStartHour: Int,
        sevenDayGoal: SevenDayGoal
    ) {
        self.focus = focus
        self.preferredStartHour = preferredStartHour
        self.sevenDayGoal = sevenDayGoal
        hasCompletedOnboarding = true

        defaults.set(true, forKey: hasCompletedOnboardingKey)
        defaults.set(focus.rawValue, forKey: focusKey)
        defaults.set(preferredStartHour, forKey: preferredStartHourKey)
        defaults.set(sevenDayGoal.rawValue, forKey: sevenDayGoalKey)
        defaults.set(true, forKey: AppDefaultsKey.shouldPromptAnalyticsConsent)
    }

    func updateProfile(
        focus: MotivationFocus,
        preferredStartHour: Int,
        sevenDayGoal: SevenDayGoal
    ) {
        self.focus = focus
        self.preferredStartHour = preferredStartHour
        self.sevenDayGoal = sevenDayGoal

        defaults.set(focus.rawValue, forKey: focusKey)
        defaults.set(preferredStartHour, forKey: preferredStartHourKey)
        defaults.set(sevenDayGoal.rawValue, forKey: sevenDayGoalKey)
    }
}
