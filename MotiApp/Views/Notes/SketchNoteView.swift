import SwiftUI

/// A view for editing sketch notes with both text and drawing capabilities
struct SketchNoteView: View {
    // Note content bindings
    @Binding var textContent: String
    @Binding var sketchData: Data?
    @State private var showingTextEditor = true
    
    // Focus state for text editor
    @FocusState private var isTextFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            // Use ZStack for better layout flexibility
            ZStack {
                // Mode selector at the top - always visible
                VStack(spacing: 0) {
                    HStack {
                        Picker("Mode", selection: $showingTextEditor) {
                            Text("Text").tag(true)
                            Text("Sketch").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .zIndex(2) // Keep above other content
                    
                    Spacer() // Push picker to top
                }
                .zIndex(2)
                
                // Content area - positioned to fill the entire view
                if showingTextEditor {
                    // Text editor for textual content
                    VStack(spacing: 0) {
                        // Transparent spacer to account for the picker height
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 44)
                        
                        TextEditor(text: $textContent)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .focused($isTextFocused)
                            .padding(.horizontal, 16)
                    }
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    // Drawing canvas for sketches - takes full screen except for segmented control
                    VStack(spacing: 0) {
                        // Spacer for the picker height
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 44)
                        
                        // Canvas fills remainder of screen
                        DrawingCanvas(canvasData: $sketchData)
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height - 44
                            )
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.bottom)
        }
        .ignoresSafeArea(.keyboard) // Prevent keyboard from pushing content
        .onAppear {
            // Focus text editor by default when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFocused = showingTextEditor
            }
        }
    }
}
