import SwiftUI

/// View for editing tags on a note
struct TagEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var tags: [String]
    @State private var newTagText = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Tag input field
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(.blue)
                            .padding(.leading, 8)
                        
                        TextField("Add a new tag...", text: $newTagText)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .padding(.trailing, 8)
                        }
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Current tags section
                    VStack(alignment: .leading, spacing: 12) {
                        if tags.isEmpty {
                            Text("No tags yet")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("CURRENT TAGS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal)
                            
                            // Use the FlowingTags component to display tags
                            FlowingTags(tags: tags) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                    
                                    Button(action: {
                                        removeTag(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    // Tag tips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tag Tips:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TagTip(icon: "tag", text: "Keep tags short and descriptive")
                        TagTip(icon: "number", text: "Use single words without spaces")
                        TagTip(icon: "folder", text: "Tags help organize related notes")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Invalid Tag"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    
    /// Add a new tag
    private func addTag() {
        // Clean up the tag (lowercase, trim whitespace)
        let cleanedTag = newTagText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate tag
        if cleanedTag.isEmpty {
            errorMessage = "Tag cannot be empty"
            showingError = true
            return
        }
        
        if cleanedTag.contains(" ") {
            errorMessage = "Tags cannot contain spaces"
            showingError = true
            return
        }
        
        if tags.contains(cleanedTag) {
            errorMessage = "This tag already exists"
            showingError = true
            return
        }
        
        if cleanedTag.count > 20 {
            errorMessage = "Tag is too long (20 characters max)"
            showingError = true
            return
        }
        
        // Add the tag
        withAnimation {
            tags.append(cleanedTag)
            newTagText = ""
        }
    }
    
    /// Remove a tag
    private func removeTag(_ tag: String) {
        withAnimation {
            tags.removeAll { $0 == tag }
        }
    }
}

/// Helper view for tag tips
struct TagTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}
