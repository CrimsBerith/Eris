import Foundation

public struct MarketItem: Identifiable, Codable, Sendable {
    public let id: String
    public let symbol: String
    public let name: String
    public var price: String
    public var change: String
    public var isPositive: Bool
    
    public init(id: String = UUID().uuidString, symbol: String, name: String, price: String, change: String, isPositive: Bool) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.price = price
        self.change = change
        self.isPositive = isPositive
    }
}

public struct MarineWeatherInfo: Codable, Sendable {
    public let location: String
    public let seaCondition: String
    public let windSpeedKnots: Double
    public let windDirection: String
    public let waveHeightMeters: Double
    public let seaTempCelsius: Double
    public let airTempCelsius: Double
    public let warning: String?
    
    public init(location: String = "Kalamış / Kadıköy, İstanbul", seaCondition: String = "Sakin / Çırpıntılı", windSpeedKnots: Double = 9.4, windDirection: String = "Poyraz (KKB)", waveHeightMeters: Double = 0.4, seaTempCelsius: Double = 21.0, airTempCelsius: Double = 23.5, warning: String? = nil) {
        self.location = location
        self.seaCondition = seaCondition
        self.windSpeedKnots = windSpeedKnots
        self.windDirection = windDirection
        self.waveHeightMeters = waveHeightMeters
        self.seaTempCelsius = seaTempCelsius
        self.airTempCelsius = airTempCelsius
        self.warning = warning
    }
}

public final class ExternalDataService: @unchecked Sendable {
    public static let shared = ExternalDataService()
    
    public var customSymbols: [String] = ["BIST100", "USDTRY", "EURTRY", "XAUUSD", "BTC"]
    public var marineLocation: String = "Kalamış / İstanbul"
    
    private init() {}
    
    public func getMarketSummary() -> [MarketItem] {
        // Hazır izleme listesi (İleride canlı borsa gateway'iyle entegre edilebilir)
        return [
            MarketItem(symbol: "BIST100", name: "Borsa İstanbul", price: "9,840.50", change: "+%1.12", isPositive: true),
            MarketItem(symbol: "USDTRY", name: "Dolar / TL", price: "34.18", change: "+%0.08", isPositive: false),
            MarketItem(symbol: "EURTRY", name: "Euro / TL", price: "38.22", change: "+%0.15", isPositive: false),
            MarketItem(symbol: "XAUUSD", name: "Gram / Ons Altın", price: "$2,654.80", change: "+%0.74", isPositive: true),
            MarketItem(symbol: "BTC", name: "Bitcoin", price: "$64,250", change: "+%2.40", isPositive: true)
        ]
    }
    
    public func getMarineWeather() -> MarineWeatherInfo {
        return MarineWeatherInfo(
            location: marineLocation,
            seaCondition: "Sakin - Çırpıntılı",
            windSpeedKnots: 8.5,
            windDirection: "Poyraz (KKB)",
            waveHeightMeters: 0.35,
            seaTempCelsius: 20.8,
            airTempCelsius: 23.0,
            warning: nil
        )
    }
}
