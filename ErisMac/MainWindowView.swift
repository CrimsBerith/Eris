import SwiftUI
import ErisCore
import AppKit
enum MacSidebarTab: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case tasks = "İşler"
    case vault = "Kasa"
    
    var id: String { rawValue }
}

struct MainWindowView: View {
    @EnvironmentObject var appState: ErisMacState
    @ObservedObject var widgetManager = ErisWidgetManager.shared
    @ObservedObject var personaManager = ErisAgentPersonaManager.shared
    @ObservedObject var safeGate = ErisSafeExecutionGate.shared
    @ObservedObject var openLoopsEngine = ErisOpenLoopsEngine.shared
    @ObservedObject var checklistEngine = ErisLivingChecklistEngine.shared
    @State private var newMemoryText: String = ""
    @State private var filterMemoryCategory: MemoryCategory? = nil
    @State private var showAgentPickerPopover: Bool = false
    @State private var showVaultSheet: Bool = false
    @State private var showChecklistsSheet: Bool = false
    @State private var sidebarEditingRecord: ErisMemoryRecord? = nil
    @State private var sidebarTab: MacSidebarTab = .all
    
    var body: some View {
        HStack(spacing: 0) {
            // Ana Sohbet ve Canlı Ses Alanı
            VStack(spacing: 0) {
                // Glassmorphism Üst Başlık
                HStack(spacing: 8) {
                    // macOS Pencere Butonları (Kırmızı/Sarı/Yeşil) için Güvenli Sol Boşluk
                    Spacer().frame(width: 58)
                    
                    Image(systemName: "shield.checkered")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .font(.title3)
                        .shadow(color: ErisTheme.bronzeHighlight.opacity(0.35), radius: 6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text("ERIS")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(ErisTheme.coldWhite)
                            
                            // Durum Mikro-Animasyon Rozeti (Dinliyor / Düşünüyor / Konuşuyor)
                            ErisStatusBadgeView(
                                isListening: appState.isListening,
                                isThinking: appState.isThinking,
                                isSpeaking: appState.isSpeaking
                            )
                        }
                        
                        Text("\(appState.selectedVoiceTone.title) • ⌘⇧E")
                            .font(.system(size: 9.5))
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    
                    // Özel Ajanlar Seçici Popover
                    Button(action: {
                        showAgentPickerPopover.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: personaManager.activeModule?.icon ?? "sparkles")
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            if !appState.isCompactMode {
                                Text(personaManager.activeModule?.shortTitle ?? "Özel Ajanlar")
                                    .font(.caption2).bold()
                                    .foregroundColor(ErisTheme.coldWhite)
                                    .lineLimit(1)
                                    .frame(maxWidth: 110)
                                    .truncationMode(.tail)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(ErisTheme.bronzeHighlight.opacity(0.18))
                                .overlay(Capsule().stroke(ErisTheme.bronzeAccent.opacity(0.35), lineWidth: 0.8))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Aktif Özel Ajanı Değiştir")
                    .popover(isPresented: $showAgentPickerPopover) {
                        MacAgentQuickPopoverView {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    }
                    
                    Spacer()
                    
                    // Canlı Ses Dalgası (Yalnızca dinlerken veya konuşurken açılır)
                    if appState.isListening || appState.isSpeaking {
                        VoiceWaveformView(
                            isListening: appState.isListening,
                            isSpeaking: appState.isSpeaking,
                            audioLevel: appState.audioLevel,
                            barCount: appState.isCompactMode ? 8 : 14
                        )
                        .padding(.horizontal, 4)
                        .transition(.opacity)
                    }
                    
                    // ⚡ Tek Birleşik Hızlı Erişim Menüsü
                    Menu {
                        Button(action: { appState.playMorningBriefing() }) {
                            Label(L10n.morningBriefingTitle, systemImage: "sun.max.fill")
                        }
                        Divider()
                        Button(action: { showVaultSheet = true }) {
                            Label("Hafıza Kasası", systemImage: "brain.head.profile")
                        }
                        Button(action: { showChecklistsSheet = true }) {
                            Label("Yaşayan Listeler", systemImage: "checklist.checked")
                        }
                        Button(action: {
                            sidebarTab = .tasks
                            appState.sendUserMessage(L10n.promptListOpenLoops)
                        }) {
                            Label(L10n.openLoopsTitle, systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(action: {
                            sidebarTab = .tasks
                            appState.sendUserMessage(L10n.promptCheckHabits)
                        }) {
                            Label(L10n.habitsGoalsTitle, systemImage: "flame.fill")
                        }
                        Divider()
                        Button(action: { appState.clearChat() }) {
                            Label("Yeni Sohbet (⌘N)", systemImage: "square.and.pencil")
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            if !appState.isCompactMode {
                                Text("Hızlı Erişim")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundColor(ErisTheme.coldWhite)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(ErisTheme.bronzeHighlight.opacity(0.12))
                                .overlay(Capsule().stroke(ErisTheme.bronzeAccent.opacity(0.3), lineWidth: 0.8))
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Hızlı Erişim — Brifing, Kasa, Listeler")
                    
                    Divider()
                        .frame(height: 16)
                        .background(Color.white.opacity(0.12))
                        .padding(.horizontal, 2)
                    
                    // AlwaysOnTop Pin Butonu
                    Button(action: {
                        appState.toggleAlwaysOnTop()
                    }) {
                        Image(systemName: appState.isAlwaysOnTop ? "pin.fill" : "pin")
                            .font(.system(size: 12))
                            .foregroundColor(appState.isAlwaysOnTop ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                    .help(appState.isAlwaysOnTop ? "Her Zaman Üstte: Açık" : "Her Zaman Üstte: Kapalı")
                    
                    // Compact / Full Panel Geçiş Butonu
                    Button(action: {
                        appState.toggleCompactMode()
                    }) {
                        Image(systemName: appState.isCompactMode ? "arrow.up.left.and.arrow.down.right" : "rectangle.compress.vertical")
                            .font(.system(size: 12))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                    .help(appState.isCompactMode ? "Tam Görünüme Geç" : "Kompakt Floating Panele Geç")
                }
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 10)
                .background(
                    VisualEffectBlur(material: .headerView, blendingMode: .withinWindow)
                )
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Mesaj Akışı veya Karşılama Başlangıç Paneli
                if appState.messages.count <= 1 {
                    ScrollView {
                        VStack {
                            ErisQuickActionHubView(
                                onSelectAction: { action in
                                    switch action {
                                    case .morningBriefing:
                                        appState.playMorningBriefing()
                                    case .quickNote:
                                        showVaultSheet = true
                                    case .openLoops:
                                        sidebarTab = .tasks
                                        appState.sendUserMessage(L10n.promptListOpenLoops)
                                    case .livingLists:
                                        showChecklistsSheet = true
                                    case .habitsGoals:
                                        sidebarTab = .tasks
                                        appState.sendUserMessage(L10n.promptCheckHabits)
                                    }
                                },
                                onSelectPrompt: { promptText in
                                    appState.sendUserMessage(promptText)
                                }
                            )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 14) {
                                ForEach(appState.messages) { msg in
                                    GlassMessageBubble(message: msg)
                                }
                            }
                            .padding(appState.isCompactMode ? 12 : 20)
                        }
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
                    GlassApprovalBanner(action: action)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 6)
                } else if safeGate.hasPendingApprovals, let ticket = safeGate.pendingTickets.first(where: { $0.isPending }) {
                    SafeActionBannerView(
                        ticket: ticket,
                        onApprove: { safeGate.approve(ticketId: ticket.id) },
                        onReject: { safeGate.reject(ticketId: ticket.id) }
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
                }
                
                // Sohbet İçi Hızlı Öneri Hapları (Yalnızca mesajlar varken gösterilir)
                if appState.messages.count > 1 {
                    ErisPromptSuggestionsBar { promptText in
                        appState.sendUserMessage(promptText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 2)
                }
                
                // Alt Giriş Çubuğu (Glassmorphism)
                HStack(spacing: 8) {
                    // Hızlı Aksiyon Menüsü (+)
                    Menu {
                        Button(action: { appState.clearChat() }) {
                            Label("Yeni Sohbet", systemImage: "square.and.pencil")
                        }
                        Divider()
                        Button(action: { appState.playMorningBriefing() }) {
                            Label(L10n.morningBriefingTitle, systemImage: "sun.max.fill")
                        }
                        Button(action: { showVaultSheet = true }) {
                            Label(L10n.quickNoteTitle, systemImage: "brain.head.profile")
                        }
                        Button(action: { showChecklistsSheet = true }) {
                            Label(L10n.livingListsTitle, systemImage: "checklist.checked")
                        }
                        Button(action: {
                            sidebarTab = .tasks
                            appState.sendUserMessage(L10n.promptListOpenLoops)
                        }) {
                            Label(L10n.openLoopsTitle, systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(action: {
                            sidebarTab = .tasks
                            appState.sendUserMessage(L10n.promptCheckHabits)
                        }) {
                            Label(L10n.habitsGoalsTitle, systemImage: "flame.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                            .padding(4)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Hızlı İşlemler")
                    
                    HStack(spacing: 6) {
                        TextField(
                            appState.isCompactMode ? "Eris'e talimat ver..." : L10n.askErisPlaceholder,
                            text: $appState.inputText
                        )
                        .textFieldStyle(.plain)
                        .foregroundColor(ErisTheme.coldWhite)
                        .onSubmit {
                            appState.sendUserMessage(appState.inputText)
                        }
                        
                        if !appState.inputText.isEmpty {
                            Button(action: { appState.inputText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ErisTheme.graphiteSurface.opacity(0.65))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ErisTheme.bronzeAccent.opacity(0.25), lineWidth: 0.8)
                            )
                    )
                    
                    Button(action: {
                        appState.toggleListening()
                    }) {
                        Image(systemName: appState.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(appState.isListening ? .black : ErisTheme.bronzeHighlight)
                            .padding(7)
                            .background(
                                Circle()
                                    .fill(appState.isListening ? ErisTheme.listeningGreen : Color.white.opacity(0.08))
                                    .overlay(Circle().stroke(appState.isListening ? ErisTheme.listeningGreen : ErisTheme.bronzeAccent.opacity(0.3), lineWidth: 0.8))
                            )
                    }
                    .buttonStyle(.plain)
                    .help(appState.isListening ? L10n.tapToStop : L10n.tapToSpeak)
                    
                    Button(action: {
                        appState.sendUserMessage(appState.inputText)
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                    }
                    .buttonStyle(.plain)
                    .disabled(appState.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(appState.isCompactMode ? 10 : 14)
                .background(
                    VisualEffectBlur(material: .underWindowBackground, blendingMode: .withinWindow)
                )
            }
            
            // Eğer kompakt moddaysa yan panel gizlenir (Floating Panel tasarımı)
            if !appState.isCompactMode {
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Sağ Bağlam Paneli (Seçili Widget'lar)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Odak Filtresi: Tümü / İşler / Kasa
                        Picker("", selection: $sidebarTab) {
                            ForEach(MacSidebarTab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 2)
                        
                        // Güvenlik Kapısı: Bekleyen onay bileti varsa en üstte göster
                        if safeGate.hasPendingApprovals, let ticket = safeGate.pendingTickets.first(where: { $0.isPending }) {
                            SafeActionBannerView(
                                ticket: ticket,
                                onApprove: { safeGate.approve(ticketId: ticket.id) },
                                onReject: { safeGate.reject(ticketId: ticket.id) }
                            )
                        }
                        
                        // Dinamik Rota & Çıkış Sayacı
                        if (sidebarTab == .all || sidebarTab == .tasks) && widgetManager.isWidgetEnabled(.commuteTracker) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "car.fill")
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    Text("DİNAMİK ROTA")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    Spacer()
                                    HStack(spacing: 3) {
                                        Circle().fill(ErisTheme.listeningGreen).frame(width: 5, height: 5)
                                        Text("OPTİMAL")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(ErisTheme.listeningGreen)
                                    }
                                }
                                
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Ev → Ofis / Atölye")
                                            .font(.caption).bold()
                                            .foregroundColor(ErisTheme.coldWhite)
                                        Text("Akıcı Trafik (38 dk)")
                                            .font(.caption2)
                                            .foregroundColor(ErisTheme.coldGray)
                                    }
                                    Spacer()
                                    Text("14:38")
                                        .font(.system(size: 18, weight: .black, design: .monospaced))
                                        .foregroundColor(ErisTheme.thinkingAmber)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        // Açık Döngüler (Zihinsel Berraklık)
                        if (sidebarTab == .all || sidebarTab == .tasks) && widgetManager.isWidgetEnabled(.openLoops) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "checklist")
                                        .foregroundColor(ErisTheme.thinkingAmber)
                                    Text("AÇIK DÖNGÜLER")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(ErisTheme.thinkingAmber)
                                    Spacer()
                                    Text("\(openLoopsEngine.pendingCount) Askıda")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(ErisTheme.thinkingAmber)
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(Capsule().fill(ErisTheme.thinkingAmber.opacity(0.15)))
                                }
                                
                                ForEach(openLoopsEngine.activeLoops.prefix(2)) { loop in
                                    OpenLoopCardView(
                                        loop: loop,
                                        onComplete: { openLoopsEngine.completeLoop(id: loop.id) },
                                        onDismiss: { openLoopsEngine.dismissLoop(id: loop.id) }
                                    )
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ErisTheme.thinkingAmber.opacity(0.25), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        // Yaşayan Checklists
                        if (sidebarTab == .all || sidebarTab == .tasks) && widgetManager.isWidgetEnabled(.livingChecklists) {
                            if let activeList = checklistEngine.checklists.first {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "suitcase.fill")
                                            .foregroundColor(ErisTheme.bronzeHighlight)
                                        Text("YAŞAYAN LİSTE")
                                            .font(.system(size: 11, weight: .bold))
                                            .tracking(1.2)
                                            .foregroundColor(ErisTheme.bronzeHighlight)
                                        Spacer()
                                        Text("\(activeList.completedCount)/\(activeList.items.count)")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(ErisTheme.coldWhite)
                                    }
                                    
                                    Text(activeList.title)
                                        .font(.caption).bold()
                                        .foregroundColor(ErisTheme.coldWhite)
                                    
                                    ForEach(activeList.items.prefix(2)) { item in
                                        Button(action: {
                                            checklistEngine.toggleItem(checklistId: activeList.id, itemId: item.id)
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(item.isCompleted ? ErisTheme.listeningGreen : ErisTheme.coldGray)
                                                Text(item.title)
                                                    .font(.caption2)
                                                    .foregroundColor(item.isCompleted ? ErisTheme.coldGray : ErisTheme.coldWhite)
                                                    .strikethrough(item.isCompleted)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                                        )
                                )
                            }
                        }
                        
                        // Takvim / Günün Planı Widget'ı
                        if (sidebarTab == .all || sidebarTab == .tasks) && widgetManager.isWidgetEnabled(.calendar) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    Text("GÜNÜN PLANI")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    Spacer()
                                    Button(action: {
                                        appState.sendUserMessage("Bugünkü planlarımız nedir?")
                                    }) {
                                        Image(systemName: "speaker.wave.2")
                                            .font(.caption2)
                                            .foregroundColor(ErisTheme.coldGray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Text("Bugün 3 toplantı, Nişantaşı kumaş seçimi ve seyir planlaması var.")
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldWhite.opacity(0.85))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        // Notlar & Dosyalar Kasası Kartı
                        if (sidebarTab == .all || sidebarTab == .vault) && (widgetManager.isWidgetEnabled(.memoryVault) || widgetManager.isWidgetEnabled(.fabricCost) || widgetManager.isWidgetEnabled(.designIdeas)) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    Text("NOTLAR & DOSYALAR")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    Spacer()
                                    
                                    Button(action: { showVaultSheet = true }) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "arrow.up.right.square")
                                            Text("Kasa (\(appState.memories.count))")
                                        }
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(ErisTheme.coldWhite)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Capsule().fill(Color.white.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                // Kategori Filtre Butonları
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 4) {
                                        MacCategoryMiniButton(title: "Tümü", isSelected: filterMemoryCategory == nil) { filterMemoryCategory = nil }
                                        MacCategoryMiniButton(title: "Belgeler", isSelected: filterMemoryCategory == .document) { filterMemoryCategory = .document }
                                        MacCategoryMiniButton(title: "Teknik", isSelected: filterMemoryCategory == .technical) { filterMemoryCategory = .technical }
                                        MacCategoryMiniButton(title: "Finans", isSelected: filterMemoryCategory == .finance) { filterMemoryCategory = .finance }
                                        MacCategoryMiniButton(title: "Tasarım", isSelected: filterMemoryCategory == .designIdea) { filterMemoryCategory = .designIdea }
                                        MacCategoryMiniButton(title: "Projeler", isSelected: filterMemoryCategory == .project) { filterMemoryCategory = .project }
                                    }
                                }
                                
                                // Hızlı Hafıza & Dosya Ekleme
                                HStack(spacing: 6) {
                                    TextField("Hızlı not veya dosya kaydı...", text: $newMemoryText)
                                        .textFieldStyle(.plain)
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(6)
                                        .foregroundColor(ErisTheme.coldWhite)
                                        .onSubmit {
                                            saveQuickMemory()
                                        }
                                    
                                    Button(action: saveQuickMemory) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(ErisTheme.bronzeHighlight)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                ForEach(displayedMacMemories.prefix(5)) { mem in
                                    MacMemoryCardRow(
                                        record: mem,
                                        onTogglePin: { appState.togglePin(id: mem.id) },
                                        onEdit: { sidebarEditingRecord = mem },
                                        onExport: { exportRecordOnMac(mem) },
                                        onDelete: { appState.deleteMemory(id: mem.id) }
                                    )
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        // Deniz Durumu Kartı
                        if (sidebarTab == .all || sidebarTab == .vault) && widgetManager.isWidgetEnabled(.marine) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "water.waves")
                                        .foregroundColor(Color(red: 0.5, green: 0.75, blue: 0.95))
                                    Text("DENİZ & HAVA")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                }
                                
                                Text(appState.marineInfo.location)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldGray)
                                
                                HStack {
                                    Text("\(Int(appState.marineInfo.airTempCelsius))°C")
                                        .font(.title3).bold()
                                        .foregroundColor(ErisTheme.coldWhite)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(appState.marineInfo.windDirection)
                                            .font(.caption2).foregroundColor(ErisTheme.coldGray)
                                        Text("\(String(format: "%.1f", appState.marineInfo.windSpeedKnots)) kts")
                                            .font(.caption).bold().foregroundColor(ErisTheme.coldWhite)
                                    }
                                }
                                
                                Text("Deniz: \(appState.marineInfo.seaCondition) (\(String(format: "%.1f", appState.marineInfo.waveHeightMeters))m)")
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        // Canlı Piyasa Özeti Kartı
                        if (sidebarTab == .all || sidebarTab == .vault) && widgetManager.isWidgetEnabled(.markets) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .foregroundColor(ErisTheme.listeningGreen)
                                    Text("PİYASALAR")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                }
                                
                                ForEach(appState.marketItems) { item in
                                    HStack {
                                        Text(item.symbol)
                                            .font(.caption).bold()
                                            .foregroundColor(ErisTheme.coldWhite)
                                        Spacer()
                                        Text(item.price)
                                            .font(.caption)
                                            .foregroundColor(ErisTheme.coldGray)
                                        Text(item.change)
                                            .font(.caption2).bold()
                                            .foregroundColor(item.isPositive ? ErisTheme.listeningGreen : .red)
                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        // Hızlı Sesli Eylemler Widget'ı
                        if widgetManager.isWidgetEnabled(.quickActions) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "waveform.badge.mic")
                                        .foregroundColor(Color(red: 0.75, green: 0.60, blue: 0.95))
                                    Text("HIZLI SESLİ EYLEMLER")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.2)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                }
                                
                                Button(action: {
                                    appState.sendUserMessage("Bugünkü planlarımızı anlat.")
                                }) {
                                    HStack {
                                        Image(systemName: "sun.haze.fill")
                                            .font(.caption)
                                            .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.45))
                                        Text("Sabah Brifingi Dinle")
                                            .font(.caption2)
                                            .foregroundColor(ErisTheme.coldWhite)
                                        Spacer()
                                    }
                                    .padding(6)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    appState.sendUserMessage("Aktif ajan olarak uzmanlık alanın kapsamında bugünkü hedeflerimi ve önceliklerimi analiz et.")
                                }) {
                                    HStack {
                                        Image(systemName: personaManager.activeModule?.icon ?? "sparkles")
                                            .font(.caption)
                                            .foregroundColor(Color(red: 0.75, green: 0.60, blue: 0.95))
                                        Text(personaManager.activeModule?.title ?? "Ajan Danışmanlığı")
                                            .font(.caption2)
                                            .foregroundColor(ErisTheme.coldWhite)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(6)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    appState.sendUserMessage("Hafızamdaki kayıtlı notlarımı ve önemli noktaları karşılaştır.")
                                }) {
                                    HStack {
                                        Image(systemName: "brain.head.profile")
                                            .font(.caption)
                                            .foregroundColor(Color(red: 0.5, green: 0.75, blue: 0.95))
                                        Text("Hafıza & Not Analizi")
                                            .font(.caption2)
                                            .foregroundColor(ErisTheme.coldWhite)
                                        Spacer()
                                    }
                                    .padding(6)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                                    )
                            )
                        }
                        
                        if widgetManager.activeWidgets.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 26))
                                    .foregroundColor(ErisTheme.coldGray.opacity(0.4))
                                Text("Görünür Widget Yok")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ErisTheme.coldWhite)
                                Text("Ayarlar > Widget Seçimi menüsünden istediğiniz widget'ları açabilirsiniz.")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                }
                .frame(width: 260)
                .background(
                    VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow)
                )
            }
        }
        .background(
            ErisTheme.graphite
        )
        .sheet(isPresented: $showVaultSheet) {
            MacNotesAndFilesVaultSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showChecklistsSheet) {
            MacChecklistsSheetView()
        }
        .sheet(item: $sidebarEditingRecord) { mem in
            MacEditNoteSheet(record: mem) { updatedTitle, updatedContent, updatedCat, updatedTags, updatedFileName in
                appState.updateMemory(
                    id: mem.id,
                    title: updatedTitle,
                    content: updatedContent,
                    category: updatedCat,
                    tags: updatedTags,
                    fileName: updatedFileName
                )
            }
        }
    }
    
