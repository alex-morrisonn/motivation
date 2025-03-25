import SwiftUI

// More view with additional app features
struct MoreView: View {
    @ObservedObject var quoteService = QuoteService.shared
    @ObservedObject var eventService = EventService.shared
    
    @State private var showingAbout = false
    @State private var showingSettings = false
    @State private var showingFeedback = false
    @State private var showingShare = false
    @State private var isDarkModeEnabled = true
    @State private var notificationsEnabled = true
    @State private var selectedReminderTime = Date()
    @State private var selectedCategories: Set<String> = []
    
    // Main components for the More view
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("More")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // User profile section
                    UserProfileSection()
                    
                    // Stats section
                    StatsSection(
                        favoriteCount: quoteService.favorites.count,
                        eventCount: eventService.events.count,
                        streakCount: 7 // This would ideally be tracked elsewhere
                    )
                    
                    // Features section
                    MoreFeaturesSection(
                        onSettingsTapped: { showingSettings.toggle() },
                        onAboutTapped: { showingAbout.toggle() },
                        onFeedbackTapped: { showingFeedback.toggle() },
                        onShareTapped: { showingShare.toggle() }
                    )
                    
                    // Categories section
                    CategoriesSection(
                        categories: quoteService.getAllCategories(),
                        selectedCategories: $selectedCategories
                    )
                    
                    // App info
                    AppInfoSection()
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                isDarkModeEnabled: $isDarkModeEnabled,
                notificationsEnabled: $notificationsEnabled,
                selectedReminderTime: $selectedReminderTime
            )
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
    }
}

// User profile section
struct UserProfileSection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.white)
            
            Text("Daily Inspiration")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Personalize your experience")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// Stats section
struct StatsSection: View {
    let favoriteCount: Int
    let eventCount: Int
    let streakCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Favorites stat
            StatItemView(
                icon: "heart.fill",
                color: .red,
                value: "\(favoriteCount)",
                label: "Favorites"
            )
            
            // Events stat
            StatItemView(
                icon: "calendar",
                color: .blue,
                value: "\(eventCount)",
                label: "Events"
            )
            
            // Streak stat
            StatItemView(
                icon: "flame.fill",
                color: .orange,
                value: "\(streakCount)",
                label: "Day Streak"
            )
        }
        .padding(.horizontal)
    }
}

// Individual stat item
struct StatItemView: View {
    let icon: String
    let color: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(16)
    }
}

// Features section
struct MoreFeaturesSection: View {
    var onSettingsTapped: () -> Void
    var onAboutTapped: () -> Void
    var onFeedbackTapped: () -> Void
    var onShareTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("FEATURES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Settings option
            MoreOptionRow(
                icon: "gear",
                title: "Settings",
                subtitle: "Customize app preferences",
                action: onSettingsTapped
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal)
            
            // About option
            MoreOptionRow(
                icon: "info.circle",
                title: "About",
                subtitle: "Learn more about Moti",
                action: onAboutTapped
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal)
            
            // Feedback option
            MoreOptionRow(
                icon: "envelope",
                title: "Send Feedback",
                subtitle: "Help us improve",
                action: onFeedbackTapped
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal)
            
            // Share option
            MoreOptionRow(
                icon: "square.and.arrow.up",
                title: "Share App",
                subtitle: "Spread motivation",
                action: onShareTapped
            )
        }
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// More option row component
struct MoreOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

// Categories section
struct CategoriesSection: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    
    var body: some View {
        VStack(spacing: 8) {
            Text("PREFERRED CATEGORIES")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 4)
            
            Text("Select your favorite categories for personalized content")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            VStack(spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    CategoryToggleRow(
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
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGray6).opacity(0.2))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
}

// Category toggle row
struct CategoryToggleRow: View {
    let category: String
    let isSelected: Bool
    var onToggle: () -> Void
    
    // Color mapping for category backgrounds - reusing from the main app
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Success & Achievement":
            return Color.blue.opacity(0.7)
        case "Life & Perspective":
            return Color.purple.opacity(0.7)
        case "Dreams & Goals":
            return Color.green.opacity(0.7)
        case "Courage & Confidence":
            return Color.orange.opacity(0.7)
        case "Perseverance & Resilience":
            return Color.red.opacity(0.7)
        case "Growth & Change":
            return Color.teal.opacity(0.7)
        case "Action & Determination":
            return Color.indigo.opacity(0.7)
        case "Mindset & Attitude":
            return Color.pink.opacity(0.7)
        case "Focus & Discipline":
            return Color.yellow.opacity(0.7)
        default:
            return Color.gray.opacity(0.7)
        }
    }
    
    // Icon mapping for categories - reusing from the main app
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Success & Achievement":
            return "trophy"
        case "Life & Perspective":
            return "scope"
        case "Dreams & Goals":
            return "sparkles"
        case "Courage & Confidence":
            return "bolt.heart"
        case "Perseverance & Resilience":
            return "figure.walk"
        case "Growth & Change":
            return "leaf"
        case "Action & Determination":
            return "flag"
        case "Mindset & Attitude":
            return "brain"
        case "Focus & Discipline":
            return "target"
        default:
            return "quote.bubble"
        }
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Category icon
                Image(systemName: iconForCategory(category))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(colorForCategory(category))
                    .clipShape(Circle())
                
                Text(category)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.system(size: 20))
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }
}

