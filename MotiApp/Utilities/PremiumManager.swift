import Foundation
import SwiftUI
import Combine

/// Premium plans available
enum PremiumPlan: String, Codable {
    case none
    case monthly
    case annual
    
    var displayName: String {
        switch self {
        case .none: return "Free"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
}

/// Manages premium features and subscription state
class PremiumManager: ObservableObject {
    // Shared instance for app-wide access
    static let shared = PremiumManager()
    
    // Published properties for SwiftUI binding
    @Published var isPremiumUser: Bool = false
    @Published var currentPlan: PremiumPlan = .none
    @Published var temporaryPremiumEndTime: Date?
    @Published var availableThemes: [AppTheme] = []
    
    // Feature limits for free tier
    private let freeThemeLimit = 2
    private let freeNoteLimit = 10
    private let freeWidgetLimit = 2
    
    // Private initializer for singleton
    private init() {
        loadPremiumState()
        updateAvailableThemes()
        startSubscriptionTimer()
    }
    
    // MARK: - Private Methods
    
    /// Load premium state from UserDefaults
    private func loadPremiumState() {
        // Load premium status
        self.isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
        
        // Load premium plan
        if let planString = UserDefaults.standard.string(forKey: "premiumPlan"),
           let plan = PremiumPlan(rawValue: planString) {
            self.currentPlan = plan
        }
        
        // Load temporary premium end time if exists
        if let expiryTimeInterval = UserDefaults.standard.object(forKey: "temporaryPremiumEndTime") as? TimeInterval {
            self.temporaryPremiumEndTime = Date(timeIntervalSince1970: expiryTimeInterval)
            checkTemporaryPremium()
        }
    }
    
    /// Start timer to check temporary premium status
    private func startSubscriptionTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkTemporaryPremium()
        }
    }
    
    /// Update available themes based on premium status
    private func updateAvailableThemes() {
        let allThemes = ThemeManager.shared.getAvailableThemes()
        
        if isPremiumUser {
            // Premium users get all themes
            self.availableThemes = allThemes
        } else {
            // Free users get limited themes
            self.availableThemes = allThemes.count <= freeThemeLimit ?
                allThemes : Array(allThemes.prefix(freeThemeLimit))
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if temporary premium has expired
    func checkTemporaryPremium() {
        guard let expiryTime = temporaryPremiumEndTime else { return }
        
        if Date() > expiryTime {
            // Premium has expired
            isPremiumUser = false
            temporaryPremiumEndTime = nil
            currentPlan = .none
            
            // Update user defaults
            UserDefaults.standard.set(false, forKey: "isPremiumUser")
            UserDefaults.standard.removeObject(forKey: "temporaryPremiumEndTime")
            UserDefaults.standard.removeObject(forKey: "premiumPlan")
            
            // Update available themes
            updateAvailableThemes()
            
            // Post notification
            NotificationCenter.default.post(name: Notification.Name("PremiumStatusChanged"), object: nil)
        }
    }
    
    /// Grant temporary premium access for specified duration
    func grantTemporaryPremium(hours: Int) {
        // Set premium end time
        let endTime = Date().addingTimeInterval(TimeInterval(hours * 3600))
        temporaryPremiumEndTime = endTime
        isPremiumUser = true
        currentPlan = .monthly // Temporary users get monthly benefits
        
        // Save to user defaults
        UserDefaults.standard.set(true, forKey: "isPremiumUser")
        UserDefaults.standard.set(endTime.timeIntervalSince1970, forKey: "temporaryPremiumEndTime")
        UserDefaults.standard.set(PremiumPlan.monthly.rawValue, forKey: "premiumPlan")
        
        // Update available themes
        updateAvailableThemes()
        
        // Post notification
        NotificationCenter.default.post(name: Notification.Name("PremiumStatusChanged"), object: nil)
    }
    
    /// Set premium status (normally called after purchase verification)
    func setPremiumStatus(isActive: Bool, plan: PremiumPlan = .none) {
        isPremiumUser = isActive
        currentPlan = plan
        
        // Update user defaults
        UserDefaults.standard.set(isActive, forKey: "isPremiumUser")
        UserDefaults.standard.set(plan.rawValue, forKey: "premiumPlan")
        
        // Clear temporary premium if upgrading to full premium
        if isActive && plan != .none {
            temporaryPremiumEndTime = nil
            UserDefaults.standard.removeObject(forKey: "temporaryPremiumEndTime")
        }
        
        // Update available themes
        updateAvailableThemes()
        
        // Post notification
        NotificationCenter.default.post(name: Notification.Name("PremiumStatusChanged"), object: nil)
    }
    
    // MARK: - Feature Access Methods
    
    /// Check if a specific theme is available
    func isThemeAvailable(_ theme: AppTheme) -> Bool {
        return isPremiumUser || availableThemes.contains { $0.id == theme.id }
    }
    
    /// Get the number of notes allowed
    func getNotesLimit() -> Int {
        return isPremiumUser ? .max : freeNoteLimit
    }
    
    /// Check if user has reached note limit
    func hasReachedNoteLimit(currentCount: Int) -> Bool {
        return !isPremiumUser && currentCount >= freeNoteLimit
    }
    
    /// Check if todo custom fields are available
    func areTodoCustomFieldsAvailable() -> Bool {
        return isPremiumUser
    }
    
    /// Get the widget style limit
    func getWidgetStyleLimit() -> Int {
        return isPremiumUser ? .max : freeWidgetLimit
    }
    
    /// Check if advanced pomodoro features are available
    func areAdvancedPomodoroFeaturesAvailable() -> Bool {
        return isPremiumUser
    }
    
    /// Check if streak forgiveness is available
    func isStreakForgivenessAvailable() -> Bool {
        return isPremiumUser
    }
    
    /// Get formatted time remaining for temporary premium
    func getFormattedTimeRemaining() -> String? {
        guard let endTime = temporaryPremiumEndTime else { return nil }
        
        let timeInterval = endTime.timeIntervalSince(Date())
        if timeInterval <= 0 {
            return "Expired"
        }
        
        // Convert to hours and minutes
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes) minutes remaining"
        }
    }
}

