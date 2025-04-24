import SwiftUI

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
    
    // UI state properties
    @State private var showingDeleteAlert = false
    @State private var showingColorPicker = false
    @State private var showingTypeSelector = false
    @State private var showingTagEditor = false
    @State private var newTag: String = ""
    @State private var isShowingToolbar = true
    @State private var isSaved = true
    @State private var showingSaveIndicator = false
    @FocusState private var isContentFocused: Bool
    
    // Properties for handling the focused editing
    @State private var focusMode = false
    @State private var toolbarHeight: CGFloat = 44
    
    // For easier tracking of existing note vs new note
    private let existingNoteId: UUID?
    private let isNewNote: Bool
    
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
    init(isNewNote: Bool = true) {
        _noteTitle = State(initialValue: "")
        _noteContent = State(initialValue: "")
        _noteColor = State(initialValue: .blue)
        _noteType = State(initialValue: .basic)
        _isPinned = State(initialValue: false)
        _tags = State(initialValue: [])
        
        self.existingNoteId = nil
        self.isNewNote = true
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                // Editor area
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Title
                        TextField("Untitled Note", text: $noteTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .onChange(of: noteTitle) { oldValue, newValue in
                                isSaved = false
                                autosave()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        
                        // Note type indicator and date
                        HStack {
                            HStack {
                                Image(systemName: noteType.iconName)
                                    .foregroundColor(noteColor.color)
                                
                                Text(noteType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(noteColor.color.opacity(0.1))
                            .cornerRadius(6)
                            
                            Spacer()
                            
                            // Last edited placeholder
                            Text("Edited just now")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        
                        // Content
                        TextEditor(text: $noteContent)
                            .focused($isContentFocused)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .font(.body)
                            .foregroundColor(.white)
                            .lineSpacing(4)
                            .frame(minHeight: 300)
                            .onChange(of: noteContent) { oldValue, newValue in
                                isSaved = false
                                autosave()
                            }
                            .padding(.horizontal, 12)
                            .overlay(
                                // Placeholder text
                                Group {
                                    if noteContent.isEmpty && !isContentFocused {
                                        VStack {
                                            HStack {
                                                Text(getPlaceholderText())
                                                    .foregroundColor(.gray)
                                                    .padding(.horizontal, 16)
                                                    .padding(.top, 8)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            )
                        
                        // Tags section
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        tagView(tag)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.bottom, 100) // Extra padding at bottom for toolbar
                }
                .background(Color.black)
            }
            
            // Floating toolbar
            if isShowingToolbar {
                FloatingToolbar(
                    noteType: $noteType,
                    noteColor: $noteColor,
                    isPinned: $isPinned,
                    onFocusMode: toggleFocusMode,
                    onShowTags: { showingTagEditor = true },
                    onDelete: { showingDeleteAlert = true }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Only show toolbar items when not in focus mode
            if !focusMode {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Save indicator - briefly appears when saving
                        if showingSaveIndicator {
                            Text("Saved")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .transition(.opacity)
                        }
                        
                        // Toggle pin button
                        Button(action: {
                            isPinned.toggle()
                            isSaved = false
                            autosave()
                        }) {
                            Image(systemName: isPinned ? "pin.fill" : "pin")
                                .foregroundColor(isPinned ? .yellow : .white)
                        }
                        
                        // Toggle toolbar button
                        Button(action: {
                            withAnimation {
                                isShowingToolbar.toggle()
                            }
                        }) {
                            Image(systemName: isShowingToolbar ? "chevron.down.circle" : "chevron.up.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            } else {
                // Exit focus mode button when in focus mode
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleFocusMode()
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTagEditor) {
            // Tag editor sheet
            TagEditorView(tags: $tags)
        }
        .alert(isPresented: $showingDeleteAlert) {
            // Delete confirmation alert
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
            // Focus content when the view appears for new notes
            if isNewNote {
                isContentFocused = true
            }
        }
        .onDisappear {
            // Ensure note is saved when view disappears
            saveNote()
        }
    }
    
    // MARK: - Helper Views
    
    /// Tag view for displaying a tag with delete option
    private func tagView(_ tag: String) -> some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: {
                // Remove tag
                tags.removeAll { $0 == tag }
                isSaved = false
                autosave()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    /// Save the current note
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
        
        isSaved = true
    }
    
    /// Auto-save after a delay
    private func autosave() {
        // Use debounce pattern - only save after user stops typing
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                              selector: #selector(performAutosave),
                                              object: nil)
        perform(#selector(performAutosave), with: nil, afterDelay: 1.0)
    }
    
    /// Perform actual auto-save operation
    @objc private func performAutosave() {
        saveNote()
        
        // Show saved indicator briefly
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
    
    /// Delete the current note
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
    
    /// Toggle focus mode
    private func toggleFocusMode() {
        withAnimation {
            focusMode.toggle()
            
            // Hide toolbar and other UI elements in focus mode
            if focusMode {
                isShowingToolbar = false
            } else {
                isShowingToolbar = true
            }
        }
    }
    
    /// Get placeholder text based on note type
    private func getPlaceholderText() -> String {
        switch noteType {
        case .basic:
            return "Start typing your thoughts here..."
        case .bullets:
            return "• Start typing your bullet points\n• Use • to create new bullets\n• Organize your thoughts in lists"
        case .markdown:
            return "# Heading\n## Subheading\n\nStart writing with **markdown** formatting...\n\n- List item 1\n- List item 2\n\n> Blockquote"
        case .sketch:
            return "Use this space for visual thinking and rough sketches with text..."
        }
    }
}

// MARK: - Floating Toolbar

struct FloatingToolbar: View {
    @Binding var noteType: Note.NoteType
    @Binding var noteColor: Note.NoteColor
    @Binding var isPinned: Bool
    
    let onFocusMode: () -> Void
    let onShowTags: () -> Void
    let onDelete: () -> Void
    
    @State private var showingColorPicker = false
    @State private var showingTypeSelector = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Note format selector
            Button(action: {
                withAnimation {
                    showingTypeSelector.toggle()
                    if showingTypeSelector {
                        showingColorPicker = false
                    }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: noteType.iconName)
                        .foregroundColor(.white)
                    
                    if !showingTypeSelector {
                        Text(noteType.rawValue)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(16)
            }
            
            // Spacer or type selector dropdown
            if showingTypeSelector {
                HStack(spacing: 12) {
                    ForEach(Note.NoteType.allCases) { type in
                        Button(action: {
                            noteType = type
                            withAnimation {
                                showingTypeSelector = false
                            }
                        }) {
                            Image(systemName: type.iconName)
                                .foregroundColor(noteType == type ? .white : .gray)
                                .frame(width: 32, height: 32)
                                .background(noteType == type ? Color.blue.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .transition(.opacity)
            }
            
            Spacer()
            
            // Color button
            Button(action: {
                withAnimation {
                    showingColorPicker.toggle()
                    if showingColorPicker {
                        showingTypeSelector = false
                    }
                }
            }) {
                Circle()
                    .fill(noteColor.color)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 8)
            
            // Color picker dropdown
            if showingColorPicker {
                HStack(spacing: 8) {
                    ForEach(Note.NoteColor.allCases) { color in
                        Button(action: {
                            noteColor = color
                            withAnimation {
                                showingColorPicker = false
                            }
                        }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(noteColor == color ? Color.white : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, 8)
                .transition(.opacity)
            }
            
            // Tags button
            Button(action: onShowTags) {
                Image(systemName: "tag")
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
            }
            
            // Focus mode button
            Button(action: onFocusMode) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
            }
        }
        .frame(height: 44)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(UIColor.systemGray6).opacity(0.95))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Tag Editor View

struct TagEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tags: [String]
    @State private var newTag: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // New tag input field
                    HStack {
                        Text("#")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        TextField("Add new tag", text: $newTag)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button(action: addTag) {
                            Text("Add")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                                .opacity(newTag.isEmpty ? 0.5 : 1.0)
                        }
                        .disabled(newTag.isEmpty)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Current tags section
                    if tags.isEmpty {
                        Text("No tags yet. Add a tag to categorize your note.")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.top, 20)
                            .padding(.horizontal)
                    } else {
                        // Tags grid
                        ScrollView {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 120))],
                                spacing: 12
                            ) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack {
                                        Text("#\(tag)")
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            removeTag(tag)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationBarTitle("Manage Tags", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onSubmit(addTag)
        }
    }
    
    /// Add a new tag
    private func addTag() {
        // Clean up tag: lowercase, no spaces, alphanumeric and underscore only
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
    
    /// Remove a tag
    private func removeTag(_ tag: String) {
        withAnimation {
            tags.removeAll { $0 == tag }
        }
    }
}


// MARK: - Preview

struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditorView(note: Note.sample)
            .environmentObject(NoteService.shared)
            .preferredColorScheme(.dark)
    }
}
