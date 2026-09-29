//
//  GlassCard.swift
//  ErisCore — Paylaşımlı Glassmorphism / Liquid Glass Kart Bileşeni
//
//  iOS 26+ / macOS 26+ → Apple Liquid Glass (.glassEffect)
//  iOS 17–25 / macOS 14–25 → El yapımı glassmorphism (mevcut tasarım)
//

import SwiftUI

// MARK: - Merkezi erisGlass View Uzantısı

public extension View {
    /// Eris tasarım dili için birleşik cam efekti.
    ///
    /// - iOS 26+ / macOS 26+: Apple'ın yerli `.glassEffect` modifier'ını kullanır.
    ///   Reduce Transparency'e, hover/interactive tepkilere otomatik uyum sağlar.
    /// - iOS 17-25 / macOS 14-25: Önceki el yapımı glassmorphism overlay'ine döner.
    ///
    /// Kullanım:
    /// ```swift
    /// Text("Merhaba")
    ///     .padding()
    ///     .erisGlass(in: RoundedRectangle(cornerRadius: 14))
    /// ```
    func erisGlass(
        in shape: some Shape = RoundedRectangle(cornerRadius: 14),
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        self.modifier(ErisGlassModifier(shape: AnyShape(shape), tint: tint, interactive: interactive))
    }
}

// MARK: - ErisGlassModifier

private struct ErisGlassModifier: ViewModifier {
    let shape: AnyShape
    let tint: Color?
    let interactive: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            liquidGlass(content: content)
        } else {
            legacyGlass(content: content)
        }
    }

    // MARK: Liquid Glass (iOS 26+ / macOS 26+)
    @available(iOS 26, macOS 26, *)
    private func liquidGlass(content: Content) -> some View {
        var glass = Glass.regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return content.glassEffect(glass, in: shape)
    }

    // MARK: Eski Glassmorphism (iOS 17–25 / macOS 14–25)
    private func legacyGlass(content: Content) -> some View {
        content
            .background(
                shape.fill(
                    reduceTransparency
                        ? AnyShapeStyle(ErisTheme.graphiteSurface)
                        : AnyShapeStyle(ErisTheme.cardSurfaceGradient)
                )
                .overlay(shape.stroke(Color.white.opacity(0.06), lineWidth: 0.8))
            )
            .shadow(color: Color.black.opacity(0.12), radius: 8, y: 2)
    }
}

// MARK: - GlassCard

/// Eris tasarım dilinde yeniden kullanılabilir cam kart bileşeni.
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
            .erisGlass(
                in: RoundedRectangle(cornerRadius: cornerRadius),
                tint: isPinned ? ErisTheme.bronzeAccent : nil
            )
            .overlay(
                // Sabitlenmiş notta ince bronz kenar vurgusu
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isPinned
                            ? ErisTheme.bronzeAccent.opacity(0.3)
                            : Color.clear,
                        lineWidth: 0.8
                    )
            )
    }
}

// MARK: - GlassCardCompact

/// Küçük cam kart — sidebar widget'ları ve kompakt listeler için
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
            .erisGlass(in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - GlassCardHeader

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
                    .accessibilityHidden(true) // Dekoratif — başlıkla birlikte okunmasın
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(ErisTheme.bronzeHighlight)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            if let trailingView = trailing {
                trailingView
            }
        }
    }
}

// MARK: - GlassPillButton

/// Cam stilde pill buton — canlı bilgi şeridi ve hızlı aksiyonlar için
public struct GlassPillButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isHighlighted: Bool
    let pillAccessibilityLabel: String?
    let action: () -> Void

    public init(
        icon: String,
        iconColor: Color = ErisTheme.bronzeHighlight,
        title: String,
        isHighlighted: Bool = false,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.isHighlighted = isHighlighted
        self.pillAccessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .accessibilityHidden(true)
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
        .accessibilityLabel(pillAccessibilityLabel ?? title)
    }
}

// MARK: - ErisGlassGroup (GlassEffectContainer Sarmalayıcı)

/// Birden fazla cam efektini morph geçişleriyle bir arada gruplar (iOS 26+).
/// Eski OS'ta basit Group olarak davranır.
public struct ErisGlassGroup<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26, macOS 26, *) {
            GlassEffectContainer { content }
        } else {
            content
        }
    }
}
