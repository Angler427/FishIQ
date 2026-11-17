import SwiftUI
import CoreLocation
import MapKit

struct FishingFeaturesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.fishBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("PLAN YOUR NEXT OUTING")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.4)
                                .foregroundStyle(Color.fishMuted)
                            Text("Fishing Planner")
                                .font(.largeTitle.bold())
                                .foregroundStyle(Color.fishText)
                        }
                        TripPlannerSection()
                        LakeProfileSection()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(Color.fishColorScheme)
    }
}

private struct TripPlannerSection: View {
    @StateObject private var locationManager = LocationManager()
    @State private var selectedSpecies = "Largemouth Bass"
    @State private var tripStartDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var tripEndDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var lakeName = ""
    @State private var weather: FishingWeather?
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let species = [
        "Largemouth Bass", "Smallmouth Bass", "Northern Pike", "Walleye",
        "Muskellunge", "Bluegill", "Crappie", "Yellow Perch", "Trout", "Catfish"
    ]
    private let weatherService = FishingWeatherService()
    private var earliestPlanningDate: Date { Calendar.current.startOfDay(for: Date()) }
    private var latestPlanningDate: Date {
        Calendar.current.date(byAdding: .year, value: 1, to: earliestPlanningDate) ?? earliestPlanningDate
    }

    private var forecastsInTripRange: [DailyForecastPoint] {
        guard let weather else { return [] }
        let start = Self.dateKey(tripStartDate)
        let end = Self.dateKey(tripEndDate)
        return weather.dailyForecast.filter { $0.date >= start && $0.date <= end }
    }

    private var tripDayCount: Int {
        max(1, (Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: tripStartDate), to: Calendar.current.startOfDay(for: tripEndDate)).day ?? 0) + 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureHeading("TRIP PLANNER", subtitle: "Choose a single day or plan a multi-day trip up to one year ahead")

