import SwiftUI
import AVFoundation

/// Main view for the Pomodoro Timer feature
struct PomodoroTimerView: View {
    // MARK: - Properties
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var pomodoroManager = PomodoroManager.shared
    
    // Local UI state
    @State private var showingSettings = false
    @State private var animationAmount: CGFloat = 1.0
    @State private var ringProgress: CGFloat = 0.0
    
    // Haptic feedback
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Computed properties for UI
    private var timerColor: Color {
        switch pomodoroManager.mode {
        case .work:
            return .red
        case .shortBreak:
            return .green
        case .longBreak:
            return .blue
        }
    }
    
    private var modeTitle: String {
        switch pomodoroManager.mode {
        case .work:
            return "Focus Time"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Main content with proper safe area insets
                VStack(spacing: 10) {
                    // Settings button moved to top-right with less spacing
                    HStack {
                        Spacer()
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        .padding(.trailing, 5)
                    }
                    // Timer mode indicator with improved visibility
                    Text(modeTitle)
                        .font(.headline)
                        .foregroundColor(.white) // Changed to white for better visibility
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(timerColor.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .stroke(timerColor, lineWidth: 1.5)
                                )
                        )
                        .padding(.top, 10) // Extra padding at the top
                    
                    // Timer circle with reduced padding
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(timerColor.opacity(0.2), lineWidth: 15)
                            .padding(10)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: pomodoroManager.progress)
                            .stroke(
                                timerColor,
                                style: StrokeStyle(
                                    lineWidth: 15,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                            .padding(10)
                            .animation(.linear(duration: 0.2), value: pomodoroManager.progress)
                        
                        // Time display
                        VStack {
                            Text(pomodoroManager.timeString)
                                .font(.system(size: 70, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if pomodoroManager.isRunning {
                                Text("In progress")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else if pomodoroManager.isReset {
                                Text("Ready to focus")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Timer paused")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .scaleEffect(animationAmount)
                    }
                    .frame(width: 280, height: 280)
                    .padding(.bottom, 5)
                    .onAppear {
                        // Subtle breathing animation
                        withAnimation(
                            Animation.easeInOut(duration: 2)
                                .repeatForever(autoreverses: true)
                        ) {
                            animationAmount = 1.05
                        }
                    }
                    
                    // Dynamic work/break info section with tips instead of just stats
                    VStack(spacing: 4) {
                        // Show relevant timer information based on current mode
                        let modeInfo = getModeInfo()
                        
                        Text(modeInfo.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.top, 4)
                        
                        Text(modeInfo.description)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    
                    // Control buttons
                    HStack(spacing: 20) {
                        // Reset button
                        Button(action: {
                            impactGenerator.impactOccurred()
                            pomodoroManager.resetTimer()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(20)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        
                        // Start/Pause button
                        Button(action: {
                            impactGenerator.impactOccurred()
                            if pomodoroManager.isRunning {
                                pomodoroManager.pauseTimer()
                            } else {
                                pomodoroManager.startTimer()
                            }
                        }) {
                            Image(systemName: pomodoroManager.isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .padding(24)
                                .background(
                                    Circle()
                                        .fill(timerColor)
                                        .shadow(color: timerColor.opacity(0.5), radius: 10, x: 0, y: 5)
                                )
                        }
                        
                        // Skip button
                        Button(action: {
                            impactGenerator.impactOccurred()
                            pomodoroManager.skipToNextMode()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(20)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.top, 5)
                    
                    // Motivation quote with better spacing
                    if let quote = getRandomMotivationQuote() {
                        VStack(spacing: 4) {
                            Text(quote.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                            
                            Text("— \(quote.author)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        .padding(.bottom, 30) // Ensure quote is fully visible above tab bar
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10) // Minimal top padding
                .padding(.bottom, 5) // Minimal bottom padding
            }
            .navigationBarHidden(true) // Hide the navigation bar completely
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            // Set up notifications when timer completes
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("PomodoroTimerCompleted"),
                object: nil,
                queue: .main
            ) { [self] notification in
                notificationGenerator.notificationOccurred(.success)
                
                // Use more pronounced animation when timer completes
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                    animationAmount = 1.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                        animationAmount = 1.0
                    }
                }
            }
        }
        .onDisappear {
            // Remove observer when view disappears
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("PomodoroTimerCompleted"),
                object: nil
            )
        }
        .sheet(isPresented: $showingSettings) {
            PomodoroSettingsView()
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get a random motivational quote from the app's quote service
    private func getRandomMotivationQuote() -> Quote? {
        return QuoteService.shared.getRandomQuote()
    }
    
    // Helper method to get relevant mode information
    private func getModeInfo() -> (title: String, description: String) {
        switch pomodoroManager.mode {
        case .work:
            return (
                "Focus Session",
                "Stay on task and avoid distractions. Consider the one thing you want to accomplish."
            )
        case .shortBreak:
            return (
                "Short Break",
                "Take a moment to stretch, breathe, or rest your eyes. Movement helps refresh your mind."
            )
        case .longBreak:
            return (
                "Long Break",
                "You've earned a longer rest. Step away from the screen and recharge before your next session."
            )
        }
    }
    
    /// Get the safe area insets
    private var safeAreaInsets: EdgeInsets {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        
        return EdgeInsets(
            top: keyWindow?.safeAreaInsets.top ?? 0,
            leading: keyWindow?.safeAreaInsets.left ?? 0,
            bottom: keyWindow?.safeAreaInsets.bottom ?? 0,
            trailing: keyWindow?.safeAreaInsets.right ?? 0
        )
    }
    
    /// Get just the top safe area inset for spacing
    private func getSafeAreaTopInset() -> CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        
        return keyWindow?.safeAreaInsets.top ?? 0
    }
}

// MARK: - Previews

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
            .preferredColorScheme(.dark)
    }
}
