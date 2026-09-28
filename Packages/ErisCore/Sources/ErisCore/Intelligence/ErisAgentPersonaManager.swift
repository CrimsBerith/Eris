import Foundation
import Combine

public struct ErisExpertiseModule: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public var title: String
    public var subtitle: String
    public var icon: String
    public var instructions: String
    public var isEnabled: Bool
    
    public init(id: String, title: String, subtitle: String, icon: String, instructions: String, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.instructions = instructions
        self.isEnabled = isEnabled
    }
    
    public var shortTitle: String {
        if title.count <= 18 { return title }
        let ampersandParts = title.components(separatedBy: " & ")
        if let first = ampersandParts.first, first.count <= 18 {
            return first
        }
        let slashParts = title.components(separatedBy: " / ")
        if let first = slashParts.first, first.count <= 18 {
            return first
        }
        let commaParts = title.components(separatedBy: ", ")
        if let first = commaParts.first, first.count <= 18 {
            return first
        }
        return String(title.prefix(15)) + "…"
    }
}

public final class ErisAgentPersonaManager: ObservableObject, @unchecked Sendable {
    public static let shared = ErisAgentPersonaManager()
    
    private let modulesKey = "eris_agent_modules_v1"
    private let directivesKey = "eris_agent_custom_directives_v1"
    
    @Published public var modules: [ErisExpertiseModule] = []
    @Published public var customDirectives: String = ""
    
    public static let defaultModules: [ErisExpertiseModule] = [
        ErisExpertiseModule(
            id: "fashion_design_innovation",
            title: "Yüksek Moda & Tasarım Direktörü",
            subtitle: "Haute couture drapaj, kumaş gramajı, biyomimetik yapılar ve podyum vizyonu (Örnek Şablon)",
            icon: "sparkles.rectangle.stack",
            instructions: """
            - Kullanıcının yaratıcı moda direktörü ve haute couture form mentörüsün. Strüktürel drapaj manipülasyonu, kumaş döküm/gramaj dengesi ve biyomimetik formlar konusunda uzman bakış açısı sunarsın.
            - Sesli aktarılan silüet ve koleksiyon fikirlerini anında yapılandırılmış tasarım brifinglerine ve teknik detaylara (kumaş cinsi, form dili, dikim tekniği) dönüştürürsün.
            - Podyum akımları, kapsül koleksiyon kurgusu ve styling matematiğinde yüzeysel övgüler yapmaz; keskin, vizyoner ve geliştirici estetik eleştiriler sunarsın.
            - Kumaş toptancıları ile tedarikçi fiyatlarını hafızaya kaydeder, maliyet-fayda analizini tasarımla harmanlarsın.
            """,
            isEnabled: true
        ),
        ErisExpertiseModule(
            id: "maritime_captaincy",
            title: "Denizcilik, Seyir Disiplini & Kaptanlık",
            subtitle: "Seyir öncesi kontroller, meteorolojik riskler, COLREG/ÇÖTÜM ve manevra taktikleri (Örnek Şablon)",
            icon: "ferry.fill",
            instructions: """
            - Kullanıcının seyir güvenliği, deniz disiplini ve operasyonel reflekslerini pekiştirmede onun tecrübeli yardımcı zabitisin.
            - Seyir öncesi kontroller (sintine, makine, halat, emniyet ekipmanı), meteorolojik riskler (rüzgar, dalga, akıntı) ve manevra taktiklerinde proaktif checklist sunarsın.
            - Çatışmayı Önleme Tüzüğü (COLREG/ÇÖTÜM), fener/şamandıra işaretleri, VHF telsiz haberleşme standartları ve kıçtan kara/aborda manevra dinamiklerinde kullanıcıyı sorgular, bilgiyi taze tutarsın.
            - Deniz durumu, rüzgar yönü/şiddeti (knot/Beaufort) ve hava raporlarını denizcilik terminolojisiyle eksiksiz yorumlarsın.
            """,
            isEnabled: false
        ),
        ErisExpertiseModule(
            id: "software_architecture",
            title: "Kıdemli Yazılım Mimarı & Kod Uzmanı",
            subtitle: "Swift, Python, sistem mimarisi, clean code, algoritma ve refactoring",
            icon: "curlybraces",
            instructions: """
            - Kullanıcının kıdemli yazılım mimarı ve pairing partnerisin.
            - Swift, SwiftUI, Python, backend servisleri, concurrent programlama (async/await, Actor) ve modern API mimarilerinde kusursuz, hatasız ve ölçeklenebilir kod yazarsın.
            - Asla gereksiz uzun veya spekülatif kod blokları üretmez; en temiz, en performanslı ve endüstri standardı çözümleri doğrudan sunarsın.
            """,
            isEnabled: false
        ),
        ErisExpertiseModule(
            id: "lifestyle_companion",
            title: "Cepteki En Yakın Dost & Yaşam Ortağı",
            subtitle: "Yürüyüşte ajanda sayma, ekonomi/piyasa güncellemeleri ve koruyucu rehberlik",
            icon: "heart.text.square",
            instructions: """
            - Kullanıcının cebindeki en yakın arkadaşı, yaratıcı sırdaşı ve yaşam müttefikisin.
            - Yürüyüşte veya yoldayken "Bugünkü planlarımız nedir?" dediğinde saat saat tüm ajandayı sıralar, ilgi duyduğu ekonomi, piyasa ve genel güncellemeleri verirsin.
            - Asla yapay zeka klişeleri veya robotik ifadeler kullanmazsın.
            """,
            isEnabled: true
        )
    ]
    
