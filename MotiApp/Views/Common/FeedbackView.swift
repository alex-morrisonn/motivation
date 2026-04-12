import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackText = ""
    @State private var feedbackType = 0
    @State private var contactEmail = ""
    @State private var includeDeviceInfo = true
    @State private var showingConfirmation = false
    @State private var isSubmitting = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    private let feedbackTypes = ["General", "Bug Report", "Feature", "Question"]

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
                        feedbackTypeCard
                        feedbackTextCard
                        contactCard
                        deviceInfoCard
                        submitCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }

                if isSubmitting {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()

                    ProgressView("Sending...")
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Color.themeCardBackground.opacity(0.98))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.themePrimary)
                }
            }
            .alert("Thank You", isPresented: $showingConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your feedback has been submitted and will help guide the next improvements.")
            }
            .alert("Error Submitting Feedback", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FEEDBACK")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(Color.themeSecondaryText)

            Text("Tell me what needs to get better")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.themeText)

            Text("Use this to report friction, bugs, or missing features while the context is still fresh.")
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

    private var feedbackTypeCard: some View {
        cardSection(title: "Type", subtitle: "Choose the best fit so the feedback is easier to triage.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                ForEach(Array(feedbackTypes.enumerated()), id: \.offset) { index, type in
                    Button(action: {
                        feedbackType = index
                    }) {
                        Text(type)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(feedbackType == index ? Color.themeBackground : Color.themeText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(feedbackType == index ? Color.themePrimary : Color.themeBackground.opacity(0.28))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var feedbackTextCard: some View {
        cardSection(title: "Your Feedback", subtitle: "\(feedbackText.count)/500 characters") {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.themeBackground.opacity(0.28))

                if feedbackText.isEmpty {
                    Text("Share your experience, what felt off, and what you expected instead.")
                        .font(.subheadline)
                        .foregroundColor(Color.themeSecondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $feedbackText)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(Color.themeText)
                    .frame(minHeight: 180)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .onChange(of: feedbackText) { _, newValue in
                        if newValue.count > 500 {
                            feedbackText = String(newValue.prefix(500))
                        }
                    }
            }
        }
    }

    private var contactCard: some View {
        cardSection(title: "Contact Email", subtitle: "Optional, if you want a follow-up.") {
            TextField("your.email@example.com", text: $contactEmail)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .foregroundColor(Color.themeText)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.themeBackground.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var deviceInfoCard: some View {
        cardSection(title: "Diagnostics", subtitle: "Useful when reporting a bug or crash.") {
            Toggle(isOn: $includeDeviceInfo) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Include device information")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.themeText)

                    Text("App and device details help reproduce issues faster. Feedback is sent securely and is not stored locally if the device is offline.")
                        .font(.caption)
                        .foregroundColor(Color.themeSecondaryText)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Color.themePrimary))
        }
    }

    private var submitCard: some View {
        VStack(spacing: 14) {
            Button(action: submitFeedback) {
                Text(isSubmitting ? "Submitting..." : "Submit Feedback")
                    .font(.headline)
                    .foregroundColor(Color.themeBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(feedbackText.isEmpty ? Color.themeSecondaryText.opacity(0.45) : Color.themePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(feedbackText.isEmpty || isSubmitting)

            Text("Short, specific feedback is the most useful.")
                .font(.caption)
                .foregroundColor(Color.themeSecondaryText)
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func cardSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(Color.themeText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.themeSecondaryText)
            }

            content()
        }
        .padding(20)
        .background(Color.themeCardBackground.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.themeDivider.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func submitFeedback() {
        guard !feedbackText.isEmpty else {
            return
        }

        if !contactEmail.isEmpty && !isValidEmail(contactEmail) {
            errorMessage = "Please enter a valid email address or leave the field empty."
            showingErrorAlert = true
            return
        }

        withAnimation {
            isSubmitting = true
        }

        let typeString = feedbackTypes[feedbackType]

        Task {
            do {
                let result = try await FeedbackService.sendFeedback(
                    text: feedbackText,
                    type: typeString,
                    email: contactEmail,
                    includeDeviceInfo: includeDeviceInfo
                )

                await MainActor.run {
                    isSubmitting = false

                    if result.success {
                        showingConfirmation = true
                    } else {
                        errorMessage = result.error?.errorDescription ?? "Unable to submit your feedback. Please try again later."
                        showingErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Error: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
