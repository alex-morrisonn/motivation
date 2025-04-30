import SwiftUI
import GoogleMobileAds
import UIKit

/// A centralized manager for handling all ad-related functionality
/// This class follows the Singleton pattern for app-wide ad management
class AdManager: NSObject, ObservableObject {
    // MARK: - Singleton Instance
    
    /// Shared instance for app-wide access
    static let shared = AdManager()
    
    // MARK: - Published Properties
    
    /// Indicates whether banner ads are ready to be displayed
    @Published var isBannerAdReady = true
    
    /// Indicates whether interstitial ads are ready to be displayed
    @Published var isInterstitialReady = false
    
    /// Indicates whether rewarded ads are ready to be displayed
    @Published var isRewardedAdReady = false
    
    /// Premium status property
    @Published var isPremiumUser = false
    
    // MARK: - Private Properties
    
    /// Timestamp of the last shown interstitial ad for frequency capping
    private var lastInterstitialTime: Date?
    
    /// Minimum time interval between interstitial ads in seconds (3 minutes)
    private let minInterstitialInterval: TimeInterval = 180
    
    /// Counter for ad impressions (for frequency capping)
    private var sessionImpressions = 0
    
    /// Maximum number of ad impressions allowed per day
    private let maxDailyImpressions = 10
    
    /// Reference to loaded interstitial ad
    private var interstitialAd: InterstitialAd?
    
    /// Reference to loaded rewarded ad
    private var rewardedAd: RewardedAd?
    
    // MARK: - Ad Unit IDs
    
    /// Ad Unit IDs - Configured for test or production based on build configuration
    #if DEBUG
    let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716" // Test banner ID
    let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test interstitial ID
    let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Test rewarded ID
    let nativeAdUnitID = "ca-app-pub-3940256099942544/3986624511" // Test native ID
    #else
    // Production Ad Unit IDs - update these with your actual production IDs
    let bannerAdUnitID = "ca-app-pub-3143440761815563/8342942720"
    let interstitialAdUnitID = "ca-app-pub-3143440761815563/3510252594"
    let rewardedAdUnitID = "ca-app-pub-3143440761815563/8107500397"
    let nativeAdUnitID = "ca-app-pub-3143440761815563/3387087375"
    #endif
    
    // MARK: - Initialization
    
    /// Private initializer for singleton
    private override init() {
        super.init()
        
        // Explicitly initialize banner ad state
        isBannerAdReady = true
        
        // Load initial premium status from UserDefaults
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        
        // Only load ads if user is not premium
        if !isPremiumUser {
            // Load ads on initialization
            loadInterstitialAd()
            loadRewardedAd()
        }
        
        // Add observer for premium status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(premiumStatusChanged),
            name: Notification.Name("PremiumStatusChanged"),
            object: nil
        )
        
