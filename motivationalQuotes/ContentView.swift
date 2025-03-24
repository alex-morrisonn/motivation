// Categories View
struct CategoriesView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var selectedCategory: String?
    @State private var showingShareSheet = false
    @State private var quoteToShare: Quote?
    
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
                        LazyVStack(spacing: 60) {
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
                // Show categories list
                VStack {
                    Text("Categories")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(quoteService.getAllCategories(), id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack {
                                        Text(category)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text("\(quoteService.getQuotes(forCategory: category).count)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(10)
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

import SwiftUI
import UIKit

// Quote Model
struct Quote: Identifiable, Codable, Equatable {
    var id = UUID()
    let text: String
    let author: String
    let category: String
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        return lhs.id == rhs.id
    }
}

// Quote Service
class QuoteService: ObservableObject {
    static let shared = QuoteService()
    
    // Local quotes data source
    private let quotes: [Quote] = [
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Success"),
        Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon", category: "Life"),
        Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", category: "Dreams"),
        Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Confidence"),
        Quote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius", category: "Perseverance"),
        Quote(text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs", category: "Life"),
        Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker", category: "Ambition"),
        Quote(text: "Success is not final, failure is not fatal: It is the courage to continue that counts.", author: "Winston Churchill", category: "Perseverance"),
        Quote(text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein", category: "Perspective"),
        Quote(text: "The only limit to our realization of tomorrow will be our doubts of today.", author: "Franklin D. Roosevelt", category: "Confidence"),
        Quote(text: "The purpose of our lives is to be happy.", author: "Dalai Lama", category: "Happiness"),
        Quote(text: "Don't count the days, make the days count.", author: "Muhammad Ali", category: "Life"),
        Quote(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney", category: "Action"),
        Quote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis", category: "Dreams"),
        Quote(text: "Be the change that you wish to see in the world.", author: "Mahatma Gandhi", category: "Change"),
        Quote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar", category: "Growth"),
        Quote(text: "If you want to live a happy life, tie it to a goal, not to people or things.", author: "Albert Einstein", category: "Happiness"),
        Quote(text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson", category: "Self-Awareness"),
        Quote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela", category: "Resilience"),
        Quote(text: "Life is 10% what happens to us and 90% how we react to it.", author: "Charles R. Swindoll", category: "Perspective"),
        Quote(text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky", category: "Risk"),
        Quote(text: "Whether you think you can or you think you can't, you're right.", author: "Henry Ford", category: "Mindset"),
        Quote(text: "I have not failed. I've just found 10,000 ways that won't work.", author: "Thomas Edison", category: "Failure"),
        Quote(text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu", category: "Action"),
        Quote(text: "Every moment is a fresh beginning.", author: "T.S. Eliot", category: "New Beginnings"),
        Quote(text: "Start each day with a positive thought and a grateful heart.", author: "Roy T. Bennett", category: "Gratitude")
    ]
    
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

// Home Quote View
struct HomeQuoteView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var quote: Quote
    @State private var showingShareSheet = false
    
    init() {
        // Initialize with today's quote
        _quote = State(initialValue: QuoteService.shared.getTodaysQuote())
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
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
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
        }
    }
}

// Main ContentView
struct ContentView: View {
    @State private var selectedTab = 0
    
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
                
                // Widgets Tab
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    Text("Widgets")
                        .foregroundColor(.white)
                }
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Widgets")
                }
                .tag(3)
                
                // More Tab
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    Text("More")
                        .foregroundColor(.white)
                }
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
    }
}
