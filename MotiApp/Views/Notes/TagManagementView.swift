import SwiftUI

/// View for managing and exploring tags across all notes
struct TagManagementView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var noteService = NoteService.shared
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false
    @State private var tagToDelete: String? = nil
    @State private var newTagName = ""
    @State private var tagToRename: String? = nil
    @State private var showingRenameAlert = false
    @State private var selectedTag: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                        
                        TextField("Search tags...", text: $searchText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
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
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    
                    // Tag stats
                    VStack(alignment: .leading, spacing: 5) {
                        Text("TAGS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(2)
                            .padding(.horizontal, 16)
                        
                        Text("\(filteredTags.count) tags across \(noteService.notes.count) notes")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                    }
                    
                    // Tags list
                    if filteredTags.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            if searchText.isEmpty {
                                // No tags at all
                                Image(systemName: "tag")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                    .padding()
                                
                                Text("No Tags Yet")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Start adding tags to your notes to organize them better.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            } else {
                                // No search results
                                Text("No tags matching \"\(searchText)\"")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    searchText = ""
                                }) {
                                    Text("Clear Search")
                                        .foregroundColor(.blue)
                                        .padding(.top, 8)
                                }
                            }
                            
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredTags, id: \.self) { tag in
                                    TagRow(
                                        tag: tag,
                                        notesCount: countNotesWithTag(tag),
                                        isSelected: selectedTag == tag,
                                        onSelect: {
                                            // Toggle selection
                                            if selectedTag == tag {
                                                selectedTag = nil
                                            } else {
                                                selectedTag = tag
                                            }
                                        },
                                        onRename: {
                                            tagToRename = tag
                                            newTagName = tag
                                            showingRenameAlert = true
                                        },
                                        onDelete: {
                                            tagToDelete = tag
                                            showingDeleteConfirmation = true
                                        }
                                    )
                                    .padding(.horizontal)
                                    
                                    // If tag is selected, show notes with this tag
                                    if selectedTag == tag {
                                        TaggedNotesView(tag: tag)
                                            .padding(.leading, 46)
                                            .padding(.trailing, 8)
                                            .padding(.vertical, 8)
                                            .transition(.opacity)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .navigationBarTitle("Manage Tags", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Tag"),
                    message: Text("Are you sure you want to remove the tag \"\(tagToDelete ?? "")\" from all notes? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let tag = tagToDelete {
                            deleteTag(tag)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Rename Tag", isPresented: $showingRenameAlert) {
                TextField("New name", text: $newTagName)
                    .foregroundColor(.black)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button("Cancel", role: .cancel) { }
                Button("Rename") {
                    if let oldTag = tagToRename, !newTagName.isEmpty {
                        renameTag(from: oldTag, to: newTagName)
                    }
                }
            } message: {
                Text("Enter a new name for this tag")
            }
        }
        .preferredColorScheme(.dark)
        .accentColor(.white)
    }
    
    /// Filtered tags based on search term
    private var filteredTags: [String] {
        let allTags = noteService.getAllTags()
        
        if searchText.isEmpty {
            return allTags
        } else {
            return allTags.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    /// Count notes that have the specified tag
    private func countNotesWithTag(_ tag: String) -> Int {
        return noteService.notes.filter { $0.tags.contains(tag) }.count
    }
    
    /// Delete a tag from all notes
    private func deleteTag(_ tag: String) {
        // Find all notes with this tag
        let notesWithTag = noteService.notes.filter { $0.tags.contains(tag) }
        
        // Remove tag from each note
        for note in notesWithTag {
            noteService.removeTag(tag, from: note)
        }
    }
    
    /// Rename a tag across all notes
    private func renameTag(from oldTag: String, to newTag: String) {
        // Don't proceed if new tag is empty or already exists
        guard !newTag.isEmpty else { return }
        
        // Clean the new tag (lowercase, remove spaces)
        let cleanedNewTag = newTag.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find all notes with the old tag
        let notesWithTag = noteService.notes.filter { $0.tags.contains(oldTag) }
        
        // Update each note
        for note in notesWithTag {
            if let index = noteService.notes.firstIndex(where: { $0.id == note.id }) {
                // Remove old tag
                var updatedTags = noteService.notes[index].tags.filter { $0 != oldTag }
                
                // Add new tag if it doesn't already exist
                if !updatedTags.contains(cleanedNewTag) {
                    updatedTags.append(cleanedNewTag)
                }
                
                // Update the note
                noteService.notes[index].tags = updatedTags
                noteService.notes[index].lastEditedDate = Date()
            }
        }
        
        // Trigger save
        noteService.triggerAutosave()
        
        // Update selected tag if it was the renamed one
        if selectedTag == oldTag {
            selectedTag = cleanedNewTag
        }
    }
}

/// Single row for displaying tag information
struct TagRow: View {
    let tag: String
    let notesCount: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                // Tag indicator
                Image(systemName: "tag.fill")
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                // Tag name and count
                VStack(alignment: .leading, spacing: 4) {
                    Text("#\(tag)")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("\(notesCount) note\(notesCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Expand/collapse icon
                if isSelected {
                    Image(systemName: "chevron.up")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Menu for actions
                Menu {
                    Button(action: onRename) {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
        }
    }
}

/// View that shows notes with a specific tag
struct TaggedNotesView: View {
    let tag: String
    @ObservedObject private var noteService = NoteService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES WITH THIS TAG")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            
            // List of notes with this tag
            ForEach(notesWithTag) { note in
                NavigationLink(destination:
                    NoteEditorView(note: note)
                        .environmentObject(noteService)
                ) {
                    MiniNoteRow(note: note)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    /// Notes that have this tag
    private var notesWithTag: [Note] {
        return noteService.notes.filter { $0.tags.contains(tag) }
            .sorted(by: { $0.lastEditedDate > $1.lastEditedDate })
    }
}

/// Compact row for displaying a note preview
struct MiniNoteRow: View {
    let note: Note
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Rectangle()
                .fill(note.color.color)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Content preview
                Text(note.getContentPreview(maxLength: 60))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Date
            Text(note.formattedDate)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct TagManagementView_Previews: PreviewProvider {
    static var previews: some View {
        TagManagementView()
            .preferredColorScheme(.dark)
            .onAppear {
                // Add sample notes with tags for preview
                if NoteService.shared.notes.isEmpty {
                    let notes = Note.samples
                    for note in notes {
                        NoteService.shared.addNote(note)
                    }
                }
            }
    }
}
