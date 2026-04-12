import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        policyScreen(
            title: "Privacy Policy",
            summary: "How \(AppMetadata.name) handles your data, permissions, and third-party services.",
            sections: privacySections
        )
    }

    private var privacySections: [PolicySection] {
        [
            PolicySection(title: "Overview", body: "\(AppMetadata.name) is designed to store most personal app data on your device. When enabled, the app may also send limited data to Firebase services for analytics, crash diagnostics, and feedback handling."),
            PolicySection(title: "Data Stored On Your Device", body: "The app stores settings, favorites, streak progress, reminders, theme choices, onboarding selections, and planned events locally using Apple system storage so the app and widgets can work properly."),
            PolicySection(title: "Feedback You Choose To Send", body: "If you submit feedback, the message you write, the category you select, your optional email address, and optional device diagnostics are sent to a Firestore database managed through Firebase. Feedback is not cached locally for later upload if your device is offline."),
            PolicySection(title: "Analytics and Diagnostics", body: "If you allow analytics, the app may send product usage events to Firebase Analytics. Crash reports may be sent to Firebase Crashlytics to help diagnose reliability issues. \(AppMetadata.name) does not use this flow for cross-app tracking."),
            PolicySection(title: "Notifications", body: "If you enable reminders, the app schedules local notifications on your device at the time you choose. Notification content is generated from the quote library stored in the app."),
            PolicySection(title: "Third-Party Services", body: "Firebase services used by the app may process technical information such as app version, device type, coarse usage patterns, crash diagnostics, and the feedback payload you choose to submit. Their handling is governed by Google's Firebase terms and privacy materials."),
            PolicySection(title: "Your Choices", body: "You can disable notifications in iPhone Settings, decline analytics from within the app, and remove local app data by deleting the app. To request deletion of submitted feedback or to ask privacy questions, contact \(AppMetadata.supportEmail)."),
            PolicySection(title: "Contact", body: "Privacy questions, deletion requests, and support inquiries can be sent to \(AppMetadata.supportEmail).")
        ]
    }

    @ViewBuilder
    private func policyScreen(title: String, summary: String, sections: [PolicySection]) -> some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackground,
                        Color.themeCardBackground.opacity(0.82),
                        Color.themeBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        policyHeader(title: title, summary: summary)

                        ForEach(sections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(Color.themeText)

                                Text(section.body)
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeSecondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)
                            .background(Color.themeCardBackground.opacity(0.92))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }

                        linkCard(
                            title: "Online Policy",
                            summary: "Open the hosted privacy policy in Safari.",
                            buttonTitle: "Open Privacy Policy",
                            destination: AppMetadata.privacyPolicyURL
                        )

                        Text("Last Updated: \(AppMetadata.legalLastUpdated)")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
    }

    private func policyHeader(title: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(Color.themeSecondaryText)

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeText)

            Text(summary)
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.themeCardBackground.opacity(0.96), Color.themePrimary.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.themeDivider.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func linkCard(title: String, summary: String, buttonTitle: String, destination: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            Text(summary)
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)

            Button(buttonTitle) {
                openURL(destination)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Color.themeBackground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.themePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.themeBackground,
                        Color.themeCardBackground.opacity(0.82),
                        Color.themeBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerCard

                        ForEach(termSections) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.title)
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(Color.themeText)

                                Text(section.body)
                                    .font(.subheadline)
                                    .foregroundColor(Color.themeSecondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)
                            .background(Color.themeCardBackground.opacity(0.92))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        }

                        linkCard(
                            title: "Online Terms",
                            summary: "Open the hosted terms of service in Safari.",
                            buttonTitle: "Open Terms",
                            destination: AppMetadata.termsOfServiceURL
                        )

                        Text("Last Updated: \(AppMetadata.legalLastUpdated)")
                            .font(.caption)
                            .foregroundColor(Color.themeSecondaryText)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TERMS")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(Color.themeSecondaryText)

            Text("Terms of Service")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeText)

            Text("The core terms that apply to use of the \(AppMetadata.name) app.")
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.themeCardBackground.opacity(0.96), Color.themePrimary.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.themeDivider.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var termSections: [PolicySection] {
        [
            PolicySection(title: "Acceptance", body: "By downloading or using \(AppMetadata.name), you agree to these terms. If you do not agree, do not use the app."),
            PolicySection(title: "Permitted Use", body: "You may use the app for your own personal, non-commercial use on Apple devices you control, subject to the App Store license terms."),
            PolicySection(title: "Quotes and Content", body: "Quotes, artwork, and written materials remain subject to the rights of their original authors or owners where applicable. The app is intended for inspiration, planning, and habit support."),
            PolicySection(title: "No Professional Advice", body: "\(AppMetadata.name) provides motivational and organizational content only. It is not medical, mental health, legal, or financial advice, and it is not a substitute for professional care."),
            PolicySection(title: "Availability", body: "The app may change over time. Features may be added, updated, suspended, or removed without prior notice."),
            PolicySection(title: "Liability", body: "To the maximum extent permitted by law, the app is provided on an as-is basis without guarantees of uninterrupted availability, fitness for a particular purpose, or specific outcomes."),
            PolicySection(title: "Contact", body: "Questions about these terms can be sent to \(AppMetadata.supportEmail).")
        ]
    }

    private func linkCard(title: String, summary: String, buttonTitle: String, destination: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(Color.themeText)

            Text(summary)
                .font(.subheadline)
                .foregroundColor(Color.themeSecondaryText)

            Button(buttonTitle) {
                openURL(destination)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Color.themeBackground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.themePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct PolicySection: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}
