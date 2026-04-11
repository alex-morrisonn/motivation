import SwiftUI

/// View for creating and editing events
struct EventEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var eventService: EventService

    @State private var title: String
    @State private var date: Date
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var iconName: String
    @State private var tintHex: String
    @State private var isAllDay: Bool

    private let isNew: Bool
    private let eventId: UUID

    /// Initialize with a new event and optional suggestions
    init(
        eventService: EventService = EventService.shared,
        initialDate: Date = Date(),
        suggestedTitle: String = "",
        suggestedNotes: String = "",
        suggestedIconName: String = EventIconLibrary.defaultIcon,
        suggestedTintHex: String = EventTintPalette.defaultHex,
        suggestedAllDay: Bool = false
    ) {
        self.eventService = eventService
        _title = State(initialValue: suggestedTitle)
        _date = State(initialValue: initialDate)
        _notes = State(initialValue: suggestedNotes)
        _isCompleted = State(initialValue: false)
        _iconName = State(initialValue: suggestedIconName)
        _tintHex = State(initialValue: suggestedTintHex)
        _isAllDay = State(initialValue: suggestedAllDay)
        isNew = true
        eventId = UUID()
    }

    /// Initialize for editing an existing event
    init(event: Event, eventService: EventService = EventService.shared) {
        self.eventService = eventService
        _title = State(initialValue: event.title)
        _date = State(initialValue: event.date)
        _notes = State(initialValue: event.notes)
        _isCompleted = State(initialValue: event.isCompleted)
        _iconName = State(initialValue: event.iconName)
        _tintHex = State(initialValue: event.tintHex)
        _isAllDay = State(initialValue: event.isAllDay)
        isNew = false
        eventId = event.id
    }

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
                    VStack(spacing: 20) {
                        previewCard
                        detailsCard
                        quickTimeCard
                        iconCard
                        notesCard
                    }
                    .padding(18)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(isNew ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.themeSecondaryText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isNew ? "Add" : "Save") {
                        saveEvent()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isSaveDisabled ? Color.themeSecondaryText : Color.themePrimary)
                    .disabled(isSaveDisabled)
                }
            }
        }
    }

    private var previewCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(selectedTint.opacity(0.18))
                    .frame(width: 58, height: 58)

                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(selectedTint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Event" : title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(Color.themeText)

                Text(previewSubtitle)
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
            }

            Spacer()
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Details")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            VStack(alignment: .leading, spacing: 10) {
                Text("Title")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.themeSecondaryText)

                TextField("What matters here?", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .padding(14)
                    .background(Color.themeBackground.opacity(0.32))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundColor(Color.themeText)
            }

            Toggle(isOn: $isAllDay) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All-day event")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text("Switch off if you want a specific time.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }
            }
            .tint(Color.themePrimary)

            DatePicker(
                isAllDay ? "Date" : "Date & Time",
                selection: $date,
                displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .tint(Color.themePrimary)

            if !isNew {
                Toggle(isOn: $isCompleted) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mark completed")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.themeText)

                        Text("Useful when the calendar doubles as your done list.")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                }
                .tint(Color.themeSuccess)
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var quickTimeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Time")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    editorShortcut(title: "Now", symbol: "clock.fill") {
                        Haptics.selection()
                        date = Date()
                        isAllDay = false
                    }

                    editorShortcut(title: "Morning", symbol: "sunrise.fill") {
                        Haptics.selection()
                        date = timeOnCurrentDay(hour: 8, minute: 0)
                        isAllDay = false
                    }

                    editorShortcut(title: "Tonight", symbol: "moon.stars.fill") {
                        Haptics.selection()
                        date = timeOnCurrentDay(hour: 19, minute: 30)
                        isAllDay = false
                    }

                    editorShortcut(title: "Tomorrow", symbol: "arrow.right.circle.fill") {
                        Haptics.selection()
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                        date = isAllDay ? tomorrow : Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
                    }
                }
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var iconCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Style")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.themeSecondaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(EventIconLibrary.options, id: \.self) { symbol in
                            Button(action: {
                                Haptics.selection()
                                iconName = symbol
                            }) {
                                Image(systemName: symbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(iconName == symbol ? .white : Color.themeText)
                                    .frame(width: 46, height: 46)
                                    .background(iconName == symbol ? selectedTint : Color.themeBackground.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Color")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.themeSecondaryText)

                HStack(spacing: 12) {
                    ForEach(EventTintPalette.options) { option in
                        Button(action: {
                            Haptics.selection()
                            tintHex = option.hex
                        }) {
                            Circle()
                                .fill(EventTintPalette.color(for: option.hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(tintHex == option.hex ? 0.95 : 0), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.themeBackground.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundColor(Color.themeText)
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedTint: Color {
        EventTintPalette.color(for: tintHex)
    }

    private var previewSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = isAllDay ? "EEEE, MMM d" : "EEEE, MMM d • h:mm a"
        return (isAllDay ? "All day • " : "") + formatter.string(from: date)
    }

    private func editorShortcut(title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.themePrimary)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.themeText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.themeBackground.opacity(0.3))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func timeOnCurrentDay(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private func saveEvent() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return
        }

        let eventToSave = Event(
            id: eventId,
            title: trimmedTitle,
            date: isAllDay ? Calendar.current.startOfDay(for: date) : date,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isCompleted: isCompleted,
            iconName: iconName,
            tintHex: tintHex,
            isAllDay: isAllDay
        )

        if isNew {
            eventService.addEvent(eventToSave)
        } else {
            eventService.updateEvent(eventToSave)
        }

        Haptics.success()
        dismiss()
    }
}

struct EventEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EventEditorView(initialDate: Date())
                .preferredColorScheme(.dark)
                .previewDisplayName("New Event")

            EventEditorView(event: Event(
                id: UUID(),
                title: "Sample Event",
                date: Date(),
                notes: "This is a sample event note",
                isCompleted: false,
                iconName: "target",
                tintHex: EventTintPalette.options[0].hex
            ))
            .preferredColorScheme(.dark)
            .previewDisplayName("Edit Event")
        }
    }
}
