import SwiftUI

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("fishiq.colorTheme") private var selectedTheme = "Forest"
    @State private var showingClearConfirmation = false
    @State private var showingClearSuccess = false

    private let themes = ["Forest", "Ocean", "Sunset", "Violet", "Default", "Black"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PERSONALIZE FISHIQ")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(Color.fishMuted)
                            Text("Settings")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.fishText)
                        }

                        settingsSectionTitle("COLOR THEME")
                        VStack(spacing: 10) {
                            ForEach(themes, id: \.self) { theme in
                                Button {
                                    selectedTheme = theme
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(themeColor(for: theme))
                                            .frame(width: 28, height: 28)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(theme)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Color.fishText)
                                            Text(themeDetail(for: theme))
                                                .font(.caption)
                                                .foregroundStyle(Color.fishMuted)
                                        }
                                        Spacer()
                                        if selectedTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(Color.fishGreen)
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        settingsSectionTitle("DATA")
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            Label("Delete All Catch History", systemImage: "trash")
                                .font(.subheadline.bold())
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(15)
                                .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
                        }

                        settingsSectionTitle("ABOUT")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FishIQ")
                                .font(.headline)
                                .foregroundStyle(Color.fishText)
                            Text("Freshwater fishing forecasts and catch tracking.")
                                .font(.caption)
                                .foregroundStyle(Color.fishMuted)
                            Text("Your catch history is stored locally on this device.")
                                .font(.caption)
                                .foregroundStyle(Color.fishMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(15)
                        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog(
                "Delete all catch history?",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All Catches", role: .destructive) {
                    CatchEntry.saveAll([])
                    showingClearSuccess = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently deletes every catch saved on this device.")
            }
            .alert("Catch history deleted", isPresented: $showingClearSuccess) {
                Button("OK", role: .cancel) { }
            }
        }
        .preferredColorScheme(Color.fishColorScheme)
    }

    private func settingsSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.4)
            .foregroundStyle(Color.fishMuted)
    }

    private func themeDetail(for theme: String) -> String {
        switch theme {
        case "Default": return "Clean white and green theme"
        case "Black": return "Pure dark theme"
        case "Ocean": return "Cool blue water theme"
        case "Sunset": return "Warm orange theme"
        case "Violet": return "Deep purple theme"
        default: return "Original green fishing theme"
        }
    }

    private func themeColor(for theme: String) -> Color {
        switch theme {
        case "Default": return Color(red: 0.95, green: 0.96, blue: 0.94)
        case "Black": return Color(red: 0.025, green: 0.025, blue: 0.03)
        case "Ocean": return Color(red: 0.35, green: 0.78, blue: 0.92)
        case "Sunset": return Color(red: 1.0, green: 0.66, blue: 0.36)
        case "Violet": return Color(red: 0.72, green: 0.60, blue: 0.98)
        default: return Color(red: 0.65, green: 0.84, blue: 0.65)
        }
    }
}
