//
//  ErisLanguageManager.swift
//  ErisCore
//

import Foundation
import Combine

public final class ErisLanguageManager: ObservableObject, @unchecked Sendable {
    public static let shared = ErisLanguageManager()
    
    private let languageKey = "eris_selected_language_v1"
    private let appGroupSuite = "group.com.alfagolab.eris"
    
    @Published public var currentLanguage: ErisLanguage = .turkish {
        didSet {
            saveLanguage(currentLanguage)
            onLanguageChanged?(currentLanguage)
        }
    }
    
    public var onLanguageChanged: (@Sendable (ErisLanguage) -> Void)?
    
    private init() {
        self.currentLanguage = loadSavedLanguage()
    }
    
    private func loadSavedLanguage() -> ErisLanguage {
        let groupDefaults = UserDefaults(suiteName: appGroupSuite)
        if let raw = groupDefaults?.string(forKey: languageKey) ?? UserDefaults.standard.string(forKey: languageKey),
           let lang = ErisLanguage(rawValue: raw) {
            return lang
        }
        
        // Cihazın varsayılan diline göre otomatik eşleştir
        let preferred = Locale.preferredLanguages.first ?? "tr"
        for lang in ErisLanguage.allCases {
            if preferred.starts(with: lang.rawValue) {
                return lang
            }
        }
        return .turkish
    }
    
    private func saveLanguage(_ language: ErisLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        if let groupDefaults = UserDefaults(suiteName: appGroupSuite) {
            groupDefaults.set(language.rawValue, forKey: languageKey)
        }
    }
    
    public func setLanguage(_ language: ErisLanguage) {
        if self.currentLanguage != language {
            self.currentLanguage = language
        }
    }
}

// MARK: - Localized String Dictionary
public struct L10n {
    public static var lang: ErisLanguage {
        ErisLanguageManager.shared.currentLanguage
    }
    
    // MARK: - Navigation Tabs
    public static var tabChat: String {
        switch lang {
        case .english: return "Chat"
        case .turkish: return "Sohbet"
        case .spanish: return "Chat"
        case .french: return "Discussion"
        case .german: return "Chat"
        case .italian: return "Chat"
        case .portuguese: return "Conversa"
        case .japanese: return "チャット"
        case .chinese: return "对话"
        case .korean: return "대화"
        case .russian: return "Чат"
        case .dutch: return "Gesprek"
        }
    }
    
    public static var tabWidgets: String {
        switch lang {
        case .english: return "Widgets"
        case .turkish: return "Widget'lar"
        case .spanish: return "Widgets"
        case .french: return "Widgets"
        case .german: return "Widgets"
        case .italian: return "Widget"
        case .portuguese: return "Widgets"
        case .japanese: return "ウィジェット"
        case .chinese: return "小组件"
        case .korean: return "위젯"
        case .russian: return "Виджеты"
        case .dutch: return "Widgets"
        }
    }
    
    public static var tabMemory: String {
        switch lang {
        case .english: return "Notes & Files"
        case .turkish: return "Notlar & Dosyalar"
        case .spanish: return "Notas y Archivos"
        case .french: return "Notes et Fichiers"
        case .german: return "Notizen & Dateien"
        case .italian: return "Note e File"
        case .portuguese: return "Notas e Arquivos"
        case .japanese: return "ノートとファイル"
        case .chinese: return "笔记与文件"
        case .korean: return "노트 및 파일"
        case .russian: return "Заметки и файлы"
        case .dutch: return "Notities & Bestanden"
        }
    }
    
    public static var tabSettings: String {
        switch lang {
        case .english: return "Settings"
        case .turkish: return "Ayarlar"
        case .spanish: return "Ajustes"
        case .french: return "Paramètres"
        case .german: return "Einstellungen"
        case .italian: return "Impostazioni"
        case .portuguese: return "Ajustes"
        case .japanese: return "設定"
        case .chinese: return "设置"
        case .korean: return "설정"
        case .russian: return "Настройки"
        case .dutch: return "Instellingen"
        }
    }
    
    public static var tabChecklists: String {
        switch lang {
        case .english: return "Checklists"
        case .turkish: return "Listeler"
        case .spanish: return "Listas"
        case .french: return "Listes"
        case .german: return "Listen"
        case .italian: return "Liste"
        case .portuguese: return "Listas"
        case .japanese: return "リスト"
        case .chinese: return "清单"
        case .korean: return "체크리스트"
        case .russian: return "Списки"
        case .dutch: return "Lijsten"
        }
    }
    
    // MARK: - Common Actions
    public static var seeAll: String {
        switch lang {
        case .english: return "See All"
        case .turkish: return "Tümünü Gör"
        case .spanish: return "Ver Todo"
        case .french: return "Voir Tout"
        case .german: return "Alle Anzeigen"
        case .italian: return "Vedi Tutti"
        case .portuguese: return "Ver Tudo"
        case .japanese: return "すべて見る"
        case .chinese: return "查看全部"
        case .korean: return "전체 보기"
        case .russian: return "Смотреть все"
        case .dutch: return "Alles Bekijken"
        }
    }
    
