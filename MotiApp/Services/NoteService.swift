import Foundation
import SwiftUI

/// Service for managing notes with persistence and CRUD operations
class NoteService: ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance for app-wide access
    static let shared = NoteService()
    
    // MARK: - Published Properties
    
    /// Collection of all notes
    @Published var notes: [Note] = []
    
    /// Refresh trigger to force UI updates
    @Published var refreshTrigger = UUID()
    
    // MARK: - Private Properties
    
    /// UserDefaults keys
    private let notesKey = "savedNotes"
    private let backupNotesKey = "savedNotes_backup"
    
    // MARK: - Error Types
    
    /// Error type for NoteService operations
    enum NoteServiceError: Error, LocalizedError {
        case failedToLoadNotes
        case failedToSaveNotes
        case invalidNote
        case noteNotFound
        
        var errorDescription: String? {
            switch self {
            case .failedToLoadNotes: return "Failed to load notes"
            case .failedToSaveNotes: return "Failed to save notes"
            case .invalidNote: return "Invalid note data"
            case .noteNotFound: return "Note not found"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved notes
        loadNotes()
        
        // If no notes found, create sample notes for first-time users
        if notes.isEmpty {
            #if DEBUG
            // In debug mode, add sample notes
            notes = Note.samples
            saveNotes()
            #endif
        }
    }
    
    // MARK: - Public Methods - CRUD
    
    /// Add a new note
    /// - Parameter note: The note to add
    func addNote(_ note: Note) {
        // Update the last edited date to now
        note.lastEditedDate = Date()
        
        notes.append(note)
        refreshTrigger = UUID() // Force UI update
        saveNotes()
    }
    
    /// Update an existing note
    /// - Parameter note: The note with updated properties
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            // Update the last edited date to now
            note.lastEditedDate = Date()
            
            notes[index] = note
            refreshTrigger = UUID() // Force UI update
            saveNotes()
        } else {
            print("Warning: Attempted to update non-existent note: \(note.id)")
        }
    }
    
    /// Delete a note
    /// - Parameter note: The note to delete
    func deleteNote(_ note: Note) {
        notes.removeAll(where: { $0.id == note.id })
        refreshTrigger = UUID() // Force UI update
        saveNotes()
    }
    
    /// Toggle pinned status for a note
    /// - Parameter note: The note to toggle
    func togglePinned(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            refreshTrigger = UUID() // Force UI update
            saveNotes()
        } else {
            print("Warning: Attempted to toggle pinned status for non-existent note: \(note.id)")
        }
    }
    
    // MARK: - Public Methods - Queries
    
    /// Get pinned notes sorted by last edited date
    /// - Returns: Array of pinned notes
    func getPinnedNotes() -> [Note] {
        return notes
            .filter { $0.isPinned }
            .sorted(by: { $0.lastEditedDate > $1.lastEditedDate })
    }
    
    /// Get unpinned notes sorted by last edited date
    /// - Returns: Array of unpinned notes
    func getUnpinnedNotes() -> [Note] {
        return notes
            .filter { !$0.isPinned }
            .sorted(by: { $0.lastEditedDate > $1.lastEditedDate })
    }
    
    /// Get all notes with a specific tag
    /// - Parameter tag: The tag to filter by
    /// - Returns: Array of notes with the specified tag
    func getNotesByTag(_ tag: String) -> [Note] {
        return notes
            .filter { $0.tags.contains(tag) }
            .sorted(by: { $0.lastEditedDate > $1.lastEditedDate })
    }
    
    /// Get all notes matching a search term
    /// - Parameter searchTerm: The term to search for in title and content
    /// - Returns: Array of matching notes
    func searchNotes(_ searchTerm: String) -> [Note] {
        guard !searchTerm.isEmpty else {
            return notes.sorted(by: { $0.lastEditedDate > $1.lastEditedDate })
        }
        
        let lowercasedTerm = searchTerm.lowercased()
        return notes
            .filter {
                $0.title.lowercased().contains(lowercasedTerm) ||
                $0.content.lowercased().contains(lowercasedTerm) ||
                $0.tags.contains(where: { $0.lowercased().contains(lowercasedTerm) })
            }
            .sorted(by: { $0.lastEditedDate > $1.lastEditedDate })
    }
    
    /// Get all unique tags used across notes
    /// - Returns: Array of unique tags
    func getAllTags() -> [String] {
        var allTags = Set<String>()
        for note in notes {
            for tag in note.tags {
                allTags.insert(tag)
            }
        }
        return Array(allTags).sorted()
    }
    
    // MARK: - Private Methods
    
    /// Save notes to UserDefaults with error handling
    private func saveNotes() {
        do {
            // Create backup before saving
            createBackup()
            
            let encoded = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(encoded, forKey: notesKey)
            
            print("Successfully saved \(notes.count) notes")
        } catch {
            print("Error saving notes: \(error.localizedDescription)")
            // Try to recover by saving valid notes
            attemptPartialSave()
        }
    }
    
    /// Load notes from UserDefaults with error handling
    private func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: notesKey) {
            do {
                let decodedNotes = try JSONDecoder().decode([Note].self, from: savedNotes)
                notes = decodedNotes
                print("Successfully loaded \(notes.count) notes")
            } catch {
                print("Error decoding notes: \(error.localizedDescription)")
                // Attempt to recover from backup
                if !restoreFromBackup() {
                    // If recovery fails, start with empty array
                    notes = []
                }
            }
        } else {
            notes = [] // Default to empty array if no notes found
            print("No saved notes found")
        }
    }
    
    /// Create a backup of notes data
    private func createBackup() {
        // Only backup if we have valid data
        if !notes.isEmpty {
            if let encoded = try? JSONEncoder().encode(notes) {
                UserDefaults.standard.set(encoded, forKey: backupNotesKey)
                print("Notes backup created")
            }
        }
    }
    
    /// Restore from backup if available
    /// - Returns: Boolean indicating if restore was successful
    private func restoreFromBackup() -> Bool {
        if let backupData = UserDefaults.standard.data(forKey: backupNotesKey) {
            do {
                let recoveredNotes = try JSONDecoder().decode([Note].self, from: backupData)
                if !recoveredNotes.isEmpty {
                    print("Recovered \(recoveredNotes.count) notes from backup")
                    notes = recoveredNotes
                    return true
                }
            } catch {
                print("Backup restoration failed: \(error.localizedDescription)")
            }
        }
        return false
    }
    
    /// Attempt to save only valid notes
    private func attemptPartialSave() {
        let validNotes = notes.filter { !$0.title.isEmpty || !$0.content.isEmpty }
        
        if validNotes.count < notes.count {
            print("Attempting to save \(validNotes.count) valid notes out of \(notes.count) total")
            notes = validNotes
        }
        
        do {
            let encoded = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(encoded, forKey: notesKey)
            print("Partial save successful")
        } catch {
            print("Partial save also failed: \(error.localizedDescription)")
        }
    }
}
