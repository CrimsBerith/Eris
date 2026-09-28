import Foundation
import Combine

public enum ErisWidgetType: String, CaseIterable, Identifiable, Codable, Sendable {
    case calendar = "calendar_agenda"
    case commuteTracker = "commute_tracker"
    case openLoops = "open_loops_hub"
    case livingChecklists = "living_checklists"
    case memoryVault = "memory_vault"
    case fabricCost = "fabric_ledger"
    case marine = "marine_weather"
    case markets = "financial_markets"
    case designIdeas = "creative_ideas"
    case quickActions = "quick_actions"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .calendar: return "Günün Ajandası & Takvim"
        case .commuteTracker: return "Dinamik Rota & Çıkış Sayacı"
        case .openLoops: return "Açık Döngüler (Zihinsel Berraklık)"
        case .livingChecklists: return "Yaşayan Listeler (Bavul & Kiler)"
        case .memoryVault: return "Notlar & Dosyalar Kasası"
        case .fabricCost: return "Kumaş Fiyatları & Tedarikçiler"
        case .marine: return "Deniz & Kaptanlık Raporu"
        case .markets: return "Finans & Döviz Piyasaları"
        case .designIdeas: return "Tasarım & Koleksiyon Fikirleri"
        case .quickActions: return "Hızlı Sesli Eylemler"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .calendar: return "Toplantılar, randevular ve saatlik plan brifingi"
        case .commuteTracker: return "Canlı trafik, rota durakları ve çıkış için geri sayım"
        case .openLoops: return "Askıda kalan işler, faturalar ve tamamlanacak taahhütler"
        case .livingChecklists: return "Hava durumuna uyarlanan bavul ve azalan kiler listeleri"
        case .memoryVault: return "Sesli konuşmalardan yakalanan bilgiler, teknik notlar ve belgeler"
        case .fabricCost: return "Tedarikçilerden alınan metre fiyatları ve maliyet analizi"
        case .marine: return "Rüzgar, dalga yüksekliği ve seyir güvenliği"
        case .markets: return "Dolar, Euro, Altın, BIST ve Kripto canlı kurları"
        case .designIdeas: return "Drapaj, form, silüet ve ilham notları"
        case .quickActions: return "Tek dokunuşla brifing ve 'Hey Eris' dinleme"
        }
    }
    
    public var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .commuteTracker: return "car.fill"
        case .openLoops: return "checklist"
        case .livingChecklists: return "suitcase.fill"
        case .memoryVault: return "folder.fill"
        case .fabricCost: return "tag.fill"
        case .marine: return "water.waves"
        case .markets: return "chart.line.uptrend.xyaxis"
        case .designIdeas: return "lightbulb.fill"
        case .quickActions: return "bolt.fill"
        }
    }
    
    public var systemImage: String {
        icon
    }
    
    public var defaultEnabled: Bool {
        return true
    }
}

public final class ErisWidgetManager: ObservableObject, @unchecked Sendable {
    public static let shared = ErisWidgetManager()
    
    private let storageKey = "eris_active_widget_types_v1"
    
    @Published public var activeWidgets: [ErisWidgetType] = []
    
    private init() {
        loadSettings()
    }
    
    public func loadSettings() {
        let groupDefaults = UserDefaults(suiteName: "group.com.alfagolab.eris")
        if let rawArray = groupDefaults?.stringArray(forKey: storageKey) ?? UserDefaults.standard.stringArray(forKey: storageKey) {
            let loaded = rawArray.compactMap { ErisWidgetType(rawValue: $0) }
            if !loaded.isEmpty {
                self.activeWidgets = loaded
                return
            }
        }
        self.activeWidgets = ErisWidgetType.allCases
    }
    
    public func saveSettings() {
        let rawArray = activeWidgets.map { $0.rawValue }
        UserDefaults.standard.set(rawArray, forKey: storageKey)
        if let groupDefaults = UserDefaults(suiteName: "group.com.alfagolab.eris") {
            groupDefaults.set(rawArray, forKey: storageKey)
        }
        objectWillChange.send()
    }
    
    public func isWidgetEnabled(_ type: ErisWidgetType) -> Bool {
        return activeWidgets.contains(type)
    }
    
    public func setWidgetEnabled(_ type: ErisWidgetType, enabled: Bool) {
        if enabled {
            if !activeWidgets.contains(type) {
                activeWidgets.append(type)
                saveSettings()
            }
        } else {
            activeWidgets.removeAll(where: { $0 == type })
            saveSettings()
        }
    }
    
    public func toggleWidget(_ type: ErisWidgetType) {
        setWidgetEnabled(type, enabled: !isWidgetEnabled(type))
    }
    
    public func resetToDefaults() {
        self.activeWidgets = ErisWidgetType.allCases
        saveSettings()
    }
}
