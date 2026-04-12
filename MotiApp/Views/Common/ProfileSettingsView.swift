import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var profileManager = ProfileManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var selectedFocus: MotivationFocus
    @State private var selectedStartHour: Int
    @State private var selectedGoal: SevenDayGoal

    init() {
        let profile = ProfileManager.shared
        _selectedFocus = State(initialValue: profile.focus)
        _selectedStartHour = State(initialValue: profile.preferredStartHour)
        _selectedGoal = State(initialValue: profile.sevenDayGoal)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerCard
                        focusSection
                        reminderSection
                        goalSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Your Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shape the app around the version of you that is trying to show up this week.")
                .font(.headline)
                .foregroundColor(Color.themeText)

            Text("This updates your daily prompt, suggested reminder window, and weekly target.")
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var focusSection: some View {
        profileSection(title: "Focus") {
            ForEach(MotivationFocus.allCases) { focus in
                profileChoiceRow(
                    title: focus.title,
                    subtitle: focus.subtitle,
                    isSelected: selectedFocus == focus
                ) {
                    selectedFocus = focus
                }
            }
        }
    }

    private var reminderSection: some View {
        profileSection(title: "Reminder Time") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 10)], spacing: 10) {
                ForEach(6...22, id: \.self) { hour in
                    Button(action: {
                        selectedStartHour = hour
                    }) {
                        Text(formattedHour(hour))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selectedStartHour == hour ? Color.themeBackground : Color.themeText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedStartHour == hour ? Color.themePrimary : Color.themeBackground.opacity(0.32))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var goalSection: some View {
        profileSection(title: "7-Day Goal") {
            ForEach(SevenDayGoal.allCases) { goal in
                profileChoiceRow(
                    title: goal.title,
                    subtitle: goal.subtitle,
                    isSelected: selectedGoal == goal
                ) {
                    selectedGoal = goal
                }
            }
        }
    }

    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            VStack(spacing: 10) {
                content()
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func profileChoiceRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.themePrimary : Color.themeDivider)
            }
            .padding(14)
            .background(Color.themeBackground.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func saveProfile() {
        profileManager.updateProfile(
            focus: selectedFocus,
            preferredStartHour: selectedStartHour,
            sevenDayGoal: selectedGoal
        )
        notificationManager.updateReminderTime(profileManager.reminderDate)
        dismiss()
    }

    private func formattedHour(_ hour: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour):00 \(period)"
    }
}
