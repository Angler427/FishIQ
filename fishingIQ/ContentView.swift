import SwiftUI

import CoreLocation
import PhotosUI
import UIKit



// MARK: - Main App

struct ContentView: View {
    @AppStorage("fishiq.colorTheme") private var selectedTheme = "Forest"

    var body: some View {
        TabView {
            DiscoverHomeView()
                .tabItem {
                    Label("Discover", systemImage: "water.waves")
                }

            ExperimentCenterView()
                .tabItem {
                    Label("Experiments", systemImage: "flask")
                }

            LakePassportView()
                .tabItem {
                    Label("Passport", systemImage: "map")
                }

            ProfileHomeView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        .tint(Color.fishGreen)
        .preferredColorScheme(Color.fishColorScheme)
        .id(selectedTheme)
    }
}

// MARK: - Discover

private struct DiscoverHomeView: View {
    @State private var showingLakeExplorer = false
    @State private var showingForecast = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EXPLORE FRESHWATER")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(Color.fishMuted)
                            Text("Discover")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.fishText)
                            Text("Explore lakes, understand the water, and find your next place to fish.")
                                .font(.subheadline)
                                .foregroundStyle(Color.fishMuted)
                        }

                        Button { showingLakeExplorer = true } label: {
                            navigationFeatureCard(
                                title: "Lake Detective",
                                subtitle: "Explore lake maps, waterbodies, and available lake information.",
                                symbol: "map.fill",
                                prominent: true
                            )
                        }
                        .buttonStyle(.plain)

                        Button { showingForecast = true } label: {
                            navigationFeatureCard(
                                title: "Fishing Conditions",
                                subtitle: "Check local weather and the fishing forecast.",
                                symbol: "cloud.sun.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingLakeExplorer) { LakesView() }
            .sheet(isPresented: $showingForecast) { ForecastView() }
        }
    }
}

// MARK: - Experiments

private struct ExperimentCenterView: View {
    @State private var showingPlanner = false
    @State private var showingCatchHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TEST. RECORD. LEARN.")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(Color.fishMuted)
                            Text("Experiments")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.fishText)
                            Text("Keep track of what you try and what happens on the water.")
                                .font(.subheadline)
                                .foregroundStyle(Color.fishMuted)
                        }

                        Button { showingPlanner = true } label: {
                            navigationFeatureCard(
                                title: "Plan an Outing",
                                subtitle: "Choose a lake, target species, and trip dates.",
                                symbol: "calendar",
                                prominent: true
                            )
                        }
                        .buttonStyle(.plain)

                        Button { showingCatchHistory = true } label: {
                            navigationFeatureCard(
                                title: "Catch Results",
                                subtitle: "Review catches, photos, and fishing history.",
                                symbol: "fish.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 7) {
                            Label("Experiment tracking is next", systemImage: "flask")
                                .font(.headline)
                                .foregroundStyle(Color.fishText)
                            Text("The next upgrade will let you define a fishing question, record what you tested, and compare results across trips.")
                                .font(.subheadline)
                                .foregroundStyle(Color.fishMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingPlanner) { FishingFeaturesView() }
            .sheet(isPresented: $showingCatchHistory) { CatchLogView() }
        }
    }
}

// MARK: - Lake Passport

private struct LakePassportView: View {
    @State private var showingLakeExplorer = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("YOUR FRESHWATER JOURNEY")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(Color.fishMuted)
                            Text("Lake Passport")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.fishText)
                            Text("Build a record of the lakes you explore and the species you discover.")
                                .font(.subheadline)
                                .foregroundStyle(Color.fishMuted)
                        }

                        VStack(spacing: 12) {
                            Image(systemName: "map")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(Color.fishGreen)
                            Text("Your passport starts here")
                                .font(.title3.bold())
                                .foregroundStyle(Color.fishText)
                            Text("Lake visits, species discoveries, and achievements will collect here as the Passport feature is built.")
                                .font(.subheadline)
                                .foregroundStyle(Color.fishMuted)
                                .multilineTextAlignment(.center)
                            Button { showingLakeExplorer = true } label: {
                                Label("Explore lakes", systemImage: "water.waves")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.fishBackground)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(Color.fishGreen, in: Capsule())
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingLakeExplorer) { LakesView() }
        }
    }
}

// MARK: - Profile

private struct ProfileHomeView: View {
    @State private var catches = CatchEntry.loadAll()
    @State private var showingSettings = false

    private var speciesCount: Int { Set(catches.map { $0.species }).count }
    private var lakeCount: Int { Set(catches.map { $0.lake }.filter { !$0.isEmpty }).count }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("YOUR FISHIQ")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(Color.fishMuted)
                            Text("Profile")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.fishText)
                            Text("Your personal fishing history and app preferences.")
                                .font(.subheadline)
                                .foregroundStyle(Color.fishMuted)
                        }

                        HStack(spacing: 10) {
                            profileStat(value: "\(catches.count)", title: "CATCHES", symbol: "fish.fill")
                            profileStat(value: "\(speciesCount)", title: "SPECIES", symbol: "water.waves")
                            profileStat(value: "\(lakeCount)", title: "LAKES FISHED", symbol: "map")
                        }

                        Button { showingSettings = true } label: {
                            navigationFeatureCard(
                                title: "Settings",
                                subtitle: "Change your theme and manage local app data.",
                                symbol: "gearshape.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { catches = CatchEntry.loadAll() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }
}

// MARK: - Shared Navigation Components

private func navigationFeatureCard(
    title: String,
    subtitle: String,
    symbol: String,
    prominent: Bool = false
) -> some View {
    HStack(spacing: 14) {
        Image(systemName: symbol)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(prominent ? Color.fishBackground : Color.fishGreen)
            .frame(width: 50, height: 50)
            .background(
                prominent ? Color.fishGreen.opacity(0.95) : Color.fishBackground,
                in: RoundedRectangle(cornerRadius: 14)
            )

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.fishText)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.fishMuted)
                .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 4)
        Image(systemName: "chevron.right")
            .font(.caption.bold())
            .foregroundStyle(Color.fishMuted)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 18))
    .overlay {
        RoundedRectangle(cornerRadius: 18)
            .stroke(prominent ? Color.fishGreen.opacity(0.35) : Color.clear, lineWidth: 1)
    }
}

private func profileStat(value: String, title: String, symbol: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.fishGreen)
        Text(value)
            .font(.system(size: 23, weight: .bold, design: .rounded))
            .foregroundStyle(Color.fishText)
        Text(title)
            .font(.system(size: 8, weight: .bold))
            .tracking(0.5)
            .foregroundStyle(Color.fishMuted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
}

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



// MARK: - Fishing Score



private struct FishingScore {

    let total: Int

    let wind: Int

    let precipitation: Int

