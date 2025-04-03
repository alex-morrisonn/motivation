import Foundation
import SwiftUI
import UserNotifications

/// Service responsible for managing app usage streak logic with comprehensive error handling
class StreakManager: ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance for singleton access
    static let shared = StreakManager()
    
    // MARK: - Error Types
    
    /// Error types for streak operations
    enum StreakError: Error {
        case dateCalculationFailed(String)
        case saveDataFailed(String)
        case loadDataFailed(String)
        case appGroupAccessDenied
        case invalidStreak
        case invalidDate
        case dataCorruption(String)
        
        var description: String {
            switch self {
            case .dateCalculationFailed(let details):
                return "Failed to calculate streak dates: \(details)"
            case .saveDataFailed(let details):
                return "Failed to save streak data: \(details)"
            case .loadDataFailed(let details):
                return "Failed to load streak data: \(details)"
            case .appGroupAccessDenied:
                return "Failed to access app group storage"
            case .invalidStreak:
                return "Invalid streak value"
            case .invalidDate:
                return "Invalid date value"
            case .dataCorruption(let details):
                return "Streak data corrupted: \(details)"
            }
        }
    }
    
    // MARK: - Published Properties
    
    /// Current streak count, updates UI when changed
    @Published var currentStreak: Int = 0
    
    /// Longest achieved streak
    @Published var longestStreak: Int = 0
    
    /// Last date the app was opened
    @Published var lastOpenDate: Date? = nil
    
    // MARK: - Private Properties
    
    /// Keys for UserDefaults
    private let lastOpenDateKey = "streak_lastOpenDate"
    private let currentStreakKey = "streak_currentStreak"
    private let longestStreakKey = "streak_longestStreak"
    private let streakDaysKey = "streak_daysRecord"
    private let backupSuffix = "_backup"
    
    /// UserDefaults instance - using the shared group for widget access
    private var defaults: UserDefaults
    
    /// Days record to track which days the app was opened (stored as timestamps)
    private var streakDays: [TimeInterval] = []
    
    /// Flag to track if data was corrupted on load
    private var dataWasCorrupted = false
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with UserDefaults access error handling
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = sharedDefaults
            print("Successfully connected to shared app group UserDefaults")
        } else {
            print("ERROR: Could not access shared app group, falling back to standard UserDefaults")
            self.defaults = UserDefaults.standard
        }
        
        do {
            try loadStreakData()
            
            // Validate loaded data
            if !isStreakDataValid() {
                print("Warning: Loaded streak data failed validation, attempting to repair")
                repairStreakData()
            }
        } catch let error as StreakError {
            print("Error loading streak data: \(error.description)")
            createBackup()
            resetStreakData()
        } catch {
            print("Unexpected error loading streak data: \(error.localizedDescription)")
            createBackup()
            resetStreakData()
        }
    }
    
    // MARK: - Data Management
    
    /// Load saved streak data from UserDefaults with error handling
    private func loadStreakData() throws {
        // First, check if we have backup data if regular data is corrupted
        if isDataCorrupted() && isBackupAvailable() {
            print("Primary streak data appears corrupted, attempting to restore from backup")
            try restoreFromBackup()
            return
        }
        
        // Regular loading
        if let lastDate = defaults.object(forKey: lastOpenDateKey) as? Date {
            lastOpenDate = lastDate
            currentStreak = defaults.integer(forKey: currentStreakKey)
            longestStreak = defaults.integer(forKey: longestStreakKey)
            
            if let savedDays = defaults.array(forKey: streakDaysKey) as? [TimeInterval] {
                streakDays = savedDays
            } else {
                print("Warning: No streak days found, initializing empty array")
                streakDays = []
            }
            
            // Check if we need to update since last open
            try checkStreak()
        } else {
            // First app open ever - initialize with 0
            print("No previous streak data found, initializing new streak")
            resetStreakData()
        }
    }
    
    /// Save streak data to UserDefaults with error handling
    private func saveStreakData() throws {
        // Validate data before saving
        guard currentStreak >= 0, longestStreak >= 0,
              currentStreak <= 1000, longestStreak <= 1000 else { // Reasonable upper limits
            throw StreakError.invalidStreak
        }
        
        // Create backup before saving new data
        createBackup()
        
        // Save the data
        defaults.set(lastOpenDate, forKey: lastOpenDateKey)
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(longestStreak, forKey: longestStreakKey)
        defaults.set(streakDays, forKey: streakDaysKey)
        
        // Verify data was saved correctly
        if defaults.integer(forKey: currentStreakKey) != currentStreak ||
           defaults.integer(forKey: longestStreakKey) != longestStreak {
            print("ERROR: Streak data verification failed after save")
            throw StreakError.saveDataFailed("Verification failed")
        }
        
        print("Streak data saved successfully: current=\(currentStreak), longest=\(longestStreak)")
    }
    
    // MARK: - Streak Logic
    
    /// Check and possibly update the streak counter with error handling
    private func checkStreak() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastDate = lastOpenDate else {
            // No previous open date found, this is the first time
            currentStreak = 1
            lastOpenDate = today
            recordDay(today)
            try saveStreakData()
            
            print("First app open, started new streak")
            
            // Notify observers
            NotificationCenter.default.post(name: NSNotification.Name("StreakUpdated"), object: nil)
            return
        }

        let lastOpenDay = calendar.startOfDay(for: lastDate)
        
        // If the app was already opened today, no streak update needed
        if calendar.isDate(today, inSameDayAs: lastOpenDay) {
            print("App already opened today, streak remains at \(currentStreak)")
            return
        }
        
        // Calculate days between last open and today
        guard let daysBetween = calendar.dateComponents([.day], from: lastOpenDay, to: today).day else {
            print("ERROR: Failed to calculate days between dates")
            throw StreakError.dateCalculationFailed("Could not calculate interval between dates")
        }
        
        let previousStreak = currentStreak
        
        switch daysBetween {
        case 1:
            // Consecutive day - increase streak
            currentStreak += 1
            
            // Update longest streak if needed
            if currentStreak > longestStreak {
                print("New record! Longest streak updated: \(longestStreak) → \(currentStreak)")
                longestStreak = currentStreak
            }
            
            // Check for streak milestones
            checkForStreakMilestone()
            
            print("Streak continued: \(previousStreak) → \(currentStreak)")
            recordDay(today)
            
        case 0:
            // Same day, no change to streak
            print("Same day detected, streak unchanged at \(currentStreak)")
            break
            
        default:
            // More than one day passed - streak broken
            let missedDays = daysBetween - 1
            print("Streak broken after \(currentStreak) days (missed \(missedDays) days)")
            
            currentStreak = 1
            
            // Clear old streak days before adding today
            clearOldStreakDays()
            recordDay(today)
        }
        
        // Update last open date to today
        lastOpenDate = today
        try saveStreakData()
        
        // Notify observers if streak changed
        if previousStreak != currentStreak {
            NotificationCenter.default.post(name: NSNotification.Name("StreakUpdated"), object: nil)
        }
    }
    
    /// Record a day in the streak days array with validation
    private func recordDay(_ day: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        
        // Check if this day already exists in the record to avoid duplicates
        let dayTimestamp = startOfDay.timeIntervalSince1970
        if !streakDays.contains(dayTimestamp) {
            // Add the day's timestamp to the record
            streakDays.append(dayTimestamp)
            
            // Keep only the last 366 days (for a year of history)
            if streakDays.count > 366 {
                streakDays = Array(streakDays.suffix(366))
            }
            
            print("Recorded day in streak: \(startOfDay)")
        } else {
            print("Day already recorded in streak, skipping: \(startOfDay)")
        }
    }
    
    /// Clear previous streak days when streak is broken
    private func clearOldStreakDays() {
        let previousCount = streakDays.count
        streakDays.removeAll()
        print("Cleared \(previousCount) previous streak days")
    }
    
    // MARK: - Public Methods
    
    /// Public method to check in daily when app opens with error handling
    func checkInToday() {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Only proceed if this is a new day
            if lastOpenDate == nil || !calendar.isDate(today, inSameDayAs: calendar.startOfDay(for: lastOpenDate!)) {
                try checkStreak()
            } else {
                print("Check-in: Already checked in today")
            }
        } catch {
            print("Error checking in today: \(error.localizedDescription)")
            // If there's an error during check-in, we'll still count it as a visit
            // to avoid penalizing the user for technical issues
            ensureTodayIsRecorded()
        }
    }
    
    /// Get streak days for calendar visualization
    func getStreakDays() -> [Date] {
        return streakDays.map { Date(timeIntervalSince1970: $0) }
    }

    /// Check if a specific date is part of the streak
    func isDateInStreak(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // If we don't have any streak days or the date is in the future, it's not part of streak
        if streakDays.isEmpty || startOfDay > calendar.startOfDay(for: Date()) {
            return false
        }
        
        // Check if this exact date is in our streak records
        return streakDays.contains(where: { dayTimestamp in
            let streakDay = Date(timeIntervalSince1970: dayTimestamp)
            return calendar.isDate(startOfDay, inSameDayAs: streakDay)
        })
    }
    
    /// Method to reset streak data (for testing or if needed)
    func resetStreakData() {
        print("Resetting streak data")
        currentStreak = 0
        longestStreak = 0
        lastOpenDate = nil
        streakDays.removeAll()
        
        do {
            try saveStreakData()
        } catch {
            print("Error saving reset streak data: \(error.localizedDescription)")
        }
    }
    
    /// Get the current streak's start date with error handling
    func getStreakStartDate() -> Date? {
        guard currentStreak > 0, let lastDate = lastOpenDate else {
            return nil
        }
        
        let calendar = Calendar.current
        // Calculate streak start date
        guard let startDate = calendar.date(byAdding: .day, value: -(currentStreak - 1), to: lastDate) else {
            print("Warning: Could not calculate streak start date")
            return nil
        }
        return startDate
    }
    
    // MARK: - Error Recovery
    
    /// Check if data appears to be corrupted
    private func isDataCorrupted() -> Bool {
        // Check for inconsistent streak values
        if currentStreak < 0 || longestStreak < 0 ||
           currentStreak > 1000 || longestStreak > 1000 {
            return true
        }
        
        // Check if longest streak is less than current streak
        if longestStreak < currentStreak && currentStreak > 0 {
            return true
        }
        
        // Check if last open date is in the future
        if let lastDate = lastOpenDate,
           lastDate > Date().addingTimeInterval(60*60) { // Allow for slight clock differences (1 hour)
            return true
        }
        
        return false
    }
    
    /// Validate that streak data makes sense
    private func isStreakDataValid() -> Bool {
        // Check streak values are consistent
        if currentStreak < 0 || longestStreak < 0 {
            return false
        }
        
        if longestStreak < currentStreak {
            return false
        }
        
        // Check streak days array makes sense for current streak
        if currentStreak > 0 && streakDays.isEmpty {
            return false
        }
        
        return true
    }
    
    /// Attempt to repair corrupted streak data
    private func repairStreakData() {
        print("Attempting to repair streak data")
        
        // Fix longest streak if it's less than current streak
        if longestStreak < currentStreak && currentStreak > 0 {
            print("Fixing longest streak: \(longestStreak) → \(currentStreak)")
            longestStreak = currentStreak
        }
        
        // Fix negative values
        if currentStreak < 0 {
            print("Fixing negative current streak: \(currentStreak) → 0")
            currentStreak = 0
        }
        
        if longestStreak < 0 {
            print("Fixing negative longest streak: \(longestStreak) → 0")
            longestStreak = 0
        }
        
        // Fix future dates
        if let lastDate = lastOpenDate, lastDate > Date() {
            print("Fixing future last open date")
            lastOpenDate = Date()
        }
        
        // If streak is positive but no days recorded, add today
        if currentStreak > 0 && streakDays.isEmpty {
            print("Adding today to empty streak days array")
            recordDay(Date())
        }
        
        // Save repaired data
        do {
            try saveStreakData()
            print("Streak data repaired successfully")
        } catch {
            print("Failed to save repaired streak data: \(error.localizedDescription)")
        }
    }
    
    /// Ensure today is recorded in the streak (for error recovery)
    private func ensureTodayIsRecorded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if !isDateInStreak(today) {
            print("Ensuring today is recorded in streak despite errors")
            recordDay(today)
            
            // If there was no streak, start one
            if currentStreak <= 0 {
                currentStreak = 1
                print("Starting new streak due to error recovery")
            }
            
            lastOpenDate = today
            
            // Save changes
            do {
                try saveStreakData()
            } catch {
                print("Failed to save recovery streak data: \(error.localizedDescription)")
            }
        }
    }
    
    /// Create backup of streak data
    private func createBackup() {
        // Only backup if we have valid data
        if lastOpenDate != nil {
            defaults.set(lastOpenDate, forKey: lastOpenDateKey + backupSuffix)
            defaults.set(currentStreak, forKey: currentStreakKey + backupSuffix)
            defaults.set(longestStreak, forKey: longestStreakKey + backupSuffix)
            defaults.set(streakDays, forKey: streakDaysKey + backupSuffix)
            
            // Add timestamp of backup
            defaults.set(Date(), forKey: "streak_backup_timestamp")
            
            print("Streak data backup created")
        }
    }
    
    /// Check if backup is available
    private func isBackupAvailable() -> Bool {
        return defaults.object(forKey: lastOpenDateKey + backupSuffix) != nil
    }
    
    /// Restore from backup
    private func restoreFromBackup() throws {
        guard isBackupAvailable() else {
            throw StreakError.dataCorruption("No backup available to restore from")
        }
        
        if let backupDate = defaults.object(forKey: lastOpenDateKey + backupSuffix) as? Date {
            lastOpenDate = backupDate
            currentStreak = defaults.integer(forKey: currentStreakKey + backupSuffix)
            longestStreak = defaults.integer(forKey: longestStreakKey + backupSuffix)
            
            if let backupDays = defaults.array(forKey: streakDaysKey + backupSuffix) as? [TimeInterval] {
                streakDays = backupDays
            } else {
                streakDays = []
            }
            
            print("Streak data restored from backup: current=\(currentStreak), longest=\(longestStreak)")
            
            // Mark that data was corrupted
            dataWasCorrupted = true
            
            // After successful restore, update the data
            try checkStreak()
        } else {
            throw StreakError.dataCorruption("Backup restoration failed")
        }
    }
    
    // MARK: - Notifications
    
    /// Check for streak milestones and send notifications
    private func checkForStreakMilestone() {
        // Define milestones to celebrate
        let milestones = [3, 7, 14, 21, 30, 50, 100, 365]
        
        // If current streak matches a milestone, show a notification
        if milestones.contains(currentStreak) {
            sendStreakMilestoneNotification(currentStreak)
        }
    }
    
    /// Send a notification for reaching a streak milestone with error handling
    private func sendStreakMilestoneNotification(_ streakDays: Int) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Check notification permission
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("Skipping streak notification - no permission")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Streak Milestone Reached! 🔥"
            
            // Customize message based on streak length
            if streakDays < 10 {
                content.body = "Amazing! You've used Moti for \(streakDays) days in a row. Keep going!"
            } else if streakDays < 30 {
                content.body = "Incredible discipline! Your \(streakDays)-day streak shows your commitment to growth."
            } else if streakDays < 100 {
                content.body = "You're unstoppable! \(streakDays) consecutive days of motivation and inspiration."
            } else {
                content.body = "WOW! \(streakDays) DAYS! You're in the elite club of dedicated Moti users!"
            }
            
            content.sound = UNNotificationSound.default
            
            // Create the request
            let identifier = "com.moti.streakMilestone.\(streakDays)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            
            // Add the notification request with error handling
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error sending streak milestone notification: \(error.localizedDescription)")
                } else {
                    print("Streak milestone notification sent for \(streakDays) days")
                }
            }
        }
    }
    
    // MARK: - Debugging
    
    /// Diagnostic method to print streak status (for debugging)
    func printStreakDiagnostics() {
        print("=== STREAK DIAGNOSTICS ===")
        print("Current streak: \(currentStreak)")
        print("Longest streak: \(longestStreak)")
        print("Last open date: \(String(describing: lastOpenDate))")
        print("Days recorded: \(streakDays.count)")
        print("Data was corrupted: \(dataWasCorrupted)")
        print("Backup available: \(isBackupAvailable())")
        
        let calendar = Calendar.current
        if let lastDate = lastOpenDate {
            print("Days since last open: \(calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: Date())).day ?? 0)")
        }
        
        print("=========================")
    }
}
