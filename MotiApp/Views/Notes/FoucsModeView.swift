import SwiftUI
import Combine

/// A simplified, distraction-free editor for notes
struct FocusModeView: View {
    // MARK: - Environment & Properties
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var noteService: NoteService
    
    // Note properties
    @Binding var noteContent: String
    @Binding var noteTitle: String
    let noteType: Note.NoteType
    let noteColor: Note.NoteColor
    
    // UI State
    @State private var showControls = false
    @State private var showSettings = false
    @State private var showingExitAlert = false
    @State private var showSavedIndicator = false
    @State private var timerActive = false
    @State private var timerSeconds = 0
    @State private var timerDuration = 1500 // Default: 25 minutes in seconds
    @State private var fontSize: CGFloat = 18
    @State private var backgroundColor = Color.black
    
    // Focus State
    @FocusState private var isContentFocused: Bool
    
    // Autosave
    @State private var autoSaveCancellable: AnyCancellable?
    private let saveSubject = PassthroughSubject<Void, Never>()
    
    // MARK: - Initializer
    
    init(noteContent: Binding<String>, noteTitle: Binding<String>, noteType: Note.NoteType, noteColor: Note.NoteColor) {
        self._noteContent = noteContent
        self._noteTitle = noteTitle
        self.noteType = noteType
        self.noteColor = noteColor
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundColor
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Title and content area
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Title field
                            if showControls {
                                TextField("Untitled Note", text: $noteTitle)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                                    .padding(.horizontal, 24)
                                    .padding(.bottom, 16)
                                    .onChange(of: noteTitle) { _, _ in
                                        triggerAutosave()
                                    }
                                    .transition(.opacity)
                            }
                            
                            // Content editor with appropriate styling for note type
                            contentArea
                                .frame(minHeight: geometry.size.height - 150)
                                .padding(.top, showControls ? 0 : 20)
                                .padding(.horizontal, 24)
                                .onChange(of: noteContent) { _, _ in
                                    triggerAutosave()
                                }
                        }
                        .padding(.bottom, 100) // Space for toolbar
                    }
                    
                    // Bottom toolbar (visible when controls are shown)
                    if showControls {
                        bottomToolbar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                // Settings panel overlay
                if showSettings {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSettings = false
                            }
                        }
                    
                    settingsPanel
                        .transition(.move(edge: .trailing))
                }
                
                // Fullscreen tap area to toggle controls
                if !showSettings {
                    Color.clear
                        .contentShape(Rectangle())
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showControls.toggle()
                            }
                        }
                }
                
                // Timer display when active
                if timerActive {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Text(formatTime(timerSeconds))
                                .font(.system(.title3, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(12)
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                        }
                        
                        Spacer()
                    }
                }
                
                // Save indicator
                if showSavedIndicator {
                    VStack {
                        Spacer()
                        
                        Text("Saved")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.green.opacity(0.3)))
                            .padding(.bottom, 16)
                    }
                    .transition(.opacity)
                    .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                setupAutosave()
                
                // Start with focus on the content
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isContentFocused = true
                    
                    // Show controls briefly when view appears
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showControls = true
                    }
                    
                    // Then hide after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showControls = false
                        }
                    }
                }
                
                // Set background color based on note color (subtle)
                updateBackgroundColor()
            }
            .onDisappear {
                autoSaveCancellable?.cancel()
                stopTimer()
            }
            .statusBar(hidden: true)
            .alert(isPresented: $showingExitAlert) {
                Alert(
                    title: Text("Exit Focus Mode"),
                    message: Text("Your changes have been saved. Exit focus mode?"),
                    primaryButton: .default(Text("Exit")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - Components
    
    /// Content area based on note type
    private var contentArea: some View {
        Group {
            switch noteType {
            case .markdown:
                // Markdown editor with monospaced font
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.white)
                    .focused($isContentFocused)
            case .bullets:
                // Bullets editor
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(size: fontSize))
                    .foregroundColor(.white)
                    .focused($isContentFocused)
                    .onChange(of: noteContent) { oldValue, newValue in
                        handleBulletPoints(oldValue, newValue)
                    }
            case .sketch:
                // Sketch editor with monospaced font
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(.white)
                    .focused($isContentFocused)
            case .basic:
                // Basic text editor
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(size: fontSize))
                    .foregroundColor(.white)
                    .focused($isContentFocused)
            }
        }
    }
    
    /// Bottom toolbar with minimal controls
    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            // Timer button
            toolbarButton(
                icon: timerActive ? "timer.circle.fill" : "timer.circle",
                color: timerActive ? .green : .white
            ) {
                if timerActive {
                    stopTimer()
                } else {
                    showTimerOptions()
                }
            }
            
            // Font size controls
            HStack(spacing: 8) {
                Button(action: {
                    if fontSize > 12 {
                        fontSize -= 2
                    }
                }) {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                
                Button(action: {
                    if fontSize < 28 {
                        fontSize += 2
                    }
                }) {
                    Image(systemName: "textformat.size.larger")
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
            }
            
            Spacer()
            
            // Save
            toolbarButton(icon: "arrow.down.doc", color: .white) {
                saveNote()
            }
            
            // Settings button
            toolbarButton(icon: "gearshape", color: .white) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSettings = true
                }
            }
            
            // Exit button
            toolbarButton(icon: "xmark.circle", color: .white) {
                checkAndExitFocusMode()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .edgesIgnoringSafeArea(.bottom)
        )
        .frame(height: 60)
    }
    
    /// Settings panel view
    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Focus Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSettings = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding()
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Background color section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BACKGROUND")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                colorButton(Color.black, name: "Dark")
                                colorButton(Color(red: 0.1, green: 0.1, blue: 0.2), name: "Navy")
                                colorButton(Color(red: 0.05, green: 0.15, blue: 0.05), name: "Forest")
                                colorButton(Color(red: 0.2, green: 0.05, blue: 0.15), name: "Wine")
                                colorButton(Color(red: 0.15, green: 0.15, blue: 0.15), name: "Charcoal")
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding(.top, 10)
                    
                    // Timer section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FOCUS TIMER")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                        
                        HStack(spacing: 12) {
                            timerButton(minutes: 15, label: "15m")
                            timerButton(minutes: 25, label: "25m")
                            timerButton(minutes: 30, label: "30m")
                            timerButton(minutes: 45, label: "45m")
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .frame(width: min(UIScreen.main.bounds.width * 0.8, 320))
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(.trailing, 16)
    }
    
    /// Color selection button
    private func colorButton(_ color: Color, name: String) -> some View {
        Button(action: {
            withAnimation {
                backgroundColor = color
            }
        }) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(backgroundColor == color ? Color.white : Color.clear, lineWidth: 2)
                    )
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    /// Timer button for different durations
    private func timerButton(minutes: Int, label: String) -> some View {
        let seconds = minutes * 60
        let isActive = timerActive && timerDuration == seconds
        
        return Button(action: {
            timerDuration = seconds
            startTimer()
            
            withAnimation {
                showSettings = false
            }
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .white : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isActive ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
    }
    
    /// Generic toolbar button
    private func toolbarButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Set up autosave functionality
    private func setupAutosave() {
        autoSaveCancellable = saveSubject
            .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
            .sink { _ in
                self.saveNote()
            }
    }
    
    /// Trigger autosave
    private func triggerAutosave() {
        saveSubject.send(())
    }
    
    /// Format time for display
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// Save the note
    private func saveNote() {
        // The bindings will update the original content
        
        // Show saved indicator
        withAnimation {
            showSavedIndicator = true
        }
        
        // Hide after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedIndicator = false
            }
        }
    }
    
    /// Show timer options
    private func showTimerOptions() {
        withAnimation {
            showSettings = true
        }
    }
    
    /// Start the focus timer
    private func startTimer() {
        stopTimer() // Stop any existing timer
        
        timerActive = true
        timerSeconds = timerDuration
        
        // Use a timer that fires every second
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.timerSeconds > 0 {
                self.timerSeconds -= 1
            } else {
                timer.invalidate()
                self.timerCompleted()
            }
        }
    }
    
    /// Stop the focus timer
    private func stopTimer() {
        timerActive = false
        timerSeconds = 0
    }
    
    /// Handle timer completion
    private func timerCompleted() {
        timerActive = false
        
        // Display a notification that time is up
        withAnimation {
            // Show controls
            showControls = true
        }
    }
    
    /// Update background color based on note color
    private func updateBackgroundColor() {
        switch noteColor {
        case .blue:
            backgroundColor = Color(red: 0.05, green: 0.05, blue: 0.15)
        case .purple:
            backgroundColor = Color(red: 0.1, green: 0.05, blue: 0.15)
        case .lightBlue:
            backgroundColor = Color(red: 0.05, green: 0.1, blue: 0.15)
        case .orange:
            backgroundColor = Color(red: 0.15, green: 0.05, blue: 0.05)
        case .green:
            backgroundColor = Color(red: 0.05, green: 0.15, blue: 0.05)
        case .red:
            backgroundColor = Color(red: 0.15, green: 0.05, blue: 0.1)
        }
    }
    
    /// Special handling for bullet points
    private func handleBulletPoints(_ oldValue: String, _ newValue: String) {
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
    
    /// Check for unsaved changes and exit focus mode
    private func checkAndExitFocusMode() {
        // Save before exiting
        saveNote()
        
        // Show confirmation
        showingExitAlert = true
    }
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
