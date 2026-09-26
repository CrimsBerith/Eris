import SwiftUI
import ErisCore

struct MainWindowView: View {
    @EnvironmentObject var appState: ErisMacState
    @State private var newMemoryText: String = ""
    @State private var selectedMemoryCategory: MemoryCategory = .preference
    
    var body: some View {
        HStack(spacing: 0) {
            // Sol / Orta Sohbet ve Canlı Ses Alanı
            VStack(spacing: 0) {
                // Glassmorphism Üst Başlık
                HStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                        .font(.title2)
                        .shadow(color: Color(red: 0.85, green: 0.72, blue: 0.58).opacity(0.3), radius: 6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ERIS")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .tracking(2.5)
                            .foregroundColor(.white)
                        
                        Text(appState.isListening ? "Dinliyor..." : (appState.isSpeaking ? "Konuşuyor..." : "Hazır"))
                            .font(.caption2)
                            .foregroundColor(appState.isListening ? .green : (appState.isSpeaking ? Color(red: 0.85, green: 0.72, blue: 0.58) : .gray))
                    }
                    
                    Spacer()
                    
                    // Sabah Brifingi Butonu
                    Button(action: {
                        appState.playMorningBriefing()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.yellow)
                            Text("Günün Brifingi")
                                .font(.caption2).bold()
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Canlı Ses Dalga Animasyonu
                    VoiceWaveformView(
                        isListening: appState.isListening,
                        isSpeaking: appState.isSpeaking,
                        audioLevel: appState.audioLevel
                    )
                    .padding(.horizontal, 6)
                    
                    // Mikrofon / Ses Butonu
                    Button(action: {
                        appState.toggleListening()
                    }) {
                        Image(systemName: appState.isListening ? "mic.fill" : "mic.slash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(appState.isListening ? .white : Color(red: 0.85, green: 0.72, blue: 0.58))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(appState.isListening ? Color.red.opacity(0.8) : Color.white.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    
                    if appState.isThinking {
                        ProgressView()
                            .scaleEffect(0.65)
                            .tint(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    VisualEffectBlur(material: .headerView, blendingMode: .withinWindow)
                )
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Mesaj Akışı
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(appState.messages) { msg in
                                GlassMessageBubble(message: msg)
                            }
                        }
                        .padding(20)
                    }
                }
                
                // Onay Uyarısı
                if let action = appState.pendingApproval {
                    GlassApprovalBanner(action: action)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
                
                // Alt Giriş Çubuğu
                HStack(spacing: 12) {
                    TextField("Eris'e talimat ver (Örn: 'Saat 15:00'e toplantı ekle')...", text: $appState.inputText)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
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
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    VisualEffectBlur(material: .underWindowBackground, blendingMode: .withinWindow)
                )
            }
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Sağ Bağlam Paneli (Hafıza, Deniz, Piyasalar)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Kişisel Hafıza Motoru Kartı
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                            Text("KİŞİSEL HAFIZA")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                            Spacer()
                            Text("\(appState.memories.count)")
                                .font(.caption2).bold()
                                .foregroundColor(.gray)
                        }
                        
                        // Hafıza Ekleme Girişi
                        HStack(spacing: 6) {
                            TextField("Yeni hatırla...", text: $newMemoryText)
                                .textFieldStyle(.plain)
                                .font(.caption)
                                .padding(6)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .onSubmit {
                                    if !newMemoryText.isEmpty {
                                        appState.addMemory(content: newMemoryText, category: selectedMemoryCategory)
                                        newMemoryText = ""
                                    }
                                }
                            
                            Button(action: {
                                if !newMemoryText.isEmpty {
                                    appState.addMemory(content: newMemoryText, category: selectedMemoryCategory)
                                    newMemoryText = ""
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        ForEach(appState.memories.prefix(4)) { mem in
                            HStack(alignment: .top, spacing: 6) {
                                Circle()
                                    .fill(Color(red: 0.85, green: 0.72, blue: 0.58))
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 5)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mem.content)
                                        .font(.caption2)
                                        .foregroundColor(Color.white.opacity(0.85))
                                    Text(mem.category.displayName)
                                        .font(.system(size: 9))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Button(action: {
                                    appState.deleteMemory(id: mem.id)
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8))
                                        .foregroundColor(.gray.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                    )
                    
                    // Deniz Durumu Kartı
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "water.waves")
                                .foregroundColor(Color(red: 0.5, green: 0.75, blue: 0.95))
                            Text("DENİZ & HAVA")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                        }
                        
                        Text(appState.marineInfo.location)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        HStack {
                            Text("\(Int(appState.marineInfo.airTempCelsius))°C")
                                .font(.title3).bold()
                                .foregroundColor(.white)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(appState.marineInfo.windDirection)
                                    .font(.caption2).foregroundColor(.gray)
                                Text("\(String(format: "%.1f", appState.marineInfo.windSpeedKnots)) kts")
                                    .font(.caption).bold().foregroundColor(.white)
                            }
                        }
                        
                        Text("Deniz: \(appState.marineInfo.seaCondition) (\(String(format: "%.1f", appState.marineInfo.waveHeightMeters))m)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                    )
                    
                    // Canlı Piyasa Özeti Kartı
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.green)
                            Text("PİYASALAR")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.2)
                                .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                        }
                        
                        ForEach(appState.marketItems) { item in
                            HStack {
                                Text(item.symbol)
                                    .font(.caption).bold()
                                    .foregroundColor(.white)
                                Spacer()
                                Text(item.price)
                                    .font(.caption)
                                    .foregroundColor(Color.gray.opacity(0.9))
                                Text(item.change)
                                    .font(.caption2).bold()
                                    .foregroundColor(item.isPositive ? .green : .red)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                            )
                    )
                    
                    Spacer()
                }
                .padding(16)
            }
            .frame(width: 260)
            .background(
                VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow)
            )
        }
        .background(
            Color(red: 0.08, green: 0.085, blue: 0.095).opacity(0.94)
        )
    }
}

