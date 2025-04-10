import SwiftUI
import ObjectiveC // Add this for object identifiers

/// Helper for navigating between tabs in the app
class TabNavigationHelper {
    /// Shared instance for app-wide access
    static let shared = TabNavigationHelper()
    
    /// Subject for publishing tab selection events
    private let tabSelectionSubject = NotificationCenter.default
    
    /// Notification name for tab selection events
    private let tabSelectionNotificationName = Notification.Name("TabSelectionChanged")
    
    /// Private initializer for singleton
    private init() {}
    
    /// Switch to the specified tab index
    /// - Parameter index: The index of the tab to select
    func switchToTab(_ index: Int) {
        tabSelectionSubject.post(
            name: tabSelectionNotificationName,
            object: nil,
            userInfo: ["selectedTab": index]
        )
    }
    
    /// Add an observer to listen for tab selection changes
    /// - Parameters:
    ///   - observer: The observer object
    ///   - handler: The handler to call when tab selection changes
    func addObserver(_ observer: NSObject, handler: @escaping (Int) -> Void) {
        tabSelectionSubject.addObserver(
            observer,
            selector: #selector(TabNavigationHelper.handleTabSelectionNotification(_:)),
            name: tabSelectionNotificationName,
            object: nil
        )
        
        // Store the handler using a unique identifier for the observer
        let observerId = ObjectIdentifier(observer)
        observerHandlers[observerId] = handler
    }
    
    /// Remove an observer from listening for tab selection changes
    /// - Parameter observer: The observer to remove
    func removeObserver(_ observer: NSObject) {
        tabSelectionSubject.removeObserver(
            observer,
            name: tabSelectionNotificationName,
            object: nil
        )
        
        // Remove the handler from the map
        let observerId = ObjectIdentifier(observer)
        observerHandlers.removeValue(forKey: observerId)
    }
    
    // MARK: - Private Properties
    
    /// Map of observer identifiers to handlers
    private var observerHandlers = [ObjectIdentifier: (Int) -> Void]()
    
    // MARK: - Notification Handler
    
    @objc func handleTabSelectionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let selectedTab = userInfo["selectedTab"] as? Int else {
            return
        }
        
        // Find the handler for the observer and call it
        if let observer = notification.object as? NSObject {
            let observerId = ObjectIdentifier(observer)
            if let handler = observerHandlers[observerId] {
                handler(selectedTab)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Add a button to navigate to a specific tab
    /// - Parameters:
    ///   - tabIndex: The index of the tab to navigate to
    ///   - label: The label for the button
    /// - Returns: A button that will navigate to the specified tab
    func navigateToTab(_ tabIndex: Int, label: some View) -> some View {
        Button(action: {
            TabNavigationHelper.shared.switchToTab(tabIndex)
        }) {
            label
        }
    }
}
