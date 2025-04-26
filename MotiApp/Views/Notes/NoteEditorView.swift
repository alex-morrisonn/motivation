import SwiftUI
import Combine
import PencilKit

/// Redesigned Note Editor View with simplified controls and sketch support
struct NoteEditorView: View {
    // MARK: - Environment & Dependencies
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var noteService: NoteService
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - State Properties
    
    // Note properties
    @State private var noteTitle: String
    @State private var noteContent: String
    @State private var noteColor: Note.NoteColor
    @State private var noteType: Note.NoteType
    @State private var isPinned: Bool
    @State private var tags: [String]
    
    // UI state properties
    @State private var showingMoreOptions = false
    @State private var showingTagEditor = false
    @State private var showingDeleteAlert = false
    @State private var showingColorPalette = false
    @State private var showingSaveIndicator = false
    @State private var focusMode = false
    @FocusState private var isContentFocused: Bool
    @FocusState private var isTitleFocused: Bool
    
    // For easier tracking of existing note vs new note
    private let existingNoteId: UUID?
    private let isNewNote: Bool
    
    // Autosave handling
    private let autosaveSubject = PassthroughSubject<Void, Never>()
    @State private var autosaveCancellable: AnyCancellable?
    
    // MARK: - Initialization
    
    /// Initialize with an existing note
    init(note: Note) {
        _noteTitle = State(initialValue: note.title)
        _noteContent = State(initialValue: note.content)
        _noteColor = State(initialValue: note.color)
        _noteType = State(initialValue: note.type)
        _isPinned = State(initialValue: note.isPinned)
        _tags = State(initialValue: note.tags)
        
        self.existingNoteId = note.id
        self.isNewNote = false
    }
    
