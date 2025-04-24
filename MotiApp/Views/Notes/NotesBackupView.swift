import SwiftUI
import UniformTypeIdentifiers

/// View for managing note backups, export and import
struct NotesBackupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var noteService = NoteService.shared
    
    // State for UI controls
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showingExportAlert = false
    @State private var showingImportAlert = false
    @State private var importSuccess = false
    @State private var importError = false
    @State private var errorMessage = ""
    @State private var exportedData: Data?
    @State private var backupDate: Date?
    
    // UI animation states
    @State private var isAnimating = false
    @State private var showExportSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                                .padding(.bottom, 12)
                            
                            Text("Notes Backup & Export")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Keep your notes safe and portable")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                        
                        // Notes Stats
                        VStack(alignment: .leading, spacing: 16) {
                            Text("STATS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal, 4)
                            
                            HStack(spacing: 20) {
                                statsBox(
                                    value: "\(noteService.notes.count)",
                                    label: "Total Notes",
                                    icon: "note.text",
                                    iconColor: .blue
                                )
                                
                                statsBox(
                                    value: "\(noteService.getPinnedNotes().count)",
                                    label: "Pinned",
                                    icon: "pin.fill",
                                    iconColor: .yellow
                                )
                                
                                statsBox(
                                    value: "\(noteService.getAllTags().count)",
                                    label: "Tags",
                                    icon: "tag.fill",
                                    iconColor: .green
                                )
                            }
                            
                            if let date = backupDate {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.gray)
                                    
                                    Text("Last Backup: \(dateFormatter.string(from: date))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Export Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("EXPORT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal, 4)
                            
                            Button(action: {
                                prepareExport()
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.white)
                                        .frame(width: 24)
                                    
                                    Text("Export All Notes")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if isAnimating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .disabled(noteService.notes.isEmpty || isAnimating)
                            .opacity(noteService.notes.isEmpty ? 0.6 : 1)
                            
                            Text("Export your notes to a file that can be imported back into Mind Dump.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Import Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("IMPORT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal, 4)
                            
                            Button(action: {
                                isImporting = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                        .foregroundColor(.white)
                                        .frame(width: 24)
                                    
                                    Text("Import Notes")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if isAnimating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .disabled(isAnimating)
                            
                            Text("Import notes from a previously exported file. Notes will be added to your existing collection.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Reset Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("RESET")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal, 4)
                            
                            Button(action: {
                                showingExportAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    
                                    Text("Reset All Notes")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .disabled(noteService.notes.isEmpty || isAnimating)
                            .opacity(noteService.notes.isEmpty ? 0.6 : 1)
                            
                            Text("Delete all your notes. This action cannot be undone, so please export your notes first if you want to keep them.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                    }
                    .padding()
                }
                
                // Success overlay
                if showExportSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: NotesDocument(data: exportedData ?? Data()),
                contentType: .json,
                defaultFilename: "mind_dump_notes_\(dateString)"
            ) { result in
                switch result {
                case .success(let url):
                    print("Successfully exported notes to: \(url.path)")
                    showExportSuccessAndDismiss()
                    // Save the backup date
                    let now = Date()
                    backupDate = now
                    UserDefaults.standard.set(now, forKey: "lastNotesBackupDate")
                case .failure(let error):
                    print("Failed to export notes: \(error.localizedDescription)")
                }
                isAnimating = false
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                isAnimating = true
                
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importNotes(from: url)
                    }
                case .failure(let error):
                    print("Failed to import: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    importError = true
                    isAnimating = false
                }
            }
            .alert(isPresented: $showingExportAlert) {
                Alert(
                    title: Text("Reset All Notes"),
                    message: Text("Are you sure you want to delete all your notes? This action cannot be undone. Export your notes first if you want to keep them."),
                    primaryButton: .destructive(Text("Delete All")) {
                        // Delete all notes
                        noteService.deleteAllNotes()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Import Successful", isPresented: $importSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your notes have been successfully imported.")
            }
            .alert("Import Failed", isPresented: $importError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage.isEmpty ? "Failed to import notes. The file may be corrupted or in an incompatible format." : errorMessage)
            }
            .onAppear {
                // Load backup date if available
                if let date = UserDefaults.standard.object(forKey: "lastNotesBackupDate") as? Date {
                    backupDate = date
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helper Views
    
    /// Stats box component
    private func statsBox(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
    
    /// Success overlay
    private var successOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.green)
                }
                
                Text("Export Successful!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your notes have been saved")
                    .foregroundColor(.gray)
            }
            .padding(40)
            .background(Color(UIColor.systemGray6).opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 10)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
    }
    
    // MARK: - Helper Methods
    
    /// Current date as a string for filenames
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// Date formatter for display
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    /// Prepare data for export
    private func prepareExport() {
        isAnimating = true
        
        // Get data from service
        if let data = noteService.exportNotes() {
            exportedData = data
            isExporting = true
        } else {
            isAnimating = false
            errorMessage = "Failed to prepare notes for export"
            importError = true // Reusing the import error alert
        }
    }
    
    /// Import notes from a file URL
    private func importNotes(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let success = noteService.importNotes(from: data)
            
            DispatchQueue.main.async {
                isAnimating = false
                if success {
                    importSuccess = true
                } else {
                    errorMessage = "The file contains invalid note data"
                    importError = true
                }
            }
        } catch {
            DispatchQueue.main.async {
                isAnimating = false
                errorMessage = error.localizedDescription
                importError = true
            }
        }
    }
    
    /// Show export success and dismiss after delay
    private func showExportSuccessAndDismiss() {
        withAnimation {
            showExportSuccess = true
        }
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showExportSuccess = false
            }
        }
    }
}

/// Document type for file exporting
struct NotesDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            self.data = Data()
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Preview

struct NotesBackupView_Previews: PreviewProvider {
    static var previews: some View {
        NotesBackupView()
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
