import SwiftUI

/// Main home view focused on Daily Discipline System
struct DisciplineHomeView: View {
    // MARK: - Properties
    
    @StateObject private var disciplineSystem = DisciplineSystemState()
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var streakManager = StreakManager.shared
    
    @State private var showingTaskEditor = false
    @State private var editingTaskIndex: Int?
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var celebratingCompletion = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color.themeBackground
                .edgesIgnoringSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with date and streak
                    headerView
                    
                    // Main discipline tasks card
                    dailyTasksCard
                    
                    // Progress summary
                    progressSummaryCard
                    
                    // Quick stats
                    quickStatsGrid
                    
                    // Motivational quote (smaller, secondary focus)
                    motivationalQuoteCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showingTaskEditor) {
            TaskTemplateEditorView(
                templates: disciplineSystem.taskTemplates,
                onSave: { newTemplates in
                    disciplineSystem.updateTemplates(newTemplates)
                }
            )
        }
        .sheet(isPresented: $showingHistory) {
            DisciplineHistoryView(disciplineSystem: disciplineSystem)
        }
        .fullScreenCover(isPresented: $celebratingCompletion) {
            DailyCompletionCelebrationView(
                onDismiss: { celebratingCompletion = false }
            )
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Date
            Text(formattedDate)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color.themeText)
            
            // Streak badge
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(disciplineSystem.streak.currentStreak) Day Streak")
                        .font(.headline)
                        .foregroundColor(Color.themeText)
                    
                    if disciplineSystem.streak.longestStreak > 0 {
                        Text("Best: \(disciplineSystem.streak.longestStreak) days")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                }
                
                Spacer()
                
                // Settings button
                Button(action: { showingTaskEditor = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(Color.themeText)
                        .padding(8)
                        .background(Color.themeCardBackground)
                        .clipShape(Circle())
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.1),
                        Color.red.opacity(0.05)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
    
    // MARK: - Daily Tasks Card
    
    private var dailyTasksCard: some View {
        VStack(spacing: 20) {
            // Card header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Discipline")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                    
                    Text("\(completedTasksCount)/3 completed")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }
                
                Spacer()
                
                // Completion ring
                ZStack {
                    Circle()
                        .stroke(Color.themeDivider, lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: completionPercentage)
                        .stroke(
                            completionPercentage == 1.0 ? Color.themeSuccess : Color.themePrimary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: completionPercentage)
                    
                    Text("\(Int(completionPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.themeText)
                }
            }
            
            // Task list
            VStack(spacing: 12) {
                let today = disciplineSystem.getTodayDay()
                
                ForEach(Array(today.tasks.enumerated()), id: \.element.id) { index, task in
                    DisciplineTaskRow(
                        task: task,
                        onToggle: {
                            disciplineSystem.toggleTodayTask(at: index)
                            checkForDailyCompletion()
                        }
                    )
                }
            }
            
            // Customize tasks button
            Button(action: { showingTaskEditor = true }) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("Customize Daily Tasks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(Color.themePrimary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color.themePrimary.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.themeCardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Progress Summary Card
    
    private var progressSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(Color.themeText)
                
                Spacer()
                
                Button(action: { showingHistory = true }) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(Color.themePrimary)
                }
            }
            
            // Week progress bars
            VStack(spacing: 10) {
                let history = disciplineSystem.getCompletionHistory(days: 7)
                
                ForEach(history.reversed(), id: \.id) { day in
                    WeekDayProgressRow(day: day)
                }
            }
        }
        .padding(20)
        .background(Color.themeCardBackground)
        .cornerRadius(20)
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Total completed days
            StatCard(
                icon: "checkmark.circle.fill",
                iconColor: Color.themeSuccess,
                value: "\(disciplineSystem.streak.totalCompletedDays)",
                label: "Total Days"
            )
            
            // 30-day completion rate
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: Color.themePrimary,
                value: "\(Int(disciplineSystem.completionRate(in: 30) * 100))%",
                label: "30-Day Rate"
            )
        }
    }
    
    // MARK: - Motivational Quote Card
    
    private var motivationalQuoteCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                
                Text("Daily Motivation")
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
                    .tracking(1)
                
                Spacer()
            }
            
            let quote = QuoteService.shared.getTodaysQuote()
            
            Text(quote.text)
                .font(.body)
                .foregroundColor(Color.themeText)
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
        }
        .padding(16)
        .background(Color.themeCardBackground.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private var completedTasksCount: Int {
        disciplineSystem.getTodayDay().completedTaskCount
    }
    
    private var completionPercentage: Double {
        disciplineSystem.getTodayDay().completionPercentage
    }
    
    // MARK: - Helper Methods
    
    private func checkForDailyCompletion() {
        let today = disciplineSystem.getTodayDay()
        if today.isFullyCompleted {
            // Show celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                celebratingCompletion = true
            }
        }
    }
}

// MARK: - Supporting Views

