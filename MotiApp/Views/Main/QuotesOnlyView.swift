import SwiftUI

/// Quotes-only view - focused on motivational quotes
struct QuotesOnlyView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var quote: Quote
    @State private var showingShareSheet = false
    
    init() {
        // Initialize with today's quote
        _quote = State(initialValue: QuoteService.shared.getTodaysQuote())
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.themeBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    // Quote of the day section
                    VStack(spacing: 20) {
                        Text("QUOTE OF THE DAY")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                            .tracking(2)
                            .padding(.top, 20)
                        
                        // Main quote card
                        VStack(spacing: 20) {
                            Text(quote.text)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color.themeText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Text("— \(quote.author)")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.bottom, 20)
                            
                            // Action Buttons
                            HStack(spacing: 40) {
                                // Favorite Button
                                Button(action: {
                                    if quoteService.isFavorite(quote) {
                                        quoteService.removeFromFavorites(quote)
                                    } else {
                                        quoteService.addToFavorites(quote)
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: quoteService.isFavorite(quote) ? "heart.fill" : "heart")
                                            .font(.system(size: 24))
                                            .foregroundColor(quoteService.isFavorite(quote) ? Color.themeError : Color.themeText)
                                        
                                        Text(quoteService.isFavorite(quote) ? "Saved" : "Save")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                    }
                                }
                                
                                // Refresh Button
                                Button(action: {
                                    withAnimation {
                                        quote = quoteService.getRandomQuote()
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.themeText)
                                        
                                        Text("New")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                    }
                                }
                                
                                // Share Button
                                Button(action: {
                                    showingShareSheet = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.themeText)
                                        
                                        Text("Share")
                                            .font(.caption)
                                            .foregroundColor(Color.themeSecondaryText)
                                    }
                                }
                            }
                            .padding(.bottom, 10)
                        }
                        .padding(.vertical, 30)
                        .padding(.horizontal, 20)
                        .background(Color.themeCardBackground)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                    }
                    
                    // Divider
                    Divider()
                        .background(Color.themeDivider)
                        .padding(.horizontal, 40)
                    
                    // Quick access section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("EXPLORE")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            // Favorites
                            NavigationLink(destination: FavoritesView()) {
                                QuickAccessCard(
                                    icon: "heart.fill",
                                    title: "Favorites",
                                    count: quoteService.favorites.count,
                                    color: Color.themeError
                                )
                            }
                            
                            // Categories
                            NavigationLink(destination: CategoriesView()) {
                                QuickAccessCard(
                                    icon: "square.grid.2x2",
                                    title: "Categories",
                                    count: quoteService.getAllCategories().count,
                                    color: Color.themeSecondary
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Quote stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR COLLECTION")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                            .tracking(2)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            StatCard(
                                icon: "heart.fill",
                                iconColor: Color.themeError,
                                value: "\(quoteService.favorites.count)",
                                label: "Favorites"
                            )
                            
                            StatCard(
                                icon: "folder.fill",
                                iconColor: Color.themePrimary,
                                value: "\(quoteService.getAllCategories().count)",
                                label: "Categories"
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
        }
    }
}

// MARK: - Supporting Views

struct QuickAccessCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
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
}

// MARK: - Preview

struct QuotesOnlyView_Previews: PreviewProvider {
    static var previews: some View {
        QuotesOnlyView()
            .preferredColorScheme(.dark)
    }
}
