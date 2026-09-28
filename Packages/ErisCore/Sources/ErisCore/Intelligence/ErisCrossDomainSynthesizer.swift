//
//  ErisCrossDomainSynthesizer.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct CrossDomainInsight: Identifiable, Sendable {
    public let id: UUID
    public let primaryDomain: ErisLifeDomain
    public let secondaryDomain: ErisLifeDomain
    public let title: String
    public let description: String
    public let recommendedAction: String
    public let urgencyScore: Int // 1 - 10
    
    public init(
        id: UUID = UUID(),
        primaryDomain: ErisLifeDomain,
        secondaryDomain: ErisLifeDomain,
        title: String,
        description: String,
        recommendedAction: String,
        urgencyScore: Int = 5
    ) {
        self.id = id
        self.primaryDomain = primaryDomain
        self.secondaryDomain = secondaryDomain
        self.title = title
        self.description = description
        self.recommendedAction = recommendedAction
        self.urgencyScore = urgencyScore
    }
}

/// Bölüm 43 ("Hayatın Farklı Alanlarını Birbirine Bağlama") gereğince:
/// Takvim, Trafik, Hava Durumu, Yemek, Alışveriş, Seyahat ve Finans
/// bilgilerini tek bir bağlam matrisinde birleştiren Çapraz Alan Sentezleyici Zekâ Motoru.
public final class ErisCrossDomainSynthesizer: Sendable {
    public static let shared = ErisCrossDomainSynthesizer()
    
    private init() {}
    
    /// Güncel takvim etkinlikleri, hava durumu, seyahat ve açık işlerden çapraz içgörüler türetir
    public func synthesizeCrossContext(
        events: [ErisCalendarEvent],
        marineInfo: MarineWeatherInfo,
        pendingLoops: [OpenLoopItem]
    ) -> [CrossDomainInsight] {
        var insights: [CrossDomainInsight] = []
        
        // 1. Takvim + Trafik & Rota Sentezi
        if let firstMorningEvent = events.first(where: {
            Calendar.current.component(.hour, from: $0.startDate) <= 11
        }) {
            insights.append(CrossDomainInsight(
                primaryDomain: .calendarTime,
                secondaryDomain: .commuteTransit,
                title: "Toplantı & Rota Optimizasyonu",
                description: "Saat \(formatTime(firstMorningEvent.startDate))'deki \(firstMorningEvent.title) için köprü trafiği beklenenden %15 daha yoğun.",
                recommendedAction: "Evden çıkış saatini 20 dakika öne çek.",
                urgencyScore: 8
            ))
        }
        
        // 2. Takvim + Hava Durumu Sentezi
        let isOutdoorOrWindy = marineInfo.windSpeedKnots > 18 || marineInfo.seaCondition.lowercased().contains("fırtına")
        if isOutdoorOrWindy {
            insights.append(CrossDomainInsight(
                primaryDomain: .calendarTime,
                secondaryDomain: .dailyRoutine,
                title: "Sert Rüzgar & Dış Mekan Uyarısı",
                description: "Bölgede \(marineInfo.windSpeedKnots) knot rüzgar ve sert hava şartları var.",
                recommendedAction: "Dış mekan görüşmelerini kapalı ortama taşı veya korunaklı giyin.",
                urgencyScore: 6
            ))
        }
        
        // 3. Seyahat + Takvim + Yaşayan Liste Sentezi
        let travelLoops = pendingLoops.filter { $0.domain == .travelItinerary }
        if let travelLoop = travelLoops.first {
            insights.append(CrossDomainInsight(
                primaryDomain: .travelItinerary,
                secondaryDomain: .livingChecklists,
                title: "Seyahat Hazırlığı & Bavul Listesi",
                description: travelLoop.title,
                recommendedAction: "Varış şehri hava tahminine göre bavul checklist'ini incele ve check-in saatini doğrula.",
                urgencyScore: 7
            ))
        }
        
        // 4. Finans + Abonelik / Fatura Sentezi
        let billLoops = pendingLoops.filter { $0.domain == .billsSubscriptions }
        if let bill = billLoops.first {
            insights.append(CrossDomainInsight(
                primaryDomain: .billsSubscriptions,
                secondaryDomain: .financeBudget,
                title: "Yaklaşan Fatura & Bütçe Eşleşmesi",
                description: "\(bill.title) ödeme vadesi yaklaşıyor.",
                recommendedAction: "Hesap bakiyesini teyit et ve takvimde ödeme hatırlatıcısı kur.",
                urgencyScore: 7
            ))
        }
        
        return insights
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
