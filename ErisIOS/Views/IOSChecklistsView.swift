//
//  IOSChecklistsView.swift
//  ErisIOS
//
//  Created by Antigravity on 2026-09-28.
//

import SwiftUI
import ErisCore

struct IOSChecklistsView: View {
    @ObservedObject var checklistEngine = ErisLivingChecklistEngine.shared
    @State private var selectedFilter: ChecklistType? = nil
    @State private var showNewChecklistSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Üst Başlık & Filtreler
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yaşayan Listeler")
                                .font(.title3).bold()
                                .foregroundColor(ErisTheme.coldWhite)
                            Text("Hava durumu ve takvime göre uyarlanan dinamik hazırlıklar")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Spacer()
                        
                        // Yeni Liste Oluştur Butonu
                        Button(action: { showNewChecklistSheet = true }) {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                Text("Yeni Liste")
                            }
                            .font(.caption).bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(ErisTheme.bronzeHighlight)
                            )
                            .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Yatay Filtre Pill'leri
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterPill(title: "Tümü (\(checklistEngine.checklists.count))", icon: "square.grid.2x2", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            ForEach(ChecklistType.allCases, id: \.self) { type in
                                let count = checklistEngine.checklists.filter { $0.type == type }.count
                                FilterPill(title: "\(type.displayName) (\(count))", icon: type.icon, isSelected: selectedFilter == type) {
                                    selectedFilter = type
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(ErisTheme.graphite.opacity(0.95))
                
                // Liste İçeriği
                ScrollView {
                    if filteredChecklists.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.system(size: 40))
                                .foregroundColor(ErisTheme.coldGray.opacity(0.5))
                                .padding(.top, 50)
                            Text("Bu filtrede aktif liste bulunmuyor")
                                .font(.subheadline).bold()
                                .foregroundColor(ErisTheme.coldWhite)
                            Text("Sağ üstteki 'Yeni Liste' butonuna dokunarak hemen seyahat, kiler veya ev rutini listesi ekleyebilirsin.")
                                .font(.caption)
                                .foregroundColor(ErisTheme.coldGray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(filteredChecklists) { checklist in
                                ChecklistCardDetail(
                                    checklist: checklist,
                                    onToggleItem: { itemId in
                                        checklistEngine.toggleItem(checklistId: checklist.id, itemId: itemId)
                                    },
                                    onAddItem: { title in
                                        checklistEngine.addItem(checklistId: checklist.id, title: title)
                                    },
                                    onDeleteItem: { itemId in
                                        checklistEngine.deleteItem(checklistId: checklist.id, itemId: itemId)
                                    },
                                    onDeleteChecklist: {
                                        checklistEngine.deleteChecklist(id: checklist.id)
                                    },
                                    onClearCompleted: {
                                        checklistEngine.clearCompletedItems(checklistId: checklist.id)
                                    },
                                    onCompleteAll: {
                                        checklistEngine.completeAllItems(checklistId: checklist.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, 95)
                    }
                }
            }
            .background(ErisTheme.backgroundGradient.ignoresSafeArea())
            .sheet(isPresented: $showNewChecklistSheet) {
                IOSNewChecklistSheet()
            }
        }
    }
    
    private var filteredChecklists: [LivingChecklist] {
        if let filter = selectedFilter {
            return checklistEngine.checklists.filter { $0.type == filter }
        }
        return checklistEngine.checklists
    }
}

// MARK: - Filtre Hapı
private struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .font(.caption2).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(isSelected ? ErisTheme.bronzeHighlight : Color.white.opacity(0.06))
            )
            .foregroundColor(isSelected ? .black : ErisTheme.coldWhite)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detaylı Checklist Kartı
private struct ChecklistCardDetail: View {
    let checklist: LivingChecklist
    let onToggleItem: (UUID) -> Void
    let onAddItem: (String) -> Void
    let onDeleteItem: (UUID) -> Void
    let onDeleteChecklist: () -> Void
    let onClearCompleted: () -> Void
    let onCompleteAll: () -> Void
    
