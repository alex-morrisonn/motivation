import SwiftUI

// Reusable Quote Card View component
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

// Preview provider for SwiftUI previews
struct QuoteCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            QuoteCardView(
                quote: Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker", category: "Success"),
                isFavorite: false,
                onFavoriteToggle: {},
                onShare: {},
                onRefresh: {}
            )
        }
    }
}
