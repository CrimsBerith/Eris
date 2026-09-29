import SwiftUI

public struct VoiceWaveformView: View {
    @State private var phase: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var isListening: Bool
    public var isSpeaking: Bool
    public var audioLevel: Float = 0.0
    public var barCount: Int = 16

    /// Aktif ses durumu — animasyon yalnızca dinlerken veya konuşurken çalışır (pil tasarrufu)
    private var isActive: Bool { isListening || isSpeaking }

    public init(isListening: Bool, isSpeaking: Bool, audioLevel: Float = 0.0, barCount: Int = 16) {
        self.isListening = isListening
        self.isSpeaking = isSpeaking
        self.audioLevel = audioLevel
        self.barCount = barCount
    }

    public var body: some View {
        HStack(spacing: 3.5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(
                        LinearGradient(
                            colors: waveGradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: 3.5,
                        height: barHeight(for: index)
                    )
                    .shadow(color: glowColor.opacity(isActive ? 0.45 : 0.0), radius: 4)
                    // Reduce Motion kapalıysa ve aktif durumdayken animasyonu uygula
                    .animation(
                        isActive && !reduceMotion
                            ? .easeInOut(duration: 0.15).repeatForever(autoreverses: true)
                            : .default,
                        value: phase
                    )
            }
        }
        .frame(height: 34)
        .padding(.horizontal, 8)
        .accessibilityHidden(true) // Dekoratif ses dalgası — VoiceOver için gizle
        .onChange(of: isActive) { _, active in
            // Sadece aktif modda animasyonu başlat; boşta durdurup faz sıfırla (pil tasarrufu)
            if active && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    phase = 1.0
                }
            } else {
                withAnimation(.default) { phase = 0 }
            }
        }
        .onAppear {
            if isActive && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    phase = 1.0
                }
            }
        }
    }
    
    private var waveGradientColors: [Color] {
        if isListening {
            return [
                ErisTheme.listeningGreen,
                ErisTheme.bronzeAccent
            ]
        } else if isSpeaking {
            return [
                ErisTheme.bronzeLight,
                ErisTheme.bronzeAccent
            ]
        } else {
            return [
                ErisTheme.coldGray.opacity(0.5),
                ErisTheme.graphiteSurface
            ]
        }
    }
    
    private var glowColor: Color {
        if isListening {
            return ErisTheme.listeningGreen
        } else if isSpeaking {
            return ErisTheme.bronzeHighlight
        } else {
            return .clear
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        if isListening || isSpeaking {
            let normalizedIndex = Double(index) / Double(max(1, barCount - 1))
            let centerCurve = sin(normalizedIndex * .pi)
            let wavePhase = sin(Double(index) * 0.5 + phase * 3.1415)
            let levelBonus = CGFloat(min(max(audioLevel, 0.0), 1.0)) * 36.0
            let dynamic = abs(wavePhase) * (14.0 * centerCurve) + 6.0 + levelBonus
            return max(5, min(32, dynamic))
        }
        return 4.5
    }
}