    @State private var newItemText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: checklist.type.icon)
                        .font(.headline)
                        .foregroundColor(ErisTheme.bronzeHighlight)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(checklist.title)
                            .font(.subheadline).bold()
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        if let city = checklist.destinationCity {
                            Text("Hedef: \(city)")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                    }
                }
                
                Spacer()
                
                // Tamamlanma Sayacı
                Text("\(checklist.completedCount)/\(checklist.items.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(checklist.progressFraction == 1.0 ? ErisTheme.listeningGreen : ErisTheme.thinkingAmber)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                
                // Menü
                Menu {
                    Button(action: onCompleteAll) {
                        Label("Tümünü Tamamla", systemImage: "checkmark.circle.fill")
                    }
                    Button(action: onClearCompleted) {
                        Label("Tamamlananları Temizle", systemImage: "trash.slash")
                    }
                    Divider()
                    Button(role: .destructive, action: onDeleteChecklist) {
                        Label("Listeyi Sil", systemImage: "trash.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundColor(ErisTheme.coldGray)
                }
            }
            
            // Hava Durumu Notu (Seyahat bavul listeleri için)
            if let weather = checklist.weatherNote {
                HStack(spacing: 6) {
                    Image(systemName: "cloud.rain.fill")
                        .foregroundColor(ErisTheme.thinkingAmber)
                    Text(weather)
                        .font(.caption2)
                        .foregroundColor(ErisTheme.thinkingAmber)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(ErisTheme.thinkingAmber.opacity(0.12)))
            }
            
            // İlerleme Çubuğu
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06)).frame(height: 5)
                    Capsule()
                        .fill(checklist.progressFraction == 1.0 ? ErisTheme.listeningGreen : ErisTheme.bronzeHighlight)
                        .frame(width: geo.size.width * CGFloat(checklist.progressFraction), height: 5)
                }
            }
            .frame(height: 5)
            
            // Maddeler
            VStack(spacing: 8) {
                ForEach(checklist.items) { item in
                    HStack(spacing: 10) {
                        Button(action: { onToggleItem(item.id) }) {
                            HStack(spacing: 8) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 16))
                                    .foregroundColor(item.isCompleted ? ErisTheme.listeningGreen : ErisTheme.coldGray)
                                
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundColor(item.isCompleted ? ErisTheme.coldGray : ErisTheme.coldWhite)
                                    .strikethrough(item.isCompleted)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        if let category = item.category {
                            Text(category)
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.white.opacity(0.05)))
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Button(action: { onDeleteItem(item.id) }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 4)
            
            // Hızlı Madde Ekleme
            HStack(spacing: 8) {
                TextField("Yeni madde ekle...", text: $newItemText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(8)
                    .foregroundColor(ErisTheme.coldWhite)
                    .onSubmit {
                        submitNewItem()
                    }
                
                Button(action: submitNewItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
                .disabled(newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 4)
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
    
    private func submitNewItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddItem(trimmed)
        newItemText = ""
    }
}

// MARK: - iOS Yeni Liste Oluşturma Sayfası (Sheet)

struct IOSNewChecklistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var checklistEngine = ErisLivingChecklistEngine.shared
    
    @State private var title: String = ""
    @State private var type: ChecklistType = .travelPacking
    @State private var destinationCity: String = ""
    @State private var weatherNote: String = ""
    @State private var itemsText: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("LİSTE BİLGİLERİ").font(.caption).foregroundColor(ErisTheme.bronzeHighlight)) {
                    TextField("Liste Başlığı (Örn: Paris Moda Haftası)", text: $title)
                    
                    Picker("Tür", selection: $type) {
                        ForEach(ChecklistType.allCases, id: \.self) { item in
                            HStack {
                                Image(systemName: item.icon)
                                Text(item.displayName)
                            }
                            .tag(item)
                        }
                    }
                }
                
                if type == .travelPacking {
                    Section(header: Text("SEYAHAT DETAYLARI").font(.caption).foregroundColor(ErisTheme.bronzeHighlight)) {
                        TextField("Hedef Şehir (Örn: Londra, Tokyo)", text: $destinationCity)
                        TextField("Hava Durumu Notu (Örn: 15°C Yağmurlu)", text: $weatherNote)
                    }
                }
                
                Section(header: Text("BAŞLANGIÇ MADDELERİ").font(.caption).foregroundColor(ErisTheme.bronzeHighlight), footer: Text("Maddeleri virgülle (,) ayırarak toplu girebilirsiniz.")) {
                    TextField("Örn: Pasaport, Şarj adaptörü, Cüzdan", text: $itemsText, axis: .vertical)
                        .lineLimit(3...5)
                    
                    Button(action: prefillPresetItems) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Önerilen Şablon Maddeleri Yükle")
                        }
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.bronzeHighlight)
                    }
                }
            }
            .navigationTitle("Yeni Yaşayan Liste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Oluştur") {
                        saveChecklist()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func prefillPresetItems() {
        switch type {
        case .travelPacking:
            itemsText = "Bordo Pasaport, Şarj adaptörü & powerbank, Kulaklık, Güneş gözlüğü, Kişisel bakım kiti"
        case .groceryPantry:
            itemsText = "Organik zeytinyağı, Badem sütü, Kahve çekirdeği, Yumurta, Ekmek"
        case .relocationMoving:
            itemsText = "İnternet abonelik nakli, Elektrik/su devri, Koli bantları, Eşya sigortası, Adres beyanı"
        case .homeChores:
            itemsText = "Su filtresi değişimi, Çöp tasnifi, Robot süpürge hazne temizliği, Havalandırma"
        case .eventPreparation:
            itemsText = "Menü planı, Müzik çalma listesi, İçecek ve buz takviyesi, Sofra düzeni"
        case .vehicleMaintenance:
            itemsText = "Lastik hava basıncı kontrolü, Motor yağı & cam suyu, İlk yardım çantası, Trafik seti"
        case .custom:
            itemsText = "Öncelikli görev, Kontrol adımı, Not ve takip"
        }
    }
    
    private func saveChecklist() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let rawItems = itemsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let itemsToUse = rawItems.isEmpty ? ["İlk hazırlık maddesi"] : rawItems
        
        checklistEngine.createChecklist(
            title: trimmed,
            type: type,
            items: itemsToUse,
            destinationCity: destinationCity.isEmpty ? nil : destinationCity,
            weatherNote: weatherNote.isEmpty ? nil : weatherNote
        )
        dismiss()
    }
}
