//
//  IOSChatView.swift
//  ErisIOS
//

import SwiftUI
import ErisCore

struct IOSChatView: View {
    @EnvironmentObject var appState: ErisIOSState
    @ObservedObject var personaManager = ErisAgentPersonaManager.shared
    @FocusState private var isInputFocused: Bool
    @State private var showAgentPicker: Bool = false
    @State private var isCreatingNewAgent: Bool = false
    @State private var showSaveToast: Bool = false
    @State private var lastSavedCategory: MemoryCategory = .document
    @State private var showQuickActionMenu: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst Şerit: Ajan Seçici + Hava Durumu + Brifing + Yeni Sohbet
            HStack(spacing: 8) {
                // Aktif Özel Ajan Seçici Pill
                Button(action: {
                    ErisHaptics.light()
                    showAgentPicker = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: personaManager.activeModule?.icon ?? "sparkles")
                            .foregroundColor(ErisTheme.bronzeHighlight)
                            .font(.system(size: 12))
                            .accessibilityHidden(true)
                        Text(personaManager.activeModule?.shortTitle ?? "Özel Ajan")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(ErisTheme.coldWhite)
                            .lineLimit(1)
                            .frame(maxWidth: 110)
                            .truncationMode(.tail)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(ErisTheme.coldGray)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule().fill(ErisTheme.bronzeHighlight.opacity(0.18))
                            .overlay(Capsule().stroke(ErisTheme.bronzeAccent.opacity(0.35), lineWidth: 0.8))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ajan seç: \(personaManager.activeModule?.shortTitle ?? "Özel Ajan")")
                .accessibilityHint("Ajan listesini açar")
                
                Spacer()
                
                // Kompakt Hava Durumu Chip'i
                HStack(spacing: 5) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.5, green: 0.75, blue: 0.95))
                        .accessibilityHidden(true)
                    Text("\(Int(appState.marineInfo.airTempCelsius))°C")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(ErisTheme.coldWhite)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .accessibilityLabel("Hava durumu: \(Int(appState.marineInfo.airTempCelsius)) derece")
                
