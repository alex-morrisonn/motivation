import SwiftUI
import GoogleMobileAds
import UIKit

// UIKit wrapper for GADBannerView to use in SwiftUI
struct BannerAdView: UIViewRepresentable {
    var adUnitID: String
    
    func makeUIView(context: Context) -> GADBannerView {
        // Create a banner view
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        
        // Set the ad unit ID
        banner.adUnitID = adUnitID
        
        // Set the root view controller for presenting the ad
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        
        // Load the ad
        banner.load(GADRequest())
        
        return banner
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // Nothing to update
    }
}

// A modifier to add a banner ad at the bottom of any view
struct BannerAdViewModifier: ViewModifier {
    // Use test ID for development, replace with your actual ad unit ID for production
    let adUnitID: String
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            
            BannerAdView(adUnitID: adUnitID)
                .frame(height: 50)
                // Add a subtle separator line
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.white.opacity(0.3)),
                    alignment: .top
                )
                .background(Color.black)
        }
    }
}

// Extension to make it easy to add banner ads to any view
extension View {
    func withBannerAd(adUnitID: String = "ca-app-pub-3940256099942544/2934735716") -> some View {
        self.modifier(BannerAdViewModifier(adUnitID: adUnitID))
    }
}
