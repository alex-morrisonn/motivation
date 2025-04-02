import SwiftUI

/// A view that showcases all available widgets and how to add them
struct WidgetsShowcaseView: View {
    // MARK: - Properties
    
    @ObservedObject private var quoteService = QuoteService.shared
    @State private var selectedWidgetType = 0
    private let tabOptions = ["Home Screen", "Lock Screen"]
    
    // Demo quote for the preview
    private var demoQuote: Quote {
        quoteService.getTodaysQuote()
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Widgets")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 16)
                    
                    // Tab selector for Home Screen vs Lock Screen widgets
                    CustomSegmentedControl(
                        selectedIndex: $selectedWidgetType,
                        options: tabOptions
                    )
                    
                    // Instructions card
                    InstructionsCard(
                        isHomeScreen: selectedWidgetType == 0
                    )
                    .padding(.horizontal)
                    
                    // Widget previews - different for each tab
                    if selectedWidgetType == 0 {
                        homeScreenWidgetPreviews
                    } else {
                        lockScreenWidgetPreviews
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Widget Preview Views
    
    /// Home screen widget previews
    private var homeScreenWidgetPreviews: some View {
        VStack(spacing: 20) {
            Text("HOME SCREEN WIDGETS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Small Widget Preview
            WidgetPreviewCard(
                title: "Small",
                description: "Quote only",
                size: CGSize(width: 170, height: 170),
                content: {
                    HomeScreenWidgetPreview(
                        quote: demoQuote,
                        size: .small
                    )
                }
            )
            .padding(.horizontal)
            .id("small-widget-preview")
            
            // Medium Widget Preview
            WidgetPreviewCard(
                title: "Medium",
                description: "Quote with more text",
                size: CGSize(width: 320, height: 170),
                content: {
                    HomeScreenWidgetPreview(
                        quote: demoQuote,
                        size: .medium
                    )
                }
            )
            .padding(.horizontal)
            .id("medium-widget-preview")
            
            // Large Widget Preview
            WidgetPreviewCard(
                title: "Large",
                description: "Quote with calendar",
                size: CGSize(width: 320, height: 360),
                content: {
                    HomeScreenWidgetPreview(
                        quote: demoQuote,
                        size: .large
                    )
                }
            )
            .padding(.horizontal)
            .id("large-widget-preview")
        }
    }
    
    /// Lock screen widget previews
    private var lockScreenWidgetPreviews: some View {
        VStack(spacing: 20) {
            Text("LOCK SCREEN WIDGETS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)
            
            HStack(spacing: 16) {
                // Circular Lock Screen Widget
                WidgetPreviewCard(
                    title: "Circular",
                    description: "Short quote",
                    size: CGSize(width: 160, height: 160),
                    content: {
                        LockScreenWidgetPreview(
                            quote: demoQuote,
                            type: .circular
                        )
                    }
                )
                .id("circular-widget-preview")
                
                // Rectangular Lock Screen Widget
                WidgetPreviewCard(
                    title: "Rectangular",
                    description: "Longer quote",
                    size: CGSize(width: 160, height: 160),
                    content: {
                        LockScreenWidgetPreview(
                            quote: demoQuote,
                            type: .rectangular
                        )
                    }
                )
                .id("rectangular-widget-preview")
            }
            .padding(.horizontal)
            
            // Inline Lock Screen Widget
            WidgetPreviewCard(
                title: "Inline",
                description: "Single line quote",
                size: CGSize(width: 320, height: 60),
                content: {
                    LockScreenWidgetPreview(
                        quote: demoQuote,
                        type: .inline
                    )
                }
            )
            .padding(.horizontal)
            .id("inline-widget-preview")
        }
    }
}

// MARK: - Supporting Components

/// Custom segmented control with better visibility
struct CustomSegmentedControl: View {
    @Binding var selectedIndex: Int
    let options: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    selectedIndex = index
                }) {
                    Text(option)
                        .fontWeight(selectedIndex == index ? .semibold : .regular)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                }
                .background(
                    selectedIndex == index ?
                    Color.white :
                    Color.white.opacity(0.15) // More visible unselected state
                )
                .foregroundColor(selectedIndex == index ? .black : .white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1) // Add border
                )
                .padding(.horizontal, 4)
                .id("tab-option-\(index)")
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

/// Instructions card component explaining how to add widgets
struct InstructionsCard: View {
    let isHomeScreen: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("How to Add Widgets")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(isHomeScreen ? homeScreenSteps : lockScreenSteps, id: \.number) { step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(step.number)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                        
                        Text(step.instruction)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .id("step-\(isHomeScreen ? "home" : "lock")-\(step.number)")
                }
            }
            .padding(.leading, 4)
        }
        .padding(16)
        .background(Color(UIColor.systemGray6).opacity(0.3))
        .cornerRadius(16)
    }
    
    // Step-by-step instructions
    struct Step: Identifiable {
        let id = UUID()
        let number: Int
        let instruction: String
    }
    
    let homeScreenSteps: [Step] = [
        Step(number: 1, instruction: "Long press on an empty area of your Home Screen."),
        Step(number: 2, instruction: "Tap the + button in the top-left corner."),
        Step(number: 3, instruction: "Search for \"Moti\" or scroll to find it."),
        Step(number: 4, instruction: "Choose a widget size by swiping left or right."),
        Step(number: 5, instruction: "Tap \"Add Widget\" and position it where you want.")
    ]
    
    let lockScreenSteps: [Step] = [
        Step(number: 1, instruction: "Long press on your Lock Screen to enter edit mode."),
        Step(number: 2, instruction: "Tap \"Customize\"."),
        Step(number: 3, instruction: "Select the area where you want to add a widget."),
        Step(number: 4, instruction: "Tap the + button."),
        Step(number: 5, instruction: "Find \"Moti\" and select a widget style.")
    ]
}

