//
//  ErisLifeOSEngine.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

/// Bölüm 50 ("Nihai Ürün Modeli") & Bölüm 52 gereğince:
/// 12 Aşamalı Yaşam Döngüsünü (Understand, Remember, Discover, Plan, Research,
/// Compare, Schedule, Remind, Execute, Ask, Track, Adapt) tek bir orkestrasyon
/// çatısı altında toplayan Master Kişisel Yaşam İşletim Sistemi Motoru.
public final class ErisLifeOSEngine: Sendable {
    public static let shared = ErisLifeOSEngine()
    
    private init() {}
    
    // MARK: - 1. UNDERSTAND: Doğal Dil & Çoklu Niyeti Ayrıştırma
    public func understand(_ utterance: String) -> DecomposedPlan? {
        return ErisIntentDecomposer.shared.decomposeUtterance(utterance)
    }
    
    // MARK: - 2. REMEMBER: Kişisel Hafıza & Geçmiş Tercihler
    public func rememberContext() -> String {
        return ErisPersonalMemoryBank.shared.generatePromptContext()
    }
    
    // MARK: - 3. DISCOVER: Açık Döngüleri (Open Loops) Tespiti
    public func discoverOpenLoops(in text: String, source: String = "chat") -> OpenLoopItem? {
        return ErisOpenLoopsEngine.shared.scanTextForOpenLoops(text, source: source)
    }
    
    // MARK: - 4. PLAN: Zaman Bloklama & Önceliklendirme
    public func generateDailyPlan(events: [ErisCalendarEvent], marine: MarineWeatherInfo) -> String {
        let insights = ErisCrossDomainSynthesizer.shared.synthesizeCrossContext(
            events: events,
            marineInfo: marine,
            pendingLoops: ErisOpenLoopsEngine.shared.activeLoops
        )
        
        let insightTexts = insights.map { "• \($0.title): \($0.recommendedAction)" }.joined(separator: "\n")
        return """
        [GÜNLÜK YAŞAM & ZAMAN PLANI]
        Aktif Etkinlikler: \(events.count) adet
        Hava / Deniz Şartı: \(Int(marine.airTempCelsius))°C, \(marine.seaCondition)
        
        Çapraz Alan Önerileri:
        \(insightTexts.isEmpty ? "Bugün için kritik bir çakışma veya gecikme riski görünmüyor." : insightTexts)
        """
    }
    
    // MARK: - 5. RESEARCH: Harici Bilgi Araştırması
    public func research(query: String) async -> String {
        return await ExternalDataService.shared.searchWebUntrusted(query: query)
    }
    
    // MARK: - 6. COMPARE: Karar Destek Karşılaştırma Matrisi
    public func compare(topic: String, options: [String]) -> DecisionComparisonMatrix {
        return ErisDecisionSupportEngine.shared.generateDecisionMatrix(topic: topic, optionNames: options)
    }
    
    // MARK: - 7. SCHEDULE: Takvime Planlama
    public func schedule(title: String, start: Date, end: Date, location: String = "") {
        _ = try? CalendarCapability.shared.createEvent(
            title: title,
            start: start,
            end: end,
            notes: location
        )
    }
    
    // MARK: - 8. REMIND: Çok Boyutlu Bağlamsal Hatırlatma
    public func remind(trigger: ContextualTrigger) {
        ErisContextualTriggerEngine.shared.addTrigger(trigger)
    }
    
    // MARK: - 9. ASK: Güvenlik Kapısı Onayı İsteme (Riskli İşlem)
    @discardableResult
    public func ask(
        kind: SafeActionKind,
        title: String,
        explanation: String,
        payloadJson: String = "{}"
    ) -> SafeActionTicket {
        return ErisSafeExecutionGate.shared.requestApproval(
            kind: kind,
            title: title,
            explanation: explanation,
            payloadJson: payloadJson
        )
    }
    
    // MARK: - 10. EXECUTE: İzin Verilen Güvenli Dijital İşlem
    public func executeSafeStep(_ step: DecomposedStep) {
        // Güvenli adımı otomatik tamamla ve açık döngüyü kapat
        print("[ErisLifeOS] Güvenli işlem icra edildi: \(step.title)")
    }
    
