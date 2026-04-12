import SwiftUI

struct FavoritesView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var showingShareSheet = false
    @State private var quoteToShare: Quote?

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
                    headerCard

                    if quoteService.favorites.isEmpty {
                        emptyStateCard
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(quoteService.favorites) { quote in
                                favoriteQuoteCard(for: quote)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let quote = quoteToShare {
                ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FAVORITES")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(Color.themeSecondaryText)

            Text("Keep the lines that stay with you")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeText)

            Text(quoteService.favorites.isEmpty ? "Save quotes from the main Quotes tab and they will show up here." : "\(quoteService.favorites.count) saved quote\(quoteService.favorites.count == 1 ? "" : "s") ready to revisit.")
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)
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

    private var emptyStateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(Color.themeSecondaryText)

            Text("No favorites yet")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            Text("Tap the heart on any quote to build a small library worth returning to.")
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func favoriteQuoteCard(for quote: Quote) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(quote.category.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundColor(Color.themePrimary)

            Text(quote.text)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(Color.themeText)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(quote.author)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.themeSecondaryText)

            HStack(spacing: 12) {
                actionButton(
                    title: "Saved",
                    systemImage: "heart.fill",
                    tint: Color.themeError,
                    background: Color.themeError.opacity(0.12)
                ) {
                    quoteService.removeFromFavorites(quote)
                }

                actionButton(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    tint: Color.themeText,
                    background: Color.themeBackground.opacity(0.28)
                ) {
                    quoteToShare = quote
                    showingShareSheet = true
                }
            }
        }
        .padding(22)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func actionButton(
        title: String,
        systemImage: String,
        tint: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))

                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
