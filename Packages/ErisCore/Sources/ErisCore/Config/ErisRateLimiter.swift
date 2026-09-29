//
//  ErisRateLimiter.swift
//  ErisCore
//
//  Created by Eris on 2026-09-29.
//

import Foundation

/// Eris Sıfır-Kurulum mimarisinde geliştirici API kotasını ve maliyetlerini
/// aşırı tüketimden ve kötüye kullanımdan koruyan akıllı günlük istek sınırlayıcı.
public final class ErisRateLimiter: ObservableObject, @unchecked Sendable {
    public static let shared = ErisRateLimiter()
    
    private let defaults: UserDefaults
    private let countKey = "eris_rate_limiter_daily_count"
    private let dateKey = "eris_rate_limiter_last_date"
    private let lock = NSLock()
    
    /// Standart sıfır-kurulum kullanıcıları için günlük soru kotası
    public var maxDailyRequests: Int = 50
    
    @Published public private(set) var remainingRequestsToday: Int = 50
    @Published public private(set) var dailyRequestCount: Int = 0
    
    public init(userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.alfagolab.eris") ?? .standard) {
        self.defaults = userDefaults
        refreshState()
    }
    
    // MARK: - Durum Yenileme & Gün Kontrolü
    
    private func refreshState() {
        lock.lock()
        defer { lock.unlock() }
        
        let now = Date()
        let calendar = Calendar.current
        
        if let lastDate = defaults.object(forKey: dateKey) as? Date {
            if !calendar.isDate(now, inSameDayAs: lastDate) {
                // Yeni bir güne geçildi, sayacı sıfırla
                defaults.set(0, forKey: countKey)
                defaults.set(now, forKey: dateKey)
                dailyRequestCount = 0
                remainingRequestsToday = maxDailyRequests
                return
            }
        } else {
            defaults.set(now, forKey: dateKey)
        }
        
        let count = defaults.integer(forKey: countKey)
        dailyRequestCount = count
        remainingRequestsToday = max(0, maxDailyRequests - count)
    }
    
    // MARK: - Limit Kontrolü
    
    /// Test amaçlı Keychain override'ını yok sayma bayrağı
    public var ignoreCustomKeyOverrideForTesting: Bool = false
    
    public var hasCustomApiKey: Bool {
        if ignoreCustomKeyOverrideForTesting { return false }
        if let customKey = KeychainManager.shared.getCustomOverrideApiKey(),
           !customKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    // MARK: - Limit Kontrolü
    
    /// İsteğin yapılıp yapılamayacağını doğrular
    public func canMakeRequest() -> (allowed: Bool, remaining: Int, message: String?) {
        // Eğer kullanıcı kendi özel API anahtarını tanımladıysa limit uygulanmaz (sınırsız)
        if hasCustomApiKey {
            return (true, 9999, nil)
        }
        
        refreshState()
        
        if dailyRequestCount >= maxDailyRequests {
            let msg = "Günlük soru kotanıza ulaştınız (\(maxDailyRequests)/\(maxDailyRequests)). Kotanız bu gece yarısı otomatik olarak sıfırlanacaktır."
            return (false, 0, msg)
        }
        
        return (true, remainingRequestsToday, nil)
    }
    
    /// Başarılı bir istek sonrası sayacı 1 artırır
    public func recordRequest() {
        // Özel API anahtarı varsa kota sayacı artırılmaz
        if hasCustomApiKey {
            return
        }
        
        lock.lock()
        defer { lock.unlock() }
        
        let newCount = dailyRequestCount + 1
        defaults.set(newCount, forKey: countKey)
        defaults.set(Date(), forKey: dateKey)
        dailyRequestCount = newCount
        remainingRequestsToday = max(0, maxDailyRequests - newCount)
    }
    
    /// Testler ve geliştirici amaçlı sayacı sıfırlama
    public func resetForTesting() {
        lock.lock()
        defer { lock.unlock() }
        defaults.removeObject(forKey: countKey)
        defaults.removeObject(forKey: dateKey)
        dailyRequestCount = 0
        remainingRequestsToday = maxDailyRequests
    }
}
