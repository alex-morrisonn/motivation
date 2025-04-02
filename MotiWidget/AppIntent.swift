import WidgetKit
import AppIntents

/// Configuration options for the Moti widget
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Quote Widget Settings" }
    static var description: IntentDescription { "Customize your daily quote widget" }

    // Category preference
    @Parameter(title: "Favorite Category", default: "All Categories")
    var preferredCategory: String
    
    // Display preferences
    @Parameter(title: "Show Author", default: true)
    var showAuthor: Bool
    
    // Theme selection (for future use)
    @Parameter(title: "Widget Theme", default: "Dark")
    var widgetTheme: String
    
    // Initialize with defaults
    init() {}
    
    // Initialize with specific values
    init(preferredCategory: String = "All Categories",
         showAuthor: Bool = true,
         widgetTheme: String = "Dark") {
        self.preferredCategory = preferredCategory
        self.showAuthor = showAuthor
        self.widgetTheme = widgetTheme
    }
}

/// Intent for opening the app from a widget
struct OpenMotiAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Moti App"
    static var description = IntentDescription("Opens the Moti app")
    
    // Which section to navigate to
    @Parameter(title: "Section")
    var section: String
    
    init() {
        self.section = "home"
    }
    
    init(section: String) {
        self.section = section
    }
    
    func perform() async throws -> some IntentResult {
        // This intent is handled by the app through the URL scheme
        return .result()
    }
}

/// Intent for refreshing the widget content
struct RefreshQuoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Quote"
    static var description = IntentDescription("Gets a new inspirational quote")
    
    func perform() async throws -> some IntentResult {
        // Trigger a widget refresh
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Intent for toggling widget features
struct ToggleWidgetFeatureIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Feature"
    static var description = IntentDescription("Toggles a widget feature on or off")
    
    @Parameter(title: "Feature Name")
    var featureName: String
    
    @Parameter(title: "Is Enabled")
    var isEnabled: Bool
    
    init() {
        self.featureName = "calendar"
        self.isEnabled = true
    }
    
    init(featureName: String, isEnabled: Bool) {
        self.featureName = featureName
        self.isEnabled = isEnabled
    }
    
    func perform() async throws -> some IntentResult {
        // Store setting in UserDefaults
        UserDefaults.shared.set(isEnabled, forKey: "widget_feature_\(featureName)")
        
        // Refresh widgets to show changes
        WidgetCenter.shared.reloadAllTimelines()
        
        return .result()
    }
}
