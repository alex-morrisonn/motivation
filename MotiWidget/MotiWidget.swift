import WidgetKit
import SwiftUI

struct Event: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var date: Date
    var notes: String
    var isCompleted: Bool = false
}

struct Quote: Identifiable, Codable, Equatable {
    var id = UUID()
    let text: String
    let author: String
    let category: String

    init(from sharedQuote: SharedQuote) {
        self.id = sharedQuote.id
        self.text = sharedQuote.text
        self.author = sharedQuote.author
        self.category = sharedQuote.category
    }

    init(text: String, author: String, category: String) {
        self.text = text
        self.author = author
        self.category = category
    }
}

struct WidgetEventService {
    static func getEvents() -> [Event] {
        guard
            let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
            let savedEvents = sharedDefaults.data(forKey: "savedEvents"),
            let decodedEvents = try? JSONDecoder().decode([Event].self, from: savedEvents)
        else {
            return []
        }

        return decodedEvents
    }

    static func eventDaysForMonth(containing date: Date) -> [Int: Bool] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)

        return getEvents().reduce(into: [:]) { result, event in
            let eventComponents = calendar.dateComponents([.year, .month, .day], from: event.date)
            guard
                eventComponents.year == components.year,
                eventComponents.month == components.month,
                let day = eventComponents.day
            else {
                return
            }

            result[day] = true
        }
    }

    static func currentMonthEventCount(on date: Date) -> Int {
        eventDaysForMonth(containing: date).count
    }

    static func upcomingEvents(limit: Int, from date: Date) -> [Event] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)

        return getEvents()
            .filter { !$0.isCompleted && $0.date >= start }
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { $0 }
    }
}

final class QuoteService {
    static let shared = QuoteService()

    private let quotes: [Quote]

    private init() {
        let sharedQuotes = SharedQuotes.all
        if sharedQuotes.isEmpty {
            self.quotes = [
                Quote(text: "The best way to predict the future is to create it.", author: "Peter Drucker", category: "Success"),
                Quote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Motivation")
            ]
        } else {
            self.quotes = sharedQuotes.map(Quote.init(from:))
        }
    }

    func quoteForToday(on date: Date = .now) -> Quote {
        guard !quotes.isEmpty else {
            return Quote(
                text: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
                author: "Nelson Mandela",
                category: "Inspiration"
            )
        }

        let calendar = Calendar.current
        let day = calendar.ordinality(of: .day, in: .year, for: calendar.startOfDay(for: date)) ?? 1
        return quotes[(day - 1) % quotes.count]
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
    let monthEventDays: [Int: Bool]
    let monthEventCount: Int
    let upcomingEvents: [Event]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        sampleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        completion(makeEntry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let now = Date()
        let entry = makeEntry(for: now)
        let refreshDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func makeEntry(for date: Date) -> QuoteEntry {
        QuoteEntry(
            date: date,
            quote: QuoteService.shared.quoteForToday(on: date),
            monthEventDays: WidgetEventService.eventDaysForMonth(containing: date),
            monthEventCount: WidgetEventService.currentMonthEventCount(on: date),
            upcomingEvents: WidgetEventService.upcomingEvents(limit: 3, from: date)
        )
    }

    private var sampleEntry: QuoteEntry {
        let quote = Quote(
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            category: "Success & Achievement"
        )
        let events = [
            Event(title: "Gym", date: .now, notes: "", isCompleted: false),
            Event(title: "Read 20 minutes", date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now, notes: "", isCompleted: false)
        ]

        return QuoteEntry(
            date: .now,
            quote: quote,
            monthEventDays: [4: true, 8: true, 14: true, 21: true],
            monthEventCount: 4,
            upcomingEvents: events
        )
    }
}

private enum WidgetPalette {
    static let backgroundTop = Color.black
    static let backgroundMid = Color(red: 0.10, green: 0.11, blue: 0.17)
    static let backgroundBottom = Color(red: 0.04, green: 0.06, blue: 0.11)
    static let card = Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.96)
    static let cardHighlight = Color.blue.opacity(0.10)
    static let panel = Color.white.opacity(0.05)
    static let panelBorder = Color.white.opacity(0.10)
    static let primaryText = Color.white
    static let secondaryText = Color.gray.opacity(0.95)
    static let accent = Color.blue
    static let accentSoft = Color.blue.opacity(0.18)
    static let eventDot = Color.blue
}

private struct WidgetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WidgetPalette.backgroundTop, WidgetPalette.backgroundMid, WidgetPalette.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [WidgetPalette.cardHighlight, .clear],
                startPoint: .topLeading,
                endPoint: .center
            )

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(WidgetPalette.card)
                .padding(8)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(WidgetPalette.panelBorder, lineWidth: 1)
                .padding(8)
        }
    }
}

private struct CapsuleLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(WidgetPalette.accent)
            .lineLimit(1)
    }
}

private struct MetaRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(WidgetPalette.secondaryText)
    }
}

private struct QuoteHeader: View {
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CapsuleLabel(text: quote.category)
            Text("Today’s Perspective")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.primaryText)
        }
    }
}

