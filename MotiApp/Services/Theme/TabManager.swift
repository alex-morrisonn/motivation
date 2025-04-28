import SwiftUI
import UIKit

/// Manager for handling tab bar appearance updates across theme changes
class TabBarManager {
    // Singleton instance
    static let shared = TabBarManager()
    
    private init() {
        // Private initializer for singleton
    }
    
    /// Update tab bar appearance with the current theme
    func updateTabBarAppearance() {
        let theme = ThemeManager.shared.currentTheme
        
        // Create a fresh appearance instance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.background)
        
        // Configure unselected items
        appearance.stackedLayoutAppearance.normal.iconColor = theme.isDark ? UIColor.lightGray : UIColor.darkGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.isDark ? UIColor.lightGray : UIColor.darkGray
        ]
        
        // Configure selected items
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.primary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(theme.primary)
        ]
        
        // Apply to both standard and scrollEdge appearances
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Force update of UI
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let windows = windowScene.windows as? [UIWindow], let window = windows.first {
                // Force redraw of tab bar
                window.rootViewController?.view.setNeedsLayout()
            }
        }
        
        print("Tab bar appearance updated to theme: \(theme.name)")
    }
}

/// View modifier to handle tab bar theming
struct TabBarThemeModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Update tab bar on initial appearance
                TabBarManager.shared.updateTabBarAppearance()
            }
            .onChange(of: themeManager.currentTheme) { _, _ in
                // Update tab bar whenever theme changes
                TabBarManager.shared.updateTabBarAppearance()
            }
    }
}

// Extension to make the modifier easier to use
extension View {
    /// Apply this modifier to ensure tab bar updates with theme changes
    func withTabBarTheming() -> some View {
        self.modifier(TabBarThemeModifier())
    }
}