// MARK: - SwiftUI Extensions

// View modifier for premium feature locks
struct PremiumFeatureLock<LockContent: View>: ViewModifier {
    @ObservedObject private var premiumManager = PremiumManager.shared
    let featureDescription: String
    let lockContent: LockContent
    
    init(featureDescription: String, @ViewBuilder lockContent: () -> LockContent) {
        self.featureDescription = featureDescription
        self.lockContent = lockContent()
    }
    
    func body(content: Content) -> some View {
        ZStack {
            // Original content
            content
                .disabled(!premiumManager.isPremiumUser)
                .blur(radius: premiumManager.isPremiumUser ? 0 : 3)
            
            // Premium lock overlay when not premium
            if !premiumManager.isPremiumUser {
                lockContent
            }
        }
    }
}

// Default premium lock overlay
struct StandardPremiumLockOverlay: View {
    let feature: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 30))
                .foregroundColor(.yellow)
            
            Text("Premium Feature")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(feature)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Present premium view
                NotificationCenter.default.post(name: Notification.Name("ShowPremiumView"), object: nil)
            }) {
                Text("Upgrade")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
            .padding(.top, 5)
        }
        .padding(20)
        .background(Color.black.opacity(0.85))
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

// Extension to add premium locking functionality to views
extension View {
    /// Lock a view behind premium with custom overlay
    func premiumLocked<LockContent: View>(
        feature: String,
        @ViewBuilder lockContent: @escaping () -> LockContent
    ) -> some View {
        self.modifier(PremiumFeatureLock(featureDescription: feature, lockContent: lockContent))
    }
    
    /// Lock a view behind premium with standard overlay
    func premiumLocked(feature: String) -> some View {
        self.premiumLocked(feature: feature) {
            StandardPremiumLockOverlay(feature: feature)
        }
    }
}
