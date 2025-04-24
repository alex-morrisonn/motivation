import SwiftUI
import Combine

/// A distraction-free editor for notes
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
    @State private var showingExitAlert = false
    @State private var wordCount = 0
    @State private var characterCount = 0
    @State private var autoSaveCancellable: AnyCancellable?
    @State private var showSavedIndicator = false
    @State private var timerActive = false
    @State private var timerSeconds = 0
    @State private var timerDuration = 1500 // Default: 25 minutes in seconds
    @State private var backgroundColor = Color.black
    @State private var ambientSoundOn = false
    @State private var selectedAmbientSound = "rain"
    @State private var showSettings = false
    
    // Focus State
    @FocusState private var isContentFocused: Bool
    
    // Font size adjustment
    @State private var fontSize: CGFloat = 18
    
    // Available ambient sounds
    private let ambientSounds = ["rain", "forest", "coffee", "waves", "white_noise"]
    
    // MARK: - Initializer
    
    init(noteContent: Binding<String>, noteTitle: Binding<String>, noteType: Note.NoteType, noteColor: Note.NoteColor) {
        self._noteContent = noteContent
        self._noteTitle = noteTitle
        self.noteType = noteType
        self.noteColor = noteColor
        
        // Calculate initial counts
        let content = noteContent.wrappedValue
        _wordCount = State(initialValue: content.split(separator: " ").count)
        _characterCount = State(initialValue: content.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.5), value: backgroundColor)
            
            VStack(spacing: 0) {
                // Top bar - only visible when showControls is true
                if showControls {
                    HStack {
                        // Exit button
                        Button(action: {
                            checkAndExitFocusMode()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                                .padding()
                        }
                        
                        Spacer()
                        
                        // Stats
                        HStack(spacing: 16) {
                            statsLabel(value: "\(wordCount)", label: "words")
                            statsLabel(value: "\(characterCount)", label: "chars")
                            
                            if timerActive {
                                statsLabel(value: formatTime(timerSeconds), label: "")
                            }
                        }
                        
                        Spacer()
                        
                        // Settings button
                        Button(action: {
                            withAnimation {
                                showSettings.toggle()
                            }
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .background(backgroundColor)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Title input
                if showControls {
                    TextField("Untitled Note", text: $noteTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .transition(.opacity)
                }
                
                // Content area
                contentEditor
                    .font(.system(size: fontSize))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 20)
                    .focused($isContentFocused)
                    .frame(maxWidth: 700) // Limit width for better readability
                    .frame(maxWidth: .infinity) // Center in available space
                    .onChange(of: noteContent) { oldValue, newValue in
                        updateCounts()
                        handleContentChange(oldValue, newValue)
                    }
                
                // Bottom toolbar - only visible when showControls is true
                if showControls {
                    bottomToolbar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // Tap overlay to toggle controls
            Color.clear
                .contentShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    withAnimation {
                        showControls.toggle()
                    }
                }
                .allowsHitTesting(!showSettings) // Disable when settings are shown
            
            // Settings panel
            if showSettings {
                settingsPanel
                    .transition(.move(edge: .trailing))
            }
            
            // "Saved" indicator
            if showSavedIndicator {
                Text("Saved")
                    .padding(8)
                    .background(Color.green.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            }
        }
        .onAppear {
            // Initially focus the content and show controls
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isContentFocused = true
                withAnimation {
                    showControls = true
                }
            }
            
            // Set up autosave
            setupAutosave()
            
            // Start with custom background based on note color
            updateBackgroundColor()
        }
        .onDisappear {
            // Clean up
            autoSaveCancellable?.cancel()
            
            // Stop timer if running
            if timerActive {
                stopTimer()
            }
        }
        .statusBar(hidden: true)
        .alert(isPresented: $showingExitAlert) {
            Alert(
                title: Text("Exit Focus Mode"),
                message: Text("Your changes have been saved. Do you want to exit focus mode?"),
                primaryButton: .default(Text("Exit")) {
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Content Editor
    
    @ViewBuilder
    private var contentEditor: some View {
        switch noteType {
        case .markdown:
            // Markdown editor with monospaced font
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.system(size: fontSize, design: .monospaced))
        case .bullets:
            // Bullets editor
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: noteContent) { oldValue, newValue in
                    handleBulletPoints(oldValue, newValue)
                }
        case .sketch:
            // Sketch editor with monospaced font for ASCII art
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .font(.system(size: fontSize, design: .monospaced))
        case .basic:
            // Basic text editor
            TextEditor(text: $noteContent)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Font size controls
            HStack(spacing: 15) {
                Button(action: {
                    if fontSize > 12 {
                        fontSize -= 2
                    }
                }) {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundColor(.gray)
                }
                
                Text("Aa")
                    .foregroundColor(.gray)
                
                Button(action: {
                    if fontSize < 30 {
                        fontSize += 2
                    }
                }) {
                    Image(systemName: "textformat.size.larger")
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Timer controls
            HStack(spacing: 12) {
                if timerActive {
                    Button(action: stopTimer) {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: startTimer) {
                        Image(systemName: "timer")
                            .foregroundColor(.gray)
                    }
                }
                
                // Ambient sound toggle
                Button(action: {
                    ambientSoundOn.toggle()
                    if ambientSoundOn {
                        playAmbientSound()
                    } else {
                        stopAmbientSound()
                    }
                }) {
                    Image(systemName: ambientSoundOn ? "speaker.wave.2.fill" : "speaker.slash")
                        .foregroundColor(ambientSoundOn ? .blue : .gray)
                }
            }
            
            Spacer()
            
            // Save button
            Button(action: {
                saveNote()
                showSavedFeedback()
            }) {
                Image(systemName: "arrow.down.doc")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(backgroundColor)
    }
    
    // MARK: - Settings Panel
    
    private var settingsPanel: some View {
        VStack {
            HStack {
                Spacer()
                
                // Close button
                Button(action: {
                    withAnimation {
                        showSettings = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            
            Text("Focus Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            // Theme selection
            VStack(alignment: .leading, spacing: 10) {
                Text("COLOR THEME")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        themeButton(color: Color.black, name: "Dark")
                        themeButton(color: Color(red: 0.1, green: 0.1, blue: 0.2), name: "Navy")
                        themeButton(color: Color(red: 0.05, green: 0.15, blue: 0.05), name: "Forest")
                        themeButton(color: Color(red: 0.2, green: 0.05, blue: 0.15), name: "Wine")
                        themeButton(color: Color(red: 0.15, green: 0.15, blue: 0.15), name: "Charcoal")
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding(.horizontal)
            
            // Ambient sound selection
            if ambientSoundOn {
                VStack(alignment: .leading, spacing: 10) {
                    Text("AMBIENT SOUND")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(2)
                        .padding(.top, 15)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ambientSoundButton(name: "rain", label: "Rain")
                            ambientSoundButton(name: "forest", label: "Forest")
                            ambientSoundButton(name: "coffee", label: "Café")
                            ambientSoundButton(name: "waves", label: "Waves")
                            ambientSoundButton(name: "white_noise", label: "White Noise")
                        }
                        .padding(.vertical, 5)
                    }
                }
                .padding(.horizontal)
            }
            
            // Timer section
            VStack(alignment: .leading, spacing: 10) {
                Text("FOCUS TIMER")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(2)
                    .padding(.top, 15)
                
                HStack(spacing: 15) {
                    timerButton(minutes: 15, label: "15m")
                    timerButton(minutes: 25, label: "25m")
                    timerButton(minutes: 30, label: "30m")
                    timerButton(minutes: 45, label: "45m")
                    timerButton(minutes: 60, label: "60m")
                }
                .padding(.vertical, 10)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Exit button
            Button(action: {
                checkAndExitFocusMode()
            }) {
                Text("Exit Focus Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .frame(width: 350)
        .background(Color(red: 0.12, green: 0.12, blue: 0.12).opacity(0.95))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .background(
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showSettings = false
                    }
                }
        )
    }
    
    // MARK: - Helper Views
    
    /// Stats label component
    private func statsLabel(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    /// Theme button component
    private func themeButton(color: Color, name: String) -> some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(backgroundColor == color ? Color.white : Color.clear, lineWidth: 2)
                )
                .padding(4)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onTapGesture {
            withAnimation {
                backgroundColor = color
            }
        }
    }
    
    /// Ambient sound button component
    private func ambientSoundButton(name: String, label: String) -> some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconForSound(name))
                    .foregroundColor(selectedAmbientSound == name ? .blue : .gray)
            }
            .overlay(
                Circle()
                    .stroke(selectedAmbientSound == name ? Color.blue : Color.clear, lineWidth: 2)
            )
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onTapGesture {
            selectedAmbientSound = name
            if ambientSoundOn {
                playAmbientSound()
            }
        }
    }
    
    /// Timer button component
    private func timerButton(minutes: Int, label: String) -> some View {
        let seconds = minutes * 60
        let isSelected = timerDuration == seconds
        
        return Button(action: {
            timerDuration = seconds
            if timerActive {
                stopTimer()
                startTimer()
            }
        }) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Update word and character counts
    private func updateCounts() {
        wordCount = noteContent.split(separator: " ").count
        characterCount = noteContent.count
    }
    
    /// Set up autosave with debouncing
    private func setupAutosave() {
        let autosaveSubject = PassthroughSubject<Void, Never>()
        
        autoSaveCancellable = autosaveSubject
            .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNote()
            }
        
        // Trigger initial save
        autosaveSubject.send()
    }
    
    /// Handle content changes with special handling for bullet notes
    private func handleContentChange(_ oldValue: String, _ newValue: String) {
        autoSaveCancellable?.cancel()
        let autosaveSubject = PassthroughSubject<Void, Never>()
        
        autoSaveCancellable = autosaveSubject
            .debounce(for: .seconds(2.0), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveNote()
            }
        
        autosaveSubject.send()
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
    
    /// Save the note
    private func saveNote() {
        // The binding will update the original note content, so we just need
        // to trigger a save in the parent view (which it should already do)
        
        // Just to provide visual feedback
        showSavedFeedback()
    }
    
    /// Show saved indicator briefly
    private func showSavedFeedback() {
        withAnimation {
            showSavedIndicator = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedIndicator = false
            }
        }
    }
    
    /// Format time for display
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /// Start the focus timer
    private func startTimer() {
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
        // Show alert or notification
        timerActive = false
        
        // Play sound and vibrate if enabled
        // This would require additional implementation
    }
    
    /// Play ambient sound
    private func playAmbientSound() {
        // Simplified - in a real app you would implement actual sound playback
        print("Playing ambient sound: \(selectedAmbientSound)")
        // This would require AVAudioPlayer implementation
    }
    
    /// Stop ambient sound
    private func stopAmbientSound() {
        // Simplified - in a real app you would implement actual sound stopping
        print("Stopping ambient sound")
        // This would require AVAudioPlayer implementation
    }
    
    /// Get icon for sound type
    private func iconForSound(_ sound: String) -> String {
        switch sound {
        case "rain": return "cloud.rain"
        case "forest": return "leaf"
        case "coffee": return "cup.and.saucer"
        case "waves": return "wave.3.right"
        case "white_noise": return "waveform"
        default: return "speaker.wave.2"
        }
    }
    
    /// Check for unsaved changes and exit focus mode
    private func checkAndExitFocusMode() {
        // We'll always show the exit alert, but in a real implementation
        // you might want to check for unsaved changes first
        showingExitAlert = true
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
}

// MARK: - Preview

struct FocusModeView_Previews: PreviewProvider {
    static var previews: some View {
        FocusModeView(
            noteContent: .constant("# Focus Mode\n\nThis is a test of the focus mode view. It provides a distraction-free environment for writing and note-taking.\n\n## Features\n\n- Minimal UI\n- Word count\n- Focus timer\n- Ambient sounds"),
            noteTitle: .constant("Focus Mode Test Note"),
            noteType: .markdown,
            noteColor: .blue
        )
        .environmentObject(NoteService.shared)
        .preferredColorScheme(.dark)
    }
}
