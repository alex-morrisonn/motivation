import SwiftUI

struct TodoEditorView: View {
    // MARK: - Environment & Observed Properties
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var todoService = TodoService.shared
    
    // MARK: - State Properties
    @State private var title: String
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date
    @State private var priority: TodoItem.Priority
    @State private var whyThisMatters: String // New state for emotional context
    
    // MARK: - Private Properties
    private let isNewTodo: Bool
    private var todoId: UUID
    
    // MARK: - Initialization
    
    /// Initialize with a new todo
    init() {
        _title = State(initialValue: "")
        _notes = State(initialValue: "")
        _isCompleted = State(initialValue: false)
        _dueDate = State(initialValue: Date().addingTimeInterval(3600)) // 1 hour from now
        _priority = State(initialValue: .normal)
        _whyThisMatters = State(initialValue: "") // Initialize why this matters
        isNewTodo = true
        todoId = UUID() // Generate a new id
    }
    
    /// Initialize for editing an existing todo
    init(todo: TodoItem) {
        _title = State(initialValue: todo.title)
        _notes = State(initialValue: todo.notes)
        _isCompleted = State(initialValue: todo.isCompleted)
        
        // Handle optional due date
        _hasDueDate = State(initialValue: todo.dueDate != nil)
        _dueDate = State(initialValue: todo.dueDate ?? Date().addingTimeInterval(3600))
        
        _priority = State(initialValue: todo.priority)
        _whyThisMatters = State(initialValue: todo.whyThisMatters) // Initialize with stored value
        isNewTodo = false
        todoId = todo.id // Use existing id
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text(isNewTodo ? "Add New Task" : "Edit Task")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Title")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter task title", text: $title)
                            .padding()
                            .background(Color(UIColor.systemGray6).opacity(0.2))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Notes Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(5)
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .colorScheme(.dark) // Force dark mode for TextEditor
                            
                            if notes.isEmpty {
                                Text("Add notes here...")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 13)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // "Why This Matters" Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why This Matters")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .topLeading) {
                            TextField("e.g., \"Submit this to pass the unit\"", text: $whyThisMatters)
                                .padding()
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Due Date Toggle & Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasDueDate) {
                            Text("Set Due Date")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        
                        if hasDueDate {
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(GraphicalDatePickerStyle())
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                .cornerRadius(10)
                                .colorScheme(.dark)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Priority Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        HStack(spacing: 0) {
                            ForEach(TodoItem.Priority.allCases, id: \.rawValue) { priorityLevel in
                                Button(action: {
                                    priority = priorityLevel
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(priorityColor(for: priorityLevel))
                                            .frame(width: 20, height: 20)
                                        
                                        Text(priorityLevel.name)
                                            .font(.caption)
                                            .foregroundColor(priority == priorityLevel ? .white : .gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(priority == priorityLevel ?
                                                  priorityColor(for: priorityLevel).opacity(0.3) :
                                                  Color.clear)
                                    )
                                }
                            }
                        }
                        .padding(4)
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Completed Toggle
                    Toggle(isOn: $isCompleted) {
                        Text("Completed")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack {
                        // Cancel Button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        }
                        
                        // Save Button
                        Button(action: {
                            saveTodo()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    
                    // Add padding at the bottom to ensure scrolling can reach all content
                    Spacer(minLength: 30)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get color based on priority level
    private func priorityColor(for priority: TodoItem.Priority) -> Color {
        switch priority {
        case .low:
            return .green
        case .normal:
            return .blue
        case .high:
            return .red
        }
    }
    
    /// Save the current todo to the TodoService
    private func saveTodo() {
        let todoToSave = TodoItem(
            id: todoId,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            createdDate: isNewTodo ? Date() : Date(), // In a real app, preserve the creation date when editing
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            whyThisMatters: whyThisMatters
        )
        
        if isNewTodo {
            todoService.addTodo(todoToSave)
        } else {
            todoService.updateTodo(todoToSave)
        }
    }
}

// MARK: - Preview Provider
struct TodoEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for new todo
            TodoEditorView()
                .preferredColorScheme(.dark)
                .previewDisplayName("New Todo")
            
            // Preview for editing existing todo
            TodoEditorView(todo: TodoItem.sample)
            .preferredColorScheme(.dark)
            .previewDisplayName("Edit Todo")
        }
    }
}
