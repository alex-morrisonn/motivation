import SwiftUI
import GoogleMobileAds
import UIKit

// An enhanced banner ad with better styling and animations
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
                                .fill(Color.black.opacity(0.1))
                        )
                        // Subtle border at the top of the banner ad
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundColor(Color.white.opacity(0.3)),
                            alignment: .top
                        )
                    
                    // Optional close button
                    if showCloseButton {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                temporarilyHidden = true
                            }
                            
                            // Show the ad again after some time
                            DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
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
                }
                .opacity(adLoaded ? 1 : 0)
                .animation(.easeIn(duration: 0.3), value: adLoaded)
                .transition(.move(edge: .bottom))
                
                // Premium upgrade suggestion
                if adManager.shouldShowBannerAd(on: screenName) && adLoaded {
                    premiumPrompt
                }
            }
        }
        .onAppear {
            // Only show close button occasionally
            showCloseButton = Int.random(in: 0...5) == 0 // 1/6 chance
        }
    }
    
    // Premium upgrade suggestion component
    private var premiumPrompt: some View {
        Button(action: {
            // Show premium upgrade options
            // For now, this is just a placeholder
        }) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                
                Text("Upgrade to Premium - Remove Ads")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Color.indigo.opacity(0.7))
            )
        }
        .padding(.top, 2)
        .padding(.bottom, 1)
    }
}

// The actual banner ad UIKit wrapper
struct BannerAdContent: UIViewRepresentable {
    var adUnitID: String
    @Binding var adLoaded: Bool
    @Binding var adHeight: CGFloat
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView()
        bannerView.adUnitID = adUnitID
        
        if #available(iOS 16.0, *) {
            // Use adaptive banner for better UI integration
            bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(UIScreen.main.bounds.width)
        } else {
            // Fallback for older iOS versions
            bannerView.adSize = GADAdSizeFromCGSize(CGSize(width: UIScreen.main.bounds.width, height: 50))
        }
        
        bannerView.rootViewController = getWindowRootViewController()
        bannerView.delegate = context.coordinator
        bannerView.load(GADRequest())
        
        return bannerView
    }
    
    func updateUIView(_ bannerView: BannerView, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        var parent: BannerAdContent
        
        init(_ parent: BannerAdContent) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Banner ad loaded successfully")
            // Update the height based on the loaded ad
            parent.adHeight = bannerView.frame.height
            
            withAnimation {
                parent.adLoaded = true
            }
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load: \(error.localizedDescription)")
            parent.adLoaded = false
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
        ZStack(alignment: .bottom) {
            self
            
            VStack(spacing: 0) {
                Spacer()
                EnhancedBannerAdView(screenName: screenName)
            }
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }
}
