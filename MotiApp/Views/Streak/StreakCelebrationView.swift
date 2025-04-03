import SwiftUI

/// A fullscreen celebration view that appears when the user reaches a streak milestone
struct StreakCelebrationView: View {
    // MARK: - Properties
    
    /// The current streak count to celebrate
    let streakCount: Int
    
    /// Binding to control whether the view is showing
    @Binding var isShowing: Bool
    
    // Animation state properties
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var particlesOpacity: Double = 0
    
    /// Controls the number of particles in the animation
    private let particleCount = 50
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Celebration content
            VStack(spacing: 20) {
                // Flame and streak number
                ZStack {
                    // Particles behind the flame (confetti effect)
                    ForEach(0..<particleCount, id: \.self) { index in
                        Circle()
                            .fill(particleColor(for: index))
                            .frame(width: CGFloat.random(in: 5...15), height: CGFloat.random(in: 5...15))
                            .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -100...100))
                            .opacity(particlesOpacity)
                            .rotation3DEffect(
                                .degrees(Double.random(in: 0...360)),
                                axis: (x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1), z: CGFloat.random(in: 0...1))
                            )
                    }
                    
                    // Glowing circle behind flame
                    Circle()
                        .fill(RadialGradient(
                            gradient: Gradient(colors: [.orange, .orange.opacity(0)]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 120
                        ))
                        .frame(width: 220, height: 220)
                        .opacity(0.6)
                    
                    // Flame icon
                    Image(systemName: "flame.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, height: 90)
                        .foregroundColor(.orange)
                        .shadow(color: .orange.opacity(0.8), radius: 20, x: 0, y: 0)
                        .rotationEffect(.degrees(rotation))
                    
                    // Streak number
                    Text("\(streakCount)")
                        .font(.system(size: 75, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 0, y: 2)
                        .offset(y: 20)
                }
                .frame(width: 220, height: 220)
                
                // Congrats text
                Text(congratulationText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Motivational text
                Text(motivationalText)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                
                // Continue button
                Button(action: {
                    dismissWithAnimation()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(30)
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 30)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 40)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.0, blue: 0.0),
                        Color(red: 0.3, green: 0.05, blue: 0.0),
                        Color(red: 0.1, green: 0.0, blue: 0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(30)
            .shadow(color: .orange.opacity(0.3), radius: 30, x: 0, y: 0)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                startAnimations()
                scheduleAutoDismiss()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts the entrance animations
    private func startAnimations() {
        // Animation sequence
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Rotate flame slightly
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            rotation = 5
        }
        
        // Particle animation
        withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
            particlesOpacity = 0.8
        }
    }
    
    /// Dismisses the view with animation
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.8
        }
        
        // Actually dismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
    
    /// Schedules auto-dismiss if user doesn't interact
    private func scheduleAutoDismiss() {
        // Auto dismiss after 5 seconds if no interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if isShowing {
                dismissWithAnimation()
            }
        }
    }
    
    /// Returns a random particle color based on index
    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [.orange, .yellow, .red, .pink, .purple]
        return colors[index % colors.count]
    }
    
    // MARK: - Dynamic Text Content
    
    /// Dynamic congratulation text based on streak length
    private var congratulationText: String {
        if streakCount >= 100 {
            return "Phenomenal Dedication!"
        } else if streakCount >= 30 {
            return "Amazing Persistence!"
        } else if streakCount >= 7 {
            return "Fantastic Progress!"
        } else {
            return "Great Job!"
        }
    }
    
    /// Dynamic motivational text based on streak length
    private var motivationalText: String {
        if streakCount >= 100 {
            return "Your \(streakCount)-day streak is truly extraordinary. You've made motivation a core part of your life!"
        } else if streakCount >= 30 {
            return "You've maintained your streak for \(streakCount) days! Your commitment to daily inspiration is inspiring others."
        } else if streakCount >= 7 {
            return "\(streakCount) days in a row! Your consistency is building a foundation for lasting positive change."
        } else {
            return "You've used Moti for \(streakCount) consecutive days. Keep the momentum going!"
        }
    }
}

// MARK: - Preview

struct StreakCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        StreakCelebrationView(
            streakCount: 7,
            isShowing: .constant(true)
        )
    }
}
