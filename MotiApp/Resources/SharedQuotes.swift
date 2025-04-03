import Foundation

/// A shared quote model that works across the main app and widget extension
///
/// This model is designed to be compatible with both the main app and widget extension,
/// allowing quotes to be shared between both targets.
public struct SharedQuote: Identifiable, Codable, Equatable {
    /// Unique identifier for the quote
    public var id = UUID()
    
    /// The text content of the quote
    public let text: String
    
    /// The author of the quote
    public let author: String
    
    /// The category the quote belongs to
    public let category: String
    
    /// Equality comparison
    public static func == (lhs: SharedQuote, rhs: SharedQuote) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Creates a new quote
    /// - Parameters:
    ///   - text: The quote text
    ///   - author: The quote author
    ///   - category: The category the quote belongs to
    public init(text: String, author: String, category: String) {
        self.text = text
        self.author = author
        self.category = category
    }
}

/// Repository of all motivational quotes used in the app
///
/// Provides a central repository of quotes organized by category
/// that can be accessed by both the main app and widget extension.
public struct SharedQuotes {
    
    // MARK: - Categories
    
    /// All available categories in the quotes collection
    public static var categories: [String] {
        let categorySet = Set(all.map { $0.category })
        return Array(categorySet).sorted()
    }
    
    /// Get quotes for a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of quotes in the specified category
    public static func quotesForCategory(_ category: String) -> [SharedQuote] {
        return all.filter { $0.category == category }
    }
    
    // MARK: - Quote Collection
    