    /// Initialize for a new note
    init(isNewNote: Bool = true, initialType: Note.NoteType = .basic) {
        _noteTitle = State(initialValue: "")
        _noteContent = State(initialValue: "")
        _noteColor = State(initialValue: .blue)
        _noteType = State(initialValue: initialType)
        _isPinned = State(initialValue: false)
        _tags = State(initialValue: [])
        
        self.existingNoteId = nil
        self.isNewNote = true
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background color
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Title and content fields
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // Title field
                        TextField("Untitled Note", text: $noteTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .focused($isTitleFocused)
                            .padding(.top, 12)
                            .padding(.horizontal, 16)
                            .onChange(of: noteTitle) { oldValue, newValue in
                                triggerAutosave()
                            }
                        
                        // Note type indicator and date
                        HStack {
                            // Note type pill
                            HStack(spacing: 4) {
                                Image(systemName: noteType.iconName)
                                    .foregroundColor(noteColor.color)
                                    .font(.caption)
                                
                                Text(noteType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(noteColor.color.opacity(0.1))
                            .cornerRadius(8)
                            
                            Spacer()
                            
                            // Show save indicator when saved
                            if showingSaveIndicator {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    
                                    Text("Saved")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .transition(.opacity)
                            } else {
                                // Edit status
                                Text("Editing")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                            .padding(.horizontal, 16)
                        
                        // Content editor with support for sketches
                        updatedNoteContentEditor
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        // Tags section at bottom
                        tagsSection
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                        // Extra space at bottom for toolbar
                        Spacer(minLength: 60)
                    }
                }
                
                // Bottom toolbar overlay
                VStack {
                    Spacer()
                    
                    bottomToolbar
                }
            }
            
            // Color palette overlay (appears above the toolbar)
            if showingColorPalette {
                VStack {
                    Spacer()
                    
                    colorPaletteOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // More options overlay (appears above the toolbar)
            if showingMoreOptions {
                VStack {
                    Spacer()
                    
                    moreOptionsOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Save indicator popup (centered)
            if showingSaveIndicator {
                saveIndicator
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView(tags: $tags)
                .onDisappear {
                    triggerAutosave()
                }
        }
        .sheet(isPresented: $focusMode) {
            // Focus mode for distraction-free editing
            FocusModeView(
                noteContent: $noteContent,
                noteTitle: $noteTitle,
                noteType: noteType,
                noteColor: noteColor
            )
            .environmentObject(noteService)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Note"),
                message: Text("Are you sure you want to delete this note? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteNote()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            // Set up autosave
            setupAutosave()
            
            // Focus the title field for new notes, content for existing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if isNewNote && noteTitle.isEmpty {
                    isTitleFocused = true
                } else {
                    isContentFocused = true
                }
            }
        }
        .onDisappear {
            // Clean up on disappear
            autosaveCancellable?.cancel()
            saveNoteWithSketch()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Save when app moves to background
            if newPhase == .background {
                saveNoteWithSketch()
            }
        }
    }

    // MARK: - Components
    
    /// Content editor based on note type with sketch support
    @ViewBuilder
    var updatedNoteContentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content placeholder
            if noteContent.isEmpty && !isContentFocused && noteType != .sketch {
                Text(getPlaceholderText())
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                    .padding(.leading, 4)
                    .opacity(0.8)
            }
            
            // Different editors for different note types
            switch noteType {
            case .markdown:
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(minHeight: 300)
                    .focused($isContentFocused)
            case .bullets:
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(minHeight: 300)
                    .focused($isContentFocused)
            case .sketch:
                // Use the new SketchNoteView for sketch type notes
                // We need to bind to both text content and sketch data
                if let note = getNoteForId(existingNoteId) {
                    SketchNoteView(
                        textContent: $noteContent,
                        sketchData: Binding<Data?>(
                            get: { note.sketchData },
                            set: { note.sketchData = $0 }
                        )
                    )
                    .frame(minHeight: 400)
                } else {
                    // For new notes
                    SketchNoteView(
                        textContent: $noteContent,
                        sketchData: Binding<Data?>(
                            get: { UserDefaults.standard.data(forKey: "temp_sketch_data") },
                            set: {
                                if let data = $0 {
                                    UserDefaults.standard.set(data, forKey: "temp_sketch_data")
                                }
                            }
                        )
                    )
                    .frame(minHeight: 400)
                }
            case .basic:
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(minHeight: 300)
                    .focused($isContentFocused)
            }
        }
    }
    
    /// Tags section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !tags.isEmpty {
                Text("TAGS")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .tracking(1)
                
                // Flowing tag layout
                FlowingTags(tags: tags) { tag in
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                        
                        // Remove tag button
                        Button(action: {
                            withAnimation {
                                tags.removeAll { $0 == tag }
                                triggerAutosave()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    /// Bottom toolbar
    private var bottomToolbar: some View {
        ZStack {
            // Background blur and fill
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(height: 56)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1),
                    alignment: .top
                )
            
            // Toolbar buttons
            HStack(spacing: 0) {
                // Main action buttons (equally spaced)
                Group {
                    // Pin/Unpin button
                    toolbarButton(icon: isPinned ? "pin.fill" : "pin", color: isPinned ? .yellow : .white) {
                        withAnimation {
                            isPinned.toggle()
                            triggerAutosave()
                            showSavedFeedback()
                        }
                    }
                    
                    // Add tag button
                    toolbarButton(icon: "tag", color: .white) {
                        showingTagEditor = true
                    }
                    
                    // Change color button
                    toolbarButton(icon: "circle.fill", color: noteColor.color) {
                        withAnimation {
                            showingColorPalette.toggle()
                            showingMoreOptions = false
                        }
                    }
                    
                    // Focus mode button
                    toolbarButton(icon: "arrow.up.left.and.arrow.down.right", color: .white) {
                        saveNoteWithSketch()
                        focusMode = true
                    }
                    
                    // More options button
                    toolbarButton(icon: "ellipsis", color: .white) {
                        withAnimation {
                            showingMoreOptions.toggle()
                            showingColorPalette = false
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 56)
        }
    }
    
    /// Color palette overlay
    private var colorPaletteOverlay: some View {
        HStack(spacing: 16) {
            ForEach(Note.NoteColor.allCases) { color in
                Button(action: {
                    withAnimation {
                        noteColor = color
                        showingColorPalette = false
                        triggerAutosave()
                        showSavedFeedback()
                    }
                }) {
                    Circle()
                        .fill(color.color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: noteColor == color ? 2 : 0)
                        )
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 64) // Position above toolbar with adequate spacing
    }
    
    /// More options overlay
    private var moreOptionsOverlay: some View {
        VStack(spacing: 0) {
            // Change note type
            Button(action: {
                withAnimation {
                    // Cycle through note types
                    let types = Note.NoteType.allCases
                    if let currentIndex = types.firstIndex(of: noteType),
                       let nextType = types[safe: (currentIndex + 1) % types.count] {
                        noteType = nextType
                        triggerAutosave()
                        showSavedFeedback()
                    }
                    showingMoreOptions = false
                }
            }) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 24)
                    
                    Text("Change Note Type")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(noteType.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)
            
            // Word count
            HStack {
                Image(systemName: "text.word.count")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text("Word Count")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(countWords(noteContent)) words")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)
            
            // Share button
            Button(action: {
                // Share function
                showingMoreOptions = false
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 24)
                    
                    Text("Share Note")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)
            
            // Delete button
            Button(action: {
                showingMoreOptions = false
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Delete Note")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.bottom, 64) // Position above toolbar
    }
    
    /// Toolbar button component
    private func toolbarButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
    
    /// Save indicator popup
    private var saveIndicator: some View {
        Text("Saved")
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.3))
            )
    }
    
    // MARK: - Helper Methods
    
    /// Helper method to get a note by ID
    private func getNoteForId(_ id: UUID?) -> Note? {
        guard let id = id else { return nil }
        return noteService.notes.first { $0.id == id }
    }
    
    /// Set up autosave functionality
    private func setupAutosave() {
        autosaveCancellable = autosaveSubject
            .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
            .sink { _ in
                self.saveNoteWithSketch()
            }
    }
    
    /// Trigger autosave
    private func triggerAutosave() {
        autosaveSubject.send(())
    }
    
    /// Format time for display
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// Save the note with sketch support
    func saveNoteWithSketch() {
        guard !noteTitle.isEmpty || !noteContent.isEmpty else {
            // Don't save empty notes
            return
        }
        
        if let id = existingNoteId {
            // Update existing note - sketch data is already managed by the binding
            let updatedNote = Note(
                title: noteTitle,
                content: noteContent,
                color: noteColor,
                type: noteType,
                isPinned: isPinned,
                tags: tags
            )
            updatedNote.id = id
            
            // Update the note in service
            noteService.updateNote(updatedNote)
        } else {
            // Create new note
            let newNote = Note(
                title: noteTitle,
                content: noteContent,
                color: noteColor,
                type: noteType,
                isPinned: isPinned,
                tags: tags
            )
            
            // Save the note first to get an ID
            noteService.addNote(newNote)
            
            // Transfer any temporary sketch data to the permanent note storage
            if noteType == .sketch,
               let tempSketchData = UserDefaults.standard.data(forKey: "temp_sketch_data") {
                newNote.sketchData = tempSketchData
                
                // Clear the temporary data
                UserDefaults.standard.removeObject(forKey: "temp_sketch_data")
            }
        }
        
        // Show save indicator
        showSavedFeedback()
    }
    
    /// Save note to service (wrapper for backwards compatibility)
    private func saveNote() {
        saveNoteWithSketch()
    }
    
    /// Show save indicator feedback
    private func showSavedFeedback() {
        withAnimation {
            showingSaveIndicator = true
        }
        
        // Hide indicator after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingSaveIndicator = false
            }
        }
    }
    
    /// Delete note and any associated sketch data
    private func deleteNote() {
        if let id = existingNoteId {
            // Create a temporary note with the ID to delete
            let noteToDelete = Note()
            noteToDelete.id = id
            
            // Delete the note and its sketch data
            noteService.deleteNoteWithSketch(noteToDelete)
        }
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
    
    /// Handle content changes with special handling for bullet points
    private func handleContentChange(from oldValue: String, to newValue: String) {
        // For bullet lists, add bullet points automatically
        if noteType == .bullets {
            handleBulletPoints(from: oldValue, to: newValue)
        }
        
        triggerAutosave()
    }
    
    /// Special handling for bullet points
    private func handleBulletPoints(from oldValue: String, to newValue: String) {
        // Check if the user just pressed Enter
        if newValue.hasSuffix("\n") && !newValue.hasSuffix("\n\n") && oldValue != newValue {
            // Add a bullet point to the new line
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.noteContent = newValue + "• "
            }
        }
    }
    
    /// Get placeholder text based on note type
    private func getPlaceholderText() -> String {
        switch noteType {
        case .basic:
            return "Start typing your thoughts here..."
        case .bullets:
            return "• Start typing your bullet points"
        case .markdown:
            return "# Use markdown formatting\n\nStart writing here..."
        case .sketch:
            return "Add notes about your sketch here...\n\nYou can switch between text and drawing using the toggle at the top."
        }
    }
    
    /// Count words in text
    private func countWords(_ text: String) -> Int {
        return text.split(whereSeparator: { $0.isWhitespace }).count
    }
}
