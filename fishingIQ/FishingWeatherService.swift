import Foundation
import CoreLocation

struct HourlyWeatherPoint: Identifiable {
    let time: String
    let temperatureF: Double
    let windMPH: Double
    let precipitationChance: Double
    let pressureHPa: Double

    var id: String { time }

    var displayTime: String {
        guard let clock = time.split(separator: "T").last,
              let hourText = clock.split(separator: ":").first,
              let hour = Int(hourText) else {
            return time
        }

        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(displayHour) \(suffix)"
    }
}

struct DailyForecastPoint: Identifiable {
    let date: String
    let weatherCode: Int
    let highF: Double
    let lowF: Double
    let precipitationChance: Double
    let maxWindMPH: Double

    var id: String { date }

    var dayName: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        guard let parsedDate = parser.date(from: date) else { return date }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: parsedDate)
    }

    var symbolName: String {
        switch weatherCode {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55: return "cloud.drizzle.fill"
        case 61, 63, 65, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }
}

struct FishingWeather {
    let latitude: Double
    let temperatureF: Double
    let windMPH: Double
    let condition: String
    let precipitationChance: Double
    let pressureHPa: Double
    let hourly: [HourlyWeatherPoint]
    let dailyForecast: [DailyForecastPoint]

    var highestPressure: Double {
        hourly.map(\.pressureHPa).max() ?? pressureHPa
    }

    var lowestPressure: Double {
        hourly.map(\.pressureHPa).min() ?? pressureHPa
    }

    var pressureChange: Double {
        guard let first = hourly.first, let last = hourly.last else { return 0 }
        return last.pressureHPa - first.pressureHPa
    }
}

struct OpenMeteoResponse: Decodable {
    let current: CurrentWeather
    let hourly: HourlyWeather
    let daily: DailyWeather

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
        let temperature_2m: [Double]
        let wind_speed_10m: [Double]
        let precipitation_probability: [Double]
        let pressure_msl: [Double]
    }

    struct DailyWeather: Decodable {
        let time: [String]
        let weather_code: [Int]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let precipitation_probability_max: [Double]
        let wind_speed_10m_max: [Double]
    }
}

struct FishingWeatherService {
    func fetchWeather(for location: CLLocation) async throws -> FishingWeather {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        print("FishIQ Latitude: \(latitude)")
        print("FishIQ Longitude: \(longitude)")

        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,wind_speed_10m,weather_code,pressure_msl,precipitation,rain&hourly=temperature_2m,wind_speed_10m,precipitation_probability,pressure_msl&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto&forecast_days=7"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        let current = response.current
        let currentHour = String(current.time.prefix(13))
        let currentDate = String(current.time.prefix(10))

        // Keep hourly detail cards limited to today. The seven-day outlook uses daily data below.
        let points = response.hourly.time.indices.compactMap { index -> HourlyWeatherPoint? in
            let time = response.hourly.time[index]

            guard time.hasPrefix(currentDate),
                  index < response.hourly.temperature_2m.count,
                  index < response.hourly.wind_speed_10m.count,
                  index < response.hourly.precipitation_probability.count,
                  index < response.hourly.pressure_msl.count else {
                return nil
            }

            return HourlyWeatherPoint(
                time: time,
                temperatureF: response.hourly.temperature_2m[index],
                windMPH: response.hourly.wind_speed_10m[index],
                precipitationChance: response.hourly.precipitation_probability[index],
                pressureHPa: response.hourly.pressure_msl[index]
            )
        }

        let dailyForecast = response.daily.time.indices.compactMap { index -> DailyForecastPoint? in
            guard index < response.daily.weather_code.count,
                  index < response.daily.temperature_2m_max.count,
                  index < response.daily.temperature_2m_min.count,
                  index < response.daily.precipitation_probability_max.count,
                  index < response.daily.wind_speed_10m_max.count else {
                return nil
            }

            return DailyForecastPoint(
                date: response.daily.time[index],
                weatherCode: response.daily.weather_code[index],
                highF: response.daily.temperature_2m_max[index],
                lowF: response.daily.temperature_2m_min[index],
                precipitationChance: response.daily.precipitation_probability_max[index],
                maxWindMPH: response.daily.wind_speed_10m_max[index]
            )
        }

        let currentPoint = points.first { $0.time.hasPrefix(currentHour) }
        let precipitation = currentPoint?.precipitationChance ?? 0

        var condition = Self.weatherDescription(current.weather_code)
        if current.rain > 0.1 || current.precipitation > 0.1 {
            condition = "Raining"
        }

        return FishingWeather(
            latitude: latitude,
            temperatureF: current.temperature_2m,
            windMPH: current.wind_speed_10m,
            condition: condition,
            precipitationChance: precipitation,
            pressureHPa: current.pressure_msl,
            hourly: points,
            dailyForecast: dailyForecast
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
        case 71, 73, 75, 77, 85, 86: return "Snow"
        case 80, 81, 82: return "Rain showers"
        case 95, 96, 99: return "Thunderstorms"
        default: return "Unknown"
        }
    }
}
