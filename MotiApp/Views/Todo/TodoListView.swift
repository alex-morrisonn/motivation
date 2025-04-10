import SwiftUI

struct TodoListView: View {
    @ObservedObject private var todoService = TodoService.shared
    @State private var showingAddTodo = false
    @State private var editingTodo: TodoItem?
    @State private var showCompletedTodos = false
    @State private var showingCelebration = false
    @State private var celebrationQuote = ""
    
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
            .overlay(
                Group {
                    if showingCelebration {
                        CelebrationView(isShowing: $showingCelebration, quote: celebrationQuote)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAddTodo) {
            TodoEditorView()
        }
        .sheet(item: $editingTodo) { todo in
            TodoEditorView(todo: todo)
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
                            TodoItemRow(
                                todo: todo,
                                onToggle: {
                                    if !todo.isCompleted {
                                        celebrationQuote = CelebrationView.randomQuote()
                                        todoService.toggleCompletionStatus(todo)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            showingCelebration = true
                                        }
                                    } else {
                                        todoService.toggleCompletionStatus(todo)
                                    }
                                },
                                onEdit: {
                                    editingTodo = todo
                                },
                                onDelete: {
                                    todoService.deleteTodo(todo)
                                }
                            )
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
                            TodoItemRow(
                                todo: todo,
                                onToggle: {
                                    if !todo.isCompleted {
                                        celebrationQuote = CelebrationView.randomQuote()
                                        todoService.toggleCompletionStatus(todo)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            showingCelebration = true
                                        }
                                    } else {
                                        todoService.toggleCompletionStatus(todo)
                                    }
                                },
                                onEdit: {
                                    editingTodo = todo
                                },
                                onDelete: {
                                    todoService.deleteTodo(todo)
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
                            TodoItemRow(
                                todo: todo,
                                onToggle: {
                                    todoService.toggleCompletionStatus(todo)
                                },
                                onEdit: {
                                    editingTodo = todo
                                },
                                onDelete: {
                                    todoService.deleteTodo(todo)
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
}

// Todo item row component
struct TodoItemRow: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Completion checkbox
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todo.isCompleted ? .green : getPriorityColor())
                    .font(.system(size: 22))
                    .padding(.top, 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Todo content
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .strikethrough(todo.isCompleted)
                
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
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .padding(8)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .padding(8)
                        .background(Color.red.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal)
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

// Confetti Celebration View
struct CelebrationView: View {
    @Binding var isShowing: Bool
    let quote: String
    
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
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 20) {
                // Confetti effect
                ConfettiView()
                    .frame(width: 300, height: 200)
                
                // Quote text
                Text(quote)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.3))
                    )
                    .padding(.horizontal)
                
                // Continue button
                Button(action: {
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Text("Continue")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 30)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            .onAppear {
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}

// Confetti animation view
struct ConfettiView: View {
    @State private var particles = [ConfettiParticle]()
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                particle.view
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .rotationEffect(Angle(degrees: particle.rotation))
                    .animation(
                        Animation.timingCurve(0.05, 0.7, 0.3, 1.0, duration: 2.5)
                            .delay(particle.delay),
                        value: particle.position
                    )
            }
        }
        .onAppear(perform: generateParticles)
    }
    
    private func generateParticles() {
        particles = []
        
        // Generate particles
        for _ in 0..<60 {
            let shape = Int.random(in: 0...1) // 0: circle, 1: rectangle
            let color = colors.randomElement() ?? .blue
            let position = CGPoint(
                x: CGFloat.random(in: 0...300),
                y: CGFloat.random(in: 0...50)
            )
            let finalPosition = CGPoint(
                x: position.x + CGFloat.random(in: -100...100),
                y: position.y + CGFloat.random(in: 100...200)
            )
            let size = CGFloat.random(in: 5...10)
            let opacity = Double.random(in: 0.5...1.0)
            let rotation = Double.random(in: 0...360)
            let delay = Double.random(in: 0...0.5)
            
            let view: AnyView
            if shape == 0 {
                view = AnyView(Circle().fill(color).frame(width: size, height: size))
            } else {
                view = AnyView(Rectangle().fill(color).frame(width: size, height: size * 0.5))
            }
            
            let particle = ConfettiParticle(
                id: UUID(),
                view: view,
                position: position,
                finalPosition: finalPosition,
                opacity: opacity,
                rotation: rotation,
                delay: delay
            )
            
            particles.append(particle)
        }
        
        // Animate particles
        withAnimation {
            for i in particles.indices {
                particles[i].position = particles[i].finalPosition
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    let view: AnyView
    var position: CGPoint
    let finalPosition: CGPoint
    var opacity: Double
    var rotation: Double
    let delay: Double
}

// Progress Ring View
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

// Preview
struct TodoListView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
            .preferredColorScheme(.dark)
            .onAppear {
                // Add some sample todos for preview
                let service = TodoService.shared
                if service.todos.isEmpty {
                    for todo in TodoItem.samples {
                        service.addTodo(todo)
                    }
                }
            }
    }
}