    let sky: Int

    let temperature: Int

    let rating: String

    let explanation: String



    init(weather: FishingWeather, species: String) {

        let windScore = Self.windScore(weather.windMPH)

        let precipitationScore = Self.precipitationScore(weather.precipitationChance)

        let skyScore = Self.skyScore(weather.condition)

        let temperatureScore = Self.temperatureScore(

            weather.temperatureF,

            for: species

        )



        // Air temperature is only a rough proxy for fishing conditions.

        // Seasonal guidance is shown separately; water temperature is not yet available.

        let weighted = (

            Double(windScore) * 0.30 +

            Double(precipitationScore) * 0.25 +

            Double(skyScore) * 0.25 +

            Double(temperatureScore) * 0.20

        )



        wind = windScore

        precipitation = precipitationScore

        sky = skyScore

        temperature = temperatureScore

        total = Int(weighted.rounded())



        switch total {

        case 80...100:

            rating = "Excellent"

            explanation = "Weather conditions look favorable. This could be a good time to get out."

        case 65..<80:

            rating = "Good"

            explanation = "Conditions are fairly favorable. A few factors may affect the bite."

        case 45..<65:

            rating = "Fair"

            explanation = "The conditions are mixed. Adjust your presentation and stay flexible."

        default:

            rating = "Tough"

            explanation = "Weather conditions may make fishing more challenging today."

        }

    }



    private static func windScore(_ mph: Double) -> Int {

        switch mph {

        case ..<2: return 65

        case 2..<6: return 82

        case 6..<13: return 100

        case 13..<18: return 78

        case 18..<25: return 52

        default: return 30

        }

    }



    private static func precipitationScore(_ chance: Double) -> Int {

        switch chance {

        case ..<10: return 72

        case 10..<35: return 90

        case 35..<60: return 100

        case 60..<80: return 68

        default: return 42

        }

    }



    private static func skyScore(_ condition: String) -> Int {

        let value = condition.lowercased()



        if value.contains("thunder") { return 15 }

        if value.contains("snow") { return 38 }

        if value.contains("overcast") { return 92 }

        if value.contains("cloud") { return 88 }

        if value.contains("drizzle") { return 88 }

        if value.contains("rain") { return 78 }

        if value.contains("fog") { return 72 }

        if value.contains("clear") || value.contains("sun") { return 76 }

        return 65

    }



    private static func temperatureScore(_ fahrenheit: Double, for species: String) -> Int {

        let range: ClosedRange<Double>



        switch species {

        case "Largemouth Bass":

            range = 60...80

        case "Smallmouth Bass":

            range = 55...75

        case "Northern Pike":

            range = 50...70

        case "Walleye":

            range = 50...70

        case "Trout":

            range = 45...65

        default:

            range = 55...75

        }



        if range.contains(fahrenheit) {

            return 100

        }



        let distance: Double

        if fahrenheit < range.lowerBound {

            distance = range.lowerBound - fahrenheit

        } else {

            distance = fahrenheit - range.upperBound

        }



        return max(25, 100 - Int(distance * 3.0))

    }

}



// MARK: - Forecast Dashboard



struct ForecastView: View {

    @StateObject private var locationManager = LocationManager()



    @State private var weather: FishingWeather?

    @State private var isLoading = false

    @State private var errorMessage: String?

    @State private var selectedSpecies = "Largemouth Bass"
    @State private var expandedWeatherCard: String? = nil



    private let weatherService = FishingWeatherService()



    private let species = [

        "Largemouth Bass",

        "Smallmouth Bass",

        "Northern Pike",

        "Walleye",

        "Trout"

    ]



    private var score: FishingScore? {

        guard let weather else { return nil }

        return FishingScore(weather: weather, species: selectedSpecies)

    }



    var body: some View {

        NavigationStack {

            ZStack {

                Color.fishBackground

                    .ignoresSafeArea()



                ScrollView {

                    VStack(alignment: .leading, spacing: 22) {

                        header

                        fishingScoreCard

                        speciesSelector

                        seasonalConditionsCard

                        conditionsSection

                        multiDayForecastCard

                        fishingAdvice

                        refreshButton

                    }

                    .padding()

                }

            }

            .toolbar(.hidden, for: .navigationBar)

            .onChange(of: locationManager.location) { _, newLocation in

                guard let newLocation else { return }

                Task {

                    await loadWeather(for: newLocation)

                }

            }

            .onChange(of: locationManager.errorMessage) { _, newError in

                if let newError {

                    errorMessage = newError

                }

            }

        }

        .preferredColorScheme(Color.fishColorScheme)

    }



    // MARK: Header



    private var header: some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack {

                VStack(alignment: .leading, spacing: 3) {

                    Text("FISHIQ")

                        .font(.system(size: 29, weight: .black))

                        .tracking(2)



                    Text("FRESHWATER INTELLIGENCE")

                        .font(.system(size: 9, weight: .bold))

                        .tracking(2)

                        .foregroundStyle(Color.fishMuted)

                }



                Spacer()



                Image(systemName: "water.waves")

                    .font(.system(size: 27))

                    .foregroundStyle(Color.fishGreen)

            }