    var displayedMacMemories: [ErisMemoryRecord] {
        if let cat = filterMemoryCategory {
            return appState.memories.filter { $0.category == cat }
        }
        return appState.memories
    }
    
    private func saveQuickMemory() {
        let text = newMemoryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        newMemoryText = ""
        
        if let extracted = ErisNoteIntelligence.shared.analyzeUtterance(text, isVoice: false) {
            appState.addMemory(
                title: extracted.title,
                content: extracted.content,
                category: extracted.category,
                tags: extracted.tags,
                source: "manual",
                fileName: extracted.suggestedFileName,
                pinned: true
            )
        } else {
            appState.addMemory(
                title: nil,
                content: text,
                category: filterMemoryCategory ?? .preference,
                tags: [],
                source: "manual",
                fileName: nil,
                pinned: true
            )
        }
    }
    
    private func exportRecordOnMac(_ record: ErisMemoryRecord) {
        let md = ErisMemoryDatabase.shared.exportRecordAsMarkdown(record)
        let fName = record.fileName ?? "\(record.title.replacingOccurrences(of: " ", with: "_")).md"
        exportToMacFile(content: md, defaultName: fName)
    }
    
    private func exportToMacFile(content: String, defaultName: String) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = defaultName
        savePanel.allowedContentTypes = [.plainText]
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

// Glassmorphism Mesaj Baloncuğu
struct GlassMessageBubble: View {
    let message: Message
    @State private var isCopied: Bool = false
    @State private var isHovering: Bool = false
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 13.5))
                        .padding(13)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ErisTheme.graphiteSurface,
                                            ErisTheme.graphiteLight
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(ErisTheme.bronzeAccent.opacity(0.28), lineWidth: 0.8)
                                )
                        )
                        .foregroundColor(ErisTheme.coldWhite)
                        .shadow(color: Color.black.opacity(0.25), radius: 5, y: 2)
                    
                    HStack(spacing: 4) {
                        if message.isAudioTranscript {
                            Image(systemName: "waveform")
                                .font(.system(size: 8))
                                .foregroundColor(ErisTheme.sourceVoice.opacity(0.8))
                        }
                        Text(formattedTime)
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                    }
                    .padding(.trailing, 4)
                }
                .frame(maxWidth: 580, alignment: .trailing)
                .contextMenu {
                    Button(action: { copyToClipboard(message.content) }) {
                        Label("Kopyala", systemImage: "doc.on.doc")
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 10))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        Text("ERIS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        
                        Spacer()
                        
                        Text(formattedTime)
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                    }
                    
                    Text(message.content)
                        .font(.system(size: 13.5))
                        .lineSpacing(3)
                        .foregroundColor(ErisTheme.coldWhite)
                    
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
                        .padding(.top, 6)
                    }
                    
                    // Kolay Eylem Çubuğu: Kopyala & Seslendir
                    HStack(spacing: 8) {
                        Button(action: {
                            copyToClipboard(message.content)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isCopied = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 9))
                                Text(isCopied ? "Kopyalandı" : "Kopyala")
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            .foregroundColor(isCopied ? ErisTheme.listeningGreen : ErisTheme.coldGray)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Metni Panoya Kopyala")
                        
                        Button(action: {
                            if ErisSpeaker.shared.isSpeaking {
                                ErisSpeaker.shared.stopSpeaking()
                            } else {
                                ErisSpeaker.shared.speak(message.content)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 9))
                                Text("Seslendir")
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            .foregroundColor(ErisTheme.coldGray)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Cevabı Seslendir / Durdur")
                        
                        Spacer()
                    }
                    .padding(.top, 3)
                    .opacity(isHovering || isCopied ? 1.0 : 0.5)
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ErisTheme.bronzeHighlight.opacity(0.35), lineWidth: 0.8)
                        )
                )
                .shadow(color: ErisTheme.bronzeHighlight.opacity(0.08), radius: 8, y: 2)
                .frame(maxWidth: 620, alignment: .leading)
                .onHover { isHovering = $0 }
                .contextMenu {
                    Button(action: { copyToClipboard(message.content) }) {
                        Label("Kopyala", systemImage: "doc.on.doc")
                    }
                    Button(action: { ErisSpeaker.shared.speak(message.content) }) {
                        Label("Seslendir", systemImage: "speaker.wave.2")
                    }
                }
                Spacer(minLength: 40)
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
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
                    .foregroundColor(ErisTheme.coldWhite)
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
            .tint(ErisTheme.bronzeHighlight)
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
                    .foregroundColor(ErisTheme.bronzeHighlight)
                Text("ERIS")
                    .font(.headline)
                    .foregroundColor(ErisTheme.coldWhite)
                
                Spacer()
                
                ErisStatusBadgeView(
                    isListening: appState.isListening,
                    isThinking: appState.isThinking,
                    isSpeaking: appState.isSpeaking
                )
            }
            Divider()
            
            Button(appState.isListening ? "Dinlemeyi Durdur" : "Dinlemeyi Başlat (⌘⇧E)") {
                appState.toggleListening()
            }
            
            Button("Günün Brifingini Dinle") {
                appState.playMorningBriefing()
            }
            
            Button(appState.isCompactMode ? "Tam Görünüme Geç" : "Kompakt Floating Paneli Aç") {
                appState.toggleCompactMode()
                NSApp.activate(ignoringOtherApps: true)
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
        .frame(width: 275)
        .background(ErisTheme.graphite)
    }
}

