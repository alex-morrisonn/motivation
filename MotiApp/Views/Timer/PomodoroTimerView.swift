import SwiftUI
import AVFoundation

/// Main view for the Pomodoro Timer feature
struct PomodoroTimerView: View {
    // MARK: - Properties
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var pomodoroManager = PomodoroManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared // Add theme manager
    
    // Local UI state
    @State private var showingSettings = false
    @State private var animationAmount: CGFloat = 1.0
    @State private var ringProgress: CGFloat = 0.0
    @State private var currentQuote: Quote? = QuoteService.shared.getRandomQuote()
    @State private var quoteTimer: Timer? = nil
    
    // Haptic feedback
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // Computed properties for UI
    private var timerColor: Color {
        switch pomodoroManager.mode {
        case .work:
            return Color.themeError // Use theme error color for work mode
        case .shortBreak:
            return Color.themeSuccess // Use theme success color for short breaks
        case .longBreak:
            return Color.themeAccent // Use theme accent color for long breaks
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
                // Background - use theme background color
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                // Main content with proper safe area insets
                VStack(spacing: 10) {
                    // Header with title and settings button
                    HStack {
                        // Mode title indicator with improved visibility
                        Text(modeTitle)
                            .font(.headline)
                            .foregroundColor(Color.themeText)
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
                        
                        Spacer()
                        
                        // Settings button moved into header row
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(Color.themeText)
                                .font(.system(size: 16))
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.themeText.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal)
                    
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
                        
                        // Time display - only this should have the breathing animation
                        VStack {
                            Text(pomodoroManager.timeString)
                                .font(.system(size: 70, weight: .bold, design: .rounded))
                                .foregroundColor(Color.themeText)
                                .scaleEffect(animationAmount) // Breathing animation only on the timer text
                            
                            if pomodoroManager.isRunning {
                                Text("In progress")
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeSecondaryText)
                            } else if pomodoroManager.isReset {
                                Text("Ready to focus")
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeSecondaryText)
                            } else {
                                Text("Timer paused")
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeSecondaryText)
                            }
                        }
                    }
                    .frame(width: 280, height: 280)
                    .padding(.bottom, 5)
                    .onAppear {
                        // Subtle breathing animation - now only applied to the timer text
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
                            .foregroundColor(Color.themeText)
                            .padding(.top, 4)
                        
                        Text(modeInfo.description)
                            .font(.system(size: 13))
                            .foregroundColor(Color.themeSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 4)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.themeCardBackground.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.themeDivider, lineWidth: 1)
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
                                .foregroundColor(Color.themeText)
                                .padding(20)
                                .background(
                                    Circle()
                                        .fill(Color.themeCardBackground)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.themeDivider, lineWidth: 1)
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
                                .foregroundColor(themeManager.currentTheme.isDark ? Color.themeBackground : Color.themeText)
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
                                .foregroundColor(Color.themeText)
                                .padding(20)
                                .background(
                                    Circle()
                                        .fill(Color.themeCardBackground)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.themeDivider, lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.top, 5)
                    
                    // Motivation quote with better spacing - now changes every minute
                    if let quote = currentQuote {
                        VStack(spacing: 4) {
                            Text(quote.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color.themeText.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(2)
                            
                            Text("— \(quote.author)")
                                .font(.system(size: 13))
                                .foregroundColor(Color.themeSecondaryText)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        .padding(.bottom, 30) // Ensure quote is fully visible above tab bar
                        .id("motivation-quote-\(quote.id)") // Force refresh when quote changes
                        .onAppear {
                            // Set up the timer to change quotes every minute
                            quoteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                                // In your timer callback
                                currentQuote = getRandomMotivationQuote() ?? QuoteService.shared.getFallbackQuote()
                            }
                        }
                        .onDisappear {
                            // Clean up timer when view disappears
                            quoteTimer?.invalidate()
                            quoteTimer = nil
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: .top) // Ignore container insets at top
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
            
            // Clean up the quote timer
            quoteTimer?.invalidate()
            quoteTimer = nil
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
}

// MARK: - Previews

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
            .preferredColorScheme(.dark)
    }
}
