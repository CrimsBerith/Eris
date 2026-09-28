//
//  ErisFinanceSubscriptionEngine.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct SubscriptionItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var category: String // "streaming", "software", "cloud", "gym", "telecom"
    public var cost: Double
    public var currency: String // "TRY", "USD", "EUR"
    public var billingCycle: String // "monthly", "yearly"
    public var nextRenewalDate: Date
    public var isUnusedOrLowUsage: Bool
    public var autoRenew: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        cost: Double,
        currency: String = "TRY",
        billingCycle: String = "monthly",
        nextRenewalDate: Date,
        isUnusedOrLowUsage: Bool = false,
        autoRenew: Bool = true
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.cost = cost
        self.currency = currency
        self.billingCycle = billingCycle
        self.nextRenewalDate = nextRenewalDate
        self.isUnusedOrLowUsage = isUnusedOrLowUsage
        self.autoRenew = autoRenew
    }
}

public struct BillItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var amount: Double
    public var currency: String
    public var dueDate: Date
    public var isPaid: Bool
    public var autoDebit: Bool
    
    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        currency: String = "TRY",
        dueDate: Date,
        isPaid: Bool = false,
        autoDebit: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.currency = currency
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.autoDebit = autoDebit
    }
    
    public var isApproaching: Bool {
        guard !isPaid else { return false }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
        return days >= 0 && days <= 5
    }
}

/// Bölüm 14 & 15 ("Faturalar, Abonelikler & Kişisel Finans") gereğince:
/// Düzenli yinelenen abonelikleri denetleyen, unutulan/kullanılmayan servisleri
/// yakalayan ve yaklaşan faturaları bütçeyle eşleştiren Finans Zekâ Motoru.
public final class ErisFinanceSubscriptionEngine: @unchecked Sendable {
    public static let shared = ErisFinanceSubscriptionEngine()
    
    private var subscriptions: [SubscriptionItem] = []
    private var bills: [BillItem] = []
    private let lock = NSLock()
    
    private init() {
        loadDefaultSampleData()
    }
    
    private func loadDefaultSampleData() {
        subscriptions = [
            SubscriptionItem(
                name: "iCloud+ 2TB",
                category: "cloud",
                cost: 129.99,
                nextRenewalDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()) ?? Date()
            ),
            SubscriptionItem(
                name: "Claude Pro / AI Tools",
                category: "software",
                cost: 650.0,
                nextRenewalDate: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date()
            ),
            SubscriptionItem(
                name: "Kullanılmayan Gym Üyeliği",
                category: "gym",
                cost: 1450.0,
                nextRenewalDate: Calendar.current.date(byAdding: .day, value: 4, to: Date()) ?? Date(),
                isUnusedOrLowUsage: true
            )
        ]
        
        bills = [
            BillItem(
                title: "Fiber İnternet Faturası",
                amount: 420.0,
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                autoDebit: true
            ),
            BillItem(
                title: "Atölye Elektrik Faturası",
                amount: 1850.0,
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
                autoDebit: false
            )
        ]
    }
    
    // MARK: - Abonelik & Fatura Metrikleri
    
    public func getSubscriptions() -> [SubscriptionItem] {
        lock.lock()
        defer { lock.unlock() }
        return subscriptions
    }
    
    public func getBills() -> [BillItem] {
        lock.lock()
        defer { lock.unlock() }
        return bills
    }
    
    public func totalMonthlyRecurringCost() -> Double {
        lock.lock()
        defer { lock.unlock() }
        let subTotal = subscriptions.reduce(0) { $0 + ($1.billingCycle == "monthly" ? $1.cost : $1.cost / 12) }
        let billTotal = bills.reduce(0) { $0 + $1.amount }
        return subTotal + billTotal
    }
    
    public func unusedSubscriptions() -> [SubscriptionItem] {
        lock.lock()
        defer { lock.unlock() }
        return subscriptions.filter { $0.isUnusedOrLowUsage }
    }
    
    public func markBillAsPaid(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        if let idx = bills.firstIndex(where: { $0.id == id }) {
            bills[idx].isPaid = true
        }
    }
}
