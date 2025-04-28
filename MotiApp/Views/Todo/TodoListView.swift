import SwiftUI
import Combine

// MARK: - Priority Enum
enum Priority: String, CaseIterable, Identifiable {
    case low, normal, high

    var id: String { self.rawValue }

    var name: String {
        switch self {
        case .low:
            return "Low"
        case .normal:
            return "Normal"
        case .high:
            return "High"
        }
    }
}

// MARK: - Celebration Quote Helper
struct CelebrationQuote {
    private static let celebrationQuotes = [
        "Great job! One step closer to your goals.",
        "Progress is progress, no matter how small!",
        "That's the way to get things done!",
        "You're on fire today!",
        "Fantastic! Keep up the momentum.",
        "Productivity win! Keep going!",
        "Crushing it! What's next?",
        "Success is built one task at a time.",
        "You're making it happen!",
        "Checked off and moving forward!"
    ]
    
    static func randomQuote() -> String {
        celebrationQuotes.randomElement() ?? celebrationQuotes[0]
    }
}

// MARK: - Progress Ring View
struct ProgressRingView: View {
    let progress: Double   // 0.0 to 1.0
    let totalTasks: Int
    let completedTasks: Int
    let streakDays: Int
    let ringColor: Color
    let size: CGFloat

    init(progress: Double, totalTasks: Int, completedTasks: Int, streakDays: Int, ringColor: Color = Color.themePrimary, size: CGFloat = 120) {
        self.progress = min(max(progress, 0.0), 1.0) // Clamp between 0 and 1
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.streakDays = streakDays
        self.ringColor = ringColor
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.2)
                .foregroundColor(ringColor)
            
            // Progress ring
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundColor(ringColor)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            // Center content
            VStack(spacing: 4) {
                Text("\(completedTasks)/\(totalTasks)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.themeText)
                
                Text("Tasks")
                    .font(.system(size: 12))
                    .foregroundColor(Color.themeSecondaryText)
                
                if streakDays > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.themeWarning)
                        
                        Text("\(streakDays) days")
                            .font(.system(size: 10))
                            .foregroundColor(Color.themeWarning)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .frame(width: size, height: size)
    }
}


// MARK: - Enhanced Todo Item Row
struct EnhancedTodoItemRow: View {
    // TodoItem is now a class
    let todo: TodoItem
    let isRecentlyCompleted: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // For forcing component refresh
    @ObservedObject private var todoService = TodoService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // State for animations and gestures
    @State private var offset: CGFloat = 0
    
    // The fixed width for the delete button - reduced width
    private let deleteButtonWidth: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // Delete button in a sub-view - smaller size
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("Delete")
                            .font(.subheadline)
                    }
                    .foregroundColor(Color.themeText)
                    .frame(width: deleteButtonWidth, height: 50)
                    .background(Color.themeError.opacity(0.8))
                    .cornerRadius(8)
                }
                .offset(x: min(0, offset + deleteButtonWidth))
                
                // Main content
                VStack(spacing: 8) {
                    // Top row with title and actions
                    HStack(spacing: 16) {
                        // Checkbox - green when completed, priority color when not
                        Button(action: onToggle) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 26))
                                .foregroundColor(todo.isCompleted ? Color.themeSuccess : getPriorityColor())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Title
                        Text(todo.title)
                            .font(.title3)
                            .foregroundColor(Color.themeText)
                            .strikethrough(todo.isCompleted)
                        
                        Spacer()
                        
                        // Priority badge with appropriate color but smaller
                        Text(todo.priority.name)
                            .font(.caption)
                            .foregroundColor(Color.themeText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(getPriorityColor())
                            .cornerRadius(10)
                        
                        // Edit button - smaller size
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.themeText)
                                .padding(.horizontal, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Due date info row (only if due date exists)
                    if let formattedDueDate = todo.formattedDueDate {
                        HStack(spacing: 6) {
                            // Subtle spacer to align with checkbox
                            Spacer()
                                .frame(width: 42)
                            
                            // Due date information
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(todo.isOverdue ? Color.themeError.opacity(0.8) : Color.themeSecondaryText.opacity(0.8))
                                
                                Text("Due \(formattedDueDate)")
                                    .font(.caption)
                                    .foregroundColor(todo.isOverdue ? Color.themeError.opacity(0.8) : Color.themeSecondaryText.opacity(0.8))
                                
                                if todo.isOverdue {
                                    Text("OVERDUE")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Color.themeText)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.themeError.opacity(0.8))
                                        .cornerRadius(3)
                                }
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.themeCardBackground)
                .cornerRadius(8)
                .offset(x: offset)
            }
            .frame(width: geometry.size.width)
            .gesture(dragGesture)
            // Use the refreshTrigger to force updates when completion status changes
            .id("todo-row-\(todo.id)-\(todo.isCompleted)-\(todoService.refreshTrigger)")
        }
        .frame(height: todo.formattedDueDate != nil ? 90 : 80) // Adjusted height based on whether there's a due date
        .padding(.horizontal)
    }
    
    // Helper to get priority color
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
    
    // Drag gesture to reveal the delete button
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                if gesture.translation.width < 0 {
                    // Swipe left to reveal delete button
                    self.offset = max(gesture.translation.width, -deleteButtonWidth)
                } else if offset != 0 {
                    // Allow swiping right to hide delete button
                    self.offset = min(0, offset + gesture.translation.width)
                }
            }
            .onEnded { _ in
                withAnimation(.spring()) {
                    if self.offset < -deleteButtonWidth * 0.5 {
                        self.offset = -deleteButtonWidth
                    } else {
                        self.offset = 0
                    }
                }
            }
    }
}


