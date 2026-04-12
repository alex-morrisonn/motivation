import UIKit
import UserNotifications
import Firebase
import FirebaseFirestore
import FirebaseAppCheck
import FirebaseCrashlytics
import FirebaseAnalytics

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Error Types
    
    enum AppDelegateError: Error {
        case firebaseInitFailed
        case appGroupAccessFailed
        case notificationPermissionDenied
        case firebaseConfigError
        case notificationConfigError
        
        var description: String {
            switch self {
            case .firebaseInitFailed:
                return "Failed to initialize Firebase"
            case .appGroupAccessFailed:
                return "Failed to access app group for widget data sharing"
            case .notificationPermissionDenied:
                return "Notification permission denied by user"
            case .firebaseConfigError:
                return "Error configuring Firebase services"
            case .notificationConfigError:
                return "Error configuring notifications"
            }
        }
    }
    
    // MARK: - Properties
    
    // Track initialization status for various components
    private var isFirebaseInitialized = false
    private var isNotificationConfigured = false
    private var isAppGroupConfigured = false
    
    // MARK: - Application Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize core services with proper error handling
        initializeServices(application)
        
        // Initialize streak manager
        initializeStreakManager()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Update streak when app becomes active
        updateStreak()
        
        // Reset badge count using the new UNUserNotificationCenter API in iOS 17+
        resetBadgeCount()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Save any pending data changes
        saveAppState()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Save app state when entering background
        saveAppState()
    }
    
    // MARK: - Core Initialization
    
    private func initializeServices(_ application: UIApplication) {
        // Set up Firebase and security with error handling
        initializeFirebase()
        
        // Configure push notifications
        configureNotifications(application)
        
        // Configure app group for widget data sharing
        configureAppGroup()
    }
    
    // MARK: - Service Initialization
    
    private func initializeFirebase() {
        // Set up App Check before Firebase initialization
        if #available(iOS 14.0, *) {
            let providerFactory = DeviceCheckProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
            print("App Check configured successfully")
        }
        
        // Initialize Firebase
        FirebaseApp.configure()
        print("Firebase core initialized successfully")
        
        // Configure Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        print("Crashlytics configured successfully")
        
        // Configure offline persistence for Firestore
        configureFirestoreSettings()
        
        // Configure analytics - initially disabled until ATT permission is granted
        configureAnalytics()
        
        isFirebaseInitialized = true
    }
    
    private func configureFirestoreSettings() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        
        Firestore.firestore().settings = settings
        print("Firestore offline persistence configured successfully")
    }
    
    private func configureAnalytics() {
        let consentState = AnalyticsConsentState(
            rawValue: UserDefaults.standard.string(forKey: AppDefaultsKey.analyticsConsentState) ?? ""
        ) ?? .unknown
        let analyticsEnabled = consentState == .allowed

        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(analyticsEnabled)

        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            FirebaseAnalytics.Analytics.setUserProperty(version, forName: "app_version")
        }

        if analyticsEnabled {
            FirebaseAnalytics.Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        }
    }
    
    private func configureNotifications(_ application: UIApplication) {
        // Set this class as the UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check if we should reschedule notifications on app launch
        checkAndRescheduleNotifications()
        
        isNotificationConfigured = true
        print("Notification configuration completed")
    }
    
    private func configureAppGroup() {
        // Standardize app group name across app and widget extensions
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.alexmorrison.moti.shared") else {
            print("ERROR: Could not access shared app group")
            createLocalFallbackStorage()
            return
        }
        
        // Verify we can write to and read from the shared UserDefaults
        let testKey = "app_group_verification_test"
        let testValue = "test_\(Date().timeIntervalSince1970)"
        
        // Write a test value
        sharedDefaults.set(testValue, forKey: testKey)
        
        // Immediately read it back to verify
        if let verificationValue = sharedDefaults.string(forKey: testKey), verificationValue == testValue {
            // Clean up test value
            sharedDefaults.removeObject(forKey: testKey)
            print("App group access verified successfully")
            isAppGroupConfigured = true
        } else {
            print("ERROR: App group verification failed - could not read back test value")
            createLocalFallbackStorage()
        }
    }
    
    // MARK: - Badge Count Management
    
    /// Reset the application badge count using the recommended API for iOS 17+
    private func resetBadgeCount() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error resetting badge count: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Streak Management
    
    private func initializeStreakManager() {
        StreakManager.shared.checkInToday()
        print("Streak manager initialized successfully")
    }
    
    private func updateStreak() {
        StreakManager.shared.checkInToday()
    }
    
    // MARK: - App State Management
    
    private func saveAppState() {
        // Modern iOS handles UserDefaults persistence automatically
        // But we can add any custom persistence logic here if needed
        print("Saving app state")
    }
    
    // MARK: - Notifications Management
    
    private func checkAndRescheduleNotifications() {
        let defaults = UserDefaults.standard
        let notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        
        if notificationsEnabled {
            // Check if we have permission
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .authorized, .provisional:
                        // We have permission, reschedule the notification
                        print("Notification permission already granted, scheduling notifications")
                        NotificationManager.shared.scheduleNotification()
                    case .notDetermined:
                        // First time - request permission with provisional option
                        print("Notification permission not determined, requesting permission")
                        self?.requestNotificationPermission()
                    case .denied:
                        print("Notification permission previously denied by user")
                        // Store this status so the UI can reflect it accurately
                        UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                    case .ephemeral:
                        print("Notification permission is ephemeral")
                        NotificationManager.shared.scheduleNotification()
                    @unknown default:
                        print("Unknown notification authorization status")
                    }
                }
            }
        } else {
            print("Notifications disabled by user preference")
        }
    }
    
    private func requestNotificationPermission() {
        // Request with provisional option for better UX
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                    // Log the error if Firebase is initialized
                    if self?.isFirebaseInitialized == true {
                        FirebaseAnalytics.Analytics.logEvent("notification_permission_error", parameters: [
                            "error_description": error.localizedDescription
                        ])
                    }
                }
                
                if granted {
                    print("Notification permission granted successfully")
                    NotificationManager.shared.scheduleNotification()
                    // Log success if Firebase is initialized
                    if self?.isFirebaseInitialized == true {
                        FirebaseAnalytics.Analytics.logEvent("notification_permission_granted", parameters: nil)
                    }
                } else {
                    print("Notification permission denied by user")
                    // Update our stored preference to match reality
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                    // Log denial if Firebase is initialized
                    if self?.isFirebaseInitialized == true {
                        FirebaseAnalytics.Analytics.logEvent("notification_permission_denied", parameters: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Recovery
    
    private func attemptFirebaseRecovery() {
        // This could try alternative initialization methods or
        // disable Firebase features gracefully
        print("Attempting to recover from Firebase initialization failure")
        
        // At minimum, ensure crash reporting is disabled to prevent further issues
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
    }
    
    private func createLocalFallbackStorage() {
        print("Creating local fallback storage instead of app group")
        // Here we could implement a mechanism to use local storage
        // when app group storage is unavailable
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
            NotificationCenter.default.post(name: .openQuotesTab, object: nil)
            
            // Log the event if Firebase is initialized
            if isFirebaseInitialized {
                FirebaseAnalytics.Analytics.logEvent("notification_opened", parameters: ["type": "daily_reminder"])
            }
        } else if identifier.contains("streak") {
            // Open streak details
            NotificationCenter.default.post(name: .openStreakDetails, object: nil)
            
            // Log the event if Firebase is initialized
            if isFirebaseInitialized {
                FirebaseAnalytics.Analytics.logEvent("notification_opened", parameters: ["type": "streak_milestone"])
            }
        } else {
            // Default handling
            if isFirebaseInitialized {
                FirebaseAnalytics.Analytics.logEvent("notification_opened", parameters: ["type": "other", "identifier": identifier])
            }
        }
        
        completionHandler()
    }
    
    // MARK: - Helper Methods
    
    // Check if we're in a debug/development environment
    private var isDebugBuild: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
    
    // Log error to appropriate service based on severity
    private func logError(_ error: Error, critical: Bool = false) {
        let errorString = "[\(critical ? "CRITICAL" : "ERROR")]: \(error.localizedDescription)"
        
        // Always print to console
        print(errorString)
        
        // Log to system log
        NSLog(errorString)
        
        // If Firebase is initialized and this is a critical error, log to Crashlytics
        if critical && isFirebaseInitialized {
            Crashlytics.crashlytics().record(error: error)
        }
    }
}
