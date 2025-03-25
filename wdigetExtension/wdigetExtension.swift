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

// Widget View Content
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
        default:
            return 18
        }
    }
    
    var authorFontSize: CGFloat {
        switch widgetFamily {
        case .systemSmall:
            return 12
        case .systemMedium:
            return 13
        default:
            return 14
        }
    }
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
            
            // Add logo as a subtle watermark in the background
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("M")
                        .font(.system(size: widgetFamily == .systemSmall ? 80 : 100, weight: .bold))
                        .foregroundColor(.white.opacity(0.08))
                    Spacer()
                }
                Spacer()
            }
            
            // Quote content with padding adjustments based on widget size
            VStack(alignment: .center, spacing: widgetFamily == .systemSmall ? 8 : 12) {
                // Quote text
                Text(entry.quote.text)
                    .font(.system(size: quoteFontSize, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(widgetFamily == .systemSmall ? 4 : 6)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
                // Author
                Text("— \(entry.quote.author)")
                    .font(.system(size: authorFontSize, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .padding(.top, 4)
            }
            .padding(widgetFamily == .systemSmall ? 16 : 20)
        }
    }
}

// Widget Entry View with Container Background
struct QuoteWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        QuoteContent(entry: entry)
            .containerBackground(.black, for: .widget)
    }
}

// Widget Configuration
struct QuoteWidget: Widget {
    let kind: String = "DailyQuoteWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Quote")
        .description("Displays a new inspirational quote each day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Preview Provider
struct QuoteWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleQuote = Quote(from: SharedQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Success & Achievement"))
        let entry = QuoteEntry(date: Date(), quote: sampleQuote)
        
        QuoteWidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
