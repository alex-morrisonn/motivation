import WidgetKit
import SwiftUI

@main
struct wdigetExtensionBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        QuoteWidget()
    }
}