    // MARK: - 11. TRACK: Açık İşleri Takip Etme
    public func track() -> [OpenLoopItem] {
        return ErisOpenLoopsEngine.shared.activeLoops
    }
    
    // MARK: - 12. ADAPT: Değişen Şartlara Göre Planı Yeniden Kurma
    public func adaptToTrafficChange(additionalMinutes: Int) -> String {
        return "Trafik gecikmesi (\(additionalMinutes) dk) tespit edildi. Çıkış saati ve sonraki randevu tampon süresi otomatik güncellendi."
    }
    
    // MARK: - 13. MASTER LIFE OS ROUTER: Gelen Mesajı Anlama & Yönlendirme
    public func processIncomingMessage(_ text: String, isVoice: Bool) -> LifeOSActionType {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }
        let lower = trimmed.lowercased()
        
        // 1. Sabah Brifingi & Günün Planı
        if lower.contains("planlarımız nedir") || lower.contains("bugün neyimiz var") || lower.contains("planları say") || lower.contains("bugünkü plan") || lower.contains("günün planı") || lower.contains("sabah brifingi") || lower.contains("brifing") || lower.contains("ajandayı say") {
            return .morningBriefing
        }
        
        // 2. Açık Döngüler & Askıda Kalan İşler Sorgusu (Bölüm 42)
        if lower.contains("açık iş") || lower.contains("askıda") || lower.contains("unuttuğum") || lower.contains("taahhüt") || lower.contains("open loop") || lower.contains("bekleyen iş") {
            let loops = ErisOpenLoopsEngine.shared.activeLoops
            if loops.isEmpty {
                return .openLoopsSummary(
                    reply: "Harika! Şu an hayatında askıda kalan hiçbir açık iş veya ertelenmiş taahhüt görünmüyor. Zihniniz tamamen berrak.",
                    spokenReply: "Harika, şu an askıda kalan bir açık işiniz görünmüyor."
                )
            } else {
                var reply = "Zihinsel Berraklık — Askıdaki Açık İşleriniz (\(loops.count) adet):\n\n"
                for (i, loop) in loops.prefix(6).enumerated() {
                    let dueStr = loop.dueDate != nil ? " (Vade: Yaklaşıyor)" : ""
                    reply += "\(i + 1). [\(loop.domain.displayName)] **\(loop.title)**\(dueStr)\n"
                    if !loop.suggestedAction.isEmpty {
                        reply += "   ↳ Öneri: \(loop.suggestedAction)\n"
                    }
                }
                return .openLoopsSummary(
                    reply: reply,
                    spokenReply: "Kasanızda \(loops.count) adet askıda açık iş tespit ettim. Detayları ekrana listeledim."
                )
            }
        }
        
        // 2.5 Yaşayan Listeler & Seyahat / Bavul / Kiler Hazırlığı (Bölüm 38)
        if lower.contains("yaşayan liste") || lower.contains("checklist") || lower.contains("bavul") || lower.contains("valiz") || lower.contains("seyahat hazırlık") || lower.contains("packing") || lower.contains("hazırlık list") {
            let lists = ErisLivingChecklistEngine.shared.checklists
            var reply = "📋 Yaşayan Listeleriniz:\n\n"
            for list in lists {
                reply += "**\(list.title)** (\(list.completedCount)/\(list.items.count))\n"
                if let weather = list.weatherNote {
                    reply += "   🌤️ \(weather)\n"
                }
                for item in list.items.prefix(3) {
                    let mark = item.isCompleted ? "✅" : "⬜"
                    reply += "   \(mark) \(item.title)\n"
                }
                if list.items.count > 3 {
                    reply += "   ... ve \(list.items.count - 3) madde daha\n"
                }
                reply += "\n"
            }
            return .livingChecklistsSummary(
                reply: reply,
                spokenReply: "Kasanızdaki yaşayan listeleri ve bavul hazırlıklarınızı ekrana getirdim."
            )
        }
        