            HStack {

                Label("LOCAL CONDITIONS", systemImage: "location.fill")

                    .font(.system(size: 11, weight: .bold))

                    .foregroundStyle(Color.fishMuted)



                Spacer()



                Text("POWERED BY OPEN-METEO")

                    .font(.system(size: 9, weight: .bold))

                    .foregroundStyle(Color.fishGreen)

            }

        }

    }



    // MARK: Fishing Score Card



    private var fishingScoreCard: some View {

        VStack(alignment: .leading, spacing: 16) {

            HStack {

                Text("FISHING OUTLOOK")

                    .font(.system(size: 11, weight: .bold))

                    .tracking(1.5)

                    .foregroundStyle(Color.fishMuted)



                Spacer()



                Text("WEATHER ESTIMATE")

                    .font(.system(size: 9, weight: .bold))

                    .foregroundStyle(Color.fishGreen)

            }



            HStack(alignment: .center, spacing: 18) {

                ZStack {

                    Circle()

                        .stroke(Color.white.opacity(0.10), lineWidth: 10)



                    Circle()

                        .trim(from: 0, to: CGFloat(score?.total ?? 0) / 100)

                        .stroke(

                            scoreColor,

                            style: StrokeStyle(lineWidth: 10, lineCap: .round)

                        )

                        .rotationEffect(.degrees(-90))



                    VStack(spacing: 0) {

                        Text(score.map { "\($0.total)" } ?? "--")

                            .font(.system(size: 39, weight: .bold, design: .rounded))

                            .foregroundStyle(Color.fishText)



                        Text(" / 100")

                            .font(.system(size: 10, weight: .medium))

                            .foregroundStyle(Color.fishMuted)

                    }

                }

                .frame(width: 112, height: 112)



                VStack(alignment: .leading, spacing: 6) {

                    Text(score?.rating ?? (isLoading ? "Loading..." : "Awaiting weather"))

                        .font(.title2.bold())

                        .foregroundStyle(scoreColor)



                    Text(score?.explanation ?? "Get your local weather to calculate a fishing score.")

                        .font(.caption)

                        .foregroundStyle(Color.fishMuted)

                        .fixedSize(horizontal: false, vertical: true)

                }

            }



            if isLoading {

                ProgressView()

                    .tint(Color.fishGreen)

            }



            Text("This is a weather-based estimate, not a guarantee of fish activity. Seasonal guidance is shown separately; water temperature is not available yet.")

                .font(.system(size: 10))

                .foregroundStyle(Color.fishMuted)

                .fixedSize(horizontal: false, vertical: true)

        }

        .padding(20)

        .frame(maxWidth: .infinity, alignment: .leading)

        .background(

            LinearGradient(

                colors: Color.fishThemeName == "Default"
                    ? [
                        Color(red: 0.88, green: 0.95, blue: 0.89),
                        Color.white
                    ]
                    : [
                        Color(red: 0.13, green: 0.23, blue: 0.17),
                        Color.fishCard
                    ],

                startPoint: .topLeading,

                endPoint: .bottomTrailing

            ),

            in: RoundedRectangle(cornerRadius: 22)

        )

    }



    private var scoreColor: Color {

        guard let total = score?.total else { return Color.fishGreen }

        switch total {

        case 80...100: return Color.fishGreen

        case 60..<80: return Color.yellow

        case 40..<60: return Color.orange

        default: return Color.red

        }

    }



    // MARK: Species Selector



    private var speciesSelector: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("TARGET SPECIES")



            Menu {

                ForEach(species, id: \.self) { item in

                    Button {

                        selectedSpecies = item

                    } label: {

                        if selectedSpecies == item {

                            Label(item, systemImage: "checkmark")

                        } else {

                            Text(item)

                        }

                    }

                }

            } label: {

                HStack {

                    Image(systemName: "fish.fill")

                        .foregroundStyle(Color.fishGreen)



                    Text(selectedSpecies)

                        .fontWeight(.semibold)

                        .foregroundStyle(Color.fishText)



                    Spacer()



                    Image(systemName: "chevron.down")

                        .foregroundStyle(Color.fishMuted)

                }

                .padding(16)

                .background(

                    Color.fishCard,

                    in: RoundedRectangle(cornerRadius: 14)

                )

            }

        }

    }



    // MARK: Seasonal Fishing Conditions

    private var currentSeason: String {
        let month = Calendar.current.component(.month, from: Date())
        let isNorthernHemisphere = (weather?.latitude ?? 45) >= 0

        let northernSeason: String
        switch month {
        case 3...5: northernSeason = "SPRING"
        case 6...8: northernSeason = "SUMMER"
        case 9...11: northernSeason = "FALL"
        default: northernSeason = "WINTER"
        }

        if isNorthernHemisphere { return northernSeason }

        switch northernSeason {
        case "SPRING": return "FALL"
        case "SUMMER": return "WINTER"
        case "FALL": return "SPRING"
        default: return "SUMMER"
        }
    }

    private var seasonalAdviceText: String {
        switch currentSeason {
        case "SPRING":
            switch selectedSpecies {
            case "Largemouth Bass", "Smallmouth Bass":
                return "As water warms, bass may move toward shallow flats and protected bays. Check nearby cover and follow local spawning-season rules."
            case "Northern Pike":
                return "Pike may use shallow, warming areas in spring. Look for emerging weeds, bays, and nearby drop-offs."
            case "Walleye":
                return "Walleye activity can be strong around spring spawning periods. Focus on current, shorelines, and nearby structure where legal."
            default:
                return "Look for stable, cool water and seasonal movement. Trout locations and rules vary a lot by waterbody."
            }
        case "SUMMER":
            switch selectedSpecies {
            case "Largemouth Bass", "Smallmouth Bass":
                return "Low-light periods can be productive. During hot afternoons, check shade, vegetation edges, and deeper structure."
            case "Northern Pike":
                return "During warm periods, pike may use cooler, deeper water or weed edges. Avoid stressing fish in unusually warm water."
            case "Walleye":
                return "Try low-light periods and deeper structure during bright afternoons. Windblown points and edges can be worth checking."
            default:
                return "Prioritize cool, well-oxygenated water. Warm water can stress trout, so check local guidance before targeting them."
            }
        case "FALL":
            switch selectedSpecies {
            case "Largemouth Bass", "Smallmouth Bass":
                return "Cooling water can shift bass toward baitfish and transition areas. Check points, remaining vegetation, and nearby deeper water."
            case "Northern Pike":
                return "Pike may follow baitfish toward shallower feeding areas. Check weed edges, points, and nearby drop-offs."
            case "Walleye":
                return "Cooling water can make baitfish movement important. Check rocky points, breaks, and areas where baitfish gather."
            default:
                return "Cooling water can change trout activity and feeding patterns. Check local stream or lake conditions and seasonal regulations."
            }
        default:
            switch selectedSpecies {
            case "Largemouth Bass", "Smallmouth Bass":
                return "Fish metabolism often slows in cold water. Try slower presentations around deeper structure or remaining cover."
            case "Northern Pike":
                return "Pike may be found around remaining vegetation and deeper edges. Open-water and ice-fishing opportunities depend on local conditions."
            case "Walleye":
                return "Cold-water walleye fishing often involves slower presentations near structure. Local seasonal rules and access conditions matter."
            default:
                return "Look for stable, suitable water and slower winter patterns. Trout regulations and conditions vary by waterbody."
            }
        }
    }

    private var seasonalConditionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("SEASONAL FISHING CONDITIONS")

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: seasonalSymbol)
                        .font(.title2)
                        .foregroundStyle(Color.fishGreen)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(currentSeason) PATTERNS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1)
                            .foregroundStyle(Color.fishGreen)
                        Text(selectedSpecies)
                            .font(.headline)
                            .foregroundStyle(Color.fishText)
                    }
                    Spacer()
                }

                Text(seasonalAdviceText)
                    .font(.caption)
                    .foregroundStyle(Color.fishMuted)
                    .fixedSize(horizontal: false, vertical: true)

                if currentSeason == "WINTER" {
                    Label("Never assume ice is safe. Check local official ice reports and conditions before going onto ice.", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Seasonal guidance is general. Water temperature, lake depth, and local regulations can change the pattern.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fishMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var seasonalSymbol: String {
        switch currentSeason {
        case "SPRING": return "leaf.fill"
        case "SUMMER": return "sun.max.fill"
        case "FALL": return "wind"
        default: return "snowflake"
        }
    }

    // MARK: Seven-Day Forecast

    private var multiDayForecastCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("7-DAY WEATHER OUTLOOK")

            if let weather, !weather.dailyForecast.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(weather.dailyForecast.indices, id: \.self) { index in
                            let day = weather.dailyForecast[index]
                            VStack(spacing: 8) {
                                Text(index == 0 ? "Today" : day.dayName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.fishText)

                                Image(systemName: day.symbolName)
                                    .font(.title3)
                                    .foregroundStyle(Color.fishGreen)
                                    .frame(height: 26)

                                Text("\(Int(day.highF.rounded()))°")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(Color.fishText)

                                Text("\(Int(day.lowF.rounded()))°")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.fishMuted)

                                Label("\(Int(day.precipitationChance.rounded()))%", systemImage: "drop.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.fishMuted)

                                Label("\(Int(day.maxWindMPH.rounded())) mph", systemImage: "wind")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.fishMuted)
                            }
                            .frame(width: 82)
                            .padding(.vertical, 12)
                            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            } else if isLoading {
                ProgressView()
                    .tint(Color.fishGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
            } else {
                Text("Get local weather to see the seven-day outlook.")
                    .font(.caption)
                    .foregroundStyle(Color.fishMuted)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: Conditions



    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("WEATHER CONDITIONS")

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 12
            ) {
                conditionCard(
                    icon: "wind",
                    title: "WIND",
                    value: weather.map { "\(Int($0.windMPH.rounded())) mph" } ?? "--",
                    scoreValue: score?.wind
                )

                conditionCard(
                    icon: "thermometer.medium",
                    title: "AIR TEMP",
                    value: weather.map { "\(Int($0.temperatureF.rounded()))°F" } ?? "--",
                    scoreValue: score?.temperature
                )

                conditionCard(
                    icon: "cloud.rain",
                    title: "PRECIP. CHANCE",
                    value: weather.map { "\(Int($0.precipitationChance.rounded()))%" } ?? "--",
                    scoreValue: score?.precipitation
                )

                conditionCard(
                    icon: "gauge",
                    title: "PRESSURE",
                    value: weather.map { "\(Int($0.pressureHPa.rounded())) hPa" } ?? "--",
                    scoreValue: nil
                )
            }

            if let weather {
                HStack(spacing: 10) {
                    Image(systemName: "cloud.sun")
                        .foregroundStyle(Color.fishGreen)
                    Text(weather.condition)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.fishText)
                    Spacer()
                    Text("Current conditions")
                        .font(.caption)
                        .foregroundStyle(Color.fishMuted)
                }
                .padding(14)
                .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func conditionCard(
        icon: String,
        title: String,
        value: String,
        scoreValue: Int?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedWeatherCard = expandedWeatherCard == title ? nil : title
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(Color.fishGreen)

                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Color.fishMuted)

                    Text(value)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(Color.fishText)

                    if let scoreValue {
                        Text("Factor: \(scoreValue)/100")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.fishMuted)
                    } else {
                        Text("Not scored")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.fishMuted)
                    }

                    HStack(spacing: 5) {
                        Text(expandedWeatherCard == title ? "Show less" : "Tap for details")
                        Image(systemName: expandedWeatherCard == title ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.fishGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expandedWeatherCard == title, let weather {
                weatherDetails(for: title, weather: weather)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func weatherDetails(for title: String, weather: FishingWeather) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Divider().overlay(Color.white.opacity(0.12))

            if title == "WIND" {
                Text("TODAY'S WIND")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fishMuted)

                detailRow("Right now", "\(Int(weather.windMPH.rounded())) mph")

                if let peak = weather.hourly.max(by: { $0.windMPH < $1.windMPH }) {
                    detailRow("Peak wind", "\(Int(peak.windMPH.rounded())) mph · \(peak.displayTime)")
                }

                if let low = weather.hourly.min(by: { $0.windMPH < $1.windMPH }) {
                    detailRow("Lowest wind", "\(Int(low.windMPH.rounded())) mph · \(low.displayTime)")
                }
            } else if title == "AIR TEMP" {
                Text("TODAY'S TEMPERATURE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fishMuted)

                detailRow("Right now", "\(Int(weather.temperatureF.rounded()))°F")

                if let high = weather.hourly.max(by: { $0.temperatureF < $1.temperatureF }) {
                    detailRow("Today's high", "\(Int(high.temperatureF.rounded()))°F · \(high.displayTime)")
                }

                if let low = weather.hourly.min(by: { $0.temperatureF < $1.temperatureF }) {
                    detailRow("Today's low", "\(Int(low.temperatureF.rounded()))°F · \(low.displayTime)")
                }
            } else if title == "PRECIP. CHANCE" {
                Text("HOURLY RAIN CHANCE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fishMuted)

                ScrollView(.vertical) {
                    LazyVStack(spacing: 9) {
                        ForEach(Array(weather.hourly.enumerated()), id: \.offset) { item in
                            let point = item.element
                            let previous = item.offset > 0 ? weather.hourly[item.offset - 1].precipitationChance : point.precipitationChance
                            let change = Int((point.precipitationChance - previous).rounded())

                            HStack {
                                Text(point.displayTime)
                                    .foregroundStyle(Color.fishMuted)
                                Spacer()
                                Text("\(Int(point.precipitationChance.rounded()))%")
                                    .foregroundStyle(Color.fishText)
                                    .fontWeight(.semibold)
                                if item.offset > 0 && change != 0 {
                                    Text("\(change > 0 ? "+" : "")\(change)%")
                                        .foregroundStyle(change > 0 ? Color.orange : Color.fishGreen)
                                        .fontWeight(.semibold)
                                }
                            }
                            .font(.system(size: 11))
                        }
                    }
                }
                .frame(height: 150)
                .scrollIndicators(.visible)
            } else if title == "PRESSURE" {
                Text("PRESSURE TREND · HPA")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fishMuted)

                detailRow("Right now", "\(Int(weather.pressureHPa.rounded())) hPa")
                detailRow("Today's high", "\(Int(weather.highestPressure.rounded())) hPa")
                detailRow("Today's low", "\(Int(weather.lowestPressure.rounded())) hPa")

                let change = weather.pressureChange
                detailRow(
                    "Change over today",
                    "\(change > 0 ? "+" : "")\(String(format: "%.1f", change)) hPa"
                )

                ScrollView(.vertical) {
                    LazyVStack(spacing: 9) {
                        ForEach(Array(weather.hourly.enumerated()), id: \.offset) { item in
                            let point = item.element
                            let previous = item.offset > 0 ? weather.hourly[item.offset - 1].pressureHPa : point.pressureHPa
                            let change = point.pressureHPa - previous

                            HStack {
                                Text(point.displayTime)
                                    .foregroundStyle(Color.fishMuted)
                                Spacer()
                                Text("\(String(format: "%.1f", point.pressureHPa)) hPa")
                                    .foregroundStyle(Color.fishText)
                                if item.offset > 0 && abs(change) >= 0.1 {
                                    Text("\(change > 0 ? "+" : "")\(String(format: "%.1f", change))")
                                        .foregroundStyle(change > 0 ? Color.fishGreen : Color.orange)
                                }
                            }
                            .font(.system(size: 10))
                        }
                    }
                }
                .frame(height: 150)
                .scrollIndicators(.visible)
            }
        }
        .font(.system(size: 11))
        .padding(.top, 2)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color.fishMuted)
            Spacer()
            Text(value)
                .foregroundStyle(Color.fishText)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 11))
    }

    // MARK: Fishing Advice



    private var fishingAdvice: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("FISHING INTELLIGENCE")



            VStack(alignment: .leading, spacing: 10) {

                Label("What is affecting the score?", systemImage: "chart.bar.fill")

                    .font(.headline)

                    .foregroundStyle(Color.fishText)



                if let score {

                    scoreFactorRow("Wind", value: score.wind)

                    scoreFactorRow("Precipitation", value: score.precipitation)

                    scoreFactorRow("Sky conditions", value: score.sky)

                    scoreFactorRow("Air temperature", value: score.temperature)

                } else {

                    Text("Your score breakdown will appear after weather loads.")

                        .font(.caption)

                        .foregroundStyle(Color.fishMuted)

                }



                Divider()

                    .overlay(Color.white.opacity(0.12))



                Text(adviceText)

                    .font(.caption)

                    .foregroundStyle(Color.fishMuted)

                    .fixedSize(horizontal: false, vertical: true)

            }

            .padding(16)

            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 16))

        }

    }



    private func scoreFactorRow(_ title: String, value: Int) -> some View {

        HStack {

            Text(title)

                .font(.caption)

                .foregroundStyle(Color.fishMuted)



            Spacer()



            Text("\(value)/100")

                .font(.caption.weight(.bold))

                .foregroundStyle(Color.fishText)

                .monospacedDigit()

        }

    }



    private var adviceText: String {

        guard let weather else {

            return "We'll use local weather to estimate how favorable conditions are for \(selectedSpecies.lowercased())."

        }



        if weather.windMPH >= 18 {

            return "Wind is fairly strong. Focus on protected areas where boat control and casting are manageable."

        }



        if weather.precipitationChance >= 70 {

            return "Rain is likely. Keep an eye on changing conditions and use a presentation you can control."

        }



        if weather.condition.lowercased().contains("thunder") {

            return "Thunderstorms are in the forecast. Prioritize safety and stay off the water during storms."

        }



        if weather.condition.lowercased().contains("overcast") ||

            weather.condition.lowercased().contains("cloud") {

            return "Cloud cover can encourage fish to move around. Try covering water and checking shallow areas."

        }



        return "Start by checking areas with nearby cover, then adjust your presentation based on fish activity."

    }



    // MARK: Refresh



    private var refreshButton: some View {

        VStack(spacing: 10) {

            Button {

                errorMessage = nil

                locationManager.requestLocation()

            } label: {

                HStack {

                    Image(systemName: "location.fill")

                    Text(isLoading ? "Getting Weather..." : "Get Local Weather")

                }

                .font(.headline)

                .foregroundStyle(Color.fishBackground)

                .frame(maxWidth: .infinity)

                .padding(17)

                .background(

                    Color.fishGreen,

                    in: RoundedRectangle(cornerRadius: 15)

                )

            }

            .disabled(isLoading)



            if let errorMessage {

                Text(errorMessage)

                    .font(.caption)

                    .foregroundStyle(.red)

                    .multilineTextAlignment(.center)

            }

        }

    }



    // MARK: Helpers



    private func sectionTitle(_ title: String) -> some View {

        Text(title)

            .font(.system(size: 11, weight: .bold))

            .tracking(1.5)

            .foregroundStyle(Color.fishMuted)

    }



    @MainActor

    private func loadWeather(for location: CLLocation) async {

        isLoading = true

        errorMessage = nil



        do {

            weather = try await weatherService.fetchWeather(for: location)

        } catch {

            errorMessage = error.localizedDescription

        }



        isLoading = false

    }

}



