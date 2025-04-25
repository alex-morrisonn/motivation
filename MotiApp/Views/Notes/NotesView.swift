import SwiftUI

struct NotesView: View {
    // MARK: - Properties
    
    @ObservedObject private var noteService = NoteService.shared
    @State private var showingNewNote = false
    @State private var searchText = ""
    @State private var selectedNote: Note? = nil
    @State private var activeTab: NoteTab = .all
    @State private var showingSidebar = true
    @State private var isSaved = false
    @State private var newNoteType: Note.NoteType = .basic
    @State private var showingSortMenu = false
    @State private var sortOption: SortOption = .lastEdited
    @State private var showingDeleteConfirmation = false
    @State private var showingTagManager = false
    @State private var showingBackupOptions = false
    
    // For environment adaptations
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    
    // Enum for tab navigation
    enum NoteTab {
        case all, pinned, tags
    }
    
    // Enum for sorting options
    enum SortOption {
        case lastEdited, title, created
        
        var description: String {
            switch self {
            case .lastEdited: return "Last Edited"
            case .title: return "Title"
            case .created: return "Created Date"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Main content
                if showingSidebar {
                    // Two-column layout with fixed sidebar width
                    HStack(spacing: 0) {
                        // Sidebar - with fixed narrow width
                        notesSidebar
                            .frame(width: UIScreen.main.bounds.width * 0.75) // 75% of screen width
                            .background(Color.black)
                            .transition(.move(edge: .leading))
                        
                        Spacer() // Push sidebar to the left edge
                    }
                } else {
                    // Note view or empty state when sidebar is hidden
                    ZStack {
                        if let note = selectedNote {
                            // Note editor view when a note is selected
                            NoteEditorView(note: note)
                                .id(note.id)
                                .environmentObject(noteService)
                                .transition(.opacity)
                                .onChange(of: noteService.refreshTrigger) { oldValue, newValue in
                                    // Check if the selected note still exists
                                    if !noteService.notes.contains(where: { $0.id == note.id }) {
                                        selectedNote = nil
                                    }
                                }
                        } else {
                            // Empty state when no note is selected
                            emptyStateView
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $showingNewNote) {
                // Sheet for creating a new note
                NavigationView {
                    NoteEditorView(isNewNote: true, initialType: newNoteType)
                        .environmentObject(noteService)
                        .navigationBarTitle("New Note", displayMode: .inline)
                        .navigationBarItems(
                            leading: Button("Cancel") {
                                showingNewNote = false
                            },
                            trailing: Button("Save") {
                                showingNewNote = false
                            }
                            .fontWeight(.bold)
                        )
                }
                .accentColor(.white)
            }
            .onChange(of: selectedNote) { oldValue, newValue in
                // Make the sidebar disappear on small devices when a note is selected
                if horizontalSizeClass == .compact && newValue != nil {
                    withAnimation {
                        showingSidebar = false
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // When app moves to background, make sure notes are saved
                if newPhase == .background {
                    // This triggers a save in the NoteService
                    noteService.triggerAutosave()
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete All Notes"),
                    message: Text("Are you sure you want to delete all notes? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete All")) {
                        noteService.deleteAllNotes()
                        selectedNote = nil
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading items - toggle sidebar and title
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            showingSidebar.toggle()
                        }
                    }) {
                        Image(systemName: showingSidebar ? "sidebar.left" : "sidebar.right")
                            .foregroundColor(.white)
                    }
                }
                
                // Trailing items - search and new note
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Save indicator when note is saved
                        if isSaved {
                            Label("Saved", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .transition(.opacity)
                                .onAppear {
                                    // Hide the saved indicator after a delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            isSaved = false
                                        }
                                    }
                                }
                        }
                        
                        // Only show sort button in sidebar
                        if showingSidebar {
                            Menu {
                                Picker("Sort by", selection: $sortOption) {
                                    Text("Last Edited").tag(SortOption.lastEdited)
                                    Text("Title").tag(SortOption.title)
                                    Text("Created Date").tag(SortOption.created)
                                }
                                .pickerStyle(InlinePickerStyle())
                            } label: {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // New note button - with menu for different note types
                        Menu {
                            Button(action: {
                                newNoteType = .basic
                                showingNewNote = true
                            }) {
                                Label("Basic Note", systemImage: "text.alignleft")
                            }
                            
                            Button(action: {
                                newNoteType = .bullets
                                showingNewNote = true
                            }) {
                                Label("Bullet Points", systemImage: "list.bullet")
                            }
                            
                            Button(action: {
                                newNoteType = .markdown
                                showingNewNote = true
                            }) {
                                Label("Markdown", systemImage: "text.badge.checkmark")
                            }
                            
                            Button(action: {
                                newNoteType = .sketch
                                showingNewNote = true
                            }) {
                                Label("Sketch", systemImage: "pencil.line")
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingTagManager = true
                            }) {
                                Label("Manage Tags", systemImage: "tag")
                            }
                            
                            Button(action: {
                                showingBackupOptions = true
                            }) {
                                Label("Backup & Restore", systemImage: "arrow.triangle.2.circlepath")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Delete All Notes", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onAppear {
                // For small devices, start with the sidebar shown
                showingSidebar = true
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Sidebar View
    
    private var notesSidebar: some View {
        VStack(spacing: 0) {
            // Header with title
            HStack {
                Text("Mind Dump")
                    .font(.title2) // Smaller font
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.leading, 8) // Add left padding
                
                Spacer()
                
                // Plus button with menu for new note types
                Menu {
                    Button(action: {
                        createNote(type: .basic)
                    }) {
                        Label("Basic Note", systemImage: "text.alignleft")
                    }
                    
                    Button(action: {
                        createNote(type: .bullets)
                    }) {
                        Label("Bullet Points", systemImage: "list.bullet")
                    }
                    
                    Button(action: {
                        createNote(type: .markdown)
                    }) {
                        Label("Markdown", systemImage: "text.badge.checkmark")
                    }
                    
                    Button(action: {
                        createNote(type: .sketch)
                    }) {
                        Label("Sketch", systemImage: "pencil.line")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                }
                .padding(.trailing, 8) // Add right padding
            }
            .padding(.vertical, 8) // Reduced vertical padding
            
            // Search field (tighter)
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 4) // Reduced padding
                
                TextField("Search notes...", text: $searchText)
                    .foregroundColor(.white)
                    .padding(.vertical, 6) // Reduced padding
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 4) // Reduced padding
                    }
                }
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal, 8) // Reduced horizontal padding
            .padding(.bottom, 8) // Reduced bottom padding
            
            // Tab selector (keep compact)
            HStack(spacing: 0) {
                tabButton(title: "All", tab: .all)
                tabButton(title: "Pinned", tab: .pinned)
                tabButton(title: "Tags", tab: .tags)
            }
            .padding(.bottom, 4) // Reduced padding
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Notes list (keep as is)
            ScrollView {
                LazyVStack(spacing: 4) { // Reduced spacing
                    // Display notes based on active tab and search text
                    let filteredNotes = filterNotes()
                    
                    if filteredNotes.isEmpty {
                        emptyFilterStateView
                    } else {
                        ForEach(filteredNotes) { note in
                            NoteListItem(
                                note: note,
                                isSelected: selectedNote?.id == note.id,
                                onSelect: {
                                    selectedNote = note
                                    // On phone, hide sidebar after selection
                                    if horizontalSizeClass == .compact {
                                        showingSidebar = false
                                    }
                                },
                                onTogglePin: {
                                    noteService.togglePinned(note)
                                    withAnimation {
                                        isSaved = true
                                    }
                                },
                                onDelete: {
                                    if selectedNote?.id == note.id {
                                        selectedNote = nil
                                    }
                                    noteService.deleteNote(note)
                                    withAnimation {
                                        isSaved = true
                                    }
                                }
                            )
                            .padding(.horizontal, 8) // Reduced padding
                        }
                    }
                }
                .padding(.vertical, 4) // Reduced padding
            }
            
            // Tags section (maintain if important)
            if activeTab == .tags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) { // Reduced spacing
                        ForEach(noteService.getAllTags(), id: \.self) { tag in
                            Button(action: {
                                searchText = tag
                            }) {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 6) // Reduced padding
                                    .padding(.vertical, 4) // Reduced padding
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 8) // Reduced padding
                }
                .padding(.vertical, 4) // Reduced padding
                .background(Color.black.opacity(0.2))
            }
        }
        .background(Color.black)
    }
    
