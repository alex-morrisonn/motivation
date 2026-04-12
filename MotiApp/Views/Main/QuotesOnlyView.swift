import SwiftUI

/// Quotes-only view - focused on motivational quotes
struct QuotesOnlyView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var quote: Quote
    @State private var showingShareSheet = false

    init() {
        _quote = State(initialValue: QuoteService.shared.getTodaysQuote())
    }

    var body: some View {
        NavigationStack {
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
                        overviewCard
                        quoteCard
                        librarySection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
            }
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("QUOTE")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundColor(Color.themeSecondaryText)

                    Text("Keep your direction")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)

                    Text("A clear thought for the day, so action stays intentional.")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        quote = quoteService.getRandomQuote()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.themeText)
                        .frame(width: 44, height: 44)
                        .background(Color.themeBackground.opacity(0.28))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                overviewPill(
                    title: "Category",
                    value: quote.category,
                    symbol: "quote.bubble",
                    tint: Color.themePrimary
                )

                overviewPill(
                    title: "Saved",
                    value: "\(quoteService.favorites.count)",
                    symbol: "heart.fill",
                    tint: Color.themeError
                )
            }
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

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Today’s Perspective")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Spacer()

                Text(quote.category.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color.themePrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.themePrimary.opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "quote.opening")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color.themePrimary)

                Text(quote.text)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(Color.themeText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("— \(quote.author)")
                    .font(.headline)
                    .foregroundColor(Color.themeSecondaryText)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Take it with you")
                    .font(.caption.weight(.semibold))
                    .tracking(1.6)
                    .foregroundColor(Color.themeSecondaryText)

                Text(reflectionLine)
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Applying this sends it into today’s discipline flow so you can act on it instead of just admiring it.")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                quoteActionButton(
                    title: "Apply to Today",
                    systemImage: "sparkles.rectangle.stack.fill",
                    tint: Color.themePrimary,
                    background: Color.themePrimary.opacity(0.12)
                ) {
                    applyQuoteToToday()
                }

                quoteActionButton(
                    title: quoteService.isFavorite(quote) ? "Saved" : "Save",
                    systemImage: quoteService.isFavorite(quote) ? "heart.fill" : "heart",
                    tint: quoteService.isFavorite(quote) ? Color.themeError : Color.themeText,
                    background: quoteService.isFavorite(quote) ? Color.themeError.opacity(0.14) : Color.themeBackground.opacity(0.32)
                ) {
                    toggleFavorite()
                }

                quoteActionButton(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    tint: Color.themeText,
                    background: Color.themeBackground.opacity(0.32)
                ) {
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

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep Close")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text("Save the lines worth returning to.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Text("\(quoteService.favorites.count) saved")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            HStack(spacing: 12) {
                NavigationLink(destination: FavoritesView()) {
                    QuoteUtilityCard(
                        title: "Favorites",
                        subtitle: quoteService.favorites.isEmpty ? "Save the best ones" : "\(quoteService.favorites.count) quotes kept",
                        value: "\(quoteService.favorites.count)",
                        systemImage: "heart.fill",
                        tint: Color.themeError
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: CategoriesView()) {
                    QuoteUtilityCard(
                        title: "Categories",
                        subtitle: "Browse by mindset",
                        value: "\(quoteService.getAllCategories().count)",
                        systemImage: "square.grid.2x2.fill",
                        tint: Color.themeSecondary
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var reflectionLine: String {
        switch quote.category.lowercased() {
        case "discipline":
            return "Use this as your standard for the day. Keep showing up even when the feeling is absent."
        case "success":
            return "Treat this as a prompt to move, not just a line to admire. One action is enough to begin."
        case "mindset":
            return "Let this shape your attitude before you shape your schedule."
        case "focus":
            return "Come back to this when attention drifts. Simplicity beats force."
        default:
            return "Take one useful idea from this and carry it into your next action."
        }
    }

    private func overviewPill(title: String, value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 38, height: 38)

                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.themeText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.themeBackground.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private func applyQuoteToToday() {
        let option = quoteService.suggestedTaskOption(for: quote, focus: profileManager.focus)
        DisciplineSystemState.shared.updateTodayTask(for: option.category, optionID: option.id)
        Haptics.success()
        NotificationCenter.default.post(
            name: .quoteAppliedToToday,
            object: nil,
            userInfo: [AppNotification.quoteTaskTitleUserInfoKey: option.title]
        )
        NotificationCenter.default.post(
            name: .tabSelectionChanged,
            object: nil,
            userInfo: [AppNotification.selectedTabUserInfoKey: 0]
        )
    }
}

private struct QuoteUtilityCard: View {
    let title: String
    let subtitle: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                    .frame(width: 48, height: 48)

                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tint)
            }

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
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
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .padding(18)
        .background(Color.themeBackground.opacity(0.26))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct QuotesOnlyView_Previews: PreviewProvider {
    static var previews: some View {
        QuotesOnlyView()
            .preferredColorScheme(.dark)
    }
}
