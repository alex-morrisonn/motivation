import SwiftUI

/// Main view for the Mind Dump tab - redesigned for simplicity and intuitive use
struct MindDumpView: View {
    // MARK: - Properties
    
    @ObservedObject private var noteService = NoteService.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var searchText = ""
    @State private var selectedNote: Note? = nil
    @State private var showingNewNoteMenu = false
    @State private var isCreatingNote = false
    @State private var newNoteType: NoteType = .basic
    @State private var sortOption: SortOption = .lastEdited
    @State private var filterTag: String? = nil
    @State private var showingSettings = false
    
    // Animation states
    @State private var menuOffset: CGFloat = 200
    @State private var fabRotation: Double = 0
    
    // For environment adaptations
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Simplified note types
    enum NoteType {
        case basic, sketch
        
        var title: String {
            switch self {
            case .basic: return "Note"
            case .sketch: return "Sketch"
            }
        }
        
        var icon: String {
            switch self {
            case .basic: return "note.text"
            case .sketch: return "scribble"
            }
        }
        
        var modelType: Note.NoteType {
            switch self {
            case .basic: return .basic
            case .sketch: return .sketch
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
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - use theme background color
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Notes list or selected note
                    if horizontalSizeClass == .regular {
                        // For iPads - side-by-side layout
                        HStack(spacing: 0) {
                            notesList
                                .frame(width: 320)
                            
                            Divider()
                                .background(Color.themeDivider)
                            
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
                
                // Floating menu for new note types
                if showingNewNoteMenu {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            hideNewNoteMenu()
                        }
                    
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            newNoteTypeButton(type: .basic)
                            newNoteTypeButton(type: .sketch)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(Color.themeCardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 15)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80) // Space for the FAB
                    }
                }
                
                // New note FAB (Floating Action Button)
                if selectedNote == nil || horizontalSizeClass == .regular {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button(action: toggleNewNoteMenu) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.themePrimary, Color.themePrimary.opacity(0.8)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 60, height: 60)
                                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                        .rotationEffect(.degrees(fabRotation))
                                }
                            }
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                        }
                    }
                    .ignoresSafeArea(.keyboard)
                }
            }
            .sheet(isPresented: $isCreatingNote) {
                NoteEditorView(isNewNote: true, initialType: newNoteType.modelType)
                    .environmentObject(noteService)
                    .accentColor(Color.themePrimary)
            }
            .sheet(isPresented: $showingSettings) {
                NoteSettingsView()
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
                            .foregroundColor(Color.themeText)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Search button
                        Button(action: {
                            // Show search bar
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.themeText)
                        }
                        
                        // Settings button
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(Color.themeText)
                        }
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
            // Search bar with filter tags
            VStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.themeSecondaryText)
                        .padding(.leading, 12)
                    
                    TextField("Search notes...", text: $searchText)
                        .foregroundColor(Color.themeText)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.themeSecondaryText)
                        }
                        .padding(.trailing, 12)
                    }
                }
                .padding(10)
                .background(Color.themeCardBackground.opacity(0.15))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Tags scroll for filtering
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // All notes filter
                        Button(action: {
                            filterTag = nil
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "tray.fill")
                                    .font(.caption)
                                Text("All")
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(filterTag == nil ? Color.themePrimary.opacity(0.3) : Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(20)
                            .foregroundColor(filterTag == nil ? Color.themeText : Color.themeSecondaryText)
                        }
                        
                        // Tags as filters
                        ForEach(noteService.getAllTags(), id: \.self) { tag in
                            Button(action: {
                                filterTag = tag
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "tag.fill")
                                        .font(.caption)
                                    Text(tag)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(filterTag == tag ? Color.themePrimary.opacity(0.3) : Color.themeCardBackground.opacity(0.5))
                                .cornerRadius(20)
                                .foregroundColor(filterTag == tag ? Color.themeText : Color.themeSecondaryText)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.themeBackground)
            
            // Divider
            Rectangle()
                .fill(Color.themeDivider)
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
                                },
                                onDelete: {
                                    // Handle delete action
                                    withAnimation {
                                        noteService.deleteNoteWithSketch(note)
                                        // If the deleted note was selected, clear selection
                                        if selectedNote?.id == note.id {
                                            selectedNote = nil
                                        }
                                    }
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
                                
                                // Add tag menu
                                Menu {
                                    // List existing tags
                                    ForEach(noteService.getAllTags(), id: \.self) { tag in
                                        Button(action: {
                                            noteService.addTag(tag, to: note)
                                        }) {
                                            Label(tag, systemImage: "tag")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(action: {
                                        // Add new tag UI would go here
                                    }) {
                                        Label("Add New Tag...", systemImage: "plus")
                                    }
                                } label: {
                                    Label("Add Tag", systemImage: "tag")
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
                                .foregroundColor(Color.themeError)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.bottom, 80) // Extra space for FAB
                }
            }
        }
        .background(Color.themeBackground)
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
            
            if filterTag != nil && filteredNotes.isEmpty {
                // No notes with selected tag
                Image(systemName: "tag")
                    .font(.system(size: 60))
                    .foregroundColor(Color.themeSecondaryText)
                
                Text("No Notes with #\(filterTag!)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                
                Text("Notes with this tag will appear here.")
                    .font(.body)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else if !searchText.isEmpty && filteredNotes.isEmpty {
                // No search results
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(Color.themeSecondaryText)
                
                Text("No Results")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                
                Text("No notes match '\(searchText)'")
                    .font(.body)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    searchText = ""
                }) {
                    Text("Clear Search")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.themePrimary)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            } else if noteService.notes.isEmpty {
                // No notes at all
                Image(systemName: "note.text")
                    .font(.system(size: 70))
                    .foregroundColor(Color.themeSecondaryText)
                
                Text("No Notes Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                
                Text("Create your first note to get started")
                    .font(.body)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 16) {
                    Button(action: {
                        newNoteType = .basic
                        isCreatingNote = true
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: NoteType.basic.icon)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.themePrimary)
                                .cornerRadius(30)
                            
                            Text("New Note")
                                .font(.headline)
                                .foregroundColor(Color.themeText)
                        }
                    }
                    
                    Button(action: {
                        newNoteType = .sketch
                        isCreatingNote = true
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: NoteType.sketch.icon)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.themePrimary)
                                .cornerRadius(30)
                            
                            Text("New Sketch")
                                .font(.headline)
                                .foregroundColor(Color.themeText)
                        }
                    }
                }
                .padding(.top, 24)
            } else {
                // Default empty state when a note isn't selected
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 60))
                    .foregroundColor(Color.themeSecondaryText)
                
                Text("Select a Note")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.themeText)
                
                Text("Choose a note from the list or create a new one")
                    .font(.body)
                    .foregroundColor(Color.themeSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }
    
    // New note type button
    private func newNoteTypeButton(type: NoteType) -> some View {
        Button(action: {
            newNoteType = type
            isCreatingNote = true
            hideNewNoteMenu()
        }) {
            HStack(spacing: 16) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.themePrimary)
                    .cornerRadius(25)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create \(type.title)")
                        .font(.headline)
                        .foregroundColor(Color.themeText)
                    
                    Text(type == .basic ? "Text, lists, bullet points, etc." : "Draw, sketch, doodle ideas")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                }
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.themeCardBackground.opacity(0.15))
            .cornerRadius(12)
            .frame(width: min(UIScreen.main.bounds.width - 48, 400))
        }
    }
    
    // MARK: - Helper Methods
    
    // Toggle new note menu display
    private func toggleNewNoteMenu() {
        withAnimation {
            if showingNewNoteMenu {
                hideNewNoteMenu()
            } else {
                showNewNoteMenu()
            }
        }
    }
    
    // Show new note menu
    private func showNewNoteMenu() {
        menuOffset = 0
        fabRotation = 45
        showingNewNoteMenu = true
    }
    
    // Hide new note menu
    private func hideNewNoteMenu() {
        menuOffset = 200
        fabRotation = 0
        
        // Slightly delay setting the flag to false to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if menuOffset == 200 { // Only if still hiding
                showingNewNoteMenu = false
            }
        }
    }
    
    // Filter notes based on search text and tags
    private var filteredNotes: [Note] {
        var notes = noteService.notes
        
        // Apply tag filter if selected
        if let tag = filterTag {
            notes = noteService.getNotesByTag(tag)
        }
        
        // Apply search filter if text isn't empty
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.lowercased().contains(searchText.lowercased()) ||
                note.content.lowercased().contains(searchText.lowercased()) ||
                note.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
        }
        
        // Sort notes
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

