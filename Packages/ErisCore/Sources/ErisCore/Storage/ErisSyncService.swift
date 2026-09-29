import Foundation

public final class ErisSyncService: @unchecked Sendable {
    public static let shared = ErisSyncService()
    
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    private let memoriesSyncKey = "eris_synced_memories_v1"
    private let preferencesSyncKey = "eris_synced_preferences_v1"
    private let openLoopsSyncKey = "eris_synced_open_loops_v1"
    private let checklistsSyncKey = "eris_synced_checklists_v1"
    
    public var onSyncUpdated: (@Sendable () -> Void)?
    
    private init() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: keyValueStore,
            queue: .main
        ) { [weak self] _ in
            self?.pullFromCloud()
        }
        keyValueStore.synchronize()
    }
    
    /// Yerel hafızayı, açık döngüleri ve kontrol listelerini iCloud'a yükler.
    ///
    /// ⚠️ Sınır: NSUbiquitousKeyValueStore toplamda 1 MB / 1024 anahtar sınırına tabidir.
    /// Sınıra yaklaşıldığında senkron sessizce başarısız olabilir. Boyut kontrolü yapılır.
    public func pushToCloud() {
        // NSUbiquitousKeyValueStore toplam 1 MB (1_048_576 bayt) sınırı
        let kMaxTotalBytes = 900_000 // Güvenlik payıyla 900 KB

        let localMemories = ErisMemoryDatabase.shared.getAllMemories()
        if let data = try? JSONEncoder().encode(localMemories) {
            if data.count < kMaxTotalBytes {
                keyValueStore.set(data, forKey: memoriesSyncKey)
            } else {
                // Sınır aşıldı: yalnızca son 50 kaydı ve sabitlenmiş kayıtları senkronize et
                let trimmed = Array(localMemories.filter { $0.pinned }.prefix(20) + localMemories.prefix(30))
                if let trimmedData = try? JSONEncoder().encode(trimmed) {
                    keyValueStore.set(trimmedData, forKey: memoriesSyncKey)
                }
                print("⚠️ Eris iCloud: Hafıza veri boyutu (\(data.count / 1024) KB) sınıra yaklaştı — yalnızca son/sabitlenmiş kayıtlar senkronize edildi.")
            }
        }

        let localLoops = ErisOpenLoopsEngine.shared.activeLoops
        if let data = try? JSONEncoder().encode(localLoops) {
            keyValueStore.set(data, forKey: openLoopsSyncKey)
        }

        let localChecklists = ErisLivingChecklistEngine.shared.checklists
        if let data = try? JSONEncoder().encode(localChecklists) {
            keyValueStore.set(data, forKey: checklistsSyncKey)
        }

        keyValueStore.synchronize()
    }
    
    /// iCloud'daki yeni verileri çeker ve yerel motorlara aktarır
    public func pullFromCloud() {
        var hasNew = false
        
        if let data = keyValueStore.data(forKey: memoriesSyncKey) {
            if let remoteMemories = try? JSONDecoder().decode([ErisMemoryRecord].self, from: data) {
                let localMemories = ErisMemoryDatabase.shared.getAllMemories()
                let localIds = Set(localMemories.map { $0.id })
                for remote in remoteMemories {
                    if !localIds.contains(remote.id) {
                        ErisMemoryDatabase.shared.saveMemoryInternal(remote)
                        hasNew = true
                    }
                }
            }
        }
        
        if let data = keyValueStore.data(forKey: openLoopsSyncKey) {
            if let remoteLoops = try? JSONDecoder().decode([OpenLoopItem].self, from: data), !remoteLoops.isEmpty {
                ErisOpenLoopsEngine.shared.setLoopsFromCloud(remoteLoops)
                hasNew = true
            }
        }
        
        if let data = keyValueStore.data(forKey: checklistsSyncKey) {
            if let remoteChecklists = try? JSONDecoder().decode([LivingChecklist].self, from: data), !remoteChecklists.isEmpty {
                ErisLivingChecklistEngine.shared.setChecklistsFromCloud(remoteChecklists)
                hasNew = true
            }
        }
        
        if hasNew {
            onSyncUpdated?()
        }
    }
    
    /// Tercihleri (Ses, Wake Word, Model) iCloud'a kaydeder
    public func syncPreferences(model: String, voiceGender: String, wakeWord: Bool) {
        let prefs: [String: Any] = [
            "model": model,
            "voiceGender": voiceGender,
            "wakeWord": wakeWord
        ]
        keyValueStore.set(prefs, forKey: preferencesSyncKey)
        keyValueStore.synchronize()
    }
    
    public func getSyncedPreferences() -> [String: Any]? {
        return keyValueStore.dictionary(forKey: preferencesSyncKey)
    }
}
