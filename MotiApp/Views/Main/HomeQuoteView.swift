import SwiftUI

// Home Quote View with Calendar and Todo List
struct HomeQuoteView: View {
    @ObservedObject private var quoteService = QuoteService.shared
    @ObservedObject private var eventService = EventService.shared
    @ObservedObject private var todoService = TodoService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
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
            // Background - use theme background color
            Color.themeBackground.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Quote of the day section
                    VStack {
                        Text("QUOTE OF THE DAY")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                            .tracking(2)
                            .padding(.top, 20)
                        
                        // Updated QuoteCardView with theme colors
                        ThemeQuoteCardView(
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
                    
                    // Divider with theme color
                    Divider()
                        .background(Color.themeDivider)
                        .padding(.horizontal, 40)
                    
                    // Todo section
                    VStack(spacing: 15) {
                        // Todo header with add button
                        HStack {
                            Text("TODAY'S TASKS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeText.opacity(0.6))
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                // Navigate to the Todo tab
                                TabNavigationHelper.shared.switchToTab(2)
                            }) {
                                Text("See All")
                                    .font(.caption)
                                    .foregroundColor(Color.themePrimary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Todo list preview
                        VStack(spacing: 10) {
                            let highPriorityTodos = todoService.getIncompleteTodos().filter { $0.priority == .high }
                            let otherTodos = todoService.getIncompleteTodos().filter { $0.priority != .high }
                            
                            // Show high priority todos first
                            ForEach(highPriorityTodos.prefix(2)) { todo in
                                ThemeHomeTodoRow(todo: todo)
                            }
                            
                            // Then show other todos
                            ForEach(otherTodos.prefix(3 - min(2, highPriorityTodos.count))) { todo in
                                ThemeHomeTodoRow(todo: todo)
                            }
                            
                            // No tasks message or add button
                            if todoService.getIncompleteTodos().isEmpty {
                                VStack(spacing: 10) {
                                    Text("No active tasks")
                                        .font(.subheadline)
                                        .foregroundColor(Color.themeSecondaryText)
                                        .padding(.top, 10)
                                    
                                    Button(action: {
                                        // Navigate to the Todo tab
                                        TabNavigationHelper.shared.switchToTab(2)
                                    }) {
                                        Text("Add Task")
                                            .font(.caption)
                                            .foregroundColor(Color.themeText)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.themePrimary.opacity(0.3))
                                            .cornerRadius(20)
                                    }
                                    .padding(.bottom, 10)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.themeBackground.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Divider with theme color
                    Divider()
                        .background(Color.themeDivider)
                        .padding(.horizontal, 40)
                    
                    // Calendar section
                    VStack(spacing: 15) {
                        // Calendar title with add button
                        HStack {
                            Text("IMPORTANT DATES")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeText.opacity(0.6))
                                .tracking(2)
                            
                            Spacer()
                            
                            Button(action: {
                                editingEvent = nil
                                showingEventEditor = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color.themeText)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Week calendar
                        ThemeCalendarWeekView(selectedDate: $selectedDate)
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
                                .foregroundColor(Color.themeText)
                            
                            Spacer()
                            
                            // Today shortcut button
                            Button(action: {
                                // Set dueDate to today at the same time
                                selectedDate = Date()
                            }) {
                                Text("Today")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.themePrimary.opacity(0.3))
                                    .cornerRadius(8)
                            }
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
                                        .foregroundColor(Color.themeSecondaryText)
                                        .padding(.top, 20)
                                    
                                    Text("No events for this day")
                                        .font(.subheadline)
                                        .foregroundColor(Color.themeSecondaryText)
                                    
                                    Button(action: {
                                        editingEvent = nil
                                        showingEventEditor = true
                                    }) {
                                        Text("Add Event")
                                            .font(.headline)
                                            .foregroundColor(themeManager.currentTheme.isDark ? Color.themeBackground : Color.themeText)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color.themePrimary)
                                            .cornerRadius(20)
                                    }
                                    .padding(.top, 10)
                                    .padding(.bottom, 20)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color.themeCardBackground.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
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
                        
                        // Upcoming events section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("UPCOMING EVENTS")
                                .font(.caption)
                                .foregroundColor(Color.themeSecondaryText)
                                .tracking(2)
                                .padding(.top, 10)
                                .padding(.horizontal, 20)
                            
                            let upcomingEvents = eventService.getUpcomingEvents()
                            
                            if upcomingEvents.isEmpty {
                                Text("No upcoming events for the next 7 days")
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeSecondaryText)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
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

// MARK: - Theme Components

// Updated QuoteCardView with theme colors
struct ThemeQuoteCardView: View {
    let quote: Quote
    let isFavorite: Bool
    var onFavoriteToggle: () -> Void
    var onShare: () -> Void
    var onRefresh: (() -> Void)?
    
    var body: some View {
        VStack {
            Text(quote.text)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Color.themeText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text("— \(quote.author)")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color.themeSecondaryText)
                .padding(.top, 16)
                .padding(.bottom, 30)
            
            // Action Buttons - All on one line with equal spacing
            HStack {
                Spacer()
                
                // Favorite Button
                Button(action: {
                    onFavoriteToggle()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(isFavorite ? Color.themeError : Color.themeText)
                }
                
                Spacer()
                
                // Refresh Button (only if provided)
                if let refreshAction = onRefresh {
                    Button(action: {
                        refreshAction()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 22))
                            .foregroundColor(Color.themeText)
                    }
                    
                    Spacer()
                }
                
                // Share Button
                Button(action: {
                    onShare()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 22))
                        .foregroundColor(Color.themeText)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// Updated HomeTodoRow with theme colors
struct ThemeHomeTodoRow: View {
    @ObservedObject private var todoService = TodoService.shared
    let todo: TodoItem
    
    var body: some View {
        Button(action: {
            // Navigate to Todo tab instead of completing the task
            TabNavigationHelper.shared.switchToTab(2)
        }) {
            HStack {
                // Completion checkbox - green when completed
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? Color.themeSuccess : getPriorityColor())
                    .font(.system(size: 18))
                
                // Todo title and due time
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.themeText)
                        .strikethrough(todo.isCompleted)
                        .lineLimit(1)
                    
                    // Due date or priority
                    if let formattedDueDate = todo.formattedDueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            
                            Text(formattedDueDate)
                                .font(.caption)
                            
                            // Overdue indicator
                            if todo.isOverdue {
                                Text("OVERDUE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Color.themeText)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.themeError)
                                    .cornerRadius(3)
                            }
                        }
                        .foregroundColor(todo.isOverdue ? Color.themeError : Color.themeSecondaryText)
                    } else {
                        // If no due date, show priority
                        Text("Priority: \(todo.priority.name)")
                            .font(.caption)
                            .foregroundColor(getPriorityColor())
                    }
                }
                
                Spacer()
                
                // Navigate to edit
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(Color.themeSecondaryText)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.themeCardBackground.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .contextMenu {
            // Mark as complete/incomplete - keep this functionality in the context menu
            Button(action: {
                withAnimation {
                    todoService.toggleCompletionStatus(todo)
                }
            }) {
                Label(
                    todo.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                    systemImage: todo.isCompleted ? "circle" : "checkmark.circle"
                )
            }
            
            // Navigate to edit view
            Button(action: {
                // Navigate to the Todo tab
                TabNavigationHelper.shared.switchToTab(2)
            }) {
                Label("View All Tasks", systemImage: "list.bullet")
            }
            
            Divider()
            
            // Delete option
            Button(role: .destructive, action: {
                todoService.deleteTodo(todo)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        // Use the refreshTrigger to force updates when completion status changes
        .id("home-todo-\(todo.id)-\(todo.isCompleted)-\(todoService.refreshTrigger)")
    }
    
    // Get color based on priority
    private func getPriorityColor() -> Color {
        switch todo.priority {
        case .low:
            return Color.themeSuccess
        case .normal:
            return Color.themePrimary
        case .high:
            return Color.themeError
        }
    }
}

// Updated CalendarWeekView with theme colors
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
                    selectedDate = date
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Calculate the date for each index in the week view
    func getDateForIndex(_ index: Int) -> Date {
        let firstDayOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return calendar.date(byAdding: .day, value: index, to: firstDayOfWeek)!
    }
}

// Updated CalendarDayView with theme colors
struct ThemeCalendarDayView: View {
    let date: Date
    let hasEvents: Bool
    let isSelected: Bool
    let isToday: Bool
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack {
            // Day of week label (Mon, Tue, etc.)
            Text(dayFormatter.string(from: date))
                .font(.caption)
                .foregroundColor(isToday ? Color.themeText : Color.themeSecondaryText)
            
            // Date number with selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? Color.themeText : Color.clear)
                    .frame(width: 30, height: 30)
                
                Text(dateFormatter.string(from: date))
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isSelected ? themeManager.currentTheme.isDark ? Color.themeBackground : Color.themeText : (isToday ? Color.themePrimary : Color.themeText))
            }
            
            // Indicator for events
            if hasEvents {
                Circle()
                    .fill(Color.themePrimary.opacity(0.7))
                    .frame(width: 5, height: 5)
            }
        }
        .frame(height: 60)
        .contentShape(Rectangle())
    }
    
    // Formatters
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

// Updated EventListItem with theme colors
struct ThemeEventListItem: View {
    let event: Event
    var onComplete: () -> Void
    var onDelete: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        HStack {
            // Completion checkbox
            Button(action: onComplete) {
                Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(event.isCompleted ? Color.themeSuccess : Color.themeText)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Event details
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
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(Color.themeText)
                    .font(.system(size: 16))
                    .padding(5)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(Color.themeText)
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
    
    // Time formatter
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}

// MARK: - Preview Provider

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
