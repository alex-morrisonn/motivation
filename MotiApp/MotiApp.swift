import SwiftUI
import GoogleMobileAds
import Firebase

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
        
        // Setup Google Mobile Ads
        configureAds()
        
        // Log app launch for analytics
        #if !DEBUG
        Analytics.logEvent("app_launch", parameters: nil)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(notificationManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    // Configure global appearance settings
    private func configureAppearance() {
        // Set up dark mode for UI elements
        UINavigationBar.appearance().tintColor = .white
        UITabBar.appearance().backgroundColor = .black
        UITableView.appearance().backgroundColor = .clear
    }
    
    private func configureAds() {
        // Add test device IDs for simulator during development
        #if DEBUG
        let deviceIDs = ["GAD_SIMULATOR_ID"] // Add your real test device IDs here if testing on physical devices
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = deviceIDs
        print("AdMob configured for DEBUG with test devices")
        #else
        // Production configuration
        print("AdMob configured for PRODUCTION")
        #endif
        
        // Set ad content rating
        MobileAds.shared.requestConfiguration.maxAdContentRating = GADMaxAdContentRating.general
        
        // Initialize the Mobile Ads SDK - the newest version doesn't take arguments
        MobileAds.initialize()
        print("Mobile Ads SDK initialization complete")
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
