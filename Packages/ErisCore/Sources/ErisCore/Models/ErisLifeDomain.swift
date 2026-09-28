//
//  ErisLifeDomain.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation
import SwiftUI

/// `comprehensive_ai_personal_assistant_needs_to_capabilities.md` belgesindeki
/// 52 hayat alanı ve ihtiyacını temsil eden kapsamlı Yaşam Alanı taksonomisi.
public enum ErisLifeDomain: String, Codable, CaseIterable, Sendable {
    // 1. Günlük Akış & Rutinler
    case dailyRoutine = "daily_routine"
    case morningRoutine = "morning_routine"
    case commuteTransit = "commute_transit"
    case eveningRoutine = "evening_routine"
    
    // 2. İş, Kariyer, Takvim & Görevler
    case workCareer = "work_career"
    case calendarTime = "calendar_time"
    case tasksOpenLoops = "tasks_open_loops"
    case meetingsCalls = "meetings_calls"
    case emailMessaging = "email_messaging"
    
    // 3. Ev, Mutfak & Aile
    case homeManagement = "home_management"
    case homePantry = "home_pantry"
    case mealsNutrition = "meals_nutrition"
    case familyManagement = "family_management"
    case hospitalityGuests = "hospitality_guests"
    
    // 4. Finans & Alışveriş
    case financeBudget = "finance_budget"
    case billsSubscriptions = "bills_subscriptions"
    case shoppingPurchases = "shopping_purchases"
    case priceTracking = "price_tracking"
    case warrantyReturns = "warranty_returns"
    
    // 5. Seyahat, Araç & Lojistik
    case travelItinerary = "travel_itinerary"
    case vehicleMaintenance = "vehicle_maintenance"
    case relocationMoving = "relocation_moving"
    
    // 6. Sağlık & Wellness
    case healthOrganization = "health_organization"
    case personalCare = "personal_care"
    case wellnessRest = "wellness_rest"
    
    // 7. Kişisel Gelişim & Sosyal
    case personalGoals = "personal_goals"
    case habitsRoutines = "habits_routines"
    case learningEducation = "learning_education"
    case mediaBooks = "media_books"
    case knowledgeResearch = "knowledge_research"
    case socialCRM = "social_crm"
    case eventsSpecialDays = "events_special_days"
    case leisureInterests = "leisure_interests"
    case personalProjects = "personal_projects"
    
    // 8. Dijital Yaşam, Arşiv & Güvenlik
    case documentsVault = "documents_vault"
    case digitalSecurity = "digital_security"
    case digitalFiles = "digital_files"
    case livingChecklists = "living_checklists"
    case lifeAdmin = "life_admin"
    
    // MARK: - Display Properties
    
    public var displayName: String {
        switch self {
        case .dailyRoutine: return "Günlük Plan & Rutin"
        case .morningRoutine: return "Sabah Rutini"
        case .commuteTransit: return "Ulaşım & Rota"
        case .eveningRoutine: return "Akşam Kapanışı"
        case .workCareer: return "İş & Kariyer"
        case .calendarTime: return "Takvim & Zaman"
        case .tasksOpenLoops: return "Açık İşler & Görevler"
        case .meetingsCalls: return "Toplantılar & Görüşmeler"
        case .emailMessaging: return "E-posta & İletişim"
        case .homeManagement: return "Ev Yönetimi & Bakım"
        case .homePantry: return "Kiler & Market Eksilenler"
        case .mealsNutrition: return "Yemek & Tarifler"
        case .familyManagement: return "Aile Koordinasyonu"
        case .hospitalityGuests: return "Misafir Ağırlama"
        case .financeBudget: return "Finans & Bütçe"
        case .billsSubscriptions: return "Faturalar & Abonelikler"
        case .shoppingPurchases: return "Alışveriş & Karar"
        case .priceTracking: return "Fiyat & İndirim Takibi"
        case .warrantyReturns: return "Garanti & İade Süreleri"
        case .travelItinerary: return "Seyahat & Bavul"
        case .vehicleMaintenance: return "Araç & Servis"
        case .relocationMoving: return "Taşınma & Lojistik"
        case .healthOrganization: return "Sağlık & İlaçlar"
        case .personalCare: return "Kişisel Bakım"
        case .wellnessRest: return "Dinlenme & Mola"
        case .personalGoals: return "Kişisel Hedefler"
        case .habitsRoutines: return "Alışkanlıklar & Zincir"
        case .learningEducation: return "Öğrenme & Kurslar"
        case .mediaBooks: return "Kitap & Medya"
        case .knowledgeResearch: return "Araştırma & Bilgi"
        case .socialCRM: return "Sosyal Çevre & CRM"
        case .eventsSpecialDays: return "Özel Günler & Doğum Günleri"
        case .leisureInterests: return "Boş Zaman & İlgi Alanları"
        case .personalProjects: return "Kişisel Projeler"
        case .documentsVault: return "Kişisel Kasa & Evraklar"
        case .digitalSecurity: return "Dijital Güvenlik"
        case .digitalFiles: return "Dosyalar & Arşiv"
        case .livingChecklists: return "Yaşayan Listeler"
        case .lifeAdmin: return "Life Admin & Bürokrasi"
        }
    }
    