/// Redesigned note card with cleaner layout and swipe-to-delete
struct NoteCard: View {
    let note: Note
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    // For swipe gesture
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    // Fixed width for delete button
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Delete button background (revealed on swipe)
            HStack {
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: deleteButtonWidth, height: 40)
                }
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .opacity(offset < 0 ? 1 : 0) // Only show when offset is negative (swiped left)
            
            // Note content
            VStack(alignment: .leading, spacing: 10) {
                // Top row with title, type icon and pin
                HStack(alignment: .top) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.title.isEmpty ? "Untitled Note" : note.title)
                            .font(.headline)
                            .foregroundColor(Color.themeText)
                            .lineLimit(1)
                        
                        // Date
                        Text(formattedDate)
                            .font(.caption2)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                    
                    Spacer()
                    
                    // Type indicator
                    Image(systemName: note.type == .sketch ? "scribble" : "doc.text")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                        .padding(6)
                        .background(Color.themeCardBackground.opacity(0.3))
                        .cornerRadius(6)
                    
                    // Pin indicator if pinned
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(Color.themeWarning)
                            .padding(.leading, 4)
                    }
                }
                
                // Preview content
                Text(note.getContentPreview(maxLength: 120))
                    .font(.subheadline)
                    .foregroundColor(Color.themeSecondaryText)
                    .lineLimit(2)
                
                // Tags if any
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.tags.prefix(3), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(Color.themePrimary.opacity(0.8))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.themePrimary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            if note.tags.count > 3 {
                                Text("+\(note.tags.count - 3)")
                                    .font(.caption)
                                    .foregroundColor(Color.themeSecondaryText)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(isSelected ? Color.themePrimary.opacity(0.15) : Color.themeCardBackground.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(note.color.rawValue).opacity(isSelected ? 0.8 : 0.4), lineWidth: isSelected ? 2 : 0)
            )
            .contentShape(Rectangle())
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow swiping left to reveal delete button
                        if value.translation.width < 0 {
                            // Limit drag to delete button width
                            self.offset = max(value.translation.width, -deleteButtonWidth)
                        } else if isSwiped {
                            // If already swiped, allow swiping back right
                            self.offset = min(0, -deleteButtonWidth + value.translation.width)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            // If swiped far enough, snap to reveal delete button
                            if value.translation.width < -deleteButtonWidth / 2 {
                                self.offset = -deleteButtonWidth
                                self.isSwiped = true
                            } else if value.translation.width > deleteButtonWidth / 2 && isSwiped {
                                // Swiped right to close
                                self.offset = 0
                                self.isSwiped = false
                            } else {
                                // Not swiped far enough, snap back
                                self.offset = isSwiped ? -deleteButtonWidth : 0
                            }
                        }
                    }
            )
            .onTapGesture {
                if isSwiped {
                    // Close the swipe action if open
                    withAnimation(.spring()) {
                        self.offset = 0
                        self.isSwiped = false
                    }
                } else {
                    // Otherwise select the note
                    onSelect()
                }
            }
        }
    }
    
    // Formatted date string for display
    private var formattedDate: String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(note.lastEditedDate) {
            // Today - show time
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: note.lastEditedDate))"
        } else if calendar.dateComponents([.day], from: note.lastEditedDate, to: now).day == 1 {
            // Yesterday
            return "Yesterday"
        } else {
            // Other dates
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: note.lastEditedDate)
        }
    }
}

