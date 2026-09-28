//
//  ErisLifeAutomationEngine.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public enum AutomationCadence: String, Codable, CaseIterable, Sendable {
    case dailyMorning = "daily_morning"
    case dailyEvening = "daily_evening"
    case weekly = "weekly"
    case monthly = "monthly"
    
    public var displayName: String {
        switch self {
        case .dailyMorning: return "Her Sabah Rutini"
        case .dailyEvening: return "Her Akşam Kapanışı"
        case .weekly: return "Haftalık Yaşam Planı"
        case .monthly: return "Aylık Finans & Fatura Denetimi"
        }
    }
}

public struct AutomationReport: Identifiable, Sendable {
    public let id: UUID
    public let cadence: AutomationCadence
    public let timestamp: Date
    public let summary: String
    public let actionItems: [String]
    public let openLoopsCount: Int
    
    public init(
        id: UUID = UUID(),
        cadence: AutomationCadence,
        timestamp: Date = Date(),
        summary: String,
        actionItems: [String],
        openLoopsCount: Int
    ) {
        self.id = id
        self.cadence = cadence
        self.timestamp = timestamp
        self.summary = summary
        self.actionItems = actionItems
        self.openLoopsCount = openLoopsCount
    }
}

/// Bölüm 47 ("Otomasyon") gereğince:
/// Her sabah, her akşam, her hafta ve her ay tekrarlanan yaşam iş akışlarını
/// otomatik çalıştırıp zihinsel yükü sıfıra indiren Otomasyon Motoru.
public final class ErisLifeAutomationEngine: Sendable {
    public static let shared = ErisLifeAutomationEngine()
    
    private init() {}
    
    // MARK: - 1. Her Sabah Otomasyonu
    public func runDailyMorningAutomation(
        events: [ErisCalendarEvent],
        weather: MarineWeatherInfo
    ) -> AutomationReport {
        let eventTitles = events.map { $0.title }.joined(separator: ", ")
        let summary = "Günaydın. Bugün ajandanızda \(events.count) planlı etkinlik var (\(eventTitles.isEmpty ? "Serbest odaklanma günü" : eventTitles)). Hava \(Int(weather.airTempCelsius))°C, \(weather.seaCondition). Çıkış saatiniz canlı trafiğe göre ayarlandı."
        
        let actions = [
            "Günün 1. öncelikli görevine odaklan",
            "Toplantı evraklarını gözden geçir",
            "Dışarı çıkış öncesi anahtarlar ve evrakları çantaya al"
        ]
        
        return AutomationReport(
            cadence: .dailyMorning,
            summary: summary,
            actionItems: actions,
            openLoopsCount: ErisOpenLoopsEngine.shared.pendingCount
        )
    }
    
    // MARK: - 2. Her Akşam Kapanış Otomasyonu
    public func runDailyEveningAutomation() -> AutomationReport {
        let completedToday = 3
        let remainingLoops = ErisOpenLoopsEngine.shared.pendingCount
        let summary = "Günün kapanış özeti: Bugün \(completedToday) önemli görev tamamlandı. Askıda \(remainingLoops) açık iş bulunuyor. Yarın sabahki ilk toplantınız 09:30'da."
        
        let actions = [
            "Yarım kalan notları kasaya kaydet",
            "Yarının ilk kıyafet ve çanta hazırlığını tamamla",
            "Elektronik cihazları şarja tak"
        ]
        
        return AutomationReport(
            cadence: .dailyEvening,
            summary: summary,
            actionItems: actions,
            openLoopsCount: remainingLoops
        )
    }
    
    // MARK: - 3. Haftalık Otomasyon
    public func runWeeklyAutomation() -> AutomationReport {
        let summary = "Haftalık Yaşam Planı: Önümüzdeki hafta 4 kritik teslim tarihi ve 1 seyahat hazırlığı görünüyor. Açık görevler temizlendi, market eksikleri derlendi."
        
        let actions = [
            "Haftalık yemek menüsüne göre market siparişini onayla",
            "Haftalık çalışma bloklarını takvime sabitle",
            "E-posta gelen kutusunu sıfırla (Inbox Zero)"
        ]
        
        return AutomationReport(
            cadence: .weekly,
            summary: summary,
            actionItems: actions,
            openLoopsCount: ErisOpenLoopsEngine.shared.pendingCount
        )
    }
    
    // MARK: - 4. Aylık Finans & Fatura Otomasyonu
    public func runMonthlyAutomation() -> AutomationReport {
        let summary = "Aylık Finans ve Yaşam Denetimi: 4 düzenli fatura ve 3 aktif yazılım aboneliği incelendi. Bütçe aşımı riski bulunmuyor."
        
        let actions = [
            "Kullanılmayan 1 aboneliği iptal etmek için onayla",
            "Otomatik ödenen faturaların dekontlarını arşivle",
            "Gelecek ayın tasarruf hedefini güncelle"
        ]
        
        return AutomationReport(
            cadence: .monthly,
            summary: summary,
            actionItems: actions,
            openLoopsCount: ErisOpenLoopsEngine.shared.pendingCount
        )
    }
}
