import SwiftUI
import GoogleMobileAds
import UIKit

/// A centralized manager for handling all ad-related functionality
class AdManager: NSObject, ObservableObject {
    // Singleton instance
    static let shared = AdManager()
    
    // Published properties for reactivity in SwiftUI
    @Published var isBannerAdReady = false
    @Published var isInterstitialReady = false
    @Published var isRewardedAdReady = false
    
    // Premium status - could be tied to in-app purchase
    @Published var isPremiumUser = false {
        didSet {
            UserDefaults.standard.set(isPremiumUser, forKey: "isPremiumUser")
        }
    }
    
    // Ad frequency control
    private var lastInterstitialTime: Date?
    private let minInterstitialInterval: TimeInterval = 180 // 3 minutes between interstitials
    
    // Impression counter for frequency capping
    private var sessionImpressions = 0
    private let maxDailyImpressions = 10
    
    // Ad Units - TestIDs for now, replace with real IDs for production
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
    
    // Interstitial ad reference
    private var interstitialAd: InterstitialAd?
    
    // Rewarded ad reference
    private var rewardedAd: RewardedAd?
    
    // Private initializer for singleton
    private override init() {
        super.init()
        
        // Load premium status
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        
        // Load ads on initialization
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    // MARK: - Banner Ads
    
    /// Determines if a banner ad should be shown on a specific screen
    /// - Parameter screenName: The name of the screen to check
    /// - Returns: Boolean indicating if a banner should be shown
    func shouldShowBannerAd(on screenName: String) -> Bool {
        if isPremiumUser { return false }
        
        // Don't show banner on some screens for better UX
        let bannerExcludedScreens = ["AboutView", "FeedbackView", "PrivacyPolicyView",
                                     "TermsOfServiceView", "StreakCelebrationView"]
        
        return !bannerExcludedScreens.contains(screenName)
    }
    
    // MARK: - Interstitial Ads
    
    /// Loads an interstitial ad
    func loadInterstitialAd() {
        if isPremiumUser { return }
        
        let request = Request()
        InterstitialAd.load(withAdUnitID: interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                self.isInterstitialReady = false
                return
            }
            
            self.interstitialAd = ad
            self.isInterstitialReady = true
            self.interstitialAd?.fullScreenContentDelegate = self
        }
    }
    
    /// Shows an interstitial ad if conditions are met
    /// - Parameter viewController: The view controller to present the ad from
    /// - Returns: Boolean indicating if the ad was shown
    func showInterstitialAd(from viewController: UIViewController) -> Bool {
        if isPremiumUser { return false }
        
        // Check if we've shown too many ads today
        if sessionImpressions >= maxDailyImpressions {
            return false
        }
        
        // Check if enough time has passed since the last interstitial
        if let lastTime = lastInterstitialTime,
           Date().timeIntervalSince(lastTime) < minInterstitialInterval {
            return false
        }
        
        // Check if an ad is loaded
        guard let interstitialAd = interstitialAd, isInterstitialReady else {
            loadInterstitialAd()
            return false
        }
        
        // Present the ad
        interstitialAd.present(fromRootViewController: viewController)
        lastInterstitialTime = Date()
        sessionImpressions += 1
        return true
    }
    
    // MARK: - Rewarded Ads
    
    /// Loads a rewarded ad
    func loadRewardedAd() {
        let request = Request()
        RewardedAd.load(withAdUnitID: rewardedAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                self.isRewardedAdReady = false
                return
            }
            
            self.rewardedAd = ad
            self.isRewardedAdReady = true
        }
    }
    
    /// Shows a rewarded ad with completion handler for the reward
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - completion: Callback with success flag and reward amount if successful
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool, Int) -> Void) {
        guard let rewardedAd = rewardedAd else {
            loadRewardedAd()
            completion(false, 0)
            return
        }
        
        rewardedAd.present(from: viewController, userDidEarnRewardHandler: { [weak self] reward in
            guard let self = self else { return }
            
            // Get reward details
            print("User earned reward: \(reward.amount) \(reward.type)")
            
            // Pre-load the next ad
            self.loadRewardedAd()
            
            // Call completion with success and reward amount
            completion(true, reward.amount.intValue)
        })
    }
    
    // MARK: - Helper Methods
    
    /// Reset ad impression counter at the beginning of a new day
    func resetDailyImpressions() {
        sessionImpressions = 0
    }
    
    /// Activate premium mode - would be called after successful IAP
    func activatePremium() {
        isPremiumUser = true
    }
    
    /// Restore premium status from purchase history
    func restorePremium(isSuccess: Bool) {
        isPremiumUser = isSuccess
    }
}

// MARK: - FullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Reload ad after it's been shown
        if ad is InterstitialAd {
            loadInterstitialAd()
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present: \(error.localizedDescription)")
        
        // Reset ad state
        if ad is InterstitialAd {
            isInterstitialReady = false
            loadInterstitialAd()
        }
    }
}

// MARK: - UIViewController Extension for showing ads
extension UIViewController {
    func showInterstitialAd() -> Bool {
        return AdManager.shared.showInterstitialAd(from: self)
    }
    
    func showRewardedAd(completion: @escaping (Bool, Int) -> Void) {
        AdManager.shared.showRewardedAd(from: self, completion: completion)
    }
}
