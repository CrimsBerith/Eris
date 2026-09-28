//
//  ErisContextualTriggerEngine.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation
import UserNotifications
import CoreLocation

/// Bölüm 7 & 40 ("Hatırlatmalar & Proaktif Durumlar") gereğince:
/// Zaman, Coğrafi Konum (Geofence), Kişi, Hava Durumu Koşulu ve
/// Etkinlik Öncesi Hazırlık Sürelerine dayalı çok boyutlu bağlamsal tetikleyici motoru.
public final class ErisContextualTriggerEngine: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    public static let shared = ErisContextualTriggerEngine()
    
    private var triggers: [ContextualTrigger] = []
    private let locationManager = CLLocationManager()
    private let lock = NSLock()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        loadSampleTriggers()
    }
    
    private func loadSampleTriggers() {
        triggers = [
            ContextualTrigger(
                type: .location,
                title: "Market Eksilenleri",
                promptText: "Markete girdin: Süt, zeytinyağı ve espresso kahvesi almayı unutma.",
                locationName: "Macrocenter / Kadıköy",
                latitude: 40.985,
                longitude: 29.035,
                radiusMeters: 150,
                notifyOnEntry: true
            ),
            ContextualTrigger(
                type: .preparation,
                title: "Toplantı Evrakı Hazırlığı",
                promptText: "10:00'daki strateji toplantısına 30 dakika kaldı. Sunum taslağını ve notları hazırla.",
                minutesBeforeEvent: 30
            ),
            ContextualTrigger(
                type: .condition,
                title: "Hava Durumu Uyarısı",
                promptText: "Öğleden sonra sağanak yağış bekleniyor. Çıkarken şemsiyeni yanına al.",
                weatherConditionRequired: "rain"
            )
        ]
    }
    
    // MARK: - Tetikleyici Yönetimi
    
    public func addTrigger(_ trigger: ContextualTrigger) {
        lock.lock()
        triggers.append(trigger)
        lock.unlock()
        
        // Eğer konum tabanlıysa geofence bölgesini dinlemeye başla
        if trigger.type == .location, let lat = trigger.latitude, let lon = trigger.longitude {
            startMonitoringGeofence(id: trigger.id.uuidString, lat: lat, lon: lon, radius: trigger.radiusMeters ?? 200)
        }
    }
    
    public func activeTriggers() -> [ContextualTrigger] {
        lock.lock()
        defer { lock.unlock() }
        return triggers.filter { $0.isActive && !$0.isFired }
    }
    
    // MARK: - Konum (Geofence) İzleme
    
    private func startMonitoringGeofence(id: String, lat: Double, lon: Double, radius: Double) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }
        
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = CLCircularRegion(center: center, radius: radius, identifier: id)
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        lock.lock()
        if let idx = triggers.firstIndex(where: { $0.id.uuidString == region.identifier }) {
            triggers[idx].isFired = true
            let matchedTrigger = triggers[idx]
            lock.unlock()
            
            // Kullanıcıya bildirim fırlat
            dispatchNotification(title: matchedTrigger.title, body: matchedTrigger.promptText)
        } else {
            lock.unlock()
        }
    }
    
    // MARK: - Bildirim Fırlatma
    
    private func dispatchNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Eris — " + title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
