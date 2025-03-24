import WidgetKit
import SwiftUI
import Intents

// Need to redeclare Quote model and QuoteService for the widget extension
struct Quote: Identifiable, Codable, Equatable {
    var id = UUID()
    let text: String
    let author: String
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        return lhs.id == rhs.id
    }
}

class QuoteService {
    static let shared = QuoteService()
    
    // Local quotes data source - same as in the main app
    private let quotes: [Quote] = [
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        Quote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon"),
        Quote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt"),
        Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
        Quote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius"),
        Quote(text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs"),
        Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker"),
        Quote(text: "Success is not final, failure is not fatal: It is the courage to continue that counts.", author: "Winston Churchill"),
        Quote(text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein"),
        Quote(text: "The only limit to our realization of tomorrow will be our doubts of today.", author: "Franklin D. Roosevelt"),
        Quote(text: "The purpose of our lives is to be happy.", author: "Dalai Lama"),
        Quote(text: "Don't count the days, make the days count.", author: "Muhammad Ali"),
        Quote(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney"),
        Quote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis"),
        Quote(text: "Be the change that you wish to see in the world.", author: "Mahatma Gandhi"),
        Quote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar"),
        Quote(text: "If you want to live a happy life, tie it to a goal, not to people or things.", author: "Albert Einstein"),
        Quote(text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson"),
        Quote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela"),
        Quote(text: "Life is 10% what happens to us and 90% how we react to it.", author: "Charles R. Swindoll"),
        Quote(text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky"),
        Quote(text: "Whether you think you can or you think you can't, you're right.", author: "Henry Ford"),
        Quote(text: "I have not failed. I've just found 10,000 ways that won't work.", author: "Thomas Edison"),
        Quote(text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu"),
        Quote(text: "Every moment is a fresh beginning.", author: "T.S. Eliot"),
        Quote(text: "Start each day with a positive thought and a grateful heart.", author: "Roy T. Bennett")
    ]
    
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
            quote: Quote(text: "Widget placeholder quote", author: "Author")
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
