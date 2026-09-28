//
//  ErisLivingChecklistEngine.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import Foundation
import Combine

/// Bölüm 38 ("Yaşayan Checklists — Hayatın Sürekli Değişen Listeleri") gereğince:
/// Seyahat bavulu, taşınma, ev bakımı, market ve kiler listelerini dinamik olarak
/// yöneten ve hava durumu / takvime göre uyarlayan Zekâ Motoru.
public final class ErisLivingChecklistEngine: ObservableObject, @unchecked Sendable {
    public static let shared = ErisLivingChecklistEngine()
    
    @Published public private(set) var checklists: [LivingChecklist] = []
    
    private let queue = DispatchQueue(label: "com.eris.checklists", qos: .userInitiated)
    
    private init() {
        loadDefaultChecklists()
    }
    
    private func loadDefaultChecklists() {
        self.checklists = [
            LivingChecklist(
                title: "Seyahat & Bavul Hazırlığı",
                type: .travelPacking,
                items: [
                    ChecklistItem(title: "Pasaport / Kimlik & Cüzdan", isCompleted: true, category: "Belgeler"),
                    ChecklistItem(title: "MacBook & Şarj Adaptörü", isCompleted: false, category: "Elektronik"),
                    ChecklistItem(title: "Evrak ve sözleşme kopyaları", isCompleted: false, category: "Belgeler"),
                    ChecklistItem(title: "Güneş gözlüğü & İlaç çantası", isCompleted: false, category: "Kişisel")
                ],
                targetDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                destinationCity: "Londra",
                weatherNote: "Yağmurlu ve 14°C — Şemsiye & Trençkot gerekli"
            ),
            LivingChecklist(
                title: "Haftalık Ev & Mutfak Rutini",
                type: .homeChores,
                items: [
                    ChecklistItem(title: "Kahve çekirdeği & Süt takviyesi", isCompleted: false, category: "Mutfak"),
                    ChecklistItem(title: "Su filtresi değişimi", isCompleted: true, category: "Ev Bakım"),
                    ChecklistItem(title: "Geri dönüşüm ve çöp tasnifi", isCompleted: false, category: "Düzen")
                ]
            ),
            LivingChecklist(
                title: "Market & Kiler Takviyesi",
                type: .groceryPantry,
                items: [
                    ChecklistItem(title: "Soğuk sıkım zeytinyağı", isCompleted: false, category: "Kiler"),
                    ChecklistItem(title: "Organik yumurta (10'lu)", isCompleted: true, category: "Şarküteri"),
                    ChecklistItem(title: "Badem sütü", isCompleted: false, category: "İçecek"),
                    ChecklistItem(title: "Ekmek & Fırın ürünleri", isCompleted: false, category: "Fırın")
                ]
            ),
            LivingChecklist(
                title: "Taşınma & Yaşam Lojistiği",
                type: .relocationMoving,
                items: [
                    ChecklistItem(title: "İnternet ve fiber nakil başvurusu", isCompleted: true, category: "Abonelik"),
                    ChecklistItem(title: "Elektrik ve su abonelik devri", isCompleted: false, category: "Resmi"),
                    ChecklistItem(title: "Koli ve eşya sigortası", isCompleted: false, category: "Lojistik"),
                    ChecklistItem(title: "Nüfus & İkametgah adres güncellemesi", isCompleted: false, category: "Devlet")
                ]
            )
        ]
    }
    
    // MARK: - Liste İşlemleri
    
    public func toggleItem(checklistId: UUID, itemId: UUID) {
        queue.async {
            DispatchQueue.main.async {
                guard let listIdx = self.checklists.firstIndex(where: { $0.id == checklistId }),
                      let itemIdx = self.checklists[listIdx].items.firstIndex(where: { $0.id == itemId }) else { return }
                
                self.checklists[listIdx].items[itemIdx].isCompleted.toggle()
                self.checklists[listIdx].updatedAt = Date()
            }
        }
    }
    
    public func addItem(checklistId: UUID, title: String, category: String? = nil) {
        queue.async {
            DispatchQueue.main.async {
                guard let listIdx = self.checklists.firstIndex(where: { $0.id == checklistId }) else { return }
                let newItem = ChecklistItem(title: title, category: category)
                self.checklists[listIdx].items.append(newItem)
                self.checklists[listIdx].updatedAt = Date()
            }
        }
    }
    
    public func createChecklist(title: String, type: ChecklistType, items: [String], destinationCity: String? = nil, weatherNote: String? = nil) {
        let checklistItems = items.map { ChecklistItem(title: $0) }
        let checklist = LivingChecklist(
            title: title,
            type: type,
            items: checklistItems,
            destinationCity: destinationCity,
            weatherNote: weatherNote
        )
        queue.async {
            DispatchQueue.main.async {
                self.checklists.insert(checklist, at: 0)
            }
        }
    }
    
    public func deleteItem(checklistId: UUID, itemId: UUID) {
        queue.async {
            DispatchQueue.main.async {
                guard let listIdx = self.checklists.firstIndex(where: { $0.id == checklistId }) else { return }
                self.checklists[listIdx].items.removeAll(where: { $0.id == itemId })
                self.checklists[listIdx].updatedAt = Date()
            }
        }
    }
    
    public func deleteChecklist(id: UUID) {
        queue.async {
            DispatchQueue.main.async {
                self.checklists.removeAll(where: { $0.id == id })
            }
        }
    }
    
    public func clearCompletedItems(checklistId: UUID) {
        queue.async {
            DispatchQueue.main.async {
                guard let listIdx = self.checklists.firstIndex(where: { $0.id == checklistId }) else { return }
                self.checklists[listIdx].items.removeAll(where: { $0.isCompleted })
                self.checklists[listIdx].updatedAt = Date()
            }
        }
    }
    
    public func completeAllItems(checklistId: UUID) {
        queue.async {
            DispatchQueue.main.async {
                guard let listIdx = self.checklists.firstIndex(where: { $0.id == checklistId }) else { return }
                for i in 0..<self.checklists[listIdx].items.count {
                    self.checklists[listIdx].items[i].isCompleted = true
                }
                self.checklists[listIdx].updatedAt = Date()
            }
        }
    }
}
