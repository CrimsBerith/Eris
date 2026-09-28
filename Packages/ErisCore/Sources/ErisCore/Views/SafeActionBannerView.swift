//
//  SafeActionBannerView.swift
//  ErisCore
//
//  Created by Antigravity on 2026-09-28.
//

import SwiftUI

/// Bölüm 48 gereğince: Riskli ve geri döndürülemez işlemler için
/// macOS ve iOS üzerinde ortak çalışan zarif Glassmorphic Onay Banner'ı.
public struct SafeActionBannerView: View {
    public let ticket: SafeActionTicket
    public let onApprove: () -> Void
    public let onReject: () -> Void
    
    public init(
        ticket: SafeActionTicket,
        onApprove: @escaping () -> Void,
        onReject: @escaping () -> Void
    ) {
        self.ticket = ticket
        self.onApprove = onApprove
        self.onReject = onReject
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: ticket.kind.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ErisTheme.thinkingAmber)
                
                Text("GÜVENLİK KAPISI: \(ticket.kind.displayName.uppercased())")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(ErisTheme.thinkingAmber)
                
                Spacer()
                
                // Risk rozeti
                Text(ticket.riskLevel.displayName)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(riskColor.opacity(0.2)))
                    .overlay(Capsule().stroke(riskColor.opacity(0.4), lineWidth: 0.5))
                    .foregroundColor(riskColor)
            }
            
            Text(ticket.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ErisTheme.coldWhite)
            
            if !ticket.explanation.isEmpty {
                Text(ticket.explanation)
                    .font(.system(size: 12))
                    .foregroundColor(ErisTheme.coldGray)
                    .lineLimit(2)
            }
            
            HStack(spacing: 10) {
                Spacer()
                
                Button(action: onReject) {
                    Text("Reddet")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ErisTheme.coldGray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ErisTheme.coldGray.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                Button(action: onApprove) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Onayla & İcra Et")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(ErisTheme.listeningGreen)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1F1E19").opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ErisTheme.thinkingAmber.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 3)
    }
    
    private var riskColor: Color {
        switch ticket.riskLevel {
        case .low: return ErisTheme.listeningGreen
        case .medium: return ErisTheme.thinkingAmber
        case .high, .critical: return Color(hex: "FF5E57")
        }
    }
}
