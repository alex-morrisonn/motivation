import SwiftUI

struct TodoListView: View {
    @ObservedObject private var todoService = TodoService.shared
    @State private var showingAddTodo = false
    @State private var editingTodo: TodoItem?
    @State private var showCompletedTodos = false
    
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
