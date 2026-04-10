import SwiftUI

struct ProgressJourneyView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var gamification = GamificationManager.shared
    @ObservedObject private var streakManager = StreakManager.shared

    @State private var animateRing = false
    @State private var animateStats = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        rankHeroCard
                        nextRankCard
                        statsGrid
                        journeyPath
                        recentAchievements
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Your Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                    animateRing = true
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                    animateStats = true
                }
            }
        }
    }

    // MARK: - Rank Hero Card

    private var rankHeroCard: some View {
        let rank = gamification.currentRank
        let rankColor = colorFromName(rank.color)

        return VStack(spacing: 20) {
            // Animated rank ring
            ZStack {
                // Outer glow
                Circle()
                    .fill(rankColor.opacity(0.08))
                    .frame(width: 180, height: 180)

                // Track ring
                Circle()
                    .stroke(Color.themeDivider.opacity(0.2), lineWidth: 8)
                    .frame(width: 150, height: 150)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateRing ? gamification.levelProgress : 0)
                    .stroke(
                        AngularGradient(
                            colors: [rankColor.opacity(0.5), rankColor, rankColor.opacity(0.8)],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))

                // Inner content
                VStack(spacing: 6) {
                    Image(systemName: rank.icon)
                        .font(.system(size: 32))
                        .foregroundColor(rankColor)

                    Text("\(gamification.currentLevel)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)
                }
            }

            VStack(spacing: 6) {
                Text(rank.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)

                Text("Level \(gamification.currentLevel)")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)

                // XP bar
                VStack(spacing: 6) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.themeDivider.opacity(0.2))
                                .frame(height: 10)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [rankColor, rankColor.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: max(10, geometry.size.width * (animateRing ? gamification.levelProgress : 0)),
                                    height: 10
                                )
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text("\(gamification.xpInCurrentLevel) XP")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(rankColor)

                        Spacer()

                        Text("\(gamification.xpToNextLevel) XP to level up")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            // Total XP
            Text("\(gamification.totalXP) Total XP")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeSecondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.themeBackground.opacity(0.5))
                .cornerRadius(20)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color.themeCardBackground,
                    Color.themeCardBackground.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(rankColor.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(24)
    }

    // MARK: - Next Rank Card

    private var nextRankCard: some View {
        Group {
            if let next = gamification.nextRank,
               let levelsLeft = gamification.levelsToNextRank,
               let xpLeft = gamification.xpToNextRank {
                let nextColor = colorFromName(next.color)

                HStack(spacing: 16) {
                    // Next rank icon (locked style)
                    ZStack {
                        Circle()
                            .fill(nextColor.opacity(0.1))
                            .frame(width: 56, height: 56)

                        Circle()
                            .stroke(nextColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                            .frame(width: 56, height: 56)

                        Image(systemName: next.icon)
                            .font(.system(size: 24))
                            .foregroundColor(nextColor.opacity(0.6))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("NEXT RANK")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeSecondaryText)
                            .tracking(1.5)

                        Text(next.name)
                            .font(.headline)
                            .foregroundColor(Color.themeText)

                        Text("\(levelsLeft) level\(levelsLeft == 1 ? "" : "s") away  ·  \(xpLeft) XP")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }

                    Spacer()

                    // Mini progress
                    let currentRankMin = gamification.currentRank.minLevel
                    let progress = Double(gamification.currentLevel - currentRankMin) / Double(next.minLevel - currentRankMin)

                    CircularProgressBadge(progress: progress, color: nextColor)
                }
                .padding(18)
                .background(Color.themeCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(nextColor.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(18)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR STATS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeSecondaryText)
                .tracking(1.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                JourneyStatCard(
                    value: "\(gamification.totalTasksCompleted)",
                    label: "Tasks Done",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    animate: animateStats
                )

                JourneyStatCard(
                    value: "\(gamification.totalPerfectDays)",
                    label: "Perfect Days",
                    icon: "star.fill",
                    color: .yellow,
                    animate: animateStats
                )

                JourneyStatCard(
                    value: "\(streakManager.currentStreak)",
                    label: "Current Streak",
                    icon: "flame.fill",
                    color: .orange,
                    animate: animateStats
                )

                JourneyStatCard(
                    value: "\(streakManager.longestStreak)",
                    label: "Best Streak",
                    icon: "crown.fill",
                    color: .purple,
                    animate: animateStats
                )
            }
        }
    }

    // MARK: - Journey Path

    private var journeyPath: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THE PATH")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeSecondaryText)
                .tracking(1.5)

            VStack(spacing: 0) {
                ForEach(Array(RankTier.all.enumerated()), id: \.offset) { index, tier in
                    let isCurrentOrPast = gamification.currentLevel >= tier.minLevel
                    let isCurrent = gamification.currentRank.minLevel == tier.minLevel
                    let tierColor = colorFromName(tier.color)

                    HStack(spacing: 16) {
                        // Vertical line + node
                        VStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(isCurrentOrPast ? tierColor.opacity(0.4) : Color.themeDivider.opacity(0.2))
                                    .frame(width: 2, height: 20)
                            } else {
                                Spacer().frame(height: 20)
                            }

                            ZStack {
                                Circle()
                                    .fill(isCurrentOrPast ? tierColor.opacity(0.2) : Color.themeDivider.opacity(0.1))
                                    .frame(width: isCurrent ? 44 : 36, height: isCurrent ? 44 : 36)

                                if isCurrent {
                                    Circle()
                                        .stroke(tierColor.opacity(0.5), lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                }

                                Image(systemName: tier.icon)
                                    .font(.system(size: isCurrent ? 20 : 16))
                                    .foregroundColor(isCurrentOrPast ? tierColor : Color.themeDivider.opacity(0.4))
                            }

                            if index < RankTier.all.count - 1 {
                                Rectangle()
                                    .fill(isCurrentOrPast ? tierColor.opacity(0.4) : Color.themeDivider.opacity(0.2))
                                    .frame(width: 2, height: 20)
                            } else {
                                Spacer().frame(height: 20)
                            }
                        }
                        .frame(width: 44)

                        // Rank info
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(tier.name)
                                    .font(isCurrent ? .headline : .subheadline)
                                    .fontWeight(isCurrent ? .bold : .medium)
                                    .foregroundColor(isCurrentOrPast ? Color.themeText : Color.themeSecondaryText.opacity(0.6))

                                if isCurrent {
                                    Text("YOU")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(tierColor)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(tierColor.opacity(0.15))
                                        .cornerRadius(6)
                                }
                            }

                            Text("Level \(tier.minLevel)+")
                                .font(.caption)
                                .foregroundColor(isCurrentOrPast ? Color.themeSecondaryText : Color.themeSecondaryText.opacity(0.4))
                        }

                        Spacer()

                        // Status indicator
                        if isCurrentOrPast && !isCurrent {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(tierColor.opacity(0.6))
                        } else if isCurrent {
                            Text("Lv.\(gamification.currentLevel)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(tierColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(tierColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
            .background(Color.themeCardBackground)
            .cornerRadius(20)
        }
    }

    // MARK: - Recent Achievements

    private var recentAchievements: some View {
        let unlocked = gamification.achievements
            .filter(\.isUnlocked)
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
        let nextToUnlock = gamification.achievements
            .filter { !$0.isUnlocked }
            .prefix(2)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ACHIEVEMENTS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeSecondaryText)
                    .tracking(1.5)

                Spacer()

                Text("\(unlocked.count)/\(gamification.achievements.count)")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            VStack(spacing: 10) {
                // Most recent unlocked (up to 3)
                ForEach(Array(unlocked.prefix(3)), id: \.id) { achievement in
                    AchievementRow(achievement: achievement, isUnlocked: true)
                }

                if !nextToUnlock.isEmpty {
                    Divider()
                        .background(Color.themeDivider.opacity(0.3))
                        .padding(.vertical, 4)

                    Text("UP NEXT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themeSecondaryText.opacity(0.6))
                        .tracking(1.2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Array(nextToUnlock), id: \.id) { achievement in
                        AchievementRow(achievement: achievement, isUnlocked: false)
                    }
                }
            }
            .padding(16)
            .background(Color.themeCardBackground)
            .cornerRadius(18)
        }
    }

    // MARK: - Helpers

    private func colorFromName(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "blue": return Color.themePrimary
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

private struct CircularProgressBadge: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 3)
                .frame(width: 40, height: 40)

            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
    }
}

private struct JourneyStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let animate: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color.themeText)
            }
            .scaleEffect(animate ? 1 : 0.8)
            .opacity(animate ? 1 : 0)

            Text(label)
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.themeCardBackground)
        .cornerRadius(14)
    }
}

private struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        let color = achievementColor(achievement.color)

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.15) : Color.themeDivider.opacity(0.1))
                    .frame(width: 42, height: 42)

                Image(systemName: achievement.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isUnlocked ? color : Color.themeDivider.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? Color.themeText : Color.themeSecondaryText.opacity(0.6))

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(isUnlocked ? Color.themeSecondaryText : Color.themeSecondaryText.opacity(0.4))
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(color)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.themeDivider.opacity(0.3))
            }
        }
    }

    private func achievementColor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "blue": return Color.themePrimary
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }
}

struct ProgressJourneyView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressJourneyView()
            .preferredColorScheme(.dark)
    }
}
