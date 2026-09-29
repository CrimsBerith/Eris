import SwiftUI
import AppKit
import ErisCore

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Paylaşılan badge bileşenlerini kullan (BadgeViews.swift — çoğaltma kaldırıldı)
                CategoryBadge(category: record.category, size: .compact)
                if record.source != "manual" {
                    SourceBadge(source: record.source, size: .compact)
                }
                if let fName = record.fileName {
                    FileNameBadge(fileName: fName)
                        .frame(maxWidth: 140)
                }

                Spacer()

                // Düzenle
                Button(action: onEdit) {
                    HStack(spacing: 2) {
                        Image(systemName: "pencil").accessibilityHidden(true)
                        Text("Düzenle")
                    }
                    .font(.system(size: 9.5))
                    .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .help("Notu veya Dosyayı Düzenle")
                .accessibilityLabel("Düzenle")

                // Sabitle — paylaşılan PinButton
                PinButton(isPinned: record.pinned, size: 11, action: onTogglePin)

                // Dışa Aktar (.md)
                Button(action: onExport) {
                    HStack(spacing: 2) {
                        Image(systemName: "square.and.arrow.up").accessibilityHidden(true)
                        Text("Dışa Aktar")
                    }
                    .font(.system(size: 9.5))
                    .foregroundColor(ErisTheme.coldWhite.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .accessibilityLabel("Dışa aktar")

                // Kopyala
                Button(action: onCopy) {
                    HStack(spacing: 2) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc").accessibilityHidden(true)
                        Text(isCopied ? "Kopyalandı" : "Kopyala")
                    }
                    .font(.system(size: 9.5))
                    .foregroundColor(isCopied ? Color.green : ErisTheme.coldWhite.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .accessibilityLabel(isCopied ? "Kopyalandı" : "Kopyala")

                // Sil
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sil")
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
                        // Paylaşılan TagBadge kullan
                        ForEach(record.tags, id: \.self) { tag in
                            TagBadge(tag: tag, size: .compact)
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
