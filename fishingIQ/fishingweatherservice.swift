import Foundation
import CoreLocation

struct FishingWeather {
    let temperatureF: Double
    let windMPH: Double
    let condition: String
    let precipitationChance: Double
    let pressureHPa: Double
}

struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather
    let hourly: HourlyWeather

    struct CurrentWeather: Decodable {
        let time: String
        let temperature_2m: Double
        let wind_speed_10m: Double
        let weather_code: Int
        let pressure_msl: Double
        let precipitation: Double
        let rain: Double
    }

    struct HourlyWeather: Decodable {
        let time: [String]
        let precipitation_probability: [Double]
    }
}

struct FishingWeatherService {

    func fetchWeather(for location: CLLocation) async throws -> FishingWeather {

        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        print("FishIQ Latitude: \(latitude)")
        print("FishIQ Longitude: \(longitude)")
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,wind_speed_10m,weather_code,pressure_msl,precipitation,rain&hourly=precipitation_probability&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        let response = try JSONDecoder().decode(
            OpenMeteoResponse.self,
            from: data
        )

        let current = response.current

        // Find the hourly precipitation chance matching the current hour.
        let currentHour = String(current.time.prefix(13))

        let hourlyIndex = response.hourly.time.firstIndex {
            $0.hasPrefix(currentHour)
        }

        let precipitation = hourlyIndex.map {
            response.hourly.precipitation_probability[$0]
        } ?? 0

        // Use actual reported precipitation to catch rain happening now.
        var condition = Self.weatherDescription(current.weather_code)

        if current.rain > 0.1 || current.precipitation > 0.1 {
            condition = "Raining"
        }

        return FishingWeather(
            temperatureF: current.temperature_2m,
            windMPH: current.wind_speed_10m,
            condition: condition,
            precipitationChance: precipitation,
            pressureHPa: current.pressure_msl
        )
    }

    private static func weatherDescription(_ code: Int) -> String {
        switch code {
        case 0: return "Clear"
        case 1, 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 71, 73, 75: return "Snow"
        case 80, 81, 82: return "Rain showers"
        case 95, 96, 99: return "Thunderstorms"
        default: return "Unknown"
        }
    }
}
