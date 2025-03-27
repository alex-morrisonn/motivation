import SwiftUI
import UserNotifications

// Notification Manager to handle all notification-related functionality
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    // Published properties that will update the UI - default to enabled
    @Published var isNotificationsEnabled: Bool = true
    @Published var reminderTime: Date = {
        // Default to 9:00 AM
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationIdentifier = "com.MotiApp.dailyReminder"
    
    init() {
        loadSettings()
        
        // Check if this is the first launch
        let defaults = UserDefaults.standard
        let isFirstLaunch = defaults.object(forKey: "notificationsEnabled") == nil
        
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
    
    // Request notification permissions from the user
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
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
    
    // Check if notifications are currently enabled
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
    
    // Toggle notifications on/off
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
    
    // Update the reminder time and reschedule if necessary
    func updateReminderTime(_ newTime: Date) {
        reminderTime = newTime
        saveSettings()
        
        if isNotificationsEnabled {
            scheduleNotification()
        }
    }
    
    // Schedule a daily notification at the user's selected time
    func scheduleNotification() {
        // Cancel any existing notifications first
        cancelNotifications()
        
        // Extract hour and minute from the selected time
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        guard let hour = components.hour, let minute = components.minute else { return }
        
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
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Cancel all scheduled notifications
    func cancelNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
    
    // Save notification settings to UserDefaults
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isNotificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(reminderTime, forKey: "reminderTime")
    }
    
    // Load notification settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "notificationsEnabled") != nil {
            isNotificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        }
        
        if let savedTime = defaults.object(forKey: "reminderTime") as? Date {
            reminderTime = savedTime
        }
    }
}
