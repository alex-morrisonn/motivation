import SwiftUI

// MARK: - Device Detection Extensions

extension UIDevice {
    /// Returns true if the current device is an iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Returns true if the current device is an iPhone
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - Responsive Container

/// A container view that creates iPhone-like layouts on iPad
/// by constraining the maximum width of content
struct ResponsiveContainer<Content: View>: View {
    var content: Content
    
    // Configuration parameters
    var maxWidth: CGFloat = 650
    var centerHorizontally: Bool = true
    var centerVertically: Bool = false
    var edgeInsets: EdgeInsets = EdgeInsets()
    
    // Initialize with content builder
    init(
        maxWidth: CGFloat = 650,
        centerHorizontally: Bool = true,
        centerVertically: Bool = false,
        edgeInsets: EdgeInsets = EdgeInsets(),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.maxWidth = maxWidth
        self.centerHorizontally = centerHorizontally
        self.centerVertically = centerVertically
        self.edgeInsets = edgeInsets
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Determine if we need to apply responsive constraints (iPad or large phone)
            let shouldConstrain = geometry.size.width > maxWidth
            
            if shouldConstrain && centerHorizontally {
                // Center the content with a max width
                HStack {
                    Spacer()
                    
                    if centerVertically {
                        VStack {
                            Spacer()
                            content
                                .frame(width: maxWidth)
                                .padding(edgeInsets)
                            Spacer()
                        }
                    } else {
                        content
                            .frame(width: maxWidth)
                            .padding(edgeInsets)
                    }
                    
                    Spacer()
                }
            } else {
                // Just apply padding on smaller screens
                content
                    .padding(edgeInsets)
            }
        }
    }
}

// MARK: - ContentSizedGeometryReader

/// A GeometryReader that doesn't force its children to expand to its own size
struct ContentSizedGeometryReader<Content: View>: View {
    var content: (CGSize) -> Content
    
    var body: some View {
        GeometryReader { geometry in
            self.content(geometry.size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply iPad-specific layout constraints to maintain iPhone-like layouts
    func adaptiveLayout(
        maxWidth: CGFloat = 650,
        centerHorizontally: Bool = true,
        centerVertically: Bool = false,
        edgeInsets: EdgeInsets = EdgeInsets()
    ) -> some View {
        ResponsiveContainer(
            maxWidth: maxWidth,
            centerHorizontally: centerHorizontally,
            centerVertically: centerVertically,
            edgeInsets: edgeInsets,
            content: { self }
        )
    }
    
    /// Helper to get responsive padding for horizontal sides
    func responsiveHorizontalPadding(_ padding: CGFloat = 20) -> some View {
        self.padding(.horizontal, UIDevice.isIPad ? min(padding * 1.2, 30) : padding)
    }
    
    /// Helper to constrain list or scroll content width on iPad
    func constrainedWidth(_ maxWidth: CGFloat = 650) -> some View {
        Group {
            if UIDevice.isIPad {
                HStack {
                    Spacer()
                    self.frame(width: maxWidth)
                    Spacer()
                }
            } else {
                self
            }
        }
    }
}
