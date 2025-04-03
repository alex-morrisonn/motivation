import WidgetKit
import SwiftUI

/// The main entry point for all Moti widgets
@main
struct MotiWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        // Home screen widgets
        QuoteWidget()
        
        // Lock screen widgets (iOS 16+ only)
        if #available(iOS 16.0, *) {
            CompactQuoteWidget()
        }
        
        // Debug fallback widget
        #if DEBUG
        FallbackWidget()
        #endif
    }
}

// A minimal fallback widget for debugging purposes
#if DEBUG
struct FallbackWidget: Widget {
    let kind: String = "FallbackWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteTimelineProvider()) { entry in
            ZStack {
                Color.black
                Text("Moti Widget")
                    .foregroundColor(.white)
            }
        }
        .configurationDisplayName("Moti Quote")
        .description("Daily inspirational quotes")
        .supportedFamilies([.systemSmall])
    }
}
#endif
