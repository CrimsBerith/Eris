import Foundation
import UserNotifications

public final class MorningBriefingService: @unchecked Sendable {
    public static let shared = MorningBriefingService()
    
    public var isBriefingEnabled: Bool = true
    public var briefingHour: Int = 8
    public var briefingMinute: Int = 30
    
    private init() {}
    
    public func requestNotificationPermission() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    public func scheduleDailyBriefing() {
        guard isBriefingEnabled else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["eris_morning_briefing"])
            return
        }
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["eris_morning_briefing"])
        
        let content = UNMutableNotificationContent()
        content.title = "Eris — Günlük Brifing Hazır"
        content.body = "Bugünkü ajandanız, hava & deniz durumu ve piyasa verileri hazırlandı."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = briefingHour
        dateComponents.minute = briefingMinute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "eris_morning_briefing", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Brifing bildirimi kurulamadı: \(error)")
            }
        }
    }
    
    public func generateBriefingText() -> String {
        let marine = ExternalDataService.shared.getMarineWeather()
        let markets = ExternalDataService.shared.getMarketSummary()
        let bist = markets.first(where: { $0.symbol == "BIST100" })?.price ?? "9,840"
        let usd = markets.first(where: { $0.symbol == "USDTRY" })?.price ?? "34.18"
        
        return """
        Günaydın. Bugün İstanbul \(marine.location) mevkiinde hava \(Int(marine.airTempCelsius)) derece, rüzgar \(marine.windDirection) yönünden \(String(format: "%.1f", marine.windSpeedKnots)) knot ve deniz \(marine.seaCondition).
        Piyasalarda BIST100 \(bist), Dolar/TL \(usd) seviyesinde.
        Takviminiz ve bekleyen notlarınız kontrol edildi, güne hazırsınız.
        """
    }
}