            VStack(alignment: .leading, spacing: 10) {
                TextField("Lake or river (optional)", text: $lakeName)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(Color.fishBackground, in: RoundedRectangle(cornerRadius: 10))

                Picker("Target species", selection: $selectedSpecies) {
                    ForEach(species, id: \.self) { Text($0).tag($0) }
                }
                .tint(Color.fishGreen)

                DatePicker("Trip starts", selection: $tripStartDate,
                           in: earliestPlanningDate...latestPlanningDate, displayedComponents: .date)
                    .tint(Color.fishGreen)
                    .onChange(of: tripStartDate) { _, newStart in
                        if tripEndDate < newStart { tripEndDate = newStart }
                    }

                DatePicker("Trip ends", selection: $tripEndDate,
                           in: tripStartDate...latestPlanningDate, displayedComponents: .date)
                    .tint(Color.fishGreen)

                HStack {
                    Label("\(tripDayCount) day\(tripDayCount == 1 ? "" : "s")", systemImage: "calendar")
                    Spacer()
                    Text("Planning window: 12 months")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.fishMuted)

                Button(action: refreshForecast) {
                    HStack {
                        if isLoading { ProgressView().tint(Color.fishBackground) }
                        Image(systemName: "cloud.sun.fill")
                        Text(isLoading ? "Loading forecast..." : "Build trip plan")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.fishBackground)
                    .frame(maxWidth: .infinity)
                    .padding(13)
                    .background(Color.fishGreen, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading)

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.orange)
                }
            }

            if weather != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("TRIP OUTLOOK")
                        .font(.system(size: 10, weight: .bold)).tracking(1)
                        .foregroundStyle(Color.fishMuted)

                    if forecastsInTripRange.isEmpty {
                        Text("A forecast isn't available for these dates yet. You can still choose and plan this date range now; weather and bait suggestions will appear when the dates enter the forecast window.")
                            .font(.caption).foregroundStyle(Color.fishMuted)
                    } else {
                        ForEach(forecastsInTripRange) { forecast in
                            VStack(alignment: .leading, spacing: 9) {
                                HStack(spacing: 12) {
                                    Image(systemName: forecast.symbolName)
                                        .font(.system(size: 27)).foregroundStyle(Color.fishGreen)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(Self.displayDate(forecast.date))
                                            .font(.headline).foregroundStyle(Color.fishText)
                                        Text("\(Int(forecast.highF.rounded()))° / \(Int(forecast.lowF.rounded()))° · \(weatherDescription(forecast.weatherCode))")
                                            .font(.caption).foregroundStyle(Color.fishMuted)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 3) {
                                        Label("\(Int(forecast.maxWindMPH.rounded())) mph", systemImage: "wind")
                                        Label("\(Int(forecast.precipitationChance.rounded()))%", systemImage: "drop")
                                    }
                                    .font(.caption2.weight(.semibold)).foregroundStyle(Color.fishText)
                                }
                                Text("BAIT & PRESENTATION")
                                    .font(.system(size: 9, weight: .bold)).tracking(0.8)
                                    .foregroundStyle(Color.fishMuted)
                                ForEach(BaitRecommendationEngine.recommendations(for: selectedSpecies, forecast: forecast), id: \.self) { item in
                                    HStack(alignment: .top, spacing: 7) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.fishGreen)
                                        Text(item).font(.caption).foregroundStyle(Color.fishText)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.fishBackground, in: RoundedRectangle(cornerRadius: 11))
                        }
                    }

                    let unavailableDays = max(0, tripDayCount - forecastsInTripRange.count)
                    if unavailableDays > 0 {
                        Text("Weather for \(unavailableDays) remaining trip day\(unavailableDays == 1 ? "" : "s") isn't available yet. FishIQ won't estimate conditions that haven't been forecast.")
                            .font(.caption2).foregroundStyle(Color.fishMuted)
                    }
                    Text("Forecasts are currently available for roughly the next seven days. Dates farther out can be planned now and checked again closer to departure. Bait suggestions are rule-based starting points, not guarantees.")
                        .font(.caption2).foregroundStyle(Color.fishMuted)
                }
            } else {
                Text("Build a plan to see the available local forecast. You can select dates up to one year ahead; forecasts appear when Open-Meteo publishes them.")
                    .font(.caption).foregroundStyle(Color.fishMuted)
            }
        }
        .padding(16)
        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 18))
        .task {
            if locationManager.location == nil { locationManager.requestLocation() }
        }
        .onChange(of: locationManager.location) { _, location in
            if location != nil { refreshForecast() }
        }
    }

    private func refreshForecast() {
        guard let location = locationManager.location else {
            locationManager.requestLocation()
            errorMessage = "Waiting for your location. Check location permission if this continues."
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await weatherService.fetchWeather(for: location)
                await MainActor.run {
                    weather = result
                    isLoading = false
                    if forecastsInTripRange.isEmpty {
                        errorMessage = "Your dates are saved for planning, but weather isn't available this far ahead yet."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func displayDate(_ key: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: key) else { return key }
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func weatherDescription(_ code: Int) -> String {
        switch code {
        case 0: return "Clear skies"
        case 1, 2: return "Mostly clear to partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog may reduce visibility"
        case 51...55: return "Drizzle possible"
        case 61...65, 80...82: return "Rain or showers possible"
        case 71...77, 85...86: return "Snow possible"
        case 95...99: return "Thunderstorms possible — postpone fishing on the water if storms threaten"
        default: return "Conditions vary"
        }
    }
}

private enum BaitRecommendationEngine {
    static func recommendations(for species: String, forecast: DailyForecastPoint) -> [String] {
        let windy = forecast.maxWindMPH >= 12
        let cloudyOrWet = forecast.weatherCode == 3 || (51...82).contains(forecast.weatherCode)
        let warm = forecast.highF >= 70
        let cold = forecast.highF <= 50

        switch species {
        case "Largemouth Bass", "Smallmouth Bass":
            if windy || cloudyOrWet {
                return ["Try a moving search bait such as a spinnerbait or crankbait to cover water.", "Check windblown banks and nearby cover where baitfish may collect.", "Keep a slower soft-plastic option ready if fish won't chase."]
            }
            if cold {
                return ["Start with a slower jig or soft-plastic presentation.", "Focus on deeper nearby structure and work the bait deliberately.", "Downsize if bites are difficult to trigger."]
            }
            return [warm ? "Check shallow cover during low-light periods with a topwater or moving bait." : "Start with a versatile search bait around available cover.", "Follow up with a soft plastic around docks, weeds, or other cover.", "Change depth before changing several lures at once."]
        case "Northern Pike", "Muskellunge":
            return [windy ? "Check windblown weed edges when boat control is safe." : "Start along weed edges and other ambush cover.", "Use a moving presentation that lets you cover water, then slow down around follows.", "If fish are inactive, change depth or retrieve speed before switching locations."]
        case "Walleye":
            return ["Start with a jig and soft-plastic or natural-bait trailer near bottom structure.", "Check points, breaks, and windblown areas where forage may gather.", "Low-light periods can be worth prioritizing; adjust depth to fish activity."]
        case "Bluegill", "Crappie", "Yellow Perch":
            return ["Try a small jig under a float or a compact vertical presentation.", "Look around weed edges, docks, and submerged cover.", "Adjust jig size and depth until you find active fish."]
        case "Catfish":
            return ["Use a bottom presentation with bait suited to the local fishery.", "Check deeper holes, current edges, or soft-bottom areas.", "Keep the presentation stationary long enough to evaluate the spot."]
        default:
            return ["Choose a presentation suited to the target species and local forage.", "Start near visible cover or depth changes.", "Adjust depth and retrieve speed based on bites and follows."]
        }
    }
}

private struct LakeProfileSection: View {
    @State private var searchText = ""
    @State private var suggestions: [CatchWaterbodySuggestion] = []
    @State private var selectedLake: CatchWaterbodySuggestion?
    @State private var isSearching = false
    @State private var launches: [BoatLaunchResult] = []
    @State private var isLoadingLaunches = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureHeading("LAKE PROFILES", subtitle: "Waterbody facts, your catch history, and nearby access")
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Color.fishMuted)
                TextField("Search a lake or river", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(Color.fishText)
                if isSearching { ProgressView().tint(Color.fishGreen) }
            }
            .padding(12)
            .background(Color.fishBackground, in: RoundedRectangle(cornerRadius: 10))
            .onChange(of: searchText) { _, value in search(value) }

            if !suggestions.isEmpty && selectedLake == nil {
                VStack(spacing: 0) {
                    ForEach(suggestions) { item in
                        Button {
                            selectedLake = item
                            suggestions = []
                            Task { await loadBoatLaunches(for: item) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.fishText)
                                    Text(item.kind).font(.caption2).foregroundStyle(Color.fishMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Color.fishMuted)
                            }
                            .padding(11)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if item.id != suggestions.last?.id { Divider() }
                    }
                }
                .background(Color.fishBackground, in: RoundedRectangle(cornerRadius: 10))
            }

            if let lake = selectedLake {
                profile(for: lake)
            }
        }
        .padding(16)
        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private func profile(for lake: CatchWaterbodySuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(lake.name).font(.title3.bold()).foregroundStyle(Color.fishText)
                    Text(lake.kind).font(.caption).foregroundStyle(Color.fishMuted)
                }
                Spacer()
                Button("Change") {
                    selectedLake = nil
                    searchText = ""
                    launches = []
                }
                .font(.caption.weight(.semibold)).tint(Color.fishGreen)
            }

            HStack(spacing: 10) {
                profileMetric("AREA", value: lake.areaSquareKilometers.map { String(format: "%.0f acres", $0 * 247.105) } ?? "Not listed")
                profileMetric("LOCATION", value: String(format: "%.4f, %.4f", lake.coordinate.latitude, lake.coordinate.longitude))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("FISH YOU'VE LOGGED HERE")
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Color.fishMuted)
                let catches = CatchEntry.loadAll().filter {
                    ($0.waterbodyID == lake.id) || ($0.lake.caseInsensitiveCompare(lake.name) == .orderedSame)
                }
                let fish = Array(Set(catches.map(\.species))).sorted()
                if fish.isEmpty {
                    Text("No catches logged at this waterbody yet. This is your personal catch history, not a complete fish inventory.")
                        .font(.caption).foregroundStyle(Color.fishMuted)
                } else {
                    Text(fish.joined(separator: " · ")).font(.subheadline).foregroundStyle(Color.fishText)
                    Text("Based on \(catches.count) catch record(s) in your log.")
                        .font(.caption2).foregroundStyle(Color.fishMuted)
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("DEPTH & BATHYMETRY")
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Color.fishMuted)
                if isInWaukeshaBathymetryArea(lake.coordinate) {
                    Text("A local Waukesha County bathymetry layer is available for this area. It is not a nationwide depth survey.")
                        .font(.caption).foregroundStyle(Color.fishMuted)
                    BathymetryMapView(initialRegion: MKCoordinateRegion(
                        center: lake.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                    ))
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Text("Depth contours and maximum depth aren't included in the current USGS waterbody record. FishIQ won't guess these values.")
                        .font(.caption).foregroundStyle(Color.fishMuted)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("REGULATIONS")
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Color.fishMuted)
                if isWisconsinCoordinate(lake.coordinate) {
                    Link(destination: URL(string: "https://dnr.wisconsin.gov/topic/Fishing/regulations")!) {
                        Label("Wisconsin fishing regulations", systemImage: "book.closed")
                            .font(.caption.weight(.semibold)).foregroundStyle(Color.fishGreen)
                    }
                } else {
                    Text("Rules vary by state, species, season, and waterbody. Check the official fish and wildlife agency before fishing; state-specific regulation links aren't connected nationwide yet.")
                        .font(.caption).foregroundStyle(Color.fishMuted)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("NEARBY BOAT ACCESS")
                        .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Color.fishMuted)
                    Spacer()
                    if isLoadingLaunches { ProgressView().tint(Color.fishGreen) }
                }
                if launches.isEmpty && !isLoadingLaunches {
                    Text("No nearby launch results found yet. Search results depend on Apple Maps place listings.")
                        .font(.caption).foregroundStyle(Color.fishMuted)
                } else {
                    ForEach(launches) { launch in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(launch.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.fishText)
                            Text(launch.address).font(.caption2).foregroundStyle(Color.fishMuted)
                        }
                        .padding(.vertical, 3)
                    }
                    Text("Confirm access rules and whether the launch is public before heading out.")
                        .font(.caption2).foregroundStyle(Color.fishMuted)
                }
            }

            if isWisconsinCoordinate(lake.coordinate) {
                Link(destination: URL(string: "https://dnr.wisconsin.gov/topic/Fishing/reports")!) {
                    Label("Wisconsin DNR fisheries survey reports", systemImage: "doc.text.magnifyingglass")
                        .font(.caption.weight(.semibold)).foregroundStyle(Color.fishGreen)
                }
                Text("Official survey reports can document species and management findings for individual Wisconsin waters. FishIQ does not yet have a nationwide machine-readable survey feed.")
                    .font(.caption2).foregroundStyle(Color.fishMuted)
            }

            Text("Source: USGS 3DHP waterbody layer. Area is converted from the source's reported square kilometers; launch listings come from Apple Maps.")
                .font(.caption2).foregroundStyle(Color.fishMuted)
        }
        .padding(12)
        .background(Color.fishBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func search(_ value: String) {
        searchTask?.cancel()
        selectedLake = nil
        guard value.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            suggestions = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            do {
                let results = try await CatchWaterbodySearchService.search(named: value, near: nil)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    suggestions = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    suggestions = []
                    isSearching = false
                }
            }
        }
    }

    private func loadBoatLaunches(for lake: CatchWaterbodySuggestion) async {
        isLoadingLaunches = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "public boat launch"
        request.region = MKCoordinateRegion(
            center: lake.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
        )
        do {
            let response = try await MKLocalSearch(request: request).start()
            let results = response.mapItems.prefix(5).map { item in
                BoatLaunchResult(
                    id: "\(item.name ?? "Launch")-\(item.placemark.coordinate.latitude)",
                    name: item.name ?? "Boat access",
                    address: [item.placemark.subLocality, item.placemark.locality, item.placemark.administrativeArea]
                        .compactMap { $0 }.joined(separator: ", ")
                )
            }
            await MainActor.run {
                launches = Array(results)
                isLoadingLaunches = false
            }
        } catch {
            await MainActor.run {
                launches = []
                isLoadingLaunches = false
            }
        }
    }

    private func profileMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 8, weight: .bold)).tracking(0.8).foregroundStyle(Color.fishMuted)
            Text(value).font(.caption.weight(.semibold)).foregroundStyle(Color.fishText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.fishCard, in: RoundedRectangle(cornerRadius: 9))
    }

    private func isInWaukeshaBathymetryArea(_ coordinate: CLLocationCoordinate2D) -> Bool {
        (42.85...43.35).contains(coordinate.latitude) && (-88.55 ... -88.05).contains(coordinate.longitude)
    }

    private func isWisconsinCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        (42.4...47.2).contains(coordinate.latitude) && (-93.0 ... -86.2).contains(coordinate.longitude)
    }
}

private struct BoatLaunchResult: Identifiable {
    let id: String
    let name: String
    let address: String
}

private func featureHeading(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundStyle(Color.fishMuted)
        Text(subtitle).font(.caption).foregroundStyle(Color.fishMuted)
    }
}
