//
//  OpenLoopCardView.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import SwiftUI

/// Bölüm 42 ("Hayatındaki Açık İşleri Otomatik Bulma") gereğince:
/// Açık Döngü kartı — macOS Sidebar ve iOS Dashboard'da gösterilen
/// zihinsel yükü azaltıcı şık Glassmorphism kartı.
public struct OpenLoopCardView: View {
    public let loop: OpenLoopItem
    public let onComplete: () -> Void
    public let onDismiss: () -> Void
    
    public init(
        loop: OpenLoopItem,
        onComplete: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.loop = loop
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Tamamlama butonu
            Button(action: onComplete) {
                Image(systemName: loop.status == .completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(loop.status == .completed ? ErisTheme.listeningGreen : ErisTheme.coldGray)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            .accessibilityLabel(loop.status == .completed ? "Tamamlandı olarak işaretlendi" : "Tamamlandı olarak işaretle")
            .accessibilityHint(loop.title)
            
            VStack(alignment: .leading, spacing: 4) {
                // Alan & Aciliyet rozeti
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: loop.domain.icon)
                        Text(loop.domain.shortDisplayName)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(ErisTheme.bronzeAccent.opacity(0.15)))
                    
                    Spacer()
                    
                    if let due = loop.dueDate {
                        Text(relativeDateString(for: due))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(urgencyColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                
                Text(loop.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(loop.status == .completed ? ErisTheme.coldGray : ErisTheme.coldWhite)
                    .strikethrough(loop.status == .completed)
                
                if !loop.details.isEmpty {
                    Text(loop.details)
                        .font(.system(size: 11.5))
                        .foregroundColor(ErisTheme.coldGray)
                        .lineLimit(2)
                }
                
                if !loop.suggestedAction.isEmpty && loop.status != .completed {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.thinkingAmber)
                        Text(loop.suggestedAction)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    .padding(.top, 2)
                }
            }
            
            // Kapatma / Kaldırma butonu
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                    .padding(4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kaldır")
            .accessibilityHint("Bu açık döngüyü listeden kaldırır")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(loop.domain.shortDisplayName): \(loop.title)")
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.5)
        )
    }
    
    private var urgencyColor: Color {
        switch loop.urgency {
        case .low: return ErisTheme.coldGray
        case .medium: return ErisTheme.thinkingAmber
        case .high, .urgent: return Color(hex: "FF5E57")
        }
    }
    
    private func relativeDateString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Bugün"
        } else if calendar.isDateInTomorrow(date) {
            return "Yarın"
        } else {
            let days = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
            if days > 0 {
                return "\(days) gün kaldı"
            } else {
                return "Süresi geçti"
            }
        }
    }
}