// MARK: - Other Tabs



struct ShopView: View {

    var body: some View {

        NavigationStack {

            ZStack {

                Color.fishBackground.ignoresSafeArea()



                ContentUnavailableView(

                    "Partner Shops",

                    systemImage: "bag",

                    description: Text(

                        "Fishing products from partner retailers will appear here."

                    )

                )

            }

            .navigationTitle("Shop")

        }

        .preferredColorScheme(Color.fishColorScheme)

    }

}




struct CatchLogView: View {
    @State private var catches = CatchEntry.loadAll()
    @State private var showingAddCatch = false

    private var personalBests: [CatchEntry] {
        Dictionary(grouping: catches.filter { $0.lengthInches != nil }, by: { $0.species })
            .compactMap { _, entries in
                entries.max { ($0.lengthInches ?? 0) < ($1.lengthInches ?? 0) }
            }
            .sorted { ($0.lengthInches ?? 0) > ($1.lengthInches ?? 0) }
    }

    private var speciesCount: Int {
        Set(catches.map { $0.species }).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("YOUR FISHING HISTORY")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(Color.fishMuted)
                                Text("My Catches")
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(Color.fishText)
                            }
                            Spacer()
                            Button {
                                showingAddCatch = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                    .foregroundStyle(Color.fishBackground)
                                    .frame(width: 46, height: 46)
                                    .background(Color.fishGreen, in: Circle())
                            }
                            .accessibilityLabel("Add catch")
                        }

                        HStack(spacing: 10) {
                            catchStatCard(title: "TOTAL CATCHES", value: "\(catches.count)", icon: "fish.fill")
                            catchStatCard(title: "SPECIES", value: "\(speciesCount)", icon: "water.waves")
                            catchStatCard(title: "PERSONAL BESTS", value: "\(personalBests.count)", icon: "trophy.fill")
                        }

                        catchAnalyticsSection

                        if !personalBests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("BIGGEST BY SPECIES")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(Color.fishMuted)

                                ForEach(personalBests) { entry in
                                    HStack(spacing: 12) {
                                        Image(systemName: "trophy.fill")
                                            .foregroundStyle(Color.fishGreen)
                                            .frame(width: 34, height: 34)
                                            .background(Color.fishBackground, in: RoundedRectangle(cornerRadius: 10))

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(entry.species)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(Color.fishText)
                                            Text(entry.lake.isEmpty ? entry.date.formatted(date: .abbreviated, time: .omitted) : entry.lake)
                                                .font(.caption)
                                                .foregroundStyle(Color.fishMuted)
                                        }
                                        Spacer()
                                        Text(String(format: "%.1f\"", entry.lengthInches ?? 0))
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.fishGreen)
                                    }
                                    .padding(12)
                                    .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }

                        HStack {
                            Text("RECENT CATCHES")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(Color.fishMuted)
                            Spacer()
                            if !catches.isEmpty {
                                Text("\(catches.count) total")
                                    .font(.caption)
                                    .foregroundStyle(Color.fishMuted)
                            }
                        }

                        if catches.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "fish")
                                    .font(.system(size: 38))
                                    .foregroundStyle(Color.fishGreen)
                                Text("No catches logged yet")
                                    .font(.headline)
                                    .foregroundStyle(Color.fishText)
                                Text("Save your catches, track your personal bests, and build your fishing history.")
                                    .font(.caption)
                                    .foregroundStyle(Color.fishMuted)
                                    .multilineTextAlignment(.center)
                                Button("Log Your First Catch") {
                                    showingAddCatch = true
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.fishBackground)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(Color.fishGreen, in: Capsule())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 35)
                            .padding(.horizontal, 20)
                            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 18))
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(catches) { entry in
                                    CatchRow(entry: entry)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                deleteCatch(entry)
                                            } label: {
                                                Label("Delete Catch", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddCatch) {
                AddCatchView { newCatch in
                    catches.insert(newCatch, at: 0)
                    CatchEntry.saveAll(catches)
                }
            }
            .onAppear {
                catches = CatchEntry.loadAll()
            }
        }
        .preferredColorScheme(Color.fishColorScheme)
    }

    private var catchAnalyticsSection: some View {
        let weatherEntries = catches.filter { $0.historicalTemperatureF != nil }
        let averageTemperature = weatherEntries.isEmpty ? nil :
            weatherEntries.compactMap(\.historicalTemperatureF).reduce(0, +) / Double(weatherEntries.count)
        let topSpecies = Dictionary(grouping: catches, by: { $0.species })
            .max { $0.value.count < $1.value.count }
        let topLake = Dictionary(grouping: catches.filter { !$0.lake.isEmpty }, by: { $0.lake })
            .max { $0.value.count < $1.value.count }

        return VStack(alignment: .leading, spacing: 12) {
            Text("CATCH ANALYTICS")
                .font(.system(size: 11, weight: .bold)).tracking(1.3)
                .foregroundStyle(Color.fishMuted)
            HStack(spacing: 10) {
                analyticsMetric("MOST CAUGHT", value: topSpecies.map { $0.key } ?? "—",
                                detail: topSpecies.map { "\($0.value.count) catches" } ?? "Log catches to see trends")
                analyticsMetric("TOP WATER", value: topLake.map { $0.key } ?? "—",
                                detail: topLake.map { "\($0.value.count) catches" } ?? "No lake data yet")
            }
            HStack(spacing: 10) {
                analyticsMetric("AVG. CATCH TEMP", value: averageTemperature.map { String(format: "%.0f°F", $0) } ?? "—",
                                detail: "\(weatherEntries.count) catches with weather")
                analyticsMetric("WEATHER COVERAGE", value: "\(weatherEntries.count)/\(catches.count)",
                                detail: "Historical hourly records")
            }
            Text("Weather averages use the closest hourly Open-Meteo grid-cell estimate for each catch location and time, not a measurement from the exact fishing spot. Older catches without location or weather remain in your log and are not included.")
                .font(.caption2).foregroundStyle(Color.fishMuted)
        }
        .padding(14)
        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private func analyticsMetric(_ title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 8, weight: .bold)).tracking(0.7).foregroundStyle(Color.fishMuted)
            Text(value).font(.system(size: 15, weight: .bold)).foregroundStyle(Color.fishText).lineLimit(1).minimumScaleFactor(0.7)
            Text(detail).font(.system(size: 9)).foregroundStyle(Color.fishMuted).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.fishBackground, in: RoundedRectangle(cornerRadius: 10))
    }

    private func catchStatCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.fishGreen)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.fishText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Color.fishMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 14))
    }

    private func deleteCatch(_ entry: CatchEntry) {
        catches.removeAll { $0.id == entry.id }
        CatchEntry.saveAll(catches)
    }
}

