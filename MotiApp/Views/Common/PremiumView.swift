import SwiftUI

// Premium feature model
struct PremiumFeature: Identifiable {
    var id = UUID()
    var icon: String
    var title: String
    var description: String
    var iconColor: Color
}

// Single plan button component
struct PlanButton: View {
    let plan: (title: String, price: String, period: String, saveText: String)
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Title
                Text(plan.title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .black : .white)
                
                // Price with period
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(plan.price)
                        .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                    
                    Text("/ \(plan.period)")
                        .font(.caption)
                }
                
                // Save text badge (if any)
                if !plan.saveText.isEmpty {
                    Text(plan.saveText)
                        .font(.caption)
                        .padding(4)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ?
                LinearGradient(gradient: Gradient(colors: [.yellow, .orange]), startPoint: .leading, endPoint: .trailing) :
                Color.white.opacity(0.1)
            )
            .cornerRadius(12)
        }
    }
}

// Feature row component
struct FeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon with color background
            ZStack {
                Circle()
                    .fill(feature.iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 18))
                    .foregroundColor(feature.iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// Main Premium View
struct PremiumView: View {
    // Environment & Properties
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // Local state
    @State private var selectedPlanIndex = 1 // Default to annual
    @State private var animateFeatures = false
    @State private var showComingSoon = false
    
    // Premium plans
    private let plans = [
        (title: "Monthly", price: "$2.99", period: "month", saveText: ""),
        (title: "Annual", price: "$19.99", period: "year", saveText: "Save 44%")
    ]
    
    // Feature sets
    private let primaryFeatures = [
        PremiumFeature(icon: "xmark.circle.fill", title: "Ad-Free Experience", description: "Enjoy a completely ad-free experience with no distractions", iconColor: .red),
        PremiumFeature(icon: "paintpalette.fill", title: "8+ Premium Themes", description: "Personalize your app with multiple color schemes", iconColor: .purple),
        PremiumFeature(icon: "rectangle.stack.fill", title: "Unlimited Notes", description: "No limits on Mind Dump notes with advanced formatting", iconColor: .blue)
    ]
    
    private let productivityFeatures = [
        PremiumFeature(icon: "timer", title: "Advanced Pomodoro Timer", description: "Custom presets, analytics, and auto-scheduling", iconColor: .orange),
        PremiumFeature(icon: "checklist", title: "Todo Power Features", description: "Recurring tasks, categories, and detailed analytics", iconColor: .green),
        PremiumFeature(icon: "flame.fill", title: "Streak Forgiveness", description: "One free pass per month to maintain your streak", iconColor: .yellow)
    ]
    
    private let contentFeatures = [
        PremiumFeature(icon: "quote.bubble.fill", title: "Premium Quote Collections", description: "Access 100+ exclusive motivational quotes", iconColor: .blue),
        PremiumFeature(icon: "square.grid.2x2", title: "Advanced Widget Options", description: "10+ widget styles with custom layouts and colors", iconColor: .indigo),
        PremiumFeature(icon: "square.and.arrow.up", title: "Beautiful Exports", description: "Create stunning quote images to share and save", iconColor: .pink)
    ]
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black.opacity(0.8),
                    Color(red: 0.15, green: 0.1, blue: 0.25)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    headerView
                    
                    // Plans selector
                    planSelector
                    
                    // Feature sections
                    Group {
                        featureSection(title: "UNLOCK PREMIUM FEATURES", features: primaryFeatures)
                        featureSection(title: "ENHANCED PRODUCTIVITY", features: productivityFeatures)
                        featureSection(title: "EXCLUSIVE CONTENT", features: contentFeatures)
                    }
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(y: animateFeatures ? 0 : 20)
                    
                    // Subscribe button
                    subscribeButton
                    
                    // Terms and restoration text
                    legalText
                }
            }
            
            // Coming soon overlay
            if showComingSoon {
                comingSoonOverlay
            }
        }
        .onAppear {
            // Animate features with staggered timing
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateFeatures = true
            }
        }
    }
    
    // MARK: - Component Views
    
    // Header with premium logo and title
    private var headerView: some View {
        VStack(spacing: 15) {
            // Close button on top right
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
            
            // Crown icon with glowing effect
            ZStack {
                // Glowing background
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.yellow.opacity(0.7), Color.yellow.opacity(0), Color.clear]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
            }
            
            Text("Motii Premium")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Elevate your motivation journey")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }
    
    // Plans selector section
    private var planSelector: some View {
        VStack(spacing: 10) {
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(.white)
            
            // Plan selection row
            HStack(spacing: 0) {
                // Monthly plan
                PlanButton(
                    plan: plans[0],
                    isSelected: selectedPlanIndex == 0,
                    action: {
                        withAnimation(.spring()) {
                            selectedPlanIndex = 0
                        }
                    }
                )
                
                Spacer().frame(width: 15)
                
                // Annual plan
                PlanButton(
                    plan: plans[1],
                    isSelected: selectedPlanIndex == 1,
                    action: {
                        withAnimation(.spring()) {
                            selectedPlanIndex = 1
                        }
                    }
                )
            }
            .padding(8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    // Feature section with title and list of features
    private func featureSection(title: String, features: [PremiumFeature]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
                .tracking(2)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(features) { feature in
                    FeatureRow(feature: feature)
                }
            }
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    // Subscribe button
    private var subscribeButton: some View {
        Button(action: {
            showComingSoon = true
        }) {
            Text("Subscribe Now")
                .font(.system(size: 20, weight: .bold))
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
                .cornerRadius(16)
                .shadow(color: Color.orange.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
    }
    
    // Legal text section
    private var legalText: some View {
        VStack(spacing: 10) {
            Text("Auto-renewable. Cancel anytime.")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: {
                // Restore purchases action would go here
            }) {
                Text("Restore Purchases")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase.")
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
        }
        .padding(.bottom, 30)
    }
    
    // Coming soon overlay
    private var comingSoonOverlay: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showComingSoon = false
                    }
                }
            
            // Content
            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                Text("Coming Soon!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Premium subscriptions are still in development. We're working hard to bring you these great features soon!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Button(action: {
                    withAnimation {
                        showComingSoon = false
                    }
                }) {
                    Text("OK")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(width: 120)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(Color(UIColor.systemGray6).opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
            .transition(.scale)
        }
        .transition(.opacity)
    }
}

// Preview provider
struct PremiumView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumView()
            .preferredColorScheme(.dark)
    }
}
