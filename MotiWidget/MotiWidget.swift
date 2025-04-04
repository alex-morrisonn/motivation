import WidgetKit
import SwiftUI
import Intents

// Need to redeclare Event model for the widget extension
struct Event: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var notes: String
    var isCompleted: Bool = false
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id
    }
}

// Need to redeclare Quote model for the widget extension
struct Quote: Identifiable, Codable, Equatable {
    var id = UUID()
    let text: String
    let author: String
    let category: String
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Constructor to create from SharedQuote
    init(from sharedQuote: SharedQuote) {
        self.id = sharedQuote.id
        self.text = sharedQuote.text
        self.author = sharedQuote.author
        self.category = sharedQuote.category
    }
    
    // For creating quotes directly
    init(text: String, author: String, category: String) {
        self.text = text
        self.author = author
        self.category = category
    }
}

// Widget Event Service to access events
struct WidgetEventService {
    // Defined error types for better error handling
    enum WidgetServiceError: Error {
        case appGroupAccessFailed
        case dataCorrupted
        case decodingFailed
        case noEventsFound
        
        var description: String {
            switch self {
            case .appGroupAccessFailed: return "Failed to access app group"
            case .dataCorrupted: return "Event data is corrupted"
            case .decodingFailed: return "Failed to decode events"
            case .noEventsFound: return "No events found in storage"
            }
        }
    }
    
    // Get all events saved by the main app with robust error handling
    static func getEvents() -> [Event] {
        do {
            guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
                print("Widget Error: Could not access shared UserDefaults")
                throw WidgetServiceError.appGroupAccessFailed
            }
            
            guard let savedEvents = sharedDefaults.data(forKey: "savedEvents") else {
                // No events found, but this is not an error condition
                print("Widget Info: No saved events found in shared storage")
                return []
            }
            
            do {
                let decodedEvents = try JSONDecoder().decode([Event].self, from: savedEvents)
                print("Widget Info: Successfully loaded \(decodedEvents.count) events")
                return decodedEvents
            } catch let decodingError as DecodingError {
                // Handle specific JSON decoding errors
                switch decodingError {
                case .dataCorrupted(let context):
                    print("Widget Error: Data corrupted: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    print("Widget Error: Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Widget Error: Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Widget Error: Value of type \(type) not found: \(context.debugDescription)")
                @unknown default:
                    print("Widget Error: Unknown decoding error: \(decodingError)")
                }
                throw WidgetServiceError.decodingFailed
            } catch {
                print("Widget Error: Failed to decode events: \(error.localizedDescription)")
                throw WidgetServiceError.decodingFailed
            }
        } catch {
            print("Widget Error: \(error.localizedDescription)")
            return [] // Return empty array on error for graceful degradation
        }
    }
    
    // Get days in current month that have events with error handling
    static func getEventDaysForCurrentMonth() -> [Int: Bool] {
        do {
            let events = getEvents()
            
            // Early return if no events available
            if events.isEmpty {
                print("Widget Info: No events available to calculate event days")
                return [:]
            }
            
            let calendar = Calendar.current
            let currentDate = Date()
            
            // Safely extract month and year components
            guard let currentMonth = calendar.dateComponents([.month], from: currentDate).month,
                  let currentYear = calendar.dateComponents([.year], from: currentDate).year else {
                print("Widget Error: Failed to determine current month/year")
                return [:]
            }
            
            var eventDays = [Int: Bool]()
            var processedEventsCount = 0
            
            for event in events {
                do {
                    let eventComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
                    
                    guard let eventMonth = eventComponents.month,
                          let eventYear = eventComponents.year,
                          let day = eventComponents.day else {
                        print("Widget Warning: Invalid date components in event '\(event.title)'")
                        continue
                    }
                    
                    // Only include events from current month and year
                    if eventMonth == currentMonth && eventYear == currentYear {
                        eventDays[day] = true
                        processedEventsCount += 1
                    }
                } catch {
                    print("Widget Warning: Failed to process event date: \(error.localizedDescription)")
                    // Continue processing other events
                    continue
                }
            }
            
            print("Widget Info: Found \(processedEventsCount) events for current month")
            return eventDays
        } catch {
            print("Widget Error getting event days: \(error.localizedDescription)")
            return [:] // Return empty dictionary on error for graceful degradation
        }
    }
    
