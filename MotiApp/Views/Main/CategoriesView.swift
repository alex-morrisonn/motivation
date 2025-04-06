import SwiftUI

// Categories View for browsing quotes by category
struct CategoriesView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var selectedCategory: String? = nil
    @State private var showingShareSheet = false
    @State private var quoteToShare: Quote?
    
    // Constants for consistent sizing
    private let contentMaxWidth: CGFloat = 650
    private let cardPadding: CGFloat = 16
    
    var body: some View {
        ZStack {
            // Background for entire view
            Color.black.edgesIgnoringSafeArea(.all)
            
            // GeometryReader to handle responsive sizing
            GeometryReader { geometry in
                if let category = selectedCategory {
                    // CATEGORY DETAIL VIEW - Show quotes for the selected category
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
                            // Center content on iPad with constrained width
                            HStack {
                                Spacer(minLength: 0)
                                
                                // Content container
                                VStack(spacing: 30) {
                                    let categoryQuotes = quoteService.getQuotes(forCategory: category)
                                    
                                    // Loop through quotes and insert native ads
                                    ForEach(Array(categoryQuotes.enumerated()), id: \.element.id) { index, quote in
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
                                        
                                        // Insert native ad after every 5 quotes if not premium
                                        if (index + 1) % 5 == 0 && index < categoryQuotes.count - 1 && !AdManager.shared.isPremiumUser {
                                            NativeAdView()
                                        }
                                    }
                                }
                                .frame(width: min(geometry.size.width, contentMaxWidth))
                                .padding(.vertical)
                                .padding(.bottom, AdManager.shared.isPremiumUser ? 30 : 110)
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .overlay(
                        VStack {
                            HStack {
                                Button(action: {
                                    selectedCategory = nil
                                    
                                    // Check if we should show an interstitial ad when exiting category
                                    InterstitialAdCoordinator.shared.checkForExitInterstitial(from: "CategoriesView")
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
                    // CATEGORIES LIST VIEW - Show categories grid
                    ScrollView {
                        // Center content on iPad with constrained width
                        HStack {
                            Spacer(minLength: 0)
                            
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
                                
                                // Categories list
                                VStack(spacing: 16) {
                                    ForEach(Array(quoteService.getAllCategories().enumerated()), id: \.element) { index, category in
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
                                        
                                        // Insert native ad after every 4 categories if not premium
                                        if (index + 1) % 4 == 0 && index < quoteService.getAllCategories().count - 1 && !AdManager.shared.isPremiumUser {
                                            NativeAdView()
                                        }
                                    }
                                }
                                .padding(.vertical)
                                // Add extra padding at the bottom for the banner ad
                                .padding(.bottom, AdManager.shared.isPremiumUser ? 30 : 110)
                            }
                            .frame(width: min(geometry.size.width, contentMaxWidth))
                            
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let quote = quoteToShare {
                ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
            }
        }
        .onAppear {
            // Track screen view for ad rotation
            _ = InterstitialAdCoordinator.shared.trackNavigation()
        }
    }
    
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
}

// SwiftUI Preview
struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CategoriesView()
                .previewDevice("iPhone 14 Pro")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPhone")
            
            CategoriesView()
                .previewDevice("iPad Pro (11-inch)")
                .preferredColorScheme(.dark)
                .previewDisplayName("iPad")
        }
    }
}
