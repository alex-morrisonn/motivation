import SwiftUI
import Combine

/// Redesigned Note Editor View with simplified controls and improved UI
struct NoteEditorView: View {
    // MARK: - Environment & Dependencies
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var noteService: NoteService
    
    // MARK: - State Properties
    
    // Note properties
    @State private var noteTitle: String
    @State private var noteContent: String
    @State private var noteColor: Note.NoteColor
    @State private var noteType: Note.NoteType
    @State private var isPinned: Bool
    @State private var tags: [String]
    @State private var sketchData: Data?
    
    // UI state properties
    @State private var showingTagEditor = false
    @State private var showingDeleteAlert = false
    @State private var showingColorPicker = false
    @State private var showingToolbar = true
    @State private var showingSaveIndicator = false
    @State private var isEditingTitle = false
    @State private var isSettingsExpanded = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isContentFocused: Bool
    
    // For tracking the existing note vs new note
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
        _sketchData = State(initialValue: note.sketchData)
        
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
        _sketchData = State(initialValue: nil)
        
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
                // Title area with a tap gesture to edit
                if !isEditingTitle {
                    HStack {
                        Text(noteTitle.isEmpty ? "Untitled Note" : noteTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 12)
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                isEditingTitle = true
                                isTitleFocused = true
                            }
                        
                        Spacer()
                        
                        // Pin button
                        Button(action: {
                            withAnimation {
                                isPinned.toggle()
                                triggerAutosave()
                                showSavedFeedback()
                            }
                        }) {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .foregroundColor(isPinned ? .yellow : .white)
                                .padding(8)
                                .contentShape(Rectangle())
                        }
                        .padding(.trailing, 8)
                    }
                } else {
                    // Editable title field
                    TextField("Untitled Note", text: $noteTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                        .focused($isTitleFocused)
                        .onSubmit {
                            isEditingTitle = false
                            triggerAutosave()
                        }
                }
                
                // Note type and date indicator
                HStack {
                    // Note type pill
                    HStack(spacing: 4) {
                        Image(systemName: noteType == .sketch ? "scribble" : "doc.text")
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
                    
                    // Save indicator / Edit status
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
                
                // Main content area (text or sketch)
                if noteType == .sketch {
                    SketchNoteView(
                        textContent: $noteContent,
                        sketchData: $sketchData
                    )
                    .padding(.horizontal, 8)
                } else {
                    ScrollView {
                        VStack {
                            // Content editor with appropriate styling
                            TextEditor(text: $noteContent)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(minHeight: 300)
                                .focused($isContentFocused)
                                .padding(.horizontal, 8)
                                .onChange(of: noteContent) { oldValue, newValue in
                                    handleContentChange(from: oldValue, to: newValue)
                                }
                                .overlay(
                                    // Placeholder text when content is empty
                                    Group {
                                        if noteContent.isEmpty && !isContentFocused {
                                            HStack {
                                                Text(getPlaceholderText())
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 4)
                                                Spacer()
                                            }
                                            .padding(.top, 8)
                                            .padding(.leading, 16)
                                        }
                                    }
                                )
                            
                            // Tags section
                            tagsSection
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                        }
                        .padding(.bottom, 80)  // Space for toolbar
                    }
                }
                
                Spacer()
                
                // Bottom toolbar
                if showingToolbar {
                    bottomToolbar
                }
            }
            
            // Color picker overlay - appears when color picker is active
            if showingColorPicker {
                VStack {
                    Spacer()
                    colorPickerOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .background(Color.black.opacity(0.3))
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showingColorPicker = false
                    }
                }
            }
            
            // Expanded settings overlay - appears when more button is pressed
            if isSettingsExpanded {
                VStack {
                    Spacer()
                    settingsOverlay
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .background(Color.black.opacity(0.3))
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isSettingsExpanded = false
                    }
                }
            }
            
            // Save indicator popup (centered)
            if showingSaveIndicator {
                VStack {
                    Spacer()
                    
                    Text("Saved")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.green.opacity(0.3)))
                        .padding(.bottom, 16)
                }
                .transition(.opacity)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView(tags: $tags)
                .onDisappear {
                    triggerAutosave()
                }
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Done button - only for new notes in sheet presentation
                    if isNewNote {
                        Button("Done") {
                            saveNote()
                            presentationMode.wrappedValue.dismiss()
                        }
                        .fontWeight(.bold)
                    }
                }
            }
        }
        .onAppear {
            // Set up autosave
            setupAutosave()
            
            // Focus the title field for new notes, content for existing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if isNewNote && noteTitle.isEmpty {
                    isEditingTitle = true
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
        // Keep toolbar visible regardless of keyboard status
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Components
    
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
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            HStack(spacing: 0) {
                // Text formatting buttons
                if noteType != .sketch {
                    toolbarButton(icon: "list.bullet", color: .white) {
                        insertBulletPoint()
                    }
                    
                    toolbarButton(icon: "list.number", color: .white) {
                        insertNumberedList()
                    }
                    
                    toolbarButton(icon: "text.append", color: .white) {
                        insertHeading()
                    }
                    
                    Spacer()
                }
                
                // Tags button
                toolbarButton(icon: "tag", color: .white) {
                    showingTagEditor = true
                }
                
                // Color button
                toolbarButton(icon: "circle.fill", color: noteColor.color) {
                    withAnimation {
                        showingColorPicker.toggle()
                        isSettingsExpanded = false
                    }
                }
                
                // More button
                toolbarButton(icon: "ellipsis", color: .white) {
                    withAnimation {
                        isSettingsExpanded.toggle()
                        showingColorPicker = false
                    }
                }
            }
            .frame(height: 56)
            .background(Color.black)
        }
    }
    
    /// Color picker overlay
    private var colorPickerOverlay: some View {
        HStack(spacing: 16) {
            ForEach(Note.NoteColor.allCases) { color in
                Button(action: {
                    withAnimation {
                        noteColor = color
                        showingColorPicker = false
                        triggerAutosave()
                        showSavedFeedback()
                    }
                }) {
                    Circle()
                        .fill(color.color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: noteColor == color ? 2 : 0)
                        )
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.bottom, 80) // Position above toolbar with adequate spacing
    }
    
    /// Settings overlay
    private var settingsOverlay: some View {
        VStack(spacing: 0) {
            // Section title
            HStack {
                Text("Note Options")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isSettingsExpanded = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Options list
            VStack(spacing: 0) {
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
                .padding(.vertical, 14)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                // Toggle full screen
                Button(action: {
                    // Toggle full screen would go here
                    isSettingsExpanded = false
                }) {
                    HStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 24)
                        
                        Text("Focus Mode")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                // Share button
                Button(action: {
                    // Share function would go here
                    isSettingsExpanded = false
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
                    .padding(.vertical, 14)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 16)
                
                // Delete button
                Button(action: {
                    isSettingsExpanded = false
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
                    .padding(.vertical, 14)
                }
            }
        }
        .background(Color.black.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 80) // Position above toolbar
    }
    
    /// Generic toolbar button
    private func toolbarButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get placeholder text based on note type
    private func getPlaceholderText() -> String {
        switch noteType {
        case .basic:
            return "Start typing your thoughts here..."
        case .bullets:
            return "• Start typing your bullet points\n• Use • to create new bullets\n• Organize your thoughts in lists"
        case .markdown:
            return "# Use markdown formatting\n\nStart writing here..."
        case .sketch:
            return "Add notes about your sketch here..."
        }
    }
    
    /// Set up autosave functionality
    private func setupAutosave() {
        autosaveCancellable = autosaveSubject
            .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
            .sink { _ in
                // Don't use weak self as structs don't support weak references
                self.saveNoteWithSketch()
            }
    }
    
    /// Trigger autosave
    private func triggerAutosave() {
        autosaveSubject.send(())
    }
    
    /// Save the note with sketch support
    func saveNoteWithSketch() {
        guard !noteTitle.isEmpty || !noteContent.isEmpty else {
            // Don't save completely empty notes
            return
        }
        
        if let id = existingNoteId {
            // Update existing note
            let updatedNote = Note(
                title: noteTitle,
                content: noteContent,
                color: noteColor,
                type: noteType,
                isPinned: isPinned,
                tags: tags
            )
            updatedNote.id = id
            
            // Set sketch data
            if let data = sketchData {
                updatedNote.sketchData = data
            }
            
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
            
            // Set sketch data if available
            if let data = sketchData {
                newNote.sketchData = data
            }
        }
        
        // Show save indicator
        showSavedFeedback()
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
    
    /// Save note to service (wrapper for backwards compatibility)
    private func saveNote() {
        saveNoteWithSketch()
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
    
    /// Insert a bullet point at cursor position
    private func insertBulletPoint() {
        let cursorPosition = noteContent.count
        noteContent.append("\n• ")
        isContentFocused = true
        triggerAutosave()
    }
    
    /// Insert a numbered list item at cursor position
    private func insertNumberedList() {
        let cursorPosition = noteContent.count
        noteContent.append("\n1. ")
        isContentFocused = true
        triggerAutosave()
    }
    
    /// Insert a heading at cursor position
    private func insertHeading() {
        let cursorPosition = noteContent.count
        noteContent.append("\n## ")
        isContentFocused = true
        triggerAutosave()
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
    
    /// Count words in text
    private func countWords(_ text: String) -> Int {
        return text.split(whereSeparator: { $0.isWhitespace }).count
    }
}

/// Redesigned SketchNoteView for drawing with simplified controls
struct SketchNoteView: View {
    // Note content bindings
    @Binding var textContent: String
    @Binding var sketchData: Data?
    @State private var isDrawingMode = true
    
    // Focus state for text editor
    @FocusState private var isTextFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode selector at the top
            HStack {
                Picker("Mode", selection: $isDrawingMode) {
                    Text("Draw").tag(true)
                    Text("Text").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // Content area
            if isDrawingMode {
                // Drawing canvas
                DrawingCanvas(canvasData: $sketchData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else {
                // Text area for notes about the sketch
                VStack {
                    TextEditor(text: $textContent)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .focused($isTextFocused)
                        .overlay(
                            Group {
                                if textContent.isEmpty && !isTextFocused {
                                    HStack {
                                        Text("Add notes about your sketch here...")
                                            .foregroundColor(.gray)
                                            .padding(.leading, 24)
                                        Spacer()
                                    }
                                    .padding(.top, 24)
                                }
                            }
                        )
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.05))
        .cornerRadius(12)
    }
}
