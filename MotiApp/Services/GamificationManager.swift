import Foundation

// MARK: - Achievement Definition

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: String // Stored as string for Codable; mapped to Color in views
    let requirement: Int
    let type: AchievementType
    var isUnlocked: Bool
    var unlockedAt: Date?

    enum AchievementType: String, Codable, Hashable {
        case tasksCompleted
        case perfectDays
        case totalXP
        case streak
    }
}

// MARK: - XP Award Result

struct XPAwardResult {
    let xpGained: Int
    let isPerfectDay: Bool
    let didLevelUp: Bool
    let newLevel: Int
    let newAchievements: [Achievement]
}

// MARK: - Rank Tier

struct RankTier {
    let name: String
    let icon: String
    let minLevel: Int
    let color: String

    static let all: [RankTier] = [
        RankTier(name: "Beginner", icon: "leaf.fill", minLevel: 1, color: "green"),
        RankTier(name: "Apprentice", icon: "flame", minLevel: 3, color: "orange"),
        RankTier(name: "Committed", icon: "flame.fill", minLevel: 5, color: "orange"),
        RankTier(name: "Disciplined", icon: "shield.fill", minLevel: 8, color: "blue"),
        RankTier(name: "Relentless", icon: "bolt.shield.fill", minLevel: 12, color: "purple"),
        RankTier(name: "Iron Will", icon: "crown.fill", minLevel: 17, color: "yellow"),
        RankTier(name: "Unbreakable", icon: "trophy.fill", minLevel: 23, color: "yellow"),
        RankTier(name: "Legend", icon: "star.circle.fill", minLevel: 30, color: "red"),
    ]

    static func tier(forLevel level: Int) -> RankTier {
        all.last(where: { $0.minLevel <= level }) ?? all[0]
    }

    static func nextTier(forLevel level: Int) -> RankTier? {
        all.first(where: { $0.minLevel > level })
    }
}

// MARK: - Gamification Manager

final class GamificationManager: ObservableObject {
    static let shared = GamificationManager()

    @Published private(set) var totalXP: Int = 0
    @Published private(set) var currentLevel: Int = 1
    @Published private(set) var achievements: [Achievement] = []
    @Published private(set) var totalTasksCompleted: Int = 0
    @Published private(set) var totalPerfectDays: Int = 0

    private let totalXPKey = "gamification_totalXP"
    private let currentLevelKey = "gamification_currentLevel"
    private let achievementsKey = "gamification_achievements"
    private let totalTasksCompletedKey = "gamification_totalTasksCompleted"
    private let totalPerfectDaysKey = "gamification_totalPerfectDays"
    private let defaults: UserDefaults

    // XP constants
    static let xpPerTask = 10
    static let perfectDayBonus = 20

    private init(defaults: UserDefaults = .shared) {
        self.defaults = defaults
        loadData()
        initializeAchievementsIfNeeded()
    }

    // MARK: - Level Calculations

    /// XP required to complete the given level (i.e., to go from level to level+1)
    func xpRequired(forLevel level: Int) -> Int {
        level * 100
    }

    /// Total XP needed to reach a given level from level 1
    private func cumulativeXP(toReachLevel level: Int) -> Int {
        // Sum of 1*100 + 2*100 + ... + (level-1)*100
        guard level > 1 else { return 0 }
        return (1...(level - 1)).reduce(0) { $0 + $1 * 100 }
    }

    /// XP progress within the current level
    var xpInCurrentLevel: Int {
        totalXP - cumulativeXP(toReachLevel: currentLevel)
    }

    /// XP needed to reach the next level
    var xpToNextLevel: Int {
        xpRequired(forLevel: currentLevel)
    }

    /// Progress fraction (0...1) toward next level
    var levelProgress: Double {
        guard xpToNextLevel > 0 else { return 0 }
        return min(1.0, Double(xpInCurrentLevel) / Double(xpToNextLevel))
    }

    /// Current rank based on level
    var currentRank: RankTier {
        RankTier.tier(forLevel: currentLevel)
    }

    /// Next rank to work toward (nil if at max)
    var nextRank: RankTier? {
        RankTier.nextTier(forLevel: currentLevel)
    }

    /// Levels remaining until next rank
    var levelsToNextRank: Int? {
        guard let next = nextRank else { return nil }
        return next.minLevel - currentLevel
    }

    /// XP remaining until next rank
    var xpToNextRank: Int? {
        guard let next = nextRank else { return nil }
        return cumulativeXP(toReachLevel: next.minLevel) - totalXP
    }

    // MARK: - XP Awarding

    /// Called when a single task is toggled ON. Returns nil if task was toggled off.
    func awardTaskXP(completedCount: Int, totalCount: Int, wasCompleted: Bool) -> XPAwardResult? {
        // Only award XP when completing (not un-completing)
        guard wasCompleted else { return nil }

        var xpGained = GamificationManager.xpPerTask
        totalTasksCompleted += 1

        let isPerfectDay = completedCount == totalCount
        if isPerfectDay {
            xpGained += GamificationManager.perfectDayBonus
            totalPerfectDays += 1
        }

        totalXP += xpGained

        let previousLevel = currentLevel
        recalculateLevel()
        let didLevelUp = currentLevel > previousLevel

        let newAchievements = checkAchievements()

        saveData()

        return XPAwardResult(
            xpGained: xpGained,
            isPerfectDay: isPerfectDay,
            didLevelUp: didLevelUp,
            newLevel: currentLevel,
            newAchievements: newAchievements
        )
    }

