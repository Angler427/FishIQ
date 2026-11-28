import SwiftUI

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


#Preview {
    ContentView()
}
