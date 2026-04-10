import SwiftUI

/// Main home view focused on the daily discipline system.
struct DisciplineHomeView: View {
    @StateObject private var disciplineSystem = DisciplineSystemState()
    @ObservedObject private var streakManager = StreakManager.shared
    @ObservedObject private var gamification = GamificationManager.shared

    @State private var showingTaskEditor = false
    @State private var showingHistory = false
    @State private var showingJourney = false
    @State private var celebratingCompletion = false
    @State private var xpPopup: Int? = nil
    @State private var lastXPResult: XPAwardResult? = nil

    var body: some View {
        ZStack {
            Color.themeBackground
                .edgesIgnoringSafeArea(.all)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerView
                    levelProgressCard
                    dailyTasksCard
                    progressSummaryCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
            .overlay(alignment: .top) {
                if let xp = xpPopup {
                    XPPopupView(xp: xp)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                        .padding(.top, 60)
                }
            }
        }
        .sheet(isPresented: $showingTaskEditor) {
            DailyTaskSelectionView(
                day: disciplineSystem.getTodayDay(),
                disciplineSystem: disciplineSystem
            )
        }
        .sheet(isPresented: $showingHistory) {
            DisciplineHistoryView(disciplineSystem: disciplineSystem)
        }
        .sheet(isPresented: $showingJourney) {
            ProgressJourneyView()
        }
        .fullScreenCover(isPresented: $celebratingCompletion) {
            DailyCompletionCelebrationView(
                streakCount: streakManager.currentStreak,
                xpEarned: lastXPResult?.xpGained ?? 50,
                level: gamification.currentLevel,
                onDismiss: {
                    Haptics.soft()
                    celebratingCompletion = false
                }
            )
        }
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TODAY")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeSecondaryText)
                    .tracking(1.8)

                Text(formattedDate)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themeText)
            }

            Spacer()

            Button(action: {
                Haptics.light()
                showingHistory = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)

                    Text("\(streakManager.currentStreak)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.themeCardBackground)
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button(action: {
                Haptics.light()
                showingTaskEditor = true
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.themeText)
                    .frame(width: 40, height: 40)
                    .background(Color.themeCardBackground)
                    .overlay(
                        Circle()
                            .stroke(Color.themeDivider.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var dailyTasksCard: some View {
        let today = disciplineSystem.getTodayDay()

        return VStack(spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Discipline")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)

                    Text("\(completedTasksCount)/3 completed")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.themeDivider, lineWidth: 4)
                        .frame(width: 52, height: 52)

                    Circle()
                        .trim(from: 0, to: completionPercentage)
                        .stroke(
                            completionPercentage == 1 ? Color.themeSuccess : Color.themePrimary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: completionPercentage)

                    Text("\(Int(completionPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Choose one task from each category. Finishing all three earns one streak day.")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)

                HStack(spacing: 10) {
                    ForEach(DisciplineCategory.allCases.sorted { $0.displayOrder < $1.displayOrder }) { category in
                        categoryChip(for: category, in: today)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ForEach(Array(today.tasks.enumerated()), id: \.element.id) { index, task in
                    DisciplineTaskRow(
                        task: task,
                        onToggle: {
                            let result = disciplineSystem.toggleTodayTask(at: index)
                            if let xp = result.xpResult {
                                showXPPopup(xp.xpGained)
                                lastXPResult = xp
                            }
                            if result.justCompletedAllTasks {
                                showCompletionCelebration()
                            }
                        }
                    )
                }
            }

            Button(action: {
                Haptics.light()
                showingTaskEditor = true
            }) {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 18))

                    Text("Choose Today's 3 Tasks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.themePrimary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.themePrimary.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.themeCardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }

    private func categoryChip(for category: DisciplineCategory, in day: DisciplineDay) -> some View {
        let selectedTask = day.tasks.first(where: { $0.category == category })

        return VStack(alignment: .leading, spacing: 4) {
            Text(category.rawValue.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(Color.themePrimary)

            Text(selectedTask?.title ?? "")
                .font(.caption)
                .foregroundColor(Color.themeText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.themeBackground.opacity(0.45))
        .cornerRadius(12)
    }

    private var progressSummaryCard: some View {
        let history = disciplineSystem.getCompletionHistory(days: 7).reversed()

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Snapshot")
                        .font(.headline)
                        .foregroundColor(Color.themeText)

                    Text("Track how consistently you’re closing all three categories.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Button(action: {
                    Haptics.light()
                    showingHistory = true
                }) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themePrimary)
                }
            }

            VStack(spacing: 12) {
                ForEach(Array(history), id: \.id) { day in
                    WeekDayProgressRow(day: day)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.themeCardBackground,
                    Color.themeCardBackground.opacity(0.92)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.themeDivider.opacity(0.35), lineWidth: 1)
        )
        .cornerRadius(22)
    }

    private var levelProgressCard: some View {
        let rank = gamification.currentRank
        let rankColor = rankColorFromName(rank.color)

        return Button(action: {
            Haptics.light()
            showingJourney = true
        }) {
            HStack(spacing: 14) {
                // Rank icon badge
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: rank.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(rankColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(rank.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeText)

                        Text("Lv.\(gamification.currentLevel)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(rankColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(rankColor.opacity(0.12))
                            .cornerRadius(6)

                        Spacer()

                        Text("\(gamification.xpInCurrentLevel)/\(gamification.xpToNextLevel) XP")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.themeSecondaryText.opacity(0.5))
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.themeDivider.opacity(0.3))
                                .frame(height: 8)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [rankColor, rankColor.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geometry.size.width * gamification.levelProgress), height: 8)
                                .animation(.easeInOut(duration: 0.4), value: gamification.levelProgress)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding(16)
            .background(Color.themeCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func rankColorFromName(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "blue": return Color.themePrimary
        case "purple": return .purple
        case "orange": return .orange
        case "yellow": return .yellow
        case "red": return .red
        default: return Color.themePrimary
        }
    }

    private func showXPPopup(_ xp: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            xpPopup = xp
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                xpPopup = nil
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var completedTasksCount: Int {
        disciplineSystem.getTodayDay().completedTaskCount
    }

    private var completionPercentage: Double {
        disciplineSystem.getTodayDay().completionPercentage
    }

    private func showCompletionCelebration() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            celebratingCompletion = true
        }
    }
}

struct DisciplineTaskRow: View {
    let task: DisciplineTask
    let onToggle: () -> Void

    private let holdDuration: Double = 0.8

    @State private var holdProgress: CGFloat = 0
    @State private var isHolding = false
    @State private var holdTimer: Timer?
    @State private var hapticFired = false

    var body: some View {
        HStack(spacing: 16) {
            // Checkbox circle
            ZStack {
                Circle()
                    .stroke(task.isCompleted ? Color.themeSuccess : Color.themeDivider, lineWidth: 2)
                    .frame(width: 28, height: 28)

                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.themeSuccess)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(task.category.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themePrimary)

                    if let completedAt = task.completedAt {
                        Text("Completed at \(formatTime(completedAt))")
                            .font(.caption2)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                }

                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.themeText)
                    .strikethrough(task.isCompleted)

                Text(task.detail)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if !task.isCompleted {
                    Text("Hold to complete")
                        .font(.caption2)
                        .foregroundColor(Color.themeSecondaryText.opacity(isHolding ? 0 : 0.6))
                }
            }

            Spacer()

            Image(systemName: task.category.iconName)
                .font(.system(size: 18))
                .foregroundColor(task.isCompleted ? Color.themeSuccess : Color.themeSecondaryText)
        }
        .padding(16)
        .background(
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Base background
                    RoundedRectangle(cornerRadius: 14)
                        .fill(task.isCompleted ? Color.themeSuccess.opacity(0.1) : Color.themeBackground.opacity(0.5))

                    // Hold progress fill — sweeps left to right
                    if !task.isCompleted && holdProgress > 0 {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.themeSuccess.opacity(0.12))
                            .frame(width: geometry.size.width * holdProgress)

                        // Leading edge glow
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.themeSuccess.opacity(0.06))
                            .frame(width: geometry.size.width * holdProgress)
                            .blur(radius: 6)
                    }
                }
            }
        )
        .overlay(
            // Border that fills as you hold
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isHolding ? Color.themeSuccess.opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .cornerRadius(14)
        .scaleEffect(isHolding ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHolding)
        .onTapGesture {
            if task.isCompleted {
                Haptics.soft()
                onToggle()
            }
        }
        .onLongPressGesture(minimumDuration: holdDuration, pressing: { pressing in
            if task.isCompleted { return }

            if pressing {
                startHold()
            } else {
                cancelHold()
            }
        }, perform: {
            if !task.isCompleted {
                completeTask()
            }
        })
    }

    private func startHold() {
        isHolding = true
        hapticFired = false
        holdProgress = 0

        let interval: Double = 0.02
        let increment = CGFloat(interval / holdDuration)

        holdTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            holdProgress = min(1.0, holdProgress + increment)

            if holdProgress >= 0.5 && !hapticFired {
                hapticFired = true
                Haptics.light()
            }
        }
    }

    private func cancelHold() {
        isHolding = false
        holdTimer?.invalidate()
        holdTimer = nil
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }

    private func completeTask() {
        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        holdProgress = 0

        Haptics.success()
        onToggle()
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WeekDayProgressRow: View {
    let day: DisciplineDay

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dayLabel)
                    .font(.subheadline)
                    .fontWeight(day.isToday ? .semibold : .medium)
                    .foregroundColor(Color.themeText)
                    .lineLimit(1)

                Text(dateLabel)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }
            .frame(width: 76, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Capsule()
                        .fill(day.isFullyCompleted ? Color.themeSuccess : Color.themePrimary.opacity(0.3))
                        .frame(width: 10, height: 10)

                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(day.isFullyCompleted ? Color.themeSuccess : Color.themeSecondaryText)

                    Spacer()

                    Text("\(day.completedTaskCount)/3")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themeText)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.themeBackground.opacity(0.65))
                            .frame(height: 10)

                        Capsule()
                            .fill(progressGradient)
                            .frame(width: max(10, geometry.size.width * day.completionPercentage), height: 10)
                    }
                }
                .frame(height: 10)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.themeBackground.opacity(0.42))
            .cornerRadius(16)
        }
    }

    private var statusText: String {
        if day.isFullyCompleted {
            return "Complete"
        }

        if day.completedTaskCount == 0 {
            return day.isToday ? "Not started" : "Missed"
        }

        return "In progress"
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: day.isFullyCompleted
                ? [Color.themeSuccess, Color.themeSuccess.opacity(0.75)]
                : [Color.themePrimary, Color.themePrimary.opacity(0.55)]
            ),
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var dayLabel: String {
        if day.isToday { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day.date)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: day.date)
    }
}

