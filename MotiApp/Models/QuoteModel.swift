import Foundation

/// Quote model representing an inspirational quote with text, author, and category
struct Quote: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier for the quote
    let id: UUID
    
    /// The quote text content
    let text: String
    
    /// The author of the quote
    let author: String
    
    /// The category this quote belongs to
    let category: String
    
    // MARK: - Protocol Conformance
    
    /// Equatable implementation based on id
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
    init(id: UUID = UUID(), text: String, author: String, category: String) {
        self.id = id
        self.text = text
        self.author = author
        self.category = category
    }
}
