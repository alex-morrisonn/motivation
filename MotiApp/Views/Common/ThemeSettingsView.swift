import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.background,
                        themeManager.currentTheme.cardBackground.opacity(0.88),
                        themeManager.currentTheme.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        headerCard
                        ThemePreviewCard(theme: themeManager.currentTheme)
                        themeGrid
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.primary)
                }
            }
        }
        .preferredColorScheme(themeManager.currentTheme.isDark ? .dark : .light)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THEME")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(themeManager.currentTheme.secondaryText)

            Text("Pick the one that feels right")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.text)

            Text("Tap any theme to apply it instantly. The preview updates live, so there is no second confirm step.")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryText)

            HStack(spacing: 12) {
                themeInfoPill(
                    title: "Current",
                    value: themeManager.currentTheme.name,
                    icon: "paintpalette.fill",
                    tint: themeManager.currentTheme.primary
                )

                themeInfoPill(
                    title: "Mode",
                    value: themeManager.currentTheme.isDark ? "Dark" : "Light",
                    icon: themeManager.currentTheme.isDark ? "moon.fill" : "sun.max.fill",
                    tint: themeManager.currentTheme.accent
                )
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    themeManager.currentTheme.cardBackground.opacity(0.96),
                    themeManager.currentTheme.primary.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(themeManager.currentTheme.divider.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var themeGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AVAILABLE THEMES")
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundColor(themeManager.currentTheme.secondaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(themeManager.getAvailableThemes()) { theme in
                    ThemeOptionView(
                        theme: theme,
                        isSelected: theme.id == themeManager.currentTheme.id,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                themeManager.setTheme(theme)
                            }
                        }
                    )
                }
            }
        }
    }

    private func themeInfoPill(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.secondaryText)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(themeManager.currentTheme.text)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(themeManager.currentTheme.background.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ThemeOptionView: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.background)
                        .frame(height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(theme.divider.opacity(0.5), lineWidth: 1)
                        )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(theme.primary)
                            .padding(10)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(theme.primary)
                                .frame(width: 16, height: 16)

                            Circle()
                                .fill(theme.secondary)
                                .frame(width: 16, height: 16)

                            Circle()
                                .fill(theme.accent)
                                .frame(width: 16, height: 16)
                        }

                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(theme.cardBackground)
                            .frame(height: 34)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(theme.primary)
                                    .frame(width: 44, height: 8)
                                    .padding(.leading, 12)
                            }

                        HStack(spacing: 6) {
                            Capsule()
                                .fill(theme.accent.opacity(0.85))
                                .frame(width: 46, height: 8)

                            Capsule()
                                .fill(theme.divider.opacity(0.55))
                                .frame(width: 28, height: 8)
                        }
                    }
                    .padding(14)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(ThemeManager.shared.currentTheme.text)

                    Text(isSelected ? "Active theme" : "Tap to apply")
                        .font(.caption)
                        .foregroundColor(ThemeManager.shared.currentTheme.secondaryText)
                }
            }
            .padding(12)
            .background(ThemeManager.shared.currentTheme.cardBackground.opacity(0.58))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? theme.primary : ThemeManager.shared.currentTheme.divider.opacity(0.6), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Preview")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(theme.text)

                    Text("This is how the app chrome and cards will look.")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                Circle()
                    .fill(theme.primary)
                    .frame(width: 14, height: 14)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Focus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.text)

                        Text("Protect the important work first.")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }

                    Spacer()

                    Text("2/3")
                        .font(.caption.weight(.bold))
                        .foregroundColor(theme.background)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.primary)
                        .clipShape(Capsule())
                }

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.background.opacity(theme.isDark ? 0.8 : 0.45))
                    .frame(height: 10)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(theme.accent)
                            .frame(width: 140, height: 10)
                    }

                HStack(spacing: 10) {
                    previewAction(title: "Quote", icon: "quote.bubble.fill", tint: theme.secondary, theme: theme)
                    previewAction(title: "Plan", icon: "calendar.badge.clock", tint: theme.primary, theme: theme)
                    previewAction(title: "More", icon: "ellipsis", tint: theme.accent, theme: theme)
                }
            }
            .padding(16)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .padding(22)
        .background(theme.background)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.divider.opacity(0.7), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func previewAction(title: String, icon: String, tint: Color, theme: AppTheme) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.16))
                .clipShape(Circle())

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(theme.background.opacity(theme.isDark ? 0.5 : 0.65))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSettingsView()
    }
}