    /// Complete collection of all motivational quotes
    public static let all: [SharedQuote] = [
        // MARK: Success & Achievement
        SharedQuote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Success & Achievement"),
        SharedQuote(text: "Success is not final, failure is not fatal: It is the courage to continue that counts.", author: "Winston Churchill", category: "Success & Achievement"),
        SharedQuote(text: "It always seems impossible until it's done.", author: "Nelson Mandela", category: "Success & Achievement"),
        SharedQuote(text: "The only place where success comes before work is in the dictionary.", author: "Vidal Sassoon", category: "Success & Achievement"),
        SharedQuote(text: "There is no elevator to success. You have to take the stairs.", author: "Zig Ziglar", category: "Success & Achievement"),
        SharedQuote(text: "The best way to predict the future is to create it.", author: "Peter Drucker", category: "Success & Achievement"),
        
        // MARK: Life & Perspective
        SharedQuote(text: "Life is what happens when you're busy making other plans.", author: "John Lennon", category: "Life & Perspective"),
        SharedQuote(text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs", category: "Life & Perspective"),
        SharedQuote(text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein", category: "Life & Perspective"),
        SharedQuote(text: "Life is 10% what happens to us and 90% how we react to it.", author: "Charles R. Swindoll", category: "Life & Perspective"),
        SharedQuote(text: "The purpose of our lives is to be happy.", author: "Dalai Lama", category: "Life & Perspective"),
        SharedQuote(text: "Don't count the days, make the days count.", author: "Muhammad Ali", category: "Life & Perspective"),
        SharedQuote(text: "Life is either a daring adventure or nothing at all.", author: "Helen Keller", category: "Life & Perspective"),
        SharedQuote(text: "Don't let yesterday take up too much of today.", author: "Will Rogers", category: "Life & Perspective"),
        SharedQuote(text: "The most wasted of days is one without laughter.", author: "E.E. Cummings", category: "Life & Perspective"),
        SharedQuote(text: "If you want to live a happy life, tie it to a goal, not to people or things.", author: "Albert Einstein", category: "Life & Perspective"),
        
        // MARK: Dreams & Goals
        SharedQuote(text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", category: "Dreams & Goals"),
        SharedQuote(text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis", category: "Dreams & Goals"),
        SharedQuote(text: "All our dreams can come true if we have the courage to pursue them.", author: "Walt Disney", category: "Dreams & Goals"),
        SharedQuote(text: "When you have a dream, you've got to grab it and never let go.", author: "Carol Burnett", category: "Dreams & Goals"),
        SharedQuote(text: "Never give up on a dream just because of the time it will take to accomplish it. The time will pass anyway.", author: "Earl Nightingale", category: "Dreams & Goals"),
        
        // MARK: Courage & Confidence
        SharedQuote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Courage & Confidence"),
        SharedQuote(text: "The only limit to our realization of tomorrow will be our doubts of today.", author: "Franklin D. Roosevelt", category: "Courage & Confidence"),
        SharedQuote(text: "Believe in yourself and all that you are. Know that there is something inside you that is greater than any obstacle.", author: "Christian D. Larson", category: "Courage & Confidence"),
        SharedQuote(text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair", category: "Courage & Confidence"),
        SharedQuote(text: "What we fear doing most is usually what we most need to do.", author: "Tim Ferriss", category: "Courage & Confidence"),
        SharedQuote(text: "The question isn't who is going to let me; it's who is going to stop me.", author: "Ayn Rand", category: "Courage & Confidence"),
        SharedQuote(text: "The only way to achieve the impossible is to believe it is possible.", author: "Charles Kingsleigh", category: "Courage & Confidence"),
        
        // MARK: Perseverance & Resilience
        SharedQuote(text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius", category: "Perseverance & Resilience"),
        SharedQuote(text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela", category: "Perseverance & Resilience"),
        SharedQuote(text: "I have not failed. I've just found 10,000 ways that won't work.", author: "Thomas Edison", category: "Perseverance & Resilience"),
        SharedQuote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson", category: "Perseverance & Resilience"),
        SharedQuote(text: "The harder the conflict, the greater the triumph.", author: "George Washington", category: "Perseverance & Resilience"),
        SharedQuote(text: "If you're going through hell, keep going.", author: "Winston Churchill", category: "Perseverance & Resilience"),
        SharedQuote(text: "We may encounter many defeats but we must not be defeated.", author: "Maya Angelou", category: "Perseverance & Resilience"),
        SharedQuote(text: "Tough times never last, but tough people do.", author: "Robert H. Schuller", category: "Perseverance & Resilience"),
        SharedQuote(text: "Hardships often prepare ordinary people for an extraordinary destiny.", author: "C.S. Lewis", category: "Perseverance & Resilience"),
        SharedQuote(text: "When everything seems to be going against you, remember that the airplane takes off against the wind, not with it.", author: "Henry Ford", category: "Perseverance & Resilience"),
        
        // MARK: Growth & Change
        SharedQuote(text: "Be the change that you wish to see in the world.", author: "Mahatma Gandhi", category: "Growth & Change"),
        SharedQuote(text: "What you get by achieving your goals is not as important as what you become by achieving your goals.", author: "Zig Ziglar", category: "Growth & Change"),
        SharedQuote(text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson", category: "Growth & Change"),
        SharedQuote(text: "Every moment is a fresh beginning.", author: "T.S. Eliot", category: "Growth & Change"),
        SharedQuote(text: "Your time is now. Start where you are and never stop.", author: "Roy Bennett", category: "Growth & Change"),
        SharedQuote(text: "Challenges are what make life interesting and overcoming them is what makes life meaningful.", author: "Joshua J. Marine", category: "Growth & Change"),
        SharedQuote(text: "The difference between ordinary and extraordinary is that little extra.", author: "Jimmy Johnson", category: "Growth & Change"),
        SharedQuote(text: "Don't judge each day by the harvest you reap but by the seeds that you plant.", author: "Robert Louis Stevenson", category: "Growth & Change"),
        
        // MARK: Action & Determination
        SharedQuote(text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney", category: "Action & Determination"),
        SharedQuote(text: "The journey of a thousand miles begins with one step.", author: "Lao Tzu", category: "Action & Determination"),
        SharedQuote(text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky", category: "Action & Determination"),
        SharedQuote(text: "The secret of getting ahead is getting started.", author: "Mark Twain", category: "Action & Determination"),
        SharedQuote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt", category: "Action & Determination"),
        SharedQuote(text: "The future depends on what you do today.", author: "Mahatma Gandhi", category: "Action & Determination"),
        SharedQuote(text: "If opportunity doesn't knock, build a door.", author: "Milton Berle", category: "Action & Determination"),
        
        // MARK: Mindset & Attitude
        SharedQuote(text: "Whether you think you can or you think you can't, you're right.", author: "Henry Ford", category: "Mindset & Attitude"),
        SharedQuote(text: "Start each day with a positive thought and a grateful heart.", author: "Roy T. Bennett", category: "Mindset & Attitude"),
        SharedQuote(text: "The pessimist sees difficulty in every opportunity. The optimist sees opportunity in every difficulty.", author: "Winston Churchill", category: "Mindset & Attitude"),
        SharedQuote(text: "Success is not the key to happiness. Happiness is the key to success.", author: "Albert Schweitzer", category: "Mindset & Attitude"),
        SharedQuote(text: "Your attitude, not your aptitude, will determine your altitude.", author: "Zig Ziglar", category: "Mindset & Attitude"),
        SharedQuote(text: "The mind is everything. What you think you become.", author: "Buddha", category: "Mindset & Attitude"),
        SharedQuote(text: "Keep your face always toward the sunshine, and shadows will fall behind you.", author: "Walt Whitman", category: "Mindset & Attitude"),
        
        // MARK: Focus & Discipline
        SharedQuote(text: "The successful warrior is the average person, with laser-like focus.", author: "Bruce Lee", category: "Focus & Discipline"),
        SharedQuote(text: "You have within you right now, everything you need to deal with whatever the world can throw at you.", author: "Brian Tracy", category: "Focus & Discipline"),
        SharedQuote(text: "The harder you work for something, the greater you'll feel when you achieve it.", author: "Anonymous", category: "Focus & Discipline"),
        SharedQuote(text: "Motivation is what gets you started. Habit is what keeps you going.", author: "Jim Ryun", category: "Focus & Discipline"),
        SharedQuote(text: "Every strike brings me closer to the next home run.", author: "Babe Ruth", category: "Focus & Discipline"),
        SharedQuote(text: "Act as if what you do makes a difference. It does.", author: "William James", category: "Focus & Discipline")
    ]
    
    // MARK: - Utility Methods
    
    /// Returns a random quote from the collection
    /// - Returns: A random quote
    public static func randomQuote() -> SharedQuote {
        guard !all.isEmpty else {
            return SharedQuote(text: "No quotes available", author: "System", category: "Error")
        }
        return all.randomElement()!
    }
    
    /// Returns a quote based on the day of the year (same quote each day)
    /// - Returns: A quote determined by the current date
    public static func quoteOfTheDay() -> SharedQuote {
        guard !all.isEmpty else {
            return SharedQuote(text: "No quotes available", author: "System", category: "Error")
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use the day of the year to pick a quote
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) else {
            return all[0]
        }
        
        // Use modulo to ensure we always get a valid index
        let index = (dayOfYear - 1) % all.count
        return all[index]
    }
    
    /// Returns the count of quotes in each category
    /// - Returns: Dictionary mapping category names to quote counts
    public static func quotesCountByCategory() -> [String: Int] {
        var countByCategory: [String: Int] = [:]
        
        for category in categories {
            let count = quotesForCategory(category).count
            countByCategory[category] = count
        }
        
        return countByCategory
    }
}
