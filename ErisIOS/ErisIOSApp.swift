import SwiftUI
import ErisCore

@main
struct ErisIOSApp: App {
    @StateObject private var appState = ErisIOSState()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                IOSMainView()
                    .environmentObject(appState)
                    .sheet(isPresented: $appState.showOnboarding) {
                        OnboardingView(isPresented: $appState.showOnboarding)
                    }
            }
            .preferredColorScheme(.dark)
        }
    }
}

public enum IOSTab: String, CaseIterable, Identifiable {
    case chat = "chat"
    case widgets = "widgets"
    case checklists = "checklists"
    case memory = "memory"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .chat: return L10n.tabChat
        case .widgets: return L10n.tabWidgets
        case .checklists: return L10n.tabChecklists
        case .memory: return L10n.tabMemory
        case .settings: return L10n.tabSettings
        }
    }
    
    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .widgets: return "square.grid.2x2.fill"
        case .checklists: return "checklist.checked"
        case .memory: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
final class ErisIOSState: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var isThinking: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var pendingApproval: PendingAction? = nil
    @Published var showOnboarding: Bool = false
    @Published var selectedTab: IOSTab = .chat
    
    @Published var memories: [ErisMemoryRecord] = []
    @Published var selectedModel: GeminiModelChoice = .flash
    @Published var selectedVoiceTone: ErisVoiceTone = ErisSpeaker.shared.selectedTone {
        didSet {
            ErisSpeaker.shared.selectedTone = selectedVoiceTone
        }
    }
    @Published var marineInfo = ExternalDataService.shared.getMarineWeather()
    @Published var marketItems = ExternalDataService.shared.getMarketSummary()
    @Published var wakeWordEnabled: Bool = true
    
    init() {
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
        self.messages.append(
            Message(role: .assistant, content: "Eris hazır. Dinliyorum.")
        )
        setupVoiceCallbacks()
        
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            self.showOnboarding = true
        }
        
        if let tabName = UserDefaults.standard.string(forKey: "initialTab") {
            if let tab = IOSTab(rawValue: tabName) {
                self.selectedTab = tab
            } else if tabName == "Sohbet" {
                self.selectedTab = .chat
            } else if tabName == "Widget'lar" {
                self.selectedTab = .widgets
            } else if tabName == "Listeler" {
                self.selectedTab = .checklists
            } else if tabName == "Notlar & Dosyalar" {
                self.selectedTab = .memory
            } else if tabName == "Ayarlar" {
                self.selectedTab = .settings
            }
        }
        
        ErisLanguageManager.shared.onLanguageChanged = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.objectWillChange.send()
            }
        }
        
        if UserDefaults.standard.bool(forKey: "sampleDataForScreenshots") {
            self.messages = [
                Message(role: .user, content: "Hey Eris, bugünkü planlarımız nedir?"),
                Message(role: .assistant, content: "Günaydın. Bugün saat 11:00'de Nişantaşı atölyesinde drapaj ve kumaş incelemen, 14:30'da İpek tedarikçisi görüşmen var. Hava 21°C ve açık."),
                Message(role: .user, content: "Kumaş fiyat defterinde ipek şifon kaça kayıtlıydı?"),
                Message(role: .assistant, content: "Osmanbey İpekçisi'nden metresi 18$ olarak kayıtlı. Dökümlü ve hafif kumaş, yaz koleksiyonu için uygun.")
            ]
        }
        
        ErisSyncService.shared.pullFromCloud()
        ErisSyncService.shared.onSyncUpdated = { [weak self] in
            Task { @MainActor [weak self] in
                self?.memories = ErisMemoryDatabase.shared.getAllMemories()
            }
        }
    }
    
    private func setupVoiceCallbacks() {
        ErisSpeaker.shared.onSpeakingStarted = { [weak self] in
            Task { @MainActor [weak self] in self?.isSpeaking = true }
        }
        ErisSpeaker.shared.onSpeakingFinished = { [weak self] in
            Task { @MainActor [weak self] in self?.isSpeaking = false }
        }
        
        ErisVoiceListener.shared.onAudioLevel = { [weak self] level in
            Task { @MainActor [weak self] in self?.audioLevel = level }
        }
        
        // Barge-in: Kullanıcı konuştuğunda konuşma sesi susar
        ErisVoiceListener.shared.onBargeInTriggered = { [weak self] in
            Task { @MainActor [weak self] in
                if self?.isSpeaking == true {
                    self?.isSpeaking = false
                }
            }
        }
        
        ErisVoiceListener.shared.onWakeWordDetected = { [weak self] in
            Task { @MainActor [weak self] in
                self?.handleWakeWord()
            }
        }
        
        ErisVoiceListener.shared.onFinalTranscription = { [weak self] transcript in
            Task { @MainActor [weak self] in
                if !transcript.isEmpty {
                    self?.sendUserMessage(transcript)
                }
            }
        }
    }
    
    func startListening() {
        ErisSpeaker.shared.stopSpeaking()
        isSpeaking = false
        do {
            try ErisVoiceListener.shared.startListening()
            isListening = true
        } catch {
            print("Dinleme başlatılamadı: \(error)")
        }
    }
    
    func stopListening() {
        ErisVoiceListener.shared.stopListening()
        isListening = false
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func handleWakeWord() {
        guard wakeWordEnabled else { return }
        ErisSpeaker.shared.stopSpeaking()
        isSpeaking = false
        if !isListening {
            startListening()
        }
    }
    
    func playMorningBriefing() {
        let briefing = MorningBriefingService.shared.generateBriefingText()
        messages.append(Message(role: .assistant, content: briefing))
        ErisSpeaker.shared.speak(briefing, tone: self.selectedVoiceTone)
    }
    
    func addMemory(
        title: String? = nil,
        content: String,
        category: MemoryCategory = .preference,
        tags: [String] = [],
        source: String = "manual",
        fileName: String? = nil,
        pinned: Bool = true
    ) {
        let record = ErisMemoryRecord(
            category: category,
            title: title,
            content: content,
            tags: tags,
            source: source,
            fileName: fileName,
            pinned: pinned
        )
        ErisMemoryDatabase.shared.saveMemory(record)
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
        ErisSyncService.shared.pushToCloud()
    }
    
    func togglePin(id: String) {
        ErisMemoryDatabase.shared.togglePin(id: id)
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
    }
    
    func updateMemory(id: String, title: String?, content: String, category: MemoryCategory, tags: [String], fileName: String?) {
        ErisMemoryDatabase.shared.updateMemory(
            id: id,
            title: title,
            content: content,
            category: category,
            tags: tags,
            fileName: fileName
        )
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
        ErisSyncService.shared.pushToCloud()
    }
    
    func deleteMemory(id: String) {
        ErisMemoryDatabase.shared.deleteMemory(id: id)
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
        ErisSyncService.shared.pushToCloud()
    }
    
    func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let (isSafe, reason) = GuardrailFilter.validateInput(trimmed)
        guard isSafe else {
            messages.append(Message(role: .user, content: trimmed))
            messages.append(Message(role: .assistant, content: reason ?? "Güvenlik kuralı ihlali."))
            return
        }
        
        let lower = trimmed.lowercased()
        
        let isVoice = isListening
        let lifeOSAction = ErisLifeOSEngine.shared.processIncomingMessage(trimmed, isVoice: isVoice)
        switch lifeOSAction {
        case .morningBriefing:
            messages.append(Message(role: .user, content: trimmed))
            inputText = ""
            playMorningBriefing()
            return
            
        case .openLoopsSummary(let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            inputText = ""
            messages.append(Message(role: .assistant, content: reply))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .livingChecklistsSummary(let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            inputText = ""
            messages.append(Message(role: .assistant, content: reply))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .pantryAndMeals(let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            inputText = ""
            messages.append(Message(role: .assistant, content: reply))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .decisionMatrix(_, let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            inputText = ""
            messages.append(Message(role: .assistant, content: reply))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .multiStepPlan(let plan, let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            inputText = ""
            for loopTitle in plan.openLoopsToCreate {
                ErisOpenLoopsEngine.shared.addLoop(OpenLoopItem(domain: .tasksOpenLoops, title: loopTitle, detectedSource: "chat"))
            }
            messages.append(Message(role: .assistant, content: reply, plan: plan))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .extractedNote(let extracted):
            let userMsg = Message(role: .user, content: trimmed)
            messages.append(userMsg)
            inputText = ""
            
            let payload: [String: String] = [
                "title": extracted.title,
                "content": extracted.content,
                "category": extracted.category.rawValue,
                "tags": extracted.tags.joined(separator: ","),
                "fileName": extracted.suggestedFileName,
                "source": isVoice ? "voice" : "chat"
            ]
            let payloadData = (try? JSONSerialization.data(withJSONObject: payload)) ?? Data()
            let payloadStr = String(data: payloadData, encoding: .utf8) ?? ""
            
            self.pendingApproval = PendingAction(
                actionType: .pinMemory,
                summary: "[\(extracted.category.displayName)] \(extracted.title)",
                payloadJson: payloadStr
            )
            
            let channelDesc = isVoice ? "🎙️ Sesli ifadenizden" : "💬 Mesajınızdan"
            let confirmMsg = "\(channelDesc) önemli bir bilgi tespit edildi: '\(extracted.title)'. [\(extracted.category.displayName)] olarak Notlar & Dosyalar kasasına kaydedilsin mi?"
            messages.append(Message(role: .assistant, content: confirmMsg))
            ErisSpeaker.shared.speak("Önemli bilgi tespit ettim: \(extracted.title). Notlar kasanıza kaydedilsin mi?", tone: self.selectedVoiceTone)
            return
            
        case .calendarEvent(let title, let start, let end, let dateStr):
            let userMsg = Message(role: .user, content: trimmed)
            messages.append(userMsg)
            inputText = ""
            
            self.pendingApproval = PendingAction(
                actionType: .calendarWrite,
                summary: "\(title) — Tarih: \(dateStr)",
                payloadJson: "{\"title\": \"\(title)\", \"start\": \(start.timeIntervalSince1970), \"end\": \(end.timeIntervalSince1970)}"
            )
            messages.append(Message(role: .assistant, content: "Takvim kaydı hazır (\(title), \(dateStr)). Onaylıyor musun?"))
            ErisSpeaker.shared.speak("Takvim kaydını hazırladım. Onaylıyor musun?", tone: self.selectedVoiceTone)
            return
            
        case .memoriesList, .none:
            break
        }
        
        // Genel Notları & Hafızayı Sorgulama / Listeleme
        if (lower.contains("notlar") || lower.contains("dosyalar") || lower.contains("hafıza") || lower.contains("notum") || lower.contains("notlarım") || lower.contains("notes") || lower.contains("files") || lower.contains("kumaş fiyat") || lower.contains("tedarikçi")) && (lower.contains("listele") || lower.contains("neler") || lower.contains("nedir") || lower.contains("dök") || lower.contains("say") || lower.contains("göster") || lower.contains("oku") || lower.contains("özetle") || lower.contains("show") || lower.contains("list")) {
            let allMemories = ErisMemoryDatabase.shared.getAllMemories()
            let userMsg = Message(role: .user, content: trimmed)
            messages.append(userMsg)
            inputText = ""
            
            if allMemories.isEmpty {
                let reply = "Henüz kayıtlı bir notun veya dosyan yok. Konuşurken fiyatlar, sözleşmeler veya teknik detaylar söylediğinde bunları otomatik olarak 'Notlar & Dosyalar' kasana organize edebilirim."
                messages.append(Message(role: .assistant, content: reply))
                ErisSpeaker.shared.speak("Henüz kayıtlı bir notun yok. Dilediğinde söyle, hemen organize edip kaydedeyim.", tone: self.selectedVoiceTone)
            } else {
                var reply = "Notlar & Dosyalar Kasandaki Kayıtlar:\n\n"
                for (idx, item) in allMemories.prefix(8).enumerated() {
                    let tagsStr = item.tags.isEmpty ? "" : " [\(item.tags.joined(separator: " "))]"
                    reply += "\(idx + 1). [\(item.category.displayName)] **\(item.title)**: \(item.content)\(tagsStr)\n"
                }
                if allMemories.count > 8 {
                    reply += "\n... ve \(allMemories.count - 8) kayıt daha Notlar & Dosyalar sekmesinde arşivli."
                }
                messages.append(Message(role: .assistant, content: reply))
                ErisSpeaker.shared.speak("Kasanızdaki kayıtları ekrana listeledim.", tone: self.selectedVoiceTone)
            }
            return
        }
        
        let userMsg = Message(role: .user, content: trimmed)
        messages.append(userMsg)
        inputText = ""
        isThinking = true
        
        ErisSpeaker.shared.stopSpeaking()
        isSpeaking = false
        
        Task {
            do {
                GeminiClient.shared.selectedModel = self.selectedModel
                let reply = try await GeminiClient.shared.generateContent(prompt: trimmed, conversationHistory: self.messages)
                self.messages.append(Message(role: .assistant, content: reply))
                self.isThinking = false
                
                ErisSpeaker.shared.speak(reply, tone: self.selectedVoiceTone)
            } catch {
                self.messages.append(Message(role: .assistant, content: "Hata: \(error.localizedDescription)"))
                self.isThinking = false
            }
        }
    }
    
    func approvePendingAction() {
        guard var action = pendingApproval else { return }
        let token = ApprovalToken()
        action.approvalToken = token
        
        if action.actionType == .pinMemory {
            var title = "Not"
            var content = action.summary
            var cat: MemoryCategory = .preference
            var tags: [String] = []
            var source = "chat"
            var fileName: String? = nil
            
            if let data = action.payloadJson.data(using: .utf8),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
                title = dict["title"] ?? title
                content = dict["content"] ?? content
                if let rawCat = dict["category"], let parsedCat = MemoryCategory(rawValue: rawCat) {
                    cat = parsedCat
                }
                if let tStr = dict["tags"] {
                    tags = tStr.components(separatedBy: ",").filter { !$0.isEmpty }
                }
                source = dict["source"] ?? "chat"
                fileName = dict["fileName"]
            } else {
                content = action.summary
            }
            
            addMemory(
                title: title,
                content: content,
                category: cat,
                tags: tags,
                source: source,
                fileName: fileName,
                pinned: true
            )
            messages.append(Message(role: .assistant, content: "Onaylandı. '\(title)' Notlar & Dosyalar kasana kaydedildi."))
            ErisSpeaker.shared.speak("Onaylandı. Bilgi kasanıza eklendi.", tone: self.selectedVoiceTone)
        } else if action.actionType == .calendarWrite {
            _ = try? CalendarCapability.shared.createEvent(
                title: action.summary,
                start: Date().addingTimeInterval(3600),
                end: Date().addingTimeInterval(7200)
            )
            messages.append(Message(role: .assistant, content: "Onaylandı. Ajandana ekledim: \(action.summary)"))
            ErisSpeaker.shared.speak("Onaylandı. Ajandana ekledim.", tone: self.selectedVoiceTone)
        }
        pendingApproval = nil
    }
    
    func rejectPendingAction() {
        pendingApproval = nil
        messages.append(Message(role: .assistant, content: "Eylem iptal edildi."))
        ErisSpeaker.shared.speak("İptal edildi.")
    }
}

// Ana Görünüm: Bottom Sheet / Tab Navigasyonu ile Chat, Hafıza ve Ayarlar
struct IOSMainView: View {
    @EnvironmentObject var appState: ErisIOSState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appState.selectedTab {
                case .chat:
                    IOSChatView()
                case .widgets:
                    IOSWidgetsDashboardView()
                case .checklists:
                    IOSChecklistsView()
                case .memory:
                    IOSMemoryView()
                case .settings:
                    IOSSettingsContentView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Sheet Glassmorphism Tab Bar
            IOSBottomTabBar(selectedTab: $appState.selectedTab)
        }
        .background(ErisTheme.graphite.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .font(.subheadline)
                    Text("ERIS")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    ErisStatusBadgeView(
                        isListening: appState.isListening,
                        isThinking: appState.isThinking,
                        isSpeaking: appState.isSpeaking
                    )
                }
            }
        }
    }
}

// Glassmorphism Alt Sekme Barı
struct IOSBottomTabBar: View {
    @Binding var selectedTab: IOSTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(IOSTab.allCases) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                        
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                            .foregroundColor(selectedTab == tab ? ErisTheme.coldWhite : ErisTheme.coldGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}


