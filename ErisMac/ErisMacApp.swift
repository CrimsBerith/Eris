import SwiftUI
import ErisCore
import Combine

@main
struct ErisMacApp: App {
    @StateObject private var appState = ErisMacState()
    
    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .frame(minWidth: 920, minHeight: 640)
                .background(.ultraThinMaterial)
                .sheet(isPresented: $appState.showOnboarding) {
                    OnboardingView(isPresented: $appState.showOnboarding)
                }
        }
        .windowStyle(.hiddenTitleBar)
        
        MenuBarExtra("Eris", systemImage: "shield.lefthalf.filled") {
            MenuBarContentView()
                .environmentObject(appState)
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
    
    // Hafıza ve Brifing
    @Published var memories: [ErisMemoryRecord] = []
    @Published var marketItems: [MarketItem] = []
    @Published var marineInfo: MarineWeatherInfo = ExternalDataService.shared.getMarineWeather()
    @Published var selectedModel: GeminiModelChoice = .flash
    @Published var selectedVoiceGender: ErisVoiceGender = .male
    @Published var wakeWordEnabled: Bool = true
    
    init() {
        self.marketItems = ExternalDataService.shared.getMarketSummary()
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
        self.messages.append(
            Message(role: .assistant, content: "Eris hazır. Dinliyorum.")
        )
        setupVoiceCallbacks()
        
        // İlk açılış kontrolü (API Key yoksa Onboarding aç)
        if KeychainManager.shared.getApiKey() == nil || KeychainManager.shared.getApiKey()?.isEmpty == true {
            self.showOnboarding = true
        }
        
        // Sabah Brifingi ve iCloud senkronizasyonunu başlat
        MorningBriefingService.shared.scheduleDailyBriefing()
        ErisSyncService.shared.pullFromCloud()
        ErisSyncService.shared.onSyncUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.refreshMemories()
            }
        }
    }
    
    private func setupVoiceCallbacks() {
        ErisSpeaker.shared.onSpeakingStarted = { [weak self] in
            DispatchQueue.main.async { self?.isSpeaking = true }
        }
        ErisSpeaker.shared.onSpeakingFinished = { [weak self] in
            DispatchQueue.main.async { self?.isSpeaking = false }
        }
        
        ErisVoiceListener.shared.onAudioLevel = { [weak self] level in
            DispatchQueue.main.async { self?.audioLevel = level }
        }
        
        ErisVoiceListener.shared.onWakeWordDetected = { [weak self] in
            DispatchQueue.main.async {
                self?.handleWakeWord()
            }
        }
        
        ErisVoiceListener.shared.onFinalTranscription = { [weak self] transcript in
            DispatchQueue.main.async {
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
        ErisSpeaker.shared.stopSpeaking()
        isSpeaking = false
        NSSound.beep()
    }
    
    func refreshMemories() {
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
    }
    
    func addMemory(content: String, category: MemoryCategory = .preference) {
        let record = ErisMemoryRecord(category: category, content: content, pinned: true)
        ErisMemoryDatabase.shared.saveMemory(record)
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
        ErisSpeaker.shared.selectedGender = self.selectedVoiceGender
        ErisSpeaker.shared.speak(briefing)
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
        if lower.contains("sabah brifingi") || lower.contains("günün brifingi") || lower.contains("brifing ver") {
            let userMsg = Message(role: .user, content: trimmed)
            messages.append(userMsg)
            inputText = ""
            playMorningBriefing()
            return
        }
        
        if lower.contains("toplantı ekle") || lower.contains("etkinlik ekle") || lower.contains("takvime kaydet") {
            let userMsg = Message(role: .user, content: trimmed)
            messages.append(userMsg)
            inputText = ""
            
            self.pendingApproval = PendingAction(
                actionType: .calendarWrite,
                summary: "Etkinlik Ekle: '\(trimmed)' (Saat: İstanbul)",
                payloadJson: "{\"title\": \"\(trimmed)\"}"
            )
            messages.append(Message(role: .assistant, content: "İstediğiniz takvim kaydını hazırladım. Onaylıyor musunuz?"))
            ErisSpeaker.shared.speak("İstediğiniz takvim kaydını hazırladım. Onaylıyor musunuz?")
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
                
                ErisSpeaker.shared.selectedGender = self.selectedVoiceGender
                ErisSpeaker.shared.speak(reply)
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
        
        _ = try? CalendarCapability.shared.createEvent(
            title: action.summary,
            start: Date().addingTimeInterval(3600),
            end: Date().addingTimeInterval(7200)
        )
        
        messages.append(Message(role: .assistant, content: "Onaylandı. Takvim kaydı icra edildi: \(action.summary)"))
        ErisSpeaker.shared.speak("Onaylandı. Takvime kaydedildi.")
        pendingApproval = nil
    }
    
    func rejectPendingAction() {
        pendingApproval = nil
        messages.append(Message(role: .assistant, content: "Eylem iptal edildi."))
        ErisSpeaker.shared.speak("İptal edildi.")
    }
}
