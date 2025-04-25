import SwiftUI
import Combine

/// Redesigned Note Editor View with simplified controls
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
                        
                        // Content editor
                        noteContentEditor
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .focused($isContentFocused)
                            .onChange(of: noteContent) { oldValue, newValue in
                                handleContentChange(from: oldValue, to: newValue)
                            }
                        
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
            saveNote()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Save when app moves to background
            if newPhase == .background {
                saveNote()
            }
        }
    }

    // MARK: - Components
    
    /// Content editor based on note type
    @ViewBuilder
    private var noteContentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Content placeholder
            if noteContent.isEmpty && !isContentFocused {
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
            case .bullets:
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(minHeight: 300)
            case .sketch:
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(minHeight: 300)
            case .basic:
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(minHeight: 300)
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
                        saveNote()
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
    
    /// Set up autosave with debouncing
    private func setupAutosave() {
        autosaveCancellable = autosaveSubject
            .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
            .sink { _ in
                self.saveNote()
            }
    }
    
    /// Trigger autosave
    private func triggerAutosave() {
        autosaveSubject.send(())
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
    
    /// Save note to service
    private func saveNote() {
        guard !noteTitle.isEmpty || !noteContent.isEmpty else {
            // Don't save empty notes
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
            
            // Add the note to service
            noteService.addNote(newNote)
        }
        
        // Show save indicator
        showSavedFeedback()
    }
    
    /// Delete note
    private func deleteNote() {
        if let id = existingNoteId {
            // Create a temporary note with the ID to delete
            let noteToDelete = Note()
            noteToDelete.id = id
            
            // Delete the note
            noteService.deleteNote(noteToDelete)
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
            return "Use this space for visual thinking..."
        }
    }
    
    /// Count words in text
    private func countWords(_ text: String) -> Int {
        return text.split(whereSeparator: { $0.isWhitespace }).count
    }
}

// MARK: - Tag Editor View

/// Simplified tag editor view
struct TagEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tags: [String]
    @State private var newTag: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Tag input field
                    HStack {
                        Text("#")
                            .foregroundColor(.blue)
                            .font(.headline)
                        
                        TextField("Add new tag", text: $newTag)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button(action: addTag) {
                            Text("Add")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .opacity(newTag.isEmpty ? 0.5 : 1.0)
                        }
                        .disabled(newTag.isEmpty)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if tags.isEmpty {
                        // Empty state
                        VStack(spacing: 10) {
                            Image(systemName: "tag")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                            
                            Text("No Tags Yet")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Add tags to organize your notes and find them easily")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        // Tags list
                        List {
                            ForEach(tags, id: \.self) { tag in
                                HStack {
                                    Text("#\(tag)")
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            tags.removeAll { $0 == tag }
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                                .contentShape(Rectangle())
                                .listRowBackground(Color.gray.opacity(0.2))
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .accentColor(.white)
        .preferredColorScheme(.dark)
    }
    
    /// Add tag to the list
    private func addTag() {
        // Clean up tag: lowercase, no spaces, alphanumeric
        let cleanedTag = newTag
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
        
        // Only add non-empty tags that don't already exist
        if !cleanedTag.isEmpty && !tags.contains(cleanedTag) {
            withAnimation {
                tags.append(cleanedTag)
                newTag = ""
            }
        }
    }
}

// MARK: - Flowing Tags Layout

/// Custom view for flowing tag layout
struct FlowingTags<Content: View>: View {
    let tags: [String]
    let tagView: (String) -> Content
    
    init(tags: [String], @ViewBuilder tagView: @escaping (String) -> Content) {
        self.tags = tags
        self.tagView = tagView
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(tags, id: \.self) { tag in
                tagView(tag)
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + 6
                        }
                        
                        let result = width
                        if tag == tags.last {
                            width = 0
                        } else {
                            width -= dimension.width + 6
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if tag == tags.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
        .frame(height: calculateHeight(in: geometry))
    }
    
    // Calculate the height needed for all tags
    private func calculateHeight(in geometry: GeometryProxy) -> CGFloat {
        let width = geometry.size.width
        var totalHeight: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for tag in tags {
            // This is an estimation - in a real app you'd measure actual tag sizes
            let tagWidth: CGFloat = CGFloat(tag.count * 10) + 40  // rough estimate
            
            if lineWidth + tagWidth > width {
                totalHeight += lineHeight + 6
                lineWidth = tagWidth
                lineHeight = 30  // approximate tag height
            } else {
                lineWidth += tagWidth + 6
                lineHeight = max(lineHeight, 30)
            }
        }
        
        return totalHeight + lineHeight + 10  // add padding
    }
}
