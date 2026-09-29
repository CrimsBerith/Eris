//
//  ErisEmptyStateView.swift
//  ErisCore — Paylaşımlı Boş Durum Bileşeni
//
//  Sohbet, checklist, hafıza, widget dashboard gibi tüm ekranlarda
//  tekrar eden boş durum mesajlarını tek yerde toplar.
//

import SwiftUI

/// Evrensel boş durum bileşeni.
///
/// Kullanım örneği:
/// ```swift
/// ErisEmptyStateView(
///     icon: "bubble.left.and.bubble.right",
///     title: "Henüz mesaj yok",
///     message: "Eris'e bir şey sor!",
///     action: ErisEmptyAction(label: "Başla", icon: "arrow.right.circle") { ... }
/// )
/// ```
public struct ErisEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: ErisEmptyAction?
    let tintColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var iconPulse = false

    public init(
        icon: String,
        title: String,
        message: String,
        action: ErisEmptyAction? = nil,
        tintColor: Color = ErisTheme.bronzeAccent
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.tintColor = tintColor
    }

    public var body: some View {
        VStack(spacing: 18) {
            // İkon — boşta yavaş nefes animasyonu
            ZStack {
                Circle()
                    .fill(tintColor.opacity(0.08))
                    .frame(width: 72, height: 72)
                    .scaleEffect(iconPulse && !reduceMotion ? 1.06 : 1.0)
                    .animation(
                        reduceMotion ? .default : .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                        value: iconPulse
                    )

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(tintColor.opacity(0.7))
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ErisTheme.coldWhite)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(ErisTheme.coldGray)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            if let action {
                Button(action: action.handler) {
                    HStack(spacing: 6) {
                        Image(systemName: action.icon)
                        Text(action.label)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(tintColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(tintColor.opacity(0.12)))
                    .overlay(Capsule().stroke(tintColor.opacity(0.25), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(action.label)
            }
        }
        .padding(28)
        .frame(maxWidth: 300)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                iconPulse = true
            }
        }
    }
}

// MARK: - Aksiyon Modeli

public struct ErisEmptyAction {
    public let label: String
    public let icon: String
    public let handler: () -> Void

    public init(label: String, icon: String = "arrow.right.circle", handler: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.handler = handler
    }
}

// MARK: - Yerleşik Boş Durum Presetleri

public extension ErisEmptyStateView {
    /// Sohbet — henüz mesaj yok
    static func chat(onStart: @escaping () -> Void) -> ErisEmptyStateView {
        ErisEmptyStateView(
            icon: "bubble.left.and.bubble.right",
            title: "Eris hazır",
            message: "Bir şey sor, not al, plan yap veya sabah brifingini getir.",
            action: ErisEmptyAction(label: "Başla", icon: "mic.circle", handler: onStart),
            tintColor: ErisTheme.bronzeAccent
        )
    }

    /// Hafıza kasa — henüz not yok
    static func memory(onAdd: @escaping () -> Void) -> ErisEmptyStateView {
        ErisEmptyStateView(
            icon: "brain.head.profile",
            title: "Henüz not yok",
            message: "Sesle veya yazarak not ekle; Eris hatırlasın.",
            action: ErisEmptyAction(label: "Not Ekle", icon: "plus.circle", handler: onAdd),
            tintColor: ErisTheme.categoryTechnical
        )
    }

    /// Açık döngüler — temiz
    static func openLoops() -> ErisEmptyStateView {
        ErisEmptyStateView(
            icon: "checkmark.circle",
            title: "Temiz liste!",
            message: "Askıda kalan iş yok. Eris beklemeye devam ediyor.",
            tintColor: ErisTheme.listeningGreen
        )
    }

    /// Checklists — henüz liste yok
    static func checklists(onAdd: @escaping () -> Void) -> ErisEmptyStateView {
        ErisEmptyStateView(
            icon: "checklist",
            title: "Liste yok",
            message: "Seyahat, market, taşınma — ilk listeni oluştur.",
            action: ErisEmptyAction(label: "Liste Oluştur", icon: "plus.circle", handler: onAdd),
            tintColor: ErisTheme.bronzeAccent
        )
    }

    /// Widget dashboard — henüz widget seçilmemiş
    static func widgets(onConfigure: @escaping () -> Void) -> ErisEmptyStateView {
        ErisEmptyStateView(
            icon: "squares.below.rectangle",
            title: "Widget yok",
            message: "Hangi bilgilerin görünmesini istediğini seç.",
            action: ErisEmptyAction(label: "Widget Seç", icon: "gearshape", handler: onConfigure),
            tintColor: ErisTheme.bronzeHighlight
        )
    }
}