    // View for empty results when filtering
    private var emptyFilterStateView: some View {
        VStack(spacing: 8) { // Reduced spacing
            if !searchText.isEmpty {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30)) // Smaller size
                    .foregroundColor(.gray)
                    .padding(.bottom, 4) // Reduced padding
                
                Text("No results for \"\(searchText)\"")
                    .font(.subheadline) // Smaller font
                    .foregroundColor(.white)
                
                Button(action: {
                    searchText = ""
                }) {
                    Text("Clear Search")
                        .font(.caption) // Smaller font
                        .foregroundColor(.blue)
                        .padding(.top, 4) // Reduced padding
                }
            } else {
                switch activeTab {
                case .all:
                    Text("No notes yet")
                        .font(.subheadline) // Smaller font
                        .foregroundColor(.white)
                    
                    Button(action: {
                        createNote(type: .basic)
                    }) {
                        Text("Create Note")
                            .font(.caption) // Smaller font
                            .foregroundColor(.blue)
                            .padding(.top, 4) // Reduced padding
                    }
                case .pinned:
                    Image(systemName: "pin")
                        .font(.system(size: 30)) // Smaller size
                        .foregroundColor(.gray)
                        .padding(.bottom, 4) // Reduced padding
                    
                    Text("No pinned notes")
                        .font(.subheadline) // Smaller font
                        .foregroundColor(.white)
                    
                    Text("Pin your most important notes")
                        .font(.caption) // Smaller font
                        .foregroundColor(.gray)
                        .padding(.top, 2) // Reduced padding
                case .tags:
                    Image(systemName: "tag")
                        .font(.system(size: 30)) // Smaller size
                        .foregroundColor(.gray)
                        .padding(.bottom, 4) // Reduced padding
                    
                    Text("No tagged notes")
                        .font(.subheadline) // Smaller font
                        .foregroundColor(.white)
                    
                    Text("Add tags to categorize your notes")
                        .font(.caption) // Smaller font
                        .foregroundColor(.gray)
                        .padding(.top, 2) // Reduced padding
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20) // Reduced padding
        .padding(.horizontal, 16) // Reduced padding
    }
    