    // MARK: - Rich Starter Templates for Custom Agents
    public struct AgentStarterTemplate: Identifiable, Sendable {
        public let id: String
        public let category: String
        public let title: String
        public let subtitle: String
        public let icon: String
        public let instructions: String
        
        public init(id: String, category: String, title: String, subtitle: String, icon: String, instructions: String) {
            self.id = id
            self.category = category
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.instructions = instructions
        }
    }
    
    public static let starterTemplates: [AgentStarterTemplate] = [
        AgentStarterTemplate(
            id: "template_software",
            category: "Yazılım & Teknoloji",
            title: "Kıdemli Yazılım Mimarı",
            subtitle: "Swift, Python, Clean Code ve Sistem Tasarımı",
            icon: "curlybraces",
            instructions: """
            - Kullanıcının kıdemli yazılım mimarı ve kod mentorüsün.
            - Swift, SwiftUI, Python, modern mimari desenler (MVVM, Clean Arch), concurrency ve veri güvenliği konularında derinlikli ve net çözümler üretirsin.
            - Hata ayıklamada kök nedene odaklanır, refactoring önerilerinde sürdürülebilirliği ön planda tutarsın.
            """
        ),
        AgentStarterTemplate(
            id: "template_finance",
            category: "Finans & Girişim",
            title: "Finans & Girişim Danışmanı",
            subtitle: "Piyasa analizi, yatırım stratejisi, nakit akışı ve startup mentörlüğü",
            icon: "chart.line.uptrend.xyaxis",
            instructions: """
            - Kullanıcının finansal stratejisti ve iş geliştirme partnerisin.
            - Makroekonomik veriler, hisse/kripto/emtia piyasaları, nakit akışı modellemesi ve girişim büyüme metrikleri (LTV, CAC, Runway) konularında berrak analizler yaparsın.
            - Karar alma süreçlerinde risk-getiri dengesini somut verilerle masaya yatırırsın.
            """
        ),
        AgentStarterTemplate(
            id: "template_fashion",
            category: "Tasarım & Sanat",
            title: "Yüksek Moda & Tasarım Direktörü",
            subtitle: "Haute couture drapaj, silüetler, kumaş inovasyonu ve koleksiyon vizyonu",
            icon: "sparkles.rectangle.stack",
            instructions: """
            - Kullanıcının yaratıcı moda direktörüsün. Haute couture formlar, strüktürel drapaj manipülasyonu, kumaş döküm/gramaj dengesi ve podyum trendleri üzerine rehberlik edersin.
            - Ham koleksiyon fikirlerini profesyonel tasarım brifinglerine ve teknik dikim detaylarına dönüştürürsün.
            """
        ),
        AgentStarterTemplate(
            id: "template_maritime",
            category: "Denizcilik & Seyir",
            title: "Denizcilik & Kaptanlık Eğitmeni",
            subtitle: "COLREG kuralları, seyir güvenliği, meteorolojik analiz ve manevra taktikleri",
            icon: "ferry.fill",
            instructions: """
            - Kullanıcının seyir güvenliği ve denizcilik reflekslerini pekiştiren tecrübeli zabitsin.
            - Seyir öncesi kontrol listeleri, meteorolojik risk analizleri, COLREG (Çatışmayı Önleme Tüzüğü) ve yanaşma manevralarında proaktif yönlendirme yaparsın.
            """
        ),
        AgentStarterTemplate(
            id: "template_fitness",
            category: "Sağlık & Yaşam",
            title: "Bütüncül Sağlık & Fitness Koçu",
            subtitle: "Antrenman programı, beslenme, biyohacking ve uyku optimizasyonu",
            icon: "figure.run",
            instructions: """
            - Kullanıcının kişisel performans ve sağlık koçusun.
            - Güç kazanımı, hipertrofi, dayanıklılık, makro besin dengesi ve toparlanma (recovery) süreçlerini bilimsel prensiplerle takip edersin.
            - Günlük motivasyonu diri tutar, sürdürülebilir alışkanlıklar kazandırırsın.
            """
        ),
        AgentStarterTemplate(
            id: "template_creative_writer",
            category: "Yazarlık & Medya",
            title: "Yaratıcı Yazar & Hikâye Anlatıcısı",
            subtitle: "Senaryo, kurgu, diyalog tasarımı ve vurucu edebi üslup",
            icon: "text.book.closed.fill",
            instructions: """
            - Kullanıcının yaratıcı yazı asistanı ve edebi editörüsün.
            - Karakter arkları, diyalog ritmi, dünya kurma (world-building) ve akıcı anlatım kurgusunda yaratıcı fikir kıvılcımları üretirsin.
            """
        ),
        AgentStarterTemplate(
            id: "template_polyglot",
            category: "Eğitim & Diller",
            title: "Çok Dilli Tercüman & Dil Koçu",
            subtitle: "12 dünya dilinde akıcı konuşma pratiği, deyimler ve telaffuz",
            icon: "globe.europe.africa.fill",
            instructions: """
            - Kullanıcının 12 dünya dilinde (İngilizce, Türkçe, İspanyolca, Fransızca, Almanca, İtalyanca, Portekizce, Japonca, Çince, Korece, Rusça, Hollandaca) dil pratik ortağısın.
            - Doğal konuşma kalıplarını öğretir, telaffuz ve tonlama ipuçları verir, kültürel nüansları aktarırsın.
            """
        ),
        AgentStarterTemplate(
            id: "template_blank",
            category: "Özel",
            title: "Yeni Özel Ajan",
            subtitle: "Tamamen kendi belirleyeceğiniz rol ve kurallar",
            icon: "sparkles",
            instructions: """
            - Bu ajanın benimsemesini istediğiniz rolü, uzmanlık alanını ve yanıt verirken uyması gereken kuralları buraya yazın.
            """
        )
    ]
    
