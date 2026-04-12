import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @ObservedObject private var profileManager = ProfileManager.shared

    var body: some View {
        if isActive {
            Group {
                if profileManager.hasCompletedOnboarding {
                    ContentView()
                        .environmentObject(NotificationManager.shared)
                } else {
                    OnboardingView()
                }
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackground,
                        Color.themeCardBackground.opacity(0.86),
                        Color.themeBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.themePrimary)

                    Text("Motii")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)

                    Text("Daily focus, quotes, and structure.")
                        .font(.headline)
                        .foregroundColor(Color.themeSecondaryText)
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.35)) {
                        size = 1.0
                        opacity = 1.0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        withAnimation {
                            UserDefaults.standard.set(true, forKey: "isFromSplashScreen")
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
