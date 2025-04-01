import SwiftUI

struct PremiumView: View {
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Premium Coming Soon")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("We're developing premium features for Moti")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // Premium badges
                    HStack(spacing: 20) {
                        PremiumFeatureBadge(
                            icon: "xmark.circle.fill",
                            title: "Ad-Free",
                            color: .red
                        )
                        
                        PremiumFeatureBadge(
                            icon: "square.grid.3x3.fill",
                            title: "All Widgets",
                            color: .blue
                        )
                        
                        PremiumFeatureBadge(
                            icon: "paintpalette.fill",
                            title: "Themes",
                            color: .purple
                        )
                    }
                    .padding(.bottom, 10)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 20) {
                        Text("UPCOMING PREMIUM FEATURES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(2)
                            .padding(.horizontal, 6)
                        
                        VStack(spacing: 18) {
                            PremiumFeatureRow(
                                icon: "xmark.circle.fill",
                                iconColor: .red,
                                title: "Remove All Ads",
                                description: "Enjoy a completely ad-free experience"
                            )
                            
                            PremiumFeatureRow(
                                icon: "square.grid.3x3.fill",
                                iconColor: .blue,
                                title: "Premium Widgets",
                                description: "Access all widget styles and designs"
                            )
                            
                            PremiumFeatureRow(
                                icon: "paintpalette.fill",
                                iconColor: .purple,
                                title: "Custom Themes",
                                description: "Personalize your app with custom colors"
                            )
                            
                            PremiumFeatureRow(
                                icon: "arrow.up.square.fill",
                                iconColor: .green,
                                title: "Quote Export",
                                description: "Export your favorite quotes in beautiful designs"
                            )
                            
                            PremiumFeatureRow(
                                icon: "star.fill",
                                iconColor: .yellow,
                                title: "Exclusive Content",
                                description: "Access premium quote collections and categories"
                            )
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    // Coming Soon Notice
                    VStack(spacing: 15) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                            .padding(.bottom, 10)
                        
                        Text("Premium Features Under Development")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("We're working hard to bring you these premium features soon. For now, enjoy the free version of Moti with all quotes and widgets available!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Close button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Continue with Free Version")
                            .font(.headline)
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
                            .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
 
                    .padding(.top, 10)
                    .padding(.bottom, 40)
                }
            }
            
            // Close button
            VStack {
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
                
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// Premium feature badge
struct PremiumFeatureBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// Premium feature row
struct PremiumFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
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
            
            Image(systemName: "hourglass")
                .foregroundColor(.yellow)
                .font(.system(size: 18))
        }
    }
}
