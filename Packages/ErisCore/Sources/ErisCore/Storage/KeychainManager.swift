import Foundation
import Security

public final class KeychainManager: @unchecked Sendable {
    public static let shared = KeychainManager()
    private let service = "com.alfagolab.eris"
    private let apiKeyAccount = "gemini_api_key"
    private let vapiApiKeyAccount = "vapi_api_key"
    private let vapiAssistantIdAccount = "vapi_assistant_id"
    
    private init() {}
    
    // MARK: - Gemini API Key
    public func saveApiKey(_ key: String) -> Bool {
        saveGeneric(account: apiKeyAccount, value: key)
    }
    
    /// Keychain'e kullanıcının/geliştiricinin elle girdiği özel bir override var mı kontrol eder
    public func getCustomOverrideApiKey() -> String? {
        getGeneric(account: apiKeyAccount)
    }
    
    /// Aktif API anahtarını döner (Geliştirici anahtarı veya Keychain override)
    public func getApiKey() -> String? {
        let key = ErisAppConfig.activeApiKey
        return key.isEmpty ? nil : key
    }
    
    public func deleteApiKey() {
        deleteGeneric(account: apiKeyAccount)
    }
    
    // MARK: - Vapi.ai API Key
    public func saveVapiApiKey(_ key: String) -> Bool {
        saveGeneric(account: vapiApiKeyAccount, value: key)
    }
    
    public func getVapiApiKey() -> String? {
        getGeneric(account: vapiApiKeyAccount)
    }
    
    public func deleteVapiApiKey() {
        deleteGeneric(account: vapiApiKeyAccount)
    }
    
    // MARK: - Vapi.ai Assistant ID
    public func saveVapiAssistantId(_ id: String) -> Bool {
        saveGeneric(account: vapiAssistantIdAccount, value: id)
    }
    
    public func getVapiAssistantId() -> String? {
        getGeneric(account: vapiAssistantIdAccount)
    }
    
    public func deleteVapiAssistantId() {
        deleteGeneric(account: vapiAssistantIdAccount)
    }
    
    // MARK: - Generic Keychain Helpers
    private func saveGeneric(account: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        deleteGeneric(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getGeneric(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func deleteGeneric(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