/// Settings view for Mind Dump notes
struct NoteSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var noteService = NoteService.shared
    @State private var showingTagManager = false
    @State private var showingBackupOptions = false
    @State private var showingDeleteConfirmation = false
    @State private var sortOption: MindDumpView.SortOption = .lastEdited
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Organization")) {
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
                }
                
                Section(header: Text("Sort Notes")) {
                    ForEach([MindDumpView.SortOption.lastEdited, .title, .created], id: \.self) { option in
                        Button(action: {
                            sortOption = option
                        }) {
                            HStack {
                                Text(option.description)
                                
                                Spacer()
                                
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.themePrimary)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete All Notes", systemImage: "trash")
                            .foregroundColor(Color.themeError)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete All Notes"),
                    message: Text("Are you sure you want to delete all notes? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete All")) {
                        noteService.deleteAllNotes()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingTagManager) {
                TagManagementView()
            }
            .sheet(isPresented: $showingBackupOptions) {
                NotesBackupView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct MindDumpView_Previews: PreviewProvider {
    static var previews: some View {
        MindDumpView()
            .preferredColorScheme(.dark)
            .onAppear {
                // Add sample notes for preview
                if NoteService.shared.notes.isEmpty {
                    for note in Note.samples {
                        NoteService.shared.addNote(note)
                    }
                }
            }
    }
}
