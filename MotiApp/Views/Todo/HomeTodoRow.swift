import SwiftUI

/// A compact todo row for the home screen
struct HomeTodoRow: View {
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
                    .foregroundColor(todo.isCompleted ? .green : getPriorityColor())
                    .font(.system(size: 18))
                
                // Todo title and due time
                VStack(alignment: .leading, spacing: 2) {
                    Text(todo.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
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
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.red)
                                    .cornerRadius(3)
                            }
                        }
                        .foregroundColor(todo.isOverdue ? .red : .gray)
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
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(UIColor.systemGray6).opacity(0.2))
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
            return .green
        case .normal:
            return .blue
        case .high:
            return .red
        }
    }
}

// Preview
struct HomeTodoRow_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            VStack(spacing: 16) {
                HomeTodoRow(todo: TodoItem.sample)
                HomeTodoRow(todo: TodoItem.samples[0])
                HomeTodoRow(todo: TodoItem.samples[1])
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
}