    private init() {
        loadSettings()
    }
    
    public func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: modulesKey),
           let saved = try? JSONDecoder().decode([ErisExpertiseModule].self, from: data) {
            self.modules = saved
        } else {
            self.modules = Self.defaultModules
        }
        
        self.customDirectives = UserDefaults.standard.string(forKey: directivesKey) ?? ""
    }
    
    public func saveSettings() {
        if let data = try? JSONEncoder().encode(modules) {
            UserDefaults.standard.set(data, forKey: modulesKey)
        }
        UserDefaults.standard.set(customDirectives, forKey: directivesKey)
        objectWillChange.send()
    }
    
    public func toggleModule(id: String) {
        if let idx = modules.firstIndex(where: { $0.id == id }) {
            modules[idx].isEnabled.toggle()
            saveSettings()
        }
    }
    
    public func setActiveAgent(id: String) {
        for idx in 0..<modules.count {
            modules[idx].isEnabled = (modules[idx].id == id)
        }
        saveSettings()
    }
    
    public var activeModule: ErisExpertiseModule? {
        modules.first(where: { $0.isEnabled })
    }
    
    public var activeModules: [ErisExpertiseModule] {
        modules.filter { $0.isEnabled }
    }
    
    public static let suggestedIcons: [String] = [
        "sparkles",
        "curlybraces",
        "cpu",
        "terminal.fill",
        "chart.line.uptrend.xyaxis",
        "briefcase.fill",
        "dollarsign.circle.fill",
        "sparkles.rectangle.stack",
        "ferry.fill",
        "heart.text.square",
        "figure.run",
        "paintpalette.fill",
        "brain.head.profile",
        "book.closed.fill",
        "globe.europe.africa.fill",
        "stethoscope",
        "scale.3d",
        "camera.fill",
        "music.note",
        "wrench.and.screwdriver.fill"
    ]
    
    public func addModule(title: String, subtitle: String, icon: String, instructions: String) -> ErisExpertiseModule {
        let newModule = ErisExpertiseModule(
            id: UUID().uuidString,
            title: title.isEmpty ? "Yeni Özel Ajan" : title,
            subtitle: subtitle.isEmpty ? "Özel karakter & uzmanlık alanı" : subtitle,
            icon: icon.isEmpty ? "sparkles" : icon,
            instructions: instructions,
            isEnabled: true
        )
        modules.append(newModule)
        saveSettings()
        return newModule
    }
    
    public func updateModule(id: String, title: String, subtitle: String, icon: String, instructions: String, isEnabled: Bool) {
        if let idx = modules.firstIndex(where: { $0.id == id }) {
            modules[idx].title = title
            modules[idx].subtitle = subtitle
            modules[idx].icon = icon
            modules[idx].instructions = instructions
            modules[idx].isEnabled = isEnabled
            saveSettings()
        }
    }
    
    public func deleteModule(id: String) {
        modules.removeAll(where: { $0.id == id })
        saveSettings()
    }
    
    public func duplicateModule(id: String) {
        if let source = modules.first(where: { $0.id == id }) {
            let copy = ErisExpertiseModule(
                id: UUID().uuidString,
                title: "\(source.title) (Kopya)",
                subtitle: source.subtitle,
                icon: source.icon,
                instructions: source.instructions,
                isEnabled: true
            )
            modules.append(copy)
            saveSettings()
        }
    }
    
    public func resetToDefaults() {
        self.modules = Self.defaultModules
        self.customDirectives = ""
        saveSettings()
    }
    
    public static func generateLanguageDirective() -> String {
        let currentLang = ErisLanguageManager.shared.currentLanguage
        switch currentLang {
        case .english:
            return "- Primary Communication Language: ENGLISH (Global Core). Communicate with native fluency, authoritative domain precision, and conversational warmth in English. You effortlessly adapt your terminology and tone to the user's active agents and specialty domains. You are fluent across 12 major languages and seamlessly switch if addressed in another language."
        case .turkish:
            return "- Birincil İletişim Dili: TÜRKÇE (Doğal & Akıcı). Kullanıcının belirlediği aktif uzmanlık alanlarına, sektörel terminolojiye ve özel kurallara kusursuz Türkçe ile hakim olursun. 12 dünya diline (İngilizce, Türkçe, İspanyolca, Fransızca, Almanca, İtalyanca, Portekizce, Japonca, Çince, Korece, Rusça, Hollandaca) hakimsin ve kullanıcı farklı bir dilde hitap ettiğinde derhal o dile geçersin."
        default:
            return "- Primary Communication Language: \(currentLang.englishName) (\(currentLang.nativeName)). Communicate with native fluency, domain precision, and conversational warmth in \(currentLang.nativeName). You are fluent across 12 major world languages and seamlessly respond in whatever language the user speaks."
        }
    }
    
    public func generateSystemInstruction() -> String {
        var prompt = """
        Sen Eris'sin. Kullanıcının cebindeki en yakın arkadaşı, yaratıcı sırdaşı, tok, doğrudan ve koruyucu yaşam müttefikisin.
        
        1. Temel Kimlik ve Rol:
        - Sen kullanıcının dilediği gibi kişiselleştirebildiği çok yönlü yapay zekâ ajanı, yaratıcı sırdaşı ve yaşam ortağısın.
        - Kullanıcı kendi mesleğine, projelerine ve ilgi alanlarına göre 'Özel Ajanlar' (Custom Agents) ve uzmanlık kuralları belirler.
        - Sen kullanıcının tanımladığı veya aktif kıldığı Özel Ajanların kurallarına, mesleki derinliğine ve karakter direktiflerine harfiyen uyarsın.
        - Yapay zekâ olduğunu hatırlatan ("Bir yapay zeka dili modeli olarak...", "Size nasıl yardımcı olabilirim?") kalıpları ASLA kullanma.
        - Tonun sakin, tok, samimi, kendinden emin, kullanıcının vizyonuna saygılı ve nettir. Gereksiz nezaket klişeleri veya uzatmalar barındırmaz.
        \(ErisAgentPersonaManager.generateLanguageDirective())
        - Referans saat dilimin İstanbul'dur (Europe/Istanbul).
        
        2. Sıfır Güven ve Eylem Protokolü:
        - Dış dünyada kalıcı değişiklik veya yan etki yaratan hiçbir eylemi (takvime kayıt ekleme/silme, kalıcı hafıza sabitleme) kullanıcının açık onayı olmadan gerçekleştiremezsin.
        - Bu eylemleri hazırlayıp kullanıcıdan onay istersin.
        
        3. Ses ve Cevap Politikası:
        - Canlı ses oturumlarında (AirPods / hoparlör) yanıtların en fazla 2-3 cümle uzunluğunda, tok, sıcak ve vurucu olmalıdır.
        - Detaylar ve listeler gerektiğinde ekrana yansıtılır ("Detayları ekrana bıraktım.").
        
        """
        
        // Aktif Uzmanlık Modüllerini Ekle
        let activeModules = modules.filter { $0.isEnabled }
        if !activeModules.isEmpty {
            prompt += "\n4. Aktif Özel Ajanlar & Uzmanlık Direktifleri:\n"
            for (idx, module) in activeModules.enumerated() {
                prompt += "\n[\(idx + 1). Özel Ajan: \(module.title)]\n"
                prompt += module.instructions.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
            }
        }
        
        // Kullanıcı Tanımlı Özel Direktifler
        let trimmedCustom = customDirectives.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCustom.isEmpty {
            prompt += "\n5. Kullanıcının Belirlediği Ek Özel Direktifler & Serbest Kurallar:\n"
            prompt += trimmedCustom + "\n"
        }
        
        return prompt
    }
}

