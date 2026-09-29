//
//  ErisAnimations.swift
//  ErisCore — Paylaşımlı Animasyon Uzantıları
//

import SwiftUI

// MARK: - Özel Geçiş (Transition) Tanımları

public extension AnyTransition {
    /// Mesaj baloncuğu giriş animasyonu — alttan kayma + fade
    static var messageEntry: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.95, anchor: .bottom)),
            removal: .opacity
        )
    }
    
    /// Widget kartı açılış animasyonu — ölçeklenme + fade
    static var cardReveal: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.92, anchor: .center)
                .combined(with: .opacity),
            removal: .opacity
        )
    }
    
    /// Onay banner'ı — yatay kayma
    static var approvalSlide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    /// Toast bildirim — yukarı kayma + fade
    static var toastUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom)
                .combined(with: .opacity),
            removal: .move(edge: .bottom)
                .combined(with: .opacity)
        )
    }
}

// MARK: - Özel Animasyon Presetleri

public extension Animation {
    /// Sheet açılışı — yay animasyonu
    static var sheetSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.85)
    }
    
    /// Tab değişimi — hızlı yay
    static var tabSwitch: Animation {
        .spring(response: 0.35, dampingFraction: 0.9)
    }
    
    /// Kart giriş — yumuşak
    static var cardEntry: Animation {
        .easeOut(duration: 0.3)
    }
    
    /// Mesaj giriş — orta hız
    static var messageEntry: Animation {
        .spring(response: 0.35, dampingFraction: 0.82)
    }
    
    /// Hızlı fade — mikroetkileşimler
    static var quickFade: Animation {
        .easeInOut(duration: 0.2)
    }
    
    /// Nabız animasyonu — sonsuz tekrar
    static var pulse: Animation {
        .easeInOut(duration: 1.2).repeatForever(autoreverses: false)
    }
}

// MARK: - View Uzantıları

public extension View {
    /// Glassmorphism kart gölgesi
    func glassCardShadow(radius: CGFloat = 8) -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: radius, y: 2)
    }

    /// Bronz hover glow efekti (macOS)
    func bronzeGlow(isActive: Bool = false) -> some View {
        self.shadow(
            color: isActive
                ? ErisTheme.bronzeHighlight.opacity(0.15)
                : Color.clear,
            radius: 12, y: 0
        )
    }

    /// Darbeli (pulsing) kenar efekti — dinleme durumunda
    /// Reduce Motion aktifse animasyon atlanır, yalnızca renk değişir
    func pulsingBorder(isActive: Bool, color: Color = ErisTheme.listeningGreen) -> some View {
        self.modifier(PulsingBorderModifier(isActive: isActive, color: color))
    }

    /// Animasyonlu görünürlük — kart ve widget giriş/çıkışları
    func animatedVisibility(_ isVisible: Bool, transition: AnyTransition = .cardReveal) -> some View {
        Group {
            if isVisible {
                self.transition(transition)
            }
        }
        .animation(.cardEntry, value: isVisible)
    }

    /// Reduce Transparency aktifken opaklığı tam, değilse verilen değer
    func adaptiveOpacity(_ opacity: Double) -> some View {
        self.modifier(AdaptiveOpacityModifier(targetOpacity: opacity))
    }
}

// MARK: - Accessibility-Aware Modifier'lar

/// Reduce Motion ortam değerini dinleyerek nabız animasyonunu yöneten modifier
private struct PulsingBorderModifier: ViewModifier {
    let isActive: Bool
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(isActive ? 0.5 : 0), lineWidth: 1.5)
                .animation(
                    isActive && !reduceMotion
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: isActive
                )
        )
    }
}

/// Reduce Transparency aktifken opaklığı tam verir
private struct AdaptiveOpacityModifier: ViewModifier {
    let targetOpacity: Double
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content.opacity(reduceTransparency ? 1.0 : targetOpacity)
    }
}

// MARK: - Haptik Geri Bildirim Yardımcısı (iOS)

#if os(iOS)
public enum ErisHaptics {
    /// Hafif dokunuş — sekme geçişleri, seçim
    public static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    /// Orta dokunuş — buton basışları, kart kaldırma
    public static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    /// Başarı bildirimi — onay, tamamlama
    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    /// Hata bildirimi — red, başarısız eylem
    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    /// Uyarı bildirimi — sıfır-güven kapısı
    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
#endif

// MARK: - Not Kayıt Toast Bileşeni

/// Ekranın altında beliren "Not kaydedildi" toast bildirimi
public struct SaveNoteToast: View {
    let message: String
    let category: MemoryCategory
    @Binding var isShowing: Bool
    
    public init(message: String, category: MemoryCategory, isShowing: Binding<Bool>) {
        self.message = message
        self.category = category
        self._isShowing = isShowing
    }
    
    public var body: some View {
        if isShowing {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(ErisTheme.listeningGreen)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(message)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    CategoryBadge(category: category, size: .compact)
                }
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.quickFade) { isShowing = false }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ErisTheme.coldGray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ErisTheme.graphiteSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ErisTheme.listeningGreen.opacity(0.3), lineWidth: 0.8)
                    )
            )
            .shadow(color: ErisTheme.listeningGreen.opacity(0.1), radius: 12, y: 4)
            .padding(.horizontal, 16)
            .transition(.toastUp)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.quickFade) { isShowing = false }
                }
            }
        }
    }
}

// MARK: - Shimmer Yükleme Efekti

/// İçerik yüklenirken gösterilen shimmer animasyonu
public struct ShimmerView: View {
    @State private var phase: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white, .clear],
                            startPoint: .init(x: phase - 0.5, y: 0.5),
                            endPoint: .init(x: phase + 0.5, y: 0.5)
                        )
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}
