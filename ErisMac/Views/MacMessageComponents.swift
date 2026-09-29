import SwiftUI
import AppKit
import ErisCore

// MARK: - Glassmorphism Mesaj Baloncuğu

// MARK: - Paylaşılan DateFormatter (her baloncukta yeni örnek oluşturma maliyetini önler)
private extension DateFormatter {
    static let messageTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
}

struct GlassMessageBubble: View {
    let message: Message
    @State private var isCopied: Bool = false
    @State private var isHovering: Bool = false

    private var formattedTime: String {
        DateFormatter.messageTime.string(from: message.timestamp)
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 13.5))
                        .padding(13)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            ErisTheme.graphiteSurface,
                                            ErisTheme.graphiteLight
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(ErisTheme.bronzeAccent.opacity(0.28), lineWidth: 0.8)
                                )
                        )
                        .foregroundColor(ErisTheme.coldWhite)
                        .shadow(color: Color.black.opacity(0.25), radius: 5, y: 2)
                    
                    HStack(spacing: 4) {
                        if message.isAudioTranscript {
                            Image(systemName: "waveform")
                                .font(.system(size: 8))
                                .foregroundColor(ErisTheme.sourceVoice.opacity(0.8))
                                .accessibilityLabel("Sesli mesaj")
                        }
                        Text(formattedTime)
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                            .accessibilityLabel("Saat \(formattedTime)")
                    }
                    .padding(.trailing, 4)
                }
                .frame(maxWidth: 580, alignment: .trailing)
                .contextMenu {
                    Button(action: { copyToClipboard(message.content) }) {
                        Label("Kopyala", systemImage: "doc.on.doc")
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 10))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        Text("ERIS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                        
                        Spacer()
                        
                        Text(formattedTime)
                            .font(.system(size: 9))
                            .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                    }
                    
                    Text(message.content)
                        .font(.system(size: 13.5))
                        .lineSpacing(3)
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    if let plan = message.plan {
                        DecomposedPlanCardView(
                            plan: plan,
                            onScheduleAll: {},
                            onTransferToOpenLoops: {
                                for step in plan.steps {
                                    ErisOpenLoopsEngine.shared.addLoop(OpenLoopItem(domain: step.domain, title: step.title, details: step.details, detectedSource: "chat_plan"))
                                }
                            }
                        )
                        .padding(.top, 6)
                    }
                    
                    // Kolay Eylem Çubuğu: Kopyala & Seslendir
                    HStack(spacing: 8) {
                        Button(action: {
                            copyToClipboard(message.content)
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                isCopied = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 9))
                                Text(isCopied ? "Kopyalandı" : "Kopyala")
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            .foregroundColor(isCopied ? ErisTheme.listeningGreen : ErisTheme.coldGray)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Metni Panoya Kopyala")
                        .accessibilityLabel(isCopied ? "Kopyalandı" : "Metni kopyala")

                        Button(action: {
                            if ErisSpeaker.shared.isSpeaking {
                                ErisSpeaker.shared.stopSpeaking()
                            } else {
                                ErisSpeaker.shared.speak(message.content)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 9))
                                Text("Seslendir")
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            .foregroundColor(ErisTheme.coldGray)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Cevabı Seslendir / Durdur")
                        .accessibilityLabel("Seslendir veya durdur")
                        
                        Spacer()
                    }
                    .padding(.top, 3)
                    .opacity(isHovering || isCopied ? 1.0 : 0.5)
                }
                .padding(13)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ErisTheme.bronzeHighlight.opacity(0.35), lineWidth: 0.8)
                        )
                )
                .shadow(color: ErisTheme.bronzeHighlight.opacity(0.08), radius: 8, y: 2)
                .frame(maxWidth: 620, alignment: .leading)
                .onHover { isHovering = $0 }
                .contextMenu {
                    Button(action: { copyToClipboard(message.content) }) {
                        Label("Kopyala", systemImage: "doc.on.doc")
                    }
                    Button(action: { ErisSpeaker.shared.speak(message.content) }) {
                        Label("Seslendir", systemImage: "speaker.wave.2")
                    }
                }
                Spacer(minLength: 40)
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Glassmorphism Onay Banner'ı

struct GlassApprovalBanner: View {
    @EnvironmentObject var appState: ErisMacState
    let action: PendingAction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("ONAY GEREKLİ (SIFIR-GÜVEN)")
                    .font(.caption2).bold()
                    .foregroundColor(.orange)
                Text(action.summary)
                    .font(.caption)
                    .foregroundColor(ErisTheme.coldWhite)
            }
            
            Spacer()
            
            Button("Reddet") {
                appState.rejectPendingAction()
            }
            .buttonStyle(.bordered)
            
            Button("Onayla") {
                appState.approvePendingAction()
            }
            .buttonStyle(.borderedProminent)
            .tint(ErisTheme.bronzeHighlight)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.4), lineWidth: 0.8)
                )
        )
    }
}

