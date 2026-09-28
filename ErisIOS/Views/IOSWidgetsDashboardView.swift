//
//  IOSWidgetsDashboardView.swift
//  ErisIOS
//

import SwiftUI
import ErisCore

// 2. Kişisel Panel & Seçilebilir Widget'lar Görünümü
struct IOSWidgetsDashboardView: View {
    @EnvironmentObject var appState: ErisIOSState
    @ObservedObject var widgetManager = ErisWidgetManager.shared
    @ObservedObject var safeGate = ErisSafeExecutionGate.shared
    @ObservedObject var openLoopsEngine = ErisOpenLoopsEngine.shared
    @ObservedObject var checklistEngine = ErisLivingChecklistEngine.shared
    @State private var showWidgetSelector: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Başlık & Widget Seçimi Butonu
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kişisel Panel")
                            .font(.title3).bold()
                            .foregroundColor(ErisTheme.coldWhite)
                        Text("\(widgetManager.activeWidgets.count) widget aktif • Dilediğini seç")
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    
                    Spacer()
                    
                    Button(action: { showWidgetSelector = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Widget Seç")
                        }
                        .font(.caption).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(ErisTheme.bronzeHighlight))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                if widgetManager.activeWidgets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.dashed")
                            .font(.system(size: 36))
                            .foregroundColor(ErisTheme.coldGray)
                        Text("Henüz bir widget seçilmedi")
                            .font(.subheadline).bold()
                            .foregroundColor(ErisTheme.coldWhite)
                        Text("Yukarıdaki 'Widget Seç' butonuna dokunarak paneline kumaş, ajanda, piyasa veya denizcilik kartlarını ekleyebilirsin.")
                            .font(.caption)
                            .foregroundColor(ErisTheme.coldGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                } else {
                    VStack(spacing: 14) {
                        // Güvenlik Kapısı: Bekleyen onay bileti varsa en üstte göster
                        if safeGate.hasPendingApprovals, let ticket = safeGate.pendingTickets.first(where: { $0.isPending }) {
                            SafeActionBannerView(
                                ticket: ticket,
                                onApprove: { safeGate.approve(ticketId: ticket.id) },
                                onReject: { safeGate.reject(ticketId: ticket.id) }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        if widgetManager.isWidgetEnabled(.commuteTracker) {
                            IOSCommuteCountdownWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.openLoops) {
                            IOSOpenLoopsHubWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.livingChecklists) {
                            IOSLivingChecklistsWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.quickActions) {
                            IOSQuickActionsWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.memoryVault) {
                            IOSMemoryVaultWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.calendar) {
                            IOSCalendarWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.fabricCost) {
                            IOSFabricCostWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.marine) {
                            IOSMarineWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.markets) {
                            IOSMarketsWidgetCard()
                                .transition(.cardReveal)
                        }
                        if widgetManager.isWidgetEnabled(.designIdeas) {
                            IOSDesignIdeasWidgetCard()
                                .transition(.cardReveal)
                        }
                    }
                    .padding(.horizontal, 16)
                    .animation(.cardEntry, value: widgetManager.activeWidgets.count)
                }
            }
            .padding(.bottom, 95)
        }
        .sheet(isPresented: $showWidgetSelector) {
            IOSWidgetSelectorSheet()
        }
    }
}

// 1. Günün Ajandası & Takvim Widget'ı
struct IOSCalendarWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    @State private var events: [ErisCalendarEvent] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .font(.subheadline)
                    Text("GÜNÜN PLANI & AJANDA")
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .tracking(1.0)
                }
                
                Spacer()
                
                Button(action: {
                    appState.playMorningBriefing()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Brifing Dinle")
                    }
                    .font(.caption2).bold()
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(ErisTheme.bronzeHighlight))
                }
            }
            
            if events.isEmpty {
                Text("Bugün için kayıtlı etkinlik yok. 'Hey Eris' diyerek randevu ekleyebilirsin.")
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldGray)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 6) {
                    ForEach(events.prefix(3)) { ev in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(ErisTheme.bronzeHighlight)
                                .frame(width: 6, height: 6)
                            Text(ev.title)
                                .font(.caption).bold()
                                .foregroundColor(ErisTheme.coldWhite)
                                .lineLimit(1)
                            Spacer()
                            Text(ev.startDate, style: .time)
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
        )
        .onAppear {
            events = CalendarCapability.shared.getTodayEvents()
        }
    }
}

