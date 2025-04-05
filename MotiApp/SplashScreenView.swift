import SwiftUI
import AppTrackingTransparency
import FirebaseAnalytics  // Add explicit import

struct SplashScreenView: View {
    // MARK: - Properties
    
    // State for controlling view transitions
    @State private var isActive = false
    @State private var showingTrackingConsent = false
    
    // Animation properties
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    // Track whether tracking consent has been shown
    @AppStorage("hasShownTrackingConsent") private var hasShownTrackingConsent = false
    
    // MARK: - Body
    
    var body: some View {
        if isActive {
            // Main app content
            ContentView()
                .environmentObject(NotificationManager.shared)
                .fullScreenCover(isPresented: $showingTrackingConsent) {
                    TrackingConsentView()
                }
                .onAppear {
                    // Try to show tracking consent if it hasn't been shown yet
                    checkAndShowTrackingConsent()
                }
        } else {
            // Splash screen
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // App logo and title
                VStack(spacing: 20) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Moti")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Daily Motivation")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    // Start entrance animation
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                    
                    // Transition to main app after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                            
                            // Check if we need to show tracking consent
                            // after a short delay to ensure it appears properly
                            if !hasShownTrackingConsent {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    showingTrackingConsent = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check tracking status and show consent if needed
    private func checkAndShowTrackingConsent() {
        // Only check if we haven't shown consent yet
        if !hasShownTrackingConsent {
            if #available(iOS 14.0, *) {
                // Check current status without requesting
                let status = ATTrackingManager.trackingAuthorizationStatus
                
                // If status is not determined, we need to show consent
                DispatchQueue.main.async {
                    if status == .notDetermined {
                        // Slight delay to ensure the content view is fully loaded
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showingTrackingConsent = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview Provider

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
