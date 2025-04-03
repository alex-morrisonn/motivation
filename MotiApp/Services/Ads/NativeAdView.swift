import SwiftUI
import GoogleMobileAds
import UIKit

/// Native ad component that blends naturally with your app's content
/// Use this for in-feed ads or content breaks in scrolling views
struct NativeAdView: View {
    // MARK: - Properties
    
    @ObservedObject private var adManager = AdManager.shared
    @State private var nativeAdLoaded = false
    @State private var nativeAdHeight: CGFloat = 0
    
    // MARK: - View Body
    
    var body: some View {
        if adManager.isPremiumUser {
            EmptyView() // No ad for premium users
        } else {
            VStack {
                // Use UIViewControllerRepresentable for more reliable ad loading
                NativeAdController(
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

/// UIViewControllerRepresentable for creating native ads
/// This approach avoids context initialization issues that can occur with UIViewRepresentable
struct NativeAdController: UIViewControllerRepresentable {
    // MARK: - Properties
    
    var adUnitID: String
    @Binding var adLoaded: Bool
    @Binding var adHeight: CGFloat
    
    // MARK: - UIViewControllerRepresentable Methods
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let containerView = UIView(frame: viewController.view.bounds)
        viewController.view.addSubview(containerView)
        
        // Create ad loader
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 1
        
        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: viewController,
            adTypes: [.native],
            options: [multipleAdsOptions]
        )
        
        // Store the coordinator to maintain a strong reference
        context.coordinator.containerView = containerView
        context.coordinator.viewController = viewController
        
        adLoader.delegate = context.coordinator
        adLoader.load(Request())
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Nothing to update
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator Class
    
    class Coordinator: NSObject, AdLoaderDelegate, NativeAdDelegate {
        var parent: NativeAdController
        var containerView: UIView?
        var viewController: UIViewController?
        
        init(_ parent: NativeAdController) {
            self.parent = parent
        }
        
        // MARK: - AdLoaderDelegate methods
        
        func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
            guard let containerView = containerView else { return }
            
            // Clear existing subviews
            containerView.subviews.forEach { $0.removeFromSuperview() }
            
            // Create the native ad UI
            let nativeAdView = createNativeAdUI(with: nativeAd)
            containerView.addSubview(nativeAdView)
            
            // Set constraints
            nativeAdView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                nativeAdView.topAnchor.constraint(equalTo: containerView.topAnchor),
                nativeAdView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                nativeAdView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                nativeAdView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            // Calculate height after layout
            containerView.layoutIfNeeded()
            DispatchQueue.main.async {
                self.parent.adHeight = nativeAdView.systemLayoutSizeFitting(
                    CGSize(width: UIScreen.main.bounds.width - 40, height: UIView.layoutFittingCompressedSize.height),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                ).height
                
                self.parent.adLoaded = true
            }
        }
        
        func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
            print("Native ad failed to load: \(error.localizedDescription)")
            parent.adLoaded = false
        }
        
        // MARK: - Helper methods
        
        /// Creates a styled native ad UI
        private func createNativeAdUI(with nativeAd: NativeAd) -> UIView {
            // Create a container view
            let containerView = UIView()
            containerView.backgroundColor = .clear
            
            // Create UI elements
            let adBadge = createAdBadge()
            let iconImageView = createIconImageView()
            let headlineLabel = createHeadlineLabel()
            let bodyLabel = createBodyLabel()
            let mediaView = createMediaView()
            let callToActionButton = createCallToActionButton()
            let advertiserLabel = createAdvertiserLabel()
            
            // Add subviews
            containerView.addSubview(adBadge)
            containerView.addSubview(iconImageView)
            containerView.addSubview(headlineLabel)
            containerView.addSubview(bodyLabel)
            containerView.addSubview(mediaView)
            containerView.addSubview(callToActionButton)
            containerView.addSubview(advertiserLabel)
            
            // Set content
            headlineLabel.text = nativeAd.headline
            bodyLabel.text = nativeAd.body
            if let icon = nativeAd.icon?.image {
                iconImageView.image = icon
            }
            advertiserLabel.text = nativeAd.advertiser
            callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
            mediaView.mediaContent = nativeAd.mediaContent
            
            // Set constraints
            adBadge.translatesAutoresizingMaskIntoConstraints = false
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            headlineLabel.translatesAutoresizingMaskIntoConstraints = false
            bodyLabel.translatesAutoresizingMaskIntoConstraints = false
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            callToActionButton.translatesAutoresizingMaskIntoConstraints = false
            advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                // Ad badge
                adBadge.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                adBadge.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                adBadge.widthAnchor.constraint(equalToConstant: 24),
                adBadge.heightAnchor.constraint(equalToConstant: 16),
                
                // Icon
                iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                iconImageView.leadingAnchor.constraint(equalTo: adBadge.trailingAnchor, constant: 8),
                iconImageView.widthAnchor.constraint(equalToConstant: 40),
                iconImageView.heightAnchor.constraint(equalToConstant: 40),
                
                // Headline
                headlineLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
                headlineLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                
                // Advertiser
                advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
                advertiserLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
                advertiserLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                
                // Media view
                mediaView.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
                mediaView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                mediaView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                mediaView.heightAnchor.constraint(equalToConstant: 150),
                
                // Body
                bodyLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
                bodyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                bodyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                
                // CTA Button
                callToActionButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 8),
                callToActionButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                callToActionButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                callToActionButton.heightAnchor.constraint(equalToConstant: 44),
                callToActionButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
            ])
            
            // Set up native ad view
            let nativeAdView = createNativeAdView()
            if let nativeAdView = nativeAdView {
                // Replace containerView with nativeAdView
                for subview in containerView.subviews {
                    nativeAdView.addSubview(subview)
                }
                
                // Associate the native ad
                nativeAdView.nativeAd = nativeAd
                
                // Try setting views through key-value coding to avoid direct property access
                let viewsDict = [
                    "headline": headlineLabel,
                    "body": bodyLabel,
                    "media": mediaView,
                    "callToAction": callToActionButton,
                    "icon": iconImageView,
                    "advertiser": advertiserLabel,
                    "adBadge": adBadge
                ]
                
                for (key, view) in viewsDict {
                    // Use optional approach to avoid runtime crashes if the key doesn't exist
                    if nativeAdView.responds(to: Selector(key + "View")) {
                        nativeAdView.setValue(view, forKey: key + "View")
                    } else {
                        print("Key not found: \(key)View")
                    }
                }
                
                return nativeAdView
            }
            
            // Fallback to container view if native ad view creation fails
            return containerView
        }
        
