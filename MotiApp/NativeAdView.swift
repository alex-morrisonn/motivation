import SwiftUI
import GoogleMobileAds
import UIKit

// Native ad component to blend with your app's content
struct NativeAdView: View {
    @ObservedObject private var adManager = AdManager.shared
    @State private var nativeAdLoaded = false
    @State private var nativeAdHeight: CGFloat = 0
    
    var body: some View {
        if adManager.isPremiumUser {
            EmptyView() // No ad for premium users
        } else {
            VStack {
                NativeAdContent(
                    adUnitID: adManager.nativeAdUnitID,
                    adLoaded: $nativeAdLoaded,
                    adHeight: $nativeAdHeight
                )
                .frame(height: nativeAdLoaded ? nativeAdHeight : 0)
                .opacity(nativeAdLoaded ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: nativeAdLoaded)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
}

// UIKit wrapper for native ad
struct NativeAdContent: UIViewRepresentable {
    var adUnitID: String
    @Binding var adLoaded: Bool
    @Binding var adHeight: CGFloat
    
    func makeUIView(context: Context) -> NativeAdView {
        // Create a custom native ad view programmatically
        let nativeAdView = createNativeAdView()
        
        // Create ad loader
        let adLoader = GADAdLoader(
            adUnitID: adUnitID,
            rootViewController: getWindowRootViewController(),
            adTypes: [.native],
            options: [
                NativeAdMediaAdLoaderOptions(),
                NativeAdViewAdOptions()
            ]
        )
        
        adLoader.delegate = context.coordinator
        adLoader.load(Request())
        
        return nativeAdView
    }
    
    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        // Nothing to update for now
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
    
    // Create a clean, programmatic native ad view
    private func createNativeAdView() -> NativeAdView {
        let nativeAdView = NativeAdView()
        
        // Main container for ad content
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(contentView)
        
        // Add constraints for content view
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor)
        ])
        
        // Build ad components
        let adBadge = createAdBadge()
        let headlineLabel = createHeadlineLabel()
        let bodyLabel = createBodyLabel()
        let mediaView = createMediaView()
        let iconView = createIconView()
        let starRatingView = createStarRatingView()
        let advertiserLabel = createAdvertiserLabel()
        let callToActionButton = createCallToActionButton()
        
        // Add components to content view
        contentView.addSubview(adBadge)
        contentView.addSubview(headlineLabel)
        contentView.addSubview(bodyLabel)
        contentView.addSubview(mediaView)
        contentView.addSubview(iconView)
        contentView.addSubview(starRatingView)
        contentView.addSubview(advertiserLabel)
        contentView.addSubview(callToActionButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Ad badge (top-left corner)
            adBadge.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            adBadge.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            adBadge.widthAnchor.constraint(equalToConstant: 20),
            adBadge.heightAnchor.constraint(equalToConstant: 16),
            
            // Icon view (left side)
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Headline (next to icon)
            headlineLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            headlineLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            // Advertiser (below headline)
            advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2),
            advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            
            // Star rating (next to advertiser)
            starRatingView.centerYAnchor.constraint(equalTo: advertiserLabel.centerYAnchor),
            starRatingView.leadingAnchor.constraint(equalTo: advertiserLabel.trailingAnchor, constant: 8),
            starRatingView.widthAnchor.constraint(equalToConstant: 80),
            starRatingView.heightAnchor.constraint(equalToConstant: 15),
            
            // Media view (below icon and headline)
            mediaView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            mediaView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            mediaView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            mediaView.heightAnchor.constraint(equalToConstant: 150),
            
            // Body text (below media)
            bodyLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            // Call to action button (bottom)
            callToActionButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 12),
            callToActionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            callToActionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            callToActionButton.heightAnchor.constraint(equalToConstant: 44),
            callToActionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
        // Store asset views
        nativeAdView.adBadgeView = adBadge
        nativeAdView.headlineView = headlineLabel
        nativeAdView.bodyView = bodyLabel
        nativeAdView.mediaView = mediaView
        nativeAdView.iconView = iconView
        nativeAdView.starRatingView = starRatingView
        nativeAdView.advertiserView = advertiserLabel
        nativeAdView.callToActionView = callToActionButton
        
