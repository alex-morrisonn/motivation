import SwiftUI
import UIKit

/// A coordinator class to intelligently manage when to show interstitial ads
/// This helps prevent excessive ad display while maintaining good monetization
class InterstitialAdCoordinator: ObservableObject {
    // MARK: - Singleton Instance
    
    /// Shared instance for app-wide access
    static let shared = InterstitialAdCoordinator()
    
    // MARK: - Properties
    
    /// Reference to the ad manager
    @ObservedObject private var adManager = AdManager.shared
    
    /// Track number of navigation actions to determine when to show ads
    private var navigationCounter = 0
    
    /// Show ads every N navigation actions (adjustable)
    private let navigationThreshold = 5
    
    /// Track when the app was last backgrounded/foregrounded
    private var lastForegroundTime: Date?
    
    // MARK: - Initialization
    
    private init() {
        // Register for app lifecycle notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /// Call this method when navigating between screens to track potential ad opportunities
    /// - Returns: Boolean indicating if threshold was reached
    func trackNavigation() -> Bool {
        // Skip if premium user
        if adManager.isPremiumUser {
            return false
        }
        
        navigationCounter += 1
        
        // Check if we should show an ad
        if navigationCounter >= navigationThreshold {
            navigationCounter = 0
            return true
        }
        
        return false
    }
    
    /// Call this when user completes an action that warrants an interstitial
    func checkForInterstitial() {
        if trackNavigation() {
            tryShowingInterstitial()
        }
    }
    
    /// Smart ad display on app return after significant time
    func checkForReturnToAppInterstitial() {
        // Skip if premium user
        if adManager.isPremiumUser {
            return
        }
        
        guard let lastTime = lastForegroundTime else {
            lastForegroundTime = Date()
            return
        }
        
        // If app was in background for more than 10 minutes, show an ad with 40% probability
        let timeThreshold: TimeInterval = 10 * 60 // 10 minutes
        let currentTime = Date()
        
        if currentTime.timeIntervalSince(lastTime) > timeThreshold {
            // 40% chance to show ad
            if Double.random(in: 0..<1) < 0.4 {
                tryShowingInterstitial()
            }
        }
        
        lastForegroundTime = currentTime
    }
    
    /// Show interstitial when exiting certain views
    /// - Parameter viewName: The name of the view being exited
    func checkForExitInterstitial(from viewName: String) {
        // Skip if premium user
        if adManager.isPremiumUser {
            return
        }
        
        // List of views after which we might show an interstitial
        let exitAdViews = [
            "QuoteDetailsView",
            "FavoritesView",
            "CategoriesView"
        ]
        
        if exitAdViews.contains(viewName) {
            // Show with 30% probability to avoid being too intrusive
            if Double.random(in: 0..<1) < 0.3 {
                tryShowingInterstitial()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Private helper to attempt showing an interstitial
        /// Helper method to show interstitial ad that works across app and extension targets
        private func tryShowingInterstitial() {
            // Use a more robust method to get the root view controller
            func getRootViewController() -> UIViewController? {
                #if !WIDGET_EXTENSION
                // For main app, use UIApplication scenes
                return UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows
                    .filter { $0.isKeyWindow }
                    .first?.rootViewController
                #else
                // For widget extension, return nil or handle differently
                return nil
                #endif
            }
            
            // Only attempt to show ad in the main app context
            #if !WIDGET_EXTENSION
            if let rootController = getRootViewController() {
                _ = adManager.showInterstitialAd(from: rootController)
            }
            #endif
        }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidBecomeActive() {
        checkForReturnToAppInterstitial()
    }
    
    @objc private func appDidEnterBackground() {
        lastForegroundTime = Date()
    }
}

// MARK: - View Extension for Ad Tracking

/// Extension to make it easy to track navigation for ad display
extension View {
    /// Track navigation through this view for potential ad display
    /// - Returns: The modified view with ad tracking
    func trackNavigationForAds() -> some View {
        let shouldShowAd = InterstitialAdCoordinator.shared.trackNavigation()
        
        // If we should show an ad, trigger it after a short delay
        if shouldShowAd {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootController = windowScene.windows.first?.rootViewController {
                    _ = AdManager.shared.showInterstitialAd(from: rootController)
                }
            }
        }
        
        return self
    }
}
