import SwiftUI

/// Calendar view - focused on events and important dates
struct CalendarView: View {
    @ObservedObject private var eventService = EventService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingEventEditor = false
    @State private var editingEvent: Event?
    @State private var selectedDate = Date()
    
    var body: some View {
        ZStack {
            // Background
            Color.themeBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("CALENDAR & EVENTS")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                            .tracking(2)
                            .padding(.top, 20)
                        
                        Text("Track Important Dates")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeText)
                    }
                    
                    // Week calendar
                    VStack(spacing: 15) {
                        HStack {
                            Text("THIS WEEK")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText)
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                editingEvent = nil
                                showingEventEditor = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Add Event")
                                        .font(.caption)
                                }
                                .foregroundColor(Color.themePrimary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ThemeCalendarWeekView(selectedDate: $selectedDate)
                            .padding(.vertical, 10)
                    }
                    
                    // Selected date section
                    VStack(spacing: 16) {
                        HStack {
                            let formatter: DateFormatter = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "EEEE, MMMM d"
                                return formatter
                            }()
                            
                            Text(formatter.string(from: selectedDate))
                                .font(.headline)
                                .foregroundColor(Color.themeText)
                            
                            Spacer()
                            
                            // Today shortcut button
                            if !Calendar.current.isDateInToday(selectedDate) {
                                Button(action: {
                                    withAnimation {
                                        selectedDate = Date()
                                    }
                                }) {
                                    Text("Today")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.themePrimary.opacity(0.2))
                                        .foregroundColor(Color.themePrimary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Events for selected date
                        VStack(spacing: 10) {
                            let eventsForDay = eventService.getEvents(for: selectedDate)
                            
                            if eventsForDay.isEmpty {
                                // No events state
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 48))
                                        .foregroundColor(Color.themeSecondaryText.opacity(0.5))
                                        .padding(.top, 20)
                                    
                                    Text("No events for this day")
                                        .font(.subheadline)
                                        .foregroundColor(Color.themeSecondaryText)
                                    
                                    Button(action: {
                                        editingEvent = nil
                                        showingEventEditor = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Event")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.themePrimary)
                                        .cornerRadius(12)
                                    }
                                    .padding(.top, 8)
                                    .padding(.bottom, 24)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.themeCardBackground.opacity(0.3))
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                            } else {
                                ForEach(eventsForDay) { event in
                                    ThemeEventListItem(
                                        event: event,
                                        onComplete: {
                                            eventService.toggleCompletionStatus(event)
                                        },
                                        onDelete: {
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
                    
                    // Divider
                    Divider()
                        .background(Color.themeDivider)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 8)
                    
                    // Upcoming events section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("UPCOMING EVENTS")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText)
                                .tracking(2)
                            
                            Spacer()
                            
                            Text("Next 7 Days")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText.opacity(0.7))
                        }
                        .padding(.horizontal, 20)
                        
                        let upcomingEvents = eventService.getUpcomingEvents()
                        
                        if upcomingEvents.isEmpty {
                            Text("No upcoming events")
                                .font(.subheadline)
                                .foregroundColor(Color.themeSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.themeCardBackground.opacity(0.3))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                        } else {
                            ForEach(upcomingEvents) { event in
                                ThemeEventListItem(
                                    event: event,
                                    onComplete: {
                                        eventService.toggleCompletionStatus(event)
                                    },
                                    onDelete: {
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
                    
                    // Event stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("STATISTICS")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                            .tracking(2)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        HStack(spacing: 16) {
                            EventStatCard(
                                value: "\(eventService.getAllEvents().count)",
                                label: "Total Events",
                                icon: "calendar.badge.clock",
                                color: Color.themePrimary
                            )
                            
                            EventStatCard(
                                value: "\(eventService.getUpcomingEvents().count)",
                                label: "Upcoming",
                                icon: "arrow.forward.circle.fill",
                                color: Color.themeWarning
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingEventEditor) {
            if let event = editingEvent {
                EventEditorView(event: event)
            } else {
                EventEditorView(initialDate: selectedDate)
            }
        }
    }
}

// MARK: - Supporting Views

struct EventStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.themeCardBackground)
        .cornerRadius(12)
    }
}

// Reuse the calendar week view from HomeQuoteView
struct ThemeCalendarWeekView: View {
    @ObservedObject var eventService: EventService
    @Binding var selectedDate: Date
    @ObservedObject var themeManager = ThemeManager.shared
    
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
                
                ThemeCalendarDayView(
                    date: date,
                    hasEvents: hasEvents,
                    isSelected: isSelected,
                    isToday: isToday
                )
                .onTapGesture {
                    withAnimation {
                        selectedDate = date
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    func getDateForIndex(_ index: Int) -> Date {
        let firstDayOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return calendar.date(byAdding: .day, value: index, to: firstDayOfWeek)!
    }
}

struct ThemeCalendarDayView: View {
    let date: Date
    let hasEvents: Bool
    let isSelected: Bool
    let isToday: Bool
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack {
            Text(dayFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(isToday ? Color.themeText : Color.themeSecondaryText)
            
            ZStack {
                Circle()
                    .fill(isSelected ? Color.themeText : Color.clear)
                    .frame(width: 30, height: 30)
                
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isSelected ? themeManager.currentTheme.isDark ? Color.themeBackground : Color.themeText : (isToday ? Color.themePrimary : Color.themeText))
            }
            
            if hasEvents {
                Circle()
                    .fill(Color.themePrimary.opacity(0.7))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 60)
        .contentShape(Rectangle())
    }
    
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

struct ThemeEventListItem: View {
    let event: Event
    var onComplete: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onComplete) {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(event.isCompleted ? Color.themeSuccess : Color.themeText)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(Color.themeText)
                    .strikethrough(event.isCompleted)
                
                HStack {
                    Text(timeFormatter.string(from: event.date))
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                    
                    if !event.notes.isEmpty {
                        Text("•")
                            .foregroundColor(Color.themeSecondaryText)
                        
                        Text(event.notes)
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 5)
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(Color.themeText)
                    .font(.system(size: 16))
                    .padding(5)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(Color.themeError)
                    .font(.system(size: 16))
                    .padding(5)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .background(Color.themeCardBackground.opacity(0.3))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}

// MARK: - Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .preferredColorScheme(.dark)
    }
}
