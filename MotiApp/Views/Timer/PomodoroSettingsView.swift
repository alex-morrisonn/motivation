import SwiftUI

/// Settings view for the Pomodoro Timer
struct PomodoroSettingsView: View {
    // MARK: - Properties
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var pomodoroManager = PomodoroManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared // Add theme manager
    
    // Local state for settings
    @State private var workMinutes: Double
    @State private var shortBreakMinutes: Double
    @State private var longBreakMinutes: Double
    @State private var sessionsBeforeLongBreak: Double
    @State private var soundEnabled: Bool
    @State private var vibrationEnabled: Bool
    @State private var autoStartNextSession: Bool
    
    // Formatter for displaying time values
    private let minutesFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Initialization
    
    init() {
        // Initialize local state from manager
        // Using explicit initialValues to avoid accessing self before initialization
        let manager = PomodoroManager.shared
        _workMinutes = State(initialValue: Double(manager.workMinutes))
        _shortBreakMinutes = State(initialValue: Double(manager.shortBreakMinutes))
        _longBreakMinutes = State(initialValue: Double(manager.longBreakMinutes))
        _sessionsBeforeLongBreak = State(initialValue: Double(manager.sessionsBeforeLongBreak))
        _soundEnabled = State(initialValue: manager.soundEnabled)
        _vibrationEnabled = State(initialValue: manager.vibrationEnabled)
        _autoStartNextSession = State(initialValue: manager.autoStartNextSession)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - use theme background color
                Color.themeBackground.edgesIgnoringSafeArea(.all)
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        // Timer duration settings
                        VStack(alignment: .leading, spacing: 20) {
                            Text("TIMER DURATIONS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeText.opacity(0.6))
                                .tracking(2)
                            
                            // Focus time setting
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Focus Time")
                                    .font(.headline)
                                    .foregroundColor(Color.themeText)
                                
                                HStack {
                                    Text("\(Int(workMinutes)) minutes")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.themeError)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Slider(value: $workMinutes, in: 1...60, step: 1)
                                        .tint(Color.themeError)
                                        .onChange(of: workMinutes) { oldValue, newValue in
                                            pomodoroManager.updateWorkMinutes(Int(newValue))
                                        }
                                }
                            }
                            .padding()
                            .background(Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Short break setting
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Short Break")
                                    .font(.headline)
                                    .foregroundColor(Color.themeText)
                                
                                HStack {
                                    Text("\(Int(shortBreakMinutes)) minutes")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.themeSuccess)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Slider(value: $shortBreakMinutes, in: 1...30, step: 1)
                                        .tint(Color.themeSuccess)
                                        .onChange(of: shortBreakMinutes) { oldValue, newValue in
                                            pomodoroManager.updateShortBreakMinutes(Int(newValue))
                                        }
                                }
                            }
                            .padding()
                            .background(Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Long break setting
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Long Break")
                                    .font(.headline)
                                    .foregroundColor(Color.themeText)
                                
                                HStack {
                                    Text("\(Int(longBreakMinutes)) minutes")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.themeAccent)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Slider(value: $longBreakMinutes, in: 1...60, step: 1)
                                        .tint(Color.themeAccent)
                                        .onChange(of: longBreakMinutes) { oldValue, newValue in
                                            pomodoroManager.updateLongBreakMinutes(Int(newValue))
                                        }
                                }
                            }
                            .padding()
                            .background(Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Sessions before long break
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sessions Before Long Break")
                                    .font(.headline)
                                    .foregroundColor(Color.themeText)
                                
                                HStack {
                                    Text("\(Int(sessionsBeforeLongBreak)) sessions")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.themePrimary)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Slider(value: $sessionsBeforeLongBreak, in: 1...8, step: 1)
                                        .tint(Color.themePrimary)
                                        .onChange(of: sessionsBeforeLongBreak) { oldValue, newValue in
                                            pomodoroManager.updateSessionsBeforeLongBreak(Int(newValue))
                                        }
                                }
                            }
                            .padding()
                            .background(Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Notification settings
                        VStack(alignment: .leading, spacing: 20) {
                            Text("NOTIFICATIONS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeText.opacity(0.6))
                                .tracking(2)
                            
                            // Sound toggle
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.themeText)
                                    .frame(width: 26)
                                
                                Text("Sound Notifications")
                                    .font(.headline)
                                    .foregroundColor(Color.themeText)
                                
                                Spacer()
                                
                                Toggle("", isOn: $soundEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                                    .onChange(of: soundEnabled) { oldValue, newValue in
                                        pomodoroManager.updateSoundEnabled(newValue)
                                    }
                            }
                            .padding()
                            .background(Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(12)
                            
                            // Vibration toggle
                            HStack {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.themeText)
                                    .frame(width: 26)
                                
                                Text("Vibration")
                                    .font(.headline)
                                    .foregroundColor(Color.themeText)
                                
                                Spacer()
                                
                                Toggle("", isOn: $vibrationEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                                    .onChange(of: vibrationEnabled) { oldValue, newValue in
                                        pomodoroManager.updateVibrationEnabled(newValue)
                                    }
                            }
                            .padding()
                            .background(Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Behavior settings
                        VStack(alignment: .leading, spacing: 20) {
                            Text("BEHAVIOR")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.themeText.opacity(0.6))
                                .tracking(2)
                            
                            // Auto-start toggle
                            HStack {
                                Image(systemName: "timer")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.themeText)
                                    .frame(width: 26)
                                
                                Text("Auto-start Next Session")
                                    .font(.headline)
                                    .foregroundColor(Color.themeText)
                                
                                Spacer()
                                
                                Toggle("", isOn: $autoStartNextSession)
                                    .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
                                    .onChange(of: autoStartNextSession) { oldValue, newValue in
                                        pomodoroManager.updateAutoStartNextSession(newValue)
                                    }
                            }
                            .padding()
                            .background(Color.themeCardBackground.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Reset to defaults button
                        Button(action: {
                            resetToDefaults()
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Reset to Defaults")
                            }
                            .foregroundColor(Color.themeText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.themeError.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // Description of Pomodoro technique
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About the Pomodoro Technique")
                                .font(.headline)
                                .foregroundColor(Color.themeText)
                            
                            Text("The Pomodoro Technique is a time management method that uses a timer to break work into intervals, traditionally 25 minutes in length, separated by short breaks. These intervals are called \"pomodoros\". After a set of pomodoros, take a longer break to recharge.")
                                .font(.subheadline)
                                .foregroundColor(Color.themeSecondaryText)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Color.themeCardBackground.opacity(0.5))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light)
    }
    
    // MARK: - Helper Methods
    
    /// Reset all settings to default values
    private func resetToDefaults() {
        withAnimation {
            workMinutes = 25
            shortBreakMinutes = 5
            longBreakMinutes = 15
            sessionsBeforeLongBreak = 4
            soundEnabled = true
            vibrationEnabled = true
            autoStartNextSession = false
            
            // Update manager with default values
            pomodoroManager.resetToDefaults()
        }
    }
}

// MARK: - Previews

struct PomodoroSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PomodoroSettingsView()
            .preferredColorScheme(.dark)
    }
}