        /// Creates a native ad view
        private func createNativeAdView() -> GoogleMobileAds.NativeAdView? {
            // Create a native ad view without a try-catch since it doesn't throw
            let nativeAdView = GoogleMobileAds.NativeAdView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 300))
            return nativeAdView
        }
        
        // MARK: - UI Component Creation
        
        private func createAdBadge() -> UILabel {
            let label = UILabel()
            label.text = "Ad"
            label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            label.textColor = .white
            label.backgroundColor = UIColor(red: 0, green: 0.4, blue: 0.8, alpha: 1)
            label.textAlignment = .center
            label.layer.cornerRadius = 2
            label.clipsToBounds = true
            return label
        }
        
        private func createIconImageView() -> UIImageView {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 4
            return imageView
        }
        
        private func createHeadlineLabel() -> UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            label.textColor = .white
            label.numberOfLines = 2
            return label
        }
        
        private func createBodyLabel() -> UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .white.withAlphaComponent(0.8)
            label.numberOfLines = 3
            return label
        }
        
        private func createMediaView() -> MediaView {
            let mediaView = MediaView()
            mediaView.contentMode = .scaleAspectFill
            return mediaView
        }
        
        private func createCallToActionButton() -> UIButton {
            let button = UIButton(type: .system)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
            button.layer.cornerRadius = 8
            return button
        }
        
        private func createAdvertiserLabel() -> UILabel {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = .gray
            return label
        }
    }
}

// MARK: - Preview Provider

struct NativeAdView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Content above native ad")
                    .foregroundColor(.white)
                    .padding()
                
                NativeAdView()
                
                Text("Content below native ad")
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}
