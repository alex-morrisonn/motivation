import SwiftUI
import AppTrackingTransparency
import FirebaseAnalytics

struct TrackingConsentView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Icon - using a neutral icon
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Title - neutral language
                Text("About App Tracking")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Description - neutral explanation
                Text("This app uses device identifiers to measure app usage and improve your experience. On the next screen, you can choose whether to allow tracking.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Privacy notes - neutral information
                VStack(alignment: .leading, spacing: 16) {
                    privacyPoint(icon: "lock.shield", text: "Your data is handled according to our privacy policy")
                    privacyPoint(icon: "person.crop.circle", text: "You can change this setting anytime in your device settings")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // ONLY ONE button that leads directly to system prompt
                Button(action: {
                    proceedToSystemPrompt()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
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
    
    /// Proceed directly to system prompt - no way to skip
    private func proceedToSystemPrompt() {
        if #available(iOS 14.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                // Update analytics based on user's choice
                let isEnabled = status == .authorized
                DispatchQueue.main.async {
                    FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(isEnabled)
                    // Mark that we've shown the consent view
                    UserDefaults.standard.set(true, forKey: "hasShownTrackingConsent")
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        } else {
            // For iOS versions below 14, handle appropriately
            DispatchQueue.main.async {
                FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(true)
                UserDefaults.standard.set(true, forKey: "hasShownTrackingConsent")
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