// 2. Kumaş Fiyatları & Tedarikçiler Widget'ı
struct IOSFabricCostWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    
    var fabricMemories: [ErisMemoryRecord] {
        appState.memories.filter { $0.category == .fabricCost }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.45))
                        .font(.subheadline)
                    Text("KUMAŞ & TEDARİKÇİ FİYATLARI")
                        .font(.caption).bold()
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.45))
                        .tracking(1.0)
                }
                
                Spacer()
                
                Button(action: {
                    appState.sendUserMessage("Kumaş fiyatlarını listele ve maliyet-fayda dengesini ver.")
                }) {
                    Text("Maliyet Analizi")
                        .font(.caption2).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(red: 0.95, green: 0.75, blue: 0.45)))
                }
            }
            
            if fabricMemories.isEmpty {
                Text("Henüz kumaş fiyatı eklenmedi. 'Osmanbey'den ipek saten metresi 14 dolar fiyat aldım' diyerek anında kaydedebilirsin.")
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldGray)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(fabricMemories.prefix(3)) { mem in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.45))
                                .padding(.top, 4)
                            Text(mem.content)
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldWhite)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.95, green: 0.75, blue: 0.45).opacity(0.2), lineWidth: 0.8))
        )
    }
}

// 3. Deniz & Kaptanlık Raporu Widget'ı
struct IOSMarineWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "water.waves")
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 0.95))
                        .font(.subheadline)
                    Text("DENİZ & SEYİR GÜVENLİĞİ")
                        .font(.caption).bold()
                        .foregroundColor(Color(red: 0.45, green: 0.75, blue: 0.95))
                        .tracking(1.0)
                }
                
                Spacer()
                
                Button(action: {
                    appState.sendUserMessage("Yat seyri öncesi sintine, makine ve meteorolojik riskleri kontrol et, checklist ver.")
                }) {
                    Text("Seyir Listesi")
                        .font(.caption2).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(red: 0.45, green: 0.75, blue: 0.95)))
                }
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.marineInfo.location)
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                    Text("\(Int(appState.marineInfo.airTempCelsius))°C")
                        .font(.title3).bold()
                        .foregroundColor(ErisTheme.coldWhite)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Rüzgar: \(appState.marineInfo.windDirection) \(String(format: "%.1f", appState.marineInfo.windSpeedKnots)) kts")
                        .font(.caption2).bold()
                        .foregroundColor(ErisTheme.coldWhite)
                    Text("Deniz: \(appState.marineInfo.seaCondition) (\(String(format: "%.1f", appState.marineInfo.waveHeightMeters))m)")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.45, green: 0.75, blue: 0.95).opacity(0.2), lineWidth: 0.8))
        )
    }
}

// 4. Finans & Döviz Piyasaları Widget'ı
struct IOSMarketsWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(ErisTheme.listeningGreen)
                        .font(.subheadline)
                    Text("FİNANS & DÖVİZ PİYASALARI")
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.listeningGreen)
                        .tracking(1.0)
                }
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(appState.marketItems) { item in
                    MarketGridItemView(item: item)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.listeningGreen.opacity(0.2), lineWidth: 0.8))
        )
    }
}

struct MarketGridItemView: View {
    let item: MarketItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.symbol)
                    .font(.caption2).bold()
                    .foregroundColor(ErisTheme.coldWhite)
                Text(item.price)
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldWhite.opacity(0.85))
            }
            Spacer()
            Text(item.change)
                .font(.caption2).bold()
                .foregroundColor(item.isPositive ? ErisTheme.listeningGreen : .red.opacity(0.85))
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
    }
}

// 5. Tasarım & Koleksiyon Fikirleri Widget'ı
struct IOSDesignIdeasWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    
    var designMemories: [ErisMemoryRecord] {
        appState.memories.filter { $0.category == .designIdea }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color(red: 0.75, green: 0.60, blue: 0.95))
                        .font(.subheadline)
                    Text("TASARIM & KOLEKSİYON FİKİRLERİ")
                        .font(.caption).bold()
                        .foregroundColor(Color(red: 0.75, green: 0.60, blue: 0.95))
                        .tracking(1.0)
                }
                Spacer()
            }
            
            if designMemories.isEmpty {
                Text("Henüz tasarım fikri kaydedilmedi. 'Elimde şöyle bir drape fikri var' diyerek beyin fırtınası yapabilirsin.")
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldGray)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(designMemories.prefix(2)) { mem in
                        Text("• \(mem.content)")
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldWhite)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.75, green: 0.60, blue: 0.95).opacity(0.2), lineWidth: 0.8))
        )
    }
}

