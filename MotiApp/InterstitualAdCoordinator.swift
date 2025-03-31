import SwiftUI
import UIKit

// A coordinator to show interstitial ads at appropriate moments in the app
class InterstitialAdCoordinator: ObservableObject {
    static let shared = InterstitialAdCoordinator()
    
    @ObservedObject private var adManager = AdManager.shared
    
    // Track number of navigation actions to determine when to show ads
    private var navigationCounter = 0
    
    // Show ads every N navigation actions (adjustable)
    private let navigationThreshold = 5
    
    // Track when the app was last backgrounded/foregrounded
    private var lastForegroundTime: Date?
    
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
    
    // Call this method when navigating between screens
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
    
    // Call this when user completes an action
    func checkForInterstitial() {
        if trackNavigation() {
            tryShowingInterstitial()
        }
    }
    
    // Smart ad display on app return after significant time
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
    
    // Show interstitial when exiting certain views
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
    
    // Private helper to attempt showing an interstitial
    private func tryShowingInterstitial() {
        // Get the root controller to present the ad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootController = windowScene.windows.first?.rootViewController {
            
            // Try showing the ad
            _ = adManager.showInterstitialAd(from: rootController)
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidBecomeActive() {
        checkForReturnToAppInterstitial()
    }
    
    @objc private func appDidEnterBackground() {
        lastForegroundTime = Date()
    }
}

// Extension for View to easily track navigation
extension View {
    func trackNavigationForAds() -> some View {
        let shouldShowAd = InterstitialAdCoordinator.shared.trackNavigation()
        
        // If we should show an ad, trigger it
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
