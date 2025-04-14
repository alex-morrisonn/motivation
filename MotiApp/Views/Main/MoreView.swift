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
                .padding(.bottom, 8)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Option Row Component
struct OptionRow: View {
    let icon: String
    let title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Category Row Component
struct CategoryRow: View {
    let category: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(category)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 20))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let number: String
    let label: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            Text(number)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Coming Soon Banner Component
struct ComingSoonBanner: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Left content with icon and text
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                        .padding(8)
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(Circle())
                    
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
                
                // Right arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.1, green: 0.1, blue: 0.2)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}

// More View for settings and additional options
struct MoreView: View {
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
    
    // New state variable for Widget Guide
    @State private var showingWidgetGuide = false
    
    @State private var selectedCategories: Set<String> = []
    
    var body: some View {
        ZStack {
            // Black background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // Premium banner for non-premium users
                    ComingSoonBanner(action: { showingPremiumView = true })
                        .padding(.top, 10)
                    
                    // Stats cards with colors
                    HStack(spacing: 15) {
                        StatCard(
                            number: "\(quoteService.favorites.count)",
                            label: "Favorites",
                            icon: "heart",
                            iconColor: .red
                        )
                        
                        StatCard(
                            number: "\(eventService.events.count)",
                            label: "Events",
                            icon: "calendar",
                            iconColor: .blue
                        )
                        
                        // Updated to use real streak data with tap action
                        Button(action: {
                            showingStreakDetails = true
                        }) {
                            StatCard(
                                number: "\(streakManager.currentStreak)",
                                label: "Day Streak",
                                icon: "flame",
                                iconColor: .orange
                            )
                            .overlay(
                                // Subtle indicator that this is tappable
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(6),
                                alignment: .topTrailing
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 16)
                    
                    // Settings section
                    VStack(spacing: 0) {
                        SectionHeader(title: "SETTINGS")
                        
                        // Section background
                        VStack(spacing: 0) {
                            // Notifications toggle
                            HStack {
                                Image(systemName: "bell")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 20)
                                
                                Text("Daily Quote Reminder")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Custom toggle connected to notification manager
                                ZStack {
                                    Capsule()
                                        .fill(notificationManager.isNotificationsEnabled ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 30)
                                    
                                    Circle()
                                        .fill(notificationManager.isNotificationsEnabled ? Color.white.opacity(0.7) : Color.gray.opacity(0.5))
                                        .frame(width: 26, height: 26)
                                        .offset(x: notificationManager.isNotificationsEnabled ? 10 : -10)
                                        .animation(.spring(response: 0.2), value: notificationManager.isNotificationsEnabled)
                                }
                                .onTapGesture {
                                    if !notificationManager.isNotificationsEnabled {
                                        // When enabling, check/request permission first
                                        checkAndRequestNotificationPermission()
                                    } else {
                                        // When disabling, just update the manager
                                        notificationManager.toggleNotifications(false)
                                    }
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            
                            // Show time picker only when notifications are enabled
                            if notificationManager.isNotificationsEnabled {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .frame(width: 20)
                                    
                                    Text("Reminder Time")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    DatePicker("", selection: $notificationManager.reminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .frame(width: 100)
                                        .colorScheme(.dark)
                                        .onChange(of: notificationManager.reminderTime) { oldValue, newValue in
                                            notificationManager.updateReminderTime(newValue)
                                        }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Coming Soon section (Free Features)
                    VStack(spacing: 0) {
                        SectionHeader(title: "COMING SOON")
                        
                        // Section background
                        VStack(spacing: 0) {
                            // AI-Powered Assignment Kick-Starter
                            ComingSoonFeatureRow(
                                icon: "brain",
                                iconColor: .purple,
                                title: "Assignment Kick-Starter",
                                description: "AI-powered tool to break assignments into manageable steps and conquer blank page anxiety."
                            )
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Pomodoro Timer
                            ComingSoonFeatureRow(
                                icon: "timer",
                                iconColor: .orange,
                                title: "Pomodoro Timer",
                                description: "Focus mode with 25/5 minute sessions, ambient sounds, and encouraging messages."
                            )
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Gratitude/Mind Dump Notes
                            ComingSoonFeatureRow(
                                icon: "note.text",
                                iconColor: .green,
                                title: "Gratitude Journal",
                                description: "Simple notepad for journaling thoughts and practicing mindfulness."
                            )
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 10)
                    
                    // Premium Features section
                    VStack(spacing: 0) {
                        SectionHeader(title: "PREMIUM FEATURES")
                        
                        // Section background
                        VStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.yellow)
                                        .frame(width: 20)
                                    
                                    Text("Premium Features")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("In Development")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Ad Removal
                            PremiumFeatureItemRow(
                                icon: "xmark.circle",
                                iconColor: .red,
                                title: "Ad-Free Experience",
                                description: "Enjoy the app without any advertisements."
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Custom Themes
                            PremiumFeatureItemRow(
                                icon: "paintpalette",
                                iconColor: .blue,
                                title: "Custom Themes",
                                description: "Choose between a range of beautiful themes for the app."
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Enhanced Widgets
                            PremiumFeatureItemRow(
                                icon: "square.grid.2x2",
                                iconColor: .purple,
                                title: "Enhanced Widgets",
                                description: "Access exclusive widget designs and customization options."
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Learn More button
                            Button(action: {
                                showingPremiumView = true
                            }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.yellow)
                                        .frame(width: 20)
                                    
                                    Text("Learn More")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 10)

                    // Other options section
                    VStack(spacing: 0) {
                        SectionHeader(title: "OPTIONS")
                        
                        // Section background
                        VStack(spacing: 0) {
                            OptionRow(
                                icon: "info.circle",
                                title: "About",
                                action: { showingAbout.toggle() }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            // Widget Guide Option
                            OptionRow(
                                icon: "square.grid.2x2",
                                title: "Widget Guide",
                                action: { showingWidgetGuide.toggle() }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            OptionRow(
                                icon: "lock.shield",
                                title: "Privacy Policy",
                                action: { showingPrivacyPolicy.toggle() }
                            )
                                    
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            OptionRow(
                                 icon: "doc.text",
                                 title: "Terms of Service",
                                 action: { showingTerms.toggle() }
                             )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            OptionRow(
                                icon: "envelope",
                                title: "Send Feedback",
                                action: { showingFeedback.toggle() }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            OptionRow(
                                icon: "square.and.arrow.up",
                                title: "Share App",
                                action: { showingShare.toggle() }
                            )
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Categories section
                    VStack(spacing: 0) {
                        SectionHeader(title: "CATEGORIES")
                        
                        Text("Select your favorite categories for personalized content")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 12)
                        
                        // Categories list
                        VStack(spacing: 0) {
                            ForEach(quoteService.getAllCategories(), id: \.self) { category in
                                if category != quoteService.getAllCategories().first {
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                }
                                
                                CategoryRow(
                                    category: category,
                                    isSelected: selectedCategories.contains(category),
                                    onToggle: {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }
                                )
                            }
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.vertical, 10)
                    
                    // Clear Cache section at the bottom
                    VStack(spacing: 0) {
                        // Clear cache button with red text
                        Button(action: {
                            showingCacheAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red.opacity(0.9))
                                    .frame(width: 20)
                                
                                Text("Clear Cache")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red.opacity(0.9))
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                    }
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.bottom, 10)
                    
                    // App info
                    VStack(spacing: 8) {
                        Text("Moti")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("© 2025 Moti Team")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackView()
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: ["Check out Moti, my favorite motivational quotes app!"])
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
        // Widget Guide sheet presentation
        .sheet(isPresented: $showingWidgetGuide) {
            WidgetsShowcaseView()
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
        .alert("Themes Feature", isPresented: $showingThemesWIPAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The themes feature is currently under development. Check back soon for updates!")
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

// Free upcoming feature row
struct ComingSoonFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Coming soon label
            Text("Soon")
                .font(.caption2)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// Premium feature row
struct PremiumFeatureItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Crown icon to indicate premium
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