struct DailyTaskSelectionView: View {
    @Environment(\.presentationMode) private var presentationMode

    let day: DisciplineDay
    let disciplineSystem: DisciplineSystemState

    @State private var selections: [DisciplineCategory: String]

    init(day: DisciplineDay, disciplineSystem: DisciplineSystemState) {
        self.day = day
        self.disciplineSystem = disciplineSystem
        _selections = State(initialValue: Dictionary(uniqueKeysWithValues: day.tasks.map { ($0.category, $0.optionID) }))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)

                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose today's plan")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.themeText)

                                Text("Pick one simple task from each category. Finish all three to earn a streak day.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeSecondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(DisciplineCategory.allCases.sorted { $0.displayOrder < $1.displayOrder }) { category in
                                TaskCategorySelectionCard(
                                    category: category,
                                    options: disciplineSystem.getTaskOptions(for: category),
                                    selectedOptionID: Binding(
                                        get: {
                                            selections[category] ?? DisciplineTaskLibrary.defaultOption(for: category).id
                                        },
                                        set: { selections[category] = $0 }
                                    )
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(width: max(0, geometry.size.width - 40), alignment: .topLeading)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    .clipped()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Haptics.medium()
                        disciplineSystem.updateTodaySelections(selections)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

private struct TaskCategorySelectionCard: View {
    let category: DisciplineCategory
    let options: [DisciplineTaskOption]
    @Binding var selectedOptionID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: category.iconName)
                    .font(.headline)
                    .foregroundColor(Color.themePrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(Color.themeText)

                    Text(category.subtitle)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }
            }

            VStack(spacing: 10) {
                ForEach(options) { option in
                    Button(action: {
                        Haptics.selection()
                        selectedOptionID = option.id
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedOptionID == option.id ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(selectedOptionID == option.id ? Color.themePrimary : Color.themeDivider)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.themeText)

                                Text(option.detail)
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.themeBackground.opacity(0.45))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.themeCardBackground)
        .cornerRadius(18)
    }
}

struct DailyCompletionCelebrationView: View {
    let streakCount: Int
    let xpEarned: Int
    let level: Int
    let onDismiss: () -> Void

