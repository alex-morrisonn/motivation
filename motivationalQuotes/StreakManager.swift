import Foundation
import SwiftUI

// Streak Manager to handle app usage streak logic
class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    // Published properties that will update the UI when changed
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastOpenDate: Date? = nil
    
    // Keys for UserDefaults
    private let lastOpenDateKey = "streak_lastOpenDate"
    private let currentStreakKey = "streak_currentStreak"
    private let longestStreakKey = "streak_longestStreak"
    private let streakDaysKey = "streak_daysRecord"
    
    // UserDefaults instance - using the shared group for widget access
    private let defaults = UserDefaults.shared
    
    // Days record to track which days the app was opened (stored as timestamps)
    private var streakDays: [TimeInterval] = []
    
    private init() {
        loadStreakData()
    }
    
    // Load saved streak data from UserDefaults
    private func loadStreakData() {
        if let lastDate = defaults.object(forKey: lastOpenDateKey) as? Date {
            lastOpenDate = lastDate
            currentStreak = defaults.integer(forKey: currentStreakKey)
            longestStreak = defaults.integer(forKey: longestStreakKey)
            
            if let savedDays = defaults.array(forKey: streakDaysKey) as? [TimeInterval] {
                streakDays = savedDays
            }
            
            // Check if we need to update since last open
            checkStreak()
        } else {
            // First app open ever - initialize with 0
            resetStreakData()
        }
    }
    
    // Save streak data to UserDefaults
    private func saveStreakData() {
        defaults.set(lastOpenDate, forKey: lastOpenDateKey)
        defaults.set(currentStreak, forKey: currentStreakKey)
        defaults.set(longestStreak, forKey: longestStreakKey)
        defaults.set(streakDays, forKey: streakDaysKey)
    }
    
    // Check and possibly update the streak counter
    private func checkStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastDate = lastOpenDate else {
            // No previous open date found, this is the first time
            currentStreak = 1
            lastOpenDate = today
            recordDay(today)
            saveStreakData()
            return
        }
        
        let lastOpenDay = calendar.startOfDay(for: lastDate)
        
        // If the app was already opened today, no streak update needed
        if calendar.isDate(today, inSameDayAs: lastOpenDay) {
            return
        }
        
        // Calculate days between last open and today
        if let daysBetween = calendar.dateComponents([.day], from: lastOpenDay, to: today).day {
            switch daysBetween {
            case 1:
                // Consecutive day - increase streak
                currentStreak += 1
                
                // Update longest streak if needed
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
                
                // Check for streak milestones
                checkForStreakMilestone()
                
                recordDay(today)
                
            case 0:
                // Same day, no change to streak
                break
                
            default:
                // More than one day passed - streak broken
                currentStreak = 1
                
                // Clear old streak days before adding today
                clearOldStreakDays()
                recordDay(today)
            }
            
            // Update last open date to today
            lastOpenDate = today
            saveStreakData()
        }
    }
    
    // Record a day in the streak days array
    private func recordDay(_ day: Date) {
        // Add the day's timestamp to the record
        streakDays.append(day.timeIntervalSince1970)
        
        // Keep only the last 366 days (for a year of history)
        if streakDays.count > 366 {
            streakDays = Array(streakDays.suffix(366))
        }
    }
    
    // Clear previous streak days when streak is broken
    private func clearOldStreakDays() {
        // Optional: We could keep the history instead of clearing it
        // For now, we're resetting when a streak breaks
        streakDays.removeAll()
    }
    
    // Public method to check in daily when app opens
    func checkInToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Only proceed if this is a new day
        if lastOpenDate == nil || !calendar.isDate(today, inSameDayAs: calendar.startOfDay(for: lastOpenDate!)) {
            checkStreak()
        }
    }
    
    // Get streak days for calendar visualization
    func getStreakDays() -> [Date] {
        return streakDays.map { Date(timeIntervalSince1970: $0) }
    }

    // Check if a specific date is part of the streak
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
    
    // Method to reset streak data (for testing or if needed)
    func resetStreakData() {
        currentStreak = 0
        longestStreak = 0
        lastOpenDate = nil
        streakDays.removeAll()
        saveStreakData()
    }
    
    // Get the current streak's start date
    func getStreakStartDate() -> Date? {
        guard currentStreak > 0, let lastDate = lastOpenDate else { return nil }
        
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: -(currentStreak - 1), to: lastDate)
    }
    
    // Check for streak milestones and send notifications
    private func checkForStreakMilestone() {
        // Define milestones to celebrate
        let milestones = [3, 7, 14, 21, 30, 50, 100, 365]
        
        // If current streak matches a milestone, show a notification
        if milestones.contains(currentStreak) {
            sendStreakMilestoneNotification(currentStreak)
        }
    }
    
    // Send a notification for reaching a streak milestone
    private func sendStreakMilestoneNotification(_ streakDays: Int) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Check notification permission
        notificationCenter.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
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
            let identifier = "com.motivationalQuotes.streakMilestone.\(streakDays)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            
            // Add the notification request
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error sending streak milestone notification: \(error.localizedDescription)")
                }
            }
        }
    }
}
