import SwiftUI
import CoreLocation
import PhotosUI
import UIKit

// MARK: - Catch Log

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
