import SwiftUI
import PencilKit

/// A drawing canvas view that allows users to create sketches
struct DrawingCanvas: View {
    // Canvas state
    @Binding var canvasData: Data?
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var isFirstAppear = true
    
    // Drawing options
    @State private var selectedColor: Color = .white
    @State private var lineWidth: CGFloat = 3
    @State private var isErasing = false
    
    // Available colors
    private let colors: [Color] = [
        .white, .blue, .green, .yellow, .orange, .red, .purple
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Drawing toolbar
            HStack {
                // Color picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                    isErasing = false
                                    updateTool()
                                }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                
                Spacer(minLength: 10)
                
                // Line width slider
                VStack(alignment: .trailing) {
                    Slider(value: $lineWidth, in: 1...10) { _ in
                        updateTool()
                    }
                    .frame(width: 100)
                    
                    Text("Width: \(Int(lineWidth))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .frame(height: 30)
                    .padding(.horizontal, 10)
                
                // Eraser button
                Button(action: {
                    isErasing.toggle()
                    updateTool()
                }) {
                    Image(systemName: isErasing ? "eraser.fill" : "eraser")
                        .foregroundColor(isErasing ? .blue : .white)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                }
                
                // Clear button
                Button(action: {
                    clearCanvas()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))
            
            // Canvas
            CanvasRepresentable(canvasView: canvasView, toolPicker: toolPicker, onSaved: saveCanvas)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
        }
        .onAppear {
            setupCanvas()
        }
    }
    
    // Set up the canvas and load existing data if available
    private func setupCanvas() {
        // Only initialize once
        if isFirstAppear {
            // Load saved data if available
            if let data = canvasData {
                do {
                    canvasView.drawing = try PKDrawing(data: data)
                } catch {
                    print("Error loading canvas data: \(error.localizedDescription)")
                }
            }
            
            // Setup canvas appearance
            canvasView.backgroundColor = .clear
            canvasView.drawingPolicy = .anyInput
            
            // Set up tool picker
            toolPicker.setVisible(false, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
            
            // Initialize with default ink
            updateTool()
            
            isFirstAppear = false
        }
    }
    
    // Save canvas content as Data
    private func saveCanvas() {
        let drawing = canvasView.drawing
        self.canvasData = drawing.dataRepresentation()
    }
    
    // Clear the canvas
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
        saveCanvas()
    }
    
    // Update the ink tool based on current settings
    private func updateTool() {
        if isErasing {
            // Set up eraser
            let eraser = PKEraserTool(.vector)
            canvasView.tool = eraser
        } else {
            // Set up ink with selected color and width
            let ink = PKInkingTool(.pen, color: UIColor(selectedColor), width: lineWidth)
            canvasView.tool = ink
        }
    }
}

/// UIViewRepresentable wrapper for PKCanvasView
struct CanvasRepresentable: UIViewRepresentable {
    var canvasView: PKCanvasView
    var toolPicker: PKToolPicker
    var onSaved: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Not needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasRepresentable
        
        init(_ parent: CanvasRepresentable) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onSaved()
        }
    }
}