                // Sabah Brifingi Kısa Erişim
                Button(action: {
                    ErisHaptics.light()
                    appState.playMorningBriefing()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.98, green: 0.75, blue: 0.28))
                        Text("Brifing")
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.98, green: 0.75, blue: 0.28).opacity(0.14))
                            .overlay(Capsule().stroke(Color(red: 0.98, green: 0.75, blue: 0.28).opacity(0.3), lineWidth: 0.8))
                    )
                }
                .buttonStyle(.plain)
                
                // Yeni Sohbet Butonu (Yalnızca mesaj varken gösterilir)
                if appState.messages.count > 1 {
                    Button(action: {
                        withAnimation {
                            appState.clearChat()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.bubble")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            Text("Yeni")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(ErisTheme.coldWhite)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.02))
            
            // Mesaj Akışı veya Karşılama Başlangıç Paneli
            if appState.messages.count <= 1 {
                ScrollView {
                    VStack(spacing: 12) {
                        ErisQuickActionHubView(
                            onSelectAction: { action in
                                handleQuickAction(action)
                            },
                            onSelectPrompt: { promptText in
                                appState.sendUserMessage(promptText)
                            }
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(appState.messages) { msg in
                                IOSChatBubble(message: msg)
                                    .transition(.messageEntry)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: appState.messages.count) { _, _ in
                        withAnimation(.messageEntry) {
                            if let last = appState.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Onay Uyarısı (Sıfır-Güven Kapısı)
            if let action = appState.pendingApproval {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ONAY GEREKLİ")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.orange)
                        Text(action.summary)
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    Spacer()
                    
                    Button("Reddet") { appState.rejectPendingAction() }
                        .font(.caption2).bold()
                        .foregroundColor(.gray)
                    Button("Onayla") { appState.approvePendingAction() }
                        .font(.caption2).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(ErisTheme.bronzeHighlight))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.35), lineWidth: 0.8)
                        )
                )
                .padding(.horizontal, 14)
                .transition(.approvalSlide)
            }
            
            // Not Kayıt Toast'u
            SaveNoteToast(
                message: "Not kasaya kaydedildi",
                category: lastSavedCategory,
                isShowing: $showSaveToast
            )
            
            // Dinleme / Konuşma Canlı Ses Dalgası
            if appState.isListening || appState.isSpeaking {
                HStack(spacing: 12) {
                    Circle()
                        .fill(appState.isListening ? ErisTheme.listeningGreen : ErisTheme.bronzeHighlight)
                        .frame(width: 8, height: 8)
                    
                    Text(appState.isListening ? L10n.tapToStop : "Eris konuşuyor...")
                        .font(.caption2).bold()
                        .foregroundColor(appState.isListening ? ErisTheme.listeningGreen : ErisTheme.coldWhite)
                    
                    VoiceWaveformView(
                        isListening: appState.isListening,
                        isSpeaking: appState.isSpeaking,
                        audioLevel: appState.audioLevel,
                        barCount: 16
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                )
                .padding(.bottom, 6)
                .transition(.opacity)
            }
            
            // Sohbet İçi Hızlı Öneri Hapları (Mesajlar varken de kolayca erişilebilir)
            if appState.messages.count > 1 {
                ErisPromptSuggestionsBar { promptText in
                    appState.sendUserMessage(promptText)
                }
                .padding(.bottom, 4)
            }
            
            // Alt Giriş ve Kolay Eylem Çubuğu
            HStack(spacing: 8) {
                // Hızlı Eylem Menüsü (+)
                Menu {
                    if appState.messages.count > 1 {
                        Button(role: .destructive, action: {
                            withAnimation {
                                appState.clearChat()
                            }
                        }) {
                            Label("Yeni Sohbet", systemImage: "plus.bubble")
                        }
                        Divider()
                    }
                    Button(action: { appState.playMorningBriefing() }) {
                        Label(L10n.morningBriefingTitle, systemImage: "sun.max.fill")
                    }
                    Button(action: { appState.sendUserMessage(L10n.promptListOpenLoops) }) {
                        Label(L10n.openLoopsTitle, systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button(action: { appState.sendUserMessage(L10n.promptShowGrocery) }) {
                        Label(L10n.livingListsTitle, systemImage: "checklist.checked")
                    }
                    Button(action: { appState.sendUserMessage(L10n.promptCheckHabits) }) {
                        Label(L10n.habitsGoalsTitle, systemImage: "flame.fill")
                    }
                    Button(action: { appState.sendUserMessage(L10n.promptTakeNote) }) {
                        Label(L10n.quickNoteTitle, systemImage: "brain.head.profile")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .padding(4)
                }
                
                // Metin Giriş Alanı
                HStack(spacing: 6) {
                    TextField(L10n.askErisPlaceholder, text: $appState.inputText)
                        .font(.system(size: 14))
                        .foregroundColor(ErisTheme.coldWhite)
                        .focused($isInputFocused)
                        .onSubmit {
                            appState.sendUserMessage(appState.inputText)
                        }
                    
                    if !appState.inputText.isEmpty {
                        Button(action: { appState.inputText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Metni temizle")
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(ErisTheme.bronzeAccent.opacity(0.22), lineWidth: 0.8)
                        )
                )
                
                // Tek Dokunuşla Mikrofon / Ses Butonu
                Button(action: {
                    appState.toggleListening()
                }) {
                    ZStack {
                        if appState.isListening {
                            Circle()
                                .fill(ErisTheme.listeningGreen.opacity(0.25))
                                .frame(width: 44, height: 44)
                                .scaleEffect(1.0 + CGFloat(appState.audioLevel) * 0.3)
                        }
                        
                        Circle()
                            .fill(appState.isListening ? ErisTheme.listeningGreen : Color.white.opacity(0.08))
                            .frame(width: 38, height: 38)
                            .overlay(
                                Circle().stroke(appState.isListening ? ErisTheme.listeningGreen : ErisTheme.bronzeAccent.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: appState.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(appState.isListening ? .black : ErisTheme.bronzeHighlight)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appState.isListening ? L10n.tapToStop : L10n.tapToSpeak)
                
                // Gönder Butonu (Yalnızca metin varsa)
                if !appState.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: {
                        ErisHaptics.medium()
                        appState.sendUserMessage(appState.inputText)
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Gönder")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, isInputFocused ? 12 : 78)
            .animation(.easeOut(duration: 0.22), value: isInputFocused)
        }
        .sheet(isPresented: $showAgentPicker) {
            IOSAgentQuickSwitcherView {
                isCreatingNewAgent = true
            }
        }
        .sheet(isPresented: $isCreatingNewAgent) {
            IOSModuleEditSheet(module: nil) { title, subtitle, icon, instructions in
                _ = ErisAgentPersonaManager.shared.addModule(title: title, subtitle: subtitle, icon: icon, instructions: instructions)
            }
        }
    }
    
    private func handleQuickAction(_ action: ErisQuickActionType) {
        switch action {
        case .morningBriefing:
            appState.playMorningBriefing()
        case .quickNote:
            withAnimation {
                appState.selectedTab = .memory
            }
        case .openLoops:
            withAnimation {
                appState.selectedTab = .widgets
            }
            appState.sendUserMessage(L10n.promptListOpenLoops)
        case .livingLists:
            withAnimation {
                appState.selectedTab = .checklists
            }
        case .habitsGoals:
            withAnimation {
                appState.selectedTab = .widgets
            }
            appState.sendUserMessage(L10n.promptCheckHabits)
        }
    }
}

struct IOSAgentQuickSwitcherView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var personaManager = ErisAgentPersonaManager.shared
    var onCreateNew: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("AKTİF ÖZEL AJANLAR")) {
                    ForEach(personaManager.modules) { module in
                        HStack(spacing: 12) {
                            Image(systemName: module.icon)
                                .font(.title3)
                                .foregroundColor(module.isEnabled ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color.white.opacity(module.isEnabled ? 0.12 : 0.04)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(module.title)
                                        .font(.subheadline).bold()
                                        .foregroundColor(module.isEnabled ? ErisTheme.coldWhite : ErisTheme.coldGray)
                                    if module.isEnabled {
                                        Text("Aktif")
                                            .font(.system(size: 9, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(ErisTheme.listeningGreen.opacity(0.2)))
                                            .foregroundColor(ErisTheme.listeningGreen)
                                    }
                                }
                                Text(module.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldGray)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                personaManager.setActiveAgent(id: module.id)
                            }) {
                                Text(module.isEnabled ? "Seçili" : "Seç")
                                    .font(.caption2).bold()
                                    .foregroundColor(module.isEnabled ? .black : ErisTheme.coldWhite)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(module.isEnabled ? ErisTheme.bronzeHighlight : Color.white.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(action: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onCreateNew()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            Text("Yeni Özel Ajan Yarat...")
                                .font(.subheadline).bold()
                                .foregroundColor(ErisTheme.bronzeHighlight)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Özel Ajan Seçimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}

// MARK: - iOS Mesaj Baloncuğu Bileşeni

struct IOSChatBubble: View {
    let message: Message
    @State private var isCopied: Bool = false
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 14.5))
                        .padding(13)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(ErisTheme.userBubbleGradient)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(ErisTheme.bronzeAccent.opacity(0.3), lineWidth: 0.8)
                                )
                        )
                        .foregroundColor(ErisTheme.coldWhite)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, y: 2)
                    
                    HStack(spacing: 4) {
                        if message.isAudioTranscript {
                            HStack(spacing: 3) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 8))
                                Text("Sesli")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(ErisTheme.sourceVoice.opacity(0.7))
                        }
                        
                        Text(formattedTime)
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                    }
                    .padding(.trailing, 6)
                }
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = message.content
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Label("Kopyala", systemImage: "doc.on.doc")
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // ERIS Başlık Rozeti + Saat
                    HStack(spacing: 5) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        Text("ERIS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        
                        Spacer()
                        
                        Text(formattedTime)
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                    }
                    .padding(.horizontal, 6)
                    
                    Text(message.content)
                        .font(.system(size: 14.5))
                        .lineSpacing(3)
                        .padding(13)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(ErisTheme.bronzeHighlight.opacity(0.35), lineWidth: 0.8)
                                )
                        )
                        .foregroundColor(ErisTheme.coldWhite)
                        .shadow(color: ErisTheme.bronzeHighlight.opacity(0.06), radius: 8, y: 2)
                    
                    if let plan = message.plan {
                        DecomposedPlanCardView(
                            plan: plan,
                            onScheduleAll: {},
                            onTransferToOpenLoops: {
                                for step in plan.steps {
                                    ErisOpenLoopsEngine.shared.addLoop(OpenLoopItem(domain: step.domain, title: step.title, details: step.details, detectedSource: "chat_plan"))
                                }
                            }
                        )
                        .padding(.top, 4)
                    }
                    
                    // Alt Aksiyon Butonları (Kopyala & Dinle)
                    HStack(spacing: 8) {
                        Button(action: {
                            UIPasteboard.general.string = message.content
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isCopied = false
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 9))
                                Text(isCopied ? "Kopyalandı" : "Kopyala")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(isCopied ? ErisTheme.listeningGreen : ErisTheme.coldGray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if ErisSpeaker.shared.isSpeaking {
                                ErisSpeaker.shared.stopSpeaking()
                            } else {
                                ErisSpeaker.shared.speak(message.content)
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 9))
                                Text("Dinle")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(ErisTheme.coldGray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    .padding(.leading, 6)
                    .padding(.top, 2)
                }
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = message.content
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Label("Kopyala", systemImage: "doc.on.doc")
                    }
                    Button(action: {
                        ErisSpeaker.shared.speak(message.content)
                    }) {
                        Label("Sesli Oku", systemImage: "speaker.wave.2")
                    }
                }
                
                Spacer(minLength: 60)
            }
        }
    }
}
