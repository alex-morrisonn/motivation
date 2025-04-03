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
