import SwiftUI
import UIKit

// A view that offers premium features in exchange for watching ads
struct RewardedAdView: View {
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var isShowingAd = false
    
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
                    
                    Text("Coming Soon")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Premium trial feature is currently under development")
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
                
                // Development info
                VStack(spacing: 15) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("Feature Under Development")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("In the future, you'll be able to watch short videos to unlock premium features for limited periods. Until then, enjoy the free version of Moti with all quotes and widgets available!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Close button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Return to App")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitle("Premium Trial", displayMode: .inline)
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
