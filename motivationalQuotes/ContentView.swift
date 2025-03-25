import SwiftUI
import UIKit
import UserNotifications

// Quote Model
struct Quote: Identifiable, Codable, Equatable {
    var id = UUID()
    let text: String
    let author: String
    let category: String
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Constructor to create from SharedQuote
    init(from sharedQuote: SharedQuote) {
        self.id = sharedQuote.id
        self.text = sharedQuote.text
        self.author = sharedQuote.author
        self.category = sharedQuote.category
    }
    
    // For creating quotes directly
    init(text: String, author: String, category: String) {
        self.text = text
        self.author = author
        self.category = category
    }
}

// Quote Service
class QuoteService: ObservableObject {
    static let shared = QuoteService()
    
    // Local quotes data source - now using the shared quotes
    private let quotes: [Quote] = SharedQuotes.all.map { Quote(from: $0) }
    
    // Favorites storage
    @Published var favorites: [Quote] = []
    
    init() {
        loadFavorites()
    }
    
    // Get all unique categories
    func getAllCategories() -> [String] {
        let categories = Set(quotes.map { $0.category })
        return Array(categories).sorted()
    }
    
    // Get quotes by category
    func getQuotes(forCategory category: String) -> [Quote] {
        return quotes.filter { $0.category == category }
    }
    
    // Save favorites to UserDefaults
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "savedFavorites")
        }
    }
    
    // Load favorites from UserDefaults
    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.data(forKey: "savedFavorites") {
            if let decodedFavorites = try? JSONDecoder().decode([Quote].self, from: savedFavorites) {
                favorites = decodedFavorites
                return
            }
        }
        favorites = [] // Default to empty array if no favorites found
    }
    
    // Add quote to favorites
    func addToFavorites(_ quote: Quote) {
        // Only add if not already in favorites
        if !favorites.contains(where: { $0.text == quote.text && $0.author == quote.author }) {
            favorites.append(quote)
            saveFavorites()
        }
    }
    
    // Remove quote from favorites
    func removeFromFavorites(_ quote: Quote) {
        favorites.removeAll(where: { $0.text == quote.text && $0.author == quote.author })
        saveFavorites()
    }
    
    // Check if a quote is in favorites
    func isFavorite(_ quote: Quote) -> Bool {
        return favorites.contains(where: { $0.text == quote.text && $0.author == quote.author })
    }
    
    // Function to get today's quote
    func getTodaysQuote() -> Quote {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use the day of the year to pick a quote
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) else {
            return quotes[0] // Fallback to first quote
        }
        
        // Use modulo to ensure we always get a valid index
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }
    
    // Function to get a random quote
    func getRandomQuote() -> Quote {
        let randomIndex = Int.random(in: 0..<quotes.count)
        return quotes[randomIndex]
    }
    
    // Function to get all quotes
    func getAllQuotes() -> [Quote] {
        return quotes
    }
    
    // Fallback quote in case of errors
    func getFallbackQuote() -> Quote {
        Quote(text: "There seems to be a problem loading today's quote.", author: "Try again later", category: "Error")
    }
}

// ShareSheet for sharing functionality
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

// Quote Card View (reusable component)
struct QuoteCardView: View {
    let quote: Quote
    let isFavorite: Bool
    var onFavoriteToggle: () -> Void
    var onShare: () -> Void
    var onRefresh: (() -> Void)?
    
