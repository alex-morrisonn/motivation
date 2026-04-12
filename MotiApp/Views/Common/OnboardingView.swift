import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var stepIndex = 0
    @State private var selectedFocus = MotivationFocus.discipline
    @State private var selectedStartHour = 8
    @State private var selectedGoal = SevenDayGoal.strong

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color.themeBackground,
                    Color.themePrimary.opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                progressHeader

                Text(currentTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(currentSubtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.72))

                Group {
                    switch stepIndex {
                    case 0:
                        focusStep
                    case 1:
                        startHourStep
                    default:
                        goalStep
                    }
                }

                Spacer()

                Button(action: handlePrimaryAction) {
                    Text(stepIndex == 2 ? "Start My Week" : "Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                if stepIndex > 0 {
                    Button("Back") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            stepIndex -= 1
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MOTII SETUP")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.55))

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))

                    Capsule()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * (Double(stepIndex + 1) / 3.0))
                }
            }
            .frame(height: 8)
        }
    }

    private var focusStep: some View {
        VStack(spacing: 12) {
            ForEach(MotivationFocus.allCases) { focus in
                Button(action: {
                    selectedFocus = focus
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(focus.title)
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            Image(systemName: selectedFocus == focus ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedFocus == focus ? .white : .white.opacity(0.35))
                        }

                        Text(focus.subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.68))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selectedFocus == focus ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var startHourStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick when you want Motii to nudge you into motion.")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                ForEach(6...22, id: \.self) { hour in
                    Button(action: {
                        selectedStartHour = hour
                    }) {
                        Text(formattedHour(hour))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(selectedStartHour == hour ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedStartHour == hour ? Color.white : Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a target that feels demanding but realistic.")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(SevenDayGoal.allCases) { goal in
                Button(action: {
                    selectedGoal = goal
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(goal.title)
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(goal.subtitle)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.68))
                        }

                        Spacer()

                        Image(systemName: selectedGoal == goal ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedGoal == goal ? .white : .white.opacity(0.35))
                    }
                    .padding(18)
                    .background(selectedGoal == goal ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var currentTitle: String {
        switch stepIndex {
        case 0:
            return "What are you trying to build?"
        case 1:
            return "When should Motii show up?"
        default:
            return "What does a good week look like?"
        }
    }

    private var currentSubtitle: String {
        switch stepIndex {
        case 0:
            return "This shapes your first quote flow, suggested tasks, and weekly quest tone."
        case 1:
            return "We’ll use this to set your default reminder time and structure the first day."
        default:
            return "The goal is not perfection. It is a target you will want to chase."
        }
    }

    private func handlePrimaryAction() {
        if stepIndex < 2 {
            withAnimation(.easeInOut(duration: 0.2)) {
                stepIndex += 1
            }
            return
        }

        profileManager.completeOnboarding(
            focus: selectedFocus,
            preferredStartHour: selectedStartHour,
            sevenDayGoal: selectedGoal
        )
        notificationManager.updateReminderTime(profileManager.reminderDate)
        DisciplineSystemState.shared.updateTodaySelections(profileManager.suggestedSelections)
        GamificationManager.shared.updateWeeklyQuestProgress(
            tasksCompletedThisWeek: DisciplineSystemState.shared.getCompletionHistory(days: 7).reduce(0) { $0 + $1.completedTaskCount },
            perfectDaysThisWeek: DisciplineSystemState.shared.getCompletionHistory(days: 7).filter(\.isFullyCompleted).count
        )
    }

    private func formattedHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : hour
        return "\(displayHour):00 \(period)"
    }
}
