import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set this class as the UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check if we should reschedule notifications on app launch
        checkAndRescheduleNotifications()
        
        return true
    }
    
    // This method will be called when a notification is received while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow showing the notification even if the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // This method will be called when a user taps on a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap - can be used to navigate to a specific part of the app
        
        // Get the notification identifier
        let identifier = response.notification.request.identifier
        
        // If it's our daily quote notification, we could open the app to the quotes tab
        if identifier == "com.motivationalQuotes.dailyReminder" {
            // Note: We'll need to implement this navigation logic in the ContentView
            // using a NotificationCenter post or other state management
            NotificationCenter.default.post(name: NSNotification.Name("OpenQuotesTab"), object: nil)
        }
        
        completionHandler()
    }
    
    // Helper method to check if we should reschedule notifications on app launch
    private func checkAndRescheduleNotifications() {
        let defaults = UserDefaults.standard
        let notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        
        if notificationsEnabled {
            // Check if we have permission
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.authorizationStatus == .authorized {
                    // We have permission, reschedule the notification
                    DispatchQueue.main.async {
                        NotificationManager.shared.scheduleNotification()
                    }
                }
            }
        }
    }
}
