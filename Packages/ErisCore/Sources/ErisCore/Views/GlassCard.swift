//
//  GlassCard.swift
//  ErisCore — Paylaşımlı Glassmorphism Kart Bileşeni
//

import SwiftUI

/// Eris tasarım dilinde glassmorphism tarzında yeniden kullanılabilir kart bileşeni.
/// Her iki platform (iOS + macOS) için ortak kullanım sağlar.
public struct GlassCard<Content: View>: View {
    let isPinned: Bool
    let cornerRadius: CGFloat
    let content: Content
    
    public init(
        isPinned: Bool = false,
        cornerRadius: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.isPinned = isPinned
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(ErisTheme.cardSurfaceGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                isPinned
                                    ? ErisTheme.bronzeAccent.opacity(0.35)
                                    : Color.white.opacity(0.06),
                                lineWidth: 0.8
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 2)
    }
}

/// Küçük glassmorphism kart — sidebar widget'ları için
public struct GlassCardCompact<Content: View>: View {
    let cornerRadius: CGFloat
    let content: Content
    
    public init(
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(ErisTheme.bronzeAccent.opacity(0.18), lineWidth: 0.8)
                    )
            )
    }
}

/// Widget kart başlığı bileşeni — tutarlı ikon + başlık + aksiyon düzeni
public struct GlassCardHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let trailing: AnyView?
    
    public init(
        icon: String,
        iconColor: Color = ErisTheme.bronzeHighlight,
        title: String,
        trailing: AnyView? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.trailing = trailing
    }
    
    public var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.subheadline)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
            }
            
            Spacer()
            
            if let trailingView = trailing {
                trailingView
            }
        }
    }
}

/// Glassmorphism stilde pill buton — canlı bilgi şeridi için
public struct GlassPillButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isHighlighted: Bool
    let action: () -> Void
    
    public init(
        icon: String,
        iconColor: Color = ErisTheme.bronzeHighlight,
        title: String,
        isHighlighted: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.isHighlighted = isHighlighted
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                if !title.isEmpty {
                    Text(title)
                        .font(.caption2).bold()
                        .foregroundColor(ErisTheme.coldWhite)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isHighlighted
                          ? ErisTheme.bronzeHighlight.opacity(0.2)
                          : Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(
                                isHighlighted
                                    ? ErisTheme.bronzeAccent.opacity(0.4)
                                    : Color.white.opacity(0.15),
                                lineWidth: 0.8
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