    // New helper method to check if app group is accessible
    static func isAppGroupAccessible() -> Bool {
        guard let _ = UserDefaults(suiteName: appGroupIdentifier) else {
            return false
        }
        return true
    }
}

// Improved QuoteService with error handling for widgets
class QuoteService {
    static let shared = QuoteService()
    
    // Defined error types for better error handling
    enum QuoteServiceError: Error {
        case noQuotesAvailable
        case dayCalculationFailed
        case randomGenerationFailed
        
        var description: String {
            switch self {
            case .noQuotesAvailable: return "No quotes are available"
            case .dayCalculationFailed: return "Failed to calculate day of year"
            case .randomGenerationFailed: return "Failed to generate random quote"
            }
        }
    }
    
    // Local quotes data source using the shared quotes
    private let quotes: [Quote]
    
    init() {
        // Initialize quotes with fallback for empty array
        let sharedQuotes = SharedQuotes.all
        
        if sharedQuotes.isEmpty {
            print("Widget Warning: SharedQuotes.all returned empty array, using fallback quotes")
            // Fallback quotes in case SharedQuotes fails
            self.quotes = [
                Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker", category: "Inspiration"),
                Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon", category: "Life"),
                Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Motivation")
            ]
        } else {
            self.quotes = sharedQuotes.map { Quote(from: $0) }
            print("Widget Info: Loaded \(quotes.count) quotes successfully")
        }
    }
    
    // Function to get today's quote with error handling
    func getTodaysQuote() -> Quote {
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
            return getFallbackQuote()
        }
    }
    
    // Function to get a random quote with error handling
    func getRandomQuote() -> Quote {
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
            return getFallbackQuote()
        }
    }
    
    // Improved fallback quote in case of errors
    func getFallbackQuote() -> Quote {
        return Quote(
            text: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
            author: "Nelson Mandela",
            category: "Inspiration"
        )
    }
}

// Timeline Entry
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
    let eventDays: [Int: Bool]
    let hasError: Bool
    
    // Default initializer with error flag
    init(date: Date, quote: Quote, eventDays: [Int: Bool], hasError: Bool = false) {
        self.date = date
        self.quote = quote
        self.eventDays = eventDays
        self.hasError = hasError
    }
    
    // Static factory method for creating error entries
    static func createErrorEntry() -> QuoteEntry {
        let errorQuote = Quote(
            text: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
            author: "Nelson Mandela",
            category: "Fallback"
        )
        
        return QuoteEntry(
            date: Date(),
            quote: errorQuote,
            eventDays: [:],
            hasError: true
        )
    }
}

