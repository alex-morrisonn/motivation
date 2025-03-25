import WidgetKit
import SwiftUI

@main
struct MotiWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        QuoteWidget()
        CompactQuoteWidget()
    }
}
