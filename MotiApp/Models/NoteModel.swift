import Foundation
import SwiftUI

/// Note model for storing user's notes and thoughts
class Note: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    // Unique identifier for the note
    var id = UUID()
    
    // Note content properties
    var title: String
    var content: String
    var color: NoteColor
    var type: NoteType
    var isPinned: Bool
    var lastEditedDate: Date
    var createdDate: Date  // New: track creation date separately
    var tags: [String]
    
    // Optional properties
    var isFavorite: Bool = false
    var wordCount: Int = 0  // Cached word count
    var characterCount: Int = 0  // Cached character count
    var excerptText: String?  // Optional excerpt for quick views
    
    // MARK: - Type Definitions
    
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
        
        var description: String {
            switch self {
            case .basic: return "Simple text notes"
            case .bullets: return "Bulleted lists and outlines"
            case .markdown: return "Rich text with formatting"
            case .sketch: return "Visual structures and sketches"
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
        
        // Name for UI display
        var displayName: String {
            switch self {
            case .blue: return "Blue"
            case .purple: return "Purple"
            case .lightBlue: return "Light Blue"
            case .orange: return "Orange"
            case .green: return "Green"
            case .red: return "Red"
            }
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, color, type, isPinned, lastEditedDate, tags, isFavorite, createdDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        color = try container.decode(NoteColor.self, forKey: .color)
        type = try container.decode(NoteType.self, forKey: .type)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        lastEditedDate = try container.decode(Date.self, forKey: .lastEditedDate)
        tags = try container.decode([String].self, forKey: .tags)
        
        // Optional properties with fallbacks
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate) ?? lastEditedDate
        
        // Calculate counts
        updateCounts()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(color, forKey: .color)
        try container.encode(type, forKey: .type)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(lastEditedDate, forKey: .lastEditedDate)
        try container.encode(tags, forKey: .tags)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(createdDate, forKey: .createdDate)
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
        self.createdDate = Date()  // New note creation time
        self.tags = tags
        
        // Update counts
        updateCounts()
    }
    
    // MARK: - Helper Methods
    
    /// Returns formatted string for last edited date
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastEditedDate, relativeTo: Date())
    }
    
    /// Returns a formatted creation date string
    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdDate)
    }
    
    /// Returns the time since creation
    var daysSinceCreation: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: createdDate, to: Date()).day ?? 0
    }
    
    /// Returns a preview of the content (first few characters)
    func getContentPreview(maxLength: Int = 100) -> String {
        // Used cached excerpt if available
        if let excerpt = excerptText {
            return excerpt
        }
        
        // Remove any markdown syntax for cleaner preview
        var previewText = content
        
        // Strip markdown headings
        previewText = previewText.replacingOccurrences(of: #"#{1,6}\s"#, with: "", options: .regularExpression)
        
        // Strip markdown formatting (bold, italic)
        previewText = previewText.replacingOccurrences(of: #"[*_]{1,2}(.*?)[*_]{1,2}"#, with: "$1", options: .regularExpression)
        
        // Strip brackets and parentheses used in markdown links
        previewText = previewText.replacingOccurrences(of: #"\[(.*?)\]\(.*?\)"#, with: "$1", options: .regularExpression)
        
        // Cleanup bullet points
        // Process line by line to strip bullet points
        let lines = previewText.components(separatedBy: .newlines)
        let processedLines = lines.map { line in
            return line.replacingOccurrences(
                of: "^\\s*[-*•]\\s*",
                with: "",
                options: .regularExpression
            )
        }
        previewText = processedLines.joined(separator: "\n")
        
        if previewText.count <= maxLength {
            return previewText
        }
        
        // Try to end the preview at a space or punctuation
        let endIndex = min(maxLength - 3, previewText.count - 1)
        if let index = previewText.indices.first(where: { $0.utf16Offset(in: previewText) >= endIndex && (previewText[$0] == " " || ".,:;!?".contains(previewText[$0])) }) {
            return String(previewText[..<index]) + "..."
        }
        
        return String(previewText.prefix(maxLength - 3)) + "..."
    }
    
    /// Update word and character counts
    func updateCounts() {
        // Word count - split by whitespace
        wordCount = content.split(whereSeparator: { $0.isWhitespace }).count
        
        // Character count - exclude whitespace
        characterCount = content.count
        
        // Generate excerpt for preview if needed
        if excerptText == nil {
            excerptText = getContentPreview(maxLength: 150)
        }
    }
    
    /// Calculate reading time in minutes
    var estimatedReadingTime: Int {
        // Average reading speed: 200 words per minute
        let readingSpeed = 200
        return max(1, Int(ceil(Double(wordCount) / Double(readingSpeed))))
    }
    
    /// Check if the note contains a search term
    func containsSearchTerm(_ term: String) -> Bool {
        let lowercasedTerm = term.lowercased()
        
        return title.lowercased().contains(lowercasedTerm) ||
               content.lowercased().contains(lowercasedTerm) ||
               tags.contains { $0.lowercased().contains(lowercasedTerm) }
    }
    
    /// Export the note as clean text (removing formatting)
    func exportAsText() -> String {
        var exportText = title.isEmpty ? "Untitled Note" : title
        exportText += "\n\n"
        exportText += content
        
        // Add tags as footer
        if !tags.isEmpty {
            exportText += "\n\n"
            exportText += tags.map { "#\($0)" }.joined(separator: " ")
        }
        
        return exportText
    }
    
    /// Export the note as HTML (preserving formatting)
    func exportAsHTML() -> String {
        // Simple HTML conversion - a real implementation would use a proper markdown parser
        
        let bodyContent: String
        
        switch type {
        case .markdown:
            // Very basic markdown to HTML conversion
            let lines = content.split(separator: "\n")
            let htmlLines = lines.map { line -> String in
                let lineStr = String(line)
                
                if lineStr.hasPrefix("# ") {
                    return "<h1>\(lineStr.dropFirst(2))</h1>"
                } else if lineStr.hasPrefix("## ") {
                    return "<h2>\(lineStr.dropFirst(3))</h2>"
                } else if lineStr.hasPrefix("### ") {
                    return "<h3>\(lineStr.dropFirst(4))</h3>"
                } else if lineStr.hasPrefix("- ") || lineStr.hasPrefix("* ") {
                    return "<li>\(lineStr.dropFirst(2))</li>"
                } else if lineStr.hasPrefix(">") {
                    return "<blockquote>\(lineStr.dropFirst(1).trimmingCharacters(in: .whitespaces))</blockquote>"
                } else if lineStr.isEmpty {
                    return "<br>"
                } else {
                    return "<p>\(lineStr)</p>"
                }
            }
            
            bodyContent = htmlLines.joined(separator: "\n")
            
        case .bullets:
            // Convert bullet points to HTML lists
            let lines = content.split(separator: "\n")
            var htmlContent = "<ul>\n"
            
            for line in lines {
                let lineStr = String(line).trimmingCharacters(in: .whitespaces)
                if lineStr.hasPrefix("•") {
                    htmlContent += "<li>\(lineStr.dropFirst(1).trimmingCharacters(in: .whitespaces))</li>\n"
                } else if !lineStr.isEmpty {
                    htmlContent += "<li>\(lineStr)</li>\n"
                }
            }
            
            htmlContent += "</ul>"
            bodyContent = htmlContent
            
        default:
            // Basic text with paragraphs
            bodyContent = "<p>" + content.replacingOccurrences(of: "\n\n", with: "</p><p>")
                .replacingOccurrences(of: "\n", with: "<br>") + "</p>"
        }
        
        // Construct complete HTML
        let htmlHead = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>\(title.isEmpty ? "Untitled Note" : title)</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; line-height: 1.5; max-width: 800px; margin: 0 auto; padding: 20px; }
                h1, h2, h3 { color: #333; }
                blockquote { border-left: 3px solid #ccc; padding-left: 15px; color: #666; }
                .tags { margin-top: 30px; color: #0066cc; }
            </style>
        </head>
        <body>
            <h1>\(title.isEmpty ? "Untitled Note" : title)</h1>
        """
        
        let tagsHTML = !tags.isEmpty
            ? "<div class=\"tags\">" + tags.map { "#\($0)" }.joined(separator: " ") + "</div>"
            : ""
        
        let htmlFooter = """
            <div class="meta">
                <p><small>Created: \(formattedCreationDate)</small></p>
                <p><small>Last edited: \(formattedDate)</small></p>
            </div>
            \(tagsHTML)
        </body>
        </html>
        """
        
        return htmlHead + bodyContent + htmlFooter
    }
    
    // MARK: - Factory Methods
    
    /// Create a sample note for previews and testing
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
            ),
            Note(
                title: "App Architecture",
                content: "User Interface\n    |\n    v\nView Controllers ---> Models\n    |                   |\n    v                   v\nNetwork Layer <---> Database\n\nNotes:\n- Use MVVM pattern\n- Core Data for persistence\n- Firebase for sync",
                color: .green,
                type: .sketch,
                isPinned: true,
                tags: ["technical", "diagram"]
            ),
            Note(
                title: "Reading Notes",
                content: "# Atomic Habits\n\n## Key Takeaways\n\n- **Small changes add up**: 1% better every day compounds to big results\n- **Identity-based habits**: Focus on who you want to become\n- **Environment design**: Make good habits obvious and bad habits invisible\n- **The 2-minute rule**: Scale habits down to 2-minute versions\n\n## Action Items\n\n- Set up environment for writing each morning\n- Create a habit tracker\n- Stack new habits with existing ones",
                color: .orange,
                type: .markdown,
                isPinned: false,
                tags: ["books", "productivity"]
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
