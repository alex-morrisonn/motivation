import SwiftUI

private enum CalendarLayoutMode: String, CaseIterable {
    case month
    case week

    var title: String {
        switch self {
        case .month: return "Month"
        case .week: return "Week"
        }
    }
}

private enum AgendaScope: String, CaseIterable {
    case day
    case upcoming
    case completed

    var title: String {
        switch self {
        case .day: return "Selected Day"
        case .upcoming: return "Upcoming"
        case .completed: return "Completed"
        }
    }
}

struct CalendarView: View {
    @ObservedObject private var eventService = EventService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingEventEditor = false
    @State private var showingPlannerSettings = false
    @State private var editingEvent: Event?
    @State private var selectedDate = Date()
    @State private var visibleMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var draftTitle = ""
    @State private var draftNotes = ""
    @State private var draftIconName = EventIconLibrary.defaultIcon
    @State private var draftTintHex = EventTintPalette.defaultHex
    @State private var draftIsAllDay = false

    @AppStorage("calendar_layout_mode") private var layoutModeRawValue = CalendarLayoutMode.month.rawValue
    @AppStorage("calendar_agenda_scope") private var agendaScopeRawValue = AgendaScope.day.rawValue
    @AppStorage("calendar_show_completed") private var showCompleted = true
    @AppStorage("calendar_show_weekends") private var showWeekends = true
    @AppStorage("calendar_show_insights") private var showInsights = true

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.themeBackground,
                    Color.themeCardBackground.opacity(0.92),
                    Color.themeBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    heroCard
                    plannerModeBar
                    calendarCard
                    quickAddCard
                    agendaCard

