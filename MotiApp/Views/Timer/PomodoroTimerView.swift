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
                
                VStack(spacing: 25) {
                    // Timer mode indicator
                    Text(modeTitle)
                        .font(.headline)
                        .foregroundColor(timerColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(timerColor.opacity(0.2))
                        .cornerRadius(20)
                    
                    // Timer circle
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(timerColor.opacity(0.2), lineWidth: 15)
                            .padding(20)
                        
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
                            .padding(20)
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
                    .frame(width: 300, height: 300)
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
                    
                    // Session count
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(pomodoroManager.completedSessions)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Sessions")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack {
                            Text(String(format: "%02d:%02d", pomodoroManager.totalFocusMinutes / 60, pomodoroManager.totalFocusMinutes % 60))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Focus Time")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 40)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(20)
                    
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
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
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
                                .background(timerColor)
                                .clipShape(Circle())
                                .shadow(color: timerColor.opacity(0.5), radius: 10, x: 0, y: 5)
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
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 5)
                    
                    Spacer(minLength: 20)
                    
                    // Motivation quote
                    if let quote = getRandomMotivationQuote() {
                        VStack(spacing: 6) {
                            Text(quote.text)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text("— \(quote.author)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, safeAreaInsets.bottom)
            }
            .navigationTitle("Pomodoro Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
            }
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
}

// MARK: - Previews

struct PomodoroTimerView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroTimerView()
            .preferredColorScheme(.dark)
    }
}
