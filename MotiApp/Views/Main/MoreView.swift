import SwiftUI
import WidgetKit

struct MoreView: View {
    // MARK: - Properties
    
    @ObservedObject var quoteService = QuoteService.shared
    @ObservedObject var notificationManager = NotificationManager.shared
    @ObservedObject var streakManager = StreakManager.shared
    @ObservedObject var adManager = AdManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    
    // Sheet presentation states
    @State private var showingAbout = false
    @State private var showingFeedback = false
    @State private var showingShare = false
    @State private var showingPermissionAlert = false
    @State private var showingCacheAlert = false
    @State private var showingCacheConfirmation = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingPremiumView = false
    @State private var showingWidgetGuide = false
    @State private var showingFavorites = false
    @State private var showingCategories = false
    @State private var showingThemeSettings = false
    
    // MARK: - View Body
    
    var body: some View {
        ZStack {
            // Background - use theme background color
            Color.themeBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Premium card - prominent placement
                    premiumCardView
                    
                    // New features section
                    newFeaturesSection
                    
                    // Theme settings section - new section
                    themeSection
                    
                    // Quick access to favorites and categories
                    quickAccessSection
                    
                    // Settings section
                    settingsSection
                    
                    // Support section
                    supportSection
                    
                    // App info (version, etc.)
                    appInfoView
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.bottom, 30)
            }
        }
        // Sheet presentations
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackView()
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(activityItems: ["Check out Motii, my favorite motivational quotes app!"])
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
        .sheet(isPresented: $showingWidgetGuide) {
            WidgetsShowcaseView()
        }
        .sheet(isPresented: $showingThemeSettings) {
            ThemeSettingsView()
        }
        // New sheet presentations for Favorites and Categories
        .sheet(isPresented: $showingFavorites) {
            NavigationView {
                FavoritesView()
                    .navigationTitle("Favorites")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showingFavorites = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingCategories) {
            NavigationView {
                CategoriesView()
                    .navigationTitle("Categories")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showingCategories = false
                            }
                        }
                    }
            }
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
        .onAppear {
            // Make sure notification state is updated when view appears
            notificationManager.checkNotificationStatus()
        }
    }
    
    // MARK: - Component Views
    
    // Theme selection section - new section
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("APPEARANCE")
            
            Button(action: {
                showingThemeSettings = true
            }) {
                HStack {
                    // Icon with pretty visualization of current theme
                    ZStack {
                        Circle()
                            .fill(themeManager.currentTheme.primary.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        HStack(spacing: 2) {
                            Circle()
                                .fill(themeManager.currentTheme.primary)
                                .frame(width: 12, height: 12)
                            
                            Circle()
                                .fill(themeManager.currentTheme.secondary)
                                .frame(width: 12, height: 12)
                                .offset(x: -4, y: 8)
                            
                            Circle()
                                .fill(themeManager.currentTheme.accent)
                                .frame(width: 12, height: 12)
                                .offset(x: -8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App Theme")
                            .font(.headline)
                            .foregroundColor(Color.themeText)
                        
                        Text(themeManager.currentTheme.name)
                            .font(.subheadline)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeSecondaryText)
                }
                .padding()
                .background(Color.themeCardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.themeDivider, lineWidth: 1)
                )
            }
        }
    }
    
    // Premium subscription card with engaging design
    private var premiumCardView: some View {
        Button(action: { showingPremiumView = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    // Crown icon with glowing effect
                    ZStack {
                        Circle()
                            .fill(Color.themeWarning.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.themeWarning)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium Version")
                            .font(.headline)
                            .foregroundColor(Color.themeText)
                        
                        Text("Coming Soon!")
                            .font(.subheadline)
                            .foregroundColor(Color.themeWarning)
                    }
                    
                    Spacer()
                    
                    // Label
                    Text("Premium")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.isDark ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.themeWarning, Color.themeError.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                }
                
                // Features list in two columns
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    premiumFeatureItem(icon: "xmark.circle.fill", text: "Ad-Free Experience")
                    premiumFeatureItem(icon: "paintpalette.fill", text: "Custom Themes")
                    premiumFeatureItem(icon: "square.grid.2x2.fill", text: "Premium Widgets")
                    premiumFeatureItem(icon: "star.fill", text: "Exclusive Content")
                }
                
                // Call to action
                HStack {
                    Spacer()
                    Text("Learn More")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.isDark ? .black : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.themeWarning, Color.themeError.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    Spacer()
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.currentTheme.cardBackground,
                        themeManager.currentTheme.background
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.themeWarning, Color.themeError.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .cornerRadius(16)
        }
    }
    
    // Helper for premium feature items
    private func premiumFeatureItem(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(Color.themeWarning)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Color.themeText)
                .lineLimit(1)
            
            Spacer()
        }
    }
    
    // New features section highlighting todo, mind dump and pomodoro
    private var newFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("NEW FEATURES")
            
            VStack(spacing: 16) {
                // Todo List Feature
                newFeatureCard(
                    icon: "checkmark.circle.fill",
                    title: "To-Do List",
                    description: "Organize tasks and build momentum with our streak system",
                    color: Color.themeSuccess,
                    destination: .todo
                )
                
                // Mind Dump Feature
                newFeatureCard(
                    icon: "note.text",
                    title: "Mind Dump",
                    description: "Capture thoughts, ideas and reflections in one place",
                    color: Color.themePrimary,
                    destination: .mindDump
                )
                
                // Pomodoro Timer Feature
                newFeatureCard(
                    icon: "timer",
                    title: "Pomodoro Timer",
                    description: "Boost productivity with focused work sessions",
                    color: Color.themeWarning,
                    destination: .pomodoro
                )
            }
        }
    }
    
    // Quick access to favorites and categories
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("EXPLORE QUOTES")
            
            HStack(spacing: 16) {
                // Favorites button - now opens as a sheet
                Button(action: {
                    showingFavorites = true
                }) {
                    quickAccessButton(
                        icon: "heart.fill",
                        title: "Favorites",
                        count: quoteService.favorites.count,
                        color: Color.themeError
                    )
                }
                
                // Categories button - now opens as a sheet
                Button(action: {
                    showingCategories = true
                }) {
                    quickAccessButton(
                        icon: "square.grid.2x2",
                        title: "Categories",
                        count: quoteService.getAllCategories().count,
                        color: Color.themeSecondary
                    )
                }
            }
        }
    }
    
    // Settings section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("SETTINGS")
            
            SectionContainer {
                // Daily Quote Reminder toggle
                HStack {
                    // Icon with background
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.themeText)
                        .frame(width: 18, height: 18)
                        .padding(8)
                        .background(Color.themePrimary.opacity(0.15))
                        .clipShape(Circle())
                    
                    Text("Daily Quote Reminder")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.themeText)
                    
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
                    .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                
                // Show reminder time picker when notifications are enabled
                if notificationManager.isNotificationsEnabled {
                    Divider()
                        .background(Color.themeDivider)
                        .padding(.horizontal, 16)
                    
                    HStack {
                        // Icon with background
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color.themePrimary)
                            .frame(width: 18, height: 18)
                            .padding(8)
                            .background(Color.themePrimary.opacity(0.15))
                            .clipShape(Circle())
                        
                        Text("Reminder Time")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.themeText)
                        
                        Spacer()
                        
                        // Time picker
                        DatePicker("", selection: $notificationManager.reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(width: 100)
                            .colorScheme(themeManager.currentTheme.isDark ? .dark : .light)
                            .onChange(of: notificationManager.reminderTime) { oldValue, newValue in
                                notificationManager.updateReminderTime(newValue)
                            }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
                
                Divider()
                    .background(Color.themeDivider)
                    .padding(.horizontal, 16)
                
                // Widget Guide option
                OptionRow(
                    icon: "square.grid.2x2",
                    iconColor: Color.themeSecondary,
                    title: "Widget Guide",
                    action: { showingWidgetGuide.toggle() }
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    // Support section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("ABOUT & SUPPORT")
            
            SectionContainer {
                // About
                OptionRow(
                    icon: "info.circle",
                    iconColor: Color.themePrimary,
                    title: "About",
                    action: { showingAbout.toggle() }
                )
                .padding(.horizontal, 16)
                
                Divider()
                    .background(Color.themeDivider)
                    .padding(.horizontal, 16)
                
                // Privacy Policy
                OptionRow(
                    icon: "lock.shield",
                    iconColor: Color.themeSecondary,
                    title: "Privacy Policy",
                    action: { showingPrivacyPolicy.toggle() }
                )
                .padding(.horizontal, 16)
                
                Divider()
                    .background(Color.themeDivider)
                    .padding(.horizontal, 16)
                
                // Terms of Service
                OptionRow(
                    icon: "doc.text",
                    iconColor: Color.themeSecondaryText,
                    title: "Terms of Service",
                    action: { showingTerms.toggle() }
                )
                .padding(.horizontal, 16)
                
                Divider()
                    .background(Color.themeDivider)
                    .padding(.horizontal, 16)
                
                // Send Feedback
                OptionRow(
                    icon: "envelope",
                    iconColor: Color.themeSuccess,
                    title: "Send Feedback",
                    action: { showingFeedback.toggle() }
                )
                .padding(.horizontal, 16)
                
                Divider()
                    .background(Color.themeDivider)
                    .padding(.horizontal, 16)
                
                // Share App
                OptionRow(
                    icon: "square.and.arrow.up",
                    iconColor: Color.themePrimary,
                    title: "Share App",
                    action: { showingShare.toggle() }
                )
                .padding(.horizontal, 16)
                
                Divider()
                    .background(Color.themeDivider)
                    .padding(.horizontal, 16)
                
                // Clear cache button with red text
                Button(action: {
                    showingCacheAlert = true
                }) {
                    HStack {
                        // Icon with background
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(Color.themeError)
                            .frame(width: 18, height: 18)
                            .padding(8)
                            .background(Color.themeError.opacity(0.15))
                            .clipShape(Circle())
                        
                        Text("Clear Cache")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.themeError)
                        
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // App information view
    private var appInfoView: some View {
        VStack(spacing: 8) {
            // App logo
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 30))
                .foregroundColor(Color.themeText.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("Motii")
                .font(.headline)
                .foregroundColor(Color.themeText)
            
            Text("Version 1.1.1")
                .font(.caption)
                .foregroundColor(Color.themeText.opacity(0.5))
            
            Text("© 2025 Motii Team")
                .font(.caption2)
                .foregroundColor(Color.themeText.opacity(0.3))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Helper Components
    
    // Section header with consistent style
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color.themeText.opacity(0.6))
            .tracking(2)
    }
    
    // Section container component
    struct SectionContainer<Content: View>: View {
        let content: Content
        
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        var body: some View {
            VStack(spacing: 0) {
                content
            }
            .background(Color.themeCardBackground)
            .cornerRadius(16)
        }
    }
    
    // New feature card component
    private func newFeatureCard(icon: String, title: String, description: String, color: Color, destination: FeatureDestination) -> some View {
        Button(action: {
            navigateToFeature(destination)
        }) {
            HStack(spacing: 16) {
                // Feature icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(Color.themeText)
                        
                        Text("NEW")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.isDark ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color)
                            .cornerRadius(4)
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.themeSecondaryText)
            }
            .padding(16)
            .background(Color.themeCardBackground)
            .cornerRadius(12)
        }
    }
    
    // Quick access button component
    private func quickAccessButton(icon: String, title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(Color.themeText)
            
            Text("\(count)")
                .font(.system(size: 14))
                .foregroundColor(Color.themeSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.themeCardBackground)
        .cornerRadius(16)
    }
    
    // Option row for settings
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
                        .foregroundColor(Color.themeText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Color.themeText.opacity(0.3))
                }
                .padding(.vertical, 14)
            }
        }
    }
    
    // MARK: - Navigation and Helper Methods
    
    // Enum for feature destinations
    enum FeatureDestination {
        case todo, mindDump, pomodoro
    }
    
    // Navigate to different features
    private func navigateToFeature(_ destination: FeatureDestination) {
        switch destination {
        case .todo:
            TabNavigationHelper.shared.switchToTab(2) // Todo tab
        case .mindDump:
            TabNavigationHelper.shared.switchToTab(1) // Mind Dump tab
        case .pomodoro:
            TabNavigationHelper.shared.switchToTab(3) // Pomodoro tab
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
                                          "streak_lastOpenDate", "streak_currentStreak", "streak_longestStreak", "streak_daysRecord",
                                          "selectedThemeId"] // Keep theme preference
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
