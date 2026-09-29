//
//  BadgeViews.swift
//  ErisCore — Paylaşımlı Rozet Bileşenleri
//

import SwiftUI

/// Kategori rozeti — not kartlarında kullanılır (Belgeler, Teknik, Finans vb.)
public struct CategoryBadge: View {
    let category: MemoryCategory
    let size: BadgeSize
    
    public enum BadgeSize {
        case compact  // Sidebar, mini kartlar
        case regular  // Normal kartlar
        case large    // Detay sayfaları
        
        var fontSize: CGFloat {
            switch self {
            case .compact: return 8
            case .regular: return 9.5
            case .large: return 11
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return 4
            case .regular: return 6
            case .large: return 8
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .compact: return 2
            case .regular: return 3
            case .large: return 4
            }
        }
    }
    
    public init(category: MemoryCategory, size: BadgeSize = .regular) {
        self.category = category
        self.size = size
    }
    
    private var color: Color {
        ErisTheme.categoryColor(for: category)
    }
    
    public var body: some View {
        HStack(spacing: size == .compact ? 2 : 4) {
            Image(systemName: category.icon)
            Text(category.displayName)
        }
        .font(.system(size: size.fontSize, weight: .bold))
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(Capsule().fill(color.opacity(0.18)))
        .foregroundColor(color)
    }
}

/// Kaynak rozeti — not kartlarında kullanılır (Ses, Sohbet, Manuel)
public struct SourceBadge: View {
    let source: String
    let size: CategoryBadge.BadgeSize
    
    public init(source: String, size: CategoryBadge.BadgeSize = .regular) {
        self.source = source
        self.size = size
    }
    
    private var color: Color {
        switch source.lowercased() {
        case "voice": return ErisTheme.sourceVoice
        case "chat": return ErisTheme.categoryDocument
        default: return ErisTheme.coldGray
        }
    }
    
    private var displayText: String {
        switch source.lowercased() {
        case "voice": return "Sesli"
        case "chat": return "Sohbet"
        default: return "Manuel"
        }
    }
    
    public var body: some View {
        HStack(spacing: size == .compact ? 2 : 3) {
            Image(systemName: ErisTheme.sourceIcon(for: source))
            Text(displayText)
        }
        .font(.system(size: size.fontSize, weight: .semibold))
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule().fill(
                source.lowercased() == "voice"
                    ? Color.purple.opacity(0.2)
                    : Color.white.opacity(0.06)
            )
        )
        .foregroundColor(color)
    }
}

/// Etiket rozeti — not kartlarında tag'ler için
public struct TagBadge: View {
    let tag: String
    let size: CategoryBadge.BadgeSize
    
    public init(tag: String, size: CategoryBadge.BadgeSize = .regular) {
        self.tag = tag
        self.size = size
    }
    
    public var body: some View {
        Text(tag.hasPrefix("#") ? tag : "#\(tag)")
            .font(.system(size: size.fontSize))
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size == .compact ? 1.5 : 2)
            .background(Capsule().fill(Color.white.opacity(0.04)))
            .foregroundColor(ErisTheme.coldGray)
    }
}

/// Aktif durum rozeti — "Aktif" etiketi (ajan seçiminde kullanılır)
public struct ActiveBadge: View {
    public init() {}
    
    public var body: some View {
        Text("Aktif")
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(ErisTheme.listeningGreen.opacity(0.2)))
            .foregroundColor(ErisTheme.listeningGreen)
    }
}

/// Dosya adı rozeti
public struct FileNameBadge: View {
    let fileName: String
    
    public init(fileName: String) {
        self.fileName = fileName
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "doc.text")
            Text(fileName)
        }
        .font(.system(size: 8.5, weight: .medium))
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05)))
        .foregroundColor(ErisTheme.coldWhite)
    }
}

/// Pin rozeti butonu
public struct PinButton: View {
    let isPinned: Bool
    let size: CGFloat
    let action: () -> Void
    
    public init(isPinned: Bool, size: CGFloat = 11, action: @escaping () -> Void) {
        self.isPinned = isPinned
        self.size = size
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: size))
                .foregroundColor(
                    isPinned
                        ? ErisTheme.categoryFabric
                        : ErisTheme.coldGray.opacity(0.6)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPinned ? "Sabitlemeyi kaldır" : "Sabitle")
        .accessibilityHint("Notu sabit listeye alır ya da kaldırır")
    }
}