    public static var select: String {
        switch lang {
        case .english: return "Select"
        case .turkish: return "Seç"
        case .spanish: return "Elegir"
        case .french: return "Choisir"
        case .german: return "Wählen"
        case .italian: return "Seleziona"
        case .portuguese: return "Selecionar"
        case .japanese: return "選択"
        case .chinese: return "选择"
        case .korean: return "선택"
        case .russian: return "Выбрать"
        case .dutch: return "Selecteer"
        }
    }
    
    public static var selected: String {
        switch lang {
        case .english: return "Selected"
        case .turkish: return "Seçili"
        case .spanish: return "Seleccionado"
        case .french: return "Sélectionné"
        case .german: return "Ausgewählt"
        case .italian: return "Selezionato"
        case .portuguese: return "Selecionado"
        case .japanese: return "選択中"
        case .chinese: return "已选"
        case .korean: return "선택됨"
        case .russian: return "Выбрано"
        case .dutch: return "Geselecteerd"
        }
    }
    
    public static var listenVoice: String {
        switch lang {
        case .english: return "Listen"
        case .turkish: return "Sesi Dinle"
        case .spanish: return "Escuchar"
        case .french: return "Écouter"
        case .german: return "Anhören"
        case .italian: return "Ascolta"
        case .portuguese: return "Ouvir"
        case .japanese: return "試聴"
        case .chinese: return "试听"
        case .korean: return "듣기"
        case .russian: return "Слушать"
        case .dutch: return "Luister"
        }
    }
    
    public static var inputPlaceholder: String {
        switch lang {
        case .english: return "Instruct Eris (e.g. 'Schedule briefing for 3 PM')..."
        case .turkish: return "Eris'e talimat ver (Örn: 'Saat 15:00'e toplantı ekle')..."
        case .spanish: return "Instruye a Eris (Ej: 'Agendar reunión a las 15:00')..."
        case .french: return "Donner une consigne à Eris (ex: 'Réunion à 15h')..."
        case .german: return "Anweisung an Eris (z.B. 'Meeting um 15:00 eintragen')..."
        case .italian: return "Istruisci Eris (es: 'Aggiungi riunione alle 15:00')..."
        case .portuguese: return "Instrua Eris (ex: 'Agendar reunião às 15h')..."
        case .japanese: return "Erisに指示を入力 (例: 「15時に会議を追加」)..."
        case .chinese: return "向 Eris 下达指令 (例如: “添加下午3点会议”)..."
        case .korean: return "Eris에게 지시 입력 (예: '오후 3시 미팅 추가')..."
        case .russian: return "Дать команду Eris (напр: 'Добавить встречу на 15:00')..."
        case .dutch: return "Geef Eris een instructie (bijv: 'Plan meeting om 15:00')..."
        }
    }
    
    public static var greetingReady: String {
        switch lang {
        case .english: return "Eris ready. Listening."
        case .turkish: return "Eris hazır. Dinliyorum."
        case .spanish: return "Eris lista. Te escucho."
        case .french: return "Eris prête. Je vous écoute."
        case .german: return "Eris bereit. Ich höre zu."
        case .italian: return "Eris pronta. Ti ascolto."
        case .portuguese: return "Eris pronta. Estou ouvindo."
        case .japanese: return "Eris 準備完了。聞いています。"
        case .chinese: return "Eris 已准备就绪。正在聆听。"
        case .korean: return "Eris 준비 완료. 듣고 있습니다."
        case .russian: return "Eris готова. Слушаю вас."
        case .dutch: return "Eris gereed. Ik luister."
        }
    }
    
