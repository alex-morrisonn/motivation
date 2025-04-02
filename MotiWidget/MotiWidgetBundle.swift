import WidgetKit
import SwiftUI

/// The main entry point for all Moti widgets
@main
struct MotiWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        // Daily quote widgets
        QuoteWidget()          // Standard home screen widget
        CompactQuoteWidget()   // Lock screen widget
    }
}
