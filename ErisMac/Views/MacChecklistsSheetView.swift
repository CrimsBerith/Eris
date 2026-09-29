import SwiftUI
import ErisCore

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
