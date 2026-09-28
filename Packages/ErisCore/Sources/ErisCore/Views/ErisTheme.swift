import SwiftUI

public struct ErisTheme {
    // 2.1 Tasarım Şartnamesi Renk Paleti:
    // Grafit: #121316, Bronz vurgu: #A39890, Soğuk bronz: #C4B5A5, Soğuk beyaz: #E5E5E7
    public static let graphite = Color(red: 0.071, green: 0.075, blue: 0.086) // #121316
    public static let graphiteLight = Color(red: 0.106, green: 0.114, blue: 0.133) // #1B1D22
    public static let graphiteSurface = Color(red: 0.133, green: 0.141, blue: 0.165) // #22242A
    
    public static let bronzeAccent = Color(red: 0.639, green: 0.596, blue: 0.565) // #A39890
    public static let bronzeHighlight = Color(red: 0.768, green: 0.709, blue: 0.647) // #C4B5A5
    public static let bronzeLight = Color(red: 0.85, green: 0.78, blue: 0.72)
    public static let bronzeGlow = Color(red: 0.639, green: 0.596, blue: 0.565).opacity(0.35)
    
    public static let coldWhite = Color(red: 0.898, green: 0.898, blue: 0.906) // #E5E5E7
    public static let coldGray = Color(red: 0.55, green: 0.56, blue: 0.60)
    
    public static let listeningGreen = Color(red: 0.22, green: 0.85, blue: 0.54)
    public static let thinkingAmber = Color(red: 0.95, green: 0.75, blue: 0.35)
    
    // MARK: - Kategori Renkleri
    public static let categoryDocument = Color(red: 0.45, green: 0.75, blue: 0.95)
    public static let categoryTechnical = Color(red: 0.45, green: 0.90, blue: 0.65)
    public static let categoryFinance = Color(red: 0.95, green: 0.80, blue: 0.35)
    public static let categoryDesign = Color(red: 0.75, green: 0.60, blue: 0.95)
    public static let categoryProject = Color(red: 0.95, green: 0.60, blue: 0.45)
    public static let categoryPerson = Color(red: 0.45, green: 0.85, blue: 0.85)
    public static let categoryFabric = Color(red: 0.95, green: 0.75, blue: 0.45)
    public static let categoryMaritime = Color(red: 0.4, green: 0.7, blue: 0.9)
    public static let sourceVoice = Color(red: 0.75, green: 0.60, blue: 0.95)
    
    // MARK: - Glassmorphism Arka Plan Gradient
    public static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                graphite,
                Color(red: 0.055, green: 0.059, blue: 0.067)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Kart Yüzey Gradient
    public static var cardSurfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.06),
                Color.white.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Kullanıcı Mesaj Baloncuğu Gradient
    public static var userBubbleGradient: LinearGradient {
        LinearGradient(
            colors: [graphiteSurface, graphiteLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Kategori Rengi Helper
    public static func categoryColor(for category: MemoryCategory) -> Color {
        switch category {
        case .document: return categoryDocument
        case .technical: return categoryTechnical
        case .finance: return categoryFinance
        case .designIdea: return categoryDesign
        case .project: return categoryProject
        case .person: return categoryPerson
        case .fabricCost: return categoryFabric
        case .maritime: return categoryMaritime
        case .preference, .instruction: return bronzeHighlight
        }
    }
    
    // MARK: - Kaynak İkon Helper
    public static func sourceIcon(for source: String) -> String {
        switch source.lowercased() {
        case "voice": return "waveform"
        case "chat": return "bubble.left.fill"
        default: return "square.and.pencil"
        }
    }
    
    // MARK: - Kaynak Metin Helper
    public static func sourceDisplayName(for source: String) -> String {
        switch source.lowercased() {
        case "voice": return "Sesli"
        case "chat": return "Sohbet"
        default: return "Manuel"
        }
    }
}

// Durum Mikro-Animasyon Görünümü
public struct ErisStatusBadgeView: View {
    public let isListening: Bool
    public let isThinking: Bool
    public let isSpeaking: Bool
    
    @State private var pulse: Bool = false
    
    public init(isListening: Bool, isThinking: Bool, isSpeaking: Bool) {
        self.isListening = isListening
        self.isThinking = isThinking
        self.isSpeaking = isSpeaking
    }
    
    public var body: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                if isListening || isThinking || isSpeaking {
                    Circle()
                        .stroke(statusColor.opacity(0.6), lineWidth: 1.5)
                        .frame(width: pulse ? 18 : 8, height: pulse ? 18 : 8)
                        .opacity(pulse ? 0 : 0.8)
                }
            }
            
            Text(statusText)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(statusColor)
                .transition(.opacity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: 0.8)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
    
    private var statusColor: Color {
        if isListening {
            return ErisTheme.listeningGreen
        } else if isThinking {
            return ErisTheme.thinkingAmber
        } else if isSpeaking {
            return ErisTheme.bronzeHighlight
        } else {
            return ErisTheme.coldGray
        }
    }
    
    private var statusText: String {
        if isListening {
            return "Dinliyor…"
        } else if isThinking {
            return "Düşünüyor…"
        } else if isSpeaking {
            return "Konuşuyor…"
        } else {
            return "Hazır"
        }
    }
}

// MARK: - Hex Color Extension
public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
