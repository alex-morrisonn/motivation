import Foundation
import SwiftUI
import Combine

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
    
    /// Autosave publisher for debouncing save operations
    private var saveSubject = PassthroughSubject<Void, Never>()
    private var autosaveCancellable: AnyCancellable?
    
    // MARK: - Private Properties
    
    /// UserDefaults keys
    private let notesKey = "savedNotes"
    private let backupNotesKey = "savedNotes_backup"
    private let corruptedDataKey = "savedNotes_corrupted"
    
    // MARK: - Error Types
    
    /// Error type for NoteService operations
    enum NoteServiceError: Error, LocalizedError {
        case failedToLoadNotes
        case failedToSaveNotes
        case invalidNote
        case noteNotFound
        case dataCorruption(String)
        
        var errorDescription: String? {
            switch self {
            case .failedToLoadNotes: return "Failed to load notes"
            case .failedToSaveNotes: return "Failed to save notes"
            case .invalidNote: return "Invalid note data"
            case .noteNotFound: return "Note not found"
            case .dataCorruption(let details): return "Data corruption: \(details)"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Load saved notes
        loadNotes()
        
        // Set up autosave debounce
        autosaveCancellable = saveSubject
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNotes()
            }
        
        // If no notes found, create sample notes for first-time users
        if notes.isEmpty {
            #if DEBUG
            // In debug mode, add sample notes
            notes = Note.samples
            saveNotes()
            #endif
        }
        
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    deinit {
        // Clean up notification observers
        NotificationCenter.default.removeObserver(self)
        
        // Clean up cancellables
        autosaveCancellable?.cancel()
    }
    
    // MARK: - Public Methods - CRUD
    
    /// Add a new note
    /// - Parameter note: The note to add
    func addNote(_ note: Note) {
        // Update the last edited date to now
        note.lastEditedDate = Date()
        
        notes.append(note)
        refreshTrigger = UUID() // Force UI update
        triggerAutosave()
    }
    
    /// Update an existing note
    /// - Parameter note: The note with updated properties
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            // Update the last edited date to now
            note.lastEditedDate = Date()
            
            notes[index] = note
            refreshTrigger = UUID() // Force UI update
            triggerAutosave()
        } else {
            print("Warning: Attempted to update non-existent note: \(note.id)")
        }
    }
    
    /// Delete a note
    /// - Parameter note: The note to delete
    func deleteNote(_ note: Note) {
        notes.removeAll(where: { $0.id == note.id })
        refreshTrigger = UUID() // Force UI update
        triggerAutosave()
    }
    
    /// Delete a note and its associated sketch data
    /// - Parameter note: The note to delete
    func deleteNoteWithSketch(_ note: Note) {
        // Delete any associated sketch data
        note.deleteSketch()
        
        // Delete the note itself
        deleteNote(note)
    }
    
    /// Toggle pinned status for a note
    /// - Parameter note: The note to toggle
    func togglePinned(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            notes[index].lastEditedDate = Date()
            refreshTrigger = UUID() // Force UI update
            triggerAutosave()
        } else {
            print("Warning: Attempted to toggle pinned status for non-existent note: \(note.id)")
        }
    }
    
    /// Format content based on note type
    /// - Parameters:
    ///   - content: The content to format
    ///   - type: The note type
    /// - Returns: Formatted content
    func formatContent(_ content: String, for type: Note.NoteType) -> String {
        switch type {
        case .bullets:
            // Ensure bullet points for new lines
            var lines = content.components(separatedBy: "\n")
            for i in 0..<lines.count {
                if !lines[i].isEmpty && !lines[i].hasPrefix("•") {
                    lines[i] = "• " + lines[i]
                }
            }
            return lines.joined(separator: "\n")
            
        case .markdown, .basic, .sketch:
            // No special formatting for these types
            return content
        }
    }
    
    /// Add a tag to a note
    /// - Parameters:
    ///   - tag: The tag to add
    ///   - note: The note to add the tag to
    func addTag(_ tag: String, to note: Note) {
        // Convert tag to lowercase and clean it
        let cleanedTag = tag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Only add if not empty and not already present
        if !cleanedTag.isEmpty && !note.tags.contains(cleanedTag) {
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                notes[index].tags.append(cleanedTag)
                notes[index].lastEditedDate = Date()
                refreshTrigger = UUID()
                triggerAutosave()
            }
        }
    }
    
    /// Remove a tag from a note
    /// - Parameters:
    ///   - tag: The tag to remove
    ///   - note: The note to remove the tag from
    func removeTag(_ tag: String, from note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].tags.removeAll(where: { $0 == tag })
            notes[index].lastEditedDate = Date()
            refreshTrigger = UUID()
            triggerAutosave()
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
    
    /// Create a new note with specified type
    /// - Parameter type: The type of note to create
    /// - Returns: A new note with appropriate default content
    func createNewNote(type: Note.NoteType = .basic) -> Note {
        let content: String
        
        switch type {
        case .basic:
            content = "Start typing your thoughts here..."
        case .bullets:
            content = "• Start typing your bullet points\n• Use • to create new bullets\n• Organize your thoughts in lists"
        case .markdown:
            content = "# Heading\n## Subheading\n\nStart writing with **markdown** formatting...\n\n- List item 1\n- List item 2\n\n> Blockquote"
        case .sketch:
            content = "Add notes about your sketch here...\n\nYou can switch between text and drawing using the toggle at the top."
        }
        
        return Note(
            title: "",
            content: content,
            color: .blue,
            type: type,
            isPinned: false,
            tags: []
        )
    }
    
    /// Delete all notes (with confirmation option in UI)
    func deleteAllNotes() {
        // Delete associated sketch data for all notes
        for note in notes {
            if note.type == .sketch {
                note.deleteSketch()
            }
        }
        
        notes.removeAll()
        saveNotes()
        refreshTrigger = UUID() // Force UI update
    }
    
    /// Export notes to a data format
    /// - Returns: Data object containing notes
    func exportNotes() -> Data? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(notes)
            return data
        } catch {
            print("Error exporting notes: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Import notes from data
    /// - Parameter data: Data containing encoded notes
    /// - Returns: Boolean indicating success
    func importNotes(from data: Data) -> Bool {
        do {
            let decodedNotes = try JSONDecoder().decode([Note].self, from: data)
            
            // Merge with existing notes - don't replace duplicates
            let existingIds = notes.map { $0.id }
            let newNotes = decodedNotes.filter { !existingIds.contains($0.id) }
            
            notes.append(contentsOf: newNotes)
            saveNotes()
            refreshTrigger = UUID() // Force UI update
            
            return true
        } catch {
            print("Error importing notes: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Save notes when app becomes inactive
    @objc private func appWillResignActive() {
        saveNotes()
    }
    
    /// Trigger autosave with debouncing
    public func triggerAutosave() {
        saveSubject.send(())
    }
    
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
        // Check if data is corrupted
        if isDataCorrupted() && isBackupAvailable() {
            print("Detected corrupted notes data, attempting to restore from backup")
            _ = restoreFromBackup()
            return
        }
        
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
    
    /// Check if data appears to be corrupted
    private func isDataCorrupted() -> Bool {
        if let savedData = UserDefaults.standard.data(forKey: notesKey) {
            do {
                // Try to decode the data
                _ = try JSONDecoder().decode([Note].self, from: savedData)
                return false // Successfully decoded, not corrupted
            } catch {
                return true // Failed to decode, likely corrupted
            }
        }
        
        return false // No data, so not corrupted
    }
    
    /// Check if backup is available
    private func isBackupAvailable() -> Bool {
        return UserDefaults.standard.data(forKey: backupNotesKey) != nil
    }
    
    /// Create a backup of notes data
    private func createBackup() {
        // Only backup if we have valid data
        if !notes.isEmpty {
            if let encoded = try? JSONEncoder().encode(notes) {
                UserDefaults.standard.set(encoded, forKey: backupNotesKey)
                // Add timestamp of backup
                UserDefaults.standard.set(Date(), forKey: "notes_backup_timestamp")
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
                    
                    // Save the recovered notes to the primary storage
                    do {
                        let encoded = try JSONEncoder().encode(notes)
                        UserDefaults.standard.set(encoded, forKey: notesKey)
                    } catch {
                        print("Warning: Failed to save recovered notes: \(error.localizedDescription)")
                    }
                    
                    return true
                }
            } catch {
                print("Backup restoration failed: \(error.localizedDescription)")
                
                // Store the corrupted backup for debugging
                if let backupData = UserDefaults.standard.data(forKey: backupNotesKey) {
                    UserDefaults.standard.set(backupData, forKey: corruptedDataKey)
                    print("Stored corrupted backup data for debugging")
                }
            }
        }
        return false
    }
    
    /// Attempt to save only valid notes
    private func attemptPartialSave() {
        // Filter out notes that have problems like empty required fields
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
            
            // Last resort: try to save individual notes
            var individualSavedNotes: [Note] = []
            
            for note in notes {
                do {
                    // Try to encode each note individually
                    _ = try JSONEncoder().encode(note)
                    individualSavedNotes.append(note)
                } catch {
                    print("Failed to encode note \(note.id): \(error.localizedDescription)")
                }
            }
            
            if !individualSavedNotes.isEmpty {
                notes = individualSavedNotes
                do {
                    let encoded = try JSONEncoder().encode(notes)
                    UserDefaults.standard.set(encoded, forKey: notesKey)
                    print("Saved \(individualSavedNotes.count) individual verified notes")
                } catch {
                    print("Failed to save even individually verified notes: \(error.localizedDescription)")
                }
            }
        }
    }
}
