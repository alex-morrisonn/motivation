import Foundation
import SwiftUI

/// Note model for storing user's notes and thoughts
class Note: Identifiable, Codable, Equatable {
    // Unique identifier for the note
    var id = UUID()
    
    // Note properties
    var title: String
    var content: String
    var color: NoteColor
    var type: NoteType
    var isPinned: Bool
    var lastEditedDate: Date
    var tags: [String]
    
    // Type of note for different formatting options
    enum NoteType: String, Codable, CaseIterable, Identifiable {
        case basic = "Basic"
        case bullets = "Bullets"
        case markdown = "Markdown"
        case sketch = "Sketch"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .basic: return "text.alignleft"
            case .bullets: return "list.bullet"
            case .markdown: return "text.badge.checkmark"
            case .sketch: return "pencil.line"
            }
        }
    }
    
    // Predefined colors for notes
    enum NoteColor: String, Codable, CaseIterable, Identifiable {
        case blue = "#3b5998"
        case purple = "#6a0dad"
        case lightBlue = "#1DA1F2"
        case orange = "#FF5700"
        case green = "#25D366"
        case red = "#FF0000"
        
        var id: String { self.rawValue }
        
        // Convert hex string to SwiftUI Color
        var color: Color {
            Color(hex: self.rawValue) ?? .blue
        }
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Initializers
    
    /// Create a new note with default values
    init(title: String = "",
         content: String = "",
         color: NoteColor = .blue,
         type: NoteType = .basic,
         isPinned: Bool = false,
         tags: [String] = []) {
        
        self.title = title
        self.content = content
        self.color = color
        self.type = type
        self.isPinned = isPinned
        self.lastEditedDate = Date()
        self.tags = tags
    }
    
    // MARK: - Helper Methods
    
    /// Returns formatted string for last edited date
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastEditedDate, relativeTo: Date())
    }
    
    /// Returns a preview of the content (first few characters)
    func getContentPreview(maxLength: Int = 100) -> String {
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
    
    // MARK: - Factory Methods
    
    /// Create a sample note for UI previews
    static var sample: Note {
        Note(
            title: "Sample Note",
            content: "This is a sample note with some content.",
            color: .blue,
            type: .basic,
            isPinned: false,
            tags: ["sample", "example"]
        )
    }
    
    /// Create multiple samples for UI previews
    static var samples: [Note] {
        [
            Note(
                title: "Morning Reflection",
                content: "• Feeling motivated about the new project\n• Need to remember to take breaks during focus sessions\n• Schedule call with mentor next week\n\nThe quote from today was really helpful: \"The only way to do great work is to love what you do.\"",
                color: .blue,
                type: .bullets,
                isPinned: true,
                tags: ["reflection", "goals"]
            ),
            Note(
                title: "Project Ideas",
                content: "## Main features\n- User authentication\n- Dashboard visualization\n- Export functionality\n\n## Questions to research\n- What tech stack is best suited?\n- Timeline estimates?\n- Required resources?",
                color: .purple,
                type: .markdown,
                isPinned: false,
                tags: ["work", "planning"]
            ),
            Note(
                title: "Random Thoughts",
                content: "Just a place to dump ideas without structure. Sometimes the best insights come when you're not trying to organize them.",
                color: .lightBlue,
                type: .basic,
                isPinned: false,
                tags: ["ideas"]
            )
        ]
    }
}

// MARK: - Color Extension for hex support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
