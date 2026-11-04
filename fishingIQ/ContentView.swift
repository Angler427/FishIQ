
import SwiftUI
import CoreLocation

// MARK: - Main App

struct ContentView: View {
    var body: some View {
        TabView {
            ForecastView()
                .tabItem {
                    Label("Forecast", systemImage: "cloud.sun")
                }

            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "bag")
                }

            LakesView()
                .tabItem {
                    Label("Lakes", systemImage: "map")
                }

            CatchLogView()
                .tabItem {
                    Label("Catches", systemImage: "fish")
                }
        }
        .tint(Color.green)
    }
}

// MARK: - Design Colors

extension Color {
    static let fishBackground = Color(red: 0.055, green: 0.09, blue: 0.075)
    static let fishCard = Color(red: 0.105, green: 0.16, blue: 0.135)
    static let fishGreen = Color(red: 0.65, green: 0.84, blue: 0.65)
    static let fishMuted = Color(red: 0.63, green: 0.71, blue: 0.66)
}

// MARK: - Forecast Dashboard

struct ForecastView: View {

    @StateObject private var locationManager = LocationManager()

    @State private var weather: FishingWeather?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedSpecies = "Largemouth Bass"

    private let weatherService = FishingWeatherService()

    private let species = [
        "Largemouth Bass",
        "Smallmouth Bass",
        "Northern Pike",
        "Walleye",
        "Trout"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        header

                        forecastCard

                        speciesSelector

                        conditionsSection

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
        .preferredColorScheme(.dark)
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
                Label(
                    "LOCAL CONDITIONS",
                    systemImage: "location.fill"
                )
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.fishMuted)

                Spacer()

                Text("WEATHERKIT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.fishGreen)
            }
        }
    }

    // MARK: Forecast Card

    private var forecastCard: some View {
        VStack(alignment: .leading, spacing: 15) {

            Text("FISHING OUTLOOK")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Color.fishMuted)

            HStack(alignment: .center) {

                VStack(alignment: .leading, spacing: 5) {

                    if let weather {
                        Text("--")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(Color.fishGreen)

                        Text(weather.condition)
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("Weather loaded")
                            .font(.caption)
                            .foregroundStyle(Color.fishMuted)

                    } else {
                        Text(isLoading ? "..." : "--")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(Color.fishGreen)

                        Text(isLoading ? "Getting conditions" : "Awaiting forecast")
                            .font(.headline)
                            .foregroundStyle(.white)

                        Text("Select your location to begin")
                            .font(.caption)
                            .foregroundStyle(Color.fishMuted)
                    }
                }

                Spacer()

                Image(systemName: weather == nil
                      ? "cloud.sun"
                      : "cloud.sun.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.fishGreen)
            }

            if isLoading {
                ProgressView()
                    .tint(Color.fishGreen)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.23, blue: 0.17),
                    Color.fishCard
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: Species Selector

    private var speciesSelector: some View {
        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("TARGET SPECIES")

            Menu {
                ForEach(species, id: \.self) { item in
                    Button(item) {
                        selectedSpecies = item
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "fish.fill")
                        .foregroundStyle(Color.fishGreen)

                    Text(selectedSpecies)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

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
                    value: weather.map {
                        "\(Int($0.windMPH.rounded())) mph"
                    } ?? "--"
                )

                conditionCard(
                    icon: "thermometer.medium",
                    title: "AIR TEMP",
                    value: weather.map {
                        "\(Int($0.temperatureF.rounded()))°F"
                    } ?? "--"
                )

                conditionCard(
                    icon: "cloud.rain",
                    title: "PRECIPITATION",
                    value: weather.map {
                        "\(Int($0.precipitationChance.rounded()))%"
                    } ?? "--"
                )

                conditionCard(
                    icon: "gauge",
                    title: "PRESSURE",
                    value: weather.map {
                        "\(Int($0.pressureHPa.rounded())) hPa"
                    } ?? "--"
                )
            }
        }
    }

    private func conditionCard(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.fishGreen)

            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundStyle(Color.fishMuted)

            Text(value)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            Color.fishCard,
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: Fishing Advice

    private var fishingAdvice: some View {
        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("FISHING INTELLIGENCE")

            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundStyle(Color.fishGreen)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Species-specific insights")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(
                        "We'll analyze weather trends and seasonal patterns to recommend techniques for \(selectedSpecies)."
                    )
                    .font(.caption)
                    .foregroundStyle(Color.fishMuted)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(
                Color.fishCard,
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
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
                    Text("Get Local Weather")
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
            weather = try await weatherService.fetchWeather(
                for: location
            )
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
        .preferredColorScheme(.dark)
    }
}

struct LakesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ContentUnavailableView(
                    "Explore Lakes",
                    systemImage: "map",
                    description: Text(
                        "Find freshwater lakes and explore fishing conditions."
                    )
                )
            }
            .navigationTitle("Lakes")
        }
        .preferredColorScheme(.dark)
    }
}

struct CatchLogView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()

                ContentUnavailableView(
                    "Catch Log",
                    systemImage: "fish",
                    description: Text(
                        "Your fishing history will appear here."
                    )
                )
            }
            .navigationTitle("My Catches")
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

