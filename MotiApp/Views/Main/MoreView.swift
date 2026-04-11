import SwiftUI
import WidgetKit

struct MoreView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    @State private var showingAbout = false
    @State private var showingFeedback = false
    @State private var showingShare = false
    @State private var showingPermissionAlert = false
    @State private var showingCacheAlert = false
    @State private var showingCacheConfirmation = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingWidgetGuide = false
    @State private var showingFavorites = false
    @State private var showingCategories = false
    @State private var showingThemeSettings = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.themeBackground,
                    Color.themeCardBackground.opacity(0.82),
                    Color.themeBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    overviewCard
                    appearanceSection
                    quotesSection
                    appSection
                    supportSection
                    appInfoView
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
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
            ShareSheet(activityItems: ["Check out Motii, my favorite motivational quotes app!"])
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingWidgetGuide) {
            WidgetsShowcaseView()
        }
        .sheet(isPresented: $showingThemeSettings) {
            ThemeSettingsView()
        }
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
                notificationManager.checkNotificationStatus()
            }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("To receive daily reminders, allow notifications in Settings.")
        }
        .alert("Clear Cache", isPresented: $showingCacheAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAppCache()
                showingCacheConfirmation = true
            }
        } message: {
            Text("This will clear cached data and refresh widgets. Favorites and planned events stay intact.")
        }
        .alert("Cache Cleared", isPresented: $showingCacheConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Cached data has been cleared successfully.")
        }
        .onAppear {
            notificationManager.checkNotificationStatus()
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SETTINGS")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundColor(Color.themeSecondaryText)

                    Text("Keep it clean")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)

                    Text("Adjust the app, revisit saved ideas, and manage the essentials.")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()
            }

        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.themeCardBackground.opacity(0.96), Color.themePrimary.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.themeDivider.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var appearanceSection: some View {
        settingsGroup(
            title: "Appearance",
            subtitle: "Keep the app aligned with the way you want it to feel."
        ) {
            settingsButtonRow(
                icon: "paintpalette.fill",
                iconColor: Color.themePrimary,
                title: "App Theme",
                subtitle: themeManager.currentTheme.name
            ) {
                showingThemeSettings = true
            }
        }
    }

    private var quotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quotes")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text("Keep the ideas worth returning to.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    showingFavorites = true
                }) {
                    utilityCard(
                        title: "Favorites",
                        subtitle: quoteService.favorites.isEmpty ? "Nothing saved yet" : "\(quoteService.favorites.count) saved",
                        value: "\(quoteService.favorites.count)",
                        icon: "heart.fill",
                        tint: Color.themeError
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    showingCategories = true
                }) {
                    utilityCard(
                        title: "Categories",
                        subtitle: "Browse by theme",
                        value: "\(quoteService.getAllCategories().count)",
                        icon: "square.grid.2x2.fill",
                        tint: Color.themeSecondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var appSection: some View {
        settingsGroup(
            title: "App",
            subtitle: "Notifications and widget help in one place."
        ) {
            settingsToggleRow(
                icon: "bell.fill",
                iconColor: Color.themePrimary,
                title: "Daily Quote Reminder",
                subtitle: notificationManager.isNotificationsEnabled ? "On" : "Off",
                isOn: Binding(
                    get: { notificationManager.isNotificationsEnabled },
                    set: { newValue in
                        if newValue {
                            checkAndRequestNotificationPermission()
                        } else {
                            notificationManager.toggleNotifications(false)
                        }
                    }
                )
            )

            if notificationManager.isNotificationsEnabled {
                Divider()
                    .background(Color.themeDivider.opacity(0.3))
                    .padding(.horizontal, 16)

                HStack {
                    settingsLeading(icon: "clock.fill", color: Color.themePrimary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reminder Time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.themeText)

                        Text("Choose when the daily prompt appears.")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }

                    Spacer()

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
                .background(Color.themeDivider.opacity(0.3))
                .padding(.horizontal, 16)

            settingsButtonRow(
                icon: "square.grid.2x2.fill",
                iconColor: Color.themeSecondary,
                title: "Widget Guide",
                subtitle: "See what works best on your Home Screen."
            ) {
                showingWidgetGuide = true
            }
        }
    }

    private var supportSection: some View {
        settingsGroup(
            title: "Support",
            subtitle: "Help, policies, and app housekeeping."
        ) {
            settingsButtonRow(
                icon: "info.circle",
                iconColor: Color.themePrimary,
                title: "About",
                subtitle: "What Motii is built for."
            ) {
                showingAbout = true
            }

            sectionDivider

            settingsButtonRow(
                icon: "lock.shield",
                iconColor: Color.themeSecondary,
                title: "Privacy Policy",
                subtitle: "How your data is handled."
            ) {
                showingPrivacyPolicy = true
            }

            sectionDivider

            settingsButtonRow(
                icon: "doc.text",
                iconColor: Color.themeSecondaryText,
                title: "Terms of Service",
                subtitle: "Read the usage terms."
            ) {
                showingTerms = true
            }

            sectionDivider

            settingsButtonRow(
                icon: "envelope",
                iconColor: Color.themeSuccess,
                title: "Send Feedback",
                subtitle: "Tell me what should improve next."
            ) {
                showingFeedback = true
            }

            sectionDivider

            settingsButtonRow(
                icon: "square.and.arrow.up",
                iconColor: Color.themePrimary,
                title: "Share App",
                subtitle: "Send Motii to someone else."
            ) {
                showingShare = true
            }

            sectionDivider

            Button(action: {
                showingCacheAlert = true
            }) {
                HStack {
                    settingsLeading(icon: "trash", color: Color.themeError)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clear Cache")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.themeError)

                        Text("Refresh temporary data without removing favorites or plans.")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }

                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
            }
            .buttonStyle(.plain)
        }
    }

    private var appInfoView: some View {
        VStack(spacing: 8) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 28))
                .foregroundColor(Color.themeText.opacity(0.45))
                .padding(.bottom, 4)

            Text("Motii")
                .font(.headline)
                .foregroundColor(Color.themeText)

            Text("Version 1.1.1")
                .font(.caption)
                .foregroundColor(Color.themeText.opacity(0.5))

            Text("© 2025 Motii Team")
                .font(.caption2)
                .foregroundColor(Color.themeText.opacity(0.3))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var sectionDivider: some View {
        Divider()
            .background(Color.themeDivider.opacity(0.3))
            .padding(.horizontal, 16)
    }

    private func settingsGroup<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            VStack(spacing: 0) {
                content()
            }
            .background(Color.themeCardBackground.opacity(0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private func settingsButtonRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                settingsLeading(icon: icon, color: iconColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.themeText.opacity(0.25))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private func settingsToggleRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack {
            settingsLeading(icon: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                .labelsHidden()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    private func settingsLeading(icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .foregroundColor(color)
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 18, height: 18)
            .padding(8)
            .background(color.opacity(0.15))
            .clipShape(Circle())
    }

    private func utilityCard(
        title: String,
        subtitle: String,
        value: String,
        icon: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeText)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.themeText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .padding(18)
        .background(Color.themeBackground.opacity(0.26))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func checkAndRequestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    notificationManager.requestNotificationPermission { granted in
                        if !granted {
                            showingPermissionAlert = true
                        }
                    }
                case .denied:
                    showingPermissionAlert = true
                case .authorized, .provisional, .ephemeral:
                    notificationManager.toggleNotifications(true)
                @unknown default:
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func clearAppCache() {
        do {
            let fileManager = FileManager.default
            let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let cacheContents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)

            for url in cacheContents {
                try fileManager.removeItem(at: url)
            }

            let defaults = UserDefaults.standard
            if let bundleID = Bundle.main.bundleIdentifier {
                defaults.dictionaryRepresentation().keys.forEach { key in
                    let keysToPreserve = [
                        "savedFavorites",
                        "savedEvents",
                        "notificationsEnabled",
                        "reminderTime",
                        "streak_lastOpenDate",
                        "streak_currentStreak",
                        "streak_longestStreak",
                        "streak_daysRecord",
                        "selectedThemeId"
                    ]
                    if !keysToPreserve.contains(key) && key.hasPrefix(bundleID) {
                        defaults.removeObject(forKey: key)
                    }
                }
            }

            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
}
