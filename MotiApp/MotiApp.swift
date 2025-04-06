import SwiftUI
import GoogleMobileAds
import Firebase
import FirebaseAnalytics

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
        
        // Configure iPad-specific UI
        configureIPadUIIfNeeded()
        
        // Log app launch for analytics
        #if !DEBUG
        FirebaseAnalytics.Analytics.logEvent("app_launch", parameters: nil)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            // Use SplashScreenView as entry point
            SplashScreenView()
                .environmentObject(notificationManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .environmentObject(AdManager.shared) // Ensure AdManager is accessible everywhere
        }
    }
    
    // Configure global appearance settings for consistent dark theme
    private func configureAppearance() {
        // Set up dark mode UI elements
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .black
        
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        
        // Table view appearance
        UITableView.appearance().backgroundColor = .clear
        
        print("Global appearance configured for dark theme")
    }
    
    // Configure iPad-specific UI adjustments
    private func configureIPadUIIfNeeded() {
        if UIDevice.isIPad {
            // For iPads, adjust specific UI elements to maintain proportions
            
            // 1. Tab bar adjustments for iPad
            if let tabBarAppearance = UITabBar.appearance().standardAppearance.copy() as? UITabBarAppearance {
                // Make sure icons and text are properly sized
                tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
                tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
                
                // Apply slightly larger font for iPad tab bar titles
                let fontSize: CGFloat = 12
                
                let normalAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize),
                    .foregroundColor: UIColor.lightGray
                ]
                
                let selectedAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .medium),
                    .foregroundColor: UIColor.white
                ]
                
                tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
                tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
                
                // Apply appearance to tab bar
                UITabBar.appearance().standardAppearance = tabBarAppearance
                
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
            }
            
            // 2. Navigation bar adjustments for iPad
            if let navBarAppearance = UINavigationBar.appearance().standardAppearance.copy() as? UINavigationBarAppearance {
                // Use slightly larger fonts for iPad navigation titles
                let titleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
                let largeTitleFont = UIFont.systemFont(ofSize: 34, weight: .bold)
                
                navBarAppearance.titleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: titleFont
                ]
                
                navBarAppearance.largeTitleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: largeTitleFont
                ]
                
                // Apply appearance to navigation bar
                UINavigationBar.appearance().standardAppearance = navBarAppearance
                UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
                UINavigationBar.appearance().compactAppearance = navBarAppearance
            }
            
            print("iPad-specific UI adjustments applied")
        }
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
            
            // Configure ad sizes based on device type
            if UIDevice.isIPad {
                // Set iPad-specific ad sizes if needed
                // This helps ensure ads appear proportionally correct on iPad
                AdManager.shared.configureForIPad()
            }
        }
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



// MARK: - AdManager Extension
extension AdManager {
    /// Configure ads specifically for iPad
    func configureForIPad() {
        // No implementation changes needed here - just a placeholder for the method
        // In a real implementation, you might adjust ad sizes or positions for iPad
        print("AdManager configured for iPad")
    }
}
