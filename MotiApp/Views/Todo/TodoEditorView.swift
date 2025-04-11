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
    @State private var whyThisMatters: String
    
    // Animation states
    @State private var showWhyItMatters: Bool = false
    @State private var keyboardVisible: Bool = false
    @FocusState private var focusedField: Field?
    
    // Form field identifiers
    enum Field: Hashable {
        case title, notes, whyThisMatters
    }
    
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
        _whyThisMatters = State(initialValue: "")
        isNewTodo = true
        todoId = UUID()
    }
    
    /// Initialize for editing an existing todo
    init(todo: TodoItem) {
        _title = State(initialValue: todo.title)
        _notes = State(initialValue: todo.notes)
        _isCompleted = State(initialValue: todo.isCompleted)
        _hasDueDate = State(initialValue: todo.dueDate != nil)
        _dueDate = State(initialValue: todo.dueDate ?? Date().addingTimeInterval(3600))
        _priority = State(initialValue: todo.priority)
        _whyThisMatters = State(initialValue: todo.whyThisMatters)
        isNewTodo = false
        todoId = todo.id
        _showWhyItMatters = State(initialValue: !todo.whyThisMatters.isEmpty)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title and Visual Header
                    headerView
                    
                    // Main form content
                    formCard
                    
                    // Actions
                    actionButtons
                    
                    // Bottom spacing
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Animate "Why it matters" expansion if it has content
            if !whyThisMatters.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut) {
                        showWhyItMatters = true
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation {
                keyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation {
                keyboardVisible = false
            }
        }
    }
    
    // MARK: - UI Components
    
    // Header with title and back button
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Title
            Text(isNewTodo ? "New Task" : "Edit Task")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Balanced empty view for visual symmetry
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.top, 16)
    }
    
    // Main form card
    private var formCard: some View {
        VStack(spacing: 24) {
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                formLabel("Task Title")
                
                ZStack(alignment: .leading) {
                    if title.isEmpty {
                        Text("What do you need to do?")
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.leading, 16)
                            .padding(.top, 16)
                    }
                    
                    TextField("", text: $title)
                        .padding(16)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .focused($focusedField, equals: .title)
                }
            }
            
            // Priority selector with improved visualization
            VStack(alignment: .leading, spacing: 12) {
                formLabel("Priority")
                
                HStack(spacing: 10) {
                    ForEach(TodoItem.Priority.allCases, id: \.rawValue) { priorityOption in
                        priorityButton(priorityOption)
                    }
                }
            }
            
            // Notes Field
            VStack(alignment: .leading, spacing: 8) {
                formLabel("Notes")
                
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Add any details here...")
                            .foregroundColor(.gray.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }
                    
                    TextEditor(text: $notes)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .notes)
                }
            }
            
            // "Why This Matters" Section with collapsible UI
            VStack(alignment: .leading, spacing: 12) {
                Button(action: {
                    withAnimation(.spring()) {
                        showWhyItMatters.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .foregroundColor(.pink.opacity(0.8))
                        
                        Text("Why This Matters")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(whyThisMatters.isEmpty ? .white.opacity(0.8) : .white)
                        
                        Spacer()
                        
                        Image(systemName: showWhyItMatters ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
                
                if showWhyItMatters {
                    ZStack(alignment: .topLeading) {
                        if whyThisMatters.isEmpty {
                            Text("Why is this task important to you?")
                                .foregroundColor(.gray.opacity(0.7))
                                .padding(.leading, 16)
                                .padding(.top, 16)
                        }
                        
                        TextEditor(text: $whyThisMatters)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 80)
                            .padding(12)
                            .background(Color.white.opacity(0.07))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                            )
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .whyThisMatters)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            // Due Date Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Due date toggle button with icon
                    Button(action: {
                        withAnimation {
                            hasDueDate.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: hasDueDate ? "calendar.badge.clock.fill" : "calendar.badge.plus")
                                .foregroundColor(hasDueDate ? .blue : .gray)
                                .font(.system(size: 18))
                            
                            Text(hasDueDate ? "Due Date Set" : "Add Due Date")
                                .font(.system(size: 16, weight: hasDueDate ? .medium : .regular))
                                .foregroundColor(hasDueDate ? .white : .white.opacity(0.8))
                            
                            Spacer()
                            
                            if hasDueDate {
                                // Display the current due date
                                Text(formatDate(dueDate))
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue.opacity(0.8))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if hasDueDate {
                    // Full date picker without component restrictions
                    DatePicker("", selection: $dueDate)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .colorScheme(.dark)
                        .padding(12)
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(12)
                        .transition(.opacity)
                }
            }
            
            // Completed toggle with improved styling
            HStack {
                Button(action: {
                    withAnimation {
                        isCompleted.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(isCompleted ? .green : .gray)
                        
                        Text("Mark as Completed")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
    
    // Action buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Cancel Button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            // Save Button
            Button(action: {
                saveTodo()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(title.isEmpty ? Color.gray : Color.white)
                    )
            }
            .disabled(title.isEmpty)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Helper Components
    
    // Form label with consistent style
    private func formLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.gray)
            .padding(.leading, 4)
    }
    
    // Priority button with improved visual design
    private func priorityButton(_ priorityOption: TodoItem.Priority) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                priority = priorityOption
            }
        }) {
            VStack(spacing: 6) {
                // Colored circle indicator
                Circle()
                    .fill(priorityColor(for: priorityOption).opacity(priority == priorityOption ? 0.8 : 0.3))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // Priority label
                Text(priorityOption.name)
                    .font(.system(size: 14, weight: priority == priorityOption ? .medium : .regular))
                    .foregroundColor(priority == priorityOption ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(priority == priorityOption ?
                          priorityColor(for: priorityOption).opacity(0.2) :
                          Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        priority == priorityOption ?
                        priorityColor(for: priorityOption).opacity(0.5) :
                        Color.white.opacity(0.05),
                        lineWidth: 1
                    )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    // Hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Get color based on priority level
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
    
    // Save the todo
    private func saveTodo() {
        let todoToSave = TodoItem(
            id: todoId,
            title: title,
            notes: notes,
            isCompleted: isCompleted,
            createdDate: isNewTodo ? Date() : Date(),
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