    public var shortDisplayName: String {
        switch self {
        case .dailyRoutine: return "Günlük Plan"
        case .morningRoutine: return "Sabah"
        case .commuteTransit: return "Ulaşım"
        case .eveningRoutine: return "Akşam"
        case .workCareer: return "İş & Kariyer"
        case .calendarTime: return "Takvim"
        case .tasksOpenLoops: return "Açık İşler"
        case .meetingsCalls: return "Toplantı"
        case .emailMessaging: return "İletişim"
        case .homeManagement: return "Ev & Bakım"
        case .homePantry: return "Kiler & Market"
        case .mealsNutrition: return "Beslenme"
        case .familyManagement: return "Aile"
        case .hospitalityGuests: return "Misafir"
        case .financeBudget: return "Finans"
        case .billsSubscriptions: return "Faturalar"
        case .shoppingPurchases: return "Alışveriş"
        case .priceTracking: return "Fiyat Takip"
        case .warrantyReturns: return "Garanti & İade"
        case .travelItinerary: return "Seyahat"
        case .vehicleMaintenance: return "Araç Bakım"
        case .relocationMoving: return "Taşınma"
        case .healthOrganization: return "Sağlık"
        case .personalCare: return "Bakım"
        case .wellnessRest: return "Dinlenme"
        case .personalGoals: return "Hedefler"
        case .habitsRoutines: return "Alışkanlık"
        case .learningEducation: return "Eğitim"
        case .mediaBooks: return "Kitaplar"
        case .knowledgeResearch: return "Araştırma"
        case .socialCRM: return "Sosyal"
        case .eventsSpecialDays: return "Özel Gün"
        case .leisureInterests: return "İlgi Alanı"
        case .personalProjects: return "Projeler"
        case .documentsVault: return "Kasa"
        case .digitalSecurity: return "Güvenlik"
        case .digitalFiles: return "Dosyalar"
        case .livingChecklists: return "Listeler"
        case .lifeAdmin: return "Bürokrasi"
        }
    }
    
    public var icon: String {
        switch self {
        case .dailyRoutine: return "sun.horizon.fill"
        case .morningRoutine: return "alarm.waves.left.and.right.fill"
        case .commuteTransit: return "car.fill"
        case .eveningRoutine: return "moon.stars.fill"
        case .workCareer: return "briefcase.fill"
        case .calendarTime: return "calendar"
        case .tasksOpenLoops: return "checklist"
        case .meetingsCalls: return "person.2.wave.2.fill"
        case .emailMessaging: return "envelope.fill"
        case .homeManagement: return "house.fill"
        case .homePantry: return "cart.fill"
        case .mealsNutrition: return "fork.knife"
        case .familyManagement: return "figure.2.and.child.holdinghands"
        case .hospitalityGuests: return "cup.and.saucer.fill"
        case .financeBudget: return "creditcard.fill"
        case .billsSubscriptions: return "doc.badge.gearshape.fill"
        case .shoppingPurchases: return "bag.fill"
        case .priceTracking: return "chart.line.uptrend.xyaxis"
        case .warrantyReturns: return "clock.arrow.circlepath"
        case .travelItinerary: return "airplane"
        case .vehicleMaintenance: return "wrench.and.screwdriver.fill"
        case .relocationMoving: return "shippingbox.fill"
        case .healthOrganization: return "cross.case.fill"
        case .personalCare: return "sparkles"
        case .wellnessRest: return "heart.fill"
        case .personalGoals: return "target"
        case .habitsRoutines: return "repeat"
        case .learningEducation: return "graduationcap.fill"
        case .mediaBooks: return "book.closed.fill"
        case .knowledgeResearch: return "magnifyingglass"
        case .socialCRM: return "person.crop.circle.badge.plus"
        case .eventsSpecialDays: return "gift.fill"
        case .leisureInterests: return "gamecontroller.fill"
        case .personalProjects: return "hammer.fill"
        case .documentsVault: return "lock.shield.fill"
        case .digitalSecurity: return "key.fill"
        case .digitalFiles: return "folder.fill"
        case .livingChecklists: return "list.bullet.clipboard.fill"
        case .lifeAdmin: return "tray.full.fill"
        }
    }
    
    public var pillarName: String {
        switch self {
        case .dailyRoutine, .morningRoutine, .commuteTransit, .eveningRoutine:
            return "Günlük Akış & Rutinler"
        case .workCareer, .calendarTime, .tasksOpenLoops, .meetingsCalls, .emailMessaging:
            return "İş, Takvim & Görevler"
        case .homeManagement, .homePantry, .mealsNutrition, .familyManagement, .hospitalityGuests:
            return "Ev, Mutfak & Aile"
        case .financeBudget, .billsSubscriptions, .shoppingPurchases, .priceTracking, .warrantyReturns:
            return "Finans, Faturalar & Alışveriş"
        case .travelItinerary, .vehicleMaintenance, .relocationMoving:
            return "Seyahat & Mobilite"
        case .healthOrganization, .personalCare, .wellnessRest:
            return "Sağlık & Yaşam"
        case .personalGoals, .habitsRoutines, .learningEducation, .mediaBooks, .knowledgeResearch, .socialCRM, .eventsSpecialDays, .leisureInterests, .personalProjects:
            return "Kişisel Gelişim & Sosyal"
        case .documentsVault, .digitalSecurity, .digitalFiles, .livingChecklists, .lifeAdmin:
            return "Kasa & Life Admin"
        }
    }
}
