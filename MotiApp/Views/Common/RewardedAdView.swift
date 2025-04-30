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
    @ObservedObject private var premiumManager = PremiumManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // State
    @State private var isShowingAd = false
    @State private var selectedDuration = 0 // Index of selected duration
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var rewardHours = 0
    
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
            .overlay(
                // Success overlay
                ZStack {
                    if showSuccess {
                        Color.black.opacity(0.8)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                presentationMode.wrappedValue.dismiss()
                            }
                        
                        VStack(spacing: 20) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                                .padding(.bottom, 10)
                            
                            Text("Premium Unlocked!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("You now have premium features for \(rewardHours) hour\(rewardHours > 1 ? "s" : "")!")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Start Enjoying Premium")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(Color.yellow)
                                    .cornerRadius(20)
                            }
                            .padding(.top, 10)
                        }
                        .padding(30)
                        .background(Color(UIColor.systemGray6).opacity(0.9))
                        .cornerRadius(20)
                        .shadow(radius: 20)
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: showSuccess)
            )
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
                        videoCount: calculateVideosNeeded(for: index),
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
    
    /// Calculate how many videos needed for each duration option
    private func calculateVideosNeeded(for index: Int) -> Int {
        // Simple calculation, higher durations require more videos
        return min(index + 1, 3)
    }
    
    private func preloadRewardedAd() {
        // Request a rewarded ad to be loaded
        adManager.loadRewardedAd()
    }
    
    private func startRewardedAdFlow() {
        // Set loading state
        isLoading = true
        
        // For this implementation, we'll simulate the reward
        // In a real app, you'd check if the ad is available and show it
        
        if true { // In real app: if adManager.isRewardedAdReady
            // Get root view controller
            if let rootViewController = getRootViewController() {
                // In a real app, this would show the actual ad
                // For our implementation, we'll simulate success after a delay
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isLoading = false
                    
                    // Grant premium for the selected duration
                    self.rewardHours = self.trialDurations[self.selectedDuration]
                    self.premiumManager.grantTemporaryPremium(hours: self.rewardHours)
                    
                    // Show success animation
                    withAnimation {
                        self.showSuccess = true
                    }
                }
            } else {
                // Failed to get view controller
                isLoading = false
                errorMessage = "Could not display ad. Please try again."
                showError = true
            }
        } else {
            // No ad available
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isLoading = false
                self.errorMessage = "No ads available right now. Please try again later."
                self.showError = true
                
                // Try to load another ad for next time
                self.adManager.loadRewardedAd()
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        // Find the current UIWindow
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        
        // Return the root view controller
        return window.rootViewController
    }
}

struct RewardedAdView_Previews: PreviewProvider {
    static var previews: some View {
        RewardedAdView()
            .preferredColorScheme(.dark)
    }
}
