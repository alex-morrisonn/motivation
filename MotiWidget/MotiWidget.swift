import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Models

/// Quote model for widget
struct WidgetQuote: Identifiable, Codable, Equatable {
    var id = UUID()
    let text: String
    let author: String
    let category: String
    
    static func == (lhs: WidgetQuote, rhs: WidgetQuote) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Create from shared quote
    init(from sharedQuote: SharedQuote) {
        self.id = sharedQuote.id
        self.text = sharedQuote.text
        self.author = sharedQuote.author
        self.category = sharedQuote.category
    }
    
    /// Direct initialization
    init(text: String, author: String, category: String) {
        self.text = text
        self.author = author
        self.category = category
    }
    
    /// Create a fallback quote for error situations
    static func fallback() -> WidgetQuote {
        return WidgetQuote(
            text: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
            author: "Nelson Mandela",
            category: "Inspiration"
        )
    }
}

/// Event model for widget
struct WidgetEvent: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var notes: String
    var isCompleted: Bool = false
    
    static func == (lhs: WidgetEvent, rhs: WidgetEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Timeline entry for quotes widget
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: WidgetQuote
    let eventDays: [Int: Bool]
    let hasError: Bool
    
    /// Default initializer
    init(date: Date, quote: WidgetQuote, eventDays: [Int: Bool], hasError: Bool = false) {
        self.date = date
        self.quote = quote
        self.eventDays = eventDays
        self.hasError = hasError
    }
    
    /// Create a placeholder entry for widget gallery
    static func placeholder() -> QuoteEntry {
        let placeholderQuote = WidgetQuote(
            text: "The best way to predict the future is to create it.",
            author: "Peter Drucker",
            category: "Inspiration"
        )
        
        return QuoteEntry(
            date: Date(),
            quote: placeholderQuote,
            eventDays: [:]
        )
    }
    
    /// Create an error entry when widget encounters problems
    static func error() -> QuoteEntry {
        return QuoteEntry(
            date: Date(),
            quote: WidgetQuote.fallback(),
            eventDays: [:],
            hasError: true
        )
    }
}

// MARK: - Services

/// Service to manage quotes for widgets
class WidgetQuoteService {
    // Singleton instance
    static let shared = WidgetQuoteService()
    
    // Error types for better error handling
    enum QuoteServiceError: Error {
        case noQuotesAvailable
        case dayCalculationFailed
        case randomGenerationFailed
    }
    
    // Quotes data source
    private let quotes: [WidgetQuote]
    
    private init() {
        // Initialize quotes from SharedQuotes
        let sharedQuotes = SharedQuotes.all
        
        if sharedQuotes.isEmpty {
            print("Widget Warning: SharedQuotes.all returned empty array, using fallback quotes")
            // Fallback quotes in case SharedQuotes fails
            self.quotes = [
                WidgetQuote(text: "The best way to predict the future is to create it.", author: "Peter Drucker", category: "Inspiration"),
                WidgetQuote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon", category: "Life"),
                WidgetQuote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Motivation")
            ]
        } else {
            self.quotes = sharedQuotes.map { WidgetQuote(from: $0) }
            print("Widget Info: Loaded \(quotes.count) quotes successfully")
        }
    }
    
    /// Get today's quote based on the calendar date
    func getTodaysQuote() -> WidgetQuote {
        do {
            // Check if quotes array is populated
            guard !quotes.isEmpty else {
                print("Widget Error: No quotes available to get today's quote")
                throw QuoteServiceError.noQuotesAvailable
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Use the day of the year to pick a quote with error handling
            guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) else {
                print("Widget Warning: Could not determine day of year, using first quote")
                throw QuoteServiceError.dayCalculationFailed
            }
            
            // Safely calculate index with bounds checking
            let index = (dayOfYear - 1) % quotes.count
            return quotes[index]
        } catch {
            print("Widget Error retrieving today's quote: \(error.localizedDescription)")
            return WidgetQuote.fallback()
        }
    }
    
    /// Get a random quote
    func getRandomQuote() -> WidgetQuote {
        do {
            // Check if quotes array is populated
            guard !quotes.isEmpty else {
                print("Widget Error: No quotes available to get random quote")
                throw QuoteServiceError.noQuotesAvailable
            }
            
            guard let randomIndex = (0..<quotes.count).randomElement() else {
                print("Widget Error: Failed to generate random index")
                throw QuoteServiceError.randomGenerationFailed
            }
            
            return quotes[randomIndex]
        } catch {
            print("Widget Error retrieving random quote: \(error.localizedDescription)")
            return WidgetQuote.fallback()
        }
    }
}

