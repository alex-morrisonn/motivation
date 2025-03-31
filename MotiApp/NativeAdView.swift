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
    
    func makeUIView(context: Context) -> GADNativeAdView {
        // Load the nib containing the native ad view
        let nativeAdView = Bundle.main.loadNibNamed(
            "NativeAdView",
            owner: nil,
            options: nil
        )?.first as? GADNativeAdView ?? GADNativeAdView()
        
        // Create ad loader
        let adLoader = GADAdLoader(
            adUnitID: adUnitID,
            rootViewController: getWindowRootViewController(),
            adTypes: [.native],
            options: nil
        )
        
        adLoader.delegate = context.coordinator
        adLoader.load(GADRequest())
        
        return nativeAdView
    }
    
    func updateUIView(_ nativeAdView: GADNativeAdView, context: Context) {
        // Nothing to update
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
    
    class Coordinator: NSObject, GADNativeAdLoaderDelegate {
        var parent: NativeAdContent
        
        init(_ parent: NativeAdContent) {
            self.parent = parent
        }
        
        func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
            // Set the native ad on the ad view
            if let nativeAdView = getNativeAdView() {
                // Set the ad's media content with its view
                if let mediaView = nativeAdView.mediaView {
                    mediaView.mediaContent = nativeAd.mediaContent
                }
                
                // Set other ad assets
                (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
                (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
                (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
                
                // Set the advertiser
                if let advertiser = nativeAd.advertiser {
                    (nativeAdView.advertiserView as? UILabel)?.text = advertiser
                    nativeAdView.advertiserView?.isHidden = false
                } else {
                    nativeAdView.advertiserView?.isHidden = true
                }
                
                // The native ad view's media view will hold the media content
                nativeAdView.mediaView?.isHidden = nativeAd.mediaContent.aspectRatio == 0
                
                // This registers the view controller that will display the native ad with
                // the native ad object. The nativeAd can be rendered through it.
                nativeAdView.nativeAd = nativeAd
                
                // Update height based on ad content
                DispatchQueue.main.async {
                    self.parent.adHeight = nativeAdView.systemLayoutSizeFitting(
                        CGSize(width: UIScreen.main.bounds.width - 32, height: 1000),
                        withHorizontalFittingPriority: .required,
                        verticalFittingPriority: .fittingSizeLevel
                    ).height
                    
                    self.parent.adLoaded = true
                }
            }
        }
        
        func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
            print("Native ad failed to load: \(error.localizedDescription)")
            parent.adLoaded = false
        }
        
        private func getNativeAdView() -> GADNativeAdView? {
            // In a real app, you would have a reference to your native ad view here
            // For this example, we'll create a simplified one programmatically
            let nativeAdView = GADNativeAdView()
            
            // Create subviews
            let headlineLabel = UILabel()
            headlineLabel.font = UIFont.boldSystemFont(ofSize: 16)
            headlineLabel.textColor = .white
            
            let bodyLabel = UILabel()
            bodyLabel.font = UIFont.systemFont(ofSize: 14)
            bodyLabel.textColor = .lightGray
            bodyLabel.numberOfLines = 2
            
            let advertiserLabel = UILabel()
            advertiserLabel.font = UIFont.systemFont(ofSize: 12)
            advertiserLabel.textColor = .gray
            
            let mediaView = GADMediaView()
            
            let callToActionButton = UIButton()
            callToActionButton.setTitleColor(.white, for: .normal)
            callToActionButton.backgroundColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
            callToActionButton.layer.cornerRadius = 6
            callToActionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            
            // Set ad view's asset views
            nativeAdView.headlineView = headlineLabel
            nativeAdView.bodyView = bodyLabel
            nativeAdView.advertiserView = advertiserLabel
            nativeAdView.mediaView = mediaView
            nativeAdView.callToActionView = callToActionButton
            
            // Add subviews to ad view
            nativeAdView.addSubview(headlineLabel)
            nativeAdView.addSubview(bodyLabel)
            nativeAdView.addSubview(advertiserLabel)
            nativeAdView.addSubview(mediaView)
            nativeAdView.addSubview(callToActionButton)
            
            // Layout constraints - simplified for example
            headlineLabel.translatesAutoresizingMaskIntoConstraints = false
            bodyLabel.translatesAutoresizingMaskIntoConstraints = false
            advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
            mediaView.translatesAutoresizingMaskIntoConstraints = false
            callToActionButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                headlineLabel.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
                headlineLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
                headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
                
                mediaView.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8),
                mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
                mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
                mediaView.heightAnchor.constraint(equalToConstant: 120),
                
                bodyLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
                bodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
                bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
                
                advertiserLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4),
                advertiserLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
                
                callToActionButton.topAnchor.constraint(equalTo: advertiserLabel.bottomAnchor, constant: 8),
                callToActionButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 8),
                callToActionButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -8),
                callToActionButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -8),
                callToActionButton.heightAnchor.constraint(equalToConstant: 40)
            ])
            
            return nativeAdView
        }
    }
}

// Usage example:
// In a list or scroll view, insert a NativeAdView after every 10 items
// struct YourListView: View {
//     var items: [YourItemType]
//
//     var body: some View {
//         List {
//             ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
//                 YourItemView(item: item)
//
//                 // Insert native ad every 10 items
//                 if (index + 1) % 10 == 0 && index < items.count - 1 {
//                     NativeAdView()
//                         .listRowInsets(EdgeInsets())
//                 }
//             }
//         }
//     }
// }