    var body: some View {
        VStack {
            Text(quote.text)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("— \(quote.author)")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .padding(.top, 16)
                .padding(.bottom, 30)
            
            // Action Buttons - All on one line with equal spacing
            HStack {
                Spacer()
                
                // Favorite Button
                Button(action: {
                    onFavoriteToggle()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(isFavorite ? .red : .white)
                }
                
                Spacer()
                
                // Refresh Button (only if provided)
                if let refreshAction = onRefresh {
                    Button(action: {
                        refreshAction()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                // Share Button
                Button(action: {
                    onShare()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// Categories View
struct CategoriesView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var selectedCategory: String?
    @State private var showingShareSheet = false
    @State private var quoteToShare: Quote?
    
    // Color mapping for category backgrounds
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
    
    // Icon mapping for categories
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
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let category = selectedCategory {
                // Show quotes for the selected category
                VStack {
                    // Category title
                    Text(category)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                    // Quotes list
                    ScrollView {
                        LazyVStack(spacing: 30) {
                            let categoryQuotes = quoteService.getQuotes(forCategory: category)
                            
                            ForEach(categoryQuotes) { quote in
                                VStack(alignment: .leading, spacing: 15) {
                                    Text(quote.text)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text("— \(quote.author)")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Spacer()
                                        
                                        Button(action: {
                                            if quoteService.isFavorite(quote) {
                                                quoteService.removeFromFavorites(quote)
                                            } else {
                                                quoteService.addToFavorites(quote)
                                            }
                                        }) {
                                            Image(systemName: quoteService.isFavorite(quote) ? "heart.fill" : "heart")
                                                .font(.system(size: 22))
                                                .foregroundColor(quoteService.isFavorite(quote) ? .red : .white)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            quoteToShare = quote
                                            showingShareSheet = true
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.system(size: 22))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(15)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    Spacer()
                }
                .overlay(
                    VStack {
                        HStack {
                            Button(action: {
                                selectedCategory = nil
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                                    .padding()
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                )
            } else {
                // Show categories list with improved UI
                VStack {
                    Text("Categories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    Text("Select a category to explore quotes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                            ForEach(quoteService.getAllCategories(), id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack {
                                        // Category icon
                                        Image(systemName: iconForCategory(category))
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 40, height: 40)
                                            .background(colorForCategory(category))
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(category)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text("\(quoteService.getQuotes(forCategory: category).count) quotes")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(UIColor.systemGray6).opacity(0.2))
                                    .cornerRadius(15)
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let quote = quoteToShare {
                ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
            }
        }
    }
}

// Favorites View
struct FavoritesView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var showingShareSheet = false
    @State private var quoteToShare: Quote?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if quoteService.favorites.isEmpty {
                VStack {
                    Image(systemName: "heart")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                        .padding()
                    Text("No favorites yet")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Tap the heart icon on any quote to add it to your favorites.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 30) {
                        ForEach(quoteService.favorites) { quote in
                            QuoteCardView(
                                quote: quote,
                                isFavorite: true,
                                onFavoriteToggle: {
                                    quoteService.removeFromFavorites(quote)
                                },
                                onShare: {
                                    quoteToShare = quote
                                    showingShareSheet = true
                                }
                            )
                            .padding(.vertical)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let quote = quoteToShare {
                ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
            }
        }
    }
}

// Home Quote View with Calendar
struct HomeQuoteView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @ObservedObject private var eventService = EventService.shared
    @State private var quote: Quote
    @State private var showingShareSheet = false
    @State private var showingEventEditor = false
    @State private var editingEvent: Event?
    @State private var selectedDate = Date()
    
    init() {
        // Initialize with today's quote
        _quote = State(initialValue: QuoteService.shared.getTodaysQuote())
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Quote of the day section
                    VStack {
                        Text("QUOTE OF THE DAY")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .tracking(2)
                            .padding(.top, 20)
                        
                        QuoteCardView(
                            quote: quote,
                            isFavorite: quoteService.isFavorite(quote),
                            onFavoriteToggle: {
                                if quoteService.isFavorite(quote) {
                                    quoteService.removeFromFavorites(quote)
                                } else {
                                    quoteService.addToFavorites(quote)
                                }
                            },
                            onShare: {
                                showingShareSheet = true
                            },
                            onRefresh: {
                                // Get a random quote instead of today's quote for more variety
                                quote = quoteService.getRandomQuote()
                            }
                        )
                    }
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 40)
                    
                    // Calendar section
                    VStack(spacing: 15) {
                        // Calendar title with add button
                        HStack {
                            Text("IMPORTANT DATES")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                editingEvent = nil
                                showingEventEditor = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Week calendar
                        CalendarWeekView(selectedDate: $selectedDate)
                            .padding(.vertical, 10)
                        
                        // Selected date title
                        HStack {
                            let formatter: DateFormatter = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "EEEE, MMMM d"
                                return formatter
                            }()
                            
                            Text(formatter.string(from: selectedDate))
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        
                        // Events for selected date
                        VStack(spacing: 10) {
                            let eventsForDay = eventService.getEvents(for: selectedDate)
                            
                            if eventsForDay.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                    
                                    Text("No events for this day")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        editingEvent = nil
                                        showingEventEditor = true
                                    }) {
                                        Text("Add Event")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                    }
                                    .padding(.top, 10)
                                    .padding(.bottom, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            } else {
                                ForEach(eventsForDay) { event in
                                    EventListItem(
                                        event: event,
                                        onComplete: {
                                            eventService.toggleCompletionStatus(event)
                                        },
                                        onDelete: {
                                            eventService.deleteEvent(event)
                                        },
                                        onEdit: {
                                            editingEvent = event
                                            showingEventEditor = true
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Upcoming events section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("UPCOMING EVENTS")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                                .padding(.top, 10)
                                .padding(.horizontal, 20)
                            
                            let upcomingEvents = eventService.getUpcomingEvents()
                            
                            if upcomingEvents.isEmpty {
                                Text("No upcoming events for the next 7 days")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ForEach(upcomingEvents) { event in
                                    EventListItem(
                                        event: event,
                                        onComplete: {
                                            eventService.toggleCompletionStatus(event)
                                        },
                                        onDelete: {
                                            eventService.deleteEvent(event)
                                        },
                                        onEdit: {
                                            editingEvent = event
                                            showingEventEditor = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 50) // Extra padding at bottom for better scrolling
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
        }
        .sheet(isPresented: $showingEventEditor) {
            if let event = editingEvent {
                EventEditorView(event: event)
            } else {
                EventEditorView(initialDate: selectedDate) // Pass selected date here
            }
        }
    }
}

// Main ContentView
struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var notificationManager: NotificationManager
    
    init() {
        // Set up the dark mode appearance
        UITabBar.appearance().backgroundColor = UIColor.black
    }
    
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
                
                // Categories Tab
                CategoriesView()
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Categories")
                    }
                    .tag(1)
                
                // Favorites Tab
                FavoritesView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Favorites")
                    }
                    .tag(2)
                
                // Widgets Tab - Updated to show WidgetsShowcaseView
                WidgetsShowcaseView()
                    .tabItem {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Widgets")
                    }
                    .tag(3)
                
                // More Tab - Now using the new MoreView
                MoreView()
                    .tabItem {
                        Image(systemName: "ellipsis")
                        Text("More")
                    }
                    .tag(4)
            }
            .accentColor(.white) // Active tab color
            .onAppear {
                // Increase contrast for unselected tab items
                let tabBarAppearance = UITabBarAppearance()
                tabBarAppearance.configureWithOpaqueBackground()
                tabBarAppearance.backgroundColor = UIColor.black
                
                // Make unselected items more visible
                tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.lightGray
                tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
                
                // Apply the appearance
                UITabBar.appearance().standardAppearance = tabBarAppearance
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
            
            // Add a subtle thin line at the top of the tab bar for better visual separation
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color.white.opacity(0.3))
                    .padding(.bottom, 49) // Tab bar height is typically 49 points
            }
        }
        .onOpenURL { url in
            if url.scheme == "moti" {
                if url.host == "calendar" {
                    // Navigate to calendar or home tab
                    self.selectedTab = 0
                } else if url.host == "quotes" {
                    // Navigate to quotes tab
                    self.selectedTab = 1
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenQuotesTab"))) { _ in
            // When a notification is tapped, navigate to the quotes tab
            self.selectedTab = 1 // Index of the Categories tab
        }
    }
}
