import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var selectedTheme: AppTheme
    
    // Initialize with the current selected theme
    init() {
        _selectedTheme = State(initialValue: ThemeManager.shared.currentTheme)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dynamic background based on selected theme
                selectedTheme.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Theme preview section
                        VStack(spacing: 16) {
                            Text("Theme Preview")
                                .font(.headline)
                                .foregroundColor(selectedTheme.text)
                            
                            // Preview card
                            ThemePreviewCard(theme: selectedTheme)
                                .padding(.horizontal)
                        }
                        
                        // Theme selection section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("CHOOSE A THEME")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTheme.text.opacity(0.6))
                                .tracking(2)
                                .padding(.horizontal)
                            
                            // Theme grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(themeManager.getAvailableThemes()) { theme in
                                    ThemeOptionView(
                                        theme: theme,
                                        isSelected: selectedTheme.id == theme.id,
                                        onSelect: {
                                            withAnimation {
                                                selectedTheme = theme
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Apply button
                        if selectedTheme.id != themeManager.currentTheme.id {
                            Button(action: {
                                // Apply the selected theme
                                withAnimation {
                                    themeManager.setTheme(selectedTheme)
                                }
                            }) {
                                Text("Apply Theme")
                                    .font(.headline)
                                    .foregroundColor(selectedTheme.background)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(selectedTheme.primary)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(selectedTheme.primary)
                }
            }
        }
        .preferredColorScheme(selectedTheme.isDark ? .dark : .light)
    }
}

// MARK: - Theme Option View

struct ThemeOptionView: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Theme color preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.background)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.divider, lineWidth: 1)
                        )
                    
                    // Theme preview elements
                    VStack(spacing: 8) {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 20, height: 20)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.accent)
                            .frame(width: 60, height: 10)
                    }
                }
                
                // Theme name
                Text(theme.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? theme.primary : ThemeManager.shared.currentTheme.text)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeManager.shared.currentTheme.cardBackground.opacity(0.3))
                    .shadow(color: isSelected ? theme.primary.opacity(0.5) : Color.clear, radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.primary : ThemeManager.shared.currentTheme.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Theme Preview Card

struct ThemePreviewCard: View {
    let theme: AppTheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Preview")
                    .font(.headline)
                    .foregroundColor(theme.text)
                
                Spacer()
                
                Circle()
                    .fill(theme.accent)
                    .frame(width: 24, height: 24)
            }
            
            // Quote card preview
            VStack(spacing: 12) {
                Text("The best way to predict the future is to create it.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.text)
                    .multilineTextAlignment(.center)
                
                Text("— Peter Drucker")
                    .font(.system(size: 14))
                    .foregroundColor(theme.secondaryText)
                
                Divider()
                    .background(theme.divider)
                
                HStack(spacing: 20) {
                    Circle()
                        .fill(theme.secondary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "heart")
                                .foregroundColor(theme.secondary)
                        )
                    
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(theme.background)
                        )
                    
                    Circle()
                        .fill(theme.secondary.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(theme.secondary)
                        )
                }
                .padding(.top, 8)
            }
            .padding()
            .background(theme.cardBackground)
            .cornerRadius(16)
            
            // Button preview
            HStack(spacing: 16) {
                Button(action: {}) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.divider, lineWidth: 1)
                        )
                }
                
                Button(action: {}) {
                    Text("Confirm")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.isDark ? theme.background : theme.text)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.primary)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(theme.background)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.divider, lineWidth: 1)
        )
    }
}

// MARK: - Preview Provider

struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSettingsView()
    }
}
