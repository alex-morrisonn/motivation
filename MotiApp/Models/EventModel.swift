import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// Event model for calendar entries
struct Event: Identifiable, Codable, Equatable {
    // Unique identifier for the event
    var id = UUID()

    // Event properties
    var title: String
    var date: Date
    var notes: String
    var isCompleted: Bool = false
    var iconName: String = EventIconLibrary.defaultIcon
    var tintHex: String = EventTintPalette.defaultHex
    var isAllDay: Bool = false

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case notes
        case isCompleted
        case iconName
        case tintHex
        case isAllDay
    }

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        notes: String,
        isCompleted: Bool = false,
        iconName: String = EventIconLibrary.defaultIcon,
        tintHex: String = EventTintPalette.defaultHex,
        isAllDay: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.notes = notes
        self.isCompleted = isCompleted
        self.iconName = iconName
        self.tintHex = tintHex
        self.isAllDay = isAllDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? EventIconLibrary.defaultIcon
        tintHex = try container.decodeIfPresent(String.self, forKey: .tintHex) ?? EventTintPalette.defaultHex
        isAllDay = try container.decodeIfPresent(Bool.self, forKey: .isAllDay) ?? false
    }

    // Equatable implementation
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Convenience Methods

    /// Check if event is scheduled for today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Check if event is in the past
    var isPast: Bool {
        date < Date()
    }

    /// Check if event is in the future
    var isFuture: Bool {
        date > Date()
    }

    var tintColor: Color {
        EventTintPalette.color(for: tintHex)
    }

    /// Returns a formatted time string
    var formattedTime: String {
        if isAllDay {
            return "All day"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Returns a formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Factory Methods

    /// Create a new event scheduled for today
    static func createForToday(title: String, notes: String = "") -> Event {
        let today = Date()
        return Event(title: title, date: today, notes: notes)
    }

    /// Create a new event scheduled for tomorrow
    static func createForTomorrow(title: String, notes: String = "") -> Event {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Event(title: title, date: tomorrow, notes: notes)
    }

    /// Create a sample event for UI previews
    static var sample: Event {
        Event(
            id: UUID(),
            title: "Sample Event",
            date: Date(),
            notes: "This is a sample event for testing",
            isCompleted: false,
            iconName: "sparkles",
            tintHex: EventTintPalette.options[0].hex
        )
    }
}

struct EventTintPalette {
    struct Option: Identifiable, Hashable {
        let id: String
        let name: String
        let hex: String

        init(name: String, hex: String) {
            self.id = hex
            self.name = name
            self.hex = hex
        }
    }

    static let options: [Option] = [
        Option(name: "Sky", hex: "#5AA9FF"),
        Option(name: "Mint", hex: "#4DD3A9"),
        Option(name: "Sun", hex: "#FFB347"),
        Option(name: "Rose", hex: "#FF6B8A"),
        Option(name: "Lavender", hex: "#9B8CFF"),
        Option(name: "Coral", hex: "#FF7A59")
    ]

    static let defaultHex = options[0].hex

    static func color(for hex: String) -> Color {
        Color(calendarHex: hex) ?? .blue
    }
}

struct EventIconLibrary {
    static let defaultIcon = "sparkles"

    static let options = [
        "sparkles",
        "figure.run",
        "book.closed",
        "briefcase",
        "moon.stars",
        "sun.max",
        "heart",
        "person.2",
        "target",
        "bolt",
        "music.note",
        "airplane"
    ]
}

extension Color {
    init?(calendarHex: String) {
        #if canImport(UIKit)
        let cleaned = calendarHex.replacingOccurrences(of: "#", with: "")
        guard let value = UInt64(cleaned, radix: 16) else {
            return nil
        }

        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        switch cleaned.count {
        case 6:
            red = CGFloat((value & 0xFF0000) >> 16) / 255
            green = CGFloat((value & 0x00FF00) >> 8) / 255
            blue = CGFloat(value & 0x0000FF) / 255
            alpha = 1
        case 8:
            red = CGFloat((value & 0xFF000000) >> 24) / 255
            green = CGFloat((value & 0x00FF0000) >> 16) / 255
            blue = CGFloat((value & 0x0000FF00) >> 8) / 255
            alpha = CGFloat(value & 0x000000FF) / 255
        default:
            return nil
        }

        self = Color(uiColor: UIColor(red: red, green: green, blue: blue, alpha: alpha))
        #else
        return nil
        #endif
    }
}