// App info section
struct AppInfoSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Moti")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Version 1.0")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("© 2025 Moti Team")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Additional Views

// Settings View
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isDarkModeEnabled: Bool
    @Binding var notificationsEnabled: Bool
    @Binding var selectedReminderTime: Date
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    List {
                        Section(header: Text("Appearance").foregroundColor(.gray)) {
                            Toggle("Dark Mode", isOn: $isDarkModeEnabled)
                                .tint(.white)
                        }
                        .listRowBackground(Color(UIColor.systemGray6).opacity(0.2))
                        
                        Section(header: Text("Notifications").foregroundColor(.gray)) {
                            Toggle("Daily Quote Reminder", isOn: $notificationsEnabled)
                                .tint(.white)
                            
                            if notificationsEnabled {
                                DatePicker("Reminder Time", selection: $selectedReminderTime, displayedComponents: .hourAndMinute)
                            }
                        }
                        .listRowBackground(Color(UIColor.systemGray6).opacity(0.2))
                        
                        Section(header: Text("Storage").foregroundColor(.gray)) {
                            Button(action: {
                                // This would clear the app's cache
                            }) {
                                Text("Clear Cache")
                                    .foregroundColor(.red)
                            }
                        }
                        .listRowBackground(Color(UIColor.systemGray6).opacity(0.2))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .padding(.top, 30)
                        
                        Text("Moti")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                        
                        Text("About Moti")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        Text("Moti is a daily motivation companion designed to inspire and encourage you through life's journey. With a collection of carefully curated quotes across multiple categories, Moti helps you stay focused, positive, and motivated.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                            .multilineTextAlignment(.leading)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            FeaturesRow(icon: "quote.bubble", title: "Daily Quotes", description: "A new inspirational quote each day")
                            FeaturesRow(icon: "calendar", title: "Event Tracking", description: "Keep track of important dates and events")
                            FeaturesRow(icon: "square.grid.2x2", title: "Home & Lock Screen Widgets", description: "Quick inspiration at a glance")
                            FeaturesRow(icon: "heart", title: "Favorites Collection", description: "Save quotes that resonate with you")
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Features row for About view
struct FeaturesRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

// Feedback View
struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackText = ""
    @State private var feedbackType = 0
    @State private var contactEmail = ""
    @State private var includeDeviceInfo = true
    @State private var showingConfirmation = false
    
    private let feedbackTypes = ["General Feedback", "Bug Report", "Feature Request", "Question"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Feedback type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Feedback Type", selection: $feedbackType) {
                                ForEach(0..<feedbackTypes.count, id: \.self) { index in
                                    Text(feedbackTypes[index]).tag(index)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .colorScheme(.dark)
                        }
                        .padding(.horizontal)
                        
                        // Feedback text editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Feedback")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ZStack(alignment: .topLeading) {
                                if feedbackText.isEmpty {
                                    Text("Please enter your feedback here...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.top, 8)
                                }
                                
                                TextEditor(text: $feedbackText)
                                    .foregroundColor(.white)
                                    .frame(minHeight: 150)
                                    .background(Color(UIColor.systemGray6).opacity(0.2))
                                    .cornerRadius(8)
                                    .colorScheme(.dark)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Contact email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Email (Optional)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Your email address", text: $contactEmail)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                .cornerRadius(8)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.horizontal)
                        
                        // Include device info toggle
                        Toggle(isOn: $includeDeviceInfo) {
                            Text("Include Device Information")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .tint(.white)
                        
                        // Submit button
                        Button(action: {
                            showingConfirmation = true
                            // In a real app, this would send the feedback to a server
                        }) {
                            Text("Submit Feedback")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    feedbackText.isEmpty ?
                                        Color.gray :
                                        Color.white
                                )
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .disabled(feedbackText.isEmpty)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 20)
                }
                .alert(isPresented: $showingConfirmation) {
                    Alert(
                        title: Text("Thank You!"),
                        message: Text("Your feedback has been submitted. We appreciate your input!"),
                        dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Preview
struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView()
    }
}
