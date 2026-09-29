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


