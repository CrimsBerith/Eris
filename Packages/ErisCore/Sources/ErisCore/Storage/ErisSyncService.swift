import Foundation

public final class ErisSyncService: @unchecked Sendable {
    public static let shared = ErisSyncService()
    
    private let keyValueStore = NSUbiquitousKeyValueStore.default
    private let memoriesSyncKey = "eris_synced_memories_v1"
    private let preferencesSyncKey = "eris_synced_preferences_v1"
    
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
    
    /// Yerel hafızayı iCloud'a yükler
    public func pushToCloud() {
        let localMemories = ErisMemoryDatabase.shared.getAllMemories()
        do {
            let data = try JSONEncoder().encode(localMemories)
            keyValueStore.set(data, forKey: memoriesSyncKey)
            keyValueStore.synchronize()
        } catch {
            print("iCloud hafıza eşitleme hatası: \(error)")
        }
    }
    
    /// iCloud'daki yeni verileri çeker ve yerel SQLite'a kaydeder
    public func pullFromCloud() {
        guard let data = keyValueStore.data(forKey: memoriesSyncKey) else { return }
        do {
            let remoteMemories = try JSONDecoder().decode([ErisMemoryRecord].self, from: data)
            let localMemories = ErisMemoryDatabase.shared.getAllMemories()
            let localIds = Set(localMemories.map { $0.id })
            
            for remote in remoteMemories {
                if !localIds.contains(remote.id) {
                    ErisMemoryDatabase.shared.saveMemory(remote)
                }
            }
            onSyncUpdated?()
        } catch {
            print("iCloud veri alma hatası: \(error)")
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
