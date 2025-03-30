import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Group {
                            sectionTitle("Introduction")
                            sectionText("""
                            This Privacy Policy explains how Moti collects, uses, and discloses information about you when you use our mobile application. By using Moti, you agree to the practices described in this Privacy Policy.
                            """)

                            sectionTitle("Information We Collect")
                            sectionText("""
                            • Usage Data: Information about your interactions with the App, including features used, time spent, and content engagement.

                            • Device Information: Details about your device, such as model, operating system, unique device identifiers, and network information.

                            • User Preferences: Your in-app preferences, favorites, and settings to personalize your experience.
                            """)

                            sectionTitle("How We Use Your Information")
                            sectionText("""
                            We use the information we collect to:
                            
                            • Operate, maintain, and improve the App
                            • Understand how users engage with the App to enhance the overall experience
                            • Identify and address technical issues
                            • Monitor usage trends and analytics
                            """)
                        }

                        Group {
                            sectionTitle("Third-Party Services")
                            sectionText("""
                            We employ the following third-party services:
                            
                            • Firebase Analytics: Collects usage data and performance metrics
                            • Firebase Crashlytics: Tracks app crashes and related technical issues
                            
                            These services may receive information directly from your device. Please consult their respective privacy policies for additional details on how they handle your data.
                            """)

                            sectionTitle("Data Storage")
                            sectionText("""
                            Most data is stored locally on your device. Certain information, such as analytics data, may be stored on our servers or those of third-party providers.
                            """)

                            sectionTitle("Your Choices")
                            sectionText("""
                            • Opt-Out of Analytics: You may disable analytics tracking through your device settings.
                            • Data Deletion: To remove all app data, simply uninstall the App from your device.
                            """)

                            sectionTitle("Children's Privacy")
                            sectionText("""
                            Moti is not intended for children under 13. We do not knowingly collect personal information from individuals under 13. If you believe your child has provided us with personal information, please contact us so we can delete it.
                            """)

                            sectionTitle("Changes to This Privacy Policy")
                            sectionText("""
                            We may update this Privacy Policy from time to time. Any changes will be posted within the App, and your continued use of the App after such updates constitutes acceptance of the revised policy.
                            """)

                            sectionTitle("Contact Us")
                            sectionText("""
                            If you have any questions or concerns about this Privacy Policy, please reach out to us at: motii.team@gmail.com.
                            """)
                        }

                        
                        // Last updated date
                        Text("Last Updated: March 2025")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                            .padding(.bottom, 50)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 10)
    }
    
    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .lineSpacing(4)
    }
}

struct TermsOfServiceView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Terms of Service")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Group {
                            sectionTitle("Agreement to Terms")
                            
                            sectionText("""
                            By using the Moti app, you agree to these Terms of Service. If you disagree with any part of the terms, you do not have permission to access the app.
                            """)
                            
                            sectionTitle("Use License")
                            
                            sectionText("""
                            We grant you a personal, non-transferable, non-exclusive license to use the Moti app on your devices. This license is solely for your personal, non-commercial use and is subject to the following restrictions:
                            
                            • You may not modify, copy, distribute, transmit, display, perform, reproduce, or publish any part of the app
                            • You may not use the app for any commercial purpose
                            • You may not transfer, license or sub-license the app to any third party
                            """)
                            
                            sectionTitle("Content")
                            
                            sectionText("""
                            All quotes, content, and materials available through the Moti app are provided for your personal motivation and inspiration. The quotes and content are the property of their respective authors and are protected by applicable copyright laws.
                            """)
                            
                            sectionTitle("App Updates")
                            
                            sectionText("""
                            We may from time to time provide enhancements or improvements to the features/functionality of the app, which may include patches, bug fixes, updates, upgrades and other modifications.
                            """)
                        }
                        
                        Group {
                            sectionTitle("Third-Party Links")
                            
                            sectionText("""
                            The app may contain links to third-party websites or services that are not owned or controlled by us. We have no control over, and assume no responsibility for, the content, privacy policies, or practices of any third-party websites or services.
                            """)
                            
                            sectionTitle("Termination")
                            
                            sectionText("""
                            We may terminate or suspend your access to the app immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.
                            """)
                            
                            sectionTitle("Changes to Terms")
                            
                            sectionText("""
                            We reserve the right, at our sole discretion, to modify or replace these Terms at any time. It is your responsibility to review these Terms periodically for changes.
                            """)
                            
                            sectionTitle("Contact Us")
                            
                            sectionText("""
                            If you have any questions about these Terms, please contact us at: motii.team@gmail.com.
                            """)
                        }
                        
                        // Last updated date
                        Text("Last Updated: March 2025")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                            .padding(.bottom, 50)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitle("Terms of Service", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.top, 10)
    }
    
    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundColor(.white.opacity(0.8))
            .lineSpacing(4)
    }
}