    // MARK: - Sidebar Tab Button
    
    private func tabButton(title: String, tab: NoteTab) -> some View {
        Button(action: {
            withAnimation {
                activeTab = tab
            }
        }) {
            Text(title)
                .font(.footnote) // Smaller font
                .fontWeight(activeTab == tab ? .semibold : .regular)
                .padding(.vertical, 6) // Reduced padding
                .frame(maxWidth: .infinity)
                .foregroundColor(activeTab == tab ? .white : .gray)
        }
        .background(
            activeTab == tab ?
                Color.blue.opacity(0.2) :
                Color.clear
        )
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack {
            // Icon and title
            Image(systemName: "note.text")
                .font(.system(size: 70))
                .foregroundColor(.gray)
                .padding(.bottom, 16)
            
            Text("No Note Selected")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 8)
            
            Text("Select a note from the list or create a new one to start writing.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            
            // Create note button
            Button(action: {
                createNote(type: .basic)
            }) {
                Label("Create New Note", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            // Quick template buttons
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Templates")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                
                // Template options
                HStack(spacing: 12) {
                    ForEach(Note.NoteType.allCases) { type in
                        templateButton(for: type)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.top, 30)
            
            // On small screens, provide a way to return to the sidebar
            if horizontalSizeClass == .compact && !showingSidebar {
                Button(action: {
                    withAnimation {
                        showingSidebar = true
                    }
                }) {
                    Label("Show Notes List", systemImage: "list.bullet")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                }
            }
        }
        .padding()
        .frame(maxWidth: 500) // Limit max width for better readability
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Center in available space
        .background(Color.black)
    }
    
    // MARK: - Template Button
    
    private func templateButton(for type: Note.NoteType) -> some View {
        Button(action: {
            createNote(type: type)
        }) {
            VStack {
                Image(systemName: type.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Filter notes based on active tab, search text, and sort option
    private func filterNotes() -> [Note] {
        // First filter by tab
        var filteredNotes: [Note]
        
        switch activeTab {
        case .all:
            filteredNotes = searchText.isEmpty ?
                noteService.notes :
                noteService.searchNotes(searchText)
        case .pinned:
            filteredNotes = noteService.getPinnedNotes()
            if !searchText.isEmpty {
                filteredNotes = filteredNotes.filter { note in
                    note.title.lowercased().contains(searchText.lowercased()) ||
                    note.content.lowercased().contains(searchText.lowercased()) ||
                    note.tags.contains(where: { $0.lowercased().contains(searchText.lowercased()) })
                }
            }
        case .tags:
            if searchText.isEmpty {
                filteredNotes = noteService.notes
            } else {
                filteredNotes = noteService.getNotesByTag(searchText)
            }
        }
        
        // Then sort by selected sort option
        switch sortOption {
        case .lastEdited:
            filteredNotes.sort { $0.lastEditedDate > $1.lastEditedDate }
        case .title:
            filteredNotes.sort { $0.title.lowercased() < $1.title.lowercased() }
        case .created:
            // This would require adding a createdDate property to the Note model
            // For now, just sort by lastEditedDate as a fallback
            filteredNotes.sort { $0.lastEditedDate > $1.lastEditedDate }
        }
        
        return filteredNotes
    }
    
    /// Create a new note with the specified type
    private func createNote(type: Note.NoteType) {
        let newNote = noteService.createNewNote(type: type)
        noteService.addNote(newNote)
        withAnimation {
            selectedNote = newNote
            isSaved = true
            
            // On phone, hide sidebar when creating a note
            if horizontalSizeClass == .compact {
                showingSidebar = false
            }
        }
    }
}

// MARK: - Note List Item

struct NoteListItem: View {
    let note: Note
    let isSelected: Bool
    let onSelect: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    
    // For forcing component refresh
    @ObservedObject private var todoService = TodoService.shared
    
    // State for animations and gestures
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    
    // The fixed width for the delete button
    private let deleteButtonWidth: CGFloat = 60 // Reduced width
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18)) // Smaller size
                        .foregroundColor(.white)
                        .frame(width: deleteButtonWidth, height: 70) // Reduced height
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .opacity(showingDeleteButton ? 1 : 0)
            }
            
            // Main content
            HStack(spacing: 8) { // Reduced spacing
                // Color indicator
                Rectangle()
                    .fill(note.color.color)
                    .frame(width: 3) // Narrower indicator
                    .cornerRadius(1.5)
                
                VStack(alignment: .leading, spacing: 2) { // Reduced spacing
                    // Title and pin button
                    HStack {
                        Text(note.title.isEmpty ? "Untitled Note" : note.title)
                            .font(.subheadline) // Smaller font
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Pin button
                        Button(action: onTogglePin) {
                            Image(systemName: note.isPinned ? "pin.fill" : "pin")
                                .font(.caption) // Smaller font
                                .foregroundColor(note.isPinned ? .yellow : .gray)
                        }
                    }
                    
                    // Content preview
                    Text(note.getContentPreview())
                        .font(.caption) // Smaller font
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    // Bottom row with date and tags
                    HStack {
                        // Type icon and name
                        Image(systemName: note.type.iconName)
                            .font(.system(size: 9)) // Smaller icon
                            .foregroundColor(.gray)
                        
                        Text(note.type.rawValue)
                            .font(.system(size: 9)) // Smaller font
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Date
                        Text(note.formattedDate)
                            .font(.system(size: 9)) // Smaller font
                            .foregroundColor(.gray)
                    }
                    
                    // Tags (if any)
                    if !note.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 3) { // Reduced spacing
                                ForEach(note.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 9)) // Smaller font
                                        .foregroundColor(.blue.opacity(0.8))
                                        .lineLimit(1)
                                }
                                
                                if note.tags.count > 3 {
                                    Text("+\(note.tags.count - 3)")
                                        .font(.system(size: 9)) // Smaller font
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8) // Reduced padding
            .padding(.horizontal, 8) // Reduced padding
            .background(isSelected ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
            .cornerRadius(8) // Smaller radius
            .contentShape(Rectangle())
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            // Limit drag to delete button width
                            self.offset = max(value.translation.width, -deleteButtonWidth)
                        } else if offset != 0 {
                            // Allow swiping right to hide delete button
                            self.offset = min(0, offset + value.translation.width)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if self.offset < -deleteButtonWidth * 0.5 {
                                self.offset = -deleteButtonWidth
                                self.showingDeleteButton = true
                            } else {
                                self.offset = 0
                                self.showingDeleteButton = false
                            }
                        }
                    }
            )
            .onTapGesture {
                if showingDeleteButton {
                    // Hide delete button if showing
                    withAnimation(.spring()) {
                        self.offset = 0
                        self.showingDeleteButton = false
                    }
                } else {
                    // Select the note
                    onSelect()
                }
            }
        }
    }
}

// MARK: - Preview

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
            .preferredColorScheme(.dark)
            .onAppear {
                // Create sample notes for preview
                for note in Note.samples {
                    NoteService.shared.addNote(note)
                }
            }
    }
}
