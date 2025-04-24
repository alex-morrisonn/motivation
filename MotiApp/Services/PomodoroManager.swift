import Foundation
import SwiftUI
import AVFoundation

/// The different modes of the Pomodoro timer
enum TimerMode {
    case work
    case shortBreak
    case longBreak
}

/// Manager class for the Pomodoro timer functionality
class PomodoroManager: ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance for app-wide access
    static let shared = PomodoroManager()
    
    // MARK: - Published Properties
    
    /// Current mode of the timer
    @Published var mode: TimerMode = .work
    
    /// Whether the timer is currently running
    @Published var isRunning = false
    
    /// Whether the timer is in its initial state
    @Published var isReset = true
    
    /// Current seconds remaining in the timer (not displayed but needed for functionality)
    @Published private(set) var secondsRemaining = 0
    
    /// Progress value for the timer circle (0.0 to 1.0)
    @Published var progress: CGFloat = 1.0
    
    /// Number of completed work sessions
    @Published var completedSessions = 0
    
    /// Total minutes spent focusing
    @Published var totalFocusMinutes = 0
    
    // MARK: - Configuration Properties
    
    /// Duration of work sessions in minutes
    @Published var workMinutes = 25
    
    /// Duration of short breaks in minutes
    @Published var shortBreakMinutes = 5
    
    /// Duration of long breaks in minutes
    @Published var longBreakMinutes = 15
    
    /// Number of work sessions before a long break
    @Published var sessionsBeforeLongBreak = 4
    
    /// Whether sound notifications are enabled
    @Published var soundEnabled = true
    
    /// Whether vibration is enabled
    @Published var vibrationEnabled = true
    
    /// Whether the next session should start automatically
    @Published var autoStartNextSession = false
    
    // MARK: - Private Properties
    
    /// Timer for counting down
    private var timer: Timer?
    
    /// Total seconds for the current timer mode
    private var totalSeconds = 0
    
    /// Audio player for timer completion sound
    private var audioPlayer: AVAudioPlayer?
    
    /// Current session count (resets after long break)
    private var currentSessionCount = 0
    
    /// UserDefaults keys
    private let workMinutesKey = "pomodoro_workMinutes"
    private let shortBreakMinutesKey = "pomodoro_shortBreakMinutes"
    private let longBreakMinutesKey = "pomodoro_longBreakMinutes"
    private let sessionsBeforeLongBreakKey = "pomodoro_sessionsBeforeLongBreak"
    private let soundEnabledKey = "pomodoro_soundEnabled"
    private let vibrationEnabledKey = "pomodoro_vibrationEnabled"
    private let autoStartNextSessionKey = "pomodoro_autoStartNextSession"
    private let totalFocusMinutesKey = "pomodoro_totalFocusMinutes"
    private let completedSessionsKey = "pomodoro_completedSessions"
    
    // MARK: - Computed Properties
    
    /// Time remaining formatted as MM:SS
    var timeString: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Initialization
    
    private init() {
        loadSettings()
        configureSounds()
        resetTimerForCurrentMode()
    }
    
    // MARK: - Timer Control Methods
    
    /// Start the timer
    func startTimer() {
        // If timer is already in initial state, mark it as not reset
        if isReset {
            isReset = false
        }
        
        isRunning = true
        
        // Invalidate any existing timer
        timer?.invalidate()
        
        // Create a new timer that fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    /// Pause the timer
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
    }
    
    /// Reset the timer to initial state for current mode
    func resetTimer() {
        pauseTimer()
        isReset = true
        resetTimerForCurrentMode()
    }
    
    /// Skip to the next timer mode
    func skipToNextMode() {
        completeCurrentTimerMode()
    }
    
    // MARK: - Settings Update Methods
    
    /// Update work minutes setting
    /// - Parameter minutes: New duration in minutes
    func updateWorkMinutes(_ minutes: Int) {
        workMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: workMinutesKey)
        
        // If currently in work mode and timer is reset, update the timer
        if mode == .work && isReset {
            resetTimerForCurrentMode()
        }
    }
    
    /// Update short break minutes setting
    /// - Parameter minutes: New duration in minutes
    func updateShortBreakMinutes(_ minutes: Int) {
        shortBreakMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: shortBreakMinutesKey)
        
        // If currently in short break mode and timer is reset, update the timer
        if mode == .shortBreak && isReset {
            resetTimerForCurrentMode()
        }
    }
    
    /// Update long break minutes setting
    /// - Parameter minutes: New duration in minutes
    func updateLongBreakMinutes(_ minutes: Int) {
        longBreakMinutes = minutes
        UserDefaults.standard.set(minutes, forKey: longBreakMinutesKey)
        
        // If currently in long break mode and timer is reset, update the timer
        if mode == .longBreak && isReset {
            resetTimerForCurrentMode()
        }
    }
    
    /// Update sessions before long break setting
    /// - Parameter sessions: New number of sessions
    func updateSessionsBeforeLongBreak(_ sessions: Int) {
        sessionsBeforeLongBreak = sessions
        UserDefaults.standard.set(sessions, forKey: sessionsBeforeLongBreakKey)
    }
    
    /// Update sound enabled setting
    /// - Parameter enabled: Whether sound is enabled
    func updateSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: soundEnabledKey)
    }
    
    /// Update vibration enabled setting
    /// - Parameter enabled: Whether vibration is enabled
    func updateVibrationEnabled(_ enabled: Bool) {
        vibrationEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: vibrationEnabledKey)
    }
    
    /// Update auto-start next session setting
    /// - Parameter enabled: Whether to auto-start next session
    func updateAutoStartNextSession(_ enabled: Bool) {
        autoStartNextSession = enabled
        UserDefaults.standard.set(enabled, forKey: autoStartNextSessionKey)
    }
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        workMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        sessionsBeforeLongBreak = 4
        soundEnabled = true
        vibrationEnabled = true
        autoStartNextSession = false
        
        // Save to UserDefaults
        UserDefaults.standard.set(workMinutes, forKey: workMinutesKey)
        UserDefaults.standard.set(shortBreakMinutes, forKey: shortBreakMinutesKey)
        UserDefaults.standard.set(longBreakMinutes, forKey: longBreakMinutesKey)
        UserDefaults.standard.set(sessionsBeforeLongBreak, forKey: sessionsBeforeLongBreakKey)
        UserDefaults.standard.set(soundEnabled, forKey: soundEnabledKey)
        UserDefaults.standard.set(vibrationEnabled, forKey: vibrationEnabledKey)
        UserDefaults.standard.set(autoStartNextSession, forKey: autoStartNextSessionKey)
        
        // Reset the timer if it's not running
        if !isRunning {
            resetTimerForCurrentMode()
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Update the timer each second
    private func updateTimer() {
        guard secondsRemaining > 0 else {
            completeCurrentTimerMode()
            return
        }
        
        secondsRemaining -= 1
        
        // Update progress
        if totalSeconds > 0 {
            progress = CGFloat(secondsRemaining) / CGFloat(totalSeconds)
        }
        
        // If this is work mode, track the focus time
        if mode == .work {
            totalFocusMinutes += 1 / 60 // Add 1/60 of a minute (1 second)
            UserDefaults.standard.set(totalFocusMinutes, forKey: totalFocusMinutesKey)
        }
    }
    
    /// Actions to take when the current timer completes
    private func completeCurrentTimerMode() {
        pauseTimer()
        
        // Play sound if enabled
        if soundEnabled {
            playCompletionSound()
        }
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: NSNotification.Name("PomodoroTimerCompleted"), object: nil)
        
        // Update session count and move to next mode
        switch mode {
        case .work:
            // Increment completed sessions count
            completedSessions += 1
            UserDefaults.standard.set(completedSessions, forKey: completedSessionsKey)
            
            // Increment current session count
            currentSessionCount += 1
            
            // Determine if we should take a long break or short break
            if currentSessionCount >= sessionsBeforeLongBreak {
                mode = .longBreak
                currentSessionCount = 0
            } else {
                mode = .shortBreak
            }
            
        case .shortBreak, .longBreak:
            // After a break, switch back to work mode
            mode = .work
        }
        
        // Reset the timer for the new mode
        resetTimerForCurrentMode()
        
        // Auto-start next session if enabled
        if autoStartNextSession {
            startTimer()
        }
    }
    
    /// Reset the timer for the current mode
    private func resetTimerForCurrentMode() {
        switch mode {
        case .work:
            secondsRemaining = workMinutes * 60
        case .shortBreak:
            secondsRemaining = shortBreakMinutes * 60
        case .longBreak:
            secondsRemaining = longBreakMinutes * 60
        }
        
        totalSeconds = secondsRemaining
        progress = 1.0
    }
    
    /// Configure sound for timer completion
    private func configureSounds() {
        guard let soundURL = Bundle.main.url(forResource: "bell", withExtension: "mp3") else {
            print("Sound file not found in bundle")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to initialize audio player: \(error.localizedDescription)")
        }
    }
    
    /// Play completion sound
    private func playCompletionSound() {
        audioPlayer?.play()
    }
    
    /// Load settings from UserDefaults
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        workMinutes = defaults.integer(forKey: workMinutesKey)
        if workMinutes == 0 { workMinutes = 25 } // Default value
        
        shortBreakMinutes = defaults.integer(forKey: shortBreakMinutesKey)
        if shortBreakMinutes == 0 { shortBreakMinutes = 5 } // Default value
        
        longBreakMinutes = defaults.integer(forKey: longBreakMinutesKey)
        if longBreakMinutes == 0 { longBreakMinutes = 15 } // Default value
        
        sessionsBeforeLongBreak = defaults.integer(forKey: sessionsBeforeLongBreakKey)
        if sessionsBeforeLongBreak == 0 { sessionsBeforeLongBreak = 4 } // Default value
        
        soundEnabled = defaults.object(forKey: soundEnabledKey) as? Bool ?? true
        vibrationEnabled = defaults.object(forKey: vibrationEnabledKey) as? Bool ?? true
        autoStartNextSession = defaults.bool(forKey: autoStartNextSessionKey)
        
        totalFocusMinutes = defaults.integer(forKey: totalFocusMinutesKey)
        completedSessions = defaults.integer(forKey: completedSessionsKey)
    }
}
