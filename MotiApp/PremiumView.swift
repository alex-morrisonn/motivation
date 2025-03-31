import SwiftUI

struct PremiumView: View {
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedOption = 1 // Default to monthly plan
    
    // Premium pricing options
    private let pricingOptions = [
        (period: "Monthly", price: "$1.99", savings: "", id: 0),
        (period: "Yearly", price: "$9.99", savings: "Save 58%", id: 1),
        (period: "Lifetime", price: "$19.99", savings: "Best Value", id: 2)
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Go Premium")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Unlock the full Moti experience")
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
                        Text("PREMIUM FEATURES")
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
                    
                    // Pricing options
                    VStack(spacing: 15) {
                        Text("SELECT YOUR PLAN")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 26)
                        
                        ForEach(pricingOptions, id: \.id) { option in
                            PricingButton(
                                period: option.period,
                                price: option.price,
                                savings: option.savings,
                                isSelected: selectedOption == option.id
                            ) {
                                withAnimation {
                                    selectedOption = option.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Purchase button
                    Button(action: {
                        // Here you would implement the actual in-app purchase
                        // For now, just simulate activation
                        adManager.activatePremium()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Continue")
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
                    
                    // Restore purchases button
                    Button(action: {
                        // Here you would implement restore purchases logic
                        // For demo, just simulate success or failure
                        let randomSuccess = Bool.random()
                        adManager.restorePremium(isSuccess: randomSuccess)
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 8)
                    }
                    
                    // Privacy & Terms
                    HStack(spacing: 20) {
                        Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Link("Terms of Use", destination: URL(string: "https://example.com/terms")!)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18))
        }
    }
}

// Pricing option button
struct PricingButton: View {
    let period: String
    let price: String
    let savings: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(period)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if !savings.isEmpty {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.yellow)
                        )
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .green : .gray)
                    .padding(.leading, 8)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.yellow.opacity(0.8) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}