    @State private var animateCheckmark = false
    @State private var showXPBadge = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateCheckmark ? 1 : 0.3)

                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateCheckmark ? 1 : 0.3)
                }

                VStack(spacing: 12) {
                    Text("All Done!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("You completed all 3 tasks today")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.82))

                    // XP earned badge
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("+\(xpEarned) XP")
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        Text("  Level \(level)")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .scaleEffect(showXPBadge ? 1 : 0.5)
                    .opacity(showXPBadge ? 1 : 0)

                    Text(streakCount > 0 ? "Your streak is now \(streakCount) day\(streakCount == 1 ? "" : "s")." : "Come back tomorrow and do it again.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animateCheckmark = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4)) {
                showXPBadge = true
            }
        }
    }
}

struct DisciplineHistoryView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var disciplineSystem: DisciplineSystemState

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 16) {
                        let history = disciplineSystem.getCompletionHistory(days: 30)

                        ForEach(history, id: \.id) { day in
                            HistoryDayCard(day: day)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct HistoryDayCard: View {
    let day: DisciplineDay

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.formattedDate)
                        .font(.headline)
                        .foregroundColor(Color.themeText)

                    Text("\(day.completedTaskCount)/3 tasks completed")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                if day.isFullyCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.themeSuccess)
                }
            }

            VStack(spacing: 8) {
                ForEach(day.tasks, id: \.id) { task in
                    HStack(spacing: 8) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(task.isCompleted ? Color.themeSuccess : Color.themeDivider)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline)
                                .foregroundColor(Color.themeText)
                                .strikethrough(task.isCompleted)

                            Text(task.category.rawValue)
                                .font(.caption2)
                                .foregroundColor(Color.themeSecondaryText)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeCardBackground)
        .cornerRadius(12)
    }
}

struct XPPopupView: View {
    let xp: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.yellow)

            Text("+\(xp) XP")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct DisciplineHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DisciplineHomeView()
            .preferredColorScheme(.dark)
    }
}