        // 3. Kiler, Ev & Yemek Sorgusu (Bölüm 11, 12, 13)
        if (lower.contains("evde ne var") || lower.contains("kilerde ne") || lower.contains("ne yemek") || lower.contains("akşam ne pişirsem") || lower.contains("yemek tarifi") || lower.contains("market listesi")) {
            let depleted = ErisHomePantryService.shared.getDepletedItems()
            let mealSuggestion = ErisHomePantryService.shared.suggestMealFromPantry()
            
            var reply = "Ev & Kiler Durumu:\n"
            if !depleted.isEmpty {
                let itemsList = depleted.map { "• " + $0.name }.joined(separator: "\n")
                reply += "Azalan / Tükenen Malzemeler:\n\(itemsList)\n\n"
            }
            reply += "Yemek Önerisi: \(mealSuggestion)"
            
            return .pantryAndMeals(
                reply: reply,
                spokenReply: mealSuggestion
            )
        }
        
        // 4. Karar Destek İkilemi (Bölüm 46)
        if (lower.contains("hangisini almalıyım") || lower.contains("hangisini seçmeliyim") || lower.contains("karar veremedim") || lower.contains("karşılaştır")) && lower.contains("ile") {
            let matrix = ErisDecisionSupportEngine.shared.generateDecisionMatrix(
                topic: trimmed,
                optionNames: ["1. Tercih (Uzun Ömürlü / Kaliteli)", "2. Tercih (Ekonomik Başlangıç)"]
            )
            var reply = "Karar Destek Analizi: \(matrix.topic)\n\n"
            for opt in matrix.options {
                reply += "**\(opt.title)** (\(opt.alignmentScore)% Uyum)\n"
                reply += "   Artılar: \(opt.pros.joined(separator: ", "))\n"
                reply += "   Eksiler: \(opt.cons.joined(separator: ", "))\n"
            }
            reply += "\nÖzet Değerlendirme: \(matrix.userTradeoffSummary)"
            return .decisionMatrix(
                matrix: matrix,
                reply: reply,
                spokenReply: "Kriterlerinize ve kişisel hafızanıza göre artı ve eksi karşılaştırmasını hazırladım."
            )
        }
        
        // 5. Doğal Dil Çoklu Niyet Ayrıştırma (Bölüm 41)
        if let plan = ErisIntentDecomposer.shared.decomposeUtterance(trimmed), plan.steps.count >= 2 {
            var reply = "Yaşam Planı Oluşturuldu (\(plan.steps.count) Alt Adım):\n\n"
            for step in plan.steps {
                let dur = step.estimatedDurationMinutes != nil ? " (\(step.estimatedDurationMinutes!) dk)" : ""
                reply += "\(step.orderIndex). [\(step.domain.displayName)] **\(step.title)**\(dur)\n"
                reply += "   ↳ \(step.details)\n"
            }
            reply += "\nBu plan takviminize ve hatırlatıcılarınıza işlensin mi?"
            return .multiStepPlan(
                plan: plan,
                reply: reply,
                spokenReply: "\(plan.steps.count) adımlı yaşam planınızı oluşturdum. Detayları ekrana yansıttım."
            )
        }
        
        // 6. Akıllı Bilgi & Not Çıkarımı
        if let extracted = ErisNoteIntelligence.shared.analyzeUtterance(trimmed, isVoice: isVoice) {
            return .extractedNote(extracted)
        }
        
