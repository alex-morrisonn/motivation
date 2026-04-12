import SwiftUI
import FirebaseAnalytics

struct AnalyticsConsentView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
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

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 18) {
                    Image(systemName: "hand.raised.app.fill")
                        .font(.system(size: 42))
                        .foregroundColor(Color.themePrimary)
                        .frame(width: 86, height: 86)
                        .background(Color.themePrimary.opacity(0.12))
                        .clipShape(Circle())

                    Text("Analytics Preferences")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color.themeText)

                    Text("Motii can use privacy-friendly product analytics to understand which features are useful and improve future releases. Core app features work the same either way.")
                        .font(.body)
                        .foregroundColor(Color.themeSecondaryText)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 14) {
                    privacyPoint(icon: "lock.shield", text: "Motii does not use this screen for cross-app tracking.")
                    privacyPoint(icon: "chart.bar", text: "Allowing analytics helps measure feature usage and app quality.")
                    privacyPoint(icon: "gearshape", text: "You can change this choice later from within the app.")
                }
                .padding(20)
                .background(Color.themeCardBackground.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                Spacer()

                VStack(spacing: 12) {
                    Button(action: allowAnalytics) {
                        Text("Allow Analytics")
                            .font(.headline)
                            .foregroundColor(Color.themeBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.themePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: declineAnalytics) {
                        Text("Not Now")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.themeSecondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.themeBackground.opacity(0.24))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }

    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.themePrimary)
                .frame(width: 32, height: 32)
                .background(Color.themePrimary.opacity(0.12))
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.themeText)

            Spacer()
        }
    }

    private func allowAnalytics() {
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(true)
        UserDefaults.standard.set(AnalyticsConsentState.allowed.rawValue, forKey: AppDefaultsKey.analyticsConsentState)
        dismiss()
    }

    private func declineAnalytics() {
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(false)
        UserDefaults.standard.set(AnalyticsConsentState.declined.rawValue, forKey: AppDefaultsKey.analyticsConsentState)
        dismiss()
    }
}
