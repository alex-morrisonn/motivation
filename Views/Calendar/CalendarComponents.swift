import SwiftUI

// MARK: - Calendar Day View Component

/// A view representing a single day cell in the calendar
struct CalendarDayView: View {
    // MARK: Properties
    let date: Date
    let hasEvents: Bool
    let isSelected: Bool
    let isToday: Bool
    
    // MARK: Initializer
    init(date: Date, hasEvents: Bool, isSelected: Bool, isToday: Bool) {
        self.date = date
        self.hasEvents = hasEvents
        self.isSelected = isSelected
        self.isToday = isToday
    }
    
    // MARK: View Body
    var body: some View {
        VStack {
            // Day of week label (Mon, Tue, etc.)
            Text(dayFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(isToday ? .white : .gray)
            
            // Date number with selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .frame(width: 30, height: 30)
                
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isSelected ? .black : (isToday ? .white : .white))
            }
            
            // Indicator for events
            if hasEvents {
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 60)
        .contentShape(Rectangle())
    }
    
    // MARK: Formatters
    
    /// Formatter for day of week (e.g., "Mon")
    var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    /// Formatter for day number (e.g., "15")
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
}

// MARK: - Calendar Week View Component

/// A horizontal week view showing 7 days with event indicators
struct CalendarWeekView: View {
    // MARK: Properties
    @ObservedObject var eventService: EventService
    @Binding var selectedDate: Date
    
    let calendar = Calendar.current
    let daysInWeek = 7
    
    // MARK: Initializer
    init(eventService: EventService = EventService.shared, selectedDate: Binding<Date>) {
        self.eventService = eventService
        self._selectedDate = selectedDate
    }
    
    // MARK: View Body
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<daysInWeek, id: \.self) { index in
                let date = getDateForIndex(index)
                let hasEvents = !eventService.getEvents(for: date).isEmpty
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDateInToday(date)
                
                CalendarDayView(
                    date: date,
                    hasEvents: hasEvents,
                    isSelected: isSelected,
                    isToday: isToday
                )
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: Helper Methods
    
    /// Calculate the date for each index in the week view
    /// - Parameter index: The index position (0-6)
    /// - Returns: The corresponding date
    func getDateForIndex(_ index: Int) -> Date {
        let firstDayOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return calendar.date(byAdding: .day, value: index, to: firstDayOfWeek)!
    }
}

// MARK: - Event List Item Component

/// A list item representing a single event with action buttons
struct EventListItem: View {
    // MARK: Properties
    let event: Event
    var onComplete: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    // MARK: Initializer
    init(event: Event, onComplete: @escaping () -> Void, onDelete: @escaping () -> Void, onEdit: @escaping () -> Void) {
        self.event = event
        self.onComplete = onComplete
        self.onDelete = onDelete
        self.onEdit = onEdit
    }
    
    // MARK: Time Formatter
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    // MARK: View Body
    var body: some View {
        HStack {
            // Completion checkbox
            Button(action: onComplete) {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(event.isCompleted ? .green : .white)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .strikethrough(event.isCompleted)
                
                HStack {
                    Text(timeFormatter.string(from: event.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if !event.notes.isEmpty {
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(event.notes)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 5)
            
            Spacer()
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding(5)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .padding(5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Event Editor View

/// A form for creating and editing events
struct EventEditorView: View {
    // MARK: Environment & State
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var eventService: EventService
    
    @State private var title: String
    @State private var date: Date
    @State private var notes: String
    @State private var isCompleted: Bool
    
    // MARK: Properties
    private let isNew: Bool
    private var event: Event?
    
    // MARK: Initializers
    
    /// Initialize for creating a new event
    /// - Parameters:
    ///   - eventService: The event service
    ///   - initialDate: The initial date to use (defaults to current date)
    init(eventService: EventService = EventService.shared, initialDate: Date = Date()) {
        self.eventService = eventService
        _title = State(initialValue: "")
        _date = State(initialValue: initialDate)
        _notes = State(initialValue: "")
        _isCompleted = State(initialValue: false)
        isNew = true
        event = nil
    }
    
    /// Initialize for editing an existing event
    /// - Parameters:
    ///   - event: The event to edit
    ///   - eventService: The event service
    init(event: Event, eventService: EventService = EventService.shared) {
        self.eventService = eventService
        _title = State(initialValue: event.title)
        _date = State(initialValue: event.date)
        _notes = State(initialValue: event.notes)
        _isCompleted = State(initialValue: event.isCompleted)
        isNew = false
        self.event = event
    }
    
    // MARK: View Body
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Form header
                    Text(isNew ? "Add New Event" : "Edit Event")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Title field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Event Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter title", text: $title)
                            .padding()
                            .background(Color(UIColor.systemGray6).opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Date & time picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Date & Time")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DatePicker("", selection: $date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .background(Color(UIColor.systemGray6).opacity(0.2))
                            .cornerRadius(10)
                            .colorScheme(.dark)
                    }
                    .padding(.horizontal)
                    
                    // Notes field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(5)
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .colorScheme(.dark) // Force dark mode for TextEditor
                            
                            if notes.isEmpty {
                                Text("Add notes here...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 13)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Completed toggle
                    Toggle(isOn: $isCompleted) {
                        Text("Completed")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Action buttons
                    HStack {
                        // Cancel button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        }
                        
                        // Save button
                        Button(action: {
                            saveEvent()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    
                    // Add padding at the bottom to ensure scrolling can reach all content
                    Spacer(minLength: 30)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: Helper Methods
    
    /// Save the current event data
    private func saveEvent() {
        let newEvent = Event(
            id: event?.id ?? UUID(),
            title: title,
            date: date,
            notes: notes,
            isCompleted: isCompleted
        )
        
        if isNew {
            eventService.addEvent(newEvent)
        } else {
            eventService.updateEvent(newEvent)
        }
    }
}

// MARK: - Preview Providers

struct CalendarDayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            CalendarDayView(
                date: Date(),
                hasEvents: true,
                isSelected: true,
                isToday: true
            )
        }
        .previewLayout(.sizeThatFits)
    }
}

struct CalendarWeekView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            CalendarWeekView(
                selectedDate: .constant(Date())
            )
        }
        .previewLayout(.sizeThatFits)
    }
}

struct EventListItem_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            EventListItem(
                event: Event(
                    title: "Team Meeting",
                    date: Date(),
                    notes: "Discuss project timeline",
                    isCompleted: false
                ),
                onComplete: {},
                onDelete: {},
                onEdit: {}
            )
        }
        .previewLayout(.sizeThatFits)
    }
}

struct EventEditorView_Previews: PreviewProvider {
    static var previews: some View {
        EventEditorView()
    }
}