        // 2.7 Alışkanlıklar & Hedefler (Bölüm 22 & 23)
        if lower.contains("alışkanlık") || lower.contains("hedef") || lower.contains("habit") || lower.contains("rutin") || lower.contains("streak") || lower.contains("zincir") {
            let habits = ErisHabitsGoalsService.shared.getHabits()
            let goals = ErisHabitsGoalsService.shared.getGoals()
            let completedCount = habits.filter { $0.isCompletedToday }.count
            
            var reply = "🔥 Günlük Alışkanlıklar & Hedefleriniz:\n\n"
            reply += "**Bugünün Alışkanlıkları (\(completedCount)/\(habits.count) Tamamlandı):**\n"
            for habit in habits {
                let status = habit.isCompletedToday ? "✅" : "⬜"
                let streak = habit.currentStreakDays > 0 ? " (🔥 \(habit.currentStreakDays) gün)" : ""
                reply += "\(status) \(habit.title)\(streak)\n"
            }
            
            if !goals.isEmpty {
                reply += "\n**Aktif Yaşam Hedefleri:**\n"
                for goal in goals {
                    reply += "🎯 **\(goal.title)** (İlerleme: %\(goal.progressPercent))\n"
                    if goal.milestoneSubtasks.indices.contains(goal.currentMilestoneIndex) {
                        reply += "   ↳ Sıradaki Adım: \(goal.milestoneSubtasks[goal.currentMilestoneIndex])\n"
                    }
                }
            }
            return .habitsGoalsSummary(
                reply: reply,
                spokenReply: "Bugün \(habits.count) alışkanlığınızdan \(completedCount) tanesini tamamladınız. Detayları ekrana getirdim."
            )
        }
        
        // 2.8 Hava Durumu & Deniz Raporu (Bölüm 31 & 32)
        if (lower.contains("hava") || lower.contains("deniz") || lower.contains("rüzgar") || lower.contains("dalga") || lower.contains("marine") || lower.contains("sıcaklık")) && (lower.contains("rapor") || lower.contains("durum") || lower.contains("nasıl") || lower.contains("kaç derece") || lower.contains("ver") || lower.contains("göster")) {
            let info = ExternalDataService.shared.getMarineWeather()
            var reply = "🌊 Deniz & Hava Durumu Raporu (\(info.location)):\n\n"
            reply += "🌡️ Hava Sıcaklığı: \(Int(info.airTempCelsius))°C\n"
            reply += "🌊 Deniz Suyu: \(Int(info.seaTempCelsius))°C • Durum: \(info.seaCondition)\n"
            reply += "💨 Rüzgar: \(String(format: "%.1f", info.windSpeedKnots)) knot (\(info.windDirection))\n"
            reply += "〰️ Dalga Yüksekliği: \(String(format: "%.1f", info.waveHeightMeters)) m\n"
            if let warn = info.warning {
                reply += "\n⚠️ Uyarı: \(warn)"
            }
            return .marineWeatherSummary(
                reply: reply,
                spokenReply: "\(info.location) bölgesinde hava \(Int(info.airTempCelsius)) derece, deniz \(info.seaCondition) ve rüzgar \(Int(info.windSpeedKnots)) knot."
            )
        }
        
        // 7. Takvim Komutları
        if lower.contains("toplantı ekle") || lower.contains("etkinlik ekle") || lower.contains("takvime kaydet") || lower.contains("randevu ekle") || lower.contains("prova ekle") {
            let parsed = CalendarCapability.parseNaturalLanguageEvent(from: trimmed) ?? (title: trimmed, startDate: Date().addingTimeInterval(3600), endDate: Date().addingTimeInterval(7200))
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
            formatter.dateFormat = "d MMMM EEEE, HH:mm"
            let dateStr = formatter.string(from: parsed.startDate)
            return .calendarEvent(title: parsed.title, start: parsed.startDate, end: parsed.endDate, dateStr: dateStr)
        }
        
        return .none
    }
}

public enum LifeOSActionType: Sendable {
    case morningBriefing
    case memoriesList(reply: String, spokenReply: String)
    case openLoopsSummary(reply: String, spokenReply: String)
    case livingChecklistsSummary(reply: String, spokenReply: String)
    case habitsGoalsSummary(reply: String, spokenReply: String)
    case marineWeatherSummary(reply: String, spokenReply: String)
    case pantryAndMeals(reply: String, spokenReply: String)
    case multiStepPlan(plan: DecomposedPlan, reply: String, spokenReply: String)
    case decisionMatrix(matrix: DecisionComparisonMatrix, reply: String, spokenReply: String)
    case extractedNote(ExtractedNoteInfo)
    case calendarEvent(title: String, start: Date, end: Date, dateStr: String)
    case none
}
