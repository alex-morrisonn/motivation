import SwiftUI

struct WeeklyQuestCelebrationView: View {
    @ObservedObject private var gamification = GamificationManager.shared
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.themeBackground,
                    Color.themePrimary.opacity(0.35),
                    Color.themeBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.themePrimary.opacity(0.16))
                        .frame(width: 140, height: 140)

                    Image(systemName: "flag.checkered.2.crossed")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color.themePrimary)
                }

                VStack(spacing: 8) {
                    Text("Weekly Quest Complete")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)

                    Text(gamification.weeklyQuest.title)
                        .font(.headline)
                        .foregroundColor(Color.themePrimary)

                    Text("You finished this week's push. Keep going while the momentum is real.")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    statPill(title: "Quest", value: gamification.weeklyQuest.detail)
                    statPill(title: "Reward", value: "+ momentum, + clarity, + proof")
                }

                Spacer()

                Button(action: {
                    isShowing = false
                }) {
                    Text("Keep Going")
                        .font(.headline)
                        .foregroundColor(Color.themeBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.4)
                .foregroundColor(Color.themeSecondaryText)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.themeText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 24)
    }
}