/// Service to manage events for widgets
struct WidgetEventService {
    /// Get all events saved by the main app
    static func getEvents() -> [WidgetEvent] {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Widget Error: Could not access shared UserDefaults")
            return []
        }
        
        guard let savedEvents = sharedDefaults.data(forKey: "savedEvents") else {
            // No events found, but this is not an error condition
            print("Widget Info: No saved events found in shared storage")
            return []
        }
        
        do {
            let decodedEvents = try JSONDecoder().decode([WidgetEvent].self, from: savedEvents)
            return decodedEvents
        } catch {
            print("Widget Error: Failed to decode events: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Get days in current month that have events
    static func getEventDaysForCurrentMonth() -> [Int: Bool] {
        let events = getEvents()
        if events.isEmpty { return [:] }
        
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Safely extract month and year components
        guard let currentMonth = calendar.dateComponents([.month], from: currentDate).month,
              let currentYear = calendar.dateComponents([.year], from: currentDate).year else {
            return [:]
        }
        
        var eventDays = [Int: Bool]()
        
        for event in events {
            let eventComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
            
            if let eventMonth = eventComponents.month,
               let eventYear = eventComponents.year,
               let day = eventComponents.day,
               eventMonth == currentMonth && eventYear == currentYear {
                eventDays[day] = true
            }
        }
        
        return eventDays
    }
    
    /// Check if app group is accessible
    static func isAppGroupAccessible() -> Bool {
        return UserDefaults(suiteName: appGroupIdentifier) != nil
    }
}

// MARK: - Timeline Provider

/// Timeline Provider for Moti Quote Widgets
struct QuoteTimelineProvider: TimelineProvider {
    /// Placeholder entry for widget gallery
    func placeholder(in context: Context) -> QuoteEntry {
        return QuoteEntry.placeholder()
    }
    
    /// Snapshot for widget gallery or when taking screenshot
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        if !WidgetEventService.isAppGroupAccessible() {
            completion(QuoteEntry.placeholder())
            return
        }
            
        // Get quote with error handling
        let quote = WidgetQuoteService.shared.getTodaysQuote()
        
        // Get event days with error handling
        let eventDays = WidgetEventService.getEventDaysForCurrentMonth()
        
        let entry = QuoteEntry(
            date: Date(),
            quote: quote,
            eventDays: eventDays
        )
        completion(entry)
    }
    
    /// Timeline for the widget to update
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        if !WidgetEventService.isAppGroupAccessible() {
            let fallbackEntry = QuoteEntry.placeholder()
            let fallbackTimeline = Timeline(entries: [fallbackEntry], policy: .after(Date(timeIntervalSinceNow: 60 * 60)))
            completion(fallbackTimeline)
            return
        }
            
        // Get today's quote and events
        let quote = WidgetQuoteService.shared.getTodaysQuote()
        let eventDays = WidgetEventService.getEventDaysForCurrentMonth()
        
        // Create entry for current date
        let entry = QuoteEntry(
            date: Date(),
            quote: quote,
            eventDays: eventDays
        )
        
        // Set next update to tomorrow's midnight
        let refreshDate = nextRefreshDate()
        
        // Create timeline with single entry and update at next midnight
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    /// Calculate next refresh date (midnight tomorrow)
    private func nextRefreshDate() -> Date {
        let calendar = Calendar.current
        
        // Try to get tomorrow at midnight
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            return calendar.startOfDay(for: tomorrow)
        }
        
        // Fallback to +24 hours
        return Date(timeIntervalSinceNow: 24 * 60 * 60)
    }
}

// MARK: - Widget Views

/// Calendar view for the large widget
struct CalendarWidgetView: View {
    let date: Date
    let eventDays: [Int: Bool]
    
    // Create formatters as computed properties outside the body
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
    
    // Calculate calendar information
    var calendarInfo: (firstDay: Int, totalDays: Int, currentDay: Int) {
        let calendar = Calendar.current
        
        // Get first day of month with error handling
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return (0, 30, 1) // Safe fallback values
        }
        
