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
    
    // State to store hour and minute separately for more reliable time selection
    @State private var selectedHour: Int = 0
    @State private var selectedMinute: Int = 0
    
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
    
    // MARK: - Date Selection Helpers
    
    // Calendar helpers for the date grid
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var currentYear: Int {
        calendar.component(.year, from: dueDate)
    }
    
    private var currentMonth: Int {
        calendar.component(.month, from: dueDate)
    }
    
    private var firstWeekdayOfMonth: Int {
        let components = DateComponents(year: currentYear, month: currentMonth, day: 1)
        let firstDayOfMonth = calendar.date(from: components)!
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Adjust to make Sunday the first day (index 0)
        return (weekday - 1) % 7
    }
    
    private var daysInMonth: Int {
        let range = calendar.range(of: .day, in: .month, for: dueDate)!
        return range.count
    }
    
    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols.map { String($0.prefix(1)) }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: dueDate)
    }
    
    private var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: dueDate)
    }
    
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
            // Initialize hour and minute state from dueDate
            initializeTimeState()
            
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
            
            // Due Date Section with completely separated date and time selection
            VStack(alignment: .leading, spacing: 12) {
                // Section header with toggle button
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
                            Image(systemName: "chevron.up")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        } else {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if hasDueDate {
                    VStack(spacing: 20) {
                        // Date Selection - Completely separate
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DATE")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                        
                            // Custom date selector using buttons and calendar view
                            VStack(spacing: 10) {
                                // Selected date display
                                HStack {
                                    Text(formattedSelectedDate)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Today shortcut button
                                    Button(action: {
                                        // Set dueDate to today at the same time
                                        let currentTime = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
                                        var today = Calendar.current.startOfDay(for: Date())
                                        today = Calendar.current.date(bySettingHour: currentTime.hour ?? 0, minute: currentTime.minute ?? 0, second: 0, of: today) ?? today
                                        dueDate = today
                                    }) {
                                        Text("Today")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue.opacity(0.3))
                                            .cornerRadius(8)
                                    }
                                    
                                    // Tomorrow shortcut button
                                    Button(action: {
                                        // Set dueDate to tomorrow at the same time
                                        let currentTime = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
                                        var tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                                        tomorrow = Calendar.current.date(bySettingHour: currentTime.hour ?? 0, minute: currentTime.minute ?? 0, second: 0, of: tomorrow) ?? tomorrow
                                        dueDate = tomorrow
                                    }) {
                                        Text("Tomorrow")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue.opacity(0.3))
                                            .cornerRadius(8)
                                    }
                                }
                                
                                // Month and year selector
                                HStack {
                                    Button(action: {
                                        // Go to previous month
                                        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: dueDate) {
                                            dueDate = newDate
                                        }
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    // Month and year display
                                    Text(monthYearString)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // Go to next month
                                        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: dueDate) {
                                            dueDate = newDate
                                        }
                                    }) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                // Weekday headers
                                HStack {
                                    ForEach(weekdaySymbols, id: \.self) { symbol in
                                        Text(symbol)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.gray)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                
                                // Calendar days grid
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                                    // First, add empty cells for the first day of the month
                                    ForEach(0..<firstWeekdayOfMonth, id: \.self) { _ in
                                        Text("")
                                            .frame(height: 40)
                                    }
                                    
                                    // Then add the days of the month
                                    ForEach(1...daysInMonth, id: \.self) { day in
                                        Button(action: {
                                            // Set dueDate to this day while keeping the current time
                                            let currentTime = Calendar.current.dateComponents([.hour, .minute], from: dueDate)
                                            var newDate = Calendar.current.date(from: DateComponents(year: currentYear, month: currentMonth, day: day)) ?? Date()
                                            newDate = Calendar.current.date(bySettingHour: currentTime.hour ?? 0, minute: currentTime.minute ?? 0, second: 0, of: newDate) ?? newDate
                                            dueDate = newDate
                                        }) {
                                            ZStack {
                                                // Highlight current day
                                                if isDaySelected(day) {
                                                    Circle()
                                                        .fill(Color.blue)
                                                        .frame(width: 38, height: 38)
                                                }
                                                
                                                Text("\(day)")
                                                    .foregroundColor(isDaySelected(day) ? .white : isToday(day) ? .blue : .white)
                                                    .font(.system(size: 16, weight: isDaySelected(day) ? .bold : .regular))
                                            }
                                            .frame(height: 40)
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                        }
                        
                        // Time Selection - Modified to remove presets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TIME")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            // Time pickers in a centered layout
                            HStack(spacing: 8) {
                                // Hour picker with fixed height
                                Picker("Hour", selection: $selectedHour) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text("\(hour)")
                                            .foregroundColor(.white) // Improve text visibility
                                            .tag(hour)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100) // Fixed height
                                .clipped()
                                .onChange(of: selectedHour) { oldHour, newHour in
                                    updateTimeInDueDate()
                                }
                                .accentColor(.white) // Set accent color to improve visibility
                                
                                Text(":")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, -4)
                                
                                // Minute picker with fixed height
                                Picker("Minute", selection: $selectedMinute) {
                                    ForEach(0..<60, id: \.self) { minute in
                                        Text(String(format: "%02d", minute))
                                            .foregroundColor(.white) // Improve text visibility
                                            .tag(minute)
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 60, height: 100) // Fixed height
                                .clipped()
                                .onChange(of: selectedMinute) { oldMinute, newMinute in
                                    updateTimeInDueDate()
                                }
                                .accentColor(.white) // Set accent color to improve visibility
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center) // Center the time picker
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                        }
                        
                        // Summary of selected date and time
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.blue)
                                .font(.system(size: 18))
                            
                            Text("Due: \(formatDueDate(dueDate))")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .padding(16)
                    .background(Color(UIColor.systemGray6).opacity(0.2))
                    .cornerRadius(16)
                    .transition(.move(edge: .top).combined(with: .opacity))
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
            .opacity(title.isEmpty ? 0.5 : 1)
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
    
    // Check if a day is the selected day
    private func isDaySelected(_ day: Int) -> Bool {
        calendar.component(.day, from: dueDate) == day &&
        calendar.component(.month, from: dueDate) == currentMonth &&
        calendar.component(.year, from: dueDate) == currentYear
    }
    
    // Check if a day is today
    private func isToday(_ day: Int) -> Bool {
        let today = Date()
        return calendar.component(.day, from: today) == day &&
        calendar.component(.month, from: today) == currentMonth &&
        calendar.component(.year, from: today) == currentYear
    }
    
    // Update time in dueDate from separate hour and minute
    private func updateTimeInDueDate() {
        let components = calendar.dateComponents([.year, .month, .day], from: dueDate)
        var newComponents = DateComponents()
        newComponents.year = components.year
        newComponents.month = components.month
        newComponents.day = components.day
        newComponents.hour = selectedHour
        newComponents.minute = selectedMinute
        
        if let newDate = calendar.date(from: newComponents) {
            dueDate = newDate
        }
    }
    
    // Format due date for display
    private func formatDueDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        return "\(dateFormatter.string(from: date)) at \(timeFormatter.string(from: date))"
    }
    
    // Initialize the hour and minute state when the view appears
    private func initializeTimeState() {
        selectedHour = calendar.component(.hour, from: dueDate)
        selectedMinute = calendar.component(.minute, from: dueDate)
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
