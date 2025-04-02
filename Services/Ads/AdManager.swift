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
    
    /// Premium status property (always false in current version)
    /// Used for UI conditionals, but premium features are disabled
    @Published var isPremiumUser = false {
        didSet {
            // Always reset to false since premium is unavailable
            if isPremiumUser == true {
                DispatchQueue.main.async {
                    self.isPremiumUser = false
                }
                print("Premium cannot be enabled in this version")
            }
        }
    }
    
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
    let bannerAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
    let interstitialAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
    let rewardedAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
    let nativeAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
    #endif
    
    // MARK: - Initialization
    
    /// Private initializer for singleton
    private override init() {
        super.init()
        
        // Explicitly initialize banner ad state
        isBannerAdReady = true
        
        // Clear any premium settings from previous versions
        UserDefaults.standard.removeObject(forKey: "isPremiumUser")
        UserDefaults.standard.removeObject(forKey: "temporaryPremiumEndTime")
        
        // Load ads on initialization
        loadInterstitialAd()
        loadRewardedAd()
        
        print("AdManager initialized - Premium features disabled in this version")
    }
    
    // MARK: - Banner Ads
    
    /// Determines if a banner ad should be shown on a specific screen
    /// - Parameter screenName: The name of the screen to check
    /// - Returns: Boolean indicating if a banner should be shown
    func shouldShowBannerAd(on screenName: String) -> Bool {
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
    /// Note: Premium features are not available in the current version
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
            // Note: In current version, this doesn't activate premium features
            completion(true, reward.amount.intValue)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset ad impression counter at the beginning of a new day
    func resetDailyImpressions() {
        sessionImpressions = 0
        print("Daily impression counter reset")
    }
    
    // MARK: - Premium Features Management (Inactive in current version)
    
    /// Placeholder for premium activation (non-functional in current version)
    /// Premium features are coming in a future update
    func activatePremium() {
        print("Premium activation requested but feature is not available yet")
        // Premium remains disabled
    }
    
    /// Placeholder for premium restoration (non-functional in current version)
    /// Premium features are coming in a future update
    func restorePremium(isSuccess: Bool) {
        print("Premium restore requested but feature is not available yet")
        // Premium remains disabled
    }
    
    /// Ensures no temporary premium is active
    func checkTemporaryPremium() {
        // Clear any stored temporary premium end time
        UserDefaults.standard.removeObject(forKey: "temporaryPremiumEndTime")
        
        // Ensure premium is disabled
        if isPremiumUser {
            DispatchQueue.main.async {
                self.isPremiumUser = false
            }
        }
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
