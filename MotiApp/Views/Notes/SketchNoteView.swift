import SwiftUI

/// A view for editing sketch notes with both text and drawing capabilities
struct SketchNoteView: View {
    // Note content bindings
    @Binding var textContent: String
    @Binding var sketchData: Data?
    @State private var showingCanvas = false
    @State private var showingTextEditor = true
    
    // Focus state for text editor
    @FocusState private var isTextFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Mode selector
            HStack {
                Picker("Mode", selection: $showingTextEditor) {
                    Text("Text").tag(true)
                    Text("Sketch").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // Content area - either text editor or drawing canvas
            if showingTextEditor {
                // Text editor for textual content
                TextEditor(text: $textContent)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .focused($isTextFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            } else {
                // Drawing canvas for sketches
                DrawingCanvas(canvasData: $sketchData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Focus text editor by default when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFocused = showingTextEditor
            }
        }
    }
}
