import SwiftUI
import Combine

/// Theme definition struct containing all the colors for a specific theme
struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let cardBackground: Color
    let text: Color
    let secondaryText: Color
    let divider: Color
    let success: Color
    let warning: Color
    let error: Color
    
    // Additional theme properties
    let isDark: Bool
    let buttonRadius: CGFloat
    let cardRadius: CGFloat
    
    // Preset themes
    static let midnight = AppTheme(
        id: "midnight",
        name: "Midnight",
        primary: Color.blue,
        secondary: Color.purple,
        accent: Color.blue,
        background: Color.black,
        cardBackground: Color(red: 0.12, green: 0.12, blue: 0.18),
        text: Color.white,
        secondaryText: Color.gray,
        divider: Color.white.opacity(0.3),
        success: Color.green,
        warning: Color.orange,
        error: Color.red,
        isDark: true,
        buttonRadius: 12,
        cardRadius: 16
    )
    
    static let ocean = AppTheme(
        id: "ocean",
        name: "Ocean",
        primary: Color(red: 0, green: 0.6, blue: 0.8),
        secondary: Color(red: 0, green: 0.4, blue: 0.6),
        accent: Color(red: 0, green: 0.8, blue: 1),
        background: Color(red: 0.05, green: 0.1, blue: 0.2),
        cardBackground: Color(red: 0.1, green: 0.15, blue: 0.25),
        text: Color.white,
        secondaryText: Color(white: 0.8),
        divider: Color.white.opacity(0.2),
        success: Color(red: 0.2, green: 0.8, blue: 0.4),
        warning: Color(red: 1, green: 0.7, blue: 0.2),
        error: Color(red: 1, green: 0.3, blue: 0.3),
        isDark: true,
        buttonRadius: 12,
        cardRadius: 16
    )
    
    static let sunset = AppTheme(
        id: "sunset",
        name: "Sunset",
        primary: Color(red: 0.9, green: 0.4, blue: 0.2),
        secondary: Color(red: 0.8, green: 0.2, blue: 0.2),
        accent: Color(red: 1, green: 0.6, blue: 0.2),
        background: Color(red: 0.15, green: 0.05, blue: 0.1),
        cardBackground: Color(red: 0.25, green: 0.1, blue: 0.15),
        text: Color.white,
        secondaryText: Color(white: 0.8),
        divider: Color.white.opacity(0.2),
        success: Color(red: 0.2, green: 0.8, blue: 0.4),
        warning: Color(red: 1, green: 0.7, blue: 0.2),
        error: Color(red: 1, green: 0.3, blue: 0.3),
        isDark: true,
        buttonRadius: 12,
        cardRadius: 16
    )
    
    static let forest = AppTheme(
        id: "forest",
        name: "Forest",
        primary: Color(red: 0.3, green: 0.7, blue: 0.4),
        secondary: Color(red: 0.2, green: 0.4, blue: 0.3),
        accent: Color(red: 0.4, green: 0.8, blue: 0.5),
        background: Color(red: 0.05, green: 0.12, blue: 0.08),
        cardBackground: Color(red: 0.1, green: 0.2, blue: 0.15),
        text: Color.white,
        secondaryText: Color(white: 0.8),
        divider: Color.white.opacity(0.2),
        success: Color(red: 0.2, green: 0.8, blue: 0.4),
        warning: Color(red: 0.9, green: 0.6, blue: 0.2),
        error: Color(red: 0.8, green: 0.2, blue: 0.2),
        isDark: true,
        buttonRadius: 12,
        cardRadius: 16
    )
    
    static let light = AppTheme(
        id: "light",
        name: "Light",
        primary: Color(red: 0, green: 0.5, blue: 0.9),
        secondary: Color(red: 0.2, green: 0.4, blue: 0.8),
        accent: Color(red: 0, green: 0.7, blue: 1),
        background: Color(white: 0.95),
        cardBackground: Color.white,
        text: Color.black,
        secondaryText: Color.gray,
        divider: Color.gray.opacity(0.3),
        success: Color.green,
        warning: Color.orange,
        error: Color.red,
        isDark: false,
        buttonRadius: 12,
        cardRadius: 16
    )
    
    static let allThemes: [AppTheme] = [
        .midnight,
        .ocean,
        .sunset,
        .forest,
        .light
    ]
}

/// Theme manager to handle theme selection and persistence
class ThemeManager: ObservableObject {
    // Published property for the current theme
    @Published var currentTheme: AppTheme
    
    // Key for storing theme preference
    private let themeKey = "selectedThemeId"
    
    // Singleton instance
    static let shared = ThemeManager()
    
    private init() {
        // Load saved theme or use default
        let savedThemeId = UserDefaults.standard.string(forKey: themeKey) ?? "midnight"
        
        if let savedTheme = AppTheme.allThemes.first(where: { $0.id == savedThemeId }) {
            self.currentTheme = savedTheme
        } else {
            self.currentTheme = AppTheme.midnight
        }
    }
    
    /// Set a new theme and save the preference
    func setTheme(_ theme: AppTheme) {
        self.currentTheme = theme
        UserDefaults.standard.set(theme.id, forKey: themeKey)
    }
    
    /// Get all available themes
    func getAvailableThemes() -> [AppTheme] {
        return AppTheme.allThemes
    }
}

// MARK: - Environment Key for Theme

/// Environment key for app theme
struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.midnight
}

/// Extension to add theme to the environment
extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

// MARK: - Color Extension

/// Color extension for theme-specific colors
extension Color {
    /// Primary color from the current theme
    static var themePrimary: Color {
        ThemeManager.shared.currentTheme.primary
    }
    
    /// Secondary color from the current theme
    static var themeSecondary: Color {
        ThemeManager.shared.currentTheme.secondary
    }
    
    /// Accent color from the current theme
    static var themeAccent: Color {
        ThemeManager.shared.currentTheme.accent
    }
    
    /// Background color from the current theme
    static var themeBackground: Color {
        ThemeManager.shared.currentTheme.background
    }
    
    /// Card background color from the current theme
    static var themeCardBackground: Color {
        ThemeManager.shared.currentTheme.cardBackground
    }
    
    /// Primary text color from the current theme
    static var themeText: Color {
        ThemeManager.shared.currentTheme.text
    }
    
    /// Secondary text color from the current theme
    static var themeSecondaryText: Color {
        ThemeManager.shared.currentTheme.secondaryText
    }
    
    /// Divider color from the current theme
    static var themeDivider: Color {
        ThemeManager.shared.currentTheme.divider
    }
    
    /// Success color from the current theme
    static var themeSuccess: Color {
        ThemeManager.shared.currentTheme.success
    }
    
    /// Warning color from the current theme
    static var themeWarning: Color {
        ThemeManager.shared.currentTheme.warning
    }
    
    /// Error color from the current theme
    static var themeError: Color {
        ThemeManager.shared.currentTheme.error
    }
}

// MARK: - Additional Theme Extensions

extension View {
    /// Apply theme styling to buttons
    func themeButtonStyle(foreground: Color? = nil) -> some View {
        let theme = ThemeManager.shared.currentTheme
        return self
            .foregroundColor(foreground ?? theme.text)
            .background(theme.primary)
            .cornerRadius(theme.buttonRadius)
    }
    
    /// Apply theme styling to cards
    func themeCardStyle() -> some View {
        let theme = ThemeManager.shared.currentTheme
        return self
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(theme.cardRadius)
    }
}
