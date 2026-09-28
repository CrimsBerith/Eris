//
//  IOSMemoryView.swift
//  ErisIOS
//
//  Created by Antigravity on 2026-09-28.
//

import SwiftUI
import ErisCore

// MARK: - Notlar & Dosyalar Kasası (Notes & Files Vault)
struct IOSMemoryView: View {
    @EnvironmentObject var appState: ErisIOSState
    @ObservedObject var vaultDocService = ErisVaultDocumentService.shared
    
    @State private var searchText: String = ""
    @State private var filterCategory: MemoryCategory? = nil
    @State private var filterSource: String? = nil // nil = Tümü, "voice", "chat", "manual"
    @State private var showVaultDocsOnly: Bool = false
    @State private var showingNewNoteSheet: Bool = false
    @State private var showingNewVaultDocSheet: Bool = false
    @State private var editingMemory: ErisMemoryRecord? = nil
    @State private var editingVaultDoc: VaultDocumentRecord? = nil
    @State private var shareURL: URL? = nil
    @State private var showingShareSheet: Bool = false
    @State private var copiedNoteId: String? = nil
    
    // Filtrelenmiş notlar
    var filteredMemories: [ErisMemoryRecord] {
        var items = appState.memories
        
        // Arama filtresi
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(query) ||
                $0.content.lowercased().contains(query) ||
                $0.category.displayName.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) }) ||
                ($0.fileName?.lowercased().contains(query) ?? false)
            }
        }
        
        // Kategori filtresi
        if let cat = filterCategory {
            items = items.filter { $0.category == cat }
        }
        
        // Kaynak filtresi
        if let src = filterSource {
            items = items.filter { $0.source.lowercased() == src.lowercased() }
        }
        
        return items
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Başlık & Hızlı İstatistikler & Dışa Aktar Butonu
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill.badge.gearshape")
                                    .font(.title3)
                                    .foregroundColor(ErisTheme.bronzeHighlight)
                                Text("Notlar & Dosyalar")
                                    .font(.title2).bold()
                                    .foregroundColor(ErisTheme.coldWhite)
                            }
                            Text("Sesli konuşmalardan yakalanan bilgiler, teknik notlar ve belgeler")
                                .font(.caption)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Spacer()
                        
                        // Yeni Not & Evrak Ekleme Menüsü
                        Menu {
                            Button(action: { showingNewNoteSheet = true }) {
                                Label("Yeni Not Ekle", systemImage: "doc.text.fill")
                            }
                            Button(action: { showingNewVaultDocSheet = true }) {
                                Label("Yeni Resmî Belge / Kasa", systemImage: "person.text.rectangle.fill")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Yeni")
                            }
                            .font(.caption).bold()
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(ErisTheme.bronzeHighlight)
                            )
                            .foregroundColor(.black)
                        }
                    }
                    
                    // İstatistik Pilleri
                    HStack(spacing: 8) {
                        StatBadge(label: "Toplam", count: appState.memories.count, icon: "doc.text.fill", color: ErisTheme.coldWhite)
                        StatBadge(label: "Sesli", count: appState.memories.filter { $0.source == "voice" }.count, icon: "mic.fill", color: Color(red: 0.65, green: 0.55, blue: 0.95))
                        StatBadge(label: "Sabitli", count: appState.memories.filter { $0.pinned }.count, icon: "pin.fill", color: Color(red: 0.95, green: 0.75, blue: 0.45))
                        
                        Spacer()
                        
                        // Tümünü Dışa Aktar (.md)
                        Button(action: exportAllNotes) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Dışa Aktar")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                            .foregroundColor(ErisTheme.coldWhite)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 10)
                
                // 2. Arama Çubuğu
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ErisTheme.coldGray)
                    
                    TextField("Notlarda, etiketlerde veya dosyalarda ara...", text: $searchText)
                        .font(.subheadline)
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(ErisTheme.coldGray)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(ErisTheme.bronzeAccent.opacity(0.25), lineWidth: 0.8)
                        )
                )
                
                // 2.5 Proaktif Belge & Süre Takibi Uyarısı (Bölüm 27, 28, 29)
                let expiringDocs = vaultDocService.getExpiringDocuments(withinDays: 180)
                if !expiringDocs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(ErisTheme.thinkingAmber)
                                .font(.caption)
                            Text("SÜRE TAKİBİ • YAKLAŞAN BİTİŞLER")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(ErisTheme.thinkingAmber)
                            Spacer()
                            Text("\(expiringDocs.count) Belge")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(ErisTheme.thinkingAmber)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(ErisTheme.thinkingAmber.opacity(0.15)))
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(expiringDocs) { doc in
                                    HStack(spacing: 8) {
                                        Image(systemName: doc.category.icon)
                                            .foregroundColor(ErisTheme.bronzeHighlight)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(doc.title)
                                                .font(.caption).bold()
                                                .foregroundColor(ErisTheme.coldWhite)
                                            if let exp = doc.expirationDate ?? doc.warrantyEndDate {
                                                Text("Son: \(exp.formatted(date: .numeric, time: .omitted))")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(ErisTheme.coldGray)
                                            }
                                        }
                                        
                                        Button(action: { editingVaultDoc = doc }) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 11))
                                                .foregroundColor(ErisTheme.bronzeHighlight)
                                                .padding(4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ErisTheme.thinkingAmber.opacity(0.3), lineWidth: 0.8))
                                    )
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(ErisTheme.thinkingAmber.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ErisTheme.thinkingAmber.opacity(0.2), lineWidth: 0.8))
                    )
                }
                
                // 3. Kategori Klasör Filtreleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryPill(
                            title: "Tümü (\(appState.memories.count))",
                            icon: "tray.full.fill",
                            isSelected: !showVaultDocsOnly && filterCategory == nil,
                            color: ErisTheme.bronzeHighlight,
                            action: {
                                showVaultDocsOnly = false
                                filterCategory = nil
                            }
                        )
                        
                        CategoryPill(
                            title: "Resmî Kasa (\(vaultDocService.documents.count))",
                            icon: "shield.lefthalf.filled",
                            isSelected: showVaultDocsOnly,
                            color: ErisTheme.bronzeHighlight,
                            action: {
                                showVaultDocsOnly = true
                                filterCategory = nil
                            }
                        )
                        
                        CategoryPill(
                            title: "Belgeler",
                            icon: "doc.text.fill",
                            isSelected: !showVaultDocsOnly && filterCategory == .document,
                            color: Color(red: 0.45, green: 0.75, blue: 0.95),
                            action: {
                                showVaultDocsOnly = false
                                toggleCategoryFilter(.document)
                            }
                        )
                        
                        CategoryPill(
                            title: "Teknik",
                            icon: "curlybraces",
                            isSelected: !showVaultDocsOnly && filterCategory == .technical,
                            color: Color(red: 0.45, green: 0.90, blue: 0.65),
                            action: {
                                showVaultDocsOnly = false
                                toggleCategoryFilter(.technical)
                            }
                        )
                        
                        CategoryPill(
                            title: "Finans",
                            icon: "chart.line.uptrend.xyaxis",
                            isSelected: !showVaultDocsOnly && filterCategory == .finance,
                            color: Color(red: 0.95, green: 0.80, blue: 0.35),
                            action: {
                                showVaultDocsOnly = false
                                toggleCategoryFilter(.finance)
                            }
                        )
                        
                        CategoryPill(
                            title: "Tasarım",
                            icon: "lightbulb.fill",
                            isSelected: !showVaultDocsOnly && filterCategory == .designIdea,
                            color: Color(red: 0.75, green: 0.60, blue: 0.95),
                            action: {
                                showVaultDocsOnly = false
                                toggleCategoryFilter(.designIdea)
                            }
                        )
                        
                        CategoryPill(
                            title: "Projeler",
                            icon: "checklist",
                            isSelected: !showVaultDocsOnly && filterCategory == .project,
                            color: Color(red: 0.95, green: 0.60, blue: 0.45),
                            action: {
                                showVaultDocsOnly = false
                                toggleCategoryFilter(.project)
                            }
                        )
                        
                        CategoryPill(
                            title: "Kişiler",
                            icon: "person.crop.circle",
                            isSelected: !showVaultDocsOnly && filterCategory == .person,
                            color: Color(red: 0.45, green: 0.85, blue: 0.85),
                            action: {
                                showVaultDocsOnly = false
                                toggleCategoryFilter(.person)
                            }
                        )
                        
                        CategoryPill(
                            title: "Kumaş & Tedarik",
                            icon: "tag.fill",
                            isSelected: !showVaultDocsOnly && filterCategory == .fabricCost,
                            color: Color(red: 0.95, green: 0.75, blue: 0.45),
                            action: {
                                showVaultDocsOnly = false
                                toggleCategoryFilter(.fabricCost)
                            }
                        )
                    }
                }
                
                // 4. Kaynak Filtresi (Ses, Sohbet, Manuel - Yatay Kaydırılabilir)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        SourceFilterPill(title: "Tüm Kaynaklar", isSelected: filterSource == nil) { filterSource = nil }
                        SourceFilterPill(title: "🎙️ Sesli Konuşma", isSelected: filterSource == "voice") { filterSource = "voice" }
                        SourceFilterPill(title: "💬 Sohbet", isSelected: filterSource == "chat") { filterSource = "chat" }
                        SourceFilterPill(title: "✍️ Manuel", isSelected: filterSource == "manual") { filterSource = "manual" }
                    }
                }
                
                // 5. Notlar & Dosyalar Kart Listesi
                LazyVStack(spacing: 12) {
                    if showVaultDocsOnly {
                        if vaultDocService.documents.isEmpty {
                            EmptyVaultView(searchText: searchText)
                        } else {
                            ForEach(vaultDocService.documents) { doc in
                                VaultDocCard(
                                    doc: doc,
                                    onEdit: {
                                        editingVaultDoc = doc
                                    },
                                    onDelete: {
                                        vaultDocService.deleteDocument(id: doc.id)
                                    }
                                )
                            }
                        }
                    } else if filteredMemories.isEmpty {
                        EmptyVaultView(searchText: searchText)
                    } else {
                        ForEach(filteredMemories) { record in
                            NoteVaultCard(
                                record: record,
                                isCopied: copiedNoteId == record.id,
                                onTogglePin: {
                                    appState.togglePin(id: record.id)
                                },
                                onEdit: {
                                    editingMemory = record
                                },
                                onCopy: {
                                    UIPasteboard.general.string = record.content
                                    copiedNoteId = record.id
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        if copiedNoteId == record.id { copiedNoteId = nil }
                                    }
                                },
                                onExport: {
                                    if let url = ErisMemoryDatabase.shared.exportRecordToTempFile(record) {
                                        shareURL = url
                                        showingShareSheet = true
                                    }
                                },
                                onDelete: {
                                    appState.deleteMemory(id: record.id)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showingNewNoteSheet) {
            IOSNewNoteSheet { newRecord in
                appState.addMemory(
                    title: newRecord.title,
                    content: newRecord.content,
                    category: newRecord.category,
                    tags: newRecord.tags,
                    source: "manual",
                    fileName: newRecord.fileName,
                    pinned: newRecord.pinned
                )
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                IOSShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showingNewVaultDocSheet) {
            IOSNewVaultDocSheet()
        }
        .sheet(item: $editingMemory) { record in
            IOSEditNoteSheet(record: record) { updatedTitle, updatedContent, updatedCat, updatedTags, updatedFileName in
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
            IOSEditVaultDocSheet(doc: doc) { updated in
                vaultDocService.updateDocument(updated)
            }
        }
    }
    
    private func toggleCategoryFilter(_ cat: MemoryCategory) {
        if filterCategory == cat {
            filterCategory = nil
        } else {
            filterCategory = cat
        }
    }
    
    private func exportAllNotes() {
        if let url = ErisMemoryDatabase.shared.exportAllToTempFile() {
            shareURL = url
            showingShareSheet = true
        }
    }
}

// MARK: - Not Kartı (Note Vault Card)
struct NoteVaultCard: View {
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
        VStack(alignment: .leading, spacing: 10) {
            // Üst Satır: Kategori Rozeti + Kaynak Rozeti + Sabitleme Butonu
            HStack(spacing: 8) {
                // Kategori Rozeti
                HStack(spacing: 4) {
                    Image(systemName: record.category.icon)
                    Text(record.category.displayName)
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(categoryColor.opacity(0.18)))
                .foregroundColor(categoryColor)
                
                // Kaynak Rozeti
                SourceBadge(source: record.source)
                
                Spacer()
                
                // Pin / Sabitle Butonu
                PinButton(isPinned: record.pinned, size: 12, action: onTogglePin)
            }
            
            // Başlık
            Text(record.title)
                .font(.headline)
                .foregroundColor(ErisTheme.coldWhite)
                .lineLimit(2)
            
            // İçerik Metni
            Text(record.content)
                .font(.subheadline)
                .foregroundColor(ErisTheme.coldWhite.opacity(0.9))
                .lineSpacing(2)
            
            // Dosya Adı / Referansı Varsa
            if let fName = record.fileName, !fName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "doc.badge.arrow.up")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                    Text(fName)
                        .font(.caption2).bold()
                        .foregroundColor(ErisTheme.coldWhite)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
            }
            
            // Etiketler
            if !record.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(record.tags, id: \.self) { tag in
                        TagBadge(tag: tag, size: .regular)
                    }
                }
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            // Alt Bilgi & Aksiyon Butonları
            HStack {
                Text(formattedDate(record.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(ErisTheme.coldGray)
                
                Spacer()
                
                // Düzenle
                Button(action: onEdit) {
                    HStack(spacing: 3) {
                        Image(systemName: "pencil")
                        Text("Düzenle")
                    }
                    .font(.caption2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .padding(.trailing, 10)
                
                // Dışa Aktar (.md)
                Button(action: onExport) {
                    HStack(spacing: 3) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Dışa Aktar")
                    }
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldWhite.opacity(0.8))
                }
                .padding(.trailing, 10)
                
                // Kopyala
                Button(action: onCopy) {
                    HStack(spacing: 3) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Kopyalandı" : "Kopyala")
                    }
                    .font(.caption2)
                    .foregroundColor(isCopied ? Color.green : ErisTheme.coldWhite.opacity(0.8))
                }
                .padding(.trailing, 10)
                
                // Sil
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(record.pinned ? ErisTheme.bronzeAccent.opacity(0.4) : Color.white.opacity(0.08), lineWidth: record.pinned ? 1.0 : 0.6)
                )
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Kaynak Rozeti (Source Badge)
struct SourceBadge: View {
    let source: String
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: iconName)
            Text(displayName)
        }
        .font(.system(size: 9, weight: .semibold))
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(Capsule().fill(badgeColor.opacity(0.15)))
        .foregroundColor(badgeColor)
    }
    
    var iconName: String {
        switch source.lowercased() {
        case "voice": return "waveform"
        case "chat": return "bubble.left.fill"
        default: return "square.and.pencil"
        }
    }
    
    var displayName: String {
        switch source.lowercased() {
        case "voice": return "Sesli Konuşma"
        case "chat": return "Sohbet"
        default: return "Manuel"
        }
    }
    
    var badgeColor: Color {
        switch source.lowercased() {
        case "voice": return Color(red: 0.65, green: 0.55, blue: 0.95)
        case "chat": return Color(red: 0.45, green: 0.75, blue: 0.95)
        default: return ErisTheme.coldGray
        }
    }
}

