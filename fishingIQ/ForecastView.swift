import SwiftUI
import CoreLocation

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