/// Widget preview card component
struct WidgetPreviewCard: View {
    let title: String
    let description: String
    let size: CGSize
    let content: () -> AnyView
    
    init(title: String, description: String, size: CGSize, @ViewBuilder content: @escaping () -> some View) {
        self.title = title
        self.description = description
        self.size = size
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Widget title and description
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Widget preview
            content()
                .frame(width: size.width, height: size.height)
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        }
        .padding(16)
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(16)
    }
}

// MARK: - Widget Previews

/// Widget size enum
enum HomeWidgetSize {
    case small, medium, large
}

/// Lock screen widget type enum
enum LockScreenWidgetType {
    case circular, rectangular, inline
}

/// Home screen widget preview
struct HomeScreenWidgetPreview: View {
    let quote: Quote
    let size: HomeWidgetSize
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Add logo as a subtle watermark in the background
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("M")
                        .font(.system(size: size == .small ? 70 : 100, weight: .bold))
                        .foregroundColor(.white.opacity(0.08))
                    Spacer()
                }
                Spacer()
            }
            
            // Content based on size
            if size == .large {
                // Large widget with quote and calendar
                VStack(alignment: .center, spacing: 8) {
                    // Quote part
                    VStack(spacing: 4) {
                        Text(quote.text)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        Text("— \(quote.author)")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .padding(.bottom, 2)
                    }
                    .padding(.bottom, 5)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                    
                    // Calendar preview
                    CalendarPreview()
                }
                .padding(12)
            } else {
                // Small or medium widget with just the quote
                VStack(alignment: .center, spacing: size == .small ? 6 : 10) {
                    // Quote text
                    Text(quote.text)
                        .font(.system(size: size == .small ? 14 : 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(size == .small ? 5 : 6)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 8)
                        .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    // Author
                    Text("— \(quote.author)")
                        .font(.system(size: size == .small ? 12 : 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .padding(.bottom, 8)
                }
                .padding(size == .small ? 12 : 16)
            }
        }
    }
}

/// Simplified calendar preview for the large widget
struct CalendarPreview: View {
    let calendar = Calendar.current
    let today = Date()
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Month title
            let formatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter
            }()
            Text(formatter.string(from: today))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 4)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .id("cal-weekday-\(index)")
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
            
            // Calendar grid
            let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
            let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
            let currentDay = calendar.component(.day, from: today)
            let rows = (firstWeekday + daysInMonth + 6) / 7
            
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let cellIndex = row * 7 + column
                        let dayNumber = cellIndex - firstWeekday + 1
                        
                        if dayNumber > 0 && dayNumber <= daysInMonth {
                            ZStack {
                                // Highlight current day
                                if dayNumber == currentDay {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 22, height: 22)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: 10))
                                    .foregroundColor(dayNumber == currentDay ? Color.black : .white)
                                
                                // Sample event indicators for demo
                                if [5, 12, 20, 25].contains(dayNumber) {
                                    Circle()
                                        .fill(dayNumber == currentDay ? Color.blue : Color.blue.opacity(0.7))
                                        .frame(width: 4, height: 4)
                                        .offset(y: 8)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 24)
                            .id("cal-day-\(row)-\(column)")
                        } else {
                            // Empty cell for days outside current month
                            Text("")
                                .frame(maxWidth: .infinity, maxHeight: 24)
                                .id("cal-empty-\(row)-\(column)")
                        }
                    }
                }
                .id("cal-row-\(row)")
            }
        }
        .padding(.horizontal, 8)
    }
}

/// Lock screen widget preview
struct LockScreenWidgetPreview: View {
    let quote: Quote
    let type: LockScreenWidgetType
    
    var body: some View {
        Group {
            switch type {
            case .circular:
                // Circular widget
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.1, green: 0.1, blue: 0.3),
                                    Color(red: 0.08, green: 0.08, blue: 0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(spacing: 2) {
                        Text("\"")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .offset(y: -5)
                        
                        let shortQuote = shortenQuote(quote.text, maxLength: 30)
                        Text(shortQuote)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 4)
                    }
                }
                .frame(width: 130, height: 130)
                
            case .rectangular:
                // Rectangular widget
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.1, green: 0.1, blue: 0.3),
                                    Color(red: 0.05, green: 0.05, blue: 0.15)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(spacing: 6) {
                        let shortQuote = shortenQuote(quote.text, maxLength: 80)
                        Text(shortQuote)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        if shortQuote.count < 80 {
                            Text("— \(quote.author)")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.bottom, 8)
                        }
                    }
                }
                .frame(width: 150, height: 120)
                
            case .inline:
                // Inline widget
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.1, green: 0.1, blue: 0.3),
                                    Color(red: 0.08, green: 0.08, blue: 0.25)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .frame(height: 30)
                    
                    let veryShortQuote = shortenQuote(quote.text, maxLength: 40)
                    Text(veryShortQuote)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                }
                .frame(height: 30)
            }
        }
    }
    
    // Helper to shorten quotes for smaller widgets
    private func shortenQuote(_ quote: String, maxLength: Int) -> String {
        if quote.count <= maxLength {
            return quote
        }
        return String(quote.prefix(maxLength - 3)) + "..."
    }
}

// MARK: - Previews

struct WidgetsShowcaseView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetsShowcaseView()
            .preferredColorScheme(.dark)
    }
}
