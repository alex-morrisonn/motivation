import UIKit
import UserNotifications
import Firebase
import FirebaseFirestore
import FirebaseAppCheck
import FirebaseCrashlytics
import FirebaseAnalytics
import AppTrackingTransparency // Added for privacy compliance

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // MARK: - Error Types
    
    enum AppDelegateError: Error {
        case firebaseInitFailed
        case appGroupAccessFailed
        case notificationPermissionDenied
        case trackingPermissionDenied
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
            case .trackingPermissionDenied:
                return "Tracking permission denied by user"
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
        // Set up Firebase and security with error handling
        do {
            try configureFirebase()
            isFirebaseInitialized = true
        } catch {
            print("ERROR: Firebase initialization failed: \(error.localizedDescription)")
            // Continue app initialization despite Firebase failure
            // Log the error to the system for debugging
            NSLog("Firebase initialization error: \(error.localizedDescription)")
        }
        
        // Configure push notifications with error handling
        do {
            try configureNotifications(application)
            isNotificationConfigured = true
        } catch {
            print("WARNING: Notification configuration failed: \(error.localizedDescription)")
            // Continue app initialization despite notification failure
        }
        
        // Configure app group for widget data sharing with error handling
        do {
            try configureAppGroup()
            isAppGroupConfigured = true
        } catch {
            print("WARNING: App group configuration failed: \(error.localizedDescription)")
            // Continue app initialization despite app group failure
        }
        
        // Check and update streak counter with error handling
        do {
            StreakManager.shared.checkInToday()
        } catch {
            print("WARNING: Streak check-in failed: \(error.localizedDescription)")
            // This is non-critical, app can continue
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Update streak when app becomes active with error handling
        do {
            StreakManager.shared.checkInToday()
        } catch {
            print("WARNING: Streak update failed when app became active: \(error.localizedDescription)")
            // Non-critical failure, continue
        }
        
        // Reset badge count when app becomes active
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Request tracking authorization with delay to avoid interfering with app launch UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.requestTrackingAuthorization()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Ensure any unsaved data is persisted
        do {
            // No explicit action needed as Modern iOS handles UserDefaults persistence automatically
            // But we can add any custom persistence logic here if needed
            print("Application will terminate - ensuring data is saved")
        } catch {
            print("ERROR: Failed to save app state on termination: \(error.localizedDescription)")
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Ensure data is saved when app enters background
        do {
            print("Application entered background - ensuring data is saved")
            // Modern iOS handles state saving automatically
            // But we can add any custom state saving logic here if needed
        } catch {
            print("ERROR: Failed to save app state on background: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Privacy and Tracking
    
    private func requestTrackingAuthorization() {
        if #available(iOS 14.0, *) {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                // Update analytics collection based on authorization status
                let isEnabled = status == .authorized
                DispatchQueue.main.async {
                    do {
                        Analytics.setAnalyticsCollectionEnabled(isEnabled)
                        print("App Tracking Transparency status: \(status.rawValue)")
                        
                        if isEnabled {
                            print("User allowed tracking - analytics enabled")
                        } else {
                            print("User denied tracking or status is not determined - limited analytics only")
                        }
                        
                        // Log the tracking status if Firebase is initialized
                        if self?.isFirebaseInitialized == true {
                            Analytics.logEvent("tracking_status", parameters: ["status": status.rawValue])
                        }
                    } catch {
                        print("ERROR: Failed to update analytics collection status: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // For iOS versions below 14, enable analytics by default
            Analytics.setAnalyticsCollectionEnabled(true)
        }
    }
    
    // MARK: - Configuration Methods
    
    private func configureFirebase() throws {
        do {
            // Set up App Check before Firebase initialization
            if #available(iOS 14.0, *) {
                do {
                    let providerFactory = DeviceCheckProviderFactory()
                    AppCheck.setAppCheckProviderFactory(providerFactory)
                    print("App Check configured successfully")
                } catch {
                    print("WARNING: Failed to configure App Check: \(error.localizedDescription)")
                    // Continue Firebase initialization despite App Check failure
                }
            }
            
            // Initialize Firebase with error handling
            FirebaseApp.configure()
            print("Firebase core initialized successfully")
            
            // Configure Crashlytics
            do {
                Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
                print("Crashlytics configured successfully")
            } catch {
                print("WARNING: Failed to configure Crashlytics: \(error.localizedDescription)")
                // Continue despite Crashlytics configuration failure
            }
            
            // Configure offline persistence for Firestore
            do {
                let settings = FirestoreSettings()
                settings.isPersistenceEnabled = true
                // Use a reasonable cache size (100MB)
                settings.cacheSizeBytes = 100 * 1024 * 1024
                Firestore.firestore().settings = settings
                print("Firestore offline persistence configured successfully")
            } catch {
                print("WARNING: Failed to configure Firestore settings: \(error.localizedDescription)")
                // Continue despite Firestore settings failure
            }
            
            // Configure analytics - initially disabled until ATT permission is granted
            do {
                Analytics.setAnalyticsCollectionEnabled(false)
                
                // Set user properties for analytics
                if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                    Analytics.setUserProperty(version, forName: "app_version")
                } else {
                    print("WARNING: Could not retrieve app version for analytics")
                }
                
                // Log app open event
                Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
                print("Analytics initially configured (disabled until permission)")
            } catch {
                print("WARNING: Failed to configure Analytics: \(error.localizedDescription)")
                // Continue despite Analytics configuration failure
            }
        } catch {
            print("CRITICAL ERROR: Firebase configuration failed: \(error.localizedDescription)")
            
            // Record error for diagnostics
            if let nsError = error as NSError? {
                NSLog("Firebase configuration error: \(nsError.domain), code: \(nsError.code), description: \(nsError.localizedDescription)")
            }
            
            throw AppDelegateError.firebaseInitFailed
        }
    }
    
    private func configureAppGroup() throws {
        do {
            // Standardize app group name across app and widget extensions
            guard let sharedDefaults = UserDefaults(suiteName: "group.com.alexmorrison.moti.shared") else {
                print("ERROR: Could not access shared app group")
                throw AppDelegateError.appGroupAccessFailed
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
            } else {
                print("ERROR: App group verification failed - could not read back test value")
                throw AppDelegateError.appGroupAccessFailed
            }
        } catch {
            print("ERROR: App group configuration failed: \(error.localizedDescription)")
            throw AppDelegateError.appGroupAccessFailed
        }
    }
    
    private func configureNotifications(_ application: UIApplication) throws {
        do {
            // Set this class as the UNUserNotificationCenter delegate
            UNUserNotificationCenter.current().delegate = self
            
            // Check if we should reschedule notifications on app launch
            checkAndRescheduleNotifications()
            print("Notification configuration completed successfully")
        } catch {
            print("ERROR: Notification configuration failed: \(error.localizedDescription)")
            throw AppDelegateError.notificationConfigError
        }
    }
    
    // MARK: - Notification Methods
    
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
                        Analytics.logEvent("notification_permission_error", parameters: [
                            "error_description": error.localizedDescription
                        ])
                    }
                }
                
                if granted {
                    print("Notification permission granted successfully")
                    NotificationManager.shared.scheduleNotification()
                    // Log success if Firebase is initialized
                    if self?.isFirebaseInitialized == true {
                        Analytics.logEvent("notification_permission_granted", parameters: nil)
                    }
                } else {
                    print("Notification permission denied by user")
                    // Update our stored preference to match reality
                    UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                    // Log denial if Firebase is initialized
                    if self?.isFirebaseInitialized == true {
                        Analytics.logEvent("notification_permission_denied", parameters: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Error Recovery Methods
    
    // Attempt to recover from Firebase initialization failure
    private func attemptFirebaseRecovery() {
        // This could try alternative initialization methods or
        // disable Firebase features gracefully
        print("Attempting to recover from Firebase initialization failure")
        
        // At minimum, ensure crash reporting is disabled to prevent further issues
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
    }
    
    // Attempt to recover from app group access failure
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
        
        do {
            if identifier == "com.alexmorrison.moti.dailyReminder" {
                // Open the quotes tab
                NotificationCenter.default.post(name: NSNotification.Name("OpenQuotesTab"), object: nil)
                
                // Log the event if Firebase is initialized
                if isFirebaseInitialized {
                    Analytics.logEvent("notification_opened", parameters: ["type": "daily_reminder"])
                }
            } else if identifier.contains("streak") {
                // Open streak details
                NotificationCenter.default.post(name: NSNotification.Name("OpenStreakDetails"), object: nil)
                
                // Log the event if Firebase is initialized
                if isFirebaseInitialized {
                    Analytics.logEvent("notification_opened", parameters: ["type": "streak_milestone"])
                }
            } else {
                // Default handling
                if isFirebaseInitialized {
                    Analytics.logEvent("notification_opened", parameters: ["type": "other", "identifier": identifier])
                }
            }
        } catch {
            print("Error handling notification response: \(error.localizedDescription)")
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
