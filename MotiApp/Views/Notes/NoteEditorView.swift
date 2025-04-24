import SwiftUI
import Combine

struct NoteEditorView: View {
    // MARK: - Environment & Dependencies
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var noteService: NoteService
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
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
    @State private var showingDeleteAlert = false
    @State private var showingColorPicker = false
    @State private var showingTypeSelector = false
    @State private var showingTagEditor = false
    @State private var newTag: String = ""
    @State private var isShowingToolbar = true
    @State private var isSaved = true
    @State private var showingSaveIndicator = false
    @State private var lastSaveTimestamp: TimeInterval = 0
    @FocusState private var isContentFocused: Bool
    @FocusState private var isTitleFocused: Bool
    
    // Properties for handling the focused editing
    @State private var focusMode = false
    @State private var toolbarHeight: CGFloat = 44
    @State private var showMarkdownPreview = false
    
    // Autosave handling
    private let autosaveSubject = PassthroughSubject<Void, Never>()
    @State private var autosaveCancellable: AnyCancellable?
    
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
        mainContent
    }

    // Main content container
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Main content
            noteContentArea
            
            // Floating toolbar
            if isShowingToolbar {
                FloatingToolbar(
                    noteType: $noteType,
                    noteColor: $noteColor,
                    isPinned: $isPinned,
                    showMarkdownPreview: $showMarkdownPreview,
                    isMarkdownType: noteType == .markdown,
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
            toolbarContent
        }
        .sheet(isPresented: $showingTagEditor) {
            // Tag editor sheet
            TagEditorView(tags: $tags)
                .onDisappear {
                    // Update note when tag editor is dismissed
                    saveNote()
                }
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
        // Add remaining modifiers here
    }

    // Note content area
    private var noteContentArea: some View {
        VStack(spacing: 0) {
            // Editor area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Title field
                    titleSection
                    
                    // Note type indicator and date
                    metadataSection
                    
                    // Content section
                    contentSection
                    
                    // Tags section
                    tagsSection
                }
                .padding(.bottom, 100) // Extra padding at bottom for toolbar
            }
            .background(Color.black)
        }
    }

    // Title section
    private var titleSection: some View {
        TextField("Untitled Note", text: $noteTitle)
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .onChange(of: noteTitle) { oldValue, newValue in
                isSaved = false
                triggerAutosave()
            }
            .focused($isTitleFocused)
            .padding(.horizontal, 16)
            .padding(.top, 16)
    }

    // Metadata section
    private var metadataSection: some View {
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
            
            // Last edited placeholder or save indicator
            if showingSaveIndicator {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Saved")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text("Edited just now")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
    }

    // Content section
    private var contentSection: some View {
        Group {
            if noteType == .markdown && showMarkdownPreview {
                // Markdown preview
                VStack(alignment: .leading) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 16)
                    
                    MarkdownView(text: noteContent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                }
            } else {
                // Content editor
                ZStack(alignment: .topLeading) {
                    // Placeholder text
                    if noteContent.isEmpty && !isContentFocused {
                        Text(getPlaceholderText())
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                    
                    // Use appropriate editor for different note types
                    noteEditor
                        .focused($isContentFocused)
                        .onChange(of: noteContent) { oldValue, newValue in
                            handleContentChange(from: oldValue, to: newValue)
                        }
                }
            }
        }
    }

    // Tags section
    private var tagsSection: some View {
        Group {
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
    }

    // Toolbar content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                        triggerAutosave()
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
    
    // MARK: - Note Type Specific Editors
    
    @ViewBuilder
    private var noteEditor: some View {
        if noteType == .markdown {
            // Markdown editor with monospaced font
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.system(Font.TextStyle.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)
                .frame(minHeight: 300)
                .padding(.horizontal, 12)
        } else if noteType == .bullets {
            // Bullets editor
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(4)
                .frame(minHeight: 300)
                .padding(.horizontal, 12)
                .onChange(of: noteContent) { oldValue, newValue in
                    handleBulletPoints(from: oldValue, to: newValue)
                }
        } else if noteType == .sketch {
            // Sketch editor with monospaced font for ASCII art
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.system(Font.TextStyle.body, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)
                .frame(minHeight: 300)
                .padding(.horizontal, 12)
        } else {
            // Basic text editor
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(4)
                .frame(minHeight: 300)
                .padding(.horizontal, 12)
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
                triggerAutosave()
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
        lastSaveTimestamp = Date().timeIntervalSince1970
    }
    
    /// Format content for bullet point type
    private func formatContentForBullets() {
        if !noteContent.isEmpty {
            // Split by lines and add bullets
            let lines = noteContent.components(separatedBy: .newlines)
            let bulletedLines = lines.map { line -> String in
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return line
                }
                if line.hasPrefix("• ") || line.isEmpty {
                    return line
                }
                return "• \(line)"
            }
            noteContent = bulletedLines.joined(separator: "\n")
        }
    }
    
    /// Trigger autosave
    private func triggerAutosave() {
        autosaveSubject.send(())
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
    
    // State for focus mode
    @State private var showingFocusMode = false
    
    /// Toggle focus mode
    private func toggleFocusMode() {
        // Show the full-screen focus mode
        showingFocusMode = true
    }
    
    /// Handle content changes with special formatting for bullet points
    private func handleContentChange(from oldValue: String, to newValue: String) {
        isSaved = false
        triggerAutosave()
    }
    
    /// Special handling for bullet points
    private func handleBulletPoints(from oldValue: String, to newValue: String) {
        // Only process if this is a bullet-type note
        guard noteType == .bullets else { return }
        
        // Check if the user just pressed Enter
        if newValue.hasSuffix("\n") && !newValue.hasSuffix("\n\n") && oldValue != newValue {
            // Add a bullet point to the new line
            DispatchQueue.main.async {
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
    @Binding var showMarkdownPreview: Bool
    
    let isMarkdownType: Bool
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
                .background(Color(UIColor.systemGray6).opacity(0.95))
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1) // Add border
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2) // Add subtle shadow
            }
            
            // Type selector dropdown
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
            
            // Show/Hide Markdown Preview (only for markdown notes)
            if isMarkdownType {
                Button(action: {
                    withAnimation {
                        showMarkdownPreview.toggle()
                    }
                }) {
                    Image(systemName: showMarkdownPreview ? "doc.text" : "doc.text.magnifyingglass")
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                }
            }
            
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
            .help("Enter Focus Mode")
            
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

// MARK: - Markdown View

struct MarkdownView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(formattedText, id: \.id) { segment in
                segment.view
            }
        }
    }
    
    // Simple markdown formatting
    private var formattedText: [TextSegment] {
        var segments: [TextSegment] = []
        var currentId = 0
        
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            currentId += 1
            
            if trimmedLine.hasPrefix("# ") {
                // Heading 1
                let content = trimmedLine.dropFirst(2)
                segments.append(TextSegment(
                    id: currentId,
                    view: Text(String(content))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                ))
            } else if trimmedLine.hasPrefix("## ") {
                // Heading 2
                let content = trimmedLine.dropFirst(3)
                segments.append(TextSegment(
                    id: currentId,
                    view: Text(String(content))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 6)
                        .padding(.bottom, 2)
                ))
            } else if trimmedLine.hasPrefix("### ") {
                // Heading 3
                let content = trimmedLine.dropFirst(4)
                segments.append(TextSegment(
                    id: currentId,
                    view: Text(String(content))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                        .padding(.bottom, 2)
                ))
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                // List item
                let content = trimmedLine.dropFirst(2)
                segments.append(TextSegment(
                    id: currentId,
                    view: HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.white)
                        Text(String(content))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 16)
                ))
            } else if trimmedLine.hasPrefix(">") {
                // Blockquote
                let content = trimmedLine.dropFirst(1).trimmingCharacters(in: .whitespaces)
                segments.append(TextSegment(
                    id: currentId,
                    view: Text(content)
                        .foregroundColor(.white.opacity(0.8))
                        .italic()
                        .padding(.leading, 12)
                        .overlay(
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 4)
                                .padding(.vertical, 2),
                            alignment: .leading
                        )
                ))
            } else if !trimmedLine.isEmpty {
                // Regular text with bold and italic support
                let attributedText = formatInlineStyles(text: trimmedLine)
                segments.append(TextSegment(
                    id: currentId,
                    view: attributedText
                ))
            } else {
                // Empty line
                segments.append(TextSegment(
                    id: currentId,
                    view: Text(" ")
                        .font(.body)
                ))
            }
        }
        
        return segments
    }
    
    // Format bold and italic inline styles
    private func formatInlineStyles(text: String) -> Text {
        var formattedText = Text("")
        var currentText = ""
        var isBold = false
        var isItalic = false
        var index = text.startIndex
        
        // Helper to append current text with appropriate styling
        func appendCurrentText() {
            if !currentText.isEmpty {
                var textToAppend = Text(currentText)
                if isBold {
                    textToAppend = textToAppend.bold()
                }
                if isItalic {
                    textToAppend = textToAppend.italic()
                }
                formattedText = formattedText + textToAppend
                currentText = ""
            }
        }
        
        while index < text.endIndex {
            let char = text[index]
            
            // Check for bold marker (**)
            if char == "*" && index < text.index(before: text.endIndex) && text[text.index(after: index)] == "*" {
                appendCurrentText()
                isBold.toggle()
                index = text.index(index, offsetBy: 2)
                if index > text.endIndex {
                    index = text.endIndex
                }
                continue
            }
            
            // Check for italic marker (*)
            if char == "*" {
                appendCurrentText()
                isItalic.toggle()
                index = text.index(after: index)
                continue
            }
            
            currentText.append(char)
            index = text.index(after: index)
        }
        
        // Append any remaining text
        appendCurrentText()
        
        return formattedText.foregroundColor(.white)
    }
    
    // Helper struct to create identifiable text segments
    struct TextSegment: Identifiable {
        let id: Int
        let view: AnyView
        
        init<V: View>(id: Int, view: V) {
            self.id = id
            self.view = AnyView(view)
        }
    }
}

// MARK: - Previews

struct NoteEditorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for new note
            NoteEditorView()
                .environmentObject(NoteService.shared)
                .preferredColorScheme(.dark)
                .previewDisplayName("New Note")
            
            // Preview for editing existing note
            NoteEditorView(note: Note.samples[0])
                .environmentObject(NoteService.shared)
                .preferredColorScheme(.dark)
                .previewDisplayName("Edit Note")
        }
    }
}
