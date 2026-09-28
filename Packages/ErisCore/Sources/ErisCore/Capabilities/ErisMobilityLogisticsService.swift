//
//  ErisMobilityLogisticsService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct VehicleStatusRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var licensePlate: String
    public var modelName: String
    public var currentKilometers: Int
    public var nextServiceKilometers: Int
    public var inspectionDueDate: Date
    public var insuranceExpiryDate: Date
    public var fuelOrBatteryLevelPercent: Int
    
    public init(
        id: UUID = UUID(),
        licensePlate: String = "34 ERIS 2026",
        modelName: String = "Volvo XC60 Recharge",
        currentKilometers: Int = 42500,
        nextServiceKilometers: Int = 45000,
        inspectionDueDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
        insuranceExpiryDate: Date = Calendar.current.date(byAdding: .month, value: 5, to: Date()) ?? Date(),
        fuelOrBatteryLevelPercent: Int = 68
    ) {
        self.id = id
        self.licensePlate = licensePlate
        self.modelName = modelName
        self.currentKilometers = currentKilometers
        self.nextServiceKilometers = nextServiceKilometers
        self.inspectionDueDate = inspectionDueDate
        self.insuranceExpiryDate = insuranceExpiryDate
        self.fuelOrBatteryLevelPercent = fuelOrBatteryLevelPercent
    }
    
    public var kmUntilNextService: Int {
        max(0, nextServiceKilometers - currentKilometers)
    }
}

public struct TravelItineraryRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var flightCodeOrPnr: String
    public var destinationCity: String
    public var departureTime: Date
    public var checkInOpensTime: Date
    public var baggageAllowanceKg: Int
    public var airportName: String
    
    public init(
        id: UUID = UUID(),
        flightCodeOrPnr: String = "TK 1983 / PNR: 7K9L2M",
        destinationCity: String = "Londra (LHR)",
        departureTime: Date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        checkInOpensTime: Date = Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
        baggageAllowanceKg: Int = 23,
        airportName: String = "İstanbul Havalimanı (IST)"
    ) {
        self.id = id
        self.flightCodeOrPnr = flightCodeOrPnr
        self.destinationCity = destinationCity
        self.departureTime = departureTime
        self.checkInOpensTime = checkInOpensTime
        self.baggageAllowanceKg = baggageAllowanceKg
        self.airportName = airportName
    }
}

/// Bölüm 18 & 19 ("Seyahat & Araç Yönetimi") gereğince:
/// Araç periyodik bakımı, muayene, sigorta ve seyahat check-in/bavul
/// lojistiğini tek bir bağlamda yöneten Mobilite Servisi.
public final class ErisMobilityLogisticsService: @unchecked Sendable {
    public static let shared = ErisMobilityLogisticsService()
    
    public var primaryVehicle = VehicleStatusRecord()
    public var upcomingTrips: [TravelItineraryRecord] = []
    private let lock = NSLock()
    
    private init() {
        upcomingTrips = [TravelItineraryRecord()]
    }
    
    public func getVehicleStatus() -> VehicleStatusRecord {
        lock.lock()
        defer { lock.unlock() }
        return primaryVehicle
    }
    
    public func getNextUpcomingTrip() -> TravelItineraryRecord? {
        lock.lock()
        defer { lock.unlock() }
        return upcomingTrips.first(where: { $0.departureTime > Date() })
    }
}
