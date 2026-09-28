//
//  ErisHealthWellnessService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct MedicationSchedule: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var dosage: String
    public var scheduledTime: String // "08:30", "13:00", "21:00"
    public var withMeal: Bool
    public var isTakenToday: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        dosage: String,
        scheduledTime: String,
        withMeal: Bool = true,
        isTakenToday: Bool = false
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.scheduledTime = scheduledTime
        self.withMeal = withMeal
        self.isTakenToday = isTakenToday
    }
}

public struct WaterIntakeStatus: Codable, Equatable, Sendable {
    public var dailyTargetMl: Int
    public var currentIntakeMl: Int
    
    public init(dailyTargetMl: Int = 2500, currentIntakeMl: Int = 1250) {
        self.dailyTargetMl = dailyTargetMl
        self.currentIntakeMl = currentIntakeMl
    }
    
    public var progressFraction: Double {
        guard dailyTargetMl > 0 else { return 0.0 }
        return min(1.0, Double(currentIntakeMl) / Double(dailyTargetMl))
    }
}

/// Bölüm 20 & 21 ("Sağlık Organizasyonu, Kişisel Bakım & Wellness") gereğince:
/// İlaç / takviye saatlerini, su tüketim hedefini, dinlenme molalarını ve
/// sağlık randevularını yöneten Sağlık & Wellness Servisi.
public final class ErisHealthWellnessService: @unchecked Sendable {
    public static let shared = ErisHealthWellnessService()
    
    private var medications: [MedicationSchedule] = []
    public var waterStatus = WaterIntakeStatus()
    private let lock = NSLock()
    
    private init() {
        loadDefaultHealthSchedule()
    }
    
    private func loadDefaultHealthSchedule() {
        medications = [
            MedicationSchedule(
                name: "Omega-3 & D Vitamini",
                dosage: "1 kapsül",
                scheduledTime: "08:30",
                withMeal: true,
                isTakenToday: true
            ),
            MedicationSchedule(
                name: "Magnezyum Bisglisinat",
                dosage: "1 tablet",
                scheduledTime: "22:00",
                withMeal: false,
                isTakenToday: false
            )
        ]
    }
    
    public func getMedications() -> [MedicationSchedule] {
        lock.lock()
        defer { lock.unlock() }
        return medications
    }
    
    public func markMedicationTaken(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        if let idx = medications.firstIndex(where: { $0.id == id }) {
            medications[idx].isTakenToday = true
        }
    }
    
    public func logWater(milliliters: Int = 250) {
        lock.lock()
        defer { lock.unlock() }
        waterStatus.currentIntakeMl += milliliters
    }
}
