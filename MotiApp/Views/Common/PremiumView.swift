import SwiftUI
import StoreKit

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
                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.1)]), startPoint: .leading, endPoint: .trailing)
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
                    .lineLimit(nil)
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
    @ObservedObject private var premiumManager = PremiumManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // Local state
    @State private var selectedPlanIndex = 1 // Default to annual
    @State private var isPurchasing = false
    @State private var showingRestoreMessage = false
    @State private var restoreResult: Bool? = nil
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Premium plans
    private let plans = [
        (title: "Monthly", price: "$2.99", period: "month", saveText: ""),
        (title: "Annual", price: "$19.99", period: "year", saveText: "Save 44%")
    ]
    
    // Feature sets
    private let primaryFeatures = [
        PremiumFeature(icon: "xmark.circle.fill", title: "Ad-Free Experience", description: "Enjoy a completely ad-free experience with no distractions", iconColor: .red),
        PremiumFeature(icon: "paintpalette.fill", title: "All Premium Themes", description: "Personalize your app with multiple color schemes", iconColor: .purple),
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
                    
                    // Current premium status (if any)
                    if premiumManager.isPremiumUser {
                        currentPremiumStatusView
                            .transition(.opacity)
                    } else {
                        // Plans selector (only if not premium)
                        planSelector
                    }
                    
                    // Feature sections
                    Group {
                        featureSection(title: "PREMIUM FEATURES", features: primaryFeatures)
                        featureSection(title: "ENHANCED PRODUCTIVITY", features: productivityFeatures)
                        featureSection(title: "EXCLUSIVE CONTENT", features: contentFeatures)
                    }
                    
                    // Subscribe button
                    if !premiumManager.isPremiumUser {
                        subscribeButton
                    } else {
                        // Management buttons for current subscribers
                        managementButtons
                    }
                    
                    // Terms and restoration text
                    legalText
                }
                .padding(.bottom, 30)
            }
            
            // Close button top right
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
            
            // Loading overlay
            if isPurchasing {
                loadingOverlay
            }
        }
        .alert(isPresented: $showingRestoreMessage) {
            if let result = restoreResult {
                return Alert(
                    title: Text(result ? "Purchases Restored" : "No Purchases Found"),
                    message: Text(result ? "Your premium subscription has been restored." : "We couldn't find any previous purchases to restore."),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                return Alert(
                    title: Text("Error"),
                    message: Text("An unexpected error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Purchase Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Component Views
    
    // Header with premium logo and title
    private var headerView: some View {
        VStack(spacing: 15) {
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
    
    // Current premium status view
    private var currentPremiumStatusView: some View {
        VStack(spacing: 10) {
            Text("You are a Premium Member")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                
                Text("\(premiumManager.currentPlan.displayName) Plan")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                
                if premiumManager.currentPlan == .temporary,
                   let timeRemaining = premiumManager.getFormattedTimeRemaining() {
                    Divider()
                        .frame(height: 12)
                        .background(Color.white.opacity(0.3))
                    
                    Text(timeRemaining)
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(20)
        }
        .padding(.vertical, 10)
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
            startPurchase()
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
        .disabled(isPurchasing)
        .padding(.horizontal, 30)
        .padding(.vertical, 10)
    }
    
    // Management buttons for current subscribers
    private var managementButtons: some View {
        VStack(spacing: 12) {
            if premiumManager.currentPlan == .temporary {
                // Upgrade from temporary to full premium
                Button(action: {
                    startPurchase()
                }) {
                    Text("Upgrade to Full Premium")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.yellow, .orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 30)
            }
            
            // Manage subscription button
            Button(action: {
                openSubscriptionSettings()
            }) {
                Text("Manage Subscription")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 30)
        }
    }
    
    // Legal text section
    private var legalText: some View {
        VStack(spacing: 10) {
            if !premiumManager.isPremiumUser {
                Text("Auto-renewable. Cancel anytime.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                restorePurchases()
            }) {
                Text("Restore Purchases")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .disabled(isPurchasing)
            
            Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your App Store account settings after purchase.")
                .font(.system(size: 10))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 10)
        }
        .padding(.bottom, 30)
    }
    
    // Loading overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Purchase Methods
    
    // Start a premium purchase
    private func startPurchase() {
        isPurchasing = true
        
        // In a real app, you would integrate with StoreKit here
        // For this demo, we'll simulate a purchase process
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Simulate purchase success
            let purchaseSuccessful = true
            
            if purchaseSuccessful {
                // Set premium type based on selection
                let plan: PremiumPlan = self.selectedPlanIndex == 0 ? .monthly : .annual
                self.premiumManager.setPremiumStatus(isActive: true, plan: plan)
            } else {
                // Show error
                self.errorMessage = "Purchase could not be completed. Please try again later."
                self.showError = true
            }
            
            self.isPurchasing = false
        }
    }
    
    // Restore previous purchases
    private func restorePurchases() {
        isPurchasing = true
        
        premiumManager.restorePurchases { success in
            self.isPurchasing = false
            self.restoreResult = success
            self.showingRestoreMessage = true
        }
    }
    
    // Open subscription settings in the App Store
    private func openSubscriptionSettings() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}