        return nativeAdView
    }
    
    // MARK: - Component Builders
    
    private func createAdBadge() -> UILabel {
        let label = UILabel()
        label.text = "Ad"
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor(red: 0, green: 0.4, blue: 0.8, alpha: 1)
        label.textAlignment = .center
        label.layer.cornerRadius = 2
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createHeadlineLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createBodyLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.8)
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createMediaView() -> MediaView {
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        return mediaView
    }
    
    private func createIconView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }
    
    private func createStarRatingView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    private func createAdvertiserLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createCallToActionButton() -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NativeAdLoaderDelegate {
        var parent: NativeAdContent
        
        init(_ parent: NativeAdContent) {
            self.parent = parent
        }
        
        // MARK: - GADNativeAdLoaderDelegate methods
        
        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            // Get the native ad view
            guard let nativeAdView = getNativeAdView() else {
                print("Error: Could not get native ad view")
                return
            }
            
            // Set the headline
            if let headlineView = nativeAdView.headlineView as? UILabel {
                headlineView.text = nativeAd.headline
            }
            
            // Set the body text
            if let bodyView = nativeAdView.bodyView as? UILabel {
                bodyView.text = nativeAd.body
                bodyView.isHidden = nativeAd.body == nil
            }
            
            // Set the media content
            if let mediaView = nativeAdView.mediaView {
                mediaView.mediaContent = nativeAd.mediaContent
            }
            
            // Set the call to action
            if let callToActionView = nativeAdView.callToActionView as? UIButton {
                callToActionView.setTitle(nativeAd.callToAction, for: .normal)
                callToActionView.isHidden = nativeAd.callToAction == nil
            }
            
            // Set the icon
            if let iconView = nativeAdView.iconView as? UIImageView, let iconImage = nativeAd.icon?.image {
                iconView.image = iconImage
                iconView.isHidden = false
            } else if let iconView = nativeAdView.iconView {
                iconView.isHidden = true
            }
            
            // Set the star rating
            if let starRatingView = nativeAdView.starRatingView as? UIImageView,
               let starRating = nativeAd.starRating {
                // Create a star rating image based on the value
                starRatingView.image = createStarRatingImage(rating: starRating.doubleValue)
                starRatingView.isHidden = false
            } else if let starRatingView = nativeAdView.starRatingView {
                starRatingView.isHidden = true
            }
            
            // Set the advertiser
            if let advertiserView = nativeAdView.advertiserView as? UILabel {
                advertiserView.text = nativeAd.advertiser
                advertiserView.isHidden = nativeAd.advertiser == nil
            }
            
            // Associate the native ad with the view
            nativeAdView.nativeAd = nativeAd
            
            // Set the ad delegate
            nativeAd.delegate = self
            
            // Calculate and update height
            let fittingSize = nativeAdView.systemLayoutSizeFitting(
                CGSize(width: UIScreen.main.bounds.width - 40, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            
            DispatchQueue.main.async {
                self.parent.adHeight = fittingSize.height
                self.parent.adLoaded = true
            }
        }
        
        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            print("Native ad failed to load: \(error.localizedDescription)")
            parent.adLoaded = false
        }
        
        // Helper to get native ad view
        private func getNativeAdView() -> NativeAdView? {
            return (parent.makeUIView(context: .init(coordinator: self)) as NativeAdView)
        }
        
        // Create star rating image
        private func createStarRatingImage(rating: Double) -> UIImage? {
            // Simple implementation using a text representation
            let fullStars = Int(rating)
            let halfStar = rating.truncatingRemainder(dividingBy: 1) >= 0.5
            
            let starsLabel = UILabel()
            starsLabel.font = UIFont.systemFont(ofSize: 12)
            starsLabel.textColor = UIColor(red: 1, green: 0.8, blue: 0, alpha: 1) // Gold color
            
            var starsText = String(repeating: "★", count: fullStars)
            if halfStar {
                starsText += "½"
            }
            starsText += String(repeating: "☆", count: 5 - fullStars - (halfStar ? 1 : 0))
            
            starsLabel.text = starsText
            
            // Render to image
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 15))
            return renderer.image { ctx in
                starsLabel.drawText(in: CGRect(x: 0, y: 0, width: 80, height: 15))
            }
        }
    }
}

// MARK: - Extensions

extension Coordinator: NativeAdDelegate {
    // Handle native ad impressions and clicks
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        print("Native ad recorded impression")
    }
    
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        print("Native ad recorded click")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
        print("Native ad will present screen")
    }
    
    func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {
        print("Native ad will dismiss screen")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
        print("Native ad did dismiss screen")
    }
}

// Helper extension for UILabel
extension UILabel {
    func drawText(in rect: CGRect) {
        self.frame = rect
        self.drawHierarchy(in: rect, afterScreenUpdates: true)
    }
}

// MARK: - Preview Provider

struct NativeAdView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Content before ad")
                .padding()
            
            NativeAdView()
            
            Text("Content after ad")
                .padding()
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Usage Examples

// Example of how to use the NativeAdView in your app:
//
// struct ContentView: View {
//     var body: some View {
//         ScrollView {
//             VStack(spacing: 20) {
//                 // Your app content
//                 Text("App content above ad")
//                     .padding()
//
//                 // Native ad
//                 NativeAdView()
//
//                 // More app content
//                 Text("App content below ad")
//                     .padding()
//             }
//         }
//     }
// }
