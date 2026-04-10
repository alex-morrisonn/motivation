import SwiftUI

/// Quotes-only view - focused on motivational quotes
struct QuotesOnlyView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var quote: Quote
    @State private var showingShareSheet = false

    init() {
        _quote = State(initialValue: QuoteService.shared.getTodaysQuote())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        quoteHeader
                        quoteCard
                        librarySection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
            }
        }
    }

    private var quoteHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUOTE OF THE DAY")
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
                .tracking(2)

            Text("Read it, save it, or explore more when you want a different angle.")
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                Image(systemName: "quote.opening")
                    .font(.title3)
                    .foregroundColor(Color.themePrimary)

                Spacer()

                Text(quote.category.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.themePrimary.opacity(0.14))
                    .clipShape(Capsule())
            }

            VStack(spacing: 16) {
                Text(quote.text)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(Color.themeText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("— \(quote.author)")
                    .font(.headline)
                    .foregroundColor(Color.themeSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                quoteActionButton(
                    title: quoteService.isFavorite(quote) ? "Saved" : "Save",
                    systemImage: quoteService.isFavorite(quote) ? "heart.fill" : "heart",
                    tint: quoteService.isFavorite(quote) ? Color.themeError : Color.themeText,
                    background: quoteService.isFavorite(quote) ? Color.themeError.opacity(0.14) : Color.themeBackground.opacity(0.5)
                ) {
                    toggleFavorite()
                }

                quoteActionButton(
                    title: "New Quote",
                    systemImage: "arrow.clockwise",
                    tint: Color.themePrimary,
                    background: Color.themePrimary.opacity(0.14)
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        quote = quoteService.getRandomQuote()
                    }
                }

                quoteActionButton(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    tint: Color.themeText,
                    background: Color.themeBackground.opacity(0.5)
                ) {
                    showingShareSheet = true
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.themeCardBackground,
                    Color.themeCardBackground.opacity(0.88)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.6), lineWidth: 1)
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("YOUR LIBRARY")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .tracking(2)

                Spacer()

                Text("\(quoteService.favorites.count) saved")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            HStack(spacing: 16) {
                NavigationLink(destination: FavoritesView()) {
                    QuoteLibraryCard(
                        title: "Favorites",
                        subtitle: quoteService.favorites.isEmpty ? "Save quotes to build your list" : "\(quoteService.favorites.count) saved quotes",
                        value: "\(quoteService.favorites.count)",
                        systemImage: "heart.fill",
                        tint: Color.themeError
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: CategoriesView()) {
                    QuoteLibraryCard(
                        title: "Categories",
                        subtitle: "Browse by theme",
                        value: "\(quoteService.getAllCategories().count)",
                        systemImage: "square.grid.2x2.fill",
                        tint: Color.themeSecondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func quoteActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        background: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func toggleFavorite() {
        if quoteService.isFavorite(quote) {
            quoteService.removeFromFavorites(quote)
        } else {
            quoteService.addToFavorites(quote)
        }
    }
}

private struct QuoteLibraryCard: View {
    let title: String
    let subtitle: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 54, height: 54)

                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(tint)
            }

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
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
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
        .padding(20)
        .background(Color.themeCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.themeDivider.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(22)
    }
}

struct QuotesOnlyView_Previews: PreviewProvider {
    static var previews: some View {
        QuotesOnlyView()
            .preferredColorScheme(.dark)
    }
}