// 6. Hızlı Sesli Eylemler Widget'ı
struct IOSQuickActionsWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .font(.subheadline)
                Text("HIZLI SESLİ EYLEMLER")
                    .font(.caption).bold()
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .tracking(1.0)
            }
            
            HStack(spacing: 8) {
                Button(action: {
                    appState.toggleListening()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                        Text("Hey Eris")
                            .font(.caption2).bold()
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ErisTheme.bronzeHighlight))
                }
                
                Button(action: {
                    appState.playMorningBriefing()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .font(.caption)
                        Text("Brifing")
                            .font(.caption2).bold()
                    }
                    .foregroundColor(ErisTheme.coldWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                }
                
                Button(action: {
                    appState.sendUserMessage("Kumaş fiyatlarını listele")
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption)
                        Text("Kumaşlar")
                            .font(.caption2).bold()
                    }
                    .foregroundColor(ErisTheme.coldWhite)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
        )
    }
}

// Widget Seçim Modal / Sheet
struct IOSWidgetSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var widgetManager = ErisWidgetManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Kişisel Panel & iOS Widget'ları").font(.subheadline)) {
                    Text("iPhone ana ekranında, kilit ekranında ve uygulama içi panelinde görünmesini istediğin widget'ları buradan açıp kapatabilirsin:")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                    
                    ForEach(ErisWidgetType.allCases) { type in
                        HStack(spacing: 12) {
                            Image(systemName: type.icon)
                                .font(.headline)
                                .foregroundColor(widgetManager.isWidgetEnabled(type) ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                                .frame(width: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.title)
                                    .font(.subheadline).bold()
                                    .foregroundColor(ErisTheme.coldWhite)
                                Text(type.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { widgetManager.isWidgetEnabled(type) },
                                set: { _ in widgetManager.toggleWidget(type) }
                            ))
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button("Tüm Widget'ları Aktif Et") {
                        widgetManager.resetToDefaults()
                    }
                }
            }
            .navigationTitle("Widget Seçimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Notlar & Dosyalar Kasası Widget'ı
struct IOSMemoryVaultWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                    Text("NOTLAR & DOSYALAR KASASI")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(ErisTheme.bronzeHighlight)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        appState.selectedTab = .memory
                    }
                }) {
                    HStack(spacing: 3) {
                        Text("Tümü (\(appState.memories.count))")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption2).bold()
                    .foregroundColor(ErisTheme.coldWhite)
                }
            }
            
            if appState.memories.isEmpty {
                Text("Henüz kayıtlı bir not yok. Sesli konuşurken Eris önemli bilgileri otomatik kasanıza kaydeder.")
                    .font(.caption)
                    .foregroundColor(ErisTheme.coldGray)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 6) {
                    ForEach(appState.memories.prefix(3)) { record in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: record.category.icon)
                                .font(.caption)
                                .foregroundColor(ErisTheme.bronzeHighlight)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(record.title)
                                        .font(.caption).bold()
                                        .foregroundColor(ErisTheme.coldWhite)
                                        .lineLimit(1)
                                    
                                    if record.source == "voice" {
                                        Text("Ses")
                                            .font(.system(size: 8, weight: .semibold))
                                            .padding(.horizontal, 4).padding(.vertical, 1)
                                            .background(Capsule().fill(Color.purple.opacity(0.2)))
                                            .foregroundColor(Color(red: 0.75, green: 0.60, blue: 0.95))
                                    }
                                }
                                Text(record.content)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldGray)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - 8. Dinamik Rota & Çıkış Sayacı Widget'ı (Life OS Pillar 1 & 3)

