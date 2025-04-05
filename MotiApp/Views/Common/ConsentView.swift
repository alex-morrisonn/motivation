import SwiftUI
import AppTrackingTransparency
import FirebaseAnalytics  // Add explicit import

/// A dedicated view for requesting app tracking transparency permission
struct TrackingConsentView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var adManager = AdManager.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Title
                Text("Personalize Your Experience")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Description
                Text("This identifier helps us personalize your daily quotes based on what inspires you most and improve app features you use frequently.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Privacy notes
                VStack(alignment: .leading, spacing: 16) {
                    privacyPoint(icon: "lock.shield", text: "Your data is safe and secure")
                    privacyPoint(icon: "person.crop.circle", text: "No personally identifiable information is collected")
                    privacyPoint(icon: "hand.thumbsdown", text: "You can opt out at any time in Settings")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        requestTracking()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Skip tracking but dismiss the view
                        UserDefaults.standard.set(true, forKey: "hasShownTrackingConsent")
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Not Now")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
    
    /// UI component for privacy points
    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
    
    /// Request tracking permission and dismiss the view
    private func requestTracking() {
        if #available(iOS 14.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                // Update analytics collection based on authorization status
                let isEnabled = status == .authorized
                DispatchQueue.main.async {
                    FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(isEnabled)
                    UserDefaults.standard.set(true, forKey: "hasShownTrackingConsent")
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            // For iOS versions below 14, enable analytics by default
            DispatchQueue.main.async {
                FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(true)
                UserDefaults.standard.set(true, forKey: "hasShownTrackingConsent")
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct TrackingConsentView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingConsentView()
    }
}
