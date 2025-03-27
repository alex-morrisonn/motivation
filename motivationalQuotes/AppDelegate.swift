import UIKit
import UserNotifications
import Firebase
import FirebaseFirestore
import FirebaseAppCheck
import FirebaseCrashlytics
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Application Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up Firebase and security
        configureFirebase()
        
        // Configure push notifications
        configureNotifications(application)
        
        // Configure app group for widget data sharing
        configureAppGroup()
        
        // Check and update streak counter
        StreakManager.shared.checkInToday()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Update streak when app becomes active
        StreakManager.shared.checkInToday()
        
        // Reset badge count when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Modern iOS handles UserDefaults persistence automatically
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Modern iOS handles state saving automatically
    }
    
    // MARK: - Configuration Methods
    
    private func configureFirebase() {
        // Set up App Check before Firebase initialization
        if #available(iOS 14.0, *) {
            let providerFactory = DeviceCheckProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
        }
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Configure Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Configure offline persistence for Firestore
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        // Use a reasonable cache size (100MB)
        settings.cacheSizeBytes = 100 * 1024 * 1024
        Firestore.firestore().settings = settings
        
        // Configure analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Set user properties for analytics
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            Analytics.setUserProperty(version, forName: "app_version")
        }
        
        // Log app open event
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
    }
    
    private func configureAppGroup() {
        // Ensure app group access is working
        guard let _ = UserDefaults(suiteName: "group.com.alexmorrison.moti.shared") else {
            print("Warning: Could not access shared app group")
            return
        }
    }
    
    private func configureNotifications(_ application: UIApplication) {
        // Set this class as the UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check if we should reschedule notifications on app launch
        checkAndRescheduleNotifications()
    }
    
    // MARK: - Notification Methods
    
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
    
    // MARK: - Notification Delegate Methods
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow showing the notification even if the app is in the foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap - can be used to navigate to a specific part of the app
        let identifier = response.notification.request.identifier
        
        if identifier == "com.alexmorrison.moti.dailyReminder" {
            // Open the quotes tab
            NotificationCenter.default.post(name: NSNotification.Name("OpenQuotesTab"), object: nil)
            Analytics.logEvent("notification_opened", parameters: ["type": "daily_reminder"])
        } else if identifier.contains("streak") {
            // Open streak details
            NotificationCenter.default.post(name: NSNotification.Name("OpenStreakDetails"), object: nil)
            Analytics.logEvent("notification_opened", parameters: ["type": "streak_milestone"])
        } else {
            // Default handling
            Analytics.logEvent("notification_opened", parameters: ["type": "other"])
        }
        
        completionHandler()
    }
}