struct CatchEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var species: String
    var lake: String
    var date: Date
    var lengthInches: Double?
    var weightPounds: Double?
    var lure: String
    var notes: String
    var photoData: Data?
    var waterbodyID: String? = nil
    // Optional additions preserve compatibility with existing saved catches.
    var latitude: Double? = nil
    var longitude: Double? = nil
    var historicalTemperatureF: Double? = nil
    var historicalWindMPH: Double? = nil
    var historicalPrecipitationInches: Double? = nil
    var historicalPressureHPa: Double? = nil
    var historicalWeatherTime: Date? = nil

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fishiq-catches.json")
    }

    static func loadAll() -> [CatchEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([CatchEntry].self, from: data) else {
            return []
        }
        return entries.sorted { $0.date > $1.date }
    }

    static func saveAll(_ entries: [CatchEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

private struct CatchRow: View {
    let entry: CatchEntry

    var body: some View {
        HStack(spacing: 13) {
            if let data = entry.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 82, height: 82)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.fishBackground)
                    .frame(width: 82, height: 82)
                    .overlay {
                        Image(systemName: "fish.fill")
                            .font(.title2)
                            .foregroundStyle(Color.fishGreen)
                    }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.species)
                    .font(.headline)
                    .foregroundStyle(Color.fishText)
                Text(entry.lake.isEmpty ? "Lake not specified" : entry.lake)
                    .font(.caption)
                    .foregroundStyle(Color.fishMuted)
                HStack(spacing: 10) {
                    if let length = entry.lengthInches {
                        Label(String(format: "%.1f in", length), systemImage: "ruler")
                    }
                    if let weight = entry.weightPounds {
                        Label(String(format: "%.2f lb", weight), systemImage: "scalemass")
                    }
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.fishGreen)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.fishMuted)
                if let temperature = entry.historicalTemperatureF, let wind = entry.historicalWindMPH {
                    let weatherTime = entry.historicalWeatherTime?.formatted(date: .omitted, time: .shortened) ?? "nearest hour"
                    let rain = entry.historicalPrecipitationInches.map { String(format: "%.2f in", $0) } ?? "rain n/a"
                    let pressure = entry.historicalPressureHPa.map { "\(Int($0.rounded())) hPa" } ?? "pressure n/a"
                    Text("Weather at \(weatherTime): \(Int(temperature.rounded()))°F · \(Int(wind.rounded())) mph · \(rain) · \(pressure)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.fishGreen)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AddCatchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var species = "Largemouth Bass"
    @State private var lake = ""
    @State private var date = Date()
    @State private var lengthText = ""
    @State private var weightText = ""
    @State private var lure = ""
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var originalPhoto: UIImage?
    @State private var showingPhotoEditor = false
    @StateObject private var locationProvider = CatchLocationProvider()
    @State private var waterbodySuggestions: [CatchWaterbodySuggestion] = []
    @State private var selectedWaterbodyID: String?
    @State private var selectedWaterbodyName: String?
    @State private var selectedWaterbodyCoordinate: CLLocationCoordinate2D?
    @State private var useCurrentGPSForCatch = false
    @State private var isSaving = false
    @State private var isSearchingWaterbodies = false
    @State private var nearbyWaterbodiesLoaded = false

    let onSave: (CatchEntry) -> Void

    init(
        initialWaterbodyName: String? = nil,
        initialWaterbodyID: String? = nil,
        initialWaterbodyCoordinate: CLLocationCoordinate2D? = nil,
        onSave: @escaping (CatchEntry) -> Void
    ) {
        _lake = State(initialValue: initialWaterbodyName ?? "")
        _selectedWaterbodyID = State(initialValue: initialWaterbodyID)
        _selectedWaterbodyName = State(initialValue: initialWaterbodyName)
        _selectedWaterbodyCoordinate = State(initialValue: initialWaterbodyCoordinate)
        self.onSave = onSave
    }

    private let speciesOptions = [
        "Largemouth Bass", "Smallmouth Bass", "Northern Pike", "Walleye",
        "Muskellunge", "Bluegill", "Crappie", "Yellow Perch", "Trout", "Catfish", "Other"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(spacing: 8) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.fishCard)
                                        .frame(height: 190)
                                    if let photoData, let image = UIImage(data: photoData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 190)
                                            .padding(6)
                                    } else {
                                        VStack(spacing: 9) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 30))
                                                .foregroundStyle(Color.fishGreen)
                                            Text("Add Catch Photo")
                                                .font(.headline)
                                                .foregroundStyle(Color.fishText)
                                            Text("Optional")
                                                .font(.caption)
                                                .foregroundStyle(Color.fishMuted)
                                        }
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)

                            if photoData != nil {
                                Button {
                                    showingPhotoEditor = true
                                } label: {
                                    Label("Adjust Photo", systemImage: "crop.rotate")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.fishGreen)
                                }
                            }
                        }

                        formLabel("FISH SPECIES")
                        Picker("Species", selection: $species) {
                            ForEach(speciesOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .tint(Color.fishGreen)
                        .padding(12)
                        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 12))

                        formLabel("LOCATION & DATE")
                        waterbodyPicker
                        if selectedWaterbodyCoordinate != nil {
                            Toggle(isOn: $useCurrentGPSForCatch) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use current GPS position")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.fishText)
                                    Text("Turn on only if you're logging from the actual catch spot. Otherwise FishIQ uses the waterbody's map center.")
                                        .font(.caption2)
                                        .foregroundStyle(Color.fishMuted)
                                }
                            }
                            .tint(Color.fishGreen)
                            .padding(11)
                            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 10))
                        }
                        DatePicker("Date and time caught", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .tint(Color.fishGreen)
                            .padding(12)
                            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 12))

                        formLabel("SIZE (OPTIONAL)")
                        HStack(spacing: 10) {
                            TextField("Length (in)", text: $lengthText)
                                .keyboardType(.decimalPad)
                                .catchInputStyle()
                            TextField("Weight (lb)", text: $weightText)
                                .keyboardType(.decimalPad)
                                .catchInputStyle()
                        }

                        formLabel("GEAR & NOTES")
                        TextField("Bait or lure used", text: $lure)
                            .textInputAutocapitalization(.sentences)
                            .catchInputStyle()
                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .lineLimit(3...5)
                            .catchInputStyle()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Catch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .tint(Color.fishMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") { saveCatch() }
                        .fontWeight(.bold)
                        .tint(Color.fishGreen)
                        .disabled(!isValid || isSaving)
                }
            }
            .task {
                locationProvider.requestLocation()
            }
            .task(id: lake) {
                await searchWaterbodies()
            }
            .onChange(of: locationProvider.location) { _, newLocation in
                guard let newLocation else { return }
                Task { await loadNearbyWaterbodies(near: newLocation) }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto,
                      let data = try? await selectedPhoto.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                originalPhoto = image
                photoData = data
            }
            .sheet(isPresented: $showingPhotoEditor) {
                if let originalPhoto {
                    PhotoCropView(image: originalPhoto) { adjustedImage in
                        photoData = adjustedImage.jpegData(compressionQuality: 0.88)
                    }
                }
            }
        }
        .preferredColorScheme(Color.fishColorScheme)
    }

    private var waterbodyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "water.waves")
                    .foregroundStyle(Color.fishGreen)
                TextField("Search lakes, rivers, reservoirs...", text: $lake)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.fishText)
                    .tint(Color.fishGreen)
                    .onChange(of: lake) { _, newValue in
                        if newValue != selectedWaterbodyName {
                            selectedWaterbodyID = nil
                            selectedWaterbodyName = nil
                            selectedWaterbodyCoordinate = nil
                        }
                    }
                if isSearchingWaterbodies {
                    ProgressView().tint(Color.fishGreen)
                } else if !lake.isEmpty {
                    Button {
                        lake = ""
                        selectedWaterbodyID = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.fishMuted)
                    }
                }
            }
            .padding(14)
            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 12))

            if !waterbodySuggestions.isEmpty {
                Text(lake.isEmpty ? "NEAR YOU" : "MATCHING WATERBODIES")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Color.fishMuted)
                    .padding(.horizontal, 3)

                VStack(spacing: 0) {
                    ForEach(waterbodySuggestions) { suggestion in
                        Button {
                            lake = suggestion.name
                            selectedWaterbodyID = suggestion.id
                            selectedWaterbodyName = suggestion.name
                            selectedWaterbodyCoordinate = suggestion.coordinate
                            waterbodySuggestions = []
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "water.waves")
                                    .foregroundStyle(Color.fishGreen)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.fishText)
                                    Text(suggestion.kind)
                                        .font(.caption2)
                                        .foregroundStyle(Color.fishMuted)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundStyle(Color.fishMuted)
                            }
                            .padding(11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if suggestion.id != waterbodySuggestions.last?.id {
                            Divider().overlay(Color.fishMuted.opacity(0.2))
                        }
                    }
                }
                .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 12))
            } else if lake.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2, !isSearchingWaterbodies {
                Text("No database match. You can still save this location as entered.")
                    .font(.caption2)
                    .foregroundStyle(Color.fishMuted)
                    .padding(.horizontal, 4)
            } else if lake.isEmpty && !nearbyWaterbodiesLoaded {
                Text("Nearby suggestions appear when location access is available. You can also type to search.")
                    .font(.caption2)
                    .foregroundStyle(Color.fishMuted)
            } else if lake.isEmpty && nearbyWaterbodiesLoaded && waterbodySuggestions.isEmpty {
                Text("Type a lake or river name to search the USGS database.")
                    .font(.caption2)
                    .foregroundStyle(Color.fishMuted)
            }
        }
    }

    private func searchWaterbodies() async {
        let query = lake.trimmingCharacters(in: .whitespacesAndNewlines)
        if selectedWaterbodyID != nil && query == selectedWaterbodyName {
            waterbodySuggestions = []
            isSearchingWaterbodies = false
            return
        }
        guard query.count >= 2 else {
            isSearchingWaterbodies = false
            if query.isEmpty, let location = locationProvider.location {
                await loadNearbyWaterbodies(near: location)
            } else {
                waterbodySuggestions = []
            }
            return
        }

        isSearchingWaterbodies = true
        do {
            try await Task.sleep(nanoseconds: 300_000_000)
            let results = try await CatchWaterbodySearchService.search(
                named: query,
                near: locationProvider.location
            )
            guard !Task.isCancelled else { return }
            waterbodySuggestions = results
        } catch {
            if !Task.isCancelled { isSearchingWaterbodies = false }
        }
        if !Task.isCancelled { isSearchingWaterbodies = false }
    }

    private func loadNearbyWaterbodies(near location: CLLocation) async {
        guard lake.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do {
            let results = try await CatchWaterbodySearchService.nearby(to: location)
            guard !Task.isCancelled, lake.isEmpty else { return }
            waterbodySuggestions = results
            nearbyWaterbodiesLoaded = true
        } catch {
            if !Task.isCancelled {
                nearbyWaterbodiesLoaded = true
            }
        }
    }

    private var isValid: Bool {
        let lengthValid = lengthText.isEmpty || (Double(lengthText) ?? 0) > 0
        let weightValid = weightText.isEmpty || (Double(weightText) ?? 0) > 0
        return lengthValid && weightValid
    }

    private func formLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(Color.fishMuted)
    }

    private func saveCatch() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            let coordinate: CLLocationCoordinate2D?
            if useCurrentGPSForCatch {
                coordinate = locationProvider.location?.coordinate ?? selectedWaterbodyCoordinate
            } else {
                coordinate = selectedWaterbodyCoordinate ?? locationProvider.location?.coordinate
            }
            var entry = CatchEntry(
                species: species,
                lake: lake.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                lengthInches: Double(lengthText),
                weightPounds: Double(weightText),
                lure: lure.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                photoData: photoData,
                waterbodyID: selectedWaterbodyID,
                latitude: coordinate?.latitude,
                longitude: coordinate?.longitude
            )

            if let coordinate, date <= Date() {
                do {
                    let historical = try await HistoricalWeatherService().fetchWeather(
                        at: coordinate,
                        date: date
                    )
                    entry.historicalTemperatureF = historical.temperatureF
                    entry.historicalWindMPH = historical.windMPH
                    entry.historicalPrecipitationInches = historical.precipitationInches
                    entry.historicalPressureHPa = historical.pressureHPa
                    entry.historicalWeatherTime = historical.timestamp
                } catch {
                    // A failed weather lookup must never prevent the catch itself from being saved.
                    print("FishIQ historical weather unavailable: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                onSave(entry)
                dismiss()
            }
        }
    }
}

