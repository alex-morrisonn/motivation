import SwiftUI

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .padding(.top, 30)
                        
                        Text("Moti")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                        
                        Text("About Moti")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        Text("Moti is a daily motivation companion designed to inspire and encourage you through life's journey. With a collection of carefully curated quotes across multiple categories, Moti helps you stay focused, positive, and motivated.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                            .multilineTextAlignment(.leading)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            FeaturesRow(icon: "quote.bubble", title: "Daily Quotes", description: "A new inspirational quote each day")
                            FeaturesRow(icon: "calendar", title: "Event Tracking", description: "Keep track of important dates and events")
                            FeaturesRow(icon: "square.grid.2x2", title: "Home & Lock Screen Widgets", description: "Quick inspiration at a glance")
                            FeaturesRow(icon: "heart", title: "Favorites Collection", description: "Save quotes that resonate with you")
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6).opacity(0.2))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
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
}

// Features row for About view
struct FeaturesRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
