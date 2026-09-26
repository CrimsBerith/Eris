import SwiftUI
import ErisCore

@main
struct ErisIOSApp: App {
    @StateObject private var appState = ErisIOSState()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                IOSChatView()
                    .environmentObject(appState)
                    .sheet(isPresented: $appState.showOnboarding) {
                        OnboardingView(isPresented: $appState.showOnboarding)
                    }
            }
            .preferredColorScheme(.dark)
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
    
    @Published var memories: [ErisMemoryRecord] = []
    @Published var selectedModel: GeminiModelChoice = .flash
    @Published var selectedVoiceGender: ErisVoiceGender = .male
    @Published var marineInfo = ExternalDataService.shared.getMarineWeather()
    @Published var marketItems = ExternalDataService.shared.getMarketSummary()
    
    init() {
        self.memories = ErisMemoryDatabase.shared.getAllMemories()
        self.messages.append(
            Message(role: .assistant, content: "Eris hazır. Dinliyorum.")
        )
        setupVoiceCallbacks()
        
        if KeychainManager.shared.getApiKey() == nil || KeychainManager.shared.getApiKey()?.isEmpty == true {
            self.showOnboarding = true
        }
        
        ErisSyncService.shared.pullFromCloud()
        ErisSyncService.shared.onSyncUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.memories = ErisMemoryDatabase.shared.getAllMemories()
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
        if lower.contains("sabah brifingi") || lower.contains("brifing") {
            let userMsg = Message(role: .user, content: trimmed)
            messages.append(userMsg)
            inputText = ""
            playMorningBriefing()
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
}

struct IOSChatView: View {
    @EnvironmentObject var appState: ErisIOSState
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Canlı Bilgi Şeridi
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: {
                        appState.playMorningBriefing()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.yellow)
                            Text("Brifing")
                                .font(.caption2).bold()
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color(red: 0.85, green: 0.72, blue: 0.58).opacity(0.3))
                        )
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "water.waves")
                            .foregroundColor(Color(red: 0.5, green: 0.75, blue: 0.95))
                        Text("\(appState.marineInfo.location): \(Int(appState.marineInfo.airTempCelsius))°C, \(appState.marineInfo.seaCondition)")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.white.opacity(0.06))
                    )
                    
                    ForEach(appState.marketItems) { item in
                        HStack(spacing: 4) {
                            Text(item.symbol)
                                .font(.caption2).bold()
                                .foregroundColor(.white)
                            Text(item.price)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(item.change)
                                .font(.system(size: 9)).bold()
                                .foregroundColor(item.isPositive ? .green : .red)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.white.opacity(0.06))
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .background(Color.white.opacity(0.02))
            
            // Mesaj Akışı
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(appState.messages) { msg in
                            HStack {
                                if msg.role == .user {
                                    Spacer()
                                    Text(msg.content)
                                        .font(.system(size: 15))
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.22, green: 0.24, blue: 0.28),
                                                            Color(red: 0.16, green: 0.18, blue: 0.21)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                                )
                                        )
                                        .foregroundColor(.white)
                                } else {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(msg.content)
                                            .font(.system(size: 15))
                                            .lineSpacing(2)
                                            .padding(14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .fill(Color.white.opacity(0.06))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 18)
                                                            .stroke(Color(red: 0.85, green: 0.72, blue: 0.58).opacity(0.3), lineWidth: 0.8)
                                                    )
                                            )
                                            .foregroundColor(Color(red: 0.94, green: 0.94, blue: 0.96))
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            
            if appState.isListening || appState.isSpeaking {
                HStack {
                    VoiceWaveformView(
                        isListening: appState.isListening,
                        isSpeaking: appState.isSpeaking,
                        audioLevel: appState.audioLevel
                    )
                    Text(appState.isListening ? "Dinliyor..." : "Konuşuyor...")
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                }
                .padding(.bottom, 6)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    appState.toggleListening()
                }) {
                    Image(systemName: appState.isListening ? "mic.fill" : "mic")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(appState.isListening ? .white : Color(red: 0.85, green: 0.72, blue: 0.58))
                        .padding(10)
                        .background(
                            Circle()
                                .fill(appState.isListening ? Color.red.opacity(0.8) : Color.white.opacity(0.08))
                        )
                }
                
                TextField("Eris'e talimat ver...", text: $appState.inputText)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                    )
                    .foregroundColor(.white)
                    .onSubmit {
                        appState.sendUserMessage(appState.inputText)
                    }
                
                Button(action: {
                    appState.sendUserMessage(appState.inputText)
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color(red: 0.08, green: 0.085, blue: 0.095))
        .navigationTitle("ERIS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            IOSSettingsSheet()
        }
    }
}

struct IOSSettingsSheet: View {
    @EnvironmentObject var appState: ErisIOSState
    @State private var apiKey: String = KeychainManager.shared.getApiKey() ?? ""
    @State private var savedNotice: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Gemini API ve Model")) {
                    SecureField("API Anahtarı", text: $apiKey)
                    
                    Picker("Model", selection: $appState.selectedModel) {
                        ForEach(GeminiModelChoice.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    
                    Button("Kaydet") {
                        if KeychainManager.shared.saveApiKey(apiKey) {
                            savedNotice = "Keychain'e güvenle kaydedildi."
                        }
                    }
                    if !savedNotice.isEmpty {
                        Text(savedNotice).foregroundColor(.green).font(.caption)
                    }
                }
                
                Section(header: Text("Ses Tercihleri")) {
                    Picker("Eris Sesi", selection: $appState.selectedVoiceGender) {
                        ForEach(ErisVoiceGender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                }
                
                Section(header: Text("Kişisel Hafıza (iCloud Eşitlenir)")) {
                    ForEach(appState.memories) { mem in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mem.content).font(.subheadline)
                            Text(mem.category.displayName).font(.caption2).foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
