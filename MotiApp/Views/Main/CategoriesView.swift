import SwiftUI

struct CategoriesView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var selectedCategory: String?
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

                    if let selectedCategory {
                        categoryQuotesSection(for: selectedCategory)
                    } else {
                        categoryGrid
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let quote = quoteToShare {
                ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
            }
        }
        .navigationTitle(selectedCategory ?? "Categories")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(selectedCategory != nil)
        .toolbar {
            if selectedCategory != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        selectedCategory = nil
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CATEGORIES")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(Color.themeSecondaryText)

            Text(selectedCategory ?? "Browse by mindset")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeText)

            Text(selectedCategory == nil ? "Explore the quote library by the kind of thought you want more of." : "\(quoteService.getQuotes(forCategory: selectedCategory ?? "").count) quotes in this category.")
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

    private var categoryGrid: some View {
        LazyVStack(spacing: 14) {
            ForEach(quoteService.getAllCategories(), id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    HStack(spacing: 14) {
                        Image(systemName: iconForCategory(category))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(colorForCategory(category))
                            .frame(width: 42, height: 42)
                            .background(colorForCategory(category).opacity(0.16))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(category)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(Color.themeText)

                            Text("\(quoteService.getQuotes(forCategory: category).count) quotes")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.themeSecondaryText.opacity(0.7))
                    }
                    .padding(18)
                    .background(Color.themeCardBackground.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func categoryQuotesSection(for category: String) -> some View {
        VStack(spacing: 16) {
            ForEach(quoteService.getQuotes(forCategory: category)) { quote in
                VStack(alignment: .leading, spacing: 16) {
                    Text(quote.text)
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(Color.themeText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("— \(quote.author)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.themeSecondaryText)

                    HStack(spacing: 12) {
                        quoteActionButton(
                            title: quoteService.isFavorite(quote) ? "Saved" : "Save",
                            systemImage: quoteService.isFavorite(quote) ? "heart.fill" : "heart",
                            tint: quoteService.isFavorite(quote) ? Color.themeError : Color.themeText,
                            background: quoteService.isFavorite(quote) ? Color.themeError.opacity(0.12) : Color.themeBackground.opacity(0.28)
                        ) {
                            if quoteService.isFavorite(quote) {
                                quoteService.removeFromFavorites(quote)
                            } else {
                                quoteService.addToFavorites(quote)
                            }
                        }

                        quoteActionButton(
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

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Success & Achievement": return Color.blue
        case "Life & Perspective": return Color.themeSecondary
        case "Dreams & Goals": return Color.green
        case "Courage & Confidence": return Color.orange
        case "Perseverance & Resilience": return Color.red
        case "Growth & Change": return Color.teal
        case "Action & Determination": return Color.indigo
        case "Mindset & Attitude": return Color.pink
        case "Focus & Discipline": return Color.yellow
        default: return Color.themeSecondaryText
        }
    }
}

struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesView()
    }
}
