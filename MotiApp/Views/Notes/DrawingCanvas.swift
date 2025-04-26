import SwiftUI
import PencilKit

/// A drawing canvas view that allows users to create sketches with full screen support
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
        // Use a ZStack instead of VStack to help maximize canvas space
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Canvas - positioned to fill the entire view
                CanvasRepresentable(canvasView: canvasView, toolPicker: toolPicker, onSaved: saveCanvas)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(0)
                
                // Drawing toolbar - floating at the top
                VStack {
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
                        
                        // Line width slider with more compact design
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
                                .frame(width: 40, height: 40)
                        }
                        
                        // Clear button
                        Button(action: {
                            clearCanvas()
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    Spacer() // Push toolbar to the top
                }
                .zIndex(1) // Ensure toolbar stays on top
            }
        }
        .edgesIgnoringSafeArea(.all) // Extend to all edges
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
        canvasView.backgroundColor = .clear
        
        // Optimize for performance
        canvasView.isOpaque = false
        canvasView.maximumZoomScale = 3.0
        canvasView.minimumZoomScale = 1.0
        
        // Make canvas use entire available space
        canvasView.contentSize = UIScreen.main.bounds.size
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = true
        
        // Use full screen drawing canvas
        if let window = UIApplication.shared.windows.first {
            canvasView.contentSize = CGSize(
                width: window.frame.width,
                height: max(window.frame.height, 1000) // Ensure plenty of drawing space
            )
        }
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Not needed for basic functionality
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