struct MacAgentQuickPopoverView: View {
    @ObservedObject var personaManager = ErisAgentPersonaManager.shared
    var showSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Özel Ajanlar (Custom Agents)")
                    .font(.headline)
                    .foregroundColor(ErisTheme.coldWhite)
                
                Spacer()
                
                Button(action: {
                    showSettings()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Yönet / Yeni Ajan")
                    }
                    .font(.caption2).bold()
                    .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(spacing: 6) {
                ForEach(personaManager.modules) { module in
                    Button(action: {
                        personaManager.setActiveAgent(id: module.id)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: module.icon)
                                .font(.system(size: 15))
                                .foregroundColor(module.isEnabled ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.white.opacity(module.isEnabled ? 0.12 : 0.04)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(module.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(module.isEnabled ? ErisTheme.coldWhite : ErisTheme.coldGray)
                                    if module.isEnabled {
                                        Text("Aktif")
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(ErisTheme.listeningGreen.opacity(0.2)))
                                            .foregroundColor(ErisTheme.listeningGreen)
                                    }
                                }
                                Text(module.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(ErisTheme.coldGray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: module.isEnabled ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(module.isEnabled ? ErisTheme.bronzeHighlight : Color.white.opacity(0.2))
                                .font(.system(size: 14))
                        }
                        .padding(7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(module.isEnabled ? 0.08 : 0.02))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(ErisTheme.graphite)
    }
}

// MARK: - Mac Notlar & Dosyalar Kasası Mini Butonları ve Satırları
struct MacCategoryMiniButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Capsule().fill(isSelected ? ErisTheme.bronzeHighlight.opacity(0.3) : Color.white.opacity(0.04)))
                .foregroundColor(isSelected ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
        }
        .buttonStyle(.plain)
    }
}

struct MacMemoryCardRow: View {
    let record: ErisMemoryRecord
    let onTogglePin: () -> Void
    let onEdit: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    var categoryColor: Color {
        ErisTheme.categoryColor(for: record.category)
    }
    
