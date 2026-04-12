import SwiftUI

/// Main home view focused on the daily discipline system.
struct DisciplineHomeView: View {
    @ObservedObject private var disciplineSystem = DisciplineSystemState.shared
    @ObservedObject private var streakManager = StreakManager.shared
    @ObservedObject private var gamification = GamificationManager.shared
    @ObservedObject private var eventService = EventService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared

    @AppStorage("hasSeenHomeWalkthrough") private var hasSeenHomeWalkthrough = false
    @State private var showingTaskEditor = false
    @State private var showingHistory = false
    @State private var showingJourney = false
    @State private var celebratingCompletion = false
    @State private var xpPopup: Int? = nil
    @State private var lastXPResult: XPAwardResult? = nil
    @State private var quoteAppliedTaskTitle: String?

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
            .edgesIgnoringSafeArea(.all)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    overviewCard
                    if let quoteAppliedTaskTitle {
                        quoteAppliedCard(taskTitle: quoteAppliedTaskTitle)
                    }
                    if shouldShowHomeWalkthrough {
                        homeWalkthroughCard
                    }
                    nextStepCard
                    dailyTasksCard
                    if shouldShowHomeWalkthrough {
                        unlockDashboardCard
                    } else {
                        planningCard
                        progressSummaryCard
                        weeklyQuestCard
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
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
        .onReceive(NotificationCenter.default.publisher(for: .quoteAppliedToToday)) { notification in
            guard let taskTitle = notification.userInfo?[AppNotification.quoteTaskTitleUserInfoKey] as? String else {
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                quoteAppliedTaskTitle = taskTitle
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if quoteAppliedTaskTitle == taskTitle {
                        quoteAppliedTaskTitle = nil
                    }
                }
            }
        }
        .onChange(of: completedTasksCount) { _, newValue in
            guard newValue > 0, shouldShowHomeWalkthrough else { return }
            completeHomeWalkthrough()
        }
    }

    private var overviewCard: some View {
        let rank = gamification.currentRank
        let rankColor = rankColorFromName(rank.color)

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DISCIPLINE")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundColor(Color.themeSecondaryText)

                    Text(formattedDate)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)

                    Text(profileManager.todayPrompt)
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Button(action: {
                    Haptics.light()
                    showingTaskEditor = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.themeText)
                        .frame(width: 44, height: 44)
                        .background(Color.themeBackground.opacity(0.28))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                overviewMetricPill(
                    title: "Streak",
                    value: "\(streakManager.currentStreak)",
                    symbol: "flame.fill",
                    tint: .orange,
                    action: {
                        Haptics.light()
                        showingHistory = true
                    }
                )

                overviewMetricPill(
                    title: "Level",
                    value: "Lv. \(gamification.currentLevel)",
                    symbol: rank.icon,
                    tint: rankColor,
                    action: {
                        Haptics.light()
                        showingJourney = true
                    }
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(rank.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Spacer()

                    Text("\(gamification.xpInCurrentLevel)/\(gamification.xpToNextLevel) XP")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.themeDivider.opacity(0.22))
                            .frame(height: 10)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [rankColor, rankColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(10, geometry.size.width * gamification.levelProgress), height: 10)
                            .animation(.easeInOut(duration: 0.35), value: gamification.levelProgress)
                    }
                }
                .frame(height: 10)
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

    private var homeWalkthroughCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.themePrimary.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.themePrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Start Here")
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color.themeText)

                    Text("You do not need every feature on day one. Start with one task on this screen, then branch into quotes or planning after your first win.")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 12) {
                walkthroughStep(
                    number: "1",
                    title: "Check Today's Focus",
                    detail: "Your three default tasks are already set up below. Completing two protects the day."
                )
                walkthroughStep(
                    number: "2",
                    title: "Use Next Move",
                    detail: "This card tells you the best action right now, so you do not have to decide where to start."
                )
                walkthroughStep(
                    number: "3",
                    title: "Open more later",
                    detail: "Quotes, planning, and progress are still here. They unlock once you want the full dashboard."
                )
            }

            HStack(spacing: 12) {
                Button(action: primaryNextStepAction) {
                    HStack {
                        Image(systemName: firstRunPrimaryActionSymbol)
                            .font(.system(size: 16, weight: .semibold))

                        Text(firstRunPrimaryActionTitle)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color.themeBackground)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.themePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button("Show Everything") {
                    completeHomeWalkthrough()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.themeText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.themeBackground.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themePrimary.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func walkthroughStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundColor(Color.themeBackground)
                .frame(width: 24, height: 24)
                .background(Color.themePrimary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(detail)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    private var unlockDashboardCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Once this page feels familiar, bring back the full dashboard.")
                .font(.subheadline.weight(.medium))
                .foregroundColor(Color.themeSecondaryText)

            Button("Show Planning, Quotes, and Progress") {
                completeHomeWalkthrough()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Color.themePrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.themePrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var dailyTasksCard: some View {
        let today = disciplineSystem.getTodayDay()
        let allTasksScheduled = today.tasks.allSatisfy { eventService.hasDisciplineEvent(for: $0) }

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Focus")
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color.themeText)

                    Text("\(completedTasksCount) of 3 complete")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Text("\(Int(completionPercentage * 100))%")
                    .font(.caption.weight(.bold))
                    .foregroundColor(completionPercentage == 1 ? Color.themeSuccess : Color.themePrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background((completionPercentage == 1 ? Color.themeSuccess : Color.themePrimary).opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 10) {
                    Text("Two tasks keeps the streak. Three makes it a perfect day.")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Color.themeSecondaryText)

                HStack(spacing: 10) {
                    ForEach(DisciplineCategory.allCases.sorted { $0.displayOrder < $1.displayOrder }) { category in
                        compactCategoryChip(for: category, in: today)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.themeDivider.opacity(0.16))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: completionPercentage == 1
                                    ? [Color.themeSuccess, Color.themeSuccess.opacity(0.7)]
                                    : [Color.themePrimary, Color.themeSecondary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(10, geometry.size.width * completionPercentage), height: 10)
                }
            }
            .frame(height: 10)

            VStack(spacing: 12) {
                ForEach(Array(today.tasks.enumerated()), id: \.element.id) { index, task in
                    DisciplineTaskRow(
                        task: task,
                        onToggle: {
                            let updatedCompletionState = !task.isCompleted
                            let result = disciplineSystem.toggleTodayTask(at: index)
                            eventService.syncDisciplineTaskCompletion(
                                for: task,
                                isCompleted: updatedCompletionState
                            )
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

            HStack(spacing: 12) {
                Button(action: {
                    Haptics.light()
                    showingTaskEditor = true
                }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Edit Tasks")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color.themePrimary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.themePrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: {
                    Haptics.medium()
                    for task in today.tasks where !eventService.hasDisciplineEvent(for: task) {
                        _ = eventService.scheduleDisciplineTask(task)
                    }
                }) {
                    HStack {
                        Image(systemName: allTasksScheduled ? "checkmark.circle.fill" : "calendar.badge.plus")
                            .font(.system(size: 16, weight: .semibold))

                        Text(allTasksScheduled ? "Planned" : "Add All to Plan")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(allTasksScheduled ? Color.themeSuccess : Color.themeText)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background((allTasksScheduled ? Color.themeSuccess : Color.themeBackground).opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(allTasksScheduled)
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

    private var nextStepCard: some View {
        let today = disciplineSystem.getTodayDay()
        let nextTask = today.tasks.first(where: { !$0.isCompleted })
        let scheduledCount = today.tasks.filter { eventService.hasDisciplineEvent(for: $0) }.count

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT MOVE")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundColor(Color.themeSecondaryText)

                    Text(nextStepTitle(nextTask: nextTask))
                        .font(.title3.weight(.bold))
                        .foregroundColor(Color.themeText)

                    Text(nextStepDescription(nextTask: nextTask, scheduledCount: scheduledCount))
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Image(systemName: nextStepSymbol(nextTask: nextTask, scheduledCount: scheduledCount))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.themePrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.themePrimary.opacity(0.12))
                    .clipShape(Circle())
            }

            if let nextTask {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextTask.category.rawValue.uppercased())
                        .font(.caption2.weight(.semibold))
                        .tracking(1.4)
                        .foregroundColor(Color.themePrimary)

                    Text(nextTask.title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(eventService.hasDisciplineEvent(for: nextTask) ? "This task is already on your plan. Hold the task row below when you finish it." : "Put this on your calendar first if you want the day to feel more real.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeBackground.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            HStack(spacing: 12) {
                Button(action: primaryNextStepAction) {
                    HStack {
                        Image(systemName: primaryNextStepActionSymbol(nextTask: nextTask, scheduledCount: scheduledCount))
                            .font(.system(size: 16, weight: .semibold))

                        Text(primaryNextStepActionTitle(nextTask: nextTask, scheduledCount: scheduledCount))
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color.themeBackground)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.themePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: secondaryNextStepAction) {
                    HStack {
                        Image(systemName: secondaryNextStepActionSymbol(nextTask: nextTask))
                            .font(.system(size: 16, weight: .semibold))

                        Text(secondaryNextStepActionTitle(nextTask: nextTask))
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color.themeText)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.themeBackground.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

    private func quoteAppliedCard(taskTitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.themePrimary)
                .frame(width: 38, height: 38)
                .background(Color.themePrimary.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Quote Applied")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text("\(taskTitle) is now part of today's focus. Use the next step below to schedule it or move straight into completing it.")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.themePrimary.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func compactCategoryChip(for category: DisciplineCategory, in day: DisciplineDay) -> some View {
        let selectedTask = day.tasks.first(where: { $0.category == category })

        return HStack(spacing: 8) {
            Image(systemName: category.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.themePrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(Color.themePrimary)

                Text(selectedTask?.title ?? "")
                    .font(.caption2)
                    .foregroundColor(Color.themeText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.themeBackground.opacity(0.28))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var progressSummaryCard: some View {
        let history = disciplineSystem.getCompletionHistory(days: 7).reversed()
        let completedDays = history.filter(\.isFullyCompleted).count

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text("\(history.filter(\.isConsistencyDay).count) of 7 consistency days. \(completedDays) perfect.")
                        .font(.subheadline)
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

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ForEach(Array(history), id: \.id) { day in
                        WeeklySnapshotDayPill(day: day)
                    }
                }

                if let focusedDay = history.last(where: \.isToday) ?? history.last {
                    WeeklySnapshotFocusCard(day: focusedDay)
                }
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

    private var planningCard: some View {
        let todaysEvents = eventService.getEvents(for: Date()).filter { !$0.isCompleted }
        let nextEvent = todaysEvents.first ?? eventService.nextIncompleteEvent()

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Plan")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(todaysEvents.isEmpty ? "Turn discipline into a real schedule." : "\(todaysEvents.count) active item\(todaysEvents.count == 1 ? "" : "s") scheduled.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Button(action: openPlanningTab) {
                    Text("Open Plan")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.themePrimary)
                }
                .buttonStyle(.plain)
            }

            if let nextEvent {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(nextEvent.tintColor.opacity(0.16))
                            .frame(width: 46, height: 46)

                        Image(systemName: nextEvent.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(nextEvent.tintColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextEvent.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeText)

                        Text(nextEvent.formattedDate + " • " + nextEvent.formattedTime)
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)

                        if !nextEvent.notes.isEmpty {
                            Text(nextEvent.notes)
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText.opacity(0.85))
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
                .padding(14)
                .background(Color.themeBackground.opacity(0.32))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                Text("Nothing is scheduled yet. Put your workout, deep work, or reset block on the calendar so the day has structure.")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
            }

            HStack(spacing: 10) {
                planShortcutButton(
                    title: "Focus Block",
                    symbol: "target",
                    tint: Color.themePrimary
                )

                planShortcutButton(
                    title: "Workout",
                    symbol: "figure.run",
                    tint: Color.themeSuccess
                )

                planShortcutButton(
                    title: "Reset",
                    symbol: "sun.max",
                    tint: Color.themeWarning
                )
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

    private var weeklyQuestCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week's Push")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(gamification.weeklyQuest.detail)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Text("\(gamification.weeklyQuestProgress)/\(gamification.weeklyQuest.target)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(gamification.isWeeklyQuestComplete ? Color.themeSuccess : Color.themePrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background((gamification.isWeeklyQuestComplete ? Color.themeSuccess : Color.themePrimary).opacity(0.12))
                    .clipShape(Capsule())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.themeDivider.opacity(0.16))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: gamification.isWeeklyQuestComplete
                                    ? [Color.themeSuccess, Color.themeSuccess.opacity(0.7)]
                                    : [Color.themePrimary, Color.themeSecondary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(10, geometry.size.width * gamification.weeklyQuestCompletion), height: 10)
                }
            }
            .frame(height: 10)

            Text(gamification.isWeeklyQuestComplete ? "Weekly quest complete. Keep stacking days." : "Progress updates as you complete tasks this week.")
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
        DateFormatter.disciplineDate.string(from: Date())
    }

    private var completedTasksCount: Int {
        disciplineSystem.getTodayDay().completedTaskCount
    }

    private var completionPercentage: Double {
        disciplineSystem.getTodayDay().completionPercentage
    }

    private var shouldShowHomeWalkthrough: Bool {
        !hasSeenHomeWalkthrough && completedTasksCount == 0
    }

    private var firstRunPrimaryActionTitle: String {
        let today = disciplineSystem.getTodayDay()
        let nextTask = today.tasks.first(where: { !$0.isCompleted })
        let scheduledCount = today.tasks.filter { eventService.hasDisciplineEvent(for: $0) }.count
        return primaryNextStepActionTitle(nextTask: nextTask, scheduledCount: scheduledCount)
    }

    private var firstRunPrimaryActionSymbol: String {
        let today = disciplineSystem.getTodayDay()
        let nextTask = today.tasks.first(where: { !$0.isCompleted })
        let scheduledCount = today.tasks.filter { eventService.hasDisciplineEvent(for: $0) }.count
        return primaryNextStepActionSymbol(nextTask: nextTask, scheduledCount: scheduledCount)
    }

    private func showCompletionCelebration() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            celebratingCompletion = true
        }
    }

    private func completeHomeWalkthrough() {
        withAnimation(.easeInOut(duration: 0.2)) {
            hasSeenHomeWalkthrough = true
        }
    }

    private func openPlanningTab() {
        Haptics.light()
        NotificationCenter.default.post(
            name: .tabSelectionChanged,
            object: nil,
            userInfo: [AppNotification.selectedTabUserInfoKey: 2]
        )
    }

    private func nextStepTitle(nextTask: DisciplineTask?) -> String {
        if let nextTask {
            return eventService.hasDisciplineEvent(for: nextTask) ? "Finish your next scheduled task" : "Make the next task real"
        }

        if eventService.nextIncompleteEvent() != nil {
            return "Protect the rest of the day"
        }

        return "You cleared today's focus"
    }

    private func nextStepDescription(nextTask: DisciplineTask?, scheduledCount: Int) -> String {
        if let nextTask {
            if eventService.hasDisciplineEvent(for: nextTask) {
                return scheduledCount == 0 ? "Your next win is already chosen. Complete it when it is done." : "You already have structure. Stay with the next task instead of adding more."
            }

            return scheduledCount == 0 ? "Nothing is on the calendar yet. Start by giving one task a time and place." : "One task is still unscheduled. Add it so the plan matches the intention."
        }

        if eventService.nextIncompleteEvent() != nil {
            return "Tasks are complete. Keep momentum by following the remaining plan."
        }

        return "Take the win, review the week, or set up tomorrow."
    }

    private func nextStepSymbol(nextTask: DisciplineTask?, scheduledCount: Int) -> String {
        if let nextTask {
            return eventService.hasDisciplineEvent(for: nextTask) ? "checkmark.circle" : "calendar.badge.plus"
        }

        return scheduledCount > 0 ? "calendar" : "sparkles"
    }

    private func primaryNextStepAction() {
        let today = disciplineSystem.getTodayDay()

        if let nextTask = today.tasks.first(where: { !$0.isCompleted }),
           !eventService.hasDisciplineEvent(for: nextTask) {
            openPlanningComposer(for: nextTask)
            return
        }

        if eventService.nextIncompleteEvent() != nil {
            openPlanningTab()
            return
        }

        Haptics.light()
        showingHistory = true
    }

    private func secondaryNextStepAction() {
        let today = disciplineSystem.getTodayDay()

        if today.tasks.contains(where: { !$0.isCompleted }) {
            Haptics.light()
            showingTaskEditor = true
            return
        }

        Haptics.light()
        showingJourney = true
    }

    private func primaryNextStepActionTitle(nextTask: DisciplineTask?, scheduledCount: Int) -> String {
        if let nextTask, !eventService.hasDisciplineEvent(for: nextTask) {
            return scheduledCount == 0 ? "Schedule First Task" : "Schedule Next Task"
        }

        if eventService.nextIncompleteEvent() != nil {
            return "Open Plan"
        }

        return "Review Week"
    }

    private func primaryNextStepActionSymbol(nextTask: DisciplineTask?, scheduledCount: Int) -> String {
        if let nextTask, !eventService.hasDisciplineEvent(for: nextTask) {
            return scheduledCount == 0 ? "calendar.badge.plus" : "plus.circle.fill"
        }

        if eventService.nextIncompleteEvent() != nil {
            return "calendar.badge.clock"
        }

        return "chart.line.uptrend.xyaxis"
    }

    private func secondaryNextStepActionTitle(nextTask: DisciplineTask?) -> String {
        nextTask == nil ? "View Progress" : "Edit Tasks"
    }

    private func secondaryNextStepActionSymbol(nextTask: DisciplineTask?) -> String {
        nextTask == nil ? "figure.walk.motion" : "slider.horizontal.3"
    }

    private func planShortcutButton(title: String, symbol: String, tint: Color) -> some View {
        Button(action: openPlanningTab) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(tint.opacity(0.12))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func openPlanningComposer(for task: DisciplineTask) {
        Haptics.medium()
        NotificationCenter.default.post(
            name: .openPlannerComposer,
            object: nil,
            userInfo: [
                AppNotification.plannerDateUserInfoKey: Date(),
                AppNotification.plannerTitleUserInfoKey: task.title,
                AppNotification.plannerNotesUserInfoKey: task.detail,
                AppNotification.plannerIconUserInfoKey: task.category.iconName,
                AppNotification.plannerTintHexUserInfoKey: plannerTintHex(for: task.category),
                AppNotification.plannerAllDayUserInfoKey: false
            ]
        )
        NotificationCenter.default.post(
            name: .tabSelectionChanged,
            object: nil,
            userInfo: [AppNotification.selectedTabUserInfoKey: 2]
        )
    }

    private func plannerTintHex(for category: DisciplineCategory) -> String {
        switch category {
        case .mind:
            return EventTintPalette.options.count > 2 ? EventTintPalette.options[2].hex : EventTintPalette.defaultHex
        case .body:
            return EventTintPalette.options.count > 1 ? EventTintPalette.options[1].hex : EventTintPalette.defaultHex
        case .focus:
            return EventTintPalette.defaultHex
        }
    }

    private func overviewMetricPill(
        title: String,
        value: String,
        symbol: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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
                }

                Spacer()
            }
            .padding(14)
            .background(Color.themeBackground.opacity(0.24))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(task.isCompleted ? Color.themeSuccess.opacity(0.16) : Color.themeBackground.opacity(0.5))
                    .frame(width: 36, height: 36)

                Image(systemName: task.isCompleted ? "checkmark" : task.category.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(task.isCompleted ? Color.themeSuccess : Color.themePrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(task.category.rawValue.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(task.isCompleted ? Color.themeSuccess : Color.themePrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background((task.isCompleted ? Color.themeSuccess : Color.themePrimary).opacity(0.12))
                        .clipShape(Capsule())

                    if let completedAt = task.completedAt {
                        Text(formatTime(completedAt))
                            .font(.caption2)
                            .foregroundColor(Color.themeSecondaryText)
                    } else {
                        Text("Hold to complete")
                            .font(.caption2)
                            .foregroundColor(Color.themeSecondaryText.opacity(isHolding ? 0 : 0.7))
                    }
                }

                Text(task.title)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color.themeText)
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)

                Text(task.detail)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .lineLimit(2)
            }

            Spacer()

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.themeSuccess)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.themeSecondaryText.opacity(0.45))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(task.isCompleted ? Color.themeSuccess.opacity(0.08) : Color.themeBackground.opacity(0.32))

                    if !task.isCompleted && holdProgress > 0 {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.themeSuccess.opacity(0.12))
                            .frame(width: geometry.size.width * holdProgress)

                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.themeSuccess.opacity(0.06))
                            .frame(width: geometry.size.width * holdProgress)
                            .blur(radius: 6)
                    }
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    task.isCompleted ? Color.themeSuccess.opacity(0.2) : (isHolding ? Color.themeSuccess.opacity(0.4) : Color.themeDivider.opacity(0.08)),
                    lineWidth: 1.2
                )
        )
        .cornerRadius(14)
        .scaleEffect(isHolding ? 0.985 : 1.0)
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

struct WeeklySnapshotDayPill: View {
    let day: DisciplineDay

    var body: some View {
        VStack(spacing: 10) {
            Text(shortDayLabel)
                .font(.caption2.weight(.semibold))
                .foregroundColor(day.isToday ? Color.themePrimary : Color.themeSecondaryText)

            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 42, height: 42)

                Text("\(day.completedTaskCount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(foregroundColor)
            }

            Text(dateLabel)
                .font(.caption2)
                .foregroundColor(Color.themeSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.themeBackground.opacity(day.isToday ? 0.34 : 0.22))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(day.isToday ? Color.themePrimary.opacity(0.28) : Color.themeDivider.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var backgroundColor: Color {
        if day.isFullyCompleted {
            return Color.themeSuccess.opacity(0.16)
        }

        if day.completedTaskCount == 0 {
            return day.isToday ? Color.themeWarning.opacity(0.16) : Color.themeDivider.opacity(0.16)
        }

        return Color.themePrimary.opacity(0.16)
    }

    private var foregroundColor: Color {
        if day.isFullyCompleted {
            return Color.themeSuccess
        }

        if day.completedTaskCount == 0 {
            return day.isToday ? Color.themeWarning : Color.themeSecondaryText
        }

        return Color.themePrimary
    }

    private var shortDayLabel: String {
        if day.isToday { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: day.date)
    }
}

struct WeeklySnapshotFocusCard: View {
    let day: DisciplineDay

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(statusTint)
                }

                Spacer()

                Text("\(day.completedTaskCount)/3")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.themeText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.themeBackground.opacity(0.34))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(index < day.completedTaskCount ? statusTint : Color.themeDivider.opacity(0.18))
                            .frame(width: 10, height: 10)

                        RoundedRectangle(cornerRadius: 999)
                            .fill(index < day.completedTaskCount ? statusTint.opacity(0.85) : Color.themeDivider.opacity(0.12))
                            .frame(height: 8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeBackground.opacity(0.26))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var dayTitle: String {
        if day.isToday {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day.date)
    }

    private var statusText: String {
        if day.isFullyCompleted {
            return "Perfect day. All three tasks completed."
        }

        if day.isConsistencyDay {
            return "Consistency secured for the day."
        }

        if day.completedTaskCount == 0 {
            return day.isToday ? "No tasks completed yet." : "No tasks completed."
        }

        return "\(day.completedTaskCount) task\(day.completedTaskCount == 1 ? "" : "s") completed."
    }

    private var statusTint: Color {
        if day.isFullyCompleted {
            return Color.themeSuccess
        }

        if day.isConsistencyDay {
            return Color.themePrimary
        }

        if day.completedTaskCount == 0 {
            return day.isToday ? Color.themeWarning : Color.themeSecondaryText
        }

        return Color.themePrimary
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

                                Text("Pick one simple task from each category. Finish 2 of 3 to protect the streak, or all 3 for a perfect day.")
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