    // MARK: - Voice Tone Names
    public static func voiceToneTitle(_ tone: ErisVoiceTone) -> String {
        switch tone {
        case .tokErkek:
            switch lang {
            case .english: return "Deep & Confident Male"
            case .turkish: return "Tok & Karizmatik Erkek"
            case .spanish: return "Hombre Profundo y Resuelto"
            case .french: return "Homme Posé et Confiant"
            case .german: return "Tief & Selbstbewusst (Männlich)"
            case .italian: return "Maschile Profondo e Sicuro"
            case .portuguese: return "Masculino Firme e Confiante"
            case .japanese: return "重厚で落ち着いた男性声"
            case .chinese: return "深沉沉稳男声"
            case .korean: return "중후하고 차분한 남성"
            case .russian: return "Глубокий мужской голос"
            case .dutch: return "Diep & Zelfverzekerd Man"
            }
        case .sicakKadin:
            switch lang {
            case .english: return "Warm & Elegant Female"
            case .turkish: return "Sıcak & Zarif Kadın"
            case .spanish: return "Mujer Cálida y Elegante"
            case .french: return "Femme Chaleureuse et Élégante"
            case .german: return "Warm & Elegant (Weiblich)"
            case .italian: return "Femminile Caldo ed Elegante"
            case .portuguese: return "Feminino Caloroso e Elegante"
            case .japanese: return "温かみのある優雅な女性声"
            case .chinese: return "温婉优雅女声"
            case .korean: return "따뜻하고 우아한 여성"
            case .russian: return "Тёплый элегантный женский голос"
            case .dutch: return "Warm & Elegant Vrouw"
            }
        case .derinBariton:
            switch lang {
            case .english: return "Deep Baritone & Serene"
            case .turkish: return "Derin Bariton & Sakin"
            case .spanish: return "Barítono Profundo y Sereno"
            case .french: return "Baryton Profond et Serein"
            case .german: return "Tiefer Bariton & Gelassen"
            case .italian: return "Baritono Profondo e Calmo"
            case .portuguese: return "Barítono Profundo e Sereno"
            case .japanese: return "深みのあるバリトン"
            case .chinese: return "浑厚男低音"
            case .korean: return "깊은 바리톤과 평온함"
            case .russian: return "Глубокий спокойный баритон"
            case .dutch: return "Diepe Bariton & Rustig"
            }
        case .dinamikPartner:
            switch lang {
            case .english: return "Dynamic & Creative Partner"
            case .turkish: return "Dinamik & Yaratıcı Partner"
            case .spanish: return "Socio Dinámico y Creativo"
            case .french: return "Partenaire Dynamique et Créatif"
            case .german: return "Dynamisch & Kreativer Partner"
            case .italian: return "Partner Dinamico e Creativo"
            case .portuguese: return "Parceiro Dinâmico e Criativo"
            case .japanese: return "躍動的で創造的なパートナー"
            case .chinese: return "敏锐创意伙伴"
            case .korean: return "역동적이고 창의적인 파트너"
            case .russian: return "Динамичный творческий партнёр"
            case .dutch: return "Dynamisch & Creatieve Partner"
            }
        case .minimalistDirekt:
            switch lang {
            case .english: return "Modern & Minimalist"
            case .turkish: return "Modern & Minimalist"
            case .spanish: return "Moderno y Minimalista"
            case .french: return "Moderne et Minimaliste"
            case .german: return "Modern & Minimalistisch"
            case .italian: return "Moderno e Minimalista"
            case .portuguese: return "Moderno e Minimalista"
            case .japanese: return "洗練されたミニマリスト"
            case .chinese: return "现代简约原声"
            case .korean: return "모던 & 미니멀리스트"
            case .russian: return "Современный и лаконичный"
            case .dutch: return "Modern & Minimalistisch"
            }
        }
    }
    
