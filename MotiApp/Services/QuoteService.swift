import Foundation
import SwiftUI

/// Service responsible for managing quotes, including retrieving, filtering, and handling favorites
class QuoteService: ObservableObject {
    // Singleton instance for app-wide access
    static let shared = QuoteService()
    
    // MARK: - Published Properties
    
    /// Collection of user's favorite quotes
    @Published var favorites: [Quote] = []
    
    // MARK: - Private Properties
    
    /// All available quotes loaded from SharedQuotes
    private let quotes: [Quote]
    
    /// UserDefaults keys
    private let favoritesKey = "savedFavorites"
    private let backupFavoritesKey = "savedFavorites_backup"
    private let corruptedDataKey = "savedFavorites_corrupted"
    
    // MARK: - Error Types
    
    /// Error type for QuoteService operations
    enum QuoteServiceError: Error, LocalizedError {
        case failedToLoadFavorites
        case failedToSaveFavorites
        case invalidQuote
        case quotesUnavailable
        case categoryNotFound
        
        var errorDescription: String? {
            switch self {
            case .failedToLoadFavorites: return "Failed to load favorites"
            case .failedToSaveFavorites: return "Failed to save favorites"
            case .invalidQuote: return "Invalid quote data"
            case .quotesUnavailable: return "Quotes are unavailable"
            case .categoryNotFound: return "Category not found"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Initialize quotes with error handling
        do {
            quotes = SharedQuotes.all.map { Quote(from: $0) }
            if quotes.isEmpty {
                print("Warning: No quotes loaded from SharedQuotes")
            }
        } catch {
            print("Error initializing quotes: \(error.localizedDescription)")
            quotes = [] // Initialize with empty array on error
        }
        
        // Load saved favorites
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    /// Get all unique categories of quotes
    /// - Returns: Sorted array of category names
    func getAllCategories() -> [String] {
        let categories = Set(quotes.map { $0.category })
        return Array(categories).sorted()
    }
    
    /// Get quotes filtered by category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of quotes in the specified category
    func getQuotes(forCategory category: String) -> [Quote] {
        guard !quotes.isEmpty else {
            print("Warning: Attempting to get quotes for category but quotes array is empty")
            return []
        }
        
        let filteredQuotes = quotes.filter { $0.category == category }
        
        if filteredQuotes.isEmpty {
            print("Warning: No quotes found for category: \(category)")
        }
        
        return filteredQuotes
    }
    
    /// Add a quote to favorites
    /// - Parameter quote: The quote to add to favorites
    func addToFavorites(_ quote: Quote) {
        // Validate quote
        guard !quote.text.isEmpty && !quote.author.isEmpty else {
            print("Warning: Attempted to add invalid quote to favorites")
            return
        }
        
        // Only add if not already in favorites
        if !favorites.contains(where: { $0.text == quote.text && $0.author == quote.author }) {
            favorites.append(quote)
            saveFavorites()
        }
    }
    
    /// Remove a quote from favorites
    /// - Parameter quote: The quote to remove from favorites
    func removeFromFavorites(_ quote: Quote) {
        let initialCount = favorites.count
        favorites.removeAll(where: { $0.text == quote.text && $0.author == quote.author })
        
        if favorites.count < initialCount {
            // Quote was found and removed
            saveFavorites()
        } else {
            print("Warning: Quote not found in favorites for removal")
        }
    }
    
    /// Check if a quote is in the user's favorites
    /// - Parameter quote: The quote to check
    /// - Returns: Boolean indicating if the quote is in favorites
    func isFavorite(_ quote: Quote) -> Bool {
        return favorites.contains(where: { $0.text == quote.text && $0.author == quote.author })
    }
    
    /// Get the quote for today based on date
    /// - Returns: A quote determined by today's date
    func getTodaysQuote() -> Quote {
        guard !quotes.isEmpty else {
            print("Error: No quotes available to get today's quote")
            return getFallbackQuote()
        }
        
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Use the day of the year to pick a quote
            guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) else {
                print("Warning: Could not determine day of year, using first quote")
                return quotes[0]
            }
            
            // Use modulo to ensure we always get a valid index
            let index = (dayOfYear - 1) % quotes.count
            return quotes[index]
        } catch {
            print("Error retrieving today's quote: \(error.localizedDescription)")
            return getFallbackQuote()
        }
    }
    