// MARK: - macOS Blur Efekti

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Menü Çubuğu İçerik Görünümü

struct MenuBarContentView: View {
    @EnvironmentObject var appState: ErisMacState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(ErisTheme.bronzeHighlight)
                Text("ERIS")
                    .font(.headline)
                    .foregroundColor(ErisTheme.coldWhite)
                
                Spacer()
                
                ErisStatusBadgeView(
                    isListening: appState.isListening,
                    isThinking: appState.isThinking,
                    isSpeaking: appState.isSpeaking
                )
            }
            Divider()
            
            Button(appState.isListening ? "Dinlemeyi Durdur" : "Dinlemeyi Başlat (⌘⇧E)") {
                appState.toggleListening()
            }
            
            Button("Günün Brifingini Dinle") {
                appState.playMorningBriefing()
            }
            
            Button(appState.isCompactMode ? "Tam Görünüme Geç" : "Kompakt Floating Paneli Aç") {
                appState.toggleCompactMode()
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Button("Ayarlar...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            
            Divider()
            Button("Çıkış") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 275)
        .background(ErisTheme.graphite)
    }
}

// MARK: - Ajan Hızlı Seçim Popover'ı

struct MacAgentQuickPopoverView: View {
    @ObservedObject var personaManager = ErisAgentPersonaManager.shared
    var showSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Özel Ajanlar (Custom Agents)")
                    .font(.headline)
                    .foregroundColor(ErisTheme.coldWhite)
                
                Spacer()
                
                Button(action: {
                    showSettings()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("Yönet / Yeni Ajan")
                    }
                    .font(.caption2).bold()
                    .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(spacing: 6) {
                ForEach(personaManager.modules) { module in
                    Button(action: {
                        personaManager.setActiveAgent(id: module.id)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: module.icon)
                                .font(.system(size: 15))
                                .foregroundColor(module.isEnabled ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.white.opacity(module.isEnabled ? 0.12 : 0.04)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(module.title)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(module.isEnabled ? ErisTheme.coldWhite : ErisTheme.coldGray)
                                    if module.isEnabled {
                                        Text("Aktif")
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(ErisTheme.listeningGreen.opacity(0.2)))
                                            .foregroundColor(ErisTheme.listeningGreen)
                                    }
                                }
                                Text(module.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundColor(ErisTheme.coldGray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: module.isEnabled ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(module.isEnabled ? ErisTheme.bronzeHighlight : Color.white.opacity(0.2))
                                .font(.system(size: 14))
                        }
                        .padding(7)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(module.isEnabled ? 0.08 : 0.02))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(ErisTheme.graphite)
    }
}

// MARK: - Mac Notlar & Dosyalar Kasası Mini Butonları ve Satırları

struct MacCategoryMiniButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Capsule().fill(isSelected ? ErisTheme.bronzeHighlight.opacity(0.3) : Color.white.opacity(0.04)))
                .foregroundColor(isSelected ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
        }
        .buttonStyle(.plain)
    }
}

struct MacMemoryCardRow: View {
    let record: ErisMemoryRecord
    let onTogglePin: () -> Void
    let onEdit: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                // Paylaşılan badge bileşenlerini kullan (BadgeViews.swift)
                CategoryBadge(category: record.category, size: .compact)
                if record.source != "manual" {
                    SourceBadge(source: record.source, size: .compact)
                }

                Spacer()

                // Düzenle
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 8.5))
                        .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .buttonStyle(.plain)
                .help("Notu Düzenle")
                .accessibilityLabel("Düzenle")

                // Sabitle / Kaldır — paylaşılan PinButton kullan
                PinButton(isPinned: record.pinned, size: 8, action: onTogglePin)

                // Dışa Aktar
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 8))
                        .foregroundColor(ErisTheme.coldGray.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Markdown Olarak Dışa Aktar")
                .accessibilityLabel("Dışa aktar")

                // Sil
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(ErisTheme.coldGray.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Notu Sil")
                .accessibilityLabel("Sil")
            }

            Text(record.title)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(ErisTheme.coldWhite)
                .lineLimit(1)

            Text(record.content)
                .font(.system(size: 9.5))
                .foregroundColor(ErisTheme.coldWhite.opacity(0.85))
                .lineLimit(2)

            if !record.tags.isEmpty {
                HStack(spacing: 3) {
                    ForEach(record.tags.prefix(3), id: \.self) { tag in
                        TagBadge(tag: tag, size: .compact)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(record.pinned ? ErisTheme.bronzeAccent.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 0.6)
                )
        )
        // Erişilebilirlik: satır için birleşik etiket
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(record.category.displayName): \(record.title)")
    }
}