    public static func voiceToneSampleText(_ tone: ErisVoiceTone) -> String {
        switch lang {
        case .english:
            switch tone {
            case .tokErkek: return "Hello, I am right here. Which fabrics and silhouettes are we focusing on today?"
            case .sicakKadin: return "Have an inspired day. Let's shape your new collection ideas together."
            case .derinBariton: return "Stay calm, everything is under control. Today's agenda is prepared."
            case .dinamikPartner: return "Let's begin right away! Supplier fabric prices and atelier appointments are ready."
            case .minimalistDirekt: return "Eris ready. Direct focus on today's goals."
            }
        case .turkish:
            return tone.sampleText
        case .spanish:
            switch tone {
            case .tokErkek: return "Hola, aquí estoy. ¿En qué telas y siluetas nos enfocamos hoy?"
            case .sicakKadin: return "Que tengas un gran día. Modelemos juntos las ideas de tu nueva colección."
            case .derinBariton: return "Mantén la calma, todo está bajo control. La agenda de hoy está lista."
            case .dinamikPartner: return "¡Empecemos ya! Los precios de proveedores y citas de taller están listos."
            case .minimalistDirekt: return "Eris lista. Enfoque directo en los objetivos de hoy."
            }
        case .french:
            switch tone {
            case .tokErkek: return "Bonjour, je suis là. Sur quels tissus et silhouettes nous concentrons-nous aujourd'hui ?"
            case .sicakKadin: return "Belle journée. Donnons forme ensemble à votre nouvelle collection."
            case .derinBariton: return "Restez serein, tout est sous contrôle. Votre agenda est prêt."
            case .dinamikPartner: return "Commençons sans attendre ! Les prix des fournisseurs et vos rendez-vous sont prêts."
            case .minimalistDirekt: return "Eris prête. Concentration immédiate sur les priorités du jour."
            }
        case .german:
            switch tone {
            case .tokErkek: return "Hallo, ich bin hier. Auf welche Stoffe und Silhouetten konzentrieren wir uns heute?"
            case .sicakKadin: return "Einen wunderbaren Tag. Lass uns deine neue Kollektion zusammen gestalten."
            case .derinBariton: return "Keine Sorge, alles ist unter Kontrolle. Dein Tagesplan ist bereit."
            case .dinamikPartner: return "Lass uns sofort starten! Stoffpreise und Atelier-Termine liegen vor."
            case .minimalistDirekt: return "Eris bereit. Direkter Fokus auf die heutigen Aufgaben."
            }
        case .italian:
            switch tone {
            case .tokErkek: return "Ciao, sono qui. Su quali tessuti e silhouette ci concentriamo oggi?"
            case .sicakKadin: return "Buona giornata. Diamo forma insieme alle idee della tua nuova collezione."
            case .derinBariton: return "Rilassati, è tutto sotto controllo. La tua agenda quotidiana è pronta."
            case .dinamikPartner: return "Iniziamo subito! I prezzi dei tessuti e gli appuntamenti in atelier sono pronti."
            case .minimalistDirekt: return "Eris pronta. Massima concentrazione sugli obiettivi di oggi."
            }
        case .portuguese:
            switch tone {
            case .tokErkek: return "Olá, estou aqui. Em quais tecidos e silhuetas vamos focar hoje?"
            case .sicakKadin: return "Tenha um ótimo dia. Vamos dar forma juntos às ideias da sua nova coleção."
            case .derinBariton: return "Mantenha a calma, tudo sob controle. Sua agenda do dia está pronta."
            case .dinamikPartner: return "Vamos começar agora! Preços de fornecedores e compromissos do ateliê estão prontos."
            case .minimalistDirekt: return "Eris pronta. Foco direto nas metas de hoje."
            }
        case .japanese:
            switch tone {
            case .tokErkek: return "こんにちは、待機しています。本日はどの生地とシルエットに注力しますか？"
            case .sicakKadin: return "素晴らしい一日にしましょう。新しいコレクションのアイデアを共に創り上げましょう。"
            case .derinBariton: return "ご安心ください、すべて順調です。本日の予定は整いました。"
            case .dinamikPartner: return "早速始めましょう！生地の仕入れ価格とアトリエの予定は確認済みです。"
            case .minimalistDirekt: return "Eris 準備完了。本日の重要課題に集中します。"
            }
        case .chinese:
            switch tone {
            case .tokErkek: return "你好，我已就绪。今天我们聚焦哪些面料和版型轮廓？"
            case .sicakKadin: return "祝你度过美好的一天。让我们共同构筑新一季系列的创意灵感。"
            case .derinBariton: return "沉着从容，一切皆在掌握。今天的日程已梳理完毕。"
            case .dinamikPartner: return "即刻出发！面料供应商报价与工坊日程已准备就绪。"
            case .minimalistDirekt: return "Eris 就绪。直奔今日核心事项。"
            }
        case .korean:
            switch tone {
            case .tokErkek: return "안녕하세요, 준비되었습니다. 오늘 어떤 원단과 실루엣에 집중할까요?"
            case .sicakKadin: return "좋은 하루 되세요. 새로운 컬렉션 아이디어를 함께 완성해 나가요."
            case .derinBariton: return "안심하세요, 모든 것이 준비되어 있습니다. 오늘의 일정을 마쳤습니다."
            case .dinamikPartner: return "바로 시작하죠! 원단 공급가와 아틀리에 일정이 준비되었습니다."
            case .minimalistDirekt: return "Eris 준비 완료. 오늘의 핵심 업무에 집중합니다."
            }
        case .russian:
            switch tone {
            case .tokErkek: return "Здравствуйте, я на связи. На каких тканях и силуэтах мы сосредоточимся сегодня?"
            case .sicakKadin: return "Прекрасного дня. Давайте вместе воплотим идеи вашей новой коллекции."
            case .derinBariton: return "Сохраняйте спокойствие, всё под контролем. Расписание на сегодня готово."
            case .dinamikPartner: return "Начнём прямо сейчас! Цены на ткани и встречи в ателье готовы."
            case .minimalistDirekt: return "Eris готова. Прямой фокус на задачах дня."
            }
        case .dutch:
            switch tone {
            case .tokErkek: return "Hallo, ik ben er. Op welke stoffen en silhouetten richten we ons vandaag?"
            case .sicakKadin: return "Een fijne dag. Laten we samen de ideeën voor je nieuwe collectie vormgeven."
            case .derinBariton: return "Blijf rustig, alles is onder controle. Je agenda voor vandaag staat klaar."
            case .dinamikPartner: return "Laten we meteen beginnen! De stofprijzen en atelier-afspraken zijn gereed."
            case .minimalistDirekt: return "Eris gereed. Directe focus op de taken van vandaag."
            }
        }
    }
    
    // MARK: - Custom Agents Localized Strings
    public static var customAgentsTitle: String {
        switch lang {
        case .english: return "Custom Agents"
        case .turkish: return "Özel Ajanlar"
        case .spanish: return "Agentes Personalizados"
        case .french: return "Agents Personnalisés"
        case .german: return "Eigene Agenten"
        case .italian: return "Agenti Personalizzati"
        case .portuguese: return "Agentes Personalizados"
        case .japanese: return "カスタムエージェント"
        case .chinese: return "自定义智能体"
        case .korean: return "맞춤형 에이전트"
        case .russian: return "Пользовательские Агенты"
        case .dutch: return "Aangepaste Agenten"
        }
    }
    
