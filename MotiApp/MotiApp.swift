import SwiftUI
import Firebase
import FirebaseAnalytics  // Explicit import added

@main
struct MotiApp: App {
    // Register the app delegate for the UIApplication
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Setup shared instances
    @StateObject private var notificationManager = NotificationManager.shared
    
    // Initialize ad services during app launch
    init() {
        // Configure initial appearance settings
        configureAppearance()
        
        // Log app launch for analytics
        #if !DEBUG
        FirebaseAnalytics.Analytics.logEvent("app_launch", parameters: nil)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                SplashScreenView()
                    .environmentObject(notificationManager)
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }
    
    // Configure global appearance settings
    private func configureAppearance() {
        ThemeManager.shared.applyAppearance()
    }
    
    // Handle deep links
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "moti" else { return }
        
        print("Received deep link: \(url.absoluteString)")
        
        // Post notification for other components to handle specific deep links
        NotificationCenter.default.post(
            name: Notification.Name("DeepLinkReceived"),
            object: nil,
            userInfo: ["url": url]
        )
    }
}
