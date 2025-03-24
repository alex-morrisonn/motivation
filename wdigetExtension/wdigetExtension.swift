import WidgetKit
import SwiftUI
import Intents

// Need to redeclare Quote model for the widget extension
struct Quote: Identifiable, Codable, Equatable {
    var id = UUID()
    let text: String
    let author: String
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Constructor to create from SharedQuote
    init(from sharedQuote: SharedQuote) {
        self.id = sharedQuote.id
        self.text = sharedQuote.text
        self.author = sharedQuote.author
    }
}

class QuoteService {
    static let shared = QuoteService()
    
    // Local quotes data source - now using the shared quotes
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
}

// Timeline Entry
struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

// Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        // Placeholder for widget gallery
        QuoteEntry(
            date: Date(),
            quote: Quote(from: SharedQuotes.all[0])
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        // Snapshot for widget gallery or when taking screenshot
        let entry = QuoteEntry(
            date: Date(),
            quote: QuoteService.shared.getTodaysQuote()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        // Get today's quote
        let quote = QuoteService.shared.getTodaysQuote()
        
        // Create entry for current date
        let currentDate = Date()
        let entry = QuoteEntry(date: currentDate, quote: quote)
        
        // Set next update to tomorrow's midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        let midnight = calendar.startOfDay(for: tomorrow)
        
        // Create timeline with single entry and update at next midnight
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// Widget View
struct QuoteWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 8) {
                Text(entry.quote.text)
                    .font(widgetFamily == .systemSmall ? .caption : .body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .minimumScaleFactor(0.7)
                
                Spacer(minLength: 4)
                
                Text("— \(entry.quote.author)")
                    .font(widgetFamily == .systemSmall ? .caption2 : .caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

// Widget Configuration
struct QuoteWidget: Widget {
    let kind: String = "wdigetExtension"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Quote")
        .description("Displays a new motivational quote each day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