    public static var activeAgentLabel: String {
        switch lang {
        case .english: return "Active Agent"
        case .turkish: return "Aktif Ajan"
        case .spanish: return "Agente Activo"
        case .french: return "Agent Actif"
        case .german: return "Aktiver Agent"
        case .italian: return "Agente Attivo"
        case .portuguese: return "Agente Ativo"
        case .japanese: return "アクティブエージェント"
        case .chinese: return "当前智能体"
        case .korean: return "활성 에이전트"
        case .russian: return "Активный Агент"
        case .dutch: return "Actieve Agent"
        }
    }
    
    public static var createNewAgentLabel: String {
        switch lang {
        case .english: return "Create Custom Agent"
        case .turkish: return "Yeni Özel Ajan Yarat"
        case .spanish: return "Crear Agente Personalizado"
        case .french: return "Créer un Agent Personnalisé"
        case .german: return "Neuen Agenten Erstellen"
        case .italian: return "Crea Agente Personalizzato"
        case .portuguese: return "Criar Agente Personalizado"
        case .japanese: return "カスタムエージェントを作成"
        case .chinese: return "创建自定义智能体"
        case .korean: return "맞춤형 에이전트 만들기"
        case .russian: return "Создать Пользовательского Агента"
        case .dutch: return "Nieuwe Agent Aanmaken"
        }
    }
    
    public static var starterTemplatesLabel: String {
        switch lang {
        case .english: return "Starter Templates"
        case .turkish: return "Hazır Şablonlar"
        case .spanish: return "Plantillas de Inicio"
        case .french: return "Modèles de Départ"
        case .german: return "Startvorlagen"
        case .italian: return "Modelli Iniziali"
        case .portuguese: return "Modelos Iniciais"
        case .japanese: return "スターターテンプレート"
        case .chinese: return "预设模板"
        case .korean: return "시작 템플릿"
        case .russian: return "Готовые Шаблоны"
        case .dutch: return "Startsjablonen"
        }
    }
    
    // MARK: - Life OS Localized Keys
    public static var openLoopsTitle: String {
        switch lang {
        case .english: return "Open Loops"
        case .turkish: return "Açık Döngüler"
        case .spanish: return "Bucles Abiertos"
        case .french: return "Boucles Ouvertes"
        case .german: return "Offene Schleifen"
        case .italian: return "Cicli Aperti"
        case .portuguese: return "Loops Abertos"
        case .japanese: return "未完了ループ"
        case .chinese: return "未闭环任务"
        case .korean: return "미완료 루프"
        case .russian: return "Открытые циклы"
        case .dutch: return "Open Loops"
        }
    }
    
    public static var safetyGateTitle: String {
        switch lang {
        case .english: return "Safety Gate"
        case .turkish: return "Güvenlik Kapısı"
        case .spanish: return "Puerta de Seguridad"
        case .french: return "Porte de Sécurité"
        case .german: return "Sicherheits-Gate"
        case .italian: return "Porta di Sicurezza"
        case .portuguese: return "Portal de Segurança"
        case .japanese: return "安全ゲート"
        case .chinese: return "安全执行门"
        case .korean: return "안전 게이트"
        case .russian: return "Шлюз безопасности"
        case .dutch: return "Veiligheidspoort"
        }
    }
    
    public static var livingChecklistsTitle: String {
        switch lang {
        case .english: return "Living Checklists"
        case .turkish: return "Yaşayan Listeler"
        case .spanish: return "Listas Vivas"
        case .french: return "Listes Dynamiques"
        case .german: return "Lebendige Checklisten"
        case .italian: return "Liste Dinamiche"
        case .portuguese: return "Listas Vivas"
        case .japanese: return "ダイナミックチェックリスト"
        case .chinese: return "动态检查单"
        case .korean: return "살아있는 체크리스트"
        case .russian: return "Динамические списки"
        case .dutch: return "Dynamische Checklists"
        }
    }
    
    public static var commuteTrackerTitle: String {
        switch lang {
        case .english: return "Commute Tracker"
        case .turkish: return "Dinamik Rota"
        case .spanish: return "Rastreador de Ruta"
        case .french: return "Suivi de Trajet"
        case .german: return "Pendel-Tracker"
        case .italian: return "Tracciamento Percorso"
        case .portuguese: return "Rastreador de Rota"
        case .japanese: return "通勤ルート"
        case .chinese: return "通勤路线追踪"
        case .korean: return "출퇴근 경로"
        case .russian: return "Трекер маршрута"
        case .dutch: return "Reisplanner"
        }
    }
    
    public static var approveAndExecute: String {
        switch lang {
        case .english: return "Approve & Execute"
        case .turkish: return "Onayla & İcra Et"
        case .spanish: return "Aprobar y Ejecutar"
        case .french: return "Approuver et Exécuter"
        case .german: return "Genehmigen und Ausführen"
        case .italian: return "Approva ed Esegui"
        case .portuguese: return "Aprovar e Executar"
        case .japanese: return "承認して実行"
        case .chinese: return "批准并执行"
        case .korean: return "승인 및 실행"
        case .russian: return "Одобрить и выполнить"
        case .dutch: return "Goedkeuren en uitvoeren"
        }
    }
    
