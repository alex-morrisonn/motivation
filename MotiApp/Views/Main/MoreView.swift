import SwiftUI
import WidgetKit

// MARK: - Section Header Component
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
                .padding(.vertical, 8)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Enhanced Feature Row Component
struct EnhancedFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let badge: String?
    let badgeColor: Color
    
    // Add state to track if the row is expanded
    @State private var isExpanded = false
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        badge: String? = nil,
        badgeColor: Color = .blue
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self.badge = badge
        self.badgeColor = badgeColor
    }
    
    var body: some View {
        Button(action: {
            // Toggle expanded state on tap
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 15) {
                    // Icon with background
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(iconColor.opacity(0.15))
                        .clipShape(Circle())
                    
                    // Title and description
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            // Remove line limit restriction when expanded
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Spacer()
                    
                    // Optional badge
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(badgeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(badgeColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                // Show an indicator for expansion state
                if isExpanded {
                    HStack {
                        Spacer()
                        Text("Tap to collapse")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10))
                            .foregroundColor(.gray.opacity(0.7))
                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .background(Color.black.opacity(0.001)) // Invisible background to make entire area tappable
    }
}

// MARK: - Option Row Component
struct OptionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var action: () -> Void
    
    init(
        icon: String,
        iconColor: Color = .white,
        title: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Icon with background
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
                    .frame(width: 18, height: 18)
                    .padding(8)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let number: String
    let label: String
    let icon: String
    let iconColor: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: 12) {
                // Icon with background
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
                
                Text(number)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Premium Banner Component
struct PremiumBanner: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 15) {
                    // Premium icon and text
                    HStack(alignment: .center) {
                        // Crown icon
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.yellow)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Premium Features")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Coming soon!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Status tag
                    Text("In Development")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Animated bottom indicator
                HStack {
                    Spacer()
                    Text("Tap to learn more")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.15)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Section Container Component
struct SectionContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - More View
struct MoreView: View {
    // MARK: - Properties
    
    @ObservedObject var quoteService = QuoteService.shared
    @ObservedObject var eventService = EventService.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var streakManager = StreakManager.shared
    @ObservedObject var adManager = AdManager.shared
    
    @State private var showingAbout = false
    @State private var showingFeedback = false
    @State private var showingShare = false
    @State private var showingPermissionAlert = false
    @State private var showingCacheAlert = false
    @State private var showingCacheConfirmation = false
    @State private var showingThemesWIPAlert = false
    @State private var showingStreakDetails = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingPremiumView = false
    @State private var showingRewardedAdView = false
    @State private var showingComingSoonAlert = false
    @State private var showingWidgetGuide = false
    @State private var showingPomodoroTimer = false
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Premium Banner
                    PremiumBanner(action: { showingPremiumView = true })
                        .padding(.top, 10)
                        .padding(.horizontal, 20)
                    
                    // Stats Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "STATISTICS")
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 15) {
                            // Favorites stat
                            StatCard(
                                number: "\(quoteService.favorites.count)",
                                label: "Favorites",
                                icon: "heart.fill",
                                iconColor: .red
                            )
                            
                            // Events stat
                            StatCard(
                                number: "\(eventService.events.count)",
                                label: "Events",
                                icon: "calendar",
                                iconColor: .blue
                            )
                            
                            // Streak stat with tap action
                            StatCard(
                                number: "\(streakManager.currentStreak)",
                                label: "Day Streak",
                                icon: "flame.fill",
                                iconColor: .orange,
                                action: { showingStreakDetails = true }
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Notification Settings Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "SETTINGS")
                            .padding(.horizontal, 20)
                        
                        SectionContainer {
                            // Daily Quote Reminder toggle
                            HStack {
                                // Icon with background
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .frame(width: 18, height: 18)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Circle())
                                
                                Text("Daily Quote Reminder")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Toggle switch
                                Toggle("", isOn: Binding(
                                    get: { notificationManager.isNotificationsEnabled },
                                    set: { newValue in
                                        if !newValue {
                                            notificationManager.toggleNotifications(false)
                                        } else {
                                            checkAndRequestNotificationPermission()
                                        }
                                    }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            
                            // Show reminder time picker when notifications are enabled
                            if notificationManager.isNotificationsEnabled {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.horizontal, 16)
                                
                                HStack {
                                    // Icon with background
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                        .frame(width: 18, height: 18)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.15))
                                        .clipShape(Circle())
                                    
                                    Text("Reminder Time")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Time picker
                                    DatePicker("", selection: $notificationManager.reminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .frame(width: 100)
                                        .colorScheme(.dark)
                                        .onChange(of: notificationManager.reminderTime) { oldValue, newValue in
                                            notificationManager.updateReminderTime(newValue)
                                        }
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Coming Soon Features Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "COMING SOON")
                            .padding(.horizontal, 20)
                        
                        SectionContainer {
                            // Assignment Kick-Starter
                            EnhancedFeatureRow(
                                icon: "brain",
                                iconColor: .purple,
                                title: "Assignment Kick-Starter",
                                description: "AI-powered tool to break assignments into manageable steps and conquer blank page anxiety.",
                                badge: "Soon",
                                badgeColor: .blue
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Pomodoro Timer - Now active and clickable
                            EnhancedFeatureRow(
                                icon: "timer",
                                iconColor: .orange,
                                title: "Pomodoro Timer",
                                description: "Focus mode with 25/5 minute sessions, ambient sounds, and encouraging messages.",
                                badge: "New",
                                badgeColor: .green
                            )
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingPomodoroTimer = true
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Gratitude Journal
                            EnhancedFeatureRow(
                                icon: "note.text",
                                iconColor: .green,
                                title: "Gratitude Journal",
                                description: "Simple notepad for journaling thoughts and practicing mindfulness.",
                                badge: "Soon",
                                badgeColor: .blue
                            )
                            .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Premium Features Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "PREMIUM FEATURES")
                            .padding(.horizontal, 20)
                        
                        SectionContainer {
                            // Ad-Free Experience
                            EnhancedFeatureRow(
                                icon: "xmark.circle",
                                iconColor: .red,
                                title: "Ad-Free Experience",
                                description: "Enjoy the app without any advertisements.",
                                badge: "Premium",
                                badgeColor: .yellow
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Custom Themes
                            EnhancedFeatureRow(
                                icon: "paintpalette",
                                iconColor: .blue,
                                title: "Custom Themes",
                                description: "Choose between a range of beautiful themes for the app.",
                                badge: "Premium",
                                badgeColor: .yellow
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Enhanced Widgets
                            EnhancedFeatureRow(
                                icon: "square.grid.2x2",
                                iconColor: .purple,
                                title: "Enhanced Widgets",
                                description: "Access exclusive widget designs and customization options.",
                                badge: "Premium",
                                badgeColor: .yellow
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Learn More button
                            Button(action: {
                                showingPremiumView = true
                            }) {
                                Text("Learn More About Premium")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.3)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Options Section
                    VStack(spacing: 12) {
                        SectionHeader(title: "OPTIONS")
                            .padding(.horizontal, 20)
                        
                        SectionContainer {
                            // About
                            OptionRow(
                                icon: "info.circle",
                                iconColor: .blue,
                                title: "About",
                                action: { showingAbout.toggle() }
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Widget Guide
                            OptionRow(
                                icon: "square.grid.2x2",
                                iconColor: .purple,
                                title: "Widget Guide",
                                action: { showingWidgetGuide.toggle() }
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Privacy Policy
                            OptionRow(
                                icon: "lock.shield",
                                iconColor: .teal,
                                title: "Privacy Policy",
                                action: { showingPrivacyPolicy.toggle() }
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Terms of Service
                            OptionRow(
                                icon: "doc.text",
                                iconColor: .gray,
                                title: "Terms of Service",
                                action: { showingTerms.toggle() }
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Send Feedback
                            OptionRow(
                                icon: "envelope",
                                iconColor: .green,
                                title: "Send Feedback",
                                action: { showingFeedback.toggle() }
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 16)
                            
                            // Share App
                            OptionRow(
                                icon: "square.and.arrow.up",
                                iconColor: .blue,
                                title: "Share App",
                                action: { showingShare.toggle() }
                            )
                            .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Clear Cache Section
                    VStack(spacing: 12) {
                        SectionContainer {
                            // Clear cache button with red text
                            Button(action: {
                                showingCacheAlert = true
                            }) {
                                HStack {
                                    // Icon with background
                                    Image(systemName: "trash")
                                        .font(.system(size: 16))
                                        .foregroundColor(.red)
                                        .frame(width: 18, height: 18)
                                        .padding(8)
                                        .background(Color.red.opacity(0.15))
                                        .clipShape(Circle())
                                    
                                    Text("Clear Cache")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // App info
                    VStack(spacing: 8) {
                        Text("Motii")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Version 1.1.1")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("© 2025 Motii Team")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackView()
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: ["Check out Motii, my favorite motivational quotes app!"])
        }
        .sheet(isPresented: $showingStreakDetails) {
            StreakDetailsView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPremiumView) {
            PremiumView()
        }
        .sheet(isPresented: $showingRewardedAdView) {
            RewardedAdView()
        }
        .sheet(isPresented: $showingWidgetGuide) {
            WidgetsShowcaseView()
        }
        .sheet(isPresented: $showingPomodoroTimer) {
            PomodoroTimerView()
        }
        .alert("Notification Permission", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) {
                // User canceled, make sure toggle reflects permission state
                notificationManager.checkNotificationStatus()
            }
            Button("Settings", role: .none) {
                // Open app settings
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("To receive daily quote reminders, you need to allow notifications in Settings.")
        }
        .alert("Clear Cache", isPresented: $showingCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAppCache()
                showingCacheConfirmation = true
            }
        } message: {
            Text("This will clear all cached data and refresh widgets. Your favorites and events will not be affected.")
        }
        .alert("Cache Cleared", isPresented: $showingCacheConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All cached data has been cleared successfully.")
        }
        .alert("Coming Soon", isPresented: $showingComingSoonAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This feature is currently in development and will be available in a future update!")
        }
        .onAppear {
            // Make sure notification state is updated when view appears
            notificationManager.checkNotificationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StreakUpdated"))) { _ in
            // This ensures the UI updates when the streak changes
        }
    }
    
    // MARK: - Helper Methods
    
    // Check and request notification permissions if needed
    func checkAndRequestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    // Request permission
                    notificationManager.requestNotificationPermission { granted in
                        if !granted {
                            // If permission denied, show alert
                            showingPermissionAlert = true
                        }
                    }
                case .denied:
                    // Show alert to direct to settings
                    showingPermissionAlert = true
                case .authorized, .provisional, .ephemeral:
                    // Permission already granted, just toggle
                    notificationManager.toggleNotifications(true)
                @unknown default:
                    // For future authorizationStatus values
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    // Function to clear app cache
    func clearAppCache() {
        // Clear files in the caches directory
        do {
            let fileManager = FileManager.default
            let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let cacheContents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            
            for url in cacheContents {
                try fileManager.removeItem(at: url)
            }
            
            // Clear temporary data from UserDefaults (except favorites and events)
            // This preserves important data while clearing potential corrupted cache
            let defaults = UserDefaults.standard
            if let bundleID = Bundle.main.bundleIdentifier {
                defaults.dictionaryRepresentation().keys.forEach { key in
                    // Skip specific keys we want to preserve
                    let keysToPreserve = ["savedFavorites", "savedEvents", "notificationsEnabled", "reminderTime",
                                          "streak_lastOpenDate", "streak_currentStreak", "streak_longestStreak", "streak_daysRecord"]
                    if !keysToPreserve.contains(key) && key.hasPrefix(bundleID) {
                        defaults.removeObject(forKey: key)
                    }
                }
            }
            
            // Reload all widget timelines to refresh their data
            WidgetCenter.shared.reloadAllTimelines()
            
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
}

// MARK: - Preview
struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
            .preferredColorScheme(.dark)
    }
}