/// Individual task row
struct DisciplineTaskRow: View {
    let task: DisciplineTask
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? Color.themeSuccess : Color.themeDivider, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.themeSuccess)
                    }
                }
                
                // Task title
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(Color.themeText)
                        .strikethrough(task.isCompleted)
                    
                    if let completedAt = task.completedAt {
                        Text("Completed at \(formatTime(completedAt))")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                }
                
                Spacer()
                
                // Status indicator
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.themeSuccess)
                }
            }
            .padding(16)
            .background(
                task.isCompleted ?
                Color.themeSuccess.opacity(0.1) :
                Color.themeBackground.opacity(0.5)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Week day progress row
struct WeekDayProgressRow: View {
    let day: DisciplineDay
    
    var body: some View {
        HStack(spacing: 12) {
            // Day label
            VStack(alignment: .leading, spacing: 2) {
                Text(dayLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.themeText)
                
                Text(dateLabel)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }
            .frame(width: 80, alignment: .leading)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.themeDivider.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    // Progress
                    Rectangle()
                        .fill(day.isFullyCompleted ? Color.themeSuccess : Color.themePrimary)
                        .frame(width: geometry.size.width * day.completionPercentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Count label
            Text("\(day.completedTaskCount)/3")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(day.isFullyCompleted ? Color.themeSuccess : Color.themeSecondaryText)
                .frame(width: 35, alignment: .trailing)
        }
    }
    
    private var dayLabel: String {
        if day.isToday {
            return "Today"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day.date)
    }
    
    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: day.date)
    }
}

/// Stat card component
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(iconColor)
            
            // Value
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.themeText)
            
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.themeCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Task Template Editor

struct TaskTemplateEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let templates: [String]
    let onSave: ([String]) -> Void
    
    @State private var task1: String
    @State private var task2: String
    @State private var task3: String
    
    init(templates: [String], onSave: @escaping ([String]) -> Void) {
        self.templates = templates
        self.onSave = onSave
        
        _task1 = State(initialValue: templates.count > 0 ? templates[0] : "Task 1")
        _task2 = State(initialValue: templates.count > 1 ? templates[1] : "Task 2")
        _task3 = State(initialValue: templates.count > 2 ? templates[2] : "Task 3")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Daily Discipline Tasks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.themeText)
                        
                        Text("Customize your 3 daily tasks")
                            .font(.subheadline)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                    .padding(.top, 20)
                    
                    // Task fields
                    VStack(spacing: 16) {
                        TaskTextField(number: 1, text: $task1)
                        TaskTextField(number: 2, text: $task2)
                        TaskTextField(number: 3, text: $task3)
                    }
                    .padding(.horizontal, 20)
                    
                    // Examples
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Examples:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.themeSecondaryText)
                        
                        ExampleTaskRow(icon: "book.fill", text: "Read 20 pages")
                        ExampleTaskRow(icon: "dumbbell.fill", text: "30 min workout")
                        ExampleTaskRow(icon: "pencil", text: "Journal 10 minutes")
                        ExampleTaskRow(icon: "brain.head.profile", text: "Meditate 15 minutes")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.themeCardBackground.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Save button
                    Button(action: saveTemplates) {
                        Text("Save Tasks")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.themePrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func saveTemplates() {
        onSave([task1, task2, task3])
        presentationMode.wrappedValue.dismiss()
    }
}

struct TaskTextField: View {
    let number: Int
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.themePrimary.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(Color.themePrimary)
            }
            
            // Text field
            TextField("Task \(number)", text: $text)
                .font(.body)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.themeCardBackground)
                .cornerRadius(10)
        }
    }
}

struct ExampleTaskRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.themePrimary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
        }
    }
}

// MARK: - Daily Completion Celebration

struct DailyCompletionCelebrationView: View {
    let onDismiss: () -> Void
    
    @State private var animateCheckmark = false
    @State private var animateConfetti = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.3)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.3)
                }
                
                // Text
                VStack(spacing: 12) {
                    Text("All Done! 🎉")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("You completed all 3 tasks today")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Keep building that discipline!")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animateCheckmark = true
            }
        }
    }
}

// MARK: - Discipline History View

struct DisciplineHistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var disciplineSystem: DisciplineSystemState
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 16) {
                        let history = disciplineSystem.getCompletionHistory(days: 30)
                        
                        ForEach(history, id: \.id) { day in
                            HistoryDayCard(day: day)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct HistoryDayCard: View {
    let day: DisciplineDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.formattedDate)
                        .font(.headline)
                        .foregroundColor(Color.themeText)
                    
                    Text("\(day.completedTaskCount)/3 tasks completed")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }
                
                Spacer()
                
                if day.isFullyCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.themeSuccess)
                }
            }
            
            // Tasks
            VStack(spacing: 8) {
                ForEach(day.tasks, id: \.id) { task in
                    HStack(spacing: 8) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(task.isCompleted ? Color.themeSuccess : Color.themeDivider)
                        
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundColor(Color.themeText)
                            .strikethrough(task.isCompleted)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.themeCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct DisciplineHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DisciplineHomeView()
            .preferredColorScheme(.dark)
    }
}
