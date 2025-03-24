import SwiftUI

// Calendar day cell
struct CalendarDayView: View {
    let date: Date
    let hasEvents: Bool
    let isSelected: Bool
    let isToday: Bool
    
    init(date: Date, hasEvents: Bool, isSelected: Bool, isToday: Bool) {
        self.date = date
        self.hasEvents = hasEvents
        self.isSelected = isSelected
        self.isToday = isToday
    }
    
    var body: some View {
        VStack {
            Text(dayFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(isToday ? .white : .gray)
            
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
    
    // Date formatters
    var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
}

// Calendar week view
struct CalendarWeekView: View {
    @ObservedObject var eventService: EventService
    @Binding var selectedDate: Date
    
    let calendar = Calendar.current
    let daysInWeek = 7
    
    init(eventService: EventService = EventService.shared, selectedDate: Binding<Date>) {
        self.eventService = eventService
        self._selectedDate = selectedDate
    }
    
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
    
    // Get date for the index in the week view
    func getDateForIndex(_ index: Int) -> Date {
        let today = calendar.startOfDay(for: Date())
        let firstDayOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return calendar.date(byAdding: .day, value: index, to: firstDayOfWeek)!
    }
}

// Event list item for a specific date
struct EventListItem: View {
    let event: Event
    var onComplete: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    init(event: Event, onComplete: @escaping () -> Void, onDelete: @escaping () -> Void, onEdit: @escaping () -> Void) {
        self.event = event
        self.onComplete = onComplete
        self.onDelete = onDelete
        self.onEdit = onEdit
    }
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
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

// Event Editor View
struct EventEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var eventService: EventService
    
    @State private var title: String
    @State private var date: Date
    @State private var notes: String
    @State private var isCompleted: Bool
    
    private let isNew: Bool
    private var event: Event?
    
    // For new event
    init(eventService: EventService = EventService.shared) {
        self.eventService = eventService
        _title = State(initialValue: "")
        _date = State(initialValue: Date())
        _notes = State(initialValue: "")
        _isCompleted = State(initialValue: false)
        isNew = true
        event = nil
    }
    
    // For editing existing event
    init(event: Event, eventService: EventService = EventService.shared) {
        self.eventService = eventService
        _title = State(initialValue: event.title)
        _date = State(initialValue: event.date)
        _notes = State(initialValue: event.notes)
        _isCompleted = State(initialValue: event.isCompleted)
        isNew = false
        self.event = event
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text(isNew ? "Add New Event" : "Edit Event")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
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
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .padding(5)
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                Toggle(isOn: $isCompleted) {
                    Text("Completed")
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                
                HStack {
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
                
                Spacer()
            }
        }
    }
    
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
