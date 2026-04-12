import SwiftUI
import UserNotifications

/// Centralized manager for handling all notification-related functionality in the app
class NotificationManager: ObservableObject {
    // MARK: - Singleton and Properties
    
    /// Shared instance for app-wide access
    static let shared = NotificationManager()
    
    /// Published properties that will update the UI when changed
    @Published private(set) var isNotificationsEnabled: Bool = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var reminderTime: Date = {
        // Default to 9:00 AM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// Error types for notification operations
    enum NotificationError: Error {
        case permissionDenied
        case schedulingFailed(String)
        case badTimeFormat
        case notificationCenterUnavailable
        
        var localizedDescription: String {
            switch self {
            case .permissionDenied:
                return "Notification permission was denied by the user"
            case .schedulingFailed(let reason):
                return "Failed to schedule notification: \(reason)"
            case .badTimeFormat:
                return "Invalid time format for notification"
            case .notificationCenterUnavailable:
                return "Notification center is unavailable"
            }
        }
    }
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifier = "com.alexmorrison.moti.dailyReminder"
    
    // User defaults keys for persistence
    private let enabledKey = "notificationsEnabled"
    private let reminderTimeKey = "reminderTime"
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        checkNotificationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Request notification permissions from the user
    /// - Parameter completion: Callback with boolean indicating if permission was granted
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                }

                self.authorizationStatus = granted ? .authorized : .denied
                self.isNotificationsEnabled = granted
                self.saveSettings()

                if granted {
                    self.scheduleNotification()
                } else {
                    self.cancelNotifications()
                }

                completion(granted)
            }
        }
    }
    
    /// Check if notifications are currently enabled by the system
    func checkNotificationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus

                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    if self.isNotificationsEnabled {
                        self.scheduleNotification()
                    }
                case .denied, .notDetermined:
                    self.isNotificationsEnabled = false
                    self.cancelNotifications()
                @unknown default:
                    self.isNotificationsEnabled = false
                    self.cancelNotifications()
                }
            }
        }
    }
    
    /// Toggle notifications on/off
    /// - Parameter enabled: Boolean indicating whether notifications should be enabled
    func toggleNotifications(_ enabled: Bool) {
        guard enabled else {
            self.isNotificationsEnabled = false
            cancelNotifications()
            saveSettings()
            return
        }

        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus

                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    self.isNotificationsEnabled = true
                    self.saveSettings()
                    self.scheduleNotification()
                case .notDetermined:
                    self.requestNotificationPermission { _ in }
                case .denied:
                    self.isNotificationsEnabled = false
                    self.cancelNotifications()
                    self.saveSettings()
                @unknown default:
                    self.isNotificationsEnabled = false
                    self.cancelNotifications()
                    self.saveSettings()
                }
            }
        }
    }
    
    /// Update the reminder time and reschedule if necessary
    /// - Parameter newTime: The new time for daily reminders
    func updateReminderTime(_ newTime: Date) {
        reminderTime = newTime
        saveSettings()
        
        if isNotificationsEnabled {
            scheduleNotification()
        }
    }
    
    /// Schedule a daily notification at the user's selected time
    @discardableResult
    func scheduleNotification() -> Bool {
        // Cancel any existing notifications first
        cancelNotifications()
        
        // Extract hour and minute from the selected time
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        guard let hour = components.hour, let minute = components.minute else {
            print("Error: Failed to extract hour/minute from reminder time")
            return false
        }
        
        // Create date components for a repeating daily notification
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Get today's quote to include in the notification
        let quote = QuoteService.shared.getTodaysQuote()
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Your Daily Motivation"
        content.body = "\"\(quote.text)\" — \(quote.author)"
        content.sound = UNNotificationSound.default
        
        // Create the trigger using the time components (repeating daily)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create the request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Add the notification request to the notification center
        var schedulingSuccess = true
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
                schedulingSuccess = false
            }
        }
        
        return schedulingSuccess
    }
    
    /// Cancel all scheduled notifications
    func cancelNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
    
    // MARK: - Private Methods
    
    /// Save notification settings to UserDefaults
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isNotificationsEnabled, forKey: enabledKey)
        defaults.set(reminderTime, forKey: reminderTimeKey)
    }
    
    /// Load notification settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Load notification enabled state
        if defaults.object(forKey: enabledKey) != nil {
            isNotificationsEnabled = defaults.bool(forKey: enabledKey)
        }
        
        // Load reminder time with validation
        if let savedTime = defaults.object(forKey: reminderTimeKey) as? Date {
            reminderTime = savedTime
        } else {
            // Set default time (9:00 AM) if no saved time exists
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            if let defaultTime = Calendar.current.date(from: components) {
                reminderTime = defaultTime
            }
        }
    }
    
    /// Gets a formatted string representation of the reminder time
    func getReminderTimeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: reminderTime)
    }

    var remindersStatusText: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return isNotificationsEnabled ? "On at \(getReminderTimeFormatted())" : "Off"
        case .notDetermined:
            return "Off"
        case .denied:
            return "Off in Settings"
        @unknown default:
            return "Unavailable"
        }
    }

    var remindersDetailText: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return isNotificationsEnabled ? "Daily reminder scheduled." : "Enable reminders when you want a daily prompt."
        case .notDetermined:
            return "Enable reminders when you want a daily prompt."
        case .denied:
            return "Notifications are blocked at the system level."
        @unknown default:
            return "Notification status could not be determined."
        }
    }
}

// MARK: - Extensions

// Extension to add UI helpers
extension NotificationManager {
    /// Creates an alert for requesting notification permission
    func createPermissionAlert(onSettings: @escaping () -> Void, onCancel: @escaping () -> Void) -> Alert {
        return Alert(
            title: Text("Notification Permission"),
            message: Text("To receive daily quote reminders, you need to allow notifications in Settings."),
            primaryButton: .default(Text("Settings"), action: onSettings),
            secondaryButton: .cancel(Text("Cancel"), action: onCancel)
        )
    }
}
