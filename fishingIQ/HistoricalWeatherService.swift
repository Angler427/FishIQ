import Foundation
import CoreLocation

struct HistoricalCatchWeather {
    let timestamp: Date
    let temperatureF: Double
    let windMPH: Double
    let precipitationInches: Double
    let pressureHPa: Double
}

/// Retrieves the hourly weather closest to the catch's recorded time and coordinates.
/// Open-Meteo's archive is reanalysis data, so it is an estimate for the grid cell,
/// not a measurement taken directly at the angler's exact spot.
struct HistoricalWeatherService {
    private struct Response: Decodable {
        let utc_offset_seconds: Int?
        let hourly: Hourly
    }

    private struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let wind_speed_10m: [Double]
        let precipitation: [Double]
        let pressure_msl: [Double]
    }

    func fetchWeather(at coordinate: CLLocationCoordinate2D, date: Date) async throws -> HistoricalCatchWeather {
        let calendar = Calendar(identifier: .gregorian)
        let utcCalendar = Calendar(identifier: .gregorian)
        let start = utcCalendar.date(byAdding: .day, value: -1, to: date) ?? date
        let end = utcCalendar.date(byAdding: .day, value: 1, to: date) ?? date
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let isRecent = date >= Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let base = isRecent
            ? URL(string: "https://api.open-meteo.com/v1/forecast")!
            : URL(string: "https://archive-api.open-meteo.com/v1/archive")!

        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m,wind_speed_10m,precipitation,pressure_msl"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        if isRecent {
            items.append(URLQueryItem(name: "past_days", value: "7"))
            items.append(URLQueryItem(name: "forecast_days", value: "1"))
        } else {
            items.append(URLQueryItem(name: "start_date", value: dateFormatter.string(from: start)))
            items.append(URLQueryItem(name: "end_date", value: dateFormatter.string(from: end)))
        }
        components.queryItems = items
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(Response.self, from: data)
        let offset = decoded.utc_offset_seconds ?? 0
        let timezone = TimeZone(secondsFromGMT: offset) ?? .current
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = timezone
        parser.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let hourly = decoded.hourly
        let candidates: [(Date, Int)] = hourly.time.enumerated().compactMap { index, value in
            guard index < hourly.temperature_2m.count,
                  index < hourly.wind_speed_10m.count,
                  index < hourly.precipitation.count,
                  index < hourly.pressure_msl.count,
                  let timestamp = parser.date(from: value) else { return nil }
            return (timestamp, index)
        }
        guard let nearest = candidates.min(by: {
            abs($0.0.timeIntervalSince(date)) < abs($1.0.timeIntervalSince(date))
        }), abs(nearest.0.timeIntervalSince(date)) <= 90 * 60 else {
            throw NSError(domain: "FishIQ.HistoricalWeather", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No hourly weather was available near that catch time."])
        }
        let i = nearest.1
        return HistoricalCatchWeather(
            timestamp: nearest.0,
            temperatureF: hourly.temperature_2m[i],
            windMPH: hourly.wind_speed_10m[i],
            precipitationInches: hourly.precipitation[i],
            pressureHPa: hourly.pressure_msl[i]
        )
    }
}
