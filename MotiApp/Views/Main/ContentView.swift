import SwiftUI
import Combine
import AppTrackingTransparency
import FirebaseAnalytics

struct ContentView: View {
    // MARK: - Properties
    
    // Tab selection state
    @State private var selectedTab = 0
    
    // Environment objects and observable objects
    @EnvironmentObject var notificationManager: NotificationManager
    @ObservedObject var streakManager = StreakManager.shared
    
    // Theme manager
    @ObservedObject var themeManager = ThemeManager.shared
    
    // UI state properties
    @State private var showingStreakCelebration = false
    @State private var previousStreak = 0
    @State private var showingPremiumOffer = false
    @State private var showingPremiumAlert = false
    @State private var showingTrackingConsent = false
    
    // Track whether tracking consent has been shown
    @AppStorage("hasShownTrackingConsent") private var hasShownTrackingConsent = false
    
    // Add observer for tab selection changes
    @State private var tabNavigationCancellable: NSObjectProtocol? = nil
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab (Daily Discipline)
            DisciplineHomeView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Discipline")
                }
                .tag(0)
            
            // Quotes Tab
            QuotesOnlyView()
                .tabItem {
                    Image(systemName: "quote.bubble.fill")
                    Text("Quotes")
                }
                .tag(1)
            
            // Calendar Tab
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
                .tag(2)
            
            // More Tab - Direct access with no NavigationView wrapping
            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
                .tag(3)
        }
        .accentColor(Color.themePrimary) // Use theme primary color for accent
        .environment(\.appTheme, themeManager.currentTheme) // Pass theme through environment
        .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light) // Set color scheme based on theme
        .sheet(isPresented: $showingPremiumOffer) {
            PremiumView()
        }
        .onAppear {
            // Add observer to listen for tab selection changes
            tabNavigationCancellable = NotificationCenter.default.addObserver(
                forName: Notification.Name("TabSelectionChanged"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let newTab = userInfo["selectedTab"] as? Int {
                    withAnimation {
                        self.selectedTab = newTab
                    }
                }
            }
        }
        .onDisappear {
            // Remove observer when view disappears
            if let cancellable = tabNavigationCancellable {
                NotificationCenter.default.removeObserver(cancellable)
            }
        }
        .fullScreenCover(isPresented: $showingTrackingConsent) {
            TrackingConsentView()
        }
        .alert("Premium Coming Soon", isPresented: $showingPremiumAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Premium features are currently under development. For now, enjoy the free version with all quotes and widgets available!")
        }
        .onOpenURL { url in
            if url.scheme == "moti" {
                if url.host == "calendar" || url.host == "discipline" {
                    // Navigate to discipline/home tab
                    self.selectedTab = 0
                } else if url.host == "quotes" {
                    // Navigate to quotes tab
                    self.selectedTab = 1
                } else if url.host == "premium" {
                    // Show premium alert instead of view
                    showPremiumComingSoonAlert()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenQuotesTab"))) { _ in
            // When a notification is tapped, navigate to the quotes tab
            self.selectedTab = 1 // Quotes tab
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenStreakDetails"))) { _ in
            // Open streak details when a streak notification is tapped
            self.selectedTab = 3 // Index of the More tab
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))) { _ in
            // Check if streak increased (but not first day)
            if streakManager.currentStreak > previousStreak && previousStreak > 0 {
                // Only show celebration for meaningful increases (no need to celebrate the 1st day)
                showingStreakCelebration = true
            }
            
            // Update previous streak for next comparison
            previousStreak = streakManager.currentStreak
        }
        .onAppear {
            // Check for tracking permission status on app appear
            checkAndShowTrackingConsentIfNeeded()
        }
        .fullScreenCover(isPresented: $showingStreakCelebration) {
            StreakCelebrationView(
                streakCount: streakManager.currentStreak,
                isShowing: $showingStreakCelebration
            )
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper to show premium coming soon alert
    private func showPremiumComingSoonAlert() {
        showingPremiumAlert = true
    }
    
    /// Check tracking status and show consent if needed
    private func checkAndShowTrackingConsentIfNeeded() {
        // Skip the check if the tracking consent has already been shown
        // OR if we're coming from SplashScreenView (which already handles this)
        if !hasShownTrackingConsent && !UserDefaults.standard.bool(forKey: "isFromSplashScreen") {
            if #available(iOS 14.0, *) {
                // Get the current status directly
                let status = ATTrackingManager.trackingAuthorizationStatus
                
                DispatchQueue.main.async {
                    if status == .notDetermined {
                        // Present tracking consent after a small delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showingTrackingConsent = true
                        }
                    }
                }
            }
        } else {
            // Reset the flag for next time
            UserDefaults.standard.removeObject(forKey: "isFromSplashScreen")
        }
    }
}