private struct AdaptiveQuoteBlock: View {
    let quote: String
    let author: String
    let sizes: [CGFloat]
    let authorSize: CGFloat

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(sizes, id: \.self) { size in
                VStack(alignment: .leading, spacing: max(4, size * 0.3)) {
                    Text("“\(quote)”")
                        .font(.system(size: size, weight: .semibold, design: .rounded))
                        .foregroundStyle(WidgetPalette.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("— \(author)")
                        .font(.system(size: authorSize, weight: .medium))
                        .foregroundStyle(WidgetPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct SmallQuoteWidgetView: View {
    let entry: QuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CapsuleLabel(text: entry.quote.category)

            AdaptiveQuoteBlock(
                quote: entry.quote.text,
                author: entry.quote.author,
                sizes: [15, 14, 13, 12, 11, 10],
                authorSize: 11
            )
        }
        .padding(14)
        .widgetURL(URL(string: "moti://quotes"))
    }
}

private struct MediumQuoteWidgetView: View {
    let entry: QuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            QuoteHeader(quote: entry.quote)

            AdaptiveQuoteBlock(
                quote: entry.quote.text,
                author: entry.quote.author,
                sizes: [18, 17, 16, 15, 14, 13, 12],
                authorSize: 12
            )
        }
        .padding(16)
        .widgetURL(URL(string: "moti://quotes"))
    }
}

private struct LargeQuoteWidgetView: View {
    let entry: QuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuoteHeader(quote: entry.quote)

            AdaptiveQuoteBlock(
                quote: entry.quote.text,
                author: entry.quote.author,
                sizes: [22, 20, 18, 16, 15, 14],
                authorSize: 13
            )

            if let nextEvent = entry.upcomingEvents.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Plan")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetPalette.secondaryText)

                    EventCard(event: nextEvent, style: .featured)
                }
            } else {
                MetaRow(icon: "calendar", text: entry.monthEventCount == 1 ? "1 plan this month" : "\(entry.monthEventCount) plans this month")
            }
        }
        .padding(16)
        .widgetURL(URL(string: nextEventURL))
    }

    private var nextEventURL: String {
        entry.upcomingEvents.isEmpty ? "moti://quotes" : "moti://calendar"
    }
}

private enum EventCardStyle {
    case featured
}

private struct EventCard: View {
    let event: Event
    let style: EventCardStyle

    private var dateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(event.date) {
            return "Today"
        }
        if calendar.isDateInTomorrow(event.date) {
            return "Tomorrow"
        }
        return event.date.formatted(.dateTime.weekday(.abbreviated).day())
    }

    private var timeLabel: String {
        event.date.formatted(.dateTime.hour().minute())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: style == .featured ? 8 : 5) {
            HStack {
                Text(dateLabel)
                    .font(.system(size: style == .featured ? 12 : 11, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accent)

                Spacer(minLength: 8)

                Text(timeLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(WidgetPalette.secondaryText)
            }

            Text(event.title)
                .font(.system(size: style == .featured ? 14 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(WidgetPalette.primaryText)
                .lineLimit(2)
        }
        .padding(style == .featured ? 12 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WidgetPalette.panel, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(WidgetPalette.panelBorder, lineWidth: 1)
        )
    }
}

private struct RectangularAccessoryView: View {
    let entry: QuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.quote.text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text("— \(entry.quote.author)")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WidgetPalette.secondaryText)
                .lineLimit(1)
        }
        .widgetURL(URL(string: "moti://quotes"))
    }
}

private struct CircularAccessoryView: View {
    let entry: QuoteEntry

    private var day: String {
        String(Calendar.current.component(.day, from: entry.date))
    }

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(WidgetPalette.secondaryText.opacity(0.35), lineWidth: 1.2)
            VStack(spacing: 2) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetPalette.accent)
                Text(day)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
        }
        .widgetURL(URL(string: "moti://quotes"))
    }
}

private struct InlineAccessoryView: View {
    let entry: QuoteEntry

    var body: some View {
        Text("“\(entry.quote.author)”")
            .widgetURL(URL(string: "moti://quotes"))
    }
}

struct QuoteWidgetEntryView: View {
    let entry: QuoteEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallQuoteWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        case .systemMedium:
            MediumQuoteWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        case .systemLarge:
            LargeQuoteWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        case .accessoryRectangular:
            RectangularAccessoryView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        case .accessoryCircular:
            CircularAccessoryView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        case .accessoryInline:
            InlineAccessoryView(entry: entry)
        default:
            SmallQuoteWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
    }
}

struct QuoteWidget: Widget {
    let kind = "DailyQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Daily Focus")
        .description("A cleaner daily quote with your next plans and monthly rhythm.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CompactQuoteWidget: Widget {
    let kind = "CompactQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focus Snapshot")
        .description("Compact motivation and calendar context for the Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    QuoteWidget()
} timeline: {
    QuoteEntry(
        date: .now,
        quote: Quote(
            text: "The only way to do great work is to love what you do.",
            author: "Steve Jobs",
            category: "Success & Achievement"
        ),
        monthEventDays: [4: true, 8: true, 14: true, 21: true],
        monthEventCount: 4,
        upcomingEvents: [
            Event(title: "Morning run", date: .now, notes: "", isCompleted: false)
        ]
    )
}
