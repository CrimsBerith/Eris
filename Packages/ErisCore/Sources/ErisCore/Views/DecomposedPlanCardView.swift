//
//  DecomposedPlanCardView.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import SwiftUI

/// Bölüm 41 ("Doğal Dil ile Hayatı Yönetme") gereğince:
/// Kullanıcının karmaşık çoklu niyet komutlarından (örn: "Sabah işe gitmeden önce yakıt al,
/// markete uğra ve toplantı dosyasını hazırla") türetilen alt adımları ve yaşam planını
/// görselleştiren etkileşimli kart bileşeni.
public struct DecomposedPlanCardView: View {
    public let plan: DecomposedPlan
    public let onScheduleAll: () -> Void
    public let onTransferToOpenLoops: () -> Void
    
    @State private var isScheduled: Bool = false
    @State private var isSavedToLoops: Bool = false
    
    public init(
        plan: DecomposedPlan,
        onScheduleAll: @escaping () -> Void = {},
        onTransferToOpenLoops: @escaping () -> Void = {}
    ) {
        self.plan = plan
        self.onScheduleAll = onScheduleAll
        self.onTransferToOpenLoops = onTransferToOpenLoops
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(ErisTheme.thinkingAmber)
                    .font(.system(size: 14, weight: .bold))
                
                Text("ERIS ENTEGRE YAŞAM PLANI")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                
                Spacer()
                
                Text("\(plan.steps.count) Alt Adım")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ErisTheme.thinkingAmber)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(ErisTheme.thinkingAmber.opacity(0.15)))
            }
            
            Text(plan.summary)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ErisTheme.coldWhite)
            
            Divider().background(ErisTheme.bronzeAccent.opacity(0.2))
            
            // Adım Listesi
            VStack(alignment: .leading, spacing: 10) {
                ForEach(plan.steps) { step in
                    HStack(alignment: .top, spacing: 10) {
                        // Numara balonu
                        Text("\(step.orderIndex)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(ErisTheme.bronzeHighlight))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: step.domain.icon)
                                    .font(.system(size: 10))
                                    .foregroundColor(ErisTheme.bronzeAccent)
                                
                                Text(step.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(ErisTheme.coldWhite)
                                
                                Spacer()
                                
                                if let duration = step.estimatedDurationMinutes {
                                    Text("\(duration) dk")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(ErisTheme.coldGray)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.white.opacity(0.06)))
                                }
                            }
                            
                            if !step.details.isEmpty {
                                Text(step.details)
                                    .font(.system(size: 11))
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                        }
                    }
                }
            }
            
            Divider().background(ErisTheme.bronzeAccent.opacity(0.2))
            
            // Aksiyon Butonları
            HStack(spacing: 8) {
                Button(action: {
                    onTransferToOpenLoops()
                    withAnimation { isSavedToLoops = true }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isSavedToLoops ? "checkmark.circle.fill" : "checklist")
                        Text(isSavedToLoops ? "Açık İşlere Eklendi" : "Açık İşlere Aktar")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSavedToLoops ? ErisTheme.listeningGreen : ErisTheme.coldWhite)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    onScheduleAll()
                    withAnimation { isScheduled = true }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isScheduled ? "checkmark.circle.fill" : "calendar.badge.plus")
                        Text(isScheduled ? "Takvime Planlandı" : "Planı Onayla")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isScheduled ? ErisTheme.listeningGreen : ErisTheme.bronzeHighlight)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "181A1F").opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ErisTheme.bronzeAccent.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 3)
    }
}