// MARK: - Todo List View
struct TodoListView: View {
    @ObservedObject private var todoService = TodoService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingAddTodo = false
    @State private var editingTodo: TodoItem?
    @State private var showCompletedTodos = false
    @State private var completionCelebrationOffset: CGFloat = 100
    @State private var showCelebrationToast = false
    @State private var celebrationQuote = ""
    @State private var lastCompletedTodoID: UUID?
    
    // For haptic feedback
    private let successHaptic = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            Color.themeBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                // Header
                Text("To-Do List")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                    .padding(.top, 16)
                
                // Daily progress ring area
                VStack {
                    let totalTasks = todoService.todos.filter { Calendar.current.isDateInToday($0.createdDate) }.count
                    let completedTasks = todoService.getCompletedTodosForToday().count
                    let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
                    
                    ProgressRingView(
                        progress: progress,
                        totalTasks: totalTasks,
                        completedTasks: completedTasks,
                        streakDays: todoService.currentStreakDays,
                        ringColor: progress >= 1.0 ? Color.themeSuccess : Color.themePrimary
                    )
                    .padding(.vertical, 20)
                    .animation(.spring(response: 0.5), value: completedTasks)
                    
                    if todoService.hasMomentumToday {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color.themeWarning)
                            Text("Momentum Streak: \(todoService.currentStreakDays) \(todoService.currentStreakDays == 1 ? "day" : "days")")
                                .foregroundColor(Color.themeWarning)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 12)
                        .background(Color.themeWarning.opacity(0.1))
                        .cornerRadius(10)
                    } else if totalTasks > 0 {
                        Text("Complete \(max(3 - completedTasks, 0)) more tasks for Momentum")
                            .foregroundColor(Color.themeSecondaryText)
                            .font(.caption)
                    }
                }
                .padding(.bottom, 10)
                
                // Filter toggle and add button
                HStack {
                    Toggle(isOn: $showCompletedTodos) {
                        Text("Show Completed")
                            .font(.subheadline)
                            .foregroundColor(Color.themeText)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                    
                    Spacer()
                    
                    Button(action: { showingAddTodo = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Task")
                        }
                        .foregroundColor(Color.themeText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.themePrimary.opacity(0.3))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                
                // Main content view for todos
                if todoService.todos.isEmpty {
                    emptyStateView
                } else {
                    todoListContent
                }
            }
            .padding(.bottom, 30)
            
            // Celebration toast overlay
            if showCelebrationToast {
                VStack {
                    Spacer()
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.themeSuccess)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Task Completed!")
                                .font(.headline)
                                .foregroundColor(Color.themeText)
                            
                            Text(celebrationQuote)
                                .font(.caption)
                                .foregroundColor(Color.themeText.opacity(0.9))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            dismissCelebrationToast()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.themeText.opacity(0.7))
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.themeSuccess.opacity(0.7), Color.themePrimary.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .offset(y: completionCelebrationOffset)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: completionCelebrationOffset)
                    .onAppear {
                        completionCelebrationOffset = 0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            dismissCelebrationToast()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTodo) {
            TodoEditorView()
        }
        .sheet(item: $editingTodo) { todo in
            TodoEditorView(todo: todo)
        }
    }
    
    // Dismiss the celebration toast with animation.
    private func dismissCelebrationToast() {
        withAnimation {
            completionCelebrationOffset = 100
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCelebrationToast = false
        }
    }
    
    // View displayed when there are no todos.
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(Color.themeSecondaryText)
                .padding()
            Text("No tasks yet")
                .font(.headline)
                .foregroundColor(Color.themeText)
            Text("Tap the Add Task button to create your first task")
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)
                .multilineTextAlignment(.center)
                .padding()
            Button(action: { showingAddTodo = true }) {
                Text("Create Task")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.isDark ? Color.black : Color.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary)
                    .cornerRadius(20)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Main list content
    private var todoListContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !showCompletedTodos {
                    let incompleteTodos = todoService.getIncompleteTodos()
                    if !incompleteTodos.isEmpty {
                        HStack {
                            Text("ACTIVE TASKS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeText.opacity(0.6))
                                .tracking(2)
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        ForEach(incompleteTodos) { todo in
                            EnhancedTodoItemRow(
                                todo: todo,
                                isRecentlyCompleted: lastCompletedTodoID == todo.id,
                                onToggle: { handleTaskCompletion(todo) },
                                onEdit: { editingTodo = todo },
                                onDelete: {
                                    withAnimation {
                                        todoService.deleteTodo(todo)
                                    }
                                }
                            )
                        }
                    }
                    
                    let overdueTodos = todoService.getOverdueTodos()
                    if !overdueTodos.isEmpty {
                        HStack {
                            Text("OVERDUE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeError.opacity(0.8))
                                .tracking(2)
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        ForEach(overdueTodos) { todo in
                            EnhancedTodoItemRow(
                                todo: todo,
                                isRecentlyCompleted: lastCompletedTodoID == todo.id,
                                onToggle: { handleTaskCompletion(todo) },
                                onEdit: { editingTodo = todo },
                                onDelete: {
                                    withAnimation {
                                        todoService.deleteTodo(todo)
                                    }
                                }
                            )
                        }
                    }
                } else {
                    let completedTodos = todoService.getCompletedTodos()
                    if !completedTodos.isEmpty {
                        HStack {
                            Text("COMPLETED")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeText.opacity(0.6))
                                .tracking(2)
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        ForEach(completedTodos) { todo in
                            EnhancedTodoItemRow(
                                todo: todo,
                                isRecentlyCompleted: false,
                                onToggle: {
                                    withAnimation {
                                        todoService.toggleCompletionStatus(todo)
                                    }
                                },
                                onEdit: { editingTodo = todo },
                                onDelete: {
                                    withAnimation {
                                        todoService.deleteTodo(todo)
                                    }
                                }
                            )
                        }
                    } else {
                        VStack {
                            Text("No completed tasks")
                                .font(.subheadline)
                                .foregroundColor(Color.themeSecondaryText)
                                .padding(.top, 30)
                        }
                    }
                }
            }
            .padding(.bottom, 50)
        }
    }
    
    // Handle a task completion and trigger celebration feedback.
    private func handleTaskCompletion(_ todo: TodoItem) {
        lastCompletedTodoID = todo.id
        successHaptic.notificationOccurred(.success)
        celebrationQuote = CelebrationQuote.randomQuote()
        
        withAnimation {
            todoService.toggleCompletionStatus(todo)
        }
        
        showCelebrationToast = true
        completionCelebrationOffset = 0
    }
}
