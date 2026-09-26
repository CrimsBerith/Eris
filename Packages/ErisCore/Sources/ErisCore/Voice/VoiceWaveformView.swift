import SwiftUI

public struct VoiceWaveformView: View {
    @State private var phase: Double = 0
    public var isListening: Bool
    public var isSpeaking: Bool
    public var audioLevel: Float = 0.0
    
    public init(isListening: Bool, isSpeaking: Bool, audioLevel: Float = 0.0) {
        self.isListening = isListening
        self.isSpeaking = isSpeaking
        self.audioLevel = audioLevel
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<18) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.72, blue: 0.58), // Soğuk bronz açık
                                Color(red: 0.58, green: 0.48, blue: 0.40)  // Bronz koyu
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: 3.5,
                        height: barHeight(for: index)
                    )
                    .animation(
                        .easeInOut(duration: 0.18).repeatForever(autoreverses: true),
                        value: phase
                    )
            }
        }
        .frame(height: 36)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                phase = 1.0
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        if isListening || isSpeaking {
            let base = CGFloat(sin(Double(index) * 0.45 + phase * 3.14))
            let levelBonus = CGFloat(audioLevel) * 45.0
            return max(6, abs(base * 16) + 8 + levelBonus)
        }
        return 5 // Rölanti durumu
    }
}
