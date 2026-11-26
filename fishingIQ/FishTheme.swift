import SwiftUI

// MARK: - Design Colors

extension Color {
    static var fishThemeName: String {
        UserDefaults.standard.string(forKey: "fishiq.colorTheme") ?? "Forest"
    }

    static var fishColorScheme: ColorScheme {
        fishThemeName == "Default" ? .light : .dark
    }

    static var fishText: Color {
        fishThemeName == "Default" ? Color(red: 0.10, green: 0.13, blue: 0.11) : .white
    }

    static var fishBackground: Color {
        switch fishThemeName {
        case "Default": return Color(red: 0.95, green: 0.96, blue: 0.94)
        case "Black": return Color(red: 0.025, green: 0.025, blue: 0.03)
        case "Ocean": return Color(red: 0.035, green: 0.075, blue: 0.12)
        case "Sunset": return Color(red: 0.13, green: 0.065, blue: 0.045)
        case "Violet": return Color(red: 0.085, green: 0.055, blue: 0.13)
        default: return Color(red: 0.055, green: 0.09, blue: 0.075)
        }
    }

    static var fishCard: Color {
        switch fishThemeName {
        case "Default": return .white
        case "Black": return Color(red: 0.09, green: 0.09, blue: 0.10)
        case "Ocean": return Color(red: 0.07, green: 0.15, blue: 0.21)
        case "Sunset": return Color(red: 0.20, green: 0.105, blue: 0.075)
        case "Violet": return Color(red: 0.15, green: 0.10, blue: 0.21)
        default: return Color(red: 0.105, green: 0.16, blue: 0.135)
        }
    }

    static var fishGreen: Color {
        switch fishThemeName {
        case "Default": return Color(red: 0.16, green: 0.43, blue: 0.25)
        case "Black": return Color(red: 0.45, green: 0.82, blue: 0.53)
        case "Ocean": return Color(red: 0.35, green: 0.78, blue: 0.92)
        case "Sunset": return Color(red: 1.0, green: 0.66, blue: 0.36)
        case "Violet": return Color(red: 0.72, green: 0.60, blue: 0.98)
        default: return Color(red: 0.65, green: 0.84, blue: 0.65)
        }
    }

    static var fishMuted: Color {
        switch fishThemeName {
        case "Default": return Color(red: 0.38, green: 0.43, blue: 0.39)
        case "Black": return Color(red: 0.65, green: 0.67, blue: 0.68)
        case "Ocean": return Color(red: 0.61, green: 0.75, blue: 0.82)
        case "Sunset": return Color(red: 0.82, green: 0.70, blue: 0.61)
        case "Violet": return Color(red: 0.73, green: 0.68, blue: 0.81)
        default: return Color(red: 0.63, green: 0.71, blue: 0.66)
        }
    }
}
