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

// Shared App Group identifier
let appGroupIdentifier = "group.com.alexmorrison.moti.shared"

// Access shared UserDefaults
extension UserDefaults {
    static var shared: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

// Widget Event Service to access events
struct WidgetEventService {
    // Get all events saved by the main app
    static func getEvents() -> [Event] {
        if let savedEvents = UserDefaults.shared.data(forKey: "savedEvents") {
            if let decodedEvents = try? JSONDecoder().decode([Event].self, from: savedEvents) {
                return decodedEvents
            }
        }
        return [] // Return empty array if no events found
    }
    
    // Get days in current month that have events
    static func getEventDaysForCurrentMonth() -> [Int: Bool] {
        let events = getEvents()
        let calendar = Calendar.current
        let currentDate = Date()
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentYear = calendar.component(.year, from: currentDate)
        
        var eventDays = [Int: Bool]()
        
        for event in events {
            let eventMonth = calendar.component(.month, from: event.date)
            let eventYear = calendar.component(.year, from: event.date)
            
            // Only include events from current month and year
            if eventMonth == currentMonth && eventYear == currentYear {
                let day = calendar.component(.day, from: event.date)
                eventDays[day] = true
            }
        }
        
        return eventDays
    }
}

class QuoteService {
    static let shared = QuoteService()
    
    // Local quotes data source using the shared quotes
    private let quotes: [Quote] = SharedQuotes.all.map { Quote(from: $0) }
    
    // Function to get today's quote
    func getTodaysQuote() -> Quote {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use the day of the year to pick a quote
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) else {
            return quotes[0] // Fallback to first quote
        }
        
        // Use modulo to ensure we always get a valid index
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }
    
    // Function to get a random quote
    func getRandomQuote() -> Quote {
        let randomIndex = Int.random(in: 0..<quotes.count)
        return quotes[randomIndex]
    }
}

// Timeline Entry
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
    let eventDays: [Int: Bool]
}

// Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        // Placeholder for widget gallery
        QuoteEntry(
            date: Date(),
            quote: Quote(from: SharedQuotes.all[0]),
            eventDays: WidgetEventService.getEventDaysForCurrentMonth()
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        // Snapshot for widget gallery or when taking screenshot
        let entry = QuoteEntry(
            date: Date(),
            quote: QuoteService.shared.getTodaysQuote(),
            eventDays: WidgetEventService.getEventDaysForCurrentMonth()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        // Get today's quote
        let quote = QuoteService.shared.getTodaysQuote()
        
        // Get real event days from the main app
        let eventDays = WidgetEventService.getEventDaysForCurrentMonth()
        
        // Create entry for current date
        let currentDate = Date()
        let entry = QuoteEntry(
            date: currentDate,
            quote: quote,
            eventDays: eventDays
        )
        
        // Set next update to tomorrow's midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        let midnight = calendar.startOfDay(for: tomorrow)
        
        // Create timeline with single entry and update at next midnight
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
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
    
    // Calendar computation for current month
    func calendarDays() -> (firstDay: Int, totalDays: Int, currentDay: Int) {
        let calendar = Calendar.current
        let date = entry.date
        
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0-based index
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numberOfDays = range.count
        
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
                        
                        // Calendar grid
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
            Text(entry.quote.text)
                .font(.caption2)
                .lineLimit(widgetFamily == .accessoryInline ? 1 : 3)
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
        let sampleQuote = Quote(from: SharedQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Success & Achievement"))
        let sampleEvents = [5, 10, 15, 20, 25].reduce(into: [Int: Bool]()) { $0[$1] = true }
        let entry = QuoteEntry(date: Date(), quote: sampleQuote, eventDays: sampleEvents)
        
        Group {
            // Preview standard layouts
            QuoteWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            QuoteWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
            
            QuoteWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
            
            // Preview lock screen widgets
            QuoteWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
                .previewDisplayName("Lock Screen Rectangle")
            
            QuoteWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
                .previewDisplayName("Lock Screen Circle")
            
            QuoteWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
                .previewDisplayName("Lock Screen Inline")
        }
    }
}
