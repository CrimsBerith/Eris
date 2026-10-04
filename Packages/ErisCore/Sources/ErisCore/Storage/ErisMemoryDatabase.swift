import Foundation
import SQLite3

public enum MemoryCategory: String, Codable, CaseIterable, Sendable {
    case document = "document"
    case project = "project"
    case technical = "technical"
    case finance = "finance"
    case designIdea = "design_idea"
    case preference = "preference"
    case person = "person"
    case instruction = "instruction"
    case fabricCost = "fabric_cost"
    case maritime = "maritime"
    
    public var displayName: String {
        switch self {
        case .document: return "Belgeler & Dosyalar"
        case .project: return "Projeler & Görevler"
        case .technical: return "Kodlama & Teknik"
        case .finance: return "Finans & Fiyatlar"
        case .designIdea: return "Fikirler & Tasarım"
        case .preference: return "Tercih & Alışkanlık"
        case .person: return "Önemli Kişi"
        case .instruction: return "Kalıcı Talimat"
        case .fabricCost: return "Kumaş & Tedarikçi"
        case .maritime: return "Deniz & Seyahat"
        }
    }
    
    public var icon: String {
        switch self {
        case .document: return "doc.text.fill"
        case .project: return "checklist"
        case .technical: return "curlybraces"
        case .finance: return "chart.line.uptrend.xyaxis"
        case .designIdea: return "lightbulb.fill"
        case .preference: return "heart.text.square"
        case .person: return "person.crop.circle"
        case .instruction: return "shield.lefthalf.filled"
        case .fabricCost: return "tag.fill"
        case .maritime: return "ferry.fill"
        }
    }
}

public struct ErisMemoryRecord: Identifiable, Codable, Sendable {
    public let id: String
    public let createdAt: Date
    public var category: MemoryCategory
    public var title: String
    public var content: String
    public var tags: [String]
    public var source: String // "voice", "chat", "manual"
    public var fileName: String?
    public var pinned: Bool
    
    public init(
        id: String = UUID().uuidString,
        createdAt: Date = Date(),
        category: MemoryCategory,
        title: String? = nil,
        content: String,
        tags: [String] = [],
        source: String = "manual",
        fileName: String? = nil,
        pinned: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.category = category
        self.content = content
        self.tags = tags
        self.source = source
        self.fileName = fileName
        self.pinned = pinned
        
        if let explicitTitle = title, !explicitTitle.isEmpty {
            self.title = explicitTitle
        } else {
            // İlk cümleden veya ilk 30 karakterden anlamlı başlık türet
            let firstLine = content.components(separatedBy: .newlines).first ?? content
            if firstLine.count > 40 {
                let idx = firstLine.index(firstLine.startIndex, offsetBy: 37)
                self.title = String(firstLine[..<idx]) + "..."
            } else {
                self.title = firstLine.isEmpty ? category.displayName : firstLine
            }
        }
    }
}

public final class ErisMemoryDatabase: @unchecked Sendable {
    public static let shared = ErisMemoryDatabase(onMemoriesChanged: {
        ErisSyncService.shared.pushToCloud()
    })
    private var db: OpaquePointer?
    private let onMemoriesChanged: (@Sendable () -> Void)?
    private let dbQueue = DispatchQueue(label: "com.alfagolab.eris.memorydb", qos: .userInitiated)
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    // Tests can use a temporary database with no iCloud side effects.
    // Initialization must never call back into the shared database through sync.
    init(databaseURL: URL? = nil, onMemoriesChanged: (@Sendable () -> Void)? = nil) {
        self.onMemoriesChanged = onMemoriesChanged
        openDatabase(at: databaseURL ?? getDatabaseURL())
        createTable()
        migrateTableIfNeeded()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    private func getDatabaseURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let erisFolder = appSupport.appendingPathComponent("Eris", isDirectory: true)
        if !fileManager.fileExists(atPath: erisFolder.path) {
            try? fileManager.createDirectory(at: erisFolder, withIntermediateDirectories: true)
        }
        return erisFolder.appendingPathComponent("eris_memory.sqlite")
    }
    
