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
    
    // For environment adaptations
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Enum for tab navigation
    enum NoteTab {
        case all, pinned, tags
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Main content with sidebar and note view
                HStack(spacing: 0) {
                    // Sidebar with notes list - conditionally shown based on state and size class
                    if showingSidebar {
                        notesSidebar
                            .frame(width: 300)
                            .transition(.move(edge: .leading))
                    }
                    
                    // Note view or empty state
                    ZStack {
                        if let note = selectedNote {
                            // Note editor view when a note is selected
                            NoteEditorView(note: note)
                                .id(note.id)
                                .environmentObject(noteService)
                                .transition(.opacity)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading items - toggle sidebar and title
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        // Only show toggle on iPad/larger screens
                        if horizontalSizeClass == .regular {
                            Button(action: {
                                withAnimation {
                                    showingSidebar.toggle()
                                }
                            }) {
                                Image(systemName: "sidebar.left")
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if !showingSidebar || horizontalSizeClass == .compact {
                            Text("Mind Dump")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
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
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onAppear {
                // For small devices, hide sidebar by default when the view appears
                if horizontalSizeClass == .compact {
                    showingSidebar = false
                }
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
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
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
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 8)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("Search notes...", text: $searchText)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                }
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            // Tab selector
            HStack(spacing: 0) {
                tabButton(title: "All", tab: .all)
                tabButton(title: "Pinned", tab: .pinned)
                tabButton(title: "Tags", tab: .tags)
            }
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Notes list
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Display notes based on active tab and search text
                    let filteredNotes = filterNotes()
                    
                    if filteredNotes.isEmpty {
                        Text("No notes found")
                            .foregroundColor(.gray)
                            .padding(.top, 20)
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
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Tags section (only shown when Tags tab is active)
            if activeTab == .tags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(noteService.getAllTags(), id: \.self) { tag in
                            Button(action: {
                                searchText = tag
                            }) {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Sidebar Tab Button
    
    private func tabButton(title: String, tab: NoteTab) -> some View {
        Button(action: {
            withAnimation {
                activeTab = tab
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(activeTab == tab ? .semibold : .regular)
                .padding(.vertical, 8)
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
    
    /// Filter notes based on active tab and search text
    private func filterNotes() -> [Note] {
        // First filter by tab
        var filteredNotes: [Note]
        
        switch activeTab {
        case .all:
            filteredNotes = searchText.isEmpty ?
                noteService.notes.sorted(by: { $0.lastEditedDate > $1.lastEditedDate }) :
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
                filteredNotes = noteService.notes.sorted(by: { $0.lastEditedDate > $1.lastEditedDate })
            } else {
                filteredNotes = noteService.getNotesByTag(searchText)
            }
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
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: deleteButtonWidth, height: 80)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .opacity(showingDeleteButton ? 1 : 0)
            }
            
            // Main content
            HStack(spacing: 12) {
                // Color indicator
                Rectangle()
                    .fill(note.color.color)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title and pin button
                    HStack {
                        Text(note.title.isEmpty ? "Untitled Note" : note.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Pin button
                        Button(action: onTogglePin) {
                            Image(systemName: note.isPinned ? "pin.fill" : "pin")
                                .font(.subheadline)
                                .foregroundColor(note.isPinned ? .yellow : .gray)
                        }
                    }
                    
                    // Content preview
                    Text(note.getContentPreview())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    // Bottom row with date and tags
                    HStack {
                        // Type icon and name
                        Image(systemName: note.type.iconName)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(note.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Date
                        Text(note.formattedDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    // Tags (if any)
                    if !note.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(note.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .foregroundColor(.blue.opacity(0.8))
                                        .lineLimit(1)
                                }
                                
                                if note.tags.count > 3 {
                                    Text("+\(note.tags.count - 3)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
            .cornerRadius(12)
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

// MARK: - Previews

struct NotesView_Previews: PreviewProvider {
    static var previews: some View {
        NotesView()
            .preferredColorScheme(.dark)
    }
}
