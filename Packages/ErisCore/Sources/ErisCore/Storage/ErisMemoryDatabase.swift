import Foundation
import SQLite3

public enum MemoryCategory: String, Codable, CaseIterable, Sendable {
    case preference = "preference"
    case project = "project"
    case person = "person"
    case finance = "finance"
    case maritime = "maritime"
    case instruction = "instruction"
    
    public var displayName: String {
        switch self {
        case .preference: return "Tercih & Alışkanlık"
        case .project: return "Proje & Görev"
        case .person: return "Önemli Kişi"
        case .finance: return "Finans & Yatırım"
        case .maritime: return "Deniz & Seyahat"
        case .instruction: return "Kalıcı Talimat"
        }
    }
}

public struct ErisMemoryRecord: Identifiable, Codable, Sendable {
    public let id: String
    public let createdAt: Date
    public let category: MemoryCategory
    public let content: String
    public var pinned: Bool
    
    public init(id: String = UUID().uuidString, createdAt: Date = Date(), category: MemoryCategory, content: String, pinned: Bool = false) {
        self.id = id
        self.createdAt = createdAt
        self.category = category
        self.content = content
        self.pinned = pinned
    }
}

public final class ErisMemoryDatabase: @unchecked Sendable {
    public static let shared = ErisMemoryDatabase()
    private var db: OpaquePointer?
    private let dbQueue = DispatchQueue(label: "com.alfagolab.eris.memorydb", qos: .userInitiated)
    
    private init() {
        openDatabase()
        createTable()
        seedDefaultMemoriesIfNeeded()
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
    
    private func openDatabase() {
        let path = getDatabaseURL().path
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Veritabanı açılamadı: \(path)")
        }
    }
    
    private func createTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS memories (
            id TEXT PRIMARY KEY,
            created_at REAL,
            category TEXT,
            content TEXT,
            pinned INTEGER
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    private func seedDefaultMemoriesIfNeeded() {
        if getAllMemories().isEmpty {
            saveMemory(ErisMemoryRecord(category: .preference, content: "Kullanıcı tok, doğrudan ve az sözlü yanıtları tercih eder.", pinned: true))
            saveMemory(ErisMemoryRecord(category: .maritime, content: "Kalamış Marina ve Marmara Denizi seyir sahası takibinde.", pinned: true))
            saveMemory(ErisMemoryRecord(category: .finance, content: "BIST100, Altın (XAUUSD) ve Dolar/TL portföy ilgisi.", pinned: true))
        }
    }
    
    public func saveMemory(_ item: ErisMemoryRecord) {
        dbQueue.sync {
            let insertQuery = "INSERT OR REPLACE INTO memories (id, created_at, category, content, pinned) VALUES (?, ?, ?, ?, ?);"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (item.id as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 2, item.createdAt.timeIntervalSince1970)
                sqlite3_bind_text(statement, 3, (item.category.rawValue as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (item.content as NSString).utf8String, -1, nil)
                sqlite3_bind_int(statement, 5, item.pinned ? 1 : 0)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    public func deleteMemory(id: String) {
        dbQueue.sync {
            let query = "DELETE FROM memories WHERE id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }
    
    public func getAllMemories() -> [ErisMemoryRecord] {
        return dbQueue.sync {
            var records: [ErisMemoryRecord] = []
            let selectQuery = "SELECT id, created_at, category, content, pinned FROM memories ORDER BY pinned DESC, created_at DESC;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, selectQuery, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let id = String(cString: sqlite3_column_text(statement, 0))
                    let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
                    let categoryStr = String(cString: sqlite3_column_text(statement, 2))
                    let content = String(cString: sqlite3_column_text(statement, 3))
                    let pinned = sqlite3_column_int(statement, 4) == 1
                    
                    let cat = MemoryCategory(rawValue: categoryStr) ?? .preference
                    records.append(ErisMemoryRecord(id: id, createdAt: createdAt, category: cat, content: content, pinned: pinned))
                }
            }
            sqlite3_finalize(statement)
            return records
        }
    }
    
    public func getMemoryContextString() -> String {
        let memories = getAllMemories()
        guard !memories.isEmpty else { return "" }
        var text = "\n[KULLANICI KİŞİSEL HAFIZASI]:\n"
        for m in memories {
            text += "- (\(m.category.displayName)): \(m.content)\n"
        }
        return text
    }
}
