import SwiftUI

// Progress Ring View - Modified from your existing implementation
struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0
    let totalTasks: Int
    let completedTasks: Int
    let streakDays: Int
    let ringColor: Color
    let size: CGFloat
    
    init(progress: Double, totalTasks: Int, completedTasks: Int, streakDays: Int,
         ringColor: Color = .blue, size: CGFloat = 120) {
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
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            // Center content
            VStack(spacing: 4) {
                Text("\(completedTasks)/\(totalTasks)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Tasks")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                if streakDays > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        
                        Text("\(streakDays) days")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct TodoListView: View {
    @ObservedObject private var todoService = TodoService.shared
    @State private var showingAddTodo = false
    @State private var editingTodo: TodoItem?
    @State private var showCompletedTodos = false
    @State private var selectedTodoForCompletion: TodoItem?
    @State private var completionCelebrationOffset: CGFloat = 100
    @State private var showCelebrationToast = false
    @State private var celebrationQuote = ""
    @State private var lastCompletedTodoID: UUID?
    
    // For haptic feedback
    private let successHaptic = UINotificationFeedbackGenerator()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                // Header
                Text("To-Do List")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 16)
                
                // Daily progress ring
                VStack {
                    let totalTasks = todoService.todos.filter { Calendar.current.isDateInToday($0.createdDate) }.count
                    let completedTasks = todoService.getCompletedTodosForToday().count
                    let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
                    
                    ProgressRingView(
                        progress: progress,
                        totalTasks: totalTasks,
                        completedTasks: completedTasks,
                        streakDays: todoService.currentStreakDays,
                        ringColor: progress >= 1.0 ? .green : .blue
                    )
                    .padding(.vertical, 20)
                    
                    // Show momentum streak message if applicable
                    if todoService.hasMomentumToday {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            
                            Text("Momentum Streak: \(todoService.currentStreakDays) \(todoService.currentStreakDays == 1 ? "day" : "days")")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    } else if totalTasks > 0 {
                        // Show progress toward momentum
                        Text("Complete \(max(3 - completedTasks, 0)) more tasks for Momentum")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .padding(.bottom, 10)
                
                // Filter toggle
                HStack {
                    Toggle(isOn: $showCompletedTodos) {
                        Text("Show Completed")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    Spacer()
                    
                    // Add button
                    Button(action: {
                        showingAddTodo = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Task")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                
                // Check if list is empty
                if todoService.todos.isEmpty {
                    emptyStateView
                } else {
                    todoListContent
                }
            }
            .padding(.bottom, 30)
            
            // Non-intrusive celebration toast that slides in from the bottom
            if showCelebrationToast {
                VStack {
                    Spacer()
                    
                    HStack(alignment: .center, spacing: 12) {
                        // Checkmark icon with animation
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Task Completed!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(celebrationQuote)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        // Dismiss button
                        Button(action: {
                            dismissCelebrationToast()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.7), Color.blue.opacity(0.7)]),
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
                        // Show the toast
                        completionCelebrationOffset = 0
                        
                        // Auto-hide after 2.5 seconds
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
    
    // Dismiss the celebration toast with animation
    private func dismissCelebrationToast() {
        withAnimation {
            completionCelebrationOffset = 100
        }
        
        // Hide the toast completely after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showCelebrationToast = false
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text("No tasks yet")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Tap the Add Task button to create your first task")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                showingAddTodo = true
            }) {
                Text("Create Task")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(20)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Todo list content
    private var todoListContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Incomplete todos section with overdue indicators
                if !showCompletedTodos {
                    if !todoService.getIncompleteTodos().isEmpty {
                        // Section header for active todos
                        HStack {
                            Text("ACTIVE TASKS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        // Active todos
                        ForEach(todoService.getIncompleteTodos()) { todo in
                            EnhancedTodoItemRow(
                                todo: todo,
                                isRecentlyCompleted: lastCompletedTodoID == todo.id,
                                onToggle: {
                                    handleTaskCompletion(todo)
                                },
                                onEdit: {
                                    editingTodo = todo
                                },
                                onDelete: {
                                    withAnimation {
                                        todoService.deleteTodo(todo)
                                    }
                                }
                            )
                            .transition(.opacity)
                        }
                    }
                    
                    // Overdue todos (only show if there are any)
                    let overdueTodos = todoService.getOverdueTodos()
                    if !overdueTodos.isEmpty {
                        // Section header for overdue
                        HStack {
                            Text("OVERDUE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red.opacity(0.8))
                                .tracking(2)
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        ForEach(overdueTodos) { todo in
                            EnhancedTodoItemRow(
                                todo: todo,
                                isRecentlyCompleted: lastCompletedTodoID == todo.id,
                                onToggle: {
                                    handleTaskCompletion(todo)
                                },
                                onEdit: {
                                    editingTodo = todo
                                },
                                onDelete: {
                                    withAnimation {
                                        todoService.deleteTodo(todo)
                                    }
                                }
                            )
                        }
                    }
                } else {
                    // Completed todos section (only when toggled)
                    let completedTodos = todoService.getCompletedTodos()
                    if !completedTodos.isEmpty {
                        // Section header for completed
                        HStack {
                            Text("COMPLETED")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.leading, 20)
                            Spacer()
                        }
                        .padding(.top, 8)
                        
                        ForEach(completedTodos) { todo in
                            EnhancedTodoItemRow(
                                todo: todo,
                                isRecentlyCompleted: false, // No animation for already completed tasks
                                onToggle: {
                                    // Just toggle status without celebration for already completed tasks
                                    todoService.toggleCompletionStatus(todo)
                                },
                                onEdit: {
                                    editingTodo = todo
                                },
                                onDelete: {
                                    withAnimation {
                                        todoService.deleteTodo(todo)
                                    }
                                }
                            )
                        }
                    } else {
                        // No completed todos message
                        VStack {
                            Text("No completed tasks")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 30)
                        }
                    }
                }
            }
            .padding(.bottom, 50) // Extra padding for bottom of scroll view
        }
    }
    
    // Handle task completion with improved feedback
    private func handleTaskCompletion(_ todo: TodoItem) {
        // Remember the last completed task ID for animation
        lastCompletedTodoID = todo.id
        
        // Trigger success haptic feedback
        successHaptic.notificationOccurred(.success)
        
        // Get a motivational quote
        celebrationQuote = CelebrationQuote.randomQuote()
        
        // Toggle task completion status
        todoService.toggleCompletionStatus(todo)
        
        // Show the non-intrusive celebration toast
        showCelebrationToast = true
        completionCelebrationOffset = 0
    }
}

struct EnhancedTodoItemRow: View {
    let todo: TodoItem
    let isRecentlyCompleted: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // State for the checkbox hover/press animation
    @State private var checkboxScale: CGFloat = 1.0
    @State private var isCheckboxHovered: Bool = false
    @State private var offset: CGFloat = 0
    
    // Hardcoded delete button width to ensure proper offset
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                // Main todo row content
                HStack(alignment: .top, spacing: 12) {
                    // Completion checkbox with improved feedback
                    Button(action: {
                        // Animate button press
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            checkboxScale = 1.4
                        }
                        
                        // Execute action after slight delay for better visual feedback
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                checkboxScale = 1.0
                            }
                            onToggle()
                        }
                    }) {
                        ZStack {
                            // Circle background with hover effect
                            Circle()
                                .fill(Color.gray.opacity(isCheckboxHovered ? 0.2 : 0.0))
                                .frame(width: 36, height: 36)
                            
                            // Checkbox icon
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(todo.isCompleted ? .green : getPriorityColor())
                                .scaleEffect(checkboxScale)
                                .animation(.spring(response: 0.2), value: checkboxScale)
                        }
                        .contentShape(Circle())
                        .onHover { hovering in
                            withAnimation {
                                isCheckboxHovered = hovering
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 2)
                    
                    // Todo content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(todo.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .strikethrough(todo.isCompleted)
                            .lineLimit(1)
                        
                        if !todo.notes.isEmpty {
                            Text(todo.notes)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(2)
                        }
                        
                        // "Why This Matters" field
                        if !todo.whyThisMatters.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.text.square")
                                    .font(.system(size: 12))
                                    .foregroundColor(.pink.opacity(0.8))
                                
                                Text("Why: \(todo.whyThisMatters)")
                                    .font(.caption)
                                    .foregroundColor(.pink.opacity(0.8))
                                    .italic()
                                    .lineLimit(1)
                            }
                            .padding(.top, 4)
                        }
                        
                        // Due date if available
                        if let formattedDueDate = todo.formattedDueDate {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                
                                Text(formattedDueDate)
                                    .font(.caption)
                                
                                // Overdue indicator
                                if todo.isOverdue {
                                    Text("OVERDUE")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .cornerRadius(4)
                                }
                            }
                            .foregroundColor(todo.isOverdue ? .red : .gray)
                            .padding(.top, 2)
                        }
                        
                        // Priority indicator
                        HStack {
                            Text("Priority: \(todo.priority.name)")
                                .font(.caption)
                                .foregroundColor(getPriorityColor())
                        }
                        .padding(.top, 2)
                    }
                    
                    Spacer()
                    
                    // Edit button with conditional visibility - disappears during swipe
                    if offset == 0 {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .padding(8)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 4)
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(isRecentlyCompleted ? 0.3 : 0.1), lineWidth: 1)
                        )
                )
                .offset(x: offset)
                
                // Delete button - positioned on the right edge but only revealed during swipe
                Button(action: onDelete) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth, height: 50)
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .offset(x: min(0, offset + deleteButtonWidth)) // This ensures the button is hidden until swipe
                
            }
            .padding(.horizontal)
            .contentShape(Rectangle())
            .frame(width: geometry.size.width)
            
            // Add the gesture
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width < 0 {
                            // Limit how far you can swipe left (to the width of delete button)
                            self.offset = max(gesture.translation.width, -deleteButtonWidth)
                        } else if offset != 0 {
                            // Allow swiping right to cancel
                            self.offset = min(0, offset + gesture.translation.width)
                        }
                    }
                    .onEnded { gesture in
                        // If swiped far enough, show delete option; otherwise reset
                        withAnimation(.spring()) {
                            if self.offset < -deleteButtonWidth * 0.5 {
                                self.offset = -deleteButtonWidth // Expose delete button
                            } else {
                                self.offset = 0 // Reset position
                            }
                        }
                    }
            )
            
            // Overlay effect for recently completed tasks
            .overlay(
                isRecentlyCompleted ?
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.green.opacity(0.3), .clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.7)
                    .blendMode(.overlay)
                : nil
            )
            
            // Context menu for additional options
            .contextMenu {
                Button(action: onToggle) {
                    Label(
                        todo.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                        systemImage: todo.isCompleted ? "circle" : "checkmark.circle"
                    )
                }
                
                Button(action: onEdit) {
                    Label("Edit Task", systemImage: "pencil")
                }
                
                Divider()
                
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .frame(height: 120) // Set a fixed height for the row - adjust as needed
    }
    
    // Get color based on priority
    private func getPriorityColor() -> Color {
        switch todo.priority {
        case .low:
            return .green
        case .normal:
            return .blue
        case .high:
            return .red
        }
    }
}

// Helper to provide celebration quotes
struct CelebrationQuote {
    // List of motivational quotes for completion
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
    
    // Get a random quote
    static func randomQuote() -> String {
        celebrationQuotes.randomElement() ?? celebrationQuotes[0]
    }
}
