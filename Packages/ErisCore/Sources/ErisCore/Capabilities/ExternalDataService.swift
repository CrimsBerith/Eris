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
    
    private let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 12
        return URLSession(configuration: config)
    }()
    
    private let lock = NSLock()
    private var cachedMarket: [MarketItem] = [
        MarketItem(symbol: "BIST100", name: "Borsa İstanbul", price: "9,840.50", change: "+%1.12", isPositive: true),
        MarketItem(symbol: "USDTRY", name: "Dolar / TL", price: "34.18", change: "+%0.08", isPositive: false),
        MarketItem(symbol: "EURTRY", name: "Euro / TL", price: "38.22", change: "+%0.15", isPositive: false),
        MarketItem(symbol: "XAUUSD", name: "Gram / Ons Altın", price: "$2,654.80", change: "+%0.74", isPositive: true),
        MarketItem(symbol: "BTC", name: "Bitcoin", price: "$64,250", change: "+%2.40", isPositive: true)
    ]
    
    private var cachedMarine: MarineWeatherInfo = MarineWeatherInfo(
        location: "Kalamış / İstanbul",
        seaCondition: "Sakin - Çırpıntılı",
        windSpeedKnots: 8.5,
        windDirection: "Poyraz (KKB)",
        waveHeightMeters: 0.35,
        seaTempCelsius: 20.8,
        airTempCelsius: 23.0,
        warning: nil
    )
    
    private init() {}
    
    // MARK: - Senkron Okuma & Yazma Yardımcıları
    public func getMarketSummary() -> [MarketItem] {
        lock.lock()
        defer { lock.unlock() }
        return cachedMarket
    }
    
    public func getMarineWeather() -> MarineWeatherInfo {
        lock.lock()
        defer { lock.unlock() }
        return cachedMarine
    }
    
    private func updateCachedMarine(_ updated: MarineWeatherInfo) {
        lock.lock()
        self.cachedMarine = updated
        lock.unlock()
    }
    
    private func updateCachedMarket(_ updated: [MarketItem]) {
        lock.lock()
        self.cachedMarket = updated
        lock.unlock()
    }
    
    // MARK: - Canlı Hava & Deniz Durumu (Open-Meteo Ücretsiz API)
    public func fetchLiveMarineWeather() async -> MarineWeatherInfo {
        // Kalamış Marina koordinatları: 40.978 N, 29.043 E
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=40.978&longitude=29.043&current=temperature_2m,wind_speed_10m,wind_direction_10m,relative_humidity_2m&wind_speed_unit=kn") else {
            return getMarineWeather()
        }
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let current = json["current"] as? [String: Any] else {
                return getMarineWeather()
            }
            
            let temp = current["temperature_2m"] as? Double ?? 22.0
            let windKnots = current["wind_speed_10m"] as? Double ?? 8.0
            let windDeg = current["wind_direction_10m"] as? Double ?? 45.0
            
            // Rüzgar yönü Türkçe denizcilik terimleri
            let windDirection = compassDirectionToTurkish(degree: windDeg)
            
            // Dalga boyu ve deniz durumu tahmini (knot hızına göre ampirik)
            let waveMeters: Double
            let condition: String
            if windKnots < 5 {
                waveMeters = 0.15
                condition = "Liman / Çarşaf gibi"
            } else if windKnots < 12 {
                waveMeters = 0.35
                condition = "Sakin - Hafif Çırpıntılı"
            } else if windKnots < 20 {
                waveMeters = 0.8
                condition = "Dalgalı / Sert Rüzgarlı"
            } else {
                waveMeters = 1.6
                condition = "Kuvvetli Fırtına / Deniz Çıkışı Sakıncalı"
            }
            
            let warning = windKnots >= 20 ? "Kuvvetli rüzgar ve dalga uyarısı! Seyir emniyeti için marina kontrollerini yapın." : nil
            
            let updated = MarineWeatherInfo(
                location: marineLocation,
                seaCondition: condition,
                windSpeedKnots: windKnots,
                windDirection: "\(windDirection) (\(Int(windDeg))°)",
                waveHeightMeters: waveMeters,
                seaTempCelsius: max(temp - 2.5, 14.0),
                airTempCelsius: temp,
                warning: warning
            )
            
            updateCachedMarine(updated)
            return updated
        } catch {
            return getMarineWeather()
        }
    }
    
    // MARK: - Canlı Piyasa & Döviz Kurları
    public func fetchLiveMarketSummary() async -> [MarketItem] {
        var updatedItems = getMarketSummary()
        
        // 1. Döviz Kurları (Açık Döviz Kuru API)
        if let fxUrl = URL(string: "https://open.er-api.com/v6/latest/USD") {
            if let (data, response) = try? await urlSession.data(from: fxUrl),
               let http = response as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["rates"] as? [String: Any] {
                
                if let tryRate = rates["TRY"] as? Double {
                    let formattedUSD = String(format: "%.2f", tryRate)
                    if let idx = updatedItems.firstIndex(where: { $0.symbol == "USDTRY" }) {
                        updatedItems[idx].price = formattedUSD
                    }
                    
                    if let eurRate = rates["EUR"] as? Double, eurRate > 0 {
                        let eurTry = tryRate / eurRate
                        let formattedEUR = String(format: "%.2f", eurTry)
                        if let idx = updatedItems.firstIndex(where: { $0.symbol == "EURTRY" }) {
                            updatedItems[idx].price = formattedEUR
                        }
                    }
                }
            }
        }
        
        // 2. Kripto / Bitcoin (CoinGecko Simple Price)
        if let btcUrl = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true") {
            if let (data, response) = try? await urlSession.data(from: btcUrl),
               let http = response as? HTTPURLResponse, http.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let btcData = json["bitcoin"] as? [String: Any],
               let usdPrice = btcData["usd"] as? Double {
                
                let change24h = btcData["usd_24h_change"] as? Double ?? 0.0
                let isPos = change24h >= 0
                // Pozitif değerlere "+" öneki ekle, her ikisinde de iki ondalık + % sembolü kullan
                let changeStr = String(format: isPos ? "+%.2f%%" : "%.2f%%", change24h)
                
                let numFormatter = NumberFormatter()
                numFormatter.numberStyle = .currency
                numFormatter.currencySymbol = "$"
                numFormatter.maximumFractionDigits = 0
                let priceStr = numFormatter.string(from: NSNumber(value: usdPrice)) ?? "$\(Int(usdPrice))"
                
                if let idx = updatedItems.firstIndex(where: { $0.symbol == "BTC" }) {
                    updatedItems[idx].price = priceStr
                    updatedItems[idx].change = changeStr
                    updatedItems[idx].isPositive = isPos
                }
            }
        }
        
        updateCachedMarket(updatedItems)
        return updatedItems
    }
    
    private func compassDirectionToTurkish(degree: Double) -> String {
        switch degree {
        case 337.5...360.0, 0.0..<22.5: return "Yıldız (K)"
        case 22.5..<67.5: return "Poyraz (KD)"
        case 67.5..<112.5: return "Gündoğusu (D)"
        case 112.5..<157.5: return "Keşişleme (GD)"
        case 157.5..<202.5: return "Kıble (G)"
        case 202.5..<247.5: return "Lodos (GB)"
        case 247.5..<292.5: return "Günbatısı (B)"
        case 292.5..<337.5: return "Karayel (KB)"
        default: return "Poyraz"
        }
    }
    
    // Web Araştırması (DuckDuckGo Instant Answer API)
    // Tüm harici çıktılar `untrusted` kuralına tabidir
    public func searchWebUntrusted(query: String) async -> String {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encoded)&format=json&no_html=1&skip_disambig=1") else {
            return "[UNTRUSTED_SEARCH]: Arama URL oluşturulamadı."
        }
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return "[UNTRUSTED_SEARCH]: Arama servisi geçici olarak yanıt vermedi."
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let abstract = json["AbstractText"] as? String ?? ""
                if !abstract.isEmpty {
                    return "[UNTRUSTED_SEARCH]: \(abstract)"
                }
                
                if let related = json["RelatedTopics"] as? [[String: Any]], let first = related.first, let text = first["Text"] as? String {
                    return "[UNTRUSTED_SEARCH]: \(text)"
                }
            }
            return "[UNTRUSTED_SEARCH]: Doğrudan sonuç bulunamadı."
        } catch {
            return "[UNTRUSTED_SEARCH]: Arama hatası: \(error.localizedDescription)"
        }
    }
}
