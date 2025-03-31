import SwiftUI
import GoogleMobileAds
import UIKit

// An enhanced banner ad with better positioning to avoid blocking navigation
struct EnhancedBannerAdView: View {
    @ObservedObject private var adManager = AdManager.shared
    @State private var adLoaded = false
    @State private var adHeight: CGFloat = 50
    @State private var showCloseButton = false
    @State private var temporarilyHidden = false
    
    let screenName: String
    let adaptiveHeight: Bool
    
    init(screenName: String, adaptiveHeight: Bool = false) {
        self.screenName = screenName
        self.adaptiveHeight = adaptiveHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !adManager.isPremiumUser && adManager.shouldShowBannerAd(on: screenName) && !temporarilyHidden {
                ZStack(alignment: .topTrailing) {
                    // Ad content
                    BannerAdContent(adUnitID: adManager.bannerAdUnitID,
                                     adLoaded: $adLoaded,
                                     adHeight: $adHeight)
                        .frame(height: adaptiveHeight ? adHeight : 50)
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.2))
                        )
                        // Subtle border at the top of the banner ad
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color.white.opacity(0.3)),
                            alignment: .top
                        )
                    
                    // Always show close button for better user control
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            temporarilyHidden = true
                        }
                        
                        // Show the ad again after 10 minutes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 600) {
                            withAnimation {
                                temporarilyHidden = false
                            }
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(5)
                    }
                }
                .opacity(adLoaded ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: adLoaded)
            }
        }
        .frame(height: adLoaded && !adManager.isPremiumUser && !temporarilyHidden ? adHeight : 0)
        .onAppear {
            // Ensure ad is loaded
            if !adLoaded {
                adLoaded = adManager.isBannerAdReady
            }
            
            // Show close button always
            showCloseButton = true
        }
    }
}

// UIViewRepresentable for BannerView from GoogleMobileAds
struct BannerAdContent: UIViewRepresentable {
    let adUnitID: String
    @Binding var adLoaded: Bool
    @Binding var adHeight: CGFloat
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        
        // Use a standard banner size approach that works across iOS versions
        let viewWidth = UIScreen.main.bounds.width
        
        // Create an adaptive banner size based on the current width
        bannerView.adSize = AdSize.init(
            size: CGSize(width: viewWidth, height: 50),
            flags: 0
        )
        
        bannerView.rootViewController = getWindowRootViewController()
        bannerView.delegate = context.coordinator
        
        // Load ad immediately
        bannerView.load(Request())
        
        return bannerView
    }
    
    func updateUIView(_ bannerView: BannerView, context: Context) {
        // If ad isn't loaded, try loading it again
        if !adLoaded {
            bannerView.load(Request())
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        var parent: BannerAdContent
        
        init(_ parent: BannerAdContent) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("Banner ad loaded successfully")
            // Update the height based on the loaded ad
            parent.adHeight = bannerView.frame.height
            
            withAnimation {
                parent.adLoaded = true
            }
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load: \(error.localizedDescription)")
            parent.adLoaded = false
            
            // Try to load again after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                bannerView.load(Request())
            }
        }
    }
    
    // Helper function to get the root view controller
    private func getWindowRootViewController() -> UIViewController? {
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first?.rootViewController
    }
}

// Extension to easily add enhanced banner ads to any view
extension View {
    func withEnhancedBannerAd(screenName: String = "Default") -> some View {
        ZStack(alignment: .top) { // Changed to top alignment
            self
            
            VStack(spacing: 0) {
                EnhancedBannerAdView(screenName: screenName)
                Spacer()
            }
        }
    }
}

// Alternative extension that positions the ad at the bottom but above the tab bar
extension View {
    func withBottomBannerAd(screenName: String = "Default", aboveTabBar: Bool = true) -> some View {
        ZStack(alignment: .bottom) {
            self
            
            VStack(spacing: 0) {
                Spacer()
                EnhancedBannerAdView(screenName: screenName)
                // Add spacing to account for tab bar if needed
                if aboveTabBar {
                    Spacer().frame(height: 49) // Default tab bar height
                }
            }
        }
    }
}
