import SwiftUI

// Minimalistic More View with clean black and white theme
struct MoreView: View {
    @ObservedObject var quoteService = QuoteService.shared
    @ObservedObject var eventService = EventService.shared
    
    @State private var showingAbout = false
    @State private var showingSettings = false
    @State private var showingFeedback = false
    @State private var showingShare = false
    @State private var notificationsEnabled = true
    @State private var selectedReminderTime = Date()
    @State private var selectedCategories: Set<String> = []
    
    var body: some View {
        ZStack {
            // Black background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    // Stats cards with colors
                    HStack(spacing: 15) {
                        StatCard(
                            number: "\(quoteService.favorites.count)",
                            label: "Favorites",
                            icon: "heart"
                        )
                        
                        StatCard(
                            number: "\(eventService.events.count)",
                            label: "Events",
                            icon: "calendar"
                        )
                        
                        StatCard(
                            number: "7",
                            label: "Day Streak",
                            icon: "flame"
                        )
                    }
                    .padding(.top, 16)
                    
                    // Feature options section
                    VStack(spacing: 0) {
                        SectionHeader(title: "OPTIONS")
                        
                        // Section background
                        VStack(spacing: 0) {
                            OptionRow(
                                icon: "gear",
                                title: "Settings",
                                action: { showingSettings.toggle() }
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            OptionRow(
                                icon: "info.circle",
                                title: "About",
                                action: { showingAbout.toggle() }
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
        .sheet(isPresented: $showingSettings) {
            SettingsView(
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

// MARK: - Component Views

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
    
    // Get appropriate color for each stat type
    private var iconColor: Color {
        switch icon {
        case "heart": return .red
        case "calendar": return .blue
        case "flame": return .orange
        default: return .white
        }
    }
    
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

// MARK: - Additional Views (unchanged but included for reference)

// Settings View with dark mode option removed
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var notificationsEnabled: Bool
    @Binding var selectedReminderTime: Date
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    List {
                        Section(header: Text("NOTIFICATIONS").font(.caption).fontWeight(.semibold).foregroundColor(.white.opacity(0.6))) {
                            HStack {
                                Text("Daily Quote Reminder")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Custom toggle for notifications
                                ZStack {
                                    Capsule()
                                        .fill(notificationsEnabled ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 30)
                                    
                                    Circle()
                                        .fill(notificationsEnabled ? Color.white.opacity(0.9) : Color.gray.opacity(0.5))
                                        .frame(width: 26, height: 26)
                                        .offset(x: notificationsEnabled ? 10 : -10)
                                        .animation(.spring(response: 0.2), value: notificationsEnabled)
                                }
                                .onTapGesture {
                                    notificationsEnabled.toggle()
                                }
                            }
                            
                            if notificationsEnabled {
                                DatePicker("Reminder Time", selection: $selectedReminderTime, displayedComponents: .hourAndMinute)
                                    .foregroundColor(.white)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .accentColor(.white.opacity(0.7))
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                        
                        Section(header: Text("STORAGE").font(.caption).fontWeight(.semibold).foregroundColor(.white.opacity(0.6))) {
                            Button(action: {
                                // This would clear the app's cache
                            }) {
                                Text("Clear Cache")
                                    .foregroundColor(.red.opacity(0.9))
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.05))
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
                    .foregroundColor(.white)
                }
            }
        }
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