// MARK: - Filtre Hapları
struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
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
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Capsule().fill(isSelected ? color : Color.white.opacity(0.08)))
            .foregroundColor(isSelected ? .black : ErisTheme.coldWhite)
        }
    }
}

struct SourceFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(isSelected ? ErisTheme.bronzeAccent.opacity(0.4) : Color.white.opacity(0.04)))
                .foregroundColor(isSelected ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
        }
    }
}

struct StatBadge: View {
    let label: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
            Text("\(label): \(count)")
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundColor(ErisTheme.coldWhite)
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.05)))
    }
}

// MARK: - Boş Durum
struct EmptyVaultView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(ErisTheme.coldGray.opacity(0.5))
                .padding(.top, 30)
            
            Text(searchText.isEmpty ? "Bu kategoride henüz kayıtlı bir not yok." : "'\(searchText)' ile eşleşen bir not veya dosya bulunamadı.")
                .font(.subheadline)
                .foregroundColor(ErisTheme.coldGray)
                .multilineTextAlignment(.center)
            
            Text("Sesli konuşurken Eris önemli bilgileri (fiyatlar, sözleşmeler, görevler) otomatik yakalar veya yukarıdaki '+ Yeni' butonuyla elinizle ekleyebilirsiniz.")
                .font(.caption)
                .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Yeni Not Ekleme Sayfası (Sheet)
