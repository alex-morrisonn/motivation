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
                            This Privacy Policy describes how Moti ("we", "our", or "us") collects, uses, and shares information about you when you use our mobile application (the "App").
                            
                            By using Moti, you agree to the collection and use of information in accordance with this policy.
                            """)
                            
                            sectionTitle("Information We Collect")
                            
                            sectionText("""
                            We collect the following types of information:
                            
                            • Usage Data: We collect information about how you use our App, including app features you use, time spent in the app, and interaction with content.
                            
                            • Device Information: We collect information about your device, including device model, operating system, unique device identifiers, and network information.
                            
                            • User Preferences: We store your app preferences, favorites, and settings to provide a personalized experience.
                            """)
                            
                            sectionTitle("How We Use Your Information")
                            
                            sectionText("""
                            We use the information we collect to:
                            
                            • Provide, maintain, and improve the App
                            • Understand how you use the App to enhance user experience
                            • Detect and address technical issues
                            • Monitor usage patterns and analytics
                            """)
                            
                            sectionTitle("Third-Party Services")
                            
                            sectionText("""
                            We use the following third-party services:
                            
                            • Firebase Analytics: Used to collect usage data and app performance metrics
                            • Firebase Crashlytics: Used to track app crashes and technical issues
                            
                            These services may collect information sent by your device for their own purposes. Please review their privacy policies for more information.
                            """)
                        }
                        
                        Group {
                            sectionTitle("Data Storage")
                            
                            sectionText("""
                            Most data is stored locally on your device. Some data, such as analytics, may be stored on our servers or third-party servers.
                            """)
                            
                            sectionTitle("Your Choices")
                            
                            sectionText("""
                            You can opt-out of analytics tracking through your device settings. 
                            
                            To delete all app data, you can uninstall the app from your device.
                            """)
                            
                            sectionTitle("Children's Privacy")
                            
                            sectionText("""
                            Our App is not directed to children under 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.
                            """)
                            
                            sectionTitle("Changes to This Privacy Policy")
                            
                            sectionText("""
                            We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the App.
                            """)
                            
                            sectionTitle("Contact Us")
                            
                            sectionText("""
                            If you have any questions about this Privacy Policy, please contact us at: [YOUR CONTACT EMAIL].
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
                            If you have any questions about these Terms, please contact us at: [YOUR CONTACT EMAIL].
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

// Add these options to your MoreView
// OptionRow(
//     icon: "lock.shield",
//     title: "Privacy Policy",
//     action: { showingPrivacyPolicy.toggle() }
// )
//
// OptionRow(
//     icon: "doc.text",
//     title: "Terms of Service",
//     action: { showingTerms.toggle() }
// )
//
// .sheet(isPresented: $showingPrivacyPolicy) {
//     PrivacyPolicyView()
// }
// .sheet(isPresented: $showingTerms) {
//     TermsOfServiceView()
// }
