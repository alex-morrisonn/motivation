import Foundation

/// Quote model representing an inspirational quote with text, author, and category
struct Quote: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier for the quote
    var id = UUID()
    
    /// The quote text content
    let text: String
    
    /// The author of the quote
    let author: String
    
    /// The category this quote belongs to
    let category: String
    
    // MARK: - Protocol Conformance
    
    /// Equatable implementation based on id
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Initializers
    
    /// Creates a quote from a SharedQuote instance
    /// - Parameter sharedQuote: The SharedQuote to convert
    init(from sharedQuote: SharedQuote) {
        self.id = sharedQuote.id
        self.text = sharedQuote.text
        self.author = sharedQuote.author
        self.category = sharedQuote.category
    }
    
    /// Creates a quote directly from text, author, and category
    /// - Parameters:
    ///   - text: The quote text
    ///   - author: The quote author
    ///   - category: The quote category
    init(text: String, author: String, category: String) {
        self.text = text
        self.author = author
        self.category = category
    }
    
    // MARK: - Helper Methods
    
    /// Formats the quote as a shareable text string
    /// - Returns: Formatted quote with author for sharing
    func formattedForSharing() -> String {
        return "\"\(text)\" — \(author)"
    }
    
    /// Checks if the quote contains the given search term
    /// - Parameter searchTerm: The text to search for
    /// - Returns: Boolean indicating if the quote contains the search term
    func contains(_ searchTerm: String) -> Bool {
        let lowercasedTerm = searchTerm.lowercased()
        return text.lowercased().contains(lowercasedTerm) ||
               author.lowercased().contains(lowercasedTerm) ||
               category.lowercased().contains(lowercasedTerm)
    }
    
    /// Returns a truncated version of the quote text
    /// - Parameter maxLength: Maximum length before truncation
    /// - Returns: Truncated text with ellipsis if needed
    func truncatedText(maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength - 3)) + "..."
    }
}

// MARK: - Extensions

extension Quote {
    /// Create a sample quote for previews and testing
    static var sample: Quote {
        Quote(
            text: "The best way to predict the future is to create it.",
            author: "Peter Drucker",
            category: "Success & Achievement"
        )
    }
    
    /// Create multiple sample quotes for previews and testing
    static var samples: [Quote] {
        [
            Quote(text: "The best way to predict the future is to create it.",
                  author: "Peter Drucker",
                  category: "Success & Achievement"),
            
            Quote(text: "Life is what happens when you're busy making other plans.",
                  author: "John Lennon",
                  category: "Life & Perspective"),
            
            Quote(text: "Believe you can and you're halfway there.",
                  author: "Theodore Roosevelt",
                  category: "Courage & Confidence")
        ]
    }
}