    private func openDatabase(at url: URL) {
        let path = url.path
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("❌ Eris veritabanı açılamadı: \(path) — \(String(cString: sqlite3_errmsg(db)))")
            sqlite3_close(db)
            db = nil
        } else {
            // WAL (Write-Ahead Logging) modu ile eşzamanlı okuma-yazma performansı ve kilitlenme (SQLITE_BUSY) önleme
            sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil)
            sqlite3_exec(db, "PRAGMA synchronous = NORMAL;", nil, nil, nil)
        }
    }
    
    private func createTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS memories (
            id TEXT PRIMARY KEY,
            created_at REAL,
            category TEXT,
            content TEXT,
            pinned INTEGER,
            title TEXT,
            tags TEXT,
            source TEXT,
            file_name TEXT
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
        
        // Life OS Ek Tabloları
        let createOpenLoopsQuery = """
        CREATE TABLE IF NOT EXISTS open_loops (
            id TEXT PRIMARY KEY,
            domain TEXT,
            title TEXT,
            details TEXT,
            source TEXT,
            urgency TEXT,
            status TEXT,
            suggested_action TEXT,
            due_date REAL,
            requires_approval INTEGER,
            created_at REAL,
            updated_at REAL
        );
        """
        sqlite3_exec(db, createOpenLoopsQuery, nil, nil, nil)
        
        let createPreferencesQuery = """
        CREATE TABLE IF NOT EXISTS user_preferences (
            id TEXT PRIMARY KEY,
            category TEXT,
            pref_key TEXT UNIQUE,
            pref_value TEXT,
            confidence REAL,
            source TEXT,
            updated_at REAL
        );
        """
        sqlite3_exec(db, createPreferencesQuery, nil, nil, nil)
        
        let createVaultDocsQuery = """
        CREATE TABLE IF NOT EXISTS vault_documents (
            id TEXT PRIMARY KEY,
            title TEXT,
            category TEXT,
            doc_number TEXT,
            expiration_date REAL,
            warranty_end_date REAL,
            issuer TEXT,
            associated_person TEXT,
            tags TEXT,
            notes TEXT,
            is_encrypted INTEGER,
            created_at REAL,
            updated_at REAL
        );
        """
        sqlite3_exec(db, createVaultDocsQuery, nil, nil, nil)
        
        let createChecklistsQuery = """
        CREATE TABLE IF NOT EXISTS living_checklists (
            id TEXT PRIMARY KEY,
            title TEXT,
            checklist_type TEXT,
            items_json TEXT,
            target_date REAL,
            destination_city TEXT,
            weather_note TEXT,
            created_at REAL,
            updated_at REAL
        );
        """
        sqlite3_exec(db, createChecklistsQuery, nil, nil, nil)
    }
    
    private func migrateTableIfNeeded() {
        // Mevcut tablolara eksik kolonları ekle (hata verirse yoksayılır)
        sqlite3_exec(db, "ALTER TABLE memories ADD COLUMN title TEXT;", nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE memories ADD COLUMN tags TEXT;", nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE memories ADD COLUMN source TEXT;", nil, nil, nil)
        sqlite3_exec(db, "ALTER TABLE memories ADD COLUMN file_name TEXT;", nil, nil, nil)
    }
    
    public func saveMemory(_ item: ErisMemoryRecord) {
        saveMemoryInternal(item)
        onMemoriesChanged?()
    }
    
    public func saveMemoryInternal(_ item: ErisMemoryRecord) {
        dbQueue.sync {
            let insertQuery = """
            INSERT OR REPLACE INTO memories (id, created_at, category, content, pinned, title, tags, source, file_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                let tagsStr = item.tags.joined(separator: ",")
                // SQLITE_TRANSIENT: Swift string'ler geçici; SQLite hemen kopyalar (dangling pointer önlemi)
                sqlite3_bind_text(statement, 1, item.id, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(statement, 2, item.createdAt.timeIntervalSince1970)
                sqlite3_bind_text(statement, 3, item.category.rawValue, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 4, item.content, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(statement, 5, item.pinned ? 1 : 0)
                sqlite3_bind_text(statement, 6, item.title, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 7, tagsStr, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 8, item.source, -1, SQLITE_TRANSIENT)
                if let fName = item.fileName {
                    sqlite3_bind_text(statement, 9, fName, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 9)
                }
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("⚠️ Hafıza kaydedilemedi: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
            sqlite3_finalize(statement)
        }
    }
    
    public func updateMemory(
        id: String,
        title: String?,
        content: String,
        category: MemoryCategory,
        tags: [String],
        fileName: String?
    ) {
        dbQueue.sync {
            let updateQuery = """
            UPDATE memories 
            SET title = ?, content = ?, category = ?, tags = ?, file_name = ?
            WHERE id = ?;
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, updateQuery, -1, &statement, nil) == SQLITE_OK {
                let tagsStr = tags.joined(separator: ",")
                if let t = title, !t.isEmpty {
                    sqlite3_bind_text(statement, 1, t, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 1)
                }
                sqlite3_bind_text(statement, 2, content, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 3, category.rawValue, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 4, tagsStr, -1, SQLITE_TRANSIENT)
                if let f = fileName, !f.isEmpty {
                    sqlite3_bind_text(statement, 5, f, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 5)
                }
                sqlite3_bind_text(statement, 6, id, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) != SQLITE_DONE {
                    print("⚠️ Hafıza güncellenemedi (id: \(id)): \(String(cString: sqlite3_errmsg(db)))")
                }
            }
            sqlite3_finalize(statement)
        }
        onMemoriesChanged?()
    }
    
    public func updateMemory(_ item: ErisMemoryRecord) {
        updateMemory(
            id: item.id,
            title: item.title,
            content: item.content,
            category: item.category,
            tags: item.tags,
            fileName: item.fileName
        )
    }
    
    public func deleteMemory(id: String) {
        dbQueue.sync {
            let query = "DELETE FROM memories WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) != SQLITE_DONE { print("⚠️ Hafıza silinemedi: \(String(cString: sqlite3_errmsg(db)))") }
            }
            sqlite3_finalize(statement)
        }
        onMemoriesChanged?()
    }

    public func getAllMemories() -> [ErisMemoryRecord] {
        return dbQueue.sync {
            var records: [ErisMemoryRecord] = []
            let selectQuery = "SELECT id, created_at, category, content, pinned, title, tags, source, file_name FROM memories ORDER BY pinned DESC, created_at DESC;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, selectQuery, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    // NULL pointer güvenliği: sütun NULL ise varsayılan değer kullan (çökme önlemi)
                    guard let idPtr = sqlite3_column_text(statement, 0) else { continue }
                    let id = String(cString: idPtr)
                    let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
                    let categoryStr = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? MemoryCategory.preference.rawValue
                    let content = sqlite3_column_text(statement, 3).map { String(cString: $0) } ?? ""
                    let pinned = sqlite3_column_int(statement, 4) == 1
                    
                    let titleStr: String? = sqlite3_column_text(statement, 5).map { String(cString: $0) }
                    let tagsRaw: String? = sqlite3_column_text(statement, 6).map { String(cString: $0) }
                    let sourceStr: String = sqlite3_column_text(statement, 7).map { String(cString: $0) } ?? "manual"
                    let fileNameStr: String? = sqlite3_column_text(statement, 8).map { String(cString: $0) }
                    
                    let tags = (tagsRaw?.components(separatedBy: ",").filter { !$0.isEmpty }) ?? []
                    let cat = MemoryCategory(rawValue: categoryStr) ?? .preference
                    
                    records.append(ErisMemoryRecord(
                        id: id,
                        createdAt: createdAt,
                        category: cat,
                        title: titleStr,
                        content: content,
                        tags: tags,
                        source: sourceStr,
                        fileName: fileNameStr,
                        pinned: pinned
                    ))
                }
            }
            sqlite3_finalize(statement)
            return records
        }
    }
    
    public func togglePin(id: String) {
        dbQueue.sync {
            let query = "UPDATE memories SET pinned = CASE WHEN pinned = 1 THEN 0 ELSE 1 END WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, id, -1, SQLITE_TRANSIENT)
                if sqlite3_step(statement) != SQLITE_DONE { print("⚠️ Kayıt işlemi başarısız: \(String(cString: sqlite3_errmsg(db)))") }
            }
            sqlite3_finalize(statement)
        }
        onMemoriesChanged?()
    }
    
    public func searchMemories(keyword: String) -> [ErisMemoryRecord] {
        let lower = keyword.lowercased()
        return getAllMemories().filter {
            $0.title.lowercased().contains(lower) ||
            $0.content.lowercased().contains(lower) ||
            $0.category.displayName.lowercased().contains(lower) ||
            $0.tags.contains(where: { $0.lowercased().contains(lower) })
        }
    }
    
    public func exportRecordAsMarkdown(_ record: ErisMemoryRecord) -> String {
        return ErisNoteIntelligence.shared.formatRecordAsMarkdown(record)
    }
    
    public func exportAllAsMarkdown() -> String {
        let all = getAllMemories()
        var text = "# Eris — Notlar & Dosyalar Kasası Arşivi\n"
        text += "_Dışa Aktarım Tarihi: \(Date().description)_\n\n"
        text += "Toplam Kayıt Sayısı: \(all.count)\n\n---\n\n"
        
        let grouped = Dictionary(grouping: all, by: { $0.category })
        for cat in MemoryCategory.allCases {
            guard let records = grouped[cat], !records.isEmpty else { continue }
            text += "## \(cat.displayName) (\(records.count))\n\n"
            for r in records {
                text += "### \(r.title)\n"
                text += "- **Tarih:** \(r.createdAt)\n"
                text += "- **Kaynak:** \(r.source)\n"
                if !r.tags.isEmpty { text += "- **Etiketler:** \(r.tags.joined(separator: ", "))\n" }
                text += "\n\(r.content)\n\n"
            }
            text += "---\n\n"
        }
        return text
    }
    
    public func exportRecordToTempFile(_ record: ErisMemoryRecord) -> URL? {
        let md = exportRecordAsMarkdown(record)
        let fileName = record.fileName ?? "\(record.title.replacingOccurrences(of: " ", with: "_")).md"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try md.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
    
    public func exportAllToTempFile() -> URL? {
        let md = exportAllAsMarkdown()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Eris_Notlar_Ve_Dosyalar_Kasasi.md")
        do {
            try md.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
    
    public func getMemoryContextString() -> String {
        let memories = getAllMemories()
        guard !memories.isEmpty else { return "" }
        var text = "\n[KULLANICI KİŞİSEL HAFIZASI & KAYITLI NOTLAR / DOSYALAR]:\n"
        for m in memories.prefix(12) {
            let tagsStr = m.tags.isEmpty ? "" : " [\(m.tags.joined(separator: " "))]"
            text += "- [\(m.category.displayName)] \(m.title): \(m.content)\(tagsStr)\n"
        }
        return text
    }
    
    // MARK: - Open Loops SQLite Persistence
    
    public func saveOpenLoopToDB(_ item: OpenLoopItem) {
        dbQueue.sync {
            let query = """
            INSERT OR REPLACE INTO open_loops (
                id, domain, title, details, source, urgency, status, suggested_action, due_date, requires_approval, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, item.id.uuidString, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 2, item.domain.rawValue, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 3, item.title, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 4, item.details, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 5, item.detectedSource, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 6, item.urgency.rawValue, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 7, item.status.rawValue, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 8, item.suggestedAction, -1, SQLITE_TRANSIENT)
                if let due = item.dueDate {
                    sqlite3_bind_double(stmt, 9, due.timeIntervalSince1970)
                } else {
                    sqlite3_bind_null(stmt, 9)
                }
                sqlite3_bind_int(stmt, 10, item.requiresUserApproval ? 1 : 0)
                sqlite3_bind_double(stmt, 11, item.createdAt.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 12, item.updatedAt.timeIntervalSince1970)
                if sqlite3_step(stmt) != SQLITE_DONE { print("⚠️ Kayıt yazılamadı: \(String(cString: sqlite3_errmsg(db)))") }
            }
            sqlite3_finalize(stmt)
        }
    }
    
    public func getAllOpenLoopsFromDB() -> [OpenLoopItem] {
        return dbQueue.sync {
            var items: [OpenLoopItem] = []
            let query = "SELECT id, domain, title, details, source, urgency, status, suggested_action, due_date, requires_approval, created_at, updated_at FROM open_loops ORDER BY created_at DESC;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    guard let idStr = sqlite3_column_text(stmt, 0),
                          let uuid = UUID(uuidString: String(cString: idStr)) else { continue }
                    
                    let domainStr = String(cString: sqlite3_column_text(stmt, 1))
                    let domain = ErisLifeDomain(rawValue: domainStr) ?? .tasksOpenLoops
                    let title = String(cString: sqlite3_column_text(stmt, 2))
                    let details = String(cString: sqlite3_column_text(stmt, 3))
                    let source = String(cString: sqlite3_column_text(stmt, 4))
                    let urgencyStr = String(cString: sqlite3_column_text(stmt, 5))
                    let urgency = LoopUrgency(rawValue: urgencyStr) ?? .medium
                    let statusStr = String(cString: sqlite3_column_text(stmt, 6))
                    let status = LoopStatus(rawValue: statusStr) ?? .detected
                    let action = String(cString: sqlite3_column_text(stmt, 7))
                    
                    var dueDate: Date? = nil
                    if sqlite3_column_type(stmt, 8) != SQLITE_NULL {
                        dueDate = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 8))
                    }
                    let reqApproval = sqlite3_column_int(stmt, 9) == 1
                    let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 10))
                    let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 11))
                    
                    items.append(OpenLoopItem(
                        id: uuid,
                        domain: domain,
                        title: title,
                        details: details,
                        detectedSource: source,
                        urgency: urgency,
                        status: status,
                        suggestedAction: action,
                        dueDate: dueDate,
                        requiresUserApproval: reqApproval,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    ))
                }
            }
            sqlite3_finalize(stmt)
            return items
        }
    }
    
    public func deleteOpenLoopFromDB(id: UUID) {
        dbQueue.sync {
            let query = "DELETE FROM open_loops WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
                if sqlite3_step(stmt) != SQLITE_DONE { print("⚠️ Kayıt silinemedi: \(String(cString: sqlite3_errmsg(db)))") }
            }
            sqlite3_finalize(stmt)
        }
    }
}