    public static var declineAction: String {
        switch lang {
        case .english: return "Decline"
        case .turkish: return "Reddet"
        case .spanish: return "Rechazar"
        case .french: return "Refuser"
        case .german: return "Ablehnen"
        case .italian: return "Rifiuta"
        case .portuguese: return "Recusar"
        case .japanese: return "拒否"
        case .chinese: return "拒绝"
        case .korean: return "거부"
        case .russian: return "Отклонить"
        case .dutch: return "Afwijzen"
        }
    }
    
    // MARK: - Onboarding & First-Run
    public static var onboardingWelcomeTitle: String {
        switch lang {
        case .english: return "Welcome to ERIS"
        case .turkish: return "ERIS'e Hoş Geldiniz"
        case .spanish: return "Bienvenido a ERIS"
        case .french: return "Bienvenue sur ERIS"
        case .german: return "Willkommen bei ERIS"
        case .italian: return "Benvenuto in ERIS"
        case .portuguese: return "Bem-vindo ao ERIS"
        case .japanese: return "ERISへようこそ"
        case .chinese: return "欢迎使用 ERIS"
        case .korean: return "ERIS에 오신 것을 환영합니다"
        case .russian: return "Добро пожаловать в ERIS"
        case .dutch: return "Welkom bij ERIS"
        }
    }
    
    public static var onboardingWelcomeSubtitle: String {
        switch lang {
        case .english: return "Your proactive Personal Life OS. Managing your daily flow, open loops, living checklists, and decisions."
        case .turkish: return "Kişisel Yaşam İşletim Sisteminiz. Günlük akışınızı, açık döngülerinizi, yaşayan listelerinizi ve kararlarınızı proaktif yönetir."
        case .spanish: return "Tu sistema operativo de vida personal proactivo. Gestiona tu flujo diario, tareas pendientes y listas vivas."
        case .french: return "Votre OS de vie personnelle proactif. Gère votre flux quotidien, vos boucles ouvertes et vos listes dynamiques."
        case .german: return "Ihr proaktives Personal Life OS. Verwaltet Ihren Tagesablauf, offene Aufgaben und lebendige Checklisten."
        case .italian: return "Il tuo Life OS personale proattivo. Gestisce la tua giornata, i cicli aperti e le liste dinamiche."
        case .portuguese: return "Seu sistema operacional de vida pessoal proativo. Gerencia seu fluxo diário, loops abertos e listas vivas."
        case .japanese: return "プロアクティブなパーソナルLife OS。日常の流れ、未完了ループ、ダイナミックリストを管理します。"
        case .chinese: return "您的全能个人生活操作系统。主动管理您的每日流程、未闭环任务与动态检查单。"
        case .korean: return "능동형 개인 라이프 OS. 일상 흐름, 미완료 루프, 살아있는 체크리스트를 체계적으로 관리합니다."
        case .russian: return "Ваша проактивная операционная система жизни. Управляет ежедневным потоком, открытыми циклами и списками."
        case .dutch: return "Uw proactieve Personal Life OS. Beheert uw dagelijkse flow, open loops en dynamische checklists."
        }
    }
    
    public static var continueText: String {
        switch lang {
        case .english: return "Continue"
        case .turkish: return "Devam Et"
        case .spanish: return "Continuar"
        case .french: return "Continuer"
        case .german: return "Weiter"
        case .italian: return "Continua"
        case .portuguese: return "Continuar"
        case .japanese: return "次へ"
        case .chinese: return "继续"
        case .korean: return "계속"
        case .russian: return "Продолжить"
        case .dutch: return "Doorgaan"
        }
    }
    
    public static var getStartedText: String {
        switch lang {
        case .english: return "Get Started"
        case .turkish: return "Tamamla ve Başla"
        case .spanish: return "Comenzar"
        case .french: return "Commencer"
        case .german: return "Loslegen"
        case .italian: return "Inizia"
        case .portuguese: return "Começar"
        case .japanese: return "始める"
        case .chinese: return "开始使用"
        case .korean: return "시작하기"
        case .russian: return "Начать"
        case .dutch: return "Aan de slag"
        }
    }
    
    // MARK: - Quick Actions & Prompts
    public static var quickActions: String {
        switch lang {
        case .english: return "Quick Actions"
        case .turkish: return "Hızlı Eylemler"
        case .spanish: return "Acciones Rápidas"
        case .french: return "Actions Rapides"
        case .german: return "Schnellaktionen"
        case .italian: return "Azioni Rapide"
        case .portuguese: return "Ações Rápidas"
        case .japanese: return "クイックアクション"
        case .chinese: return "快捷操作"
        case .korean: return "빠른 작업"
        case .russian: return "Быстрые действия"
        case .dutch: return "Snelle Acties"
        }
    }
    