    var sourceIcon: String {
        switch record.source.lowercased() {
        case "voice": return "waveform"
        case "chat": return "bubble.left.fill"
        default: return "square.and.pencil"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                // Kategori Rozeti
                HStack(spacing: 2) {
                    Image(systemName: record.category.icon)
                    Text(record.category.displayName)
                }
                .font(.system(size: 8, weight: .bold))
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(Capsule().fill(categoryColor.opacity(0.18)))
                .foregroundColor(categoryColor)
                
                // Kaynak Rozeti
                if record.source == "voice" {
                    HStack(spacing: 2) {
                        Image(systemName: "waveform")
                        Text("Ses")
                    }
                    .font(.system(size: 7, weight: .semibold))
                    .padding(.horizontal, 4).padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.purple.opacity(0.2)))
                    .foregroundColor(Color(red: 0.75, green: 0.60, blue: 0.95))
                }
                
                Spacer()
                
                // Düzenle Butonu
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 8.5))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
                .help("Notu Düzenle")
                
                // Sabitle Butonu
                Button(action: onTogglePin) {
                    Image(systemName: record.pinned ? "pin.fill" : "pin")
                        .font(.system(size: 8))
                        .foregroundColor(record.pinned ? Color(red: 0.95, green: 0.75, blue: 0.45) : ErisTheme.coldGray.opacity(0.5))
                }
                .buttonStyle(.plain)
                
                // Dışa Aktar (.md)
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 8))
                        .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                // Sil Butonu
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            
            Text(record.title)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(ErisTheme.coldWhite)
                .lineLimit(1)
            
            Text(record.content)
                .font(.system(size: 9.5))
                .foregroundColor(ErisTheme.coldWhite.opacity(0.85))
                .lineLimit(2)
            
            if !record.tags.isEmpty {
                HStack(spacing: 3) {
                    ForEach(record.tags.prefix(3), id: \.self) { tag in
                        Text(tag.hasPrefix("#") ? tag : "#\(tag)")
                            .font(.system(size: 7.5))
                            .foregroundColor(ErisTheme.coldGray)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(record.pinned ? ErisTheme.bronzeAccent.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 0.6)
                )
        )
    }
}

