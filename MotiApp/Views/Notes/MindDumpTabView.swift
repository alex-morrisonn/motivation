import SwiftUI

/// Mind Dump Tab View - Entry point for the notes feature in the tab bar
struct MindDumpTabView: View {
    // MARK: - Properties
    
    @ObservedObject private var noteService = NoteService.shared
    @State private var showingOnboarding = false
    @State private var isFirstLaunch: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NotesView()
            .environmentObject(noteService)
            .onAppear {
                // Check if this is the first launch
                checkFirstLaunch()
                
                // Show onboarding if this is the first time (no notes and not in debug)
                if isFirstLaunch {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingOnboarding = true
                    }
                }
            }
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView(isPresented: $showingOnboarding)
            }
    }
    
    // MARK: - Helper Methods
    
    /// Check if this is the first launch of the Mind Dump feature
    private func checkFirstLaunch() {
        let defaults = UserDefaults.standard
        let hasLaunchedBefore = defaults.bool(forKey: "MindDumpHasLaunchedBefore")
        
        isFirstLaunch = !hasLaunchedBefore && noteService.notes.isEmpty
        
        if !hasLaunchedBefore {
            defaults.set(true, forKey: "MindDumpHasLaunchedBefore")
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    // Onboarding pages
    private let pages = [
        OnboardingPage(
            title: "Welcome to Mind Dump",
            description: "A space for your unfiltered thoughts, ideas, and reflections.",
            imageName: "note.text",
            tip: "Perfect for capturing inspiration from your daily motivation quotes."
        ),
        OnboardingPage(
            title: "Choose Your Format",
            description: "From simple notes to bullet lists, markdown, or visual sketches.",
            imageName: "list.bullet.rectangle",
            tip: "Different thought patterns need different formats."
        ),
        OnboardingPage(
            title: "Focus When You Need To",
            description: "Enter focus mode to eliminate distractions when you're in the flow.",
            imageName: "arrow.up.left.and.arrow.down.right",
            tip: "Sometimes the best ideas come when you're not thinking too hard."
        ),
        OnboardingPage(
            title: "Organize Your Way",
            description: "Use colors, pins, and tags to organize your notes however you prefer.",
            imageName: "tag",
            tip: "No rigid structure - just the way your mind works."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.white : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 20 : 10, height: 6)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.white)
                            .padding()
                        }
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding()
                        }
                    } else {
                        Button(action: {
                            isPresented = false
                            // Create a first sample note when onboarding completes
                            createWelcomeNote()
                        }) {
                            Text("Get Started")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(Color.white)
                                .cornerRadius(10)
                                .padding()
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
        }
    }
    
    // Create a welcome note for first-time users
    private func createWelcomeNote() {
        let welcomeNote = Note(
            title: "Welcome to Mind Dump",
            content: "# Welcome to Mind Dump!\n\nThis is your first note. Here are some tips to get started:\n\n- **Create different types of notes** using the + button\n- **Format your content** using the toolbar at the bottom\n- **Pin important notes** to keep them at the top\n- **Add tags** to organize related notes\n- **Enter focus mode** when you need to concentrate\n\nEnjoy capturing your thoughts!",
            color: .blue,
            type: .markdown,
            isPinned: true,
            tags: ["welcome", "getting-started"]
        )
        
        NoteService.shared.addNote(welcomeNote)
    }
}

// MARK: - Supporting Types

/// Structure for onboarding page content
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let tip: String
}

/// View for displaying a single onboarding page
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())
                .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text(page.description)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Tip
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text(page.tip)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

struct MindDumpTabView_Previews: PreviewProvider {
    static var previews: some View {
        MindDumpTabView()
            .preferredColorScheme(.dark)
    }
}