    public static var howCanIHelp: String {
        switch lang {
        case .english: return "How can I assist you today?"
        case .turkish: return "Bugün size nasıl yardımcı olabilirim?"
        case .spanish: return "¿Cómo puedo ayudarte hoy?"
        case .french: return "Comment puis-je vous aider aujourd'hui ?"
        case .german: return "Wie kann ich Ihnen heute helfen?"
        case .italian: return "Come posso aiutarti oggi?"
        case .portuguese: return "Como posso ajudar você hoje?"
        case .japanese: return "本日はどのようなご用件でしょうか？"
        case .chinese: return "今天有什么可以帮您的？"
        case .korean: return "오늘 어떤 도움이 필요하신가요?"
        case .russian: return "Чем я могу вам помочь сегодня?"
        case .dutch: return "Hoe kan ik u vandaag helpen?"
        }
    }
    
    public static var morningBriefingTitle: String {
        switch lang {
        case .english: return "Morning Briefing"
        case .turkish: return "Sabah Brifingi"
        case .spanish: return "Informe Matutino"
        case .french: return "Briefing Matinal"
        case .german: return "Morgen-Briefing"
        case .italian: return "Briefing Mattutino"
        case .portuguese: return "Briefing Matinal"
        case .japanese: return "モーニングブリーフィング"
        case .chinese: return "早间简报"
        case .korean: return "모닝 브리핑"
        case .russian: return "Утренний брифинг"
        case .dutch: return "Ochtendbriefing"
        }
    }
    
    public static var morningBriefingSubtitle: String {
        switch lang {
        case .english: return "Plan of the day, calendar & weather"
        case .turkish: return "Günün planı, takvim ve hava durumu"
        case .spanish: return "Plan del día, agenda y clima"
        case .french: return "Programme du jour, agenda et météo"
        case .german: return "Tagesplan, Kalender und Wetter"
        case .italian: return "Programma del giorno, calendario e meteo"
        case .portuguese: return "Plano do dia, calendário e clima"
        case .japanese: return "本日の予定、カレンダー、天気"
        case .chinese: return "今日计划、日历和天气"
        case .korean: return "오늘의 계획, 캘린더 및 날씨"
        case .russian: return "План на день, календарь и погода"
        case .dutch: return "Dagplanning, agenda en weer"
        }
    }
    
    public static var quickNoteTitle: String {
        switch lang {
        case .english: return "Quick Note & Vault"
        case .turkish: return "Hızlı Not & Kasa"
        case .spanish: return "Nota Rápida y Bóveda"
        case .french: return "Note Rapide & Coffre"
        case .german: return "Schnelle Notiz & Tresor"
        case .italian: return "Nota Rapida & Cassaforte"
        case .portuguese: return "Nota Rápida e Cofre"
        case .japanese: return "クイックメモと保管庫"
        case .chinese: return "快捷便签与保险库"
        case .korean: return "빠른 메모 및 금고"
        case .russian: return "Быстрая заметка и хранилище"
        case .dutch: return "Snelle Notitie & Kluis"
        }
    }
    
    public static var quickNoteSubtitle: String {
        switch lang {
        case .english: return "Save ideas, knowledge or expenses"
        case .turkish: return "Düşünce, bilgi veya harcama kaydet"
        case .spanish: return "Guarda ideas, datos o gastos"
        case .french: return "Enregistrer idées, infos ou dépenses"
        case .german: return "Ideen, Wissen oder Ausgaben sichern"
        case .italian: return "Salva idee, informazioni o spese"
        case .portuguese: return "Salve ideias, dados ou despesas"
        case .japanese: return "アイデア、情報、支出を記録"
        case .chinese: return "记录想法、知识或支出"
        case .korean: return "아이디어, 지식 또는 지출 기록"
        case .russian: return "Сохранить мысли, знания или расходы"
        case .dutch: return "Ideeën, info of uitgaven opslaan"
        }
    }
    
    public static var openLoopsSubtitle: String {
        switch lang {
        case .english: return "Track pending and unfinished tasks"
        case .turkish: return "Askıda kalan işleri takip et"
        case .spanish: return "Revisa tareas pendientes y en curso"
        case .french: return "Suivre les tâches en suspens"
        case .german: return "Ausstehende Aufgaben überwachen"
        case .italian: return "Tieni traccia delle attività in sospeso"
        case .portuguese: return "Acompanhe tarefas pendentes"
        case .japanese: return "保留中のタスクを確認"
        case .chinese: return "追踪待处理与未完结任务"
        case .korean: return "보류 중인 작업 추적"
        case .russian: return "Отслеживание незавершенных дел"
        case .dutch: return "Volg openstaande taken"
        }
    }
    
    public static var livingListsTitle: String {
        switch lang {
        case .english: return "Living Lists"
        case .turkish: return "Yaşayan Listeler"
        case .spanish: return "Listas Vivas"
        case .french: return "Listes Dynamiques"
        case .german: return "Dynamische Listen"
        case .italian: return "Liste Dinamiche"
        case .portuguese: return "Listas Vivas"
        case .japanese: return "動的チェックリスト"
        case .chinese: return "动态清单"
        case .korean: return "동적 체크리스트"
        case .russian: return "Динамические списки"
        case .dutch: return "Dynamische Lijsten"
        }
    }
    
