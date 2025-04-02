import SwiftUI

/// Displays detailed information about the user's streak
struct StreakDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var streakManager = StreakManager.shared
    
    // MARK: - Date Formatters
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Streak summary header
                        streakSummaryView
                        
                        // Streak calendar
                        streakCalendarView
                        
                        // Streak stats
                        streakStatsView
                        
                        // Streak achievements (future feature)
                        streakAchievementsView
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Your Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Component Views
    
    /// Current streak summary section
    private var streakSummaryView: some View {
        VStack(spacing: 20) {
            // Current streak number with flame
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("\(streakManager.currentStreak)")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Day or Days text
            Text(streakManager.currentStreak == 1 ? "Day" : "Days")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            // Streak description
            if let startDate = streakManager.getStreakStartDate(), streakManager.currentStreak > 1 {
                Text("You've used Moti every day since \(dateFormatter.string(from: startDate))")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            } else if streakManager.currentStreak == 1 {
                Text("You've started your Moti journey today!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            } else {
                Text("Open the app daily to build your streak")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color(red: 0.3, green: 0.1, blue: 0).opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    /// Calendar view showing streak days
    private var streakCalendarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STREAK CALENDAR")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            // Calendar current month
            let currentDate = Date()
            let calendar = Calendar.current
            
            // Show calendar for current month
            VStack(spacing: 16) {
                // Month header
                Text(monthFormatter.string(from: currentDate))
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Grid container with expanded width
                VStack(spacing: 8) {
                    // Calculate available width (screen width minus padding)
                    GeometryReader { geometry in
                        let availableWidth = geometry.size.width
                        let cellWidth = max(45, (availableWidth - 10) / 7) // Divide available width by 7 columns
                        
                        VStack(spacing: 10) {
                            // Weekday headers - aligned with cells below
                            HStack(spacing: 0) {
                                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                                    Text(day)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .frame(width: cellWidth, height: 20)
                                }
                            }
                            
                            // Generate calendar grid
                            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
                            let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
                            let daysInMonth = calendar.range(of: .day, in: .month, for: currentDate)!.count
                            
                            // Calculate how many rows we need
                            let totalCells = firstWeekday + daysInMonth
                            let numberOfRows = (totalCells + 6) / 7
                            
                            // Create the grid with proper structure
                            ForEach(0..<numberOfRows, id: \.self) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<7, id: \.self) { column in
                                        let cellIndex = row * 7 + column
                                        let dayNumber = cellIndex - firstWeekday + 1
                                        
                                        if dayNumber < 1 || dayNumber > daysInMonth {
                                            // Empty cell
                                            Color.clear
                                                .frame(width: cellWidth, height: cellWidth)
                                                .id("empty-\(row)-\(column)")
                                        } else {
                                            // Day cell
                                            let thisDate = calendar.date(byAdding: .day, value: dayNumber - 1, to: firstDay)!
                                            let isToday = calendar.isDateInToday(thisDate)
                                            let isStreakDay = streakManager.isDateInStreak(thisDate)
                                            let isPastDate = thisDate < calendar.startOfDay(for: Date())
                                            
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        isToday ? Color.orange :
                                                            (isStreakDay ? Color.red.opacity(0.3) : Color.clear)
                                                    )
                                                    .frame(width: cellWidth * 0.8, height: cellWidth * 0.8)
                                                
                                                if isToday {
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 1)
                                                        .frame(width: cellWidth * 0.8, height: cellWidth * 0.8)
                                                }
                                                
                                                Text("\(dayNumber)")
                                                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                                                    .foregroundColor(
                                                        isToday || isStreakDay ? .white :
                                                            (isPastDate ? .white.opacity(0.5) : .white.opacity(0.8))
                                                    )
                                            }
                                            .frame(width: cellWidth, height: cellWidth)
                                            .id("day-\(dayNumber)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: 380) // Fixed height to accommodate all rows
                }
                .padding(10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal, 4) // Reduced horizontal padding to allow more width
    }
    
    /// Streak statistics section
    private var streakStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STREAK STATS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            VStack(spacing: 16) {
                HStack {
                    StatItem(
                        value: "\(streakManager.currentStreak)",
                        label: "Current Streak",
                        icon: "flame",
                        iconColor: .orange
                    )
                    
                    StatItem(
                        value: "\(streakManager.longestStreak)",
                        label: "Longest Streak",
                        icon: "crown",
                        iconColor: .yellow
                    )
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
            }
            .padding(16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
        }
    }
    
    /// Streak achievements section (placeholders for future feature)
    private var streakAchievementsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACHIEVEMENTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
            
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    // Achievement examples - these would be dynamic in a full implementation
                    achievementItem(
                        icon: "1.circle.fill",
                        title: "First Day",
                        description: "Used Moti for the first time",
                        isUnlocked: streakManager.currentStreak >= 1,
                        color: .green
                    )
                    .id("achievement-1")
                    
                    achievementItem(
                        icon: "7.circle.fill",
                        title: "Week Strong",
                        description: "7 day streak",
                        isUnlocked: streakManager.currentStreak >= 7 || streakManager.longestStreak >= 7,
                        color: .blue
                    )
                    .id("achievement-2")
                }
                
                HStack(spacing: 14) {
                    achievementItem(
                        icon: "30.circle.fill",
                        title: "Monthly Master",
                        description: "30 day streak",
                        isUnlocked: streakManager.currentStreak >= 30 || streakManager.longestStreak >= 30,
                        color: .purple
                    )
                    .id("achievement-3")
                    
                    achievementItem(
                        icon: "number.circle.fill",
                        title: "Century Club",
                        description: "100 day streak",
                        isUnlocked: streakManager.currentStreak >= 100 || streakManager.longestStreak >= 100,
                        color: .orange
                    )
                    .id("achievement-4")
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(16)
        }
    }
    
    /// Single achievement item
    private func achievementItem(icon: String, title: String, description: String, isUnlocked: Bool, color: Color) -> some View {
        VStack(alignment: .center, spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(isUnlocked ? color : Color.gray.opacity(0.5))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isUnlocked ? .white : .gray)
            
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(isUnlocked ? .white.opacity(0.7) : .gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(isUnlocked ? color.opacity(0.1) : Color.clear)
        .cornerRadius(10)
    }
}

// MARK: - Supporting Views

/// Stat item component for streak stats
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct StreakDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        StreakDetailsView()
            .preferredColorScheme(.dark)
    }
}
