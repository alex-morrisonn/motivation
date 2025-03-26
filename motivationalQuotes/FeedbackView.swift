import SwiftUI

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackText = ""
    @State private var feedbackType = 0
    @State private var contactEmail = ""
    @State private var includeDeviceInfo = true
    @State private var showingConfirmation = false
    
    private let feedbackTypes = ["General Feedback", "Bug Report", "Feature Request", "Question"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Feedback type picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Picker("Feedback Type", selection: $feedbackType) {
                                ForEach(0..<feedbackTypes.count, id: \.self) { index in
                                    Text(feedbackTypes[index]).tag(index)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .colorScheme(.dark)
                        }
                        .padding(.horizontal)
                        
                        // Feedback text editor
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Feedback")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ZStack(alignment: .topLeading) {
                                if feedbackText.isEmpty {
                                    Text("Please enter your feedback here...")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 8)
                                        .padding(.top, 8)
                                }
                                
                                TextEditor(text: $feedbackText)
                                    .foregroundColor(.white)
                                    .frame(minHeight: 150)
                                    .background(Color(UIColor.systemGray6).opacity(0.2))
                                    .cornerRadius(8)
                                    .colorScheme(.dark)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Contact email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Email (Optional)")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Your email address", text: $contactEmail)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(UIColor.systemGray6).opacity(0.2))
                                .cornerRadius(8)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.horizontal)
                        
                        // Include device info toggle
                        Toggle(isOn: $includeDeviceInfo) {
                            Text("Include Device Information")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .tint(.white)
                        
                        // Submit button
                        Button(action: {
                            showingConfirmation = true
                            // In a real app, this would send the feedback to a server
                        }) {
                            Text("Submit Feedback")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    feedbackText.isEmpty ?
                                        Color.gray :
                                        Color.white
                                )
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .disabled(feedbackText.isEmpty)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 20)
                }
                .alert(isPresented: $showingConfirmation) {
                    Alert(
                        title: Text("Thank You!"),
                        message: Text("Your feedback has been submitted. We appreciate your input!"),
                        dismissButton: .default(Text("OK")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