// Timeline Provider with robust error handling
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        // Placeholder for widget gallery - must be reliable
        return QuoteEntry(
            date: Date(),
            quote: createSafePlaceholderQuote(),
            eventDays: [:]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        // Snapshot for widget gallery or when taking screenshot
        do {
            // Check for app group access first
            if !WidgetEventService.isAppGroupAccessible() {
                print("Widget Warning: App group not accessible for snapshot, using placeholder data")
                completion(createSafePlaceholderEntry())
                return
            }
            
            // Get quote with error handling
            let quote: Quote
            do {
                quote = QuoteService.shared.getTodaysQuote()
            } catch {
                print("Widget Error: Failed to get quote for snapshot: \(error.localizedDescription)")
                quote = createSafePlaceholderQuote()
            }
            
            // Get event days with error handling
            var eventDays: [Int: Bool] = [:]
            do {
                eventDays = WidgetEventService.getEventDaysForCurrentMonth()
            } catch {
                print("Widget Warning: Could not retrieve event days for snapshot: \(error.localizedDescription)")
                // Continue with empty event days
            }
            
            let entry = QuoteEntry(
                date: Date(),
                quote: quote,
                eventDays: eventDays
            )
            completion(entry)
        } catch {
            // Global error handler
            print("Widget Error creating snapshot: \(error.localizedDescription)")
            
            // Provide a reliable fallback
            completion(createSafePlaceholderEntry())
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        do {
            // Check for app group access first
            if !WidgetEventService.isAppGroupAccessible() {
                print("Widget Warning: App group not accessible for timeline, using placeholder data")
                
                let fallbackEntry = createSafePlaceholderEntry()
                let fallbackTimeline = Timeline(entries: [fallbackEntry], policy: .after(fallbackRefreshDate()))
                
                completion(fallbackTimeline)
                return
            }
            
            // Get today's quote with error handling
            let quote: Quote
            do {
                quote = QuoteService.shared.getTodaysQuote()
            } catch {
                print("Widget Error retrieving quote for timeline: \(error.localizedDescription)")
                quote = createSafePlaceholderQuote()
            }
            
            // Get real event days from the main app with error handling
            let eventDays: [Int: Bool]
            do {
                eventDays = WidgetEventService.getEventDaysForCurrentMonth()
            } catch {
                print("Widget Error retrieving event days for timeline: \(error.localizedDescription)")
                eventDays = [:]
            }
            
            // Create entry for current date
            let currentDate = Date()
            let entry = QuoteEntry(
                date: currentDate,
                quote: quote,
                eventDays: eventDays
            )
            
            // Set next update to tomorrow's midnight with error handling
            let refreshDate = nextRefreshDate(currentDate)
            
            // Create timeline with single entry and update at next midnight
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        } catch {
            // Global error handler
            print("Widget Error creating timeline: \(error.localizedDescription)")
            
            // Provide a reliable fallback timeline that updates in 1 hour
            let fallbackEntry = createSafePlaceholderEntry()
            let fallbackTimeline = Timeline(entries: [fallbackEntry], policy: .after(fallbackRefreshDate()))
            
            completion(fallbackTimeline)
        }
    }
    
    // Helper method to create a reliable placeholder quote
    private func createSafePlaceholderQuote() -> Quote {
        return Quote(
            text: "The best way to predict the future is to create it.",
            author: "Peter Drucker",
            category: "Inspiration"
        )
    }
    
    // Helper method to create a safe placeholder entry
    private func createSafePlaceholderEntry() -> QuoteEntry {
        return QuoteEntry(
            date: Date(),
            quote: createSafePlaceholderQuote(),
            eventDays: [:]
        )
    }
    
    // Calculate next refresh date with error handling
    private func nextRefreshDate(_ currentDate: Date) -> Date {
        let calendar = Calendar.current
        
        // Try to get tomorrow at midnight
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate) {
            // Don't use if let here since startOfDay returns a non-optional Date
            let midnight = calendar.startOfDay(for: tomorrow)
            return midnight
        }
        
        // Fallback to +24 hours if date calculation fails
        print("Widget Warning: Failed to calculate tomorrow's date, using 24 hours from now")
        return Date(timeIntervalSinceNow: 24 * 60 * 60)
    }
    
    // Fallback refresh date (1 hour from now)
    private func fallbackRefreshDate() -> Date {
        return Date(timeIntervalSinceNow: 60 * 60)
    }
}

