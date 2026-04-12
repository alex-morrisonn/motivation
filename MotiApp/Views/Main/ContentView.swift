import SwiftUI

struct ContentView: View {
    // MARK: - Properties
    
    // Tab selection state
    @State private var selectedTab = 0
    
    // Environment objects and observable objects
    @EnvironmentObject var notificationManager: NotificationManager
    @ObservedObject var streakManager = StreakManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    
    // Theme manager
    @ObservedObject var themeManager = ThemeManager.shared
    
    // UI state properties
    @State private var showingStreakCelebration = false
    @State private var previousStreak = 0
    @State private var showingPremiumAlert = false
    @State private var showingAnalyticsConsent = false
    @State private var showingWeeklyQuestCelebration = false
    @State private var hasRegisteredSessionOpen = false
    
    @AppStorage(AppDefaultsKey.analyticsConsentState) private var analyticsConsentState = AnalyticsConsentState.unknown.rawValue
    @AppStorage(AppDefaultsKey.shouldPromptAnalyticsConsent) private var shouldPromptAnalyticsConsent = false
    @AppStorage(AppDefaultsKey.analyticsConsentEligibleOpenCount) private var analyticsConsentEligibleOpenCount = 0
    
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
                    Image(systemName: "calendar.badge.clock")
                    Text("Plan")
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
        .onAppear {
            themeManager.applyAppearance()
            registerSessionOpenIfNeeded()
        }
        .fullScreenCover(isPresented: $showingAnalyticsConsent) {
            AnalyticsConsentView()
        }
        .alert("Premium Coming Soon", isPresented: $showingPremiumAlert) {
            Button("OK", role: .cancel) { }
        } message: {
                    Text("Premium features are currently under development. For now, enjoy the free version with all quotes and widgets available.")
        }
        .onOpenURL { url in
            if url.scheme == AppMetadata.deepLinkScheme {
                if url.host == "calendar" || url.host == "plan" {
                    // Navigate to planning tab
                    self.selectedTab = 2
                } else if url.host == "discipline" {
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
        .onReceive(NotificationCenter.default.publisher(for: .tabSelectionChanged)) { notification in
            guard
                let newTab = notification.userInfo?[AppNotification.selectedTabUserInfoKey] as? Int
            else {
                return
            }

            withAnimation {
                selectedTab = newTab
            }

            checkAndShowAnalyticsConsentIfNeeded(for: newTab)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuotesTab)) { _ in
            // When a notification is tapped, navigate to the quotes tab
            withAnimation {
                self.selectedTab = 1 // Quotes tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openStreakDetails)) { _ in
            // Open streak details when a streak notification is tapped
            self.selectedTab = 3 // Index of the More tab
        }
        .onReceive(NotificationCenter.default.publisher(for: .streakUpdated)) { _ in
            // Check if streak increased (but not first day)
            if streakManager.currentStreak > previousStreak && previousStreak > 0 {
                // Only show celebration for meaningful increases (no need to celebrate the 1st day)
                showingStreakCelebration = true
            }
            
            // Update previous streak for next comparison
            previousStreak = streakManager.currentStreak
        }
        .onChange(of: themeManager.currentTheme.id) { _, _ in
            themeManager.applyAppearance()
        }
        .onChange(of: selectedTab) { _, newValue in
            checkAndShowAnalyticsConsentIfNeeded(for: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .weeklyQuestCompleted)) { _ in
            showingWeeklyQuestCelebration = true
        }
        .fullScreenCover(isPresented: $showingStreakCelebration) {
            StreakCelebrationView(
                streakCount: streakManager.currentStreak,
                isShowing: $showingStreakCelebration
            )
        }
        .fullScreenCover(isPresented: $showingWeeklyQuestCelebration) {
            WeeklyQuestCelebrationView(isShowing: $showingWeeklyQuestCelebration)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Helper to show premium coming soon alert
    private func showPremiumComingSoonAlert() {
        showingPremiumAlert = true
    }
    
    private func registerSessionOpenIfNeeded() {
        guard !hasRegisteredSessionOpen else { return }
        hasRegisteredSessionOpen = true
        analyticsConsentEligibleOpenCount += 1
    }

    private func checkAndShowAnalyticsConsentIfNeeded(for selectedTab: Int) {
        guard
            profileManager.hasCompletedOnboarding,
            shouldPromptAnalyticsConsent,
            analyticsConsentState == AnalyticsConsentState.unknown.rawValue,
            selectedTab == 3,
            analyticsConsentEligibleOpenCount >= 3
        else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            showingAnalyticsConsent = true
            shouldPromptAnalyticsConsent = false
        }
    }
}
