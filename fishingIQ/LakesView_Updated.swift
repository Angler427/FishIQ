
import SwiftUI
import MapKit

struct LakesView: View {

    // MARK: - Search

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showingResults = false
    @State private var searchError: String?
    @State private var searchResults: [LakeMapResult] = []

    // MARK: - Waterbody Data

    @State private var usgsWaterbodies: [USGSWaterbody] = []
    @State private var isLoadingWaterbodies = false
    @State private var waterbodyError: String?
    @State private var waterbodyLoadTask: Task<Void, Never>?
    @State private var waterbodyCache: [String: [USGSWaterbody]] = [:]
    @State private var selectedWaterbodyFilter: WaterbodyFilter = .all
    @State private var isFilterPanelExpanded = false

    private let waterbodyService = USGSWaterbodyService()

    // MARK: - Recommendations

    @State private var recommendations: [FishingRecommendation] = []
    @State private var selectedRecommendationID: Int?
    @State private var waterbodyToLog: LakeCatchDestination?

    // MARK: - Map Style

    @State private var selectedMapStyle: MapTilerConfig.Style = .outdoor

    // MARK: - Map Region

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 43.0117,
            longitude: -88.2315
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 0.5,
            longitudeDelta: 0.5
        )
    )

    // MARK: - Map Pins

    private var mapPins: [LakeMapPin] {

        let searchPins = searchResults.map { result in
            LakeMapPin(
                id: "search-\(result.id.uuidString)",
                name: result.name,
                coordinate: result.coordinate,
                recommendationID: nil,
                waterbodyID: nil
            )
        }

        let waterbodyPins = usgsWaterbodies.map { waterbody in
            LakeMapPin(
                id: "usgs-\(waterbody.id)",
                name: waterbody.name,
                coordinate: waterbody.coordinate,
                recommendationID: nil,
                waterbodyID: waterbody.id
            )
        }

        let recommendationPins = recommendations.map { recommendation in
            LakeMapPin(
                id: "recommendation-\(recommendation.id)",
                name: recommendation.title,
                coordinate: recommendation.coordinate,
                recommendationID: recommendation.id,
                waterbodyID: nil
            )
        }

        return searchPins + waterbodyPins + recommendationPins
    }

    // MARK: - Main View

    var body: some View {

        ZStack {

            FishIQMapView(
                region: $region,
                annotations: mapPins,
                style: selectedMapStyle,
                onSelect: handleMapPinSelection
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {

                // MARK: Search Bar

                HStack {

                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.fishMuted)

                    TextField(
                        "Search lakes, rivers, places...",
                        text: $searchText
                    )
                    .foregroundStyle(Color.fishText)
                    .submitLabel(.search)
                    .onSubmit {
                        searchLocation()
                    }

                    if isSearching {
                        ProgressView()
                    } else {
                        Button {
                            searchLocation()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                                .foregroundStyle(Color.fishGreen)
                        }
                    }
                }
                .padding()
                .background(Color.fishCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 5)

                // MARK: Map Style Selector

                HStack {
                    Spacer()

                    HStack(spacing: 4) {

                        Button {
                            selectedMapStyle = .outdoor
                        } label: {
                            Label("Outdoor", systemImage: "tree")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    selectedMapStyle == .outdoor
                                        ? Color.white
                                        : Color.fishText
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    selectedMapStyle == .outdoor
                                        ? Color.fishGreen
                                        : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            selectedMapStyle = .satellite
                        } label: {
                            Label("Satellite", systemImage: "globe.americas")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(
                                    selectedMapStyle == .satellite
                                        ? Color.white
                                        : Color.fishText
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    selectedMapStyle == .satellite
                                        ? Color.fishGreen
                                        : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                    .background(Color.fishCard)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                }

                // MARK: Search Results

                if showingResults {

                    VStack(alignment: .leading, spacing: 0) {

                        Text("SEARCH RESULTS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .tracking(1.5)
                            .foregroundStyle(Color.fishMuted)
                            .padding()

                        if searchResults.isEmpty && !isSearching {
                            Text(searchError ?? "No results found.")
                                .foregroundStyle(Color.fishMuted)
                                .padding()
                        }

                        ForEach(searchResults) { result in

                            Button {
                                selectLake(result)
                            } label: {

                                HStack(spacing: 12) {

                                    Image(systemName: "water.waves")
                                        .font(.title3)
                                        .foregroundStyle(Color.fishGreen)

                                    Text(result.name)
                                        .foregroundStyle(Color.fishText)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(Color.fishMuted)
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if result.id != searchResults.last?.id {
                                Divider()
                            }
                        }
                    }
                    .background(Color.fishCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5)
                    .frame(maxHeight: 300)
                }

                Spacer()

                // MARK: Expandable Bottom Panel

                if isFilterPanelExpanded {

                    VStack(alignment: .leading, spacing: 7) {

                        // Filters

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {

                                ForEach(WaterbodyFilter.allCases) { filter in

                                    Button {
                                        selectedWaterbodyFilter = filter
                                    } label: {

                                        Text(filter.title)
                                            .font(.system(size: 11, weight: .semibold))
                                            .lineLimit(1)
                                            .fixedSize()
                                            .padding(.horizontal, 9)
                                            .padding(.vertical, 5)
                                            .foregroundStyle(
                                                selectedWaterbodyFilter == filter
                                                    ? Color.white
                                                    : Color.fishText
                                            )
                                            .background(
                                                selectedWaterbodyFilter == filter
                                                    ? Color.fishGreen
                                                    : Color.fishBackground
                                            )
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Lake Data

                        HStack(spacing: 5) {

                            Text("LAKE DATA")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.fishMuted)

                            Text("·")
                                .foregroundStyle(Color.fishMuted)

                            Text("\(usgsWaterbodies.count) loaded")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.fishMuted)

                            Spacer()

                            if isLoadingWaterbodies {
                                ProgressView().scaleEffect(0.7)

                                Text("Updating")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.fishGreen)
                            } else {
                                Text("Automatic")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.fishGreen)
                            }
                        }

                        if let waterbodyError {
                            Text(waterbodyError)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }

                        Divider()

                        // Recommendations

                        HStack {

                            Text("FISHING RECOMMENDATIONS")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(Color.fishMuted)

                            Spacer()

                            Text("\(recommendations.count)")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.fishMuted)
                        }

                        if recommendations.isEmpty {

                            Text("No recommendations available yet.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.fishMuted)
                                .lineLimit(1)

                        } else {

                            ScrollView(.horizontal, showsIndicators: false) {

                                HStack(spacing: 10) {

                                    ForEach(recommendations) { recommendation in

                                        Button {
                                            selectRecommendation(recommendation)
                                        } label: {

                                            VStack(alignment: .leading, spacing: 7) {

                                                HStack {

                                                    Text(recommendation.species.uppercased())
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .foregroundStyle(Color.fishGreen)

                                                    Spacer()

                                                    Text(recommendation.confidence)
                                                        .font(.caption2)
                                                        .foregroundStyle(Color.fishMuted)
                                                }

                                                Text(recommendation.title)
                                                    .font(.headline)
                                                    .foregroundStyle(Color.fishText)

                                                Text(recommendation.description)
                                                    .font(.subheadline)
                                                    .foregroundStyle(Color.fishMuted)
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(3)

                                                Divider()

                                                Text("Technique: \(recommendation.technique)")
                                                    .font(.caption)
                                                    .foregroundStyle(Color.fishText)

                                                Text("Depth: \(recommendation.depthRange)")
                                                    .font(.caption)
                                                    .foregroundStyle(Color.fishText)
                                            }
                                            .padding()
                                            .frame(width: 270, alignment: .leading)
                                            .background(Color.fishCard)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(Color.fishCard.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5)
                    .transition(
                        .move(edge: .bottom).combined(with: .opacity)
                    )
                }

                // MARK: Reset Map

                HStack {

                    Spacer()

                    Button {

                        withAnimation {

                            region = MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: 43.0117,
                                    longitude: -88.2315
                                ),
                                span: MKCoordinateSpan(
                                    latitudeDelta: 0.5,
                                    longitudeDelta: 0.5
                                )
                            )

                            searchResults = []
                            showingResults = false
                            searchText = ""
                            selectedRecommendationID = nil
                        }

                    } label: {

                        Image(systemName: "map")
                            .font(.title2)
                            .foregroundStyle(Color.fishGreen)
                            .padding(14)
                            .background(Color.fishCard)
                            .clipShape(Circle())
                    }
                }
            }
            .padding()
            .padding(.top, 8)
            .overlay(alignment: .trailing) {

                VStack {

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isFilterPanelExpanded.toggle()
                        }
                    } label: {

                        Image(
                            systemName: isFilterPanelExpanded
                                ? "chevron.down"
                                : "line.3.horizontal.decrease"
                        )
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.fishGreen)
                        .frame(width: 42, height: 48)
                        .background(Color.fishCard.opacity(0.97))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.trailing, 2)
            }
        }
        .preferredColorScheme(Color.fishColorScheme)

        // MARK: Catch Logging Sheet

        .sheet(item: $waterbodyToLog) { destination in

            AddCatchView(
                initialWaterbodyName: destination.name,
                initialWaterbodyID: destination.id,
                initialWaterbodyCoordinate: destination.coordinate
            ) { newCatch in

                var savedCatches = CatchEntry.loadAll()
                savedCatches.insert(newCatch, at: 0)
                CatchEntry.saveAll(savedCatches)
            }
        }

        // MARK: Initial Data Load

        .task {
            await loadWaterbodies(
                for: region,
                filter: selectedWaterbodyFilter
            )
        }

        // MARK: Map Region Changes

        .onChange(of: region.span.latitudeDelta) { _, _ in
            scheduleWaterbodyLoad(
                for: region,
                filter: selectedWaterbodyFilter
            )
        }

        .onChange(of: region.center.latitude) { _, _ in
            scheduleWaterbodyLoad(
                for: region,
                filter: selectedWaterbodyFilter
            )
        }

        .onChange(of: region.center.longitude) { _, _ in
            scheduleWaterbodyLoad(
                for: region,
                filter: selectedWaterbodyFilter
            )
        }

        .onChange(of: selectedWaterbodyFilter) { _, newFilter in
            scheduleWaterbodyLoad(
                for: region,
                filter: newFilter
            )
        }

        .onDisappear {
            waterbodyLoadTask?.cancel()
        }
    }

    // MARK: - Map Pin Selection

    private func handleMapPinSelection(_ pin: LakeMapPin) {

        if let id = pin.recommendationID,
           let recommendation = recommendations.first(
                where: { $0.id == id }
           ) {

            selectRecommendation(recommendation)

        } else if let waterbodyID = pin.waterbodyID {

            withAnimation {
                region = MKCoordinateRegion(
                    center: pin.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.04,
                        longitudeDelta: 0.04
                    )
                )
            }

            waterbodyToLog = LakeCatchDestination(
                id: waterbodyID,
                name: pin.name,
                coordinate: pin.coordinate
            )
        }
    }

    // MARK: - Automatic Loading

    private func scheduleWaterbodyLoad(
        for newRegion: MKCoordinateRegion,
        filter: WaterbodyFilter
    ) {

        waterbodyLoadTask?.cancel()
        isLoadingWaterbodies = false
        waterbodyError = nil

        waterbodyLoadTask = Task {

            try? await Task.sleep(nanoseconds: 700_000_000)

            guard !Task.isCancelled else {
                return
            }

            await loadWaterbodies(
                for: newRegion,
                filter: filter
            )
        }
    }

    // MARK: - Cache Key

    private func cacheKey(
        for region: MKCoordinateRegion,
        filter: WaterbodyFilter
    ) -> String {

        let zoom = region.span.latitudeDelta

        let tier: String

        if zoom > 0.8 {
            tier = "large"
        } else if zoom > 0.2 {
            tier = "medium"
        } else {
            tier = "local"
        }

        let latitude = Int(
            (region.center.latitude * 100).rounded()
        )

        let longitude = Int(
            (region.center.longitude * 100).rounded()
        )

        let zoomValue = Int(
            (zoom * 100).rounded()
        )

        return "\(filter.id)-\(tier)-\(latitude)-\(longitude)-\(zoomValue)"
    }

    // MARK: - Load Waterbodies

    @MainActor
    private func loadWaterbodies(
        for requestedRegion: MKCoordinateRegion,
        filter: WaterbodyFilter
    ) async {

        let key = cacheKey(
            for: requestedRegion,
            filter: filter
        )

        if let cachedResults = waterbodyCache[key] {
            usgsWaterbodies = cachedResults
            waterbodyError = nil
            isLoadingWaterbodies = false
            return
        }

        isLoadingWaterbodies = true
        waterbodyError = nil

        do {

            let results = try await waterbodyService.fetchWaterbodies(
                in: requestedRegion,
                filter: filter
            )

            guard !Task.isCancelled else {
                return
            }

            usgsWaterbodies = results
            waterbodyCache[key] = results

            if waterbodyCache.count > 8,
               let oldestKey = waterbodyCache.keys.first,
               oldestKey != key {

                waterbodyCache.removeValue(forKey: oldestKey)
            }

            if results.isEmpty {
                waterbodyError = "No waterbodies found in this map area."
            }

        } catch {

            if Task.isCancelled {
                return
            }

            waterbodyError = "Could not load waterbody data. Try again."
            print("USGS error: \(error)")
        }

        if !Task.isCancelled {
            isLoadingWaterbodies = false
        }
    }

    // MARK: - Search

    private func searchLocation() {

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !query.isEmpty else {
            return
        }

        isSearching = true
        showingResults = true
        searchError = nil
        searchResults = []

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)

        Task {

            do {

                let response = try await search.start()

                var results: [LakeMapResult] = []
                var seen = Set<String>()

                for item in response.mapItems {

                    guard let name = item.name else {
                        continue
                    }

                    let coordinate = item.placemark.coordinate

                    let uniqueKey =
                        "\(name)-\(coordinate.latitude)-\(coordinate.longitude)"

                    if seen.insert(uniqueKey).inserted {

                        results.append(
                            LakeMapResult(
                                name: name,
                                coordinate: coordinate
                            )
                        )
                    }

                    if results.count == 8 {
                        break
                    }
                }

                await MainActor.run {

                    searchResults = results
                    isSearching = false

                    if results.isEmpty {
                        searchError = "No locations found. Try another search."
                    }
                }

            } catch {

                await MainActor.run {
                    searchError = "Search failed. Try again."
                    isSearching = false
                }
            }
        }
    }

    // MARK: - Select Lake

    private func selectLake(_ result: LakeMapResult) {

        withAnimation {

            region = MKCoordinateRegion(
                center: result.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.04,
                    longitudeDelta: 0.04
                )
            )

            showingResults = false
            selectedRecommendationID = nil
        }

        searchText = result.name
    }

    // MARK: - Select Recommendation

    private func selectRecommendation(
        _ recommendation: FishingRecommendation
    ) {

        withAnimation {

            region = MKCoordinateRegion(
                center: recommendation.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.015,
                    longitudeDelta: 0.015
                )
            )

            selectedRecommendationID = recommendation.id
            showingResults = false
        }
    }
}

// MARK: - Map Search Result

struct LakeMapResult: Identifiable {

    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Map Pin

struct LakeMapPin: Identifiable {

    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let recommendationID: Int?
    let waterbodyID: String?
}

// MARK: - Catch Destination

private struct LakeCatchDestination: Identifiable {

    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}