// Widget View Content with Calendar for Large Widget
struct QuoteContent: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    // Calculate font size based on widget size
    var quoteFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 14
        case .systemMedium:
            return 16
        case .systemLarge:
            return 16  // Slightly smaller for large to accommodate calendar
        default:
            return 16
        }
    }
    
    var authorFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 12
        case .systemMedium:
            return 13
        default:
            return 13
        }
    }
    
    // Get current date information
    var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: entry.date)
    }
    
    // Days of the week header
    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Calendar computation for current month with error handling
    func calendarDays() -> (firstDay: Int, totalDays: Int, currentDay: Int) {
        let calendar = Calendar.current
        let date = entry.date
        
        // Get first day of month with error handling
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            print("Widget Error: Failed to calculate first day of month")
            return (0, 30, 1) // Safe fallback values
        }
        
        // Get the weekday of the first day (0-based index)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        // Get the number of days in month with error handling
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            print("Widget Error: Failed to calculate days in month")
            return (firstWeekday, 30, 1) // Safe fallback values
        }
        
        let numberOfDays = range.count
        
        // Get the current day
        let currentDay = calendar.component(.day, from: date)
        
        return (firstWeekday, numberOfDays, currentDay)
    }
    
    // Check if a date has events using the entry data
    func hasEvents(for day: Int) -> Bool {
        return entry.eventDays[day] == true
    }
    
    var body: some View {
        ZStack {
            // Unified gradient background for all widget sizes
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
                        .font(.system(size: widgetFamily == .systemSmall ? 70 : 100, weight: .bold))
                        .foregroundColor(.white.opacity(0.08))
                    Spacer()
                }
                Spacer()
            }
            
            // Content based on widget size
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
                    VStack(alignment: .center, spacing: 4) {
                        Text(currentMonth)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 4)
                        
                        // Weekday headers
                        HStack(spacing: 0) {
                            ForEach(weekdays, id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 2)
                        
                        // Calendar grid with error handling
                        let calInfo = calendarDays()
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
                                            if hasEvents(for: dayNumber) {
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
                .padding(12)
                .widgetURL(URL(string: "moti://calendar"))  // Deep link to calendar view
            } else {
                // Regular widget with just the quote
                VStack(alignment: .center, spacing: widgetFamily == .systemSmall ? 6 : 10) {
                    // Show error message if hasError is true
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
                    
                    // Author
                    Text("— \(entry.quote.author)")
                        .font(.system(size: authorFontSize, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                        .padding(.top, 2)
                }
                .padding(widgetFamily == .systemSmall ? 12 : 16)
                .widgetURL(URL(string: "moti://quotes"))  // Deep link to quotes view
            }
        }
    }
}

// Widget Entry View with Container Background
struct QuoteWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        if widgetFamily == .accessoryRectangular || widgetFamily == .accessoryCircular || widgetFamily == .accessoryInline {
            // For Apple Watch and Lock Screen widgets
            Group {
                if entry.hasError {
                    // Show simplified error view for accessory widgets
                    if widgetFamily == .accessoryInline {
                        Text("Quote unavailable")
                    } else {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: widgetFamily == .accessoryCircular ? 16 : 12))
                            Text("Tap to refresh")
                                .font(.caption2)
                        }
                    }
                } else {
                    // Normal content
                    Text(entry.quote.text)
                        .font(.caption2)
                        .lineLimit(widgetFamily == .accessoryInline ? 1 : 3)
                }
            }
            .containerBackground(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                for: .widget
            )
        } else {
            // Use the unified QuoteContent for all standard widget sizes
            QuoteContent(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
    }
}

// Standard Quote Widget
struct QuoteWidget: Widget {
    let kind: String = "DailyQuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Quote")
        .description("Displays a new inspirational quote each day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Compact Quote Widget for Lock Screen
struct CompactQuoteWidget: Widget {
    let kind: String = "CompactQuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Compact Quote")
        .description("A compact inspirational quote for your Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// Preview Provider
struct MotiWidget_Previews: PreviewProvider {
    static var previews: some View {
        // Create sample data
        let sampleQuote = Quote(from: SharedQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Success & Achievement"))
        let sampleEvents = [5, 10, 15, 20, 25].reduce(into: [Int: Bool]()) { $0[$1] = true }
        
        // Create preview entries
        let normalEntry = QuoteEntry(date: Date(), quote: sampleQuote, eventDays: sampleEvents)
        let errorEntry = QuoteEntry(date: Date(), quote: sampleQuote, eventDays: [:], hasError: true)
        
        Group {
            // Preview standard layouts
            QuoteWidgetEntryView(entry: normalEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            QuoteWidgetEntryView(entry: normalEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
            
            QuoteWidgetEntryView(entry: normalEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
            
            // Preview error state
            QuoteWidgetEntryView(entry: errorEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Error State")
            
            // Preview lock screen widgets
            QuoteWidgetEntryView(entry: normalEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Lock Screen Rectangle")
            
            QuoteWidgetEntryView(entry: normalEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Lock Screen Circle")
            
            QuoteWidgetEntryView(entry: normalEntry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Lock Screen Inline")
        }
    }
}