struct IOSCommuteCountdownWidgetCard: View {
    @State private var countdownSeconds: Int = 878 // 14 dk 38 sn
    @State private var timerActive = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .font(.subheadline)
                    Text("DİNAMİK ROTA & ÇIKIŞ SAYACI")
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .tracking(1.0)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(ErisTheme.listeningGreen)
                        .frame(width: 6, height: 6)
                    Text("ROTA OPTİMAL")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ErisTheme.listeningGreen)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(ErisTheme.listeningGreen.opacity(0.15)))
            }
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ev → Ofis & Atölye")
                        .font(.subheadline).bold()
                        .foregroundColor(ErisTheme.coldWhite)
                    Text("Canlı Trafik: Akıcı • Tahmini Varış: 09:20")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("ÇIKIŞA KALAN")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(ErisTheme.thinkingAmber)
                    
                    Text(formattedCountdown)
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(ErisTheme.thinkingAmber)
                }
            }
            
            Divider().background(ErisTheme.bronzeAccent.opacity(0.2))
            
            HStack(spacing: 8) {
                Label("Kadıköy → Levent", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldGray)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "fuelpump.fill")
                    Text("Yakıt ikmali rotaya eklendi")
                }
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(ErisTheme.bronzeHighlight)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(ErisTheme.bronzeAccent.opacity(0.12)))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8)
                )
        )
    }
    
    private var formattedCountdown: String {
        let minutes = countdownSeconds / 60
        let seconds = countdownSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 9. Açık Döngüler (Zihinsel Berraklık) Hub Widget'ı (Life OS Pillar 2 & 8)

struct IOSOpenLoopsHubWidgetCard: View {
    @ObservedObject var openLoopsEngine = ErisOpenLoopsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                        .foregroundColor(ErisTheme.thinkingAmber)
                        .font(.subheadline)
                    Text("AÇIK DÖNGÜLER (ZİHİNSEL BERRAKLIK)")
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.thinkingAmber)
                        .tracking(1.0)
                }
                
                Spacer()
                
                Text("\(openLoopsEngine.pendingCount) Askıda İş")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ErisTheme.thinkingAmber)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(ErisTheme.thinkingAmber.opacity(0.15)))
            }
            
            Text("Konuşmalardan, takvimden ve kasadan tespit edilen açık taahhütler:")
                .font(.caption2)
                .foregroundColor(ErisTheme.coldGray)
            
            VStack(spacing: 8) {
                ForEach(openLoopsEngine.activeLoops.prefix(3)) { loop in
                    OpenLoopCardView(
                        loop: loop,
                        onComplete: { openLoopsEngine.completeLoop(id: loop.id) },
                        onDismiss: { openLoopsEngine.dismissLoop(id: loop.id) }
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ErisTheme.thinkingAmber.opacity(0.25), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - 10. Yaşayan Checklists Widget'ı (Life OS Pillar 4 & 6)

struct IOSLivingChecklistsWidgetCard: View {
    @EnvironmentObject var appState: ErisIOSState
    @ObservedObject var checklistEngine = ErisLivingChecklistEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "suitcase.fill")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .font(.subheadline)
                    Text(L10n.livingChecklistsTitle.uppercased())
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .tracking(1.0)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        appState.selectedTab = .checklists
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(L10n.seeAll)
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ErisTheme.bronzeAccent.opacity(0.18)))
                }
                .buttonStyle(.plain)
            }
            
            if let activeList = checklistEngine.checklists.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activeList.title)
                                .font(.subheadline).bold()
                                .foregroundColor(ErisTheme.coldWhite)
                            
                            if let note = activeList.weatherNote {
                                Text(note)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.thinkingAmber)
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(activeList.completedCount)/\(activeList.items.count)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    // İlerleme Çubuğu
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ErisTheme.graphiteSurface)
                                .frame(height: 4)
                            Capsule()
                                .fill(ErisTheme.listeningGreen)
                                .frame(width: geo.size.width * CGFloat(activeList.progressFraction), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    // İlk 3 Madde
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(activeList.items.prefix(3)) { item in
                            Button(action: {
                                checklistEngine.toggleItem(checklistId: activeList.id, itemId: item.id)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 13))
                                        .foregroundColor(item.isCompleted ? ErisTheme.listeningGreen : ErisTheme.coldGray)
                                    
                                    Text(item.title)
                                        .font(.caption)
                                        .foregroundColor(item.isCompleted ? ErisTheme.coldGray : ErisTheme.coldWhite)
                                        .strikethrough(item.isCompleted)
                                    
                                    Spacer()
                                    
                                    if let cat = item.category {
                                        Text(cat)
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundColor(ErisTheme.coldGray)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8)
                )
        )
    }
}

