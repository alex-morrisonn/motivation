import SwiftUI

@main
struct MotiApp: App {
    // Register the app delegate for the UIApplication
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(NotificationManager.shared)
        }
    }
}
