import Foundation

// MARK: - Catch Entry

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
