import SwiftUI
import UIKit

// A view that offers premium features in exchange for watching ads
struct RewardedAdView: View {
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingAd = false
    @State private var showingThankYou = false
    @State private var rewardAmount = 0
    @State private var rewardDuration = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .padding()
                    
                    Text("Try Premium Features")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Watch a short video to unlock premium features for 24 hours")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Premium features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "xmark.circle", title: "No Ads", description: "Enjoy the app without any advertisements")
                    
                    FeatureRow(icon: "square.on.square", title: "Widget Themes", description: "Access exclusive widget designs")
                    
                    FeatureRow(icon: "wand.and.stars", title: "Premium Content", description: "Get access to exclusive quote collections")
                    
                    FeatureRow(icon: "square.and.arrow.up", title: "Enhanced Sharing", description: "Share quotes with beautiful backgrounds")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Watch ad button
                Button(action: {
                    if adManager.isRewardedAdReady {
                        showRewardedAd()
                    } else {
                        // Try to load a new ad
                        adManager.loadRewardedAd()
                        
                        // Show message that ad is not ready
                        isShowingAd = false
                    }
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("Watch Video For Premium")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        adManager.isRewardedAdReady ?
                            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(gradient: Gradient(colors: [.gray.opacity(0.5), .gray.opacity(0.7)]), startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .shadow(color: adManager.isRewardedAdReady ? .blue.opacity(0.5) : .clear, radius: 5, x: 0, y: 2)
                }
                .disabled(!adManager.isRewardedAdReady)
                
                // Or buy premium button
                Button(action: {
                    // Here you would implement the IAP flow
                    // For now just show a placeholder
                }) {
                    Text("Or Get Permanent Premium For $2.99")
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 10)
                }
                .padding(.bottom, 20)
            }
            .padding(.bottom, 40)
            
            // Thank you overlay
            if showingThankYou {
                Color.black.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Premium Activated!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You now have premium features for 24 hours. Enjoy!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                            .shadow(color: Color.white.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.top, 20)
                }
                .padding(30)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
                .shadow(color: Color.white.opacity(0.1), radius: 20, x: 0, y: 0)
                .transition(.scale)
                .padding(.horizontal, 30)
            }
        }
        .navigationBarTitle("Premium Features", displayMode: .inline)
        .onAppear {
            if !adManager.isRewardedAdReady {
                adManager.loadRewardedAd()
            }
        }
    }
    
    private func showRewardedAd() {
        isShowingAd = true
        
        // Get the root controller to present the ad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootController = windowScene.windows.first?.rootViewController {
            
            adManager.showRewardedAd(from: rootController) { success, amount in
                isShowingAd = false
                
                if success {
                    // Activate temporary premium
                    rewardAmount = amount
                    rewardDuration = 24 // hours
                    
                    // Grant the premium for 24 hours
                    let temporaryPremiumEndTime = Date().addingTimeInterval(24 * 60 * 60)
                    UserDefaults.standard.set(temporaryPremiumEndTime, forKey: "temporaryPremiumEndTime")
                    
                    // Refresh premium status in manager
                    adManager.isPremiumUser = true
                    
                    // Schedule premium expiration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 24 * 60 * 60) {
                        if UserDefaults.standard.bool(forKey: "isPremiumUser") == false {
                            adManager.isPremiumUser = false
                        }
                    }
                    
                    // Show thank you message
                    withAnimation {
                        showingThankYou = true
                    }
                    
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if showingThankYou {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
}

// Feature row component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}
