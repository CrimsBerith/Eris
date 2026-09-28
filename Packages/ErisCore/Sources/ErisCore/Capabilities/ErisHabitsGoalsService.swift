//
//  ErisHabitsGoalsService.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation

public struct PersonalGoalItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var targetDate: Date
    public var progressPercent: Int // 0 - 100
    public var milestoneSubtasks: [String]
    public var currentMilestoneIndex: Int
    
    public init(
        id: UUID = UUID(),
        title: String,
        targetDate: Date,
        progressPercent: Int = 0,
        milestoneSubtasks: [String] = [],
        currentMilestoneIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.progressPercent = progressPercent
        self.milestoneSubtasks = milestoneSubtasks
        self.currentMilestoneIndex = currentMilestoneIndex
    }
}

public struct DailyHabitRecord: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var icon: String
    public var currentStreakDays: Int
    public var isCompletedToday: Bool
    public var targetDaysPerWeek: Int
    
    public init(
        id: UUID = UUID(),
        title: String,
        icon: String = "flame.fill",
        currentStreakDays: Int = 0,
        isCompletedToday: Bool = false,
        targetDaysPerWeek: Int = 7
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.currentStreakDays = currentStreakDays
        self.isCompletedToday = isCompletedToday
        self.targetDaysPerWeek = targetDaysPerWeek
    }
}

import Foundation
import Combine

/// Bölüm 22 & 23 ("Kişisel Hedefler, Alışkanlıklar & Rutinler") gereğince:
/// Uzun vadeli hedefleri haftalık mikrogörevlere bölen ve günlük alışkanlık
/// zincirini (streak) takip eden Hedef & Alışkanlık Servisi.
public final class ErisHabitsGoalsService: ObservableObject, @unchecked Sendable {
    public static let shared = ErisHabitsGoalsService()
    
    @Published public private(set) var goals: [PersonalGoalItem] = []
    @Published public private(set) var habits: [DailyHabitRecord] = []
    private let lock = NSLock()
    private let goalsKey = "eris_personal_goals_v1"
    private let habitsKey = "eris_daily_habits_v1"
    private let appGroupSuite = "group.com.alfagolab.eris"
    
    private init() {
        loadData()
    }
    
    private func loadData() {
        let groupDefaults = UserDefaults(suiteName: appGroupSuite)
        var hasGoals = false
        if let data = groupDefaults?.data(forKey: goalsKey) ?? UserDefaults.standard.data(forKey: goalsKey),
           let decoded = try? JSONDecoder().decode([PersonalGoalItem].self, from: data),
           !decoded.isEmpty {
            self.goals = decoded
            hasGoals = true
        }
        
        var hasHabits = false
        if let data = groupDefaults?.data(forKey: habitsKey) ?? UserDefaults.standard.data(forKey: habitsKey),
           let decoded = try? JSONDecoder().decode([DailyHabitRecord].self, from: data),
           !decoded.isEmpty {
            self.habits = decoded
            hasHabits = true
        }
        
        if !hasGoals || !hasHabits {
            loadDefaultSampleGoalsAndHabits()
            saveData()
        }
    }
    
    private func saveData() {
        let groupDefaults = UserDefaults(suiteName: appGroupSuite)
        if let gData = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(gData, forKey: goalsKey)
            groupDefaults?.set(gData, forKey: goalsKey)
        }
        if let hData = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(hData, forKey: habitsKey)
            groupDefaults?.set(hData, forKey: habitsKey)
        }
    }
    
    private func loadDefaultSampleGoalsAndHabits() {
        goals = [
            PersonalGoalItem(
                title: "2026 Eris Life OS Lansmanı & App Store Yayını",
                targetDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(),
                progressPercent: 78,
                milestoneSubtasks: [
                    "Çekirdek mimari ve veri modelleri",
                    "Doğal dil niyet ayrıştırıcı",
                    "iOS & macOS birleşik arayüz",
                    "App Store StoreKit ve inceleme hazırlığı"
                ],
                currentMilestoneIndex: 2
            ),
            PersonalGoalItem(
                title: "İtalyanca B1 Dil Seviyesi",
                targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date(),
                progressPercent: 45,
                milestoneSubtasks: [
                    "Günlük 20 dk pratik",
                    "Gramer temelleri",
                    "Konuşma seansları"
                ],
                currentMilestoneIndex: 1
            )
        ]
        
        habits = [
            DailyHabitRecord(title: "Sabah Brifingi & Günün Planı", icon: "sun.max.fill", currentStreakDays: 14, isCompletedToday: true),
            DailyHabitRecord(title: "45 Dakika Yürüyüş / Spor", icon: "figure.walk", currentStreakDays: 8, isCompletedToday: false),
            DailyHabitRecord(title: "20 Sayfa Tasarım / Teknik Okuma", icon: "book.fill", currentStreakDays: 5, isCompletedToday: false)
        ]
    }
    
    public func getGoals() -> [PersonalGoalItem] {
        lock.lock()
        defer { lock.unlock() }
        return goals
    }
    
    public func getHabits() -> [DailyHabitRecord] {
        lock.lock()
        defer { lock.unlock() }
        return habits
    }
    
    public func toggleHabit(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        if let idx = habits.firstIndex(where: { $0.id == id }) {
            habits[idx].isCompletedToday.toggle()
            if habits[idx].isCompletedToday {
                habits[idx].currentStreakDays += 1
            } else {
                habits[idx].currentStreakDays = max(0, habits[idx].currentStreakDays - 1)
            }
            saveData()
        }
    }
}
