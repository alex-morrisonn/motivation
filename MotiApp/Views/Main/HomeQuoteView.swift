import SwiftUI

// Home Quote View with Calendar and Todo List
struct HomeQuoteView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @ObservedObject private var eventService = EventService.shared
    @ObservedObject private var todoService = TodoService.shared
    @State private var quote: Quote
    @State private var showingShareSheet = false
    @State private var showingEventEditor = false
    @State private var editingEvent: Event?
    @State private var selectedDate = Date()
    
    init() {
        // Initialize with today's quote
        _quote = State(initialValue: QuoteService.shared.getTodaysQuote())
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Quote of the day section
                    VStack {
                        Text("QUOTE OF THE DAY")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .tracking(2)
                            .padding(.top, 20)
                        
                        QuoteCardView(
                            quote: quote,
                            isFavorite: quoteService.isFavorite(quote),
                            onFavoriteToggle: {
                                if quoteService.isFavorite(quote) {
                                    quoteService.removeFromFavorites(quote)
                                } else {
                                    quoteService.addToFavorites(quote)
                                }
                            },
                            onShare: {
                                showingShareSheet = true
                            },
                            onRefresh: {
                                // Get a random quote instead of today's quote for more variety
                                quote = quoteService.getRandomQuote()
                            }
                        )
                    }
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 40)
                    
                    // Todo section
                    VStack(spacing: 15) {
                        // Todo header with add button
                        HStack {
                            Text("TODAY'S TASKS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                // Navigate to the Todo tab
                                TabNavigationHelper.shared.switchToTab(2)
                            }) {
                                Text("See All")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Todo list preview
                        VStack(spacing: 10) {
                            let highPriorityTodos = todoService.getIncompleteTodos().filter { $0.priority == .high }
                            let otherTodos = todoService.getIncompleteTodos().filter { $0.priority != .high }
                            
                            // Show high priority todos first
                            ForEach(highPriorityTodos.prefix(2)) { todo in
                                HomeTodoRow(todo: todo)
                            }
                            
                            // Then show other todos
                            ForEach(otherTodos.prefix(3 - min(2, highPriorityTodos.count))) { todo in
                                HomeTodoRow(todo: todo)
                            }
                            
                            // No tasks message or add button
                            if todoService.getIncompleteTodos().isEmpty {
                                VStack(spacing: 10) {
                                    Text("No active tasks")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .padding(.top, 10)
                                    
                                    Button(action: {
                                        // Navigate to the Todo tab
                                        TabNavigationHelper.shared.switchToTab(2)
                                    }) {
                                        Text("Add Task")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.3))
                                            .cornerRadius(20)
                                    }
                                    .padding(.bottom, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 40)
                    
                    // Calendar section
                    VStack(spacing: 15) {
                        // Calendar title with add button
                        HStack {
                            Text("IMPORTANT DATES")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                editingEvent = nil
                                showingEventEditor = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Week calendar
                        CalendarWeekView(selectedDate: $selectedDate)
                            .padding(.vertical, 10)
                        
                        // Selected date title
                        HStack {
                            let formatter: DateFormatter = {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "EEEE, MMMM d"
                                return formatter
                            }()
                            
                            Text(formatter.string(from: selectedDate))
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        
                        // Events for selected date
                        VStack(spacing: 10) {
                            let eventsForDay = eventService.getEvents(for: selectedDate)
                            
                            if eventsForDay.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                        .padding(.top, 20)
                                    
                                    Text("No events for this day")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    Button(action: {
                                        editingEvent = nil
                                        showingEventEditor = true
                                    }) {
                                        Text("Add Event")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                    }
                                    .padding(.top, 10)
                                    .padding(.bottom, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
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
                        
                        // Upcoming events section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("UPCOMING EVENTS")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .tracking(2)
                                .padding(.top, 10)
                                .padding(.horizontal, 20)
                            
                            let upcomingEvents = eventService.getUpcomingEvents()
                            
                            if upcomingEvents.isEmpty {
                                Text("No upcoming events for the next 7 days")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
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
                    }
                }
                // Add extra padding at the bottom to account for tab bar + banner ad
                // Standard tab bar is 49pt + banner ad is 50pt + some extra space
                .padding(.bottom, 110)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: ["\(quote.text) — \(quote.author)"])
        }
        .sheet(isPresented: $showingEventEditor) {
            if let event = editingEvent {
                EventEditorView(event: event)
            } else {
                EventEditorView(initialDate: selectedDate) // Pass selected date here
            }
        }
    }
}

// SwiftUI Preview
struct HomeQuoteView_Previews: PreviewProvider {
    static var previews: some View {
        HomeQuoteView()
            .preferredColorScheme(.dark)
            .onAppear {
                // Add some sample todos for preview
                let todoService = TodoService.shared
                if todoService.todos.isEmpty {
                    for todo in TodoItem.samples {
                        todoService.addTodo(todo)
                    }
                }
            }
    }
}
