//
//  QuickActionHubView.swift
//  ErisCore — Hızlı Eylemler & Sezgisel Başlangıç Merkezi
//

import SwiftUI

public enum ErisQuickActionType: String, CaseIterable, Identifiable {
    case morningBriefing
    case quickNote
    case openLoops
    case livingLists
    case habitsGoals
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .morningBriefing: return L10n.morningBriefingTitle
        case .quickNote: return L10n.quickNoteTitle
        case .openLoops: return L10n.openLoopsTitle
        case .livingLists: return L10n.livingListsTitle
        case .habitsGoals: return L10n.habitsGoalsTitle
        }
    }
    
    public var subtitle: String {
        switch self {
        case .morningBriefing: return L10n.morningBriefingSubtitle
        case .quickNote: return L10n.quickNoteSubtitle
        case .openLoops: return L10n.openLoopsSubtitle
        case .livingLists: return L10n.livingListsSubtitle
        case .habitsGoals: return L10n.habitsGoalsSubtitle
        }
    }
    
    public var icon: String {
        switch self {
        case .morningBriefing: return "sun.max.fill"
        case .quickNote: return "brain.head.profile"
        case .openLoops: return "arrow.triangle.2.circlepath.circle.fill"
        case .livingLists: return "checklist.checked"
        case .habitsGoals: return "flame.fill"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .morningBriefing: return Color(red: 0.98, green: 0.75, blue: 0.28)
        case .quickNote: return ErisTheme.categoryFabric
        case .openLoops: return ErisTheme.thinkingAmber
        case .livingLists: return ErisTheme.categoryTechnical
        case .habitsGoals: return Color(red: 0.95, green: 0.45, blue: 0.35)
        }
    }
}

/// Sohbet giriş alanının üzerinde sürekli hazır bulunan hızlı öneri hapları
public struct ErisPromptSuggestionsBar: View {
    public struct PromptItem: Identifiable {
        public let id = UUID()
        public let icon: String
        public let label: String
        public let promptText: String
        public let color: Color
        
        public init(icon: String, label: String, promptText: String, color: Color) {
            self.icon = icon
            self.label = label
            self.promptText = promptText
            self.color = color
        }
    }
    
    public let onSelectPrompt: (String) -> Void
    
    public init(onSelectPrompt: @escaping (String) -> Void) {
        self.onSelectPrompt = onSelectPrompt
    }
    
    private var defaultPrompts: [PromptItem] {
        [
            PromptItem(
                icon: "sun.max.fill",
                label: L10n.morningBriefingTitle,
                promptText: L10n.promptPlanToday,
                color: Color(red: 0.98, green: 0.75, blue: 0.28)
            ),
            PromptItem(
                icon: "arrow.triangle.2.circlepath",
                label: L10n.openLoopsTitle,
                promptText: L10n.promptListOpenLoops,
                color: ErisTheme.thinkingAmber
            ),
            PromptItem(
                icon: "cart.fill",
                label: "Market & Kiler",
                promptText: L10n.promptShowGrocery,
                color: ErisTheme.categoryTechnical
            ),
            PromptItem(
                icon: "brain.head.profile",
                label: "Hafıza & Notlar",
                promptText: L10n.promptTakeNote,
                color: ErisTheme.categoryFabric
            ),
            PromptItem(
                icon: "flame.fill",
                label: L10n.habitsGoalsTitle,
                promptText: L10n.promptCheckHabits,
                color: Color(red: 0.95, green: 0.45, blue: 0.35)
            ),
            PromptItem(
                icon: "water.waves",
                label: "Hava & Deniz",
                promptText: L10n.promptWeatherMarine,
                color: Color(red: 0.45, green: 0.75, blue: 0.95)
            )
        ]
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(defaultPrompts) { item in
                    Button(action: {
                        onSelectPrompt(item.promptText)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: item.icon)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(item.color)
                            Text(item.label)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(ErisTheme.coldWhite)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    Capsule()
                                        .stroke(item.color.opacity(0.28), lineWidth: 0.7)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }
}

/// Karşılama ve Boş Ekran için Hızlı Eylemler Paneli
public struct ErisQuickActionHubView: View {
    public let onSelectAction: (ErisQuickActionType) -> Void
    public let onSelectPrompt: (String) -> Void
    
    @ObservedObject private var openLoopsEngine = ErisOpenLoopsEngine.shared
    @ObservedObject private var checklistEngine = ErisLivingChecklistEngine.shared
    @ObservedObject private var habitsService = ErisHabitsGoalsService.shared
    
    public init(
        onSelectAction: @escaping (ErisQuickActionType) -> Void,
        onSelectPrompt: @escaping (String) -> Void
    ) {
        self.onSelectAction = onSelectAction
        self.onSelectPrompt = onSelectPrompt
    }
    
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Günaydın"
        case 12..<18: return "İyi Günler"
        case 18..<23: return "İyi Akşamlar"
        default: return "İyi Geceler"
        }
    }
    