    /// Called when a task is un-completed to reverse XP
    func reverseTaskXP(wasFullyCompletedBefore: Bool) {
        totalXP = max(0, totalXP - GamificationManager.xpPerTask)
        totalTasksCompleted = max(0, totalTasksCompleted - 1)

        if wasFullyCompletedBefore {
            totalXP = max(0, totalXP - GamificationManager.perfectDayBonus)
            totalPerfectDays = max(0, totalPerfectDays - 1)
        }

        recalculateLevel()
        saveData()
    }

    func resetAllData() {
        totalXP = 0
        currentLevel = 1
        totalTasksCompleted = 0
        totalPerfectDays = 0
        achievements = []

        defaults.removeObject(forKey: totalXPKey)
        defaults.removeObject(forKey: currentLevelKey)
        defaults.removeObject(forKey: achievementsKey)
        defaults.removeObject(forKey: totalTasksCompletedKey)
        defaults.removeObject(forKey: totalPerfectDaysKey)

        initializeAchievementsIfNeeded()
    }

    // MARK: - Private

    private func recalculateLevel() {
        var level = 1
        while cumulativeXP(toReachLevel: level + 1) <= totalXP {
            level += 1
        }
        currentLevel = level
    }

    private func checkAchievements() -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }

            let met: Bool
            switch achievements[i].type {
            case .tasksCompleted:
                met = totalTasksCompleted >= achievements[i].requirement
            case .perfectDays:
                met = totalPerfectDays >= achievements[i].requirement
            case .totalXP:
                met = totalXP >= achievements[i].requirement
            case .streak:
                met = StreakManager.shared.currentStreak >= achievements[i].requirement
                    || StreakManager.shared.longestStreak >= achievements[i].requirement
            }

            if met {
                achievements[i].isUnlocked = true
                achievements[i].unlockedAt = Date()
                newlyUnlocked.append(achievements[i])
            }
        }

        if !newlyUnlocked.isEmpty {
            saveData()
        }

        return newlyUnlocked
    }

    private func initializeAchievementsIfNeeded() {
        guard achievements.isEmpty else { return }

        achievements = [
            // Task milestones
            Achievement(id: "first_task", title: "First Step", description: "Complete your first task", icon: "1.circle.fill", color: "green", requirement: 1, type: .tasksCompleted, isUnlocked: false),
            Achievement(id: "tasks_10", title: "Getting Going", description: "Complete 10 tasks", icon: "10.circle.fill", color: "blue", requirement: 10, type: .tasksCompleted, isUnlocked: false),
            Achievement(id: "tasks_50", title: "Halfway Hero", description: "Complete 50 tasks", icon: "star.fill", color: "purple", requirement: 50, type: .tasksCompleted, isUnlocked: false),
            Achievement(id: "tasks_100", title: "Centurion", description: "Complete 100 tasks", icon: "star.circle.fill", color: "orange", requirement: 100, type: .tasksCompleted, isUnlocked: false),

            // Perfect day milestones
            Achievement(id: "perfect_1", title: "Perfect Day", description: "Complete all 3 tasks in a day", icon: "checkmark.seal.fill", color: "green", requirement: 1, type: .perfectDays, isUnlocked: false),
            Achievement(id: "perfect_7", title: "Perfect Week", description: "7 perfect days", icon: "7.circle.fill", color: "blue", requirement: 7, type: .perfectDays, isUnlocked: false),
            Achievement(id: "perfect_30", title: "Perfect Month", description: "30 perfect days", icon: "30.circle.fill", color: "purple", requirement: 30, type: .perfectDays, isUnlocked: false),

            // XP milestones
            Achievement(id: "xp_500", title: "Rising", description: "Earn 500 XP", icon: "bolt.fill", color: "yellow", requirement: 500, type: .totalXP, isUnlocked: false),
            Achievement(id: "xp_1000", title: "On Fire", description: "Earn 1,000 XP", icon: "flame.fill", color: "orange", requirement: 1000, type: .totalXP, isUnlocked: false),
            Achievement(id: "xp_5000", title: "Unstoppable", description: "Earn 5,000 XP", icon: "bolt.shield.fill", color: "red", requirement: 5000, type: .totalXP, isUnlocked: false),

            // Streak milestones
            Achievement(id: "streak_3", title: "3-Day Streak", description: "3 day discipline streak", icon: "flame", color: "orange", requirement: 3, type: .streak, isUnlocked: false),
            Achievement(id: "streak_7", title: "Week Strong", description: "7 day streak", icon: "flame.fill", color: "orange", requirement: 7, type: .streak, isUnlocked: false),
            Achievement(id: "streak_30", title: "Monthly Master", description: "30 day streak", icon: "crown.fill", color: "yellow", requirement: 30, type: .streak, isUnlocked: false),
            Achievement(id: "streak_100", title: "Century Club", description: "100 day streak", icon: "trophy.fill", color: "yellow", requirement: 100, type: .streak, isUnlocked: false),
        ]

        saveData()
    }

    // MARK: - Persistence

    private func loadData() {
        totalXP = defaults.integer(forKey: totalXPKey)
        currentLevel = max(1, defaults.integer(forKey: currentLevelKey))
        totalTasksCompleted = defaults.integer(forKey: totalTasksCompletedKey)
        totalPerfectDays = defaults.integer(forKey: totalPerfectDaysKey)

        if let data = defaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }

        // Recalculate level from XP in case of inconsistency
        if totalXP > 0 {
            recalculateLevel()
        }
    }

    private func saveData() {
        defaults.set(totalXP, forKey: totalXPKey)
        defaults.set(currentLevel, forKey: currentLevelKey)
        defaults.set(totalTasksCompleted, forKey: totalTasksCompletedKey)
        defaults.set(totalPerfectDays, forKey: totalPerfectDaysKey)

        if let encoded = try? JSONEncoder().encode(achievements) {
            defaults.set(encoded, forKey: achievementsKey)
        }
    }
}