        // Get the weekday of the first day (0-based index)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // Get the number of days in month with error handling
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            return (firstWeekday, 30, 1) // Safe fallback values
        }
        
        let numberOfDays = range.count
        
        // Get the current day
        let currentDay = calendar.component(.day, from: date)
        
        return (firstWeekday, numberOfDays, currentDay)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            // Month title
            Text(monthFormatter.string(from: date))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 4)
            
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
            
            // Calendar grid with error handling
            let calInfo = calendarInfo
            let rows = (calInfo.firstDay + calInfo.totalDays + 6) / 7 // Calculate rows needed
            
            // For each row in the calendar
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    // For each column in the calendar
                    ForEach(0..<7, id: \.self) { column in
                        let dayNumber = row * 7 + column - calInfo.firstDay + 1
                        
                        if dayNumber > 0 && dayNumber <= calInfo.totalDays {
                            ZStack {
                                // Highlight current day
                                if dayNumber == calInfo.currentDay {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 22, height: 22)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: 10))
                                    .foregroundColor(dayNumber == calInfo.currentDay ? Color.black : .white)
                                
                                // Show indicator for days with events
                                if eventDays[dayNumber] == true {
                                    Circle()
                                        .fill(dayNumber == calInfo.currentDay ? Color.blue : Color.blue.opacity(0.7))
                                        .frame(width: 4, height: 4)
                                        .offset(y: 8)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 24)
                        } else {
                            // Empty cell for days outside current month
                            Text("")
                                .frame(maxWidth: .infinity, maxHeight: 24)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

/// Home screen quote widget content view
struct QuoteWidgetContent: View {
    var entry: QuoteEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    // Calculate font size based on widget size
    var quoteFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 14
        case .systemMedium: return 16
        case .systemLarge: return 16
        default: return 16
        }
    }
    
    var authorFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall: return 12
        case .systemMedium, .systemLarge: return 13
        default: return 12
        }
    }
    
    var body: some View {
        ZStack {
            // Unified gradient background for all home screen widgets
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle logo watermark
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("M")
                        .font(.system(size: widgetFamily == .systemSmall ? 70 : 100, weight: .bold))
                        .foregroundColor(.white.opacity(0.08))
                    Spacer()
                }
                Spacer()
            }
            
            // Content based on widget family
            if widgetFamily == .systemLarge {
                // Large widget with quote and calendar
                VStack(alignment: .center, spacing: 8) {
                    // Quote part
                    VStack(spacing: 4) {
                        Text(entry.quote.text)
                            .font(.system(size: quoteFontSize, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(5)
                            .minimumScaleFactor(0.7)
                            .padding(.top, 8)
                        
                        Text("— \(entry.quote.author)")
                            .font(.system(size: authorFontSize, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .padding(.bottom, 2)
                    }
                    .padding(.bottom, 5)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                    
                    // Calendar part
                    CalendarWidgetView(date: entry.date, eventDays: entry.eventDays)
                }
                .padding(12)
            } else {
                // Small or medium widget with just the quote
                VStack(alignment: .center, spacing: widgetFamily == .systemSmall ? 6 : 10) {
                    // Error indicator if needed
                    if entry.hasError {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                            .padding(.top, 8)
                    }
                    
                    // Quote text
                    Text(entry.quote.text)
                        .font(.system(size: quoteFontSize, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(widgetFamily == .systemSmall ? 5 : 6)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // Author attribution
                    Text("— \(entry.quote.author)")
                        .font(.system(size: authorFontSize, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .padding(.top, 2)
                }
                .padding(widgetFamily == .systemSmall ? 12 : 16)
            }
        }
    }
}

/// Inline lock screen widget content view
struct InlineQuoteContent: View {
    var entry: QuoteEntry
    
    var body: some View {
        // Minimal inline widget - just the quote text
        Text(entry.quote.text)
            .font(.system(size: 12, weight: .regular))
            .lineLimit(1)
    }
}

// MARK: - Widget Definitions

/// Quote Widget for home screen
struct QuoteWidget: Widget {
    let kind: String = "DailyQuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteTimelineProvider()) { entry in
            QuoteWidgetContent(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear // Remove white border by setting clear background
                }
        }
        .configurationDisplayName("Daily Quote")
        .description("Displays a new inspirational quote each day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Inline lock screen widget
@available(iOS 16.0, *)
struct InlineQuoteWidget: Widget {
    let kind: String = "InlineQuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteTimelineProvider()) { entry in
            InlineQuoteContent(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear // Clear background for minimal look
                }
        }
        .configurationDisplayName("Inline Quote")
        .description("A minimal text-only quote for your Lock Screen.")
        .supportedFamilies([.accessoryInline])
    }
}
