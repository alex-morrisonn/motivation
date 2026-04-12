import SwiftUI
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
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                SplashScreenView()
                    .environmentObject(notificationManager)
            }
            .onOpenURL(perform: handleDeepLink)
        }
    }
    
    // Configure global appearance settings
    private func configureAppearance() {
        ThemeManager.shared.applyAppearance()
    }
    
    // Handle deep links
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == AppMetadata.deepLinkScheme else { return }

        // Post notification for other components to handle specific deep links
        NotificationCenter.default.post(
            name: .deepLinkReceived,
            object: nil,
            userInfo: ["url": url]
        )
    }
}
