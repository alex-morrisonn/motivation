import SwiftUI

// Favorites View - Shows user's favorite quotes
struct FavoritesView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var showingShareSheet = false
    @State private var quoteToShare: Quote?
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if quoteService.favorites.isEmpty {
                // Empty state
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
                // List of favorites
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
                    // Add extra padding at the bottom for the banner ad
                    .padding(.bottom, 110)
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

// SwiftUI Preview
struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
            .preferredColorScheme(.dark)
    }
}
