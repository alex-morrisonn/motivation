import SwiftUI

// Break down into smaller components to reduce compile-time complexity
struct FeedbackTypeSelector: View {
    @Binding var selectedType: Int
    let types: [String]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<types.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedType = index
                    }
                }) {
                    Text(types[index])
                        .font(.system(size: 14, weight: selectedType == index ? .semibold : .regular))
                        .foregroundColor(selectedType == index ? .black : .white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedType == index ?
                                      Color.white :
                                      Color.white.opacity(0.1))
                        )
                }
            }
        }
    }
}

struct FeedbackTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Single background for the entire component
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            
            ZStack(alignment: .topLeading) {
                // Placeholder directly overlaid on TextEditor
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false) // Let taps pass through to TextEditor
                }
                
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden) // iOS 16+ way to hide background
                    .background(Color.clear) // Extra assurance for transparency
                    .foregroundColor(.white)
                    .frame(minHeight: 180)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
            }
        }
    }
}

struct DeviceInfoToggle: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "square.and.arrow.up.circle")
                .foregroundColor(.white)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Include Device Information")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text("Helps us understand issues better")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Custom styled toggle
            ZStack {
                Capsule()
                    .fill(isEnabled ? Color.green.opacity(0.5) : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(isEnabled ? Color.white : Color.gray.opacity(0.7))
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: isEnabled ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isEnabled.toggle()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
        )
    }
}

struct SubmitButton: View {
    let isEnabled: Bool
    let isSubmitting: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .padding(.trailing, 5)
                }
                
                Text(isSubmitting ? "Submitting..." : "Submit Feedback")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        !isEnabled ?
                        Color.gray.opacity(0.5) :
                        Color.white
                    )
            )
        }
        .disabled(!isEnabled || isSubmitting)
    }
}

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackText = ""
    @State private var feedbackType = 0
    @State private var contactEmail = ""
    @State private var includeDeviceInfo = true
    @State private var showingConfirmation = false
    @State private var isSubmitting = false
    
    private let feedbackTypes = ["General", "Bug Report", "Feature", "Question"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Simple background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with icon
                        VStack(spacing: 14) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color(red: 0.1, green: 0.1, blue: 0.3)))
                            
                            Text("We'd Love Your Feedback")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your thoughts help us improve Moti")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        
                        // Feedback type selector component
                        VStack(alignment: .leading, spacing: 12) {
                            Text("FEEDBACK TYPE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal, 4)
                            
                            FeedbackTypeSelector(selectedType: $feedbackType, types: feedbackTypes)
                        }
                        .padding(.horizontal)
                        
                        // Feedback text editor
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("YOUR FEEDBACK")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.6))
                                    .tracking(2)
                                
                                Spacer()
                                
                                Text("\(feedbackText.count)/500")
                                    .font(.caption)
                                    .foregroundColor(feedbackText.count > 400 ?
                                                    (feedbackText.count > 500 ? .red : .orange) :
                                                    .gray)
                            }
                            .padding(.horizontal, 4)
                            
                            FeedbackTextField(
                                text: $feedbackText,
                                placeholder: "Share your experience, suggestions, or report issues here..."
                            )
                            .onChange(of: feedbackText) { newValue in
                                if newValue.count > 500 {
                                    feedbackText = String(newValue.prefix(500))
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Contact email
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONTACT EMAIL (OPTIONAL)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal, 4)
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 16)
                                
                                TextField("your.email@example.com", text: $contactEmail)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.07))
                            )
                        }
                        .padding(.horizontal)
                        
                        // Device info toggle
                        VStack(alignment: .leading, spacing: 12) {
                            DeviceInfoToggle(isEnabled: $includeDeviceInfo)
                        }
                        .padding(.horizontal)
                        
                        // Submit button
                        SubmitButton(
                            isEnabled: !feedbackText.isEmpty,
                            isSubmitting: isSubmitting,
                            action: {
                                submitFeedback()
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Text("Thank you for helping us improve Moti!")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                            .padding(.bottom, 40)
                    }
                    .padding(.vertical, 20)
                }
                
                // Loading overlay when submitting
                if isSubmitting {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert(isPresented: $showingConfirmation) {
                Alert(
                    title: Text("Thank You!"),
                    message: Text("Your feedback has been submitted. We appreciate your input and will use it to make Moti even better."),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func submitFeedback() {
        withAnimation {
            isSubmitting = true
        }
        
        // Simulate submission with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
            showingConfirmation = true
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
