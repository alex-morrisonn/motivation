import SwiftUI

@main
struct motivationalQuotesApp: App {
    // Register the app delegate for the UIApplication
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NotificationManager.shared)
        }
    }
}
