import SwiftUI
import WidgetKit

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
                                        .onChange(of: notificationManager.reminderTime) { newValue in
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
                    
                    // Themes section
                    VStack(spacing: 0) {
                        SectionHeader(title: "THEMES")
                        
                        // Section background
                        VStack(spacing: 0) {
                            Button(action: {
                                showingThemesWIPAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "paintpalette")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .frame(width: 20)
                                    
                                    Text("App Themes")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("Coming Soon")
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(0.8))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(10)
                                    
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
                    
                    // Premium Info section
                    VStack(spacing: 0) {
                        SectionHeader(title: "PREMIUM")
                        
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
                                
                                Text("We're working on premium features like ad removal, custom themes, and enhanced widgets. Stay tuned!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding(.leading, 36)
                                    .padding(.trailing, 16)
                                    .padding(.bottom, 8)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
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

// Coming Soon banner at the top of the More view
struct ComingSoonBanner: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("What's Coming Soon")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("See upcoming features and improvements")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Arrow icon
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(Circle().fill(Color.blue.opacity(0.2)))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.sRGB, red: 0.1, green: 0.1, blue: 0.2, opacity: 0.8), Color(.sRGB, red: 0.1, green: 0.1, blue: 0.3, opacity: 0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// Section header with minimalist design
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white.opacity(0.6))
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
            .padding(.top, 8)
    }
}

// Stat card with colored icons
struct StatCard: View {
    let number: String
    let label: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .padding(.bottom, 4)
            
            Text(number)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// Option row with minimalist design
struct OptionRow: View {
    let icon: String
    let title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 20)
                
                Text(title)
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
}

// Category row with colored icon backgrounds
struct CategoryRow: View {
    let category: String
    let isSelected: Bool
    var onToggle: () -> Void
    
    // Icons for categories
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Success & Achievement": return "trophy"
        case "Life & Perspective": return "scope"
        case "Dreams & Goals": return "sparkles"
        case "Courage & Confidence": return "bolt.heart"
        case "Perseverance & Resilience": return "figure.walk"
        case "Growth & Change": return "leaf"
        case "Action & Determination": return "flag"
        case "Mindset & Attitude": return "brain"
        case "Focus & Discipline": return "target"
        default: return "quote.bubble"
        }
    }
    
    // Color for category icons
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Success & Achievement": return Color.blue
        case "Life & Perspective": return Color.purple
        case "Dreams & Goals": return Color.green
        case "Courage & Confidence": return Color.orange
        case "Perseverance & Resilience": return Color.red
        case "Growth & Change": return Color.teal
        case "Action & Determination": return Color.indigo
        case "Mindset & Attitude": return Color.pink
        case "Focus & Discipline": return Color.yellow
        default: return Color.gray
        }
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Category icon with colored background
                ZStack {
                    Circle()
                        .fill(colorForCategory(category))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: iconForCategory(category))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                
                Text(category)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Green checkmark when selected
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .white.opacity(0.3))
                    .font(.system(size: 18))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
}

// SwiftUI Preview
struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
            .preferredColorScheme(.dark)
    }
}
