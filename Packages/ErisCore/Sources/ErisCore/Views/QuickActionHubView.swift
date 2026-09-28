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
    
    public var body: some View {
        VStack(spacing: 16) {
            // Karşılama Başlığı
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(ErisTheme.bronzeHighlight.opacity(0.12))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 26))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .shadow(color: ErisTheme.bronzeHighlight.opacity(0.4), radius: 8)
                }
                
                Text(L10n.howCanIHelp)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(ErisTheme.coldWhite)
                
                Text("Eris, gününüzü ve işlerinizi proaktif olarak organize eder.")
                    .font(.system(size: 12))
                    .foregroundColor(ErisTheme.coldGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
            
            // Hero Kartı: Sabah Brifingi
            Button(action: {
                onSelectAction(.morningBriefing)
            }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.98, green: 0.75, blue: 0.28), Color(red: 0.95, green: 0.55, blue: 0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(L10n.morningBriefingTitle)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(ErisTheme.coldWhite)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.system(size: 10))
                                Text("Dinle")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color(red: 0.98, green: 0.75, blue: 0.28)))
                        }
                        
                        Text(L10n.morningBriefingSubtitle)
                            .font(.system(size: 11.5))
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
                                .stroke(Color(red: 0.98, green: 0.75, blue: 0.28).opacity(0.35), lineWidth: 0.8)
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
                    badge: "Kasa",
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
