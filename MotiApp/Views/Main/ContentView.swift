import SwiftUI
import Combine
import AppTrackingTransparency
import FirebaseAnalytics  // Add explicit import

// Main ContentView serving as the tab container for the app
struct ContentView: View {
    // MARK: - Properties
    
    // Tab selection state
    @State private var selectedTab = 0
    
    // Environment objects and observable objects
    @EnvironmentObject var notificationManager: NotificationManager
    @ObservedObject var streakManager = StreakManager.shared
    @ObservedObject var adManager = AdManager.shared
    
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
    
    // MARK: - Initialization
    
    init() {
        // Ensure proper dark mode appearance for tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        
        // Set the tab bar appearance for all states
        UITabBar.appearance().standardAppearance = appearance
        
        // For iOS 15+ we need to set scrollEdgeAppearance as well
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Increase contrast for unselected tab items for better visibility
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        
        print("Tab bar appearance configured with black background")
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Home Tab (Quotes)
                HomeQuoteView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                    .trackNavigationForAds() // Track navigation for interstitials
                
                // Mind Dump Tab (NEW)
                   MindDumpTabView()
                       .tabItem {
                           Image(systemName: "note.text")
                           Text("Mind Dump")
                       }
                       .tag(4)
                       .trackNavigationForAds()
                
                // To-Do Tab
                TodoListView()
                    .tabItem {
                        Image(systemName: "checkmark.circle")
                        Text("To-Do")
                    }
                    .tag(2)
                    .trackNavigationForAds() // Track navigation for interstitials
                
                // Pomodoro Timer Tab (New)
                PomodoroTimerView()
                    .tabItem {
                        Image(systemName: "timer")
                        Text("Pomodoro")
                    }
                    .tag(3)
                    .trackNavigationForAds() // Track navigation for interstitials
                
                // Favorites Tab (moved to index 4)
                FavoritesView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Favorites")
                    }
                    .tag(4)
                    .trackNavigationForAds() // Track navigation for interstitials
                
                // More Tab (moved to index 5)
                MoreView()
                    .tabItem {
                        Image(systemName: "ellipsis")
                        Text("More")
                    }
                    .tag(5)
                    .trackNavigationForAds() // Track navigation for interstitials
            }
            .accentColor(.white) // Active tab color
            
            // Banner ad at the top - non-intrusive
            if !adManager.isPremiumUser {
                VStack {
                    // Banner ad on top
                    EnhancedBannerAdView(screenName: currentScreenName)
                        .padding(.top, getSafeAreaTopInset()) // Add padding for status bar
                    
                    Spacer()
                }
            }
            
            // Add a subtle thin line at the top of the tab bar for better visual separation
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.white.opacity(0.3))
                    .padding(.bottom, 49) // Tab bar height
            }
        }
        .edgesIgnoringSafeArea(.top) // Allow the banner ad to extend to the top edge
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
                if url.host == "calendar" {
                    // Navigate to calendar or home tab
                    self.selectedTab = 0
                } else if url.host == "quotes" {
                    // Navigate to quotes tab
                    self.selectedTab = 1
                } else if url.host == "timer" || url.host == "pomodoro" {
                    // Navigate to pomodoro tab
                    self.selectedTab = 3
                } else if url.host == "premium" {
                    // Show premium alert instead of view
                    showPremiumComingSoonAlert()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenQuotesTab"))) { _ in
            // When a notification is tapped, navigate to the quotes tab
            self.selectedTab = 1 // Index of the Categories tab
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenStreakDetails"))) { _ in
            // Open streak details when a streak notification is tapped
            self.selectedTab = 5 // Index of the More tab (now at position 5)
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
    
    /// Helper to get current screen name for context-aware ads
    private var currentScreenName: String {
        switch selectedTab {
        case 0: return "HomeView"
        case 1: return "CategoriesView"
        case 2: return "TodoListView"
        case 3: return "PomodoroTimerView"
        case 4: return "FavoritesView"
        case 5: return "MoreView"
        default: return "Default"
        }
    }
    
    /// Helper to get the safe area top inset
    private func getSafeAreaTopInset() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.top
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

// MARK: - Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NotificationManager.shared)
            .preferredColorScheme(.dark)
            .onAppear {
                // Add some sample todos for preview
                let todoService = TodoService.shared
                if todoService.todos.isEmpty {
                    for todo in TodoItem.samples {
                        todoService.addTodo(todo)
                    }
                }
            }
    }
}
