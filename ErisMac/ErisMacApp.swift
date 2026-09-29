import SwiftUI
import ErisCore
import Combine
import AppKit

@main
struct ErisMacApp: App {
    @StateObject private var appState = ErisMacState()
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .frame(
                    minWidth: appState.isCompactMode ? 380 : 960,
                    maxWidth: appState.isCompactMode ? 420 : .infinity,
                    minHeight: appState.isCompactMode ? 520 : 640,
                    maxHeight: appState.isCompactMode ? 560 : .infinity
                )
                .background(.ultraThinMaterial)
                .sheet(isPresented: $appState.showOnboarding) {
                    OnboardingView(isPresented: $appState.showOnboarding)
                }
                .onAppear {
                    appState.setupGlobalShortcuts()
                }
        }
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "shield.lefthalf.filled")
                if appState.isListening || appState.isSpeaking {
                    Circle()
                        .fill(appState.isListening ? ErisTheme.listeningGreen : ErisTheme.bronzeHighlight)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

@MainActor
final class ErisMacState: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var isThinking: Bool = false
    @Published var audioLevel: Float = 0.0
    @Published var pendingApproval: PendingAction? = nil
    @Published var showOnboarding: Bool = false
    
    // Faz 2 Tasarım & Panel Modu
    @Published var isCompactMode: Bool = false
    @Published var isAlwaysOnTop: Bool = false
    
    // Hafıza ve Brifing
    @Published var memories: [ErisMemoryRecord] = []
    @Published var marketItems: [MarketItem] = []
    @Published var marineInfo: MarineWeatherInfo = ExternalDataService.shared.getMarineWeather()
    @Published var selectedModel: GeminiModelChoice = .flash2
    @Published var selectedVoiceTone: ErisVoiceTone = ErisSpeaker.shared.selectedTone {
        didSet {
            ErisSpeaker.shared.selectedTone = selectedVoiceTone
        }
    }
    @Published var wakeWordEnabled: Bool = true
    
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?
    
    init() {
        self.marketItems = ExternalDataService.shared.getMarketSummary()
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
        self.messages.append(
            Message(role: .assistant, content: "Eris hazır. Dinliyorum.")
        )
        setupVoiceCallbacks()
        
        // İlk açılış kontrolü (İlk kez açılıyorsa Onboarding aç)
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            self.showOnboarding = true
        }
        
        // Sabah Brifingi ve iCloud senkronizasyonunu başlat
        MorningBriefingService.shared.scheduleDailyBriefing()
        ErisSyncService.shared.pullFromCloud()
        ErisSyncService.shared.onSyncUpdated = { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshMemories()
            }
        }
        
        // Arka planda canlı hava ve piyasa verilerini çek
        Task { [weak self] in
            let liveMarine = await ExternalDataService.shared.fetchLiveMarineWeather()
            let liveMarket = await ExternalDataService.shared.fetchLiveMarketSummary()
            await MainActor.run {
                self?.marineInfo = liveMarine
                self?.marketItems = liveMarket
            }
        }
    }
    
    func setupGlobalShortcuts() {
        // macOS: Cmd+Shift+E kısayolu (Key code 14 = 'E') & Cmd+N kısayolu (Key code 45 = 'N')
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                self?.toggleListening()
                return nil
            } else if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && event.keyCode == 45 {
                self?.clearChat()
                return nil
            }
            return event
        }
        
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 14 {
                Task { @MainActor [weak self] in
                    NSApp.activate(ignoringOtherApps: true)
                    self?.toggleListening()
                }
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
        
        // Barge-in tetiklendiğinde hoparlör durumu sıfırlanır
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
    
    func toggleListening() {
        if isListening {
            ErisVoiceListener.shared.stopListening()
            isListening = false
        } else {
            ErisSpeaker.shared.stopSpeaking()
            isSpeaking = false
            
            do {
                try ErisVoiceListener.shared.startListening()
                isListening = true
            } catch {
                print("Dinleme başlatılamadı: \(error)")
            }
        }
    }
    
    func handleWakeWord() {
        guard wakeWordEnabled else { return }
        ErisSpeaker.shared.stopSpeaking()
        isSpeaking = false
        NSSound.beep()
        
        // Wake Word algılandığında uygulamayı öne getir
        NSApp.activate(ignoringOtherApps: true)
        if !isListening {
            try? ErisVoiceListener.shared.startListening()
            isListening = true
        }
    }
    
    func toggleCompactMode() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isCompactMode.toggle()
        }
    }
    
    func toggleAlwaysOnTop() {
        isAlwaysOnTop.toggle()
        if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.canBecomeMain }) ?? NSApp.windows.first {
            window.level = isAlwaysOnTop ? .floating : .normal
        }
    }
    
    func clearChat() {
        withAnimation(.easeInOut(duration: 0.25)) {
            messages = [Message(role: .assistant, content: "Eris hazır. Dinliyorum.")]
            pendingApproval = nil
            inputText = ""
        }
    }
    
    func refreshMemories() {
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
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
        refreshMemories()
        ErisSyncService.shared.pushToCloud()
    }
    
    func togglePin(id: String) {
        ErisMemoryDatabase.shared.togglePin(id: id)
        refreshMemories()
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
        refreshMemories()
        ErisSyncService.shared.pushToCloud()
    }
    
    func deleteMemory(id: String) {
        ErisMemoryDatabase.shared.deleteMemory(id: id)
        refreshMemories()
        ErisSyncService.shared.pushToCloud()
    }
    
    func playMorningBriefing() {
        let briefing = MorningBriefingService.shared.generateBriefingText()
        messages.append(Message(role: .assistant, content: briefing))
        ErisSpeaker.shared.speak(briefing, tone: self.selectedVoiceTone)
    }
    
    func sendUserMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""
        
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
            playMorningBriefing()
            return
            
        case .openLoopsSummary(let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            messages.append(Message(role: .assistant, content: reply))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .livingChecklistsSummary(let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            messages.append(Message(role: .assistant, content: reply))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .habitsGoalsSummary(let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
            messages.append(Message(role: .assistant, content: reply))
            ErisSpeaker.shared.speak(spokenReply, tone: self.selectedVoiceTone)
            return
            
        case .marineWeatherSummary(let reply, let spokenReply):
            messages.append(Message(role: .user, content: trimmed))
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
