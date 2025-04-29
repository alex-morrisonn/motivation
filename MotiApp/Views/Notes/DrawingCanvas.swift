import SwiftUI
import PencilKit

/// A drawing canvas view that allows users to create sketches with full screen support
struct DrawingCanvas: View {
    // Canvas state
    @Binding var canvasData: Data?
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var isFirstAppear = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas view that fills the available space
                CanvasRepresentable(canvasView: canvasView, toolPicker: toolPicker, onSaved: saveCanvas)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                
                // "Clear" button in the top right corner
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            clearCanvas()
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                    }
                    
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
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
            
            // Configure the native tool picker
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            
            // Apply dark mode styling to the tool picker
            if #available(iOS 14.0, *) {
                toolPicker.overrideUserInterfaceStyle = .dark
            }
            
            // Make canvas the first responder to receive touch events
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                _ = canvasView.becomeFirstResponder()
            }
            
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
        
        // Optimize for performance and appearance
        canvasView.isOpaque = false
        canvasView.maximumZoomScale = 3.0
        canvasView.minimumZoomScale = 1.0
        
        // Make canvas use entire available space and allow scrolling
        let screenSize = UIScreen.main.bounds.size
        canvasView.contentSize = CGSize(
            width: screenSize.width * 1.5,
            height: screenSize.height * 1.5
        )
        
        // Center the drawing area
        let contentOffset = CGPoint(
            x: (canvasView.contentSize.width - screenSize.width) / 2,
            y: (canvasView.contentSize.height - screenSize.height) / 2
        )
        canvasView.contentOffset = contentOffset
        
        // Enable bouncing for better user experience
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = true
        
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