    private var isDaytime: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 6 && hour < 20
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM EEEE"
        return formatter.string(from: Date())
    }
    
    private var weatherInfo: MarineWeatherInfo {
        ExternalDataService.shared.getMarineWeather()
    }
    
    private var totalMemoriesCount: Int {
        ErisMemoryDatabase.shared.getAllMemories().count
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Karşılama Başlığı & Canlı Durum
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(ErisTheme.bronzeHighlight.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 24))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .shadow(color: ErisTheme.bronzeHighlight.opacity(0.4), radius: 8)
                }
                
                VStack(spacing: 4) {
                    Text("\(timeGreeting) • Eris Hazır")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    HStack(spacing: 6) {
                        Text(formattedDate)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(ErisTheme.coldGray)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.5))
                        
                        HStack(spacing: 3) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 9.5))
                                .foregroundColor(Color(red: 0.5, green: 0.75, blue: 0.95))
                            Text("\(Int(weatherInfo.airTempCelsius))°C • \(weatherInfo.location.components(separatedBy: ",").first ?? "İstanbul")")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(ErisTheme.coldWhite.opacity(0.85))
                        }
                    }
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 16)
            
            // Hero Kartı: Dinamik Sabah / Gün Brifingi
            Button(action: {
                onSelectAction(.morningBriefing)
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: isDaytime
                                    ? [Color(red: 0.98, green: 0.75, blue: 0.28), Color(red: 0.95, green: 0.55, blue: 0.2)]
                                    : [Color(red: 0.45, green: 0.45, blue: 0.85), Color(red: 0.25, green: 0.25, blue: 0.65)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: isDaytime ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isDaytime ? .black : .white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(isDaytime ? L10n.morningBriefingTitle : "Günün Özeti & Brifing")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ErisTheme.coldWhite)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 10))
                                Text("Dinle")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(isDaytime ? .black : .white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(isDaytime ? Color(red: 0.98, green: 0.75, blue: 0.28) : Color(red: 0.45, green: 0.45, blue: 0.85)))
                        }
                        
                        Text("\(Int(weatherInfo.airTempCelsius))°C • \(openLoopsEngine.pendingCount) açık iş • \(checklistEngine.checklists.count) liste • Dinlemek için dokunun")
                            .font(.system(size: 11))
                            .foregroundColor(ErisTheme.coldGray)
                            .lineLimit(1)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke((isDaytime ? Color(red: 0.98, green: 0.75, blue: 0.28) : Color(red: 0.45, green: 0.45, blue: 0.85)).opacity(0.35), lineWidth: 0.8)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            
            // 2x2 Hızlı Eylem Kartları Izgarası
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                // Açık İşlerim
                QuickActionCard(
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    color: ErisTheme.thinkingAmber,
                    title: L10n.openLoopsTitle,
                    badge: "\(openLoopsEngine.pendingCount) Askıda",
                    description: "Bekleyen işleri tamamla",
                    action: { onSelectAction(.openLoops) }
                )
                
                // Yaşayan Listeler
                QuickActionCard(
                    icon: "checklist.checked",
                    color: ErisTheme.categoryTechnical,
                    title: L10n.livingListsTitle,
                    badge: "\(checklistEngine.checklists.count) Liste",
                    description: "Market, bavul ve ev rutinleri",
                    action: { onSelectAction(.livingLists) }
                )
                
                // Hızlı Not & Kasa
                QuickActionCard(
                    icon: "brain.head.profile",
                    color: ErisTheme.categoryFabric,
                    title: L10n.quickNoteTitle,
                    badge: "\(totalMemoriesCount) Kayıt",
                    description: "Önemli bilgileri kaydet",
                    action: { onSelectAction(.quickNote) }
                )
                
                // Alışkanlıklar & Hedefler
                QuickActionCard(
                    icon: "flame.fill",
                    color: Color(red: 0.95, green: 0.45, blue: 0.35),
                    title: L10n.habitsGoalsTitle,
                    badge: "\(habitsService.habits.filter { $0.isCompletedToday }.count)/\(habitsService.habits.count)",
                    description: "Günün hedeflerini tamamla",
                    action: { onSelectAction(.habitsGoals) }
                )
            }
            .padding(.horizontal, 16)
            
            // Hızlı Başlangıç İpuçları
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                    Text("ÖRNEK SORULAR & TALİMATLAR")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(ErisTheme.coldGray)
                }
                .padding(.horizontal, 16)
                
                ErisPromptSuggestionsBar(onSelectPrompt: onSelectPrompt)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: 580)
        .padding(.vertical, 12)
    }
}

/// Bireysel Hızlı Eylem Kartı
private struct QuickActionCard: View {
    let icon: String
    let color: Color
    let title: String
    let badge: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(color.opacity(0.16)))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(ErisTheme.coldWhite)
                        .lineLimit(1)
                    
                    Text(description)
                        .font(.system(size: 10.5))
                        .foregroundColor(ErisTheme.coldGray)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(color.opacity(0.2), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
