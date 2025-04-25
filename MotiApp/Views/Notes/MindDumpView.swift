import SwiftUI

/// Main view for the Mind Dump tab - fully rewritten with improved UI
struct MindDumpView: View {
    // MARK: - Properties
    
    @ObservedObject private var noteService = NoteService.shared
    @State private var searchText = ""
    @State private var selectedNote: Note? = nil
    @State private var showingNewNoteMenu = false
    @State private var showingNewNote = false
    @State private var showingSettings = false
    @State private var showingTagManager = false
    @State private var showingBackupOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var newNoteType: Note.NoteType = .basic
    @State private var sortOption: SortOption = .lastEdited
    @State private var filterMode: FilterMode = .all
    @State private var selectedTag: String? = nil
    @State private var animateNewNoteButton = false
    
    // For environment adaptations
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // Enum for filtering options
    enum FilterMode {
        case all, pinned, tagged
        
        var title: String {
            switch self {
            case .all: return "All Notes"
            case .pinned: return "Pinned"
            case .tagged: return "Tags"
            }
        }
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
        
        var icon: String {
            switch self {
            case .lastEdited: return "clock"
            case .title: return "textformat.abc"
            case .created: return "calendar"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Main content with notes list and editor
                    if horizontalSizeClass == .regular {
                        // For iPads - side-by-side layout
                        HStack(spacing: 0) {
                            notesList
                                .frame(width: 320)
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            noteEditorOrEmptyState
                        }
                    } else {
                        // For iPhones - stack layout with navigation
                        if selectedNote != nil {
                            noteEditorOrEmptyState
                        } else {
                            notesList
                        }
                    }
                }
                
                // New note FAB (Floating Action Button)
                if selectedNote == nil || horizontalSizeClass == .regular {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            newNoteButton
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                    .ignoresSafeArea(.keyboard)
                }
            }
            .sheet(isPresented: $showingNewNote) {
                NoteEditorView(isNewNote: true, initialType: newNoteType)
                    .environmentObject(noteService)
                    .accentColor(.white)
            }
            .sheet(isPresented: $showingSettings) {
                settingsMenu
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagementView()
            }
            .sheet(isPresented: $showingBackupOptions) {
                NotesBackupView()
            }
            .onChange(of: selectedNote) { oldValue, newValue in
                // Hide new note menu if note selection changes
                showingNewNoteMenu = false
            }
            .alert("Delete All Notes", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    noteService.deleteAllNotes()
                    selectedNote = nil
                }
            } message: {
                Text("Are you sure you want to delete all notes? This action cannot be undone.")
            }
            .navigationTitle("Mind Dump")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedNote != nil && horizontalSizeClass == .compact {
                        Button(action: {
                            selectedNote = nil
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Notes")
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showingSettings = true
                        }
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Components
    
    // Notes list view
    private var notesList: some View {
        VStack(spacing: 0) {
            // Search bar with filter pills
            VStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    TextField("Search notes...", text: $searchText)
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterPill(title: "All", mode: .all)
                        filterPill(title: "Pinned", mode: .pinned)
                        
                        // Tags pills
                        ForEach(noteService.getAllTags(), id: \.self) { tag in
                            tagPill(tag: tag)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }
            }
            .padding(.top, 12)
            .background(Color.black)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            // Notes list
            if filteredNotes.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredNotes) { note in
                            NoteCard(
                                note: note,
                                isSelected: selectedNote?.id == note.id,
                                onSelect: {
                                    selectedNote = note
                                }
                            )
                            .padding(.horizontal)
                            .contextMenu {
                                Button(action: {
                                    noteService.togglePinned(note)
                                }) {
                                    Label(
                                        note.isPinned ? "Unpin" : "Pin Note",
                                        systemImage: note.isPinned ? "pin.slash" : "pin"
                                    )
                                }
                                
                                Divider()
                                
                                Button(action: {
                                    noteService.deleteNote(note)
                                    if selectedNote?.id == note.id {
                                        selectedNote = nil
                                    }
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                                .foregroundColor(.red)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    .padding(.vertical, 12)
                    .padding(.bottom, 80) // Extra space for FAB
                }
            }
        }
        .background(Color.black)
    }
    
    // Note editor or empty state
    private var noteEditorOrEmptyState: some View {
        Group {
            if let note = selectedNote {
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
                emptyStateView
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if filterMode == .all && searchText.isEmpty && noteService.notes.isEmpty {
                // No notes at all
                Image(systemName: "note.text")
                    .font(.system(size: 70))
                    .foregroundColor(.gray)
                
                Text("No Notes Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Tap the + button to create your first note")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    newNoteType = .basic
                    showingNewNote = true
                }) {
                    Text("Create Note")
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            } else if filterMode == .pinned {
                // No pinned notes
                Image(systemName: "pin")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                
                Text("No Pinned Notes")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Pin your important notes to find them quickly")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else if filterMode == .tagged && selectedTag != nil {
                // No notes with selected tag
                Image(systemName: "tag")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                
                Text("No Notes with #\(selectedTag!)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add this tag to notes you want to see here")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else if !searchText.isEmpty {
                // No search results
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                
                Text("No matches for \"\(searchText)\"")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Button(action: {
                    searchText = ""
                }) {
                    Text("Clear Search")
                        .foregroundColor(.blue)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // New note floating action button
    private var newNoteButton: some View {
        ZStack {
            // Main button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingNewNoteMenu.toggle()
                    animateNewNoteButton.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                    
                    Image(systemName: showingNewNoteMenu ? "xmark" : "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(animateNewNoteButton ? 45 : 0))
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            // Menu options that appear when the button is tapped
            if showingNewNoteMenu {
                VStack(alignment: .trailing, spacing: 16) {
                    // Position the menu options above the FAB with proper spacing
                    noteTypeButton(type: .markdown, icon: "text.badge.checkmark", label: "Markdown")
                        .offset(y: -220)
                    
                    noteTypeButton(type: .bullets, icon: "list.bullet", label: "Bullets")
                        .offset(y: -170)
                    
                    noteTypeButton(type: .sketch, icon: "pencil.line", label: "Sketch")
                        .offset(y: -120)
                    
                    noteTypeButton(type: .basic, icon: "text.alignleft", label: "Basic")
                        .offset(y: -70)
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
    }
    
    // Button for creating a specific note type
    private func noteTypeButton(type: Note.NoteType, icon: String, label: String) -> some View {
        Button(action: {
            newNoteType = type
            showingNewNote = true
            
            // Close the menu after selection
            withAnimation {
                showingNewNoteMenu = false
                animateNewNoteButton = false
            }
        }) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(width: 90, alignment: .leading)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(20)
        }
    }
    
    // Filter pill for filtering notes
    private func filterPill(title: String, mode: FilterMode) -> some View {
        Button(action: {
            withAnimation {
                filterMode = mode
                selectedTag = nil
            }
        }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(filterMode == mode ? .medium : .regular)
                .foregroundColor(filterMode == mode ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    filterMode == mode ?
                        Color.blue.opacity(0.3) :
                        Color.gray.opacity(0.15)
                )
                .cornerRadius(16)
        }
    }
    
    // Tag pill for filtering by tag
    private func tagPill(tag: String) -> some View {
        Button(action: {
            withAnimation {
                filterMode = .tagged
                selectedTag = tag
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.system(size: 10))
                
                Text(tag)
                    .font(.subheadline)
            }
            .foregroundColor(selectedTag == tag ? .white : .gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                selectedTag == tag ?
                    Color.blue.opacity(0.3) :
                    Color.gray.opacity(0.15)
            )
            .cornerRadius(16)
        }
    }
    
    // Settings menu sheet
    private var settingsMenu: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        showingSettings = false
                        showingBackupOptions = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                            Text("Backup & Restore")
                        }
                    }
                    
                    Button(action: {
                        showingSettings = false
                        showingTagManager = true
                    }) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.blue)
                            Text("Manage Tags")
                        }
                    }
                }
                
                Section(header: Text("Sort Notes")) {
                    ForEach([SortOption.lastEdited, .title, .created], id: \.self) { option in
                        Button(action: {
                            sortOption = option
                        }) {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundColor(.blue)
                                
                                Text(option.description)
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingSettings = false
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete All Notes")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helper Methods
    
    /// Filter notes based on current filter mode, search text, and selected tag
    private var filteredNotes: [Note] {
        var notes: [Note]
        
        switch filterMode {
        case .all:
            notes = noteService.notes
        case .pinned:
            notes = noteService.getPinnedNotes()
        case .tagged:
            if let tag = selectedTag {
                notes = noteService.getNotesByTag(tag)
            } else {
                notes = noteService.notes
            }
        }
        
        // Apply search filter if search text isn't empty
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.lowercased().contains(searchText.lowercased()) ||
                note.content.lowercased().contains(searchText.lowercased()) ||
                note.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .lastEdited:
            return notes.sorted { $0.lastEditedDate > $1.lastEditedDate }
        case .title:
            return notes.sorted { $0.title.lowercased() < $1.title.lowercased() }
        case .created:
            return notes.sorted { $0.createdDate > $1.createdDate }
        }
    }
}

// MARK: - Supporting Views

/// Redesigned note card with cleaner layout
struct NoteCard: View {
    let note: Note
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 10) {
                // Title and pin indicator
                HStack {
                    if !note.title.isEmpty {
                        Text(note.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    } else {
                        Text("Untitled Note")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                // Preview content
                Text(note.getContentPreview(maxLength: 120))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                // Bottom row with metadata
                HStack {
                    // Note type
                    Label(note.type.rawValue, systemImage: note.type.iconName)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Date
                    Text(note.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // Tags (if any)
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.blue.opacity(0.8))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
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
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(note.color.rawValue).opacity(isSelected ? 0.8 : 0.4), lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Button Style

/// Scale button style for better touch feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// MARK: - Array Extension

/// Safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