    public static var livingListsSubtitle: String {
        switch lang {
        case .english: return "Groceries, packing & routines"
        case .turkish: return "Market, bavul ve ev rutinleri"
        case .spanish: return "Supermercado, equipaje y rutinas"
        case .french: return "Courses, valise et routines"
        case .german: return "Einkauf, Koffer und Routinen"
        case .italian: return "Spesa, valigia e routine di casa"
        case .portuguese: return "Mercado, malas e rotinas"
        case .japanese: return "買い物、荷造り、日課"
        case .chinese: return "购物、行李与生活例程"
        case .korean: return "장보기, 짐 싸기 및 일상 루틴"
        case .russian: return "Покупки, сборы и рутина"
        case .dutch: return "Boodschappen, bagage en routines"
        }
    }
    
    public static var habitsGoalsTitle: String {
        switch lang {
        case .english: return "Habits & Focus"
        case .turkish: return "Alışkanlıklar"
        case .spanish: return "Hábitos y Enfoque"
        case .french: return "Habitudes & Objectifs"
        case .german: return "Gewohnheiten & Fokus"
        case .italian: return "Abitudini & Focus"
        case .portuguese: return "Hábitos e Foco"
        case .japanese: return "習慣と集中"
        case .chinese: return "习惯与专注"
        case .korean: return "습관 및 집중"
        case .russian: return "Привычки и фокус"
        case .dutch: return "Gewoontes & Focus"
        }
    }
    
    public static var habitsGoalsSubtitle: String {
        switch lang {
        case .english: return "Daily targets and streaks"
        case .turkish: return "Günlük hedefler ve ilerleme"
        case .spanish: return "Metas diarias y constancia"
        case .french: return "Objectifs quotidiens et séries"
        case .german: return "Tagesziele und Serie"
        case .italian: return "Obiettivi giornalieri e costanza"
        case .portuguese: return "Metas diárias e sequências"
        case .japanese: return "毎日の目標と継続記録"
        case .chinese: return "每日目标与连续天数"
        case .korean: return "일일 목표 및 연속 기록"
        case .russian: return "Ежедневные цели и серии"
        case .dutch: return "Dagelijkse doelen en reeksen"
        }
    }
    
    public static var promptPlanToday: String {
        switch lang {
        case .english: return "What are our plans for today?"
        case .turkish: return "Bugünkü planlarımız nedir?"
        default: return "What are our plans for today?"
        }
    }
    
    public static var promptListOpenLoops: String {
        switch lang {
        case .english: return "Summarize my open loops and pending tasks"
        case .turkish: return "Askıda kalan açık işlerimi özetle"
        default: return "Summarize my open loops"
        }
    }
    
    public static var promptShowGrocery: String {
        switch lang {
        case .english: return "What is missing from my market & pantry list?"
        case .turkish: return "Market ve kiler listemde ne eksik?"
        default: return "Show my grocery list"
        }
    }
    
    public static var promptCheckHabits: String {
        switch lang {
        case .english: return "Check my daily habits and milestones"
        case .turkish: return "Bugünkü alışkanlıklarımı ve hedeflerimi kontrol et"
        default: return "Check my daily habits"
        }
    }
    
    public static var promptWeatherMarine: String {
        switch lang {
        case .english: return "What are the weather and sea conditions?"
        case .turkish: return "Hava durumu ve deniz koşulları nasıl?"
        default: return "What is the weather?"
        }
    }
    
    public static var promptTakeNote: String {
        switch lang {
        case .english: return "Add a new note to my memory vault"
        case .turkish: return "Kayıtlı hafızamdaki önemli bilgileri özetle"
        default: return "Summarize my memories"
        }
    }
    
    public static var tapToSpeak: String {
        switch lang {
        case .english: return "Tap to speak"
        case .turkish: return "Konuşmak için dokunun"
        default: return "Tap to speak"
        }
    }
    
    public static var tapToStop: String {
        switch lang {
        case .english: return "Listening... Tap to send"
        case .turkish: return "Dinleniyor... Bitirmek için dokunun"
        default: return "Listening..."
        }
    }
    
    public static var askErisPlaceholder: String {
        switch lang {
        case .english: return "Instruct Eris (e.g. 'Add meeting at 3pm')..."
        case .turkish: return "Eris'e talimat ver (Örn: 'Saat 15:00 toplantı ekle')..."
        default: return "Instruct Eris..."
        }
    }
    
    public static var backText: String {
        switch lang {
        case .english: return "Back"
        case .turkish: return "Geri"
        case .spanish: return "Atrás"
        case .french: return "Retour"
        case .german: return "Zurück"
        case .italian: return "Indietro"
        case .portuguese: return "Voltar"
        case .japanese: return "戻る"
        case .chinese: return "返回"
        case .korean: return "뒤로"
        case .russian: return "Назад"
        case .dutch: return "Terug"
        }
    }
}