                    if showInsights {
                        insightsCard
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .sheet(isPresented: $showingEventEditor) {
            if let event = editingEvent {
                EventEditorView(event: event)
            } else {
                EventEditorView(
                    initialDate: selectedDate,
                    suggestedTitle: draftTitle,
                    suggestedNotes: draftNotes,
                    suggestedIconName: draftIconName,
                    suggestedTintHex: draftTintHex,
                    suggestedAllDay: draftIsAllDay
                )
            }
        }
        .sheet(isPresented: $showingPlannerSettings) {
            CalendarPlannerSettingsSheet(
                showCompleted: $showCompleted,
                showWeekends: $showWeekends,
                showInsights: $showInsights
            )
        }
        .onChange(of: selectedDate) { _, newValue in
            visibleMonth = startOfMonth(for: newValue)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PLAN")
                        .font(.caption.weight(.semibold))
                        .tracking(2)
                        .foregroundColor(Color.themeSecondaryText)

                    Text(monthHeaderTitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)

                    Text(selectedDateSummary)
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button(action: {
                        showingPlannerSettings = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color.themeText)
                            .frame(width: 44, height: 44)
                            .background(Color.themeBackground.opacity(0.28))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        prepareNewEvent()
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 46, height: 46)
                            .background(Color.themePrimary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if let nextEvent = eventService.nextIncompleteEvent() {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(nextEvent.tintColor.opacity(0.16))
                            .frame(width: 42, height: 42)

                        Image(systemName: nextEvent.iconName)
                            .foregroundColor(nextEvent.tintColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Next step")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.themeSecondaryText)

                        Text(nextEvent.title)
                            .font(.headline.weight(.semibold))
                            .foregroundColor(Color.themeText)

                        Text(nextEvent.formattedDate + " • " + nextEvent.formattedTime)
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }

                    Spacer()
                }
                .padding(16)
                .background(Color.themeBackground.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            } else {
                Text("Give the day a shape. Add only what matters.")
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.themeCardBackground.opacity(0.95), Color.themePrimary.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var plannerModeBar: some View {
        HStack(spacing: 14) {
            Picker("Layout", selection: $layoutModeRawValue) {
                ForEach(CalendarLayoutMode.allCases, id: \.rawValue) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)

            Button(action: {
                Haptics.selection()
                selectedDate = Date()
            }) {
                Text(calendar.isDateInToday(selectedDate) ? "Today" : "Jump to Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(calendar.isDateInToday(selectedDate) ? Color.themeSecondaryText : Color.themePrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.themeCardBackground.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button(action: {
                    shiftVisibleMonth(by: -1)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)
                        .frame(width: 34, height: 34)
                        .background(Color.themeBackground.opacity(0.35))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    Text(monthHeaderTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(layoutMode == .month ? "Choose a day and give it a shape" : "Move through the week with intention")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Button(action: {
                    shiftVisibleMonth(by: 1)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)
                        .frame(width: 34, height: 34)
                        .background(Color.themeBackground.opacity(0.35))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if layoutMode == .month {
                CalendarMonthGridView(
                    month: visibleMonth,
                    selectedDate: selectedDate,
                    showWeekends: showWeekends,
                    eventService: eventService
                ) { date in
                    selectedDate = date
                }
            } else {
                CalendarWeekStripView(
                    selectedDate: selectedDate,
                    anchorDate: selectedDate,
                    showWeekends: showWeekends,
                    eventService: eventService
                ) { date in
                    selectedDate = date
                }
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var quickAddCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Quick Add")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Spacer()

                    Text("Quick starts")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CalendarQuickActionChip(
                        title: "Focus Block",
                        subtitle: "90 min deep work",
                        symbol: "target"
                    ) {
                        let time = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                        openNewEvent(
                            title: "Focus Block",
                            notes: "Protect this time for your most important work.",
                            date: time,
                            icon: "target",
                            tint: EventTintPalette.options[0].hex,
                            isAllDay: false
                        )
                    }

                    CalendarQuickActionChip(
                        title: "Workout",
                        subtitle: "Move today",
                        symbol: "figure.run"
                    ) {
                        let time = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                        openNewEvent(
                            title: "Workout",
                            notes: "Show up, even if it is short.",
                            date: time,
                            icon: "figure.run",
                            tint: EventTintPalette.options[1].hex,
                            isAllDay: false
                        )
                    }

                    CalendarQuickActionChip(
                        title: "Reset Day",
                        subtitle: "All day intention",
                        symbol: "sun.max"
                    ) {
                        openNewEvent(
                            title: "Reset Day",
                            notes: "One clear theme for the day.",
                            date: selectedDate,
                            icon: "sun.max",
                            tint: EventTintPalette.options[2].hex,
                            isAllDay: true
                        )
                    }

                    CalendarQuickActionChip(
                        title: "Meet Up",
                        subtitle: "People matter too",
                        symbol: "person.2"
                    ) {
                        let time = calendar.date(bySettingHour: 19, minute: 30, second: 0, of: selectedDate) ?? selectedDate
                        openNewEvent(
                            title: "Meet Up",
                            notes: "",
                            date: time,
                            icon: "person.2",
                            tint: EventTintPalette.options[3].hex,
                            isAllDay: false
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var agendaCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(agendaTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text(agendaSubtitle)
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }

                Spacer()

                Menu {
                    Picker("Agenda Scope", selection: $agendaScopeRawValue) {
                        ForEach(AgendaScope.allCases, id: \.rawValue) { scope in
                            Text(scope.title).tag(scope.rawValue)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(agendaScope.title)
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundColor(Color.themeText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.themeBackground.opacity(0.24))
                    .clipShape(Capsule())
                }

                Text("\(displayedEvents.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.themePrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.themePrimary.opacity(0.14))
                    .clipShape(Capsule())
            }

            if displayedEvents.isEmpty {
                CalendarEmptyStateCard(
                    title: "Nothing scheduled yet",
                    message: "Use a quick preset or create a custom event for this space.",
                    actionTitle: "Create Event"
                ) {
                    prepareNewEvent()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(displayedEvents) { event in
                        CalendarEventCard(
                            event: event,
                            onComplete: {
                                Haptics.soft()
                                eventService.toggleCompletionStatus(event)
                            },
                            onDelete: {
                                Haptics.light()
                                eventService.deleteEvent(event)
                            },
                            onEdit: {
                                editingEvent = event
                                showingEventEditor = true
                            }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Insights")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            HStack(spacing: 12) {
                CalendarInsightCard(
                    title: "Scheduled this month",
                    value: "\(eventService.getEvents(forMonthContaining: visibleMonth).count)",
                    symbol: "calendar.badge.clock",
                    tint: Color.themePrimary
                )

                CalendarInsightCard(
                    title: "Upcoming next 14 days",
                    value: "\(eventService.getUpcomingEvents().count)",
                    symbol: "bolt",
                    tint: Color.themeWarning
                )
            }

            HStack(spacing: 12) {
                CalendarInsightCard(
                    title: "Completed recently",
                    value: "\(eventService.getCompletedEvents(limit: 30).count)",
                    symbol: "checkmark.circle",
                    tint: Color.themeSuccess
                )

                CalendarInsightCard(
                    title: "Focused on selected day",
                    value: "\(eventService.getEvents(for: selectedDate).filter { !$0.isCompleted }.count)",
                    symbol: "target",
                    tint: Color.themeSecondary
                )
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var displayedEvents: [Event] {
        let scopedEvents: [Event]

        switch agendaScope {
        case .day:
            scopedEvents = eventService.getEvents(for: selectedDate)
        case .upcoming:
            scopedEvents = eventService.getUpcomingEvents()
        case .completed:
            scopedEvents = eventService.getCompletedEvents(limit: 20)
        }

        if showCompleted || agendaScope == .completed {
            return scopedEvents
        }

        return scopedEvents.filter { !$0.isCompleted }
    }

    private var layoutMode: CalendarLayoutMode {
        get { CalendarLayoutMode(rawValue: layoutModeRawValue) ?? .month }
        set { layoutModeRawValue = newValue.rawValue }
    }

    private var agendaScope: AgendaScope {
        get { AgendaScope(rawValue: agendaScopeRawValue) ?? .day }
        set { agendaScopeRawValue = newValue.rawValue }
    }

    private var monthHeaderTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: visibleMonth)
    }

    private var selectedDateSummary: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    private var agendaTitle: String {
        switch agendaScope {
        case .day:
            return "Plan for " + shortSelectedDate
        case .upcoming:
            return "Upcoming Flow"
        case .completed:
            return "Completed"
        }
    }

    private var agendaSubtitle: String {
        switch agendaScope {
        case .day:
            return "What matters on the selected day."
        case .upcoming:
            return "The next two weeks, clear and ready."
        case .completed:
            return "Completed steps worth keeping visible."
        }
    }

    private var shortSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: selectedDate)
    }

    private func prepareNewEvent() {
        openNewEvent(
            title: "",
            notes: "",
            date: selectedDate,
            icon: EventIconLibrary.defaultIcon,
            tint: EventTintPalette.defaultHex,
            isAllDay: false
        )
    }

    private func openNewEvent(title: String, notes: String, date: Date, icon: String, tint: String, isAllDay: Bool) {
        Haptics.medium()
        editingEvent = nil
        selectedDate = date
        draftTitle = title
        draftNotes = notes
        draftIconName = icon
        draftTintHex = tint
        draftIsAllDay = isAllDay
        showingEventEditor = true
    }

    private func shiftVisibleMonth(by value: Int) {
        Haptics.selection()
        guard let nextMonth = calendar.date(byAdding: .month, value: value, to: visibleMonth) else {
            return
        }

        visibleMonth = startOfMonth(for: nextMonth)

        if layoutMode == .month {
            if let matchingDate = calendar.date(bySetting: .day, value: min(calendar.component(.day, from: selectedDate), daysInMonth(for: visibleMonth)), of: visibleMonth) {
                selectedDate = matchingDate
            }
        } else if let shiftedDate = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) {
            selectedDate = shiftedDate
        }
    }

    private func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func daysInMonth(for date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }
}

private struct CalendarPlannerSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showCompleted: Bool
    @Binding var showWeekends: Bool
    @Binding var showInsights: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackground,
                        Color.themeCardBackground.opacity(0.94),
                        Color.themeBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        settingsSection(
                            title: "Display",
                            subtitle: "Only the preferences that change how the planner feels."
                        ) {
                            settingsToggle(
                                title: "Show completed events",
                                subtitle: "Keep finished items visible in your agenda."
                            ,
                                isOn: $showCompleted
                            )

                            settingsToggle(
                                title: "Show weekends",
                                subtitle: "Hide Saturday and Sunday for a cleaner workweek view.",
                                isOn: $showWeekends
                            )

                            settingsToggle(
                                title: "Show insights",
                                subtitle: "Keep the stat cards visible below the agenda.",
                                isOn: $showInsights
                            )
                        }
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Planner Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
    }

    private func settingsSection<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            content()
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(14)
        .background(Color.themeBackground.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .preferredColorScheme(.dark)
    }
}
