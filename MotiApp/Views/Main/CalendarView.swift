import SwiftUI

/// Calendar view - focused on events and important dates
struct CalendarView: View {
    @ObservedObject private var eventService = EventService.shared
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
                        
                        CalendarWeekView(selectedDate: $selectedDate)
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
                                    EventListItem(
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
                                EventListItem(
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
                                value: "\(eventService.events.count)",
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

// MARK: - Preview

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .preferredColorScheme(.dark)
    }
}
