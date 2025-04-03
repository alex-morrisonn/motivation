import WidgetKit
import SwiftUI

/// The main entry point for all Moti widgets
@main
struct MotiWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        // Home screen widget
        QuoteWidget()
        
        // Inline lock screen widget only
        if #available(iOS 16.0, *) {
            InlineQuoteWidget()
        }
    }
}