// MARK: - Mac Notlar & Dosyalar Kasası Tam Pencere Modalı (Vault Sheet)
struct MacNotesAndFilesVaultSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: ErisMacState
    
    @State private var searchText: String = ""
    @State private var filterCategory: MemoryCategory? = nil
    @State private var filterSource: String? = nil
    @State private var showNewNoteForm: Bool = false
    @State private var copiedId: String? = nil
    @State private var editingRecord: ErisMemoryRecord? = nil
    @State private var editingVaultDoc: VaultDocumentRecord? = nil
    
    // Yeni Not Alanları
    @State private var newTitle: String = ""
    @State private var newContent: String = ""
    @State private var newCategory: MemoryCategory = .document
    @State private var newTags: String = ""
    @State private var newFileName: String = ""
    @State private var newPinned: Bool = false
    
    var filteredRecords: [ErisMemoryRecord] {
        var items = appState.memories
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(q) ||
                $0.content.lowercased().contains(q) ||
                $0.tags.contains(where: { $0.lowercased().contains(q) }) ||
                $0.category.displayName.lowercased().contains(q) ||
                ($0.fileName?.lowercased().contains(q) ?? false)
            }
        }
        if let cat = filterCategory {
            items = items.filter { $0.category == cat }
        }
        if let src = filterSource {
            items = items.filter { $0.source.lowercased() == src.lowercased() }
        }
        return items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Başlık Barı
            HStack(spacing: 12) {
                Image(systemName: "folder.fill.badge.gearshape")
                    .font(.title2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("NOTLAR & DOSYALAR KASASI")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        Text("(\(appState.memories.count) Kayıt)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    Text("Sesli konuşmalardan yakalanan bilgiler, teknik kararlar, fiyatlar ve belgeler")
                        .font(.system(size: 10.5))
                        .foregroundColor(ErisTheme.coldGray)
                }
                
                Spacer()
                
                // Yeni Not Ekle Butonu
                Button(action: { showNewNoteForm.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showNewNoteForm ? "chevron.up" : "plus")
                        Text(showNewNoteForm ? "Formu Kapat" : "Yeni Not Ekle")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(ErisTheme.bronzeHighlight))
                    .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                
                // Tüm Kasa Arşivini Dışa Aktar (.md)
                Button(action: exportAllToMarkdownFile) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Tümünü İndir (.md)")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                    .foregroundColor(ErisTheme.coldWhite)
                }
                .buttonStyle(.plain)
                
                // Kapat Butonu
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(ErisTheme.coldGray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .background(ErisTheme.graphiteSurface)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Yeni Not Ekleme Açılır Formu
            if showNewNoteForm {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        TextField("Başlık (Örn: Q1 Sunucu Bütçesi)", text: $newTitle)
                            .textFieldStyle(.plain)
                            .padding(7)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        Picker("Kategori", selection: $newCategory) {
                            ForEach(MemoryCategory.allCases, id: \.self) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .frame(width: 170)
                    }
                    
                    TextField("Not veya Belge İçeriği...", text: $newContent, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                        .padding(7)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    HStack(spacing: 12) {
                        TextField("Etiketler (#finans, #sunucu)", text: $newTags)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        TextField("Dosya Adı (Örn: Butce.md)", text: $newFileName)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        Toggle("Sabitle", isOn: $newPinned)
                            .font(.system(size: 11))
                        
                        Button(action: saveNewNoteFromSheet) {
                            Text("Kasaya Kaydet")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(ErisTheme.bronzeHighlight))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .disabled(newContent.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.02))
                Divider().background(Color.white.opacity(0.08))
            }
            
            // Filtre ve Arama Alanı (2 Kademeli Temiz Düzen)
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Arama Çubuğu
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(ErisTheme.coldGray)
                        TextField("Notlarda, etiketlerde veya dosyalarda ara...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundColor(ErisTheme.coldWhite)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                    
                    Spacer()
                    
                    // Kaynak Filtreleri
                    HStack(spacing: 4) {
                        MacCategoryMiniButton(title: "Tüm Kaynaklar", isSelected: filterSource == nil) { filterSource = nil }
                        MacCategoryMiniButton(title: "🎙️ Ses", isSelected: filterSource == "voice") { filterSource = "voice" }
                        MacCategoryMiniButton(title: "💬 Sohbet", isSelected: filterSource == "chat") { filterSource = "chat" }
                        MacCategoryMiniButton(title: "✍️ Manuel", isSelected: filterSource == "manual") { filterSource = "manual" }
                    }
                }
                
                // Kategori Klasör Filtreleri (Yatay Kaydırılabilir)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        MacCategoryMiniButton(title: "Tümü (\(appState.memories.count))", isSelected: filterCategory == nil) { filterCategory = nil }
                        MacCategoryMiniButton(title: "Belgeler", isSelected: filterCategory == .document) { filterCategory = .document }
                        MacCategoryMiniButton(title: "Teknik", isSelected: filterCategory == .technical) { filterCategory = .technical }
                        MacCategoryMiniButton(title: "Finans", isSelected: filterCategory == .finance) { filterCategory = .finance }
                        MacCategoryMiniButton(title: "Tasarım", isSelected: filterCategory == .designIdea) { filterCategory = .designIdea }
                        MacCategoryMiniButton(title: "Projeler", isSelected: filterCategory == .project) { filterCategory = .project }
                        MacCategoryMiniButton(title: "Kişiler", isSelected: filterCategory == .person) { filterCategory = .person }
                        MacCategoryMiniButton(title: "Kumaş", isSelected: filterCategory == .fabricCost) { filterCategory = .fabricCost }
                        MacCategoryMiniButton(title: "Denizcilik", isSelected: filterCategory == .maritime) { filterCategory = .maritime }
                    }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(ErisTheme.graphite)
            
            Divider().background(Color.white.opacity(0.08))
            
            // Proaktif Kasa & Süre Takibi (Bölüm 27, 28, 29)
            let expiringDocs = ErisVaultDocumentService.shared.getExpiringDocuments(withinDays: 180)
            if !expiringDocs.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(ErisTheme.thinkingAmber)
                            .font(.system(size: 11))
                        Text("PROAKTİF BELGE & SÜRE TAKİBİ (YAKLAŞAN BİTİŞLER)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ErisTheme.thinkingAmber)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(expiringDocs) { doc in
                                HStack(spacing: 8) {
                                    Image(systemName: doc.category.icon)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(doc.title)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(ErisTheme.coldWhite)
                                        if let exp = doc.expirationDate ?? doc.warrantyEndDate {
                                            Text("Bitiş: \(exp.formatted(date: .numeric, time: .omitted))")
                                                .font(.system(size: 9.5))
                                                .foregroundColor(ErisTheme.coldGray)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.04))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ErisTheme.thinkingAmber.opacity(0.3), lineWidth: 0.8))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(ErisTheme.thinkingAmber.opacity(0.05))
                Divider().background(Color.white.opacity(0.08))
            }
            
            // Kayıtlar Grid/Listesi
            ScrollView {
                if filteredRecords.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.4))
                            .padding(.top, 40)
                        Text(searchText.isEmpty ? "Bu kategoride kayıt bulunamadı." : "'\(searchText)' aramasıyla eşleşen bir kayıt yok.")
                            .font(.system(size: 13))
                            .foregroundColor(ErisTheme.coldGray)
                        Text("Mikrofonla konuşurken söylediğiniz fiyatlar, görevler ve teknik detaylar buraya otomatik organize edilir.")
                            .font(.system(size: 11))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredRecords) { record in
                            MacVaultRecordDetailCard(
                                record: record,
                                isCopied: copiedId == record.id,
                                onTogglePin: { appState.togglePin(id: record.id) },
                                onEdit: { editingRecord = record },
                                onCopy: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(record.content, forType: .string)
                                    copiedId = record.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        if copiedId == record.id { copiedId = nil }
                                    }
                                },
                                onExport: { exportRecord(record) },
                                onDelete: { appState.deleteMemory(id: record.id) }
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 760, height: 560)
        .background(ErisTheme.graphite)
        .sheet(item: $editingRecord) { record in
            MacEditNoteSheet(record: record) { updatedTitle, updatedContent, updatedCat, updatedTags, updatedFileName in
                appState.updateMemory(
                    id: record.id,
                    title: updatedTitle,
                    content: updatedContent,
                    category: updatedCat,
                    tags: updatedTags,
                    fileName: updatedFileName
                )
            }
        }
        .sheet(item: $editingVaultDoc) { doc in
            MacEditVaultDocSheet(doc: doc) { updatedDoc in
                ErisVaultDocumentService.shared.updateDocument(updatedDoc)
            }
        }
    }
    
    private func saveNewNoteFromSheet() {
        let text = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        let tags = newTags.components(separatedBy: CharacterSet(charactersIn: ", ")).filter { !$0.isEmpty }
        appState.addMemory(
            title: newTitle.isEmpty ? nil : newTitle,
            content: text,
            category: newCategory,
            tags: tags,
            source: "manual",
            fileName: newFileName.isEmpty ? nil : newFileName,
            pinned: newPinned
        )
        
        newTitle = ""
        newContent = ""
        newTags = ""
        newFileName = ""
        newPinned = false
        showNewNoteForm = false
    }
    
    private func exportRecord(_ record: ErisMemoryRecord) {
        let md = ErisMemoryDatabase.shared.exportRecordAsMarkdown(record)
        let fName = record.fileName ?? "\(record.title.replacingOccurrences(of: " ", with: "_")).md"
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = fName
        savePanel.allowedContentTypes = [.plainText]
        savePanel.begin { res in
            if res == .OK, let url = savePanel.url {
                try? md.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func exportAllToMarkdownFile() {
        let md = ErisMemoryDatabase.shared.exportAllAsMarkdown()
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "Eris_Notlar_Ve_Dosyalar_Kasasi.md"
        savePanel.allowedContentTypes = [.plainText]
        savePanel.begin { res in
            if res == .OK, let url = savePanel.url {
                try? md.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Mac Kasa Detay Kartı
struct MacVaultRecordDetailCard: View {
    let record: ErisMemoryRecord
    let isCopied: Bool
    let onTogglePin: () -> Void
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    var categoryColor: Color {
        ErisTheme.categoryColor(for: record.category)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Kategori
                HStack(spacing: 4) {
                    Image(systemName: record.category.icon)
                    Text(record.category.displayName)
                }
                .font(.system(size: 9.5, weight: .bold))
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Capsule().fill(categoryColor.opacity(0.18)))
                .foregroundColor(categoryColor)
                
                // Kaynak
                HStack(spacing: 3) {
                    Image(systemName: record.source == "voice" ? "waveform" : (record.source == "chat" ? "bubble.left.fill" : "square.and.pencil"))
                    Text(record.source == "voice" ? "Sesli Konuşma" : (record.source == "chat" ? "Sohbet" : "Manuel"))
                }
                .font(.system(size: 8.5, weight: .semibold))
                .padding(.horizontal, 6).padding(.vertical, 2.5)
                .background(Capsule().fill(record.source == "voice" ? Color.purple.opacity(0.2) : Color.white.opacity(0.06)))
                .foregroundColor(record.source == "voice" ? Color(red: 0.75, green: 0.60, blue: 0.95) : ErisTheme.coldGray)
                
                if let fName = record.fileName {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.text")
                        Text(fName)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.system(size: 8.5, weight: .medium))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)))
                    .foregroundColor(ErisTheme.coldWhite)
                    .frame(maxWidth: 140)
                }
                
                Spacer()
                
                // Düzenle
                Button(action: onEdit) {
                    HStack(spacing: 2) {
                        Image(systemName: "pencil")
                        Text("Düzenle")
                    }
                    .font(.system(size: 9.5))
                    .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .help("Notu veya Dosyayı Düzenle")
                
                // Sabitle Butonu
                Button(action: onTogglePin) {
                    Image(systemName: record.pinned ? "pin.fill" : "pin")
                        .font(.system(size: 11))
                        .foregroundColor(record.pinned ? Color(red: 0.95, green: 0.75, blue: 0.45) : ErisTheme.coldGray.opacity(0.6))
                }
                .buttonStyle(.plain)
                
                // Dışa Aktar (.md)
                Button(action: onExport) {
                    HStack(spacing: 2) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Dışa Aktar")
                    }
                    .font(.system(size: 9.5))
                    .foregroundColor(ErisTheme.coldWhite.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                
                // Kopyala
                Button(action: onCopy) {
                    HStack(spacing: 2) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Kopyalandı" : "Kopyala")
                    }
                    .font(.system(size: 9.5))
                    .foregroundColor(isCopied ? Color.green : ErisTheme.coldWhite.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                
                // Sil
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            
            // Başlık
            Text(record.title)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(ErisTheme.coldWhite)
            
            // İçerik
            Text(record.content)
                .font(.system(size: 11.5))
                .foregroundColor(ErisTheme.coldWhite.opacity(0.9))
                .lineSpacing(2)
            
            // Alt Satır: Etiketler & Tarih
            HStack {
                if !record.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(record.tags, id: \.self) { tag in
                            Text(tag.hasPrefix("#") ? tag : "#\(tag)")
                                .font(.system(size: 8.5))
                                .padding(.horizontal, 5).padding(.vertical, 1.5)
                                .background(Capsule().fill(Color.white.opacity(0.04)))
                                .foregroundColor(ErisTheme.coldGray)
                        }
                    }
                }
                Spacer()
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 9.5))
                    .foregroundColor(ErisTheme.coldGray.opacity(0.8))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(record.pinned ? ErisTheme.bronzeAccent.opacity(0.35) : Color.white.opacity(0.06), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - Mac Not / Dosya Düzenleme Modalı
struct MacEditNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    let record: ErisMemoryRecord
    let onSave: (_ title: String?, _ content: String, _ category: MemoryCategory, _ tags: [String], _ fileName: String?) -> Void
    
    @State private var editTitle: String
    @State private var editContent: String
    @State private var editCategory: MemoryCategory
    @State private var editTags: String
    @State private var editFileName: String
    
    init(record: ErisMemoryRecord, onSave: @escaping (String?, String, MemoryCategory, [String], String?) -> Void) {
        self.record = record
        self.onSave = onSave
        _editTitle = State(initialValue: record.title)
        _editContent = State(initialValue: record.content)
        _editCategory = State(initialValue: record.category)
        _editTags = State(initialValue: record.tags.joined(separator: ", "))
        _editFileName = State(initialValue: record.fileName ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Başlık
            HStack(spacing: 10) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("NOTU / DOSYAYI DÜZENLE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(ErisTheme.coldWhite)
                    Text("Değişiklikler anında yerel veritabanına ve kasaya kaydedilir.")
                        .font(.system(size: 10.5))
                        .foregroundColor(ErisTheme.coldGray)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ErisTheme.coldGray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))
            
            Divider().background(Color.white.opacity(0.08))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // 1. Başlık
                    VStack(alignment: .leading, spacing: 5) {
                        Text("BAŞLIK")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        TextField("Not başlığı...", text: $editTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(9)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    // 2. Kategori & Dosya Adı
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("KATEGORİ")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            Picker("", selection: $editCategory) {
                                ForEach(MemoryCategory.allCases, id: \.self) { cat in
                                    Text(cat.displayName).tag(cat)
                                }
                            }
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("BAĞLI DOSYA ADI (İSTEĞE BAĞLI)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(ErisTheme.coldGray)
                            TextField("Örn: Rapor.md veya Kod.swift", text: $editFileName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                                .foregroundColor(ErisTheme.coldWhite)
                        }
                    }
                    
                    // 3. İçerik (TextEditor)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("İÇERİK / NOT METNİ")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            Spacer()
                            Text("\(editContent.count) karakter")
                                .font(.system(size: 9.5))
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        TextEditor(text: $editContent)
                            .font(.system(size: 12, design: .monospaced))
                            .lineSpacing(3)
                            .padding(8)
                            .frame(minHeight: 180)
                            .scrollContentBackground(.hidden)
                            .background(RoundedRectangle(cornerRadius: 8).fill(ErisTheme.graphiteSurface))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    // 4. Etiketler
                    VStack(alignment: .leading, spacing: 5) {
                        Text("ETİKETLER (VİRGÜLLE AYIRIN)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ErisTheme.coldGray)
                        TextField("Örn: #finans, #kumaş, #toplantı", text: $editTags)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 0.8))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                }
                .padding(20)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            // Alt Butonlar
            HStack(spacing: 12) {
                Button("Vazgeç") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(ErisTheme.coldGray)
                .font(.system(size: 12, weight: .medium))
                
                Spacer()
                
                Button(action: saveChanges) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                        Text("Değişiklikleri Kaydet")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(ErisTheme.bronzeHighlight))
                    .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                .disabled(editContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
        }
        .frame(width: 580, height: 500)
        .background(ErisTheme.graphite)
    }
    
    private func saveChanges() {
        let trimmedContent = editContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        let tags = editTags.components(separatedBy: CharacterSet(charactersIn: ", ")).filter { !$0.isEmpty }
        let finalTitle = editTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalFileName = editFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        onSave(finalTitle, trimmedContent, editCategory, tags, finalFileName)
        dismiss()
    }
}

// MARK: - Mac Resmî Belge / Kasa Evrakı Düzenleme Modalı
struct MacEditVaultDocSheet: View {
    @Environment(\.dismiss) var dismiss
    let doc: VaultDocumentRecord
    let onSave: (VaultDocumentRecord) -> Void
    
    @State private var title: String
    @State private var category: VaultDocCategory
    @State private var documentNumber: String
    @State private var issuer: String
    @State private var notes: String
    @State private var hasExpiration: Bool
    @State private var expirationDate: Date
    
    init(doc: VaultDocumentRecord, onSave: @escaping (VaultDocumentRecord) -> Void) {
        self.doc = doc
        self.onSave = onSave
        _title = State(initialValue: doc.title)
        _category = State(initialValue: doc.category)
        _documentNumber = State(initialValue: doc.documentNumber ?? "")
        _issuer = State(initialValue: doc.issuer ?? "")
        _notes = State(initialValue: doc.notes)
        _hasExpiration = State(initialValue: doc.expirationDate != nil || doc.warrantyEndDate != nil)
        _expirationDate = State(initialValue: doc.expirationDate ?? doc.warrantyEndDate ?? Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("RESMÎ BELGEYİ / KASAYI DÜZENLE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundColor(ErisTheme.coldWhite)
                    Text("Geçerlilik süresi ve evrak bilgileri güncellenir.")
                        .font(.system(size: 10.5))
                        .foregroundColor(ErisTheme.coldGray)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ErisTheme.coldGray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))
            
            Divider().background(Color.white.opacity(0.08))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("BELGE BAŞLIĞI")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        TextField("Belge başlığı...", text: $title)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("KATEGORİ")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            Picker("", selection: $category) {
                                ForEach(VaultDocCategory.allCases, id: \.self) { c in
                                    Text(c.displayName).tag(c)
                                }
                            }
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("BELGE NO")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(ErisTheme.coldGray)
                            TextField("Örn: U12345678", text: $documentNumber)
                                .textFieldStyle(.plain)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                                .foregroundColor(ErisTheme.coldWhite)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("DÜZENLEYEN KURUM / İHRAÇÇI")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ErisTheme.coldGray)
                        TextField("Örn: T.C. İçişleri Bakanlığı / Apple", text: $issuer)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    Toggle("Geçerlilik / Bitiş Tarihi Var", isOn: $hasExpiration)
                        .font(.system(size: 12))
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    if hasExpiration {
                        DatePicker("Son Geçerlilik / Bitiş", selection: $expirationDate, displayedComponents: .date)
                            .font(.system(size: 12))
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("NOTLAR & DETAYLAR")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(ErisTheme.graphiteSurface))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                }
                .padding(20)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            HStack(spacing: 12) {
                Button("Vazgeç") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(ErisTheme.coldGray)
                Spacer()
                Button(action: saveDoc) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                        Text("Belgeyi Güncelle")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(ErisTheme.bronzeHighlight))
                    .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(Color.white.opacity(0.03))
        }
        .frame(width: 520, height: 460)
        .background(ErisTheme.graphite)
    }
    
    private func saveDoc() {
        var updated = doc
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.category = category
        updated.documentNumber = documentNumber.isEmpty ? nil : documentNumber
        updated.issuer = issuer.isEmpty ? nil : issuer
        updated.notes = notes
        if hasExpiration {
            if category == .warrantyCertificate {
                updated.warrantyEndDate = expirationDate
                updated.expirationDate = nil
            } else {
                updated.expirationDate = expirationDate
            }
        } else {
            updated.expirationDate = nil
            updated.warrantyEndDate = nil
        }
        onSave(updated)
        dismiss()
    }
}

// MARK: - macOS Yaşayan Checklists Sayfası (Sheet)

struct MacChecklistsSheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var checklistEngine = ErisLivingChecklistEngine.shared
    
    @State private var selectedFilter: ChecklistType? = nil
    @State private var showNewListForm: Bool = false
    @State private var newTitle: String = ""
    @State private var newType: ChecklistType = .travelPacking
    @State private var newCity: String = ""
    @State private var newWeatherNote: String = ""
    @State private var newItemsText: String = ""
    
    var filteredChecklists: [LivingChecklist] {
        if let filter = selectedFilter {
            return checklistEngine.checklists.filter { $0.type == filter }
        }
        return checklistEngine.checklists
    }
    
    var totalItemsCount: Int {
        checklistEngine.checklists.reduce(0) { $0 + $1.items.count }
    }
    
    var completedItemsCount: Int {
        checklistEngine.checklists.reduce(0) { $0 + $1.completedCount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Başlık Barı
            HStack(spacing: 12) {
                Image(systemName: "checklist.checked")
                    .font(.title2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("YAŞAYAN LİSTELER & HAZIRLIKLAR")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        Text("(\(checklistEngine.checklists.count) Liste • \(completedItemsCount)/\(totalItemsCount) Tamamlandı)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    Text("Hava durumu, seyahatler, market ve ev rutinlerine göre dinamik yönetilen akıllı listeler")
                        .font(.system(size: 10.5))
                        .foregroundColor(ErisTheme.coldGray)
                }
                
                Spacer()
                
                // Yeni Liste Ekle Butonu
                Button(action: { showNewListForm.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showNewListForm ? "chevron.up" : "plus")
                        Text(showNewListForm ? "Formu Kapat" : "Yeni Liste")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(ErisTheme.bronzeHighlight))
                    .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                
                // Kapat Butonu
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(ErisTheme.coldGray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .background(ErisTheme.graphiteSurface)
            
            Divider().background(Color.white.opacity(0.1))
            
            // Yeni Liste Oluşturma Açılır Formu
            if showNewListForm {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        TextField("Liste Başlığı (Örn: Paris Moda Haftası Bavulu)", text: $newTitle)
                            .textFieldStyle(.plain)
                            .padding(7)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        Picker("Kategori", selection: $newType) {
                            ForEach(ChecklistType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .frame(width: 170)
                    }
                    
                    HStack(spacing: 12) {
                        TextField("Hedef Şehir (Opsiyonel)", text: $newCity)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        TextField("Hava Durumu Notu (Opsiyonel)", text: $newWeatherNote)
                            .textFieldStyle(.plain)
                            .padding(6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(6)
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    TextField("Başlangıç Maddeleri (Virgülle ayırın: Pasaport, Şarj adaptörü, Cüzdan...)", text: $newItemsText)
                        .textFieldStyle(.plain)
                        .padding(7)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    HStack {
                        Button(action: prefillPresetItems) {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Şablon Maddeleri Doldur")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: createNewChecklist) {
                            Text("Listeyi Oluştur")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(ErisTheme.bronzeHighlight))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.02))
                Divider().background(Color.white.opacity(0.08))
            }
            
            // Kategori Filtre Butonları (Yatay Kaydırılabilir)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    MacCategoryMiniButton(title: "Tümü (\(checklistEngine.checklists.count))", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }
                    ForEach(ChecklistType.allCases, id: \.self) { type in
                        let count = checklistEngine.checklists.filter { $0.type == type }.count
                        MacCategoryMiniButton(title: "\(type.displayName) (\(count))", isSelected: selectedFilter == type) {
                            selectedFilter = type
                        }
                    }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(ErisTheme.graphite)
            
            Divider().background(Color.white.opacity(0.08))
            
            // Liste Kartları
            ScrollView {
                if filteredChecklists.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "checklist")
                            .font(.system(size: 36))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.4))
                            .padding(.top, 40)
                        Text("Bu kategoride liste bulunamadı.")
                            .font(.system(size: 13))
                            .foregroundColor(ErisTheme.coldGray)
                        Text("Yukarıdaki 'Yeni Liste' butonundan seyahat, kiler veya ev rutini listesi oluşturabilirsiniz.")
                            .font(.system(size: 11))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredChecklists) { checklist in
                            MacChecklistDetailCard(checklist: checklist)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 660, height: 620)
        .background(ErisTheme.graphite)
    }
    
    private func prefillPresetItems() {
        switch newType {
        case .travelPacking:
            newItemsText = "Bordo Pasaport, Şarj adaptörü & powerbank, Kulaklık, Güneş gözlüğü, Kişisel bakım kiti"
        case .groceryPantry:
            newItemsText = "Organik zeytinyağı, Badem sütü, Kahve çekirdeği, Yumurta, Ekmek"
        case .relocationMoving:
            newItemsText = "İnternet abonelik nakli, Elektrik/su devri, Koli bantları, Eşya sigortası, Adres beyanı"
        case .homeChores:
            newItemsText = "Su filtresi değişimi, Çöp tasnifi, Robot süpürge hazne temizliği, Havalandırma"
        case .eventPreparation:
            newItemsText = "Menü planı, Müzik çalma listesi, İçecek ve buz takviyesi, Sofra düzeni"
        case .vehicleMaintenance:
            newItemsText = "Lastik hava basıncı kontrolü, Motor yağı & cam suyu, İlk yardım çantası, Trafik seti"
        case .custom:
            newItemsText = "Öncelikli görev, Kontrol adımı, Not ve takip"
        }
    }
    
    private func createNewChecklist() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let rawItems = newItemsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let itemsToUse = rawItems.isEmpty ? ["İlk hazırlık maddesi"] : rawItems
        
        checklistEngine.createChecklist(
            title: trimmed,
            type: newType,
            items: itemsToUse,
            destinationCity: newCity.isEmpty ? nil : newCity,
            weatherNote: newWeatherNote.isEmpty ? nil : newWeatherNote
        )
        
        newTitle = ""
        newCity = ""
        newWeatherNote = ""
        newItemsText = ""
        showNewListForm = false
    }
}

// MARK: - macOS Checklist Detay Kartı

struct MacChecklistDetailCard: View {
    let checklist: LivingChecklist
    @ObservedObject var checklistEngine = ErisLivingChecklistEngine.shared
    
    @State private var newItemTitle: String = ""
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Başlık & İlerleme
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: checklist.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(ErisTheme.bronzeHighlight)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(checklist.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        if let city = checklist.destinationCity {
                            Text(city)
                                .font(.system(size: 9.5, weight: .semibold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                                .foregroundColor(ErisTheme.coldGray)
                        }
                    }
                    
                    if let note = checklist.weatherNote {
                        HStack(spacing: 4) {
                            Image(systemName: "cloud.sun.fill")
                                .font(.system(size: 9))
                                .foregroundColor(ErisTheme.thinkingAmber)
                            Text(note)
                                .font(.system(size: 10))
                                .foregroundColor(ErisTheme.thinkingAmber)
                        }
                    }
                }
                
                Spacer()
                
                // Tamamlanma Sayacı
                Text("\(checklist.completedCount)/\(checklist.items.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(checklist.progressFraction == 1.0 ? ErisTheme.listeningGreen : ErisTheme.coldWhite)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(checklist.progressFraction == 1.0 ? ErisTheme.listeningGreen.opacity(0.2) : Color.white.opacity(0.06)))
                
                // Menü (Tümünü Tamamla, Temizle, Sil)
                Menu {
                    Button("Tümünü Tamamlandı İşaretle") {
                        checklistEngine.completeAllItems(checklistId: checklist.id)
                    }
                    Button("Tamamlanan Maddeleri Temizle") {
                        checklistEngine.clearCompletedItems(checklistId: checklist.id)
                    }
                    Divider()
                    Button("Listeyi Sil", role: .destructive) {
                        checklistEngine.deleteChecklist(id: checklist.id)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                        .foregroundColor(ErisTheme.coldGray)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            
            // İlerleme Çubuğu
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06)).frame(height: 4)
                    Capsule()
                        .fill(checklist.progressFraction == 1.0 ? ErisTheme.listeningGreen : ErisTheme.bronzeHighlight)
                        .frame(width: geo.size.width * CGFloat(checklist.progressFraction), height: 4)
                }
            }
            .frame(height: 4)
            
            // Maddeler Listesi
            VStack(spacing: 6) {
                ForEach(checklist.items) { item in
                    HStack(spacing: 8) {
                        Button(action: {
                            checklistEngine.toggleItem(checklistId: checklist.id, itemId: item.id)
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 13))
                                .foregroundColor(item.isCompleted ? ErisTheme.listeningGreen : ErisTheme.coldGray)
                        }
                        .buttonStyle(.plain)
                        
                        Text(item.title)
                            .font(.system(size: 12))
                            .foregroundColor(item.isCompleted ? ErisTheme.coldGray : ErisTheme.coldWhite)
                            .strikethrough(item.isCompleted)
                        
                        Spacer()
                        
                        if let cat = item.category {
                            Text(cat)
                                .font(.system(size: 9))
                                .padding(.horizontal, 5).padding(.vertical, 1.5)
                                .background(Capsule().fill(Color.white.opacity(0.04)))
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Button(action: {
                            checklistEngine.deleteItem(checklistId: checklist.id, itemId: item.id)
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9))
                                .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Maddeyi Sil")
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.top, 4)
            
            // Yeni Madde Ekleme Satırı
            HStack(spacing: 6) {
                TextField("Yeni madde ekle...", text: $newItemTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5))
                    .padding(6)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)
                    .foregroundColor(ErisTheme.coldWhite)
                    .onSubmit {
                        submitItem()
                    }
                
                Button(action: submitItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
                .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8)
                )
        )
    }
    
    private func submitItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        checklistEngine.addItem(checklistId: checklist.id, title: trimmed)
        newItemTitle = ""
    }
}