    /// Get a random quote
    /// - Returns: A randomly selected quote
    func getRandomQuote() -> Quote {
        guard !quotes.isEmpty else {
            print("Error: No quotes available to get random quote")
            return getFallbackQuote()
        }
        
        let randomIndex = Int.random(in: 0..<quotes.count)
        return quotes[randomIndex]
    }
    
    /// Get all available quotes
    /// - Returns: Array of all quotes
    func getAllQuotes() -> [Quote] {
        return quotes
    }
    
    /// Get a fallback quote when other methods fail
    /// - Returns: A simple fallback quote
    func getFallbackQuote() -> Quote {
        Quote(text: "There seems to be a problem loading today's quote.", author: "Try again later", category: "Error")
    }
    
    // MARK: - Private Methods
    
    /// Save favorites to UserDefaults with error handling
    private func saveFavorites() {
        do {
            let encoded = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        } catch {
            print("Error saving favorites: \(error.localizedDescription)")
            // Create a backup of what we can encode
            createFavoritesBackup()
        }
    }
    
    /// Create a backup of favorites in case of corruption
    private func createFavoritesBackup() {
        // Skip empty favorites
        if favorites.isEmpty {
            return
        }
        
        // Try to encode only the valid favorites
        var encodableFavorites: [Quote] = []
        
        for favorite in favorites {
            do {
                // Test if each favorite can be encoded individually
                let _ = try JSONEncoder().encode(favorite)
                encodableFavorites.append(favorite)
            } catch {
                print("Skipping non-encodable favorite: \(favorite.text)")
            }
        }
        
        // Save the backup if we have any valid favorites
        if !encodableFavorites.isEmpty {
            if let encoded = try? JSONEncoder().encode(encodableFavorites) {
                UserDefaults.standard.set(encoded, forKey: backupFavoritesKey)
                print("Successfully created backup with \(encodableFavorites.count) favorites")
            }
        }
    }
    
    /// Load favorites from UserDefaults with error handling
    private func loadFavorites() {
        if let savedFavorites = UserDefaults.standard.data(forKey: favoritesKey) {
            do {
                let decodedFavorites = try JSONDecoder().decode([Quote].self, from: savedFavorites)
                favorites = decodedFavorites
                print("Successfully loaded \(favorites.count) favorites")
            } catch {
                print("Error decoding favorites: \(error.localizedDescription)")
                // Attempt to recover by using any valid favorites or starting with empty array
                favorites = []
                
                // Try to recover corrupted data
                attemptFavoritesRecovery()
            }
        } else {
            favorites = [] // Default to empty array if no favorites found
            print("No saved favorites found")
        }
    }
    
    /// Attempt to recover corrupted favorites data
    private func attemptFavoritesRecovery() {
        print("Attempting to recover favorites data...")
        
        // First, try to load from backup if it exists
        if let backupData = UserDefaults.standard.data(forKey: backupFavoritesKey) {
            do {
                let recoveredFavorites = try JSONDecoder().decode([Quote].self, from: backupData)
                if !recoveredFavorites.isEmpty {
                    print("Recovered \(recoveredFavorites.count) favorites from backup")
                    favorites = recoveredFavorites
                    
                    // Save to main storage
                    saveFavorites()
                    return
                }
            } catch {
                print("Backup recovery failed: \(error.localizedDescription)")
            }
        }
        
        // If no backup or backup recovery failed, try to create a new backup
        if let savedFavorites = UserDefaults.standard.data(forKey: favoritesKey) {
            // Create a backup of corrupted data
            UserDefaults.standard.set(savedFavorites, forKey: corruptedDataKey)
            
            // Reset favorites
            favorites = []
            saveFavorites()
            
            print("Favorites reset due to data corruption. A backup was created at '\(corruptedDataKey)'")
        }
    }
}