private struct PhotoCropView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let onSave: (UIImage) -> Void

    @State private var zoom: CGFloat = 1
    @State private var savedZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var savedOffset: CGSize = .zero
    @State private var cropViewportSize: CGSize = CGSize(width: 1, height: 1)

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Drag the photo to position the fish. Pinch to zoom.")
                    .font(.subheadline)
                    .foregroundStyle(Color.fishMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                GeometryReader { geometry in
                    let fitted = fittedSize(in: geometry.size)
                    ZStack {
                        Color.black
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: fitted.width * zoom, height: fitted.height * zoom)
                            .position(
                                x: geometry.size.width / 2 + offset.width,
                                y: geometry.size.height / 2 + offset.height
                            )
                    }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: savedOffset.width + value.translation.width,
                                    height: savedOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in savedOffset = offset }
                    )
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                zoom = min(max(savedZoom * value, 0.5), 4)
                            }
                            .onEnded { _ in savedZoom = zoom }
                    )
                }
                .frame(height: 330)
                .padding(.horizontal)
                .onAppear { cropViewportSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 330) }

                HStack {
                    Button("Reset") {
                        zoom = 1
                        savedZoom = 1
                        offset = .zero
                        savedOffset = .zero
                    }
                    .foregroundStyle(Color.fishGreen)
                    Spacer()
                    Text("Pinch to zoom • Drag to move")
                        .font(.caption)
                        .foregroundStyle(Color.fishMuted)
                }
                .padding(.horizontal, 22)
                Spacer(minLength: 0)
            }
            .padding(.top, 18)
            .background(Color.fishBackground.ignoresSafeArea())
            .navigationTitle("Adjust Catch Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use Photo") {
                        let outputWidth: CGFloat = 900
                        let outputHeight = outputWidth * cropViewportSize.height / max(1, cropViewportSize.width)
                        let size = CGSize(width: outputWidth, height: outputHeight)
                        let renderer = UIGraphicsImageRenderer(size: size)
                        let result = renderer.image { context in
                            UIColor.black.setFill()
                            context.fill(CGRect(origin: .zero, size: size))
                            let base = fittedSize(in: size)
                            let scaleX = size.width / max(1, cropViewportSize.width)
                            let scaleY = size.height / max(1, cropViewportSize.height)
                            let drawSize = CGSize(width: base.width * zoom, height: base.height * zoom)
                            let drawRect = CGRect(
                                x: (size.width - drawSize.width) / 2 + offset.width * scaleX,
                                y: (size.height - drawSize.height) / 2 + offset.height * scaleY,
                                width: drawSize.width,
                                height: drawSize.height
                            )
                            image.draw(in: drawRect)
                        }
                        onSave(result)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .tint(Color.fishGreen)
                }
            }
        }
        .preferredColorScheme(Color.fishColorScheme)
    }

    private func fittedSize(in viewport: CGSize) -> CGSize {
        let scale = min(viewport.width / image.size.width, viewport.height / image.size.height)
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }
}

private extension View {
    func catchInputStyle() -> some View {
        self
            .padding(14)
            .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Color.fishText)
            .tint(Color.fishGreen)
    }
}

#Preview {

    ContentView()

}