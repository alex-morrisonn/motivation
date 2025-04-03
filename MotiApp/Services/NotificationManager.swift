import SwiftUI
import UserNotifications

/// Centralized manager for handling all notification-related functionality in the app
class NotificationManager: ObservableObject {
    // MARK: - Singleton and Properties
    
    /// Shared instance for app-wide access
    static let shared = NotificationManager()
    
    /// Published properties that will update the UI when changed
    @Published var isNotificationsEnabled: Bool = true
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
    private let notificationIdentifier = "com.MotiApp.dailyReminder"
    
    // User defaults keys for persistence
    private let enabledKey = "notificationsEnabled"
    private let reminderTimeKey = "reminderTime"
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        
        // Check if this is the first launch
        let defaults = UserDefaults.standard
        let isFirstLaunch = defaults.object(forKey: enabledKey) == nil
        
        if isFirstLaunch {
            // First launch - request permission automatically
            requestNotificationPermission { granted in
                // Even if permission is denied, we keep the UI toggle on
                // The user will see a permission alert when they interact with the app
                if granted {
                    self.scheduleNotification()
                }
            }
        } else {
            // Not first launch - check status
            checkNotificationStatus()
        }
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
                
                if granted {
                    self.isNotificationsEnabled = true
                    self.saveSettings()
                    if self.isNotificationsEnabled {
                        self.scheduleNotification()
                    }
                }
                
                completion(granted)
            }
        }
    }
    
    /// Check if notifications are currently enabled by the system
    func checkNotificationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral:
                    // Permissions are granted, schedule if enabled in app
                    if self.isNotificationsEnabled {
                        self.scheduleNotification()
                    }
                case .denied, .notDetermined:
                    // If permissions are denied, we keep the UI enabled but notifications won't work
                    // This encourages the user to grant permissions when interacting with the app
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    /// Toggle notifications on/off
    /// - Parameter enabled: Boolean indicating whether notifications should be enabled
    func toggleNotifications(_ enabled: Bool) {
        self.isNotificationsEnabled = enabled
        
        if enabled {
            // First check/request permission if enabled
            notificationCenter.getNotificationSettings { settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .authorized {
                        // Already authorized, just schedule
                        self.scheduleNotification()
                    } else {
                        // Need to request permission
                        self.requestNotificationPermission { granted in
                            // Even if permission denied, keep UI toggle on to encourage enabling later
                        }
                    }
                    self.saveSettings()
                }
            }
        } else {
            // If disabled, cancel scheduled notifications
            cancelNotifications()
            saveSettings()
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
