import SwiftUI
import UIKit

/// Component for premium feature row
struct PremiumFeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
    }
}

/// Duration option button
struct DurationOptionButton: View {
    let duration: Int
    let videoCount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(duration)h")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? .black : .white)
                
                Text("\(videoCount) video\(videoCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.yellow : Color.white.opacity(0.1))
            )
        }
    }
}

// A view that offers premium features in exchange for watching ads
struct RewardedAdView: View {
    // MARK: - Properties
    
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // State
    @State private var isShowingAd = false
    @State private var selectedDuration = 1 // Index of selected duration
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Premium trial durations in hours
    private let trialDurations = [1, 3, 6, 12]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(red: 0.1, green: 0.05, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header with premium logo
                headerView
                
                // Duration selection
                durationSelectionView
                
                // Premium features you'll unlock
                premiumFeaturesView
                
                Spacer()
                
                // Watch ad button
                watchButtonView
                
                // Small print about premium details
                Text("Premium features will be unlocked for \(trialDurations[selectedDuration]) hour\(trialDurations[selectedDuration] > 1 ? "s" : "").")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Ad Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationBarTitle("Premium Trial", displayMode: .inline)
        .navigationBarHidden(true)
        .onAppear {
            // Preload ad on appearance
            preloadRewardedAd()
        }
    }
    
    // MARK: - Component Views
    
    // Header view with premium logo
    private var headerView: some View {
        VStack(spacing: 15) {
            // Close button
            HStack {
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.6))
                        .padding()
                }
            }
            
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
                .padding()
            
            Text("Try Premium Free")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Watch a video to unlock premium features")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }
    
    // Duration selection view
    private var durationSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SELECT DURATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
                .padding(.leading, 20)
            
            // Duration options
            HStack(spacing: 10) {
                ForEach(0..<trialDurations.count, id: \.self) { index in
                    DurationOptionButton(
                        duration: trialDurations[index],
                        videoCount: index == 0 ? 1 : index,
                        isSelected: selectedDuration == index,
                        action: {
                            withAnimation {
                                selectedDuration = index
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Premium features view
    private var premiumFeaturesView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("YOU'LL UNLOCK")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
                .padding(.leading, 20)
            
            VStack(spacing: 12) {
                // List key features with icons
                PremiumFeatureRow(icon: "xmark.circle.fill", text: "Ad-Free Experience", color: .red)
                PremiumFeatureRow(icon: "paintpalette.fill", text: "All Premium Themes", color: .purple)
                PremiumFeatureRow(icon: "rectangle.stack.fill", text: "Unlimited Notes & Todos", color: .blue)
                PremiumFeatureRow(icon: "timer", text: "Advanced Pomodoro Features", color: .orange)
                PremiumFeatureRow(icon: "square.grid.2x2", text: "Premium Widget Styles", color: .green)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    // Watch button view
    private var watchButtonView: some View {
        Button(action: {
            startRewardedAdFlow()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .padding(.trailing, 10)
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 20))
                        .padding(.trailing, 5)
                }
                
                Text("Watch Video & Unlock Premium")
                    .font(.headline)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.yellow, .orange]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
    }
    
    // MARK: - Helper Methods
    
    private func preloadRewardedAd() {
        // Simulate ad preloading
        // In a real implementation, this would call the AdManager to preload
        // a rewarded ad from AdMob, Facebook Ads, etc.
    }
    
    private func startRewardedAdFlow() {
        // Set loading state
        isLoading = true
        
        // Simulate ad loading delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Normally would show the actual rewarded ad here
            simulateAdWatching()
        }
    }
    
    private func simulateAdWatching() {
        // In a real implementation, this would show the actual rewarded ad
        // For now, we'll simulate the ad completion after a short delay
        
        // Simulate ad watching for a couple seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Calculate reward hours based on selection
            let rewardHours = trialDurations[selectedDuration]
            
            // Grant temporary premium
            // In a real implementation, this would call PremiumManager
            grantTemporaryPremium(hours: rewardHours)
            
            // Reset loading state
            isLoading = false
            
            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func grantTemporaryPremium(hours: Int) {
        // This would call PremiumManager in a real implementation
        // For now just use UserDefaults directly
        let endTime = Date().addingTimeInterval(TimeInterval(hours * 3600))
        
        UserDefaults.standard.set(true, forKey: "isPremiumUser")
        UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: "temporaryPremiumEndTime")
        
        // Post notification
        NotificationCenter.default.post(name: Notification.Name("PremiumStatusChanged"), object: nil)
    }
    
    private func handleAdError(_ error: Error) {
        isLoading = false
        errorMessage = "Unable to load video. Please try again later."
        showError = true
    }
}

// Preview
struct RewardedAdView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdView()
            .preferredColorScheme(.dark)
    }
}
