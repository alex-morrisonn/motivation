import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

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
                        headerCard
                        storyCard
                        featureCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ABOUT")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(Color.themeSecondaryText)

            Text("Motii helps turn motivation into structure")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeText)

            Text("Quotes are useful, but only if they carry into action. The app is built to connect mindset, daily tasks, and a plan you can actually follow.")
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

    private var storyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What it is for")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            Text("Motii is designed to give each day a little more direction. It starts with a quote, pushes that into a practical focus, and keeps the plan visible through reminders, streaks, and widgets.")
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Core Features")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            VStack(spacing: 14) {
                featureRow(icon: "quote.bubble.fill", title: "Daily Quotes", description: "A focused thought for the day.")
                featureRow(icon: "flame.fill", title: "Discipline System", description: "Small actions that keep momentum visible.")
                featureRow(icon: "calendar.badge.clock", title: "Planning", description: "Turn ideas into scheduled steps.")
                featureRow(icon: "square.grid.2x2.fill", title: "Widgets", description: "Keep the app visible even when you are not inside it.")
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

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.themePrimary)
                .frame(width: 34, height: 34)
                .background(Color.themePrimary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            Spacer()
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