        print("AdManager initialized - Premium status: \(isPremiumUser)")
    }
    
    // MARK: - Observer Methods
    
    @objc private func premiumStatusChanged() {
        // Update premium status from PremiumManager
        let wasPremium = isPremiumUser
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        
        if wasPremium != isPremiumUser {
            if isPremiumUser {
                // User became premium - clean up ads
                cleanupAds()
            } else {
                // User is no longer premium - reload ads
                loadInterstitialAd()
                loadRewardedAd()
            }
            
            // Notify subscribers that premium status changed
            objectWillChange.send()
        }
    }
    
    // Clean up ads when user becomes premium
    private func cleanupAds() {
        interstitialAd = nil
        rewardedAd = nil
        isInterstitialReady = false
        isRewardedAdReady = false
    }
    
    // MARK: - Banner Ads
    
    /// Determines if a banner ad should be shown on a specific screen
    /// - Parameter screenName: The name of the screen to check
    /// - Returns: Boolean indicating if a banner should be shown
    func shouldShowBannerAd(on screenName: String) -> Bool {
        // Don't show ads to premium users
        if isPremiumUser {
            return false
        }
        
        // Don't show banner on these specific screens for better UX
        let bannerExcludedScreens = [
            "AboutView",
            "FeedbackView",
            "PrivacyPolicyView",
            "TermsOfServiceView",
            "StreakCelebrationView",
            "PremiumView"
        ]
        
        // Show banners on all other screens
        return !bannerExcludedScreens.contains(screenName)
    }
    
    // MARK: - Interstitial Ads
    
    /// Loads an interstitial ad
    func loadInterstitialAd() {
        // Don't load ads for premium users
        if isPremiumUser {
            return
        }
        
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                self.isInterstitialReady = false
                return
            }
            
            self.interstitialAd = ad
            self.isInterstitialReady = true
            self.interstitialAd?.fullScreenContentDelegate = self
            print("Interstitial ad loaded successfully")
        }
    }
    
    /// Shows an interstitial ad if conditions are met
    /// - Parameter viewController: The view controller to present the ad from
    /// - Returns: Boolean indicating if the ad was shown
    func showInterstitialAd(from viewController: UIViewController) -> Bool {
        // Skip if user is premium
        if isPremiumUser {
            return false
        }
        
        // Check if we've shown too many ads today
        if sessionImpressions >= maxDailyImpressions {
            print("Ad impression limit reached for today")
            return false
        }
        
        // Check if enough time has passed since the last interstitial
        if let lastTime = lastInterstitialTime,
           Date().timeIntervalSince(lastTime) < minInterstitialInterval {
            print("Not enough time has passed since last interstitial ad")
            return false
        }
        
        // Randomize a bit to not show ads every time conditions are met (70% chance)
        if Double.random(in: 0..<1) > 0.7 {
            print("Random chance prevented interstitial ad")
            return false
        }
        
        // Check if an ad is loaded
        guard let interstitialAd = interstitialAd, isInterstitialReady else {
            print("No interstitial ad ready, loading new one")
            loadInterstitialAd()
            return false
        }
        
        // Present the ad
        print("Showing interstitial ad")
        interstitialAd.present(from: viewController)
        lastInterstitialTime = Date()
        sessionImpressions += 1
        return true
    }
    
    // MARK: - Rewarded Ads
    
    /// Loads a rewarded ad
    func loadRewardedAd() {
        // Still load rewarded ads for premium users (they might want to extend)
        // but we could also add a check here if needed
        
        let request = Request()
        RewardedAd.load(with: rewardedAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                self.isRewardedAdReady = false
                return
            }
            
            self.rewardedAd = ad
            self.isRewardedAdReady = true
            print("Rewarded ad loaded successfully")
        }
    }
    
    /// Shows a rewarded ad with completion handler for the reward
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - completion: Callback with success flag and reward amount if successful
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool, Int) -> Void) {
        guard let rewardedAd = rewardedAd else {
            print("No rewarded ad ready, loading new one")
            loadRewardedAd()
            completion(false, 0)
            return
        }
        
        print("Showing rewarded ad")
        rewardedAd.present(from: viewController) { [weak self] in
            guard let self = self else { return }
            
            // Get reward details
            let reward = rewardedAd.adReward
            print("User earned reward: \(reward.amount) \(reward.type)")
            
            // Pre-load the next ad
            self.loadRewardedAd()
            
            // Call completion with success and reward amount
            completion(true, reward.amount.intValue)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset ad impression counter at the beginning of a new day
    func resetDailyImpressions() {
        sessionImpressions = 0
        print("Daily impression counter reset")
    }
}

// MARK: - FullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Reload ad after it's been shown
        if ad is InterstitialAd {
            print("Interstitial ad dismissed, loading next one")
            loadInterstitialAd()
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        
        // Reset ad state
        if ad is InterstitialAd {
            isInterstitialReady = false
            print("Interstitial ad failed, reloading")
            loadInterstitialAd()
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad will present full screen content")
    }
}

// MARK: - UIViewController Extension for showing ads
extension UIViewController {
    /// Convenience method to show an interstitial ad from any view controller
    /// - Returns: Boolean indicating if the ad was shown
    func showInterstitialAd() -> Bool {
        return AdManager.shared.showInterstitialAd(from: self)
    }
    
    /// Convenience method to show a rewarded ad from any view controller
    /// - Parameter completion: Callback with success flag and reward amount
    func showRewardedAd(completion: @escaping (Bool, Int) -> Void) {
        AdManager.shared.showRewardedAd(from: self, completion: completion)
    }
}