// Glassmorphism Mesaj Baloncuğu
struct GlassMessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                Text(message.content)
                    .font(.system(size: 14))
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                        Text("ERIS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                    }
                    
                    Text(message.content)
                        .font(.system(size: 14))
                        .lineSpacing(3)
                        .foregroundColor(Color(red: 0.94, green: 0.94, blue: 0.96))
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 0.85, green: 0.72, blue: 0.58).opacity(0.3), lineWidth: 0.8)
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 6, y: 3)
                Spacer()
            }
        }
    }
}

// Glassmorphism Onay Banner'ı
struct GlassApprovalBanner: View {
    @EnvironmentObject var appState: ErisMacState
    let action: PendingAction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ONAY GEREKLİ (SIFIR-GÜVEN)")
                    .font(.caption2).bold()
                    .foregroundColor(.orange)
                Text(action.summary)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button("Reddet") {
                appState.rejectPendingAction()
            }
            .buttonStyle(.bordered)
            
            Button("Onayla") {
                appState.approvePendingAction()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.85, green: 0.72, blue: 0.58))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 0.8)
                )
        )
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct MenuBarContentView: View {
    @EnvironmentObject var appState: ErisMacState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                Text("ERIS")
                    .font(.headline)
            }
            Divider()
            Button("Günün Brifingini Dinle") {
                appState.playMorningBriefing()
            }
            Button(appState.isListening ? "Dinlemeyi Durdur" : "Dinlemeyi Başlat (Hey Eris)") {
                appState.toggleListening()
            }
            Button("Ayarlar...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            Divider()
            Button("Çıkış") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 250)
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: ErisMacState
    @State private var apiKey: String = KeychainManager.shared.getApiKey() ?? ""
    @State private var savedMessage: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Gemini API ve Model").font(.headline)) {
                SecureField("Gemini API Anahtarı", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Model Seçimi", selection: $appState.selectedModel) {
                    ForEach(GeminiModelChoice.allCases, id: \.self) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                
                Button("Anahtarı Kaydet (Keychain)") {
                    if KeychainManager.shared.saveApiKey(apiKey) {
                        savedMessage = "Keychain'e güvenli şekilde kaydedildi."
                    } else {
                        savedMessage = "Kayıt hatası."
                    }
                }
                if !savedMessage.isEmpty {
                    Text(savedMessage).font(.caption).foregroundColor(.green)
                }
            }
            
            Section(header: Text("Ses ve Etkileşim").font(.headline)) {
                Picker("Eris Ses Profili", selection: $appState.selectedVoiceGender) {
                    ForEach(ErisVoiceGender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                
                Toggle("'Hey Eris' Dinleme (Wake Word)", isOn: $appState.wakeWordEnabled)
            }
            
            Section(header: Text("Sabah Brifingi").font(.headline)) {
                Text("Her sabah saat 08:30'da günün takvimini, hava & deniz durumunu ve piyasa açılışını hazırlar.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .frame(width: 480, height: 320)
    }
}