struct IOSNewNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    let onSave: (ErisMemoryRecord) -> Void
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var category: MemoryCategory = .document
    @State private var tagsText: String = ""
    @State private var fileName: String = ""
    @State private var pinned: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Not Başlığı & Kategori").foregroundColor(ErisTheme.coldGray)) {
                    TextField("Başlık (Örn: Q1 Sunucu Bütçesi)", text: $title)
                    
                    Picker("Kategori", selection: $category) {
                        ForEach(MemoryCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("İçerik").foregroundColor(ErisTheme.coldGray)) {
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                }
                
                Section(header: Text("Etiketler & Dosya Referansı").foregroundColor(ErisTheme.coldGray)) {
                    TextField("Etiketler (#finans, #sunucu)", text: $tagsText)
                    TextField("Dosya Adı (Örn: Butce_Q1.md)", text: $fileName)
                    Toggle("Üste Sabitle", isOn: $pinned)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ErisTheme.graphite.ignoresSafeArea())
            .navigationTitle("Yeni Not / Belge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(ErisTheme.coldGray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let tags = tagsText
                            .components(separatedBy: CharacterSet(charactersIn: ", "))
                            .filter { !$0.isEmpty }
                        
                        let record = ErisMemoryRecord(
                            category: category,
                            title: title.isEmpty ? nil : title,
                            content: content,
                            tags: tags,
                            source: "manual",
                            fileName: fileName.isEmpty ? nil : fileName,
                            pinned: pinned
                        )
                        onSave(record)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Paylaşım Sayfası (UIActivityViewController)
struct IOSShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Resmî Kasa Evrak Kartı (VaultDocCard)

struct VaultDocCard: View {
    let doc: VaultDocumentRecord
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: doc.category.icon)
                    .font(.title3)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(doc.title)
                            .font(.subheadline).bold()
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        Text(doc.category.displayName)
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    
                    if let issuer = doc.issuer {
                        Text(issuer)
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldGray)
                    }
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .padding(4)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            
            // Belge Numarası ve Geçerlilik
            HStack(spacing: 8) {
                if let num = doc.documentNumber {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                            .font(.system(size: 9))
                        Text(num)
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(ErisTheme.coldGray)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
                }
                
                if let exp = doc.expirationDate ?? doc.warrantyEndDate {
                    HStack(spacing: 4) {
                        Image(systemName: doc.isExpiringSoon ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.system(size: 9))
                            .foregroundColor(doc.isExpiringSoon ? ErisTheme.thinkingAmber : ErisTheme.coldGray)
                        Text("Son: \(exp.formatted(date: .numeric, time: .omitted))")
                            .font(.system(size: 10, weight: doc.isExpiringSoon ? .bold : .regular))
                            .foregroundColor(doc.isExpiringSoon ? ErisTheme.thinkingAmber : ErisTheme.coldGray)
                    }
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(doc.isExpiringSoon ? ErisTheme.thinkingAmber.opacity(0.12) : Color.white.opacity(0.04)))
                }
            }
            
            if !doc.notes.isEmpty {
                Text(doc.notes)
                    .font(.caption)
                    .foregroundColor(ErisTheme.coldWhite.opacity(0.85))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(doc.isExpiringSoon ? ErisTheme.thinkingAmber.opacity(0.4) : ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - Yeni Resmî Kasa Evrakı Ekleme Sayfası

struct IOSNewVaultDocSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vaultService = ErisVaultDocumentService.shared
    
    @State private var title: String = ""
    @State private var category: VaultDocCategory = .passportId
    @State private var documentNumber: String = ""
    @State private var issuer: String = ""
    @State private var hasExpirationDate: Bool = true
    @State private var expirationDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("BELGE BİLGİLERİ").font(.caption).foregroundColor(ErisTheme.bronzeHighlight)) {
                    TextField("Belge Adı (Örn: Bordo Pasaport, Kira Sözleşmesi)", text: $title)
                    
                    Picker("Tür", selection: $category) {
                        ForEach(VaultDocCategory.allCases, id: \.self) { cat in
                            HStack {
                                Image(systemName: cat.icon)
                                Text(cat.displayName)
                            }
                            .tag(cat)
                        }
                    }
                    
                    TextField("Belge No / Seri No (Opsiyonel)", text: $documentNumber)
                    TextField("Düzenleyen Kurum / Kişi (Opsiyonel)", text: $issuer)
                }
                
                Section(header: Text("GEÇERLİLİK & SÜRE BİTİMİ").font(.caption).foregroundColor(ErisTheme.bronzeHighlight)) {
                    Toggle("Bitiş / Yenileme Tarihi Var", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker("Bitiş Tarihi", selection: $expirationDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("NOTLAR").font(.caption).foregroundColor(ErisTheme.bronzeHighlight)) {
                    TextField("Örn: En az 6 ay geçerlilik süresi şartı var", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Yeni Kasa Belgesi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveDoc()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveDoc() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        let record = VaultDocumentRecord(
            title: trimmed,
            category: category,
            documentNumber: documentNumber.isEmpty ? nil : documentNumber,
            expirationDate: hasExpirationDate ? expirationDate : nil,
            issuer: issuer.isEmpty ? nil : issuer,
            notes: notes
        )
        vaultService.addDocument(record)
        dismiss()
    }
}

// MARK: - Not / Dosya Düzenleme Sayfası (Sheet)
struct IOSEditNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    let record: ErisMemoryRecord
    let onSave: (_ title: String?, _ content: String, _ category: MemoryCategory, _ tags: [String], _ fileName: String?) -> Void
    
    @State private var title: String
    @State private var content: String
    @State private var category: MemoryCategory
    @State private var tagsText: String
    @State private var fileName: String
    
    init(record: ErisMemoryRecord, onSave: @escaping (String?, String, MemoryCategory, [String], String?) -> Void) {
        self.record = record
        self.onSave = onSave
        _title = State(initialValue: record.title)
        _content = State(initialValue: record.content)
        _category = State(initialValue: record.category)
        _tagsText = State(initialValue: record.tags.joined(separator: ", "))
        _fileName = State(initialValue: record.fileName ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Not Başlığı & Kategori").foregroundColor(ErisTheme.coldGray)) {
                    TextField("Başlık", text: $title)
                    
                    Picker("Kategori", selection: $category) {
                        ForEach(MemoryCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("İçerik").foregroundColor(ErisTheme.coldGray)) {
                    TextEditor(text: $content)
                        .frame(minHeight: 140)
                }
                
                Section(header: Text("Etiketler & Bağlı Dosya").foregroundColor(ErisTheme.coldGray)) {
                    TextField("Etiketler (#finans, #proje)", text: $tagsText)
                    TextField("Dosya Adı (Örn: Rapor.md)", text: $fileName)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ErisTheme.graphite.ignoresSafeArea())
            .navigationTitle("Notu / Dosyayı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                        .foregroundColor(ErisTheme.coldGray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let tags = tagsText
                            .components(separatedBy: CharacterSet(charactersIn: ", "))
                            .filter { !$0.isEmpty }
                        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalFile = fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fileName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(finalTitle, content.trimmingCharacters(in: .whitespacesAndNewlines), category, tags, finalFile)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Resmî Belge / Kasa Evrakı Düzenleme Sayfası (Sheet)
struct IOSEditVaultDocSheet: View {
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
        NavigationStack {
            Form {
                Section(header: Text("Belge Bilgileri").foregroundColor(ErisTheme.coldGray)) {
                    TextField("Belge Başlığı", text: $title)
                    Picker("Kategori", selection: $category) {
                        ForEach(VaultDocCategory.allCases, id: \.self) { c in
                            Label(c.displayName, systemImage: c.icon).tag(c)
                        }
                    }
                    TextField("Belge Numarası", text: $documentNumber)
                    TextField("Düzenleyen Kurum / İhraççı", text: $issuer)
                }
                
                Section(header: Text("Süre & Geçerlilik").foregroundColor(ErisTheme.coldGray)) {
                    Toggle("Geçerlilik Tarihi Var", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Son Geçerlilik / Bitiş", selection: $expirationDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Notlar").foregroundColor(ErisTheme.coldGray)) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ErisTheme.graphite.ignoresSafeArea())
            .navigationTitle("Belgeyi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                        .foregroundColor(ErisTheme.coldGray)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
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
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

