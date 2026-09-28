import SwiftUI

public struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    @State private var selectedVoiceTone: ErisVoiceTone = .derinBariton
    @State private var wakeWordEnabled: Bool = true
    @State private var morningBriefingEnabled: Bool = true
    @ObservedObject private var langManager = ErisLanguageManager.shared
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Üst Başlık & İlerleme Çubuğu
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .font(.subheadline)
                Text("ERIS LIFE OS")
                    .font(.caption).bold()
                    .tracking(2)
                    .foregroundColor(ErisTheme.coldWhite)
                Spacer()
                Text("\(currentStep + 1) / 4")
                    .font(.caption2).bold()
                    .foregroundColor(ErisTheme.thinkingAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(ErisTheme.thinkingAmber.opacity(0.15)))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.04))
            
            Divider().background(Color.white.opacity(0.08))
            
            // Adım İçerikleri (Kaydırılabilir)
            ScrollView {
                VStack(spacing: 20) {
                    switch currentStep {
                    case 0:
                        stepLanguageView
                    case 1:
                        stepLifeOSVisionView
                    case 2:
                        stepVoiceToneView
                    default:
                        stepPermissionsView
                    }
                }
                .padding(24)
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            // Alt Butonlar
            HStack {
                if currentStep > 0 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            currentStep -= 1
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(L10n.backText)
                        }
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.coldGray)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Button(action: {
                    if currentStep < 3 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            currentStep += 1
                        }
                    } else {
                        ErisSpeaker.shared.selectedTone = selectedVoiceTone
                        UserDefaults.standard.set(selectedVoiceTone.rawValue, forKey: "selectedVoiceTone")
                        UserDefaults.standard.set(wakeWordEnabled, forKey: "wakeWordEnabled")
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        isPresented = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(currentStep == 3 ? L10n.getStartedText : L10n.continueText)
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: currentStep == 3 ? "checkmark" : "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(ErisTheme.bronzeHighlight)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.03))
        }
        .background(ErisTheme.graphite.ignoresSafeArea())
    }
    
    // MARK: - Adım 0: Dil Seçimi (12 Dilde Küresel Destek)
    private var stepLanguageView: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe.europe.africa.fill")
                .font(.system(size: 46))
                .foregroundColor(ErisTheme.bronzeHighlight)
                .padding(.top, 8)
            
            Text(L10n.onboardingWelcomeTitle)
                .font(.title3).bold()
                .foregroundColor(ErisTheme.coldWhite)
                .multilineTextAlignment(.center)
            
            Text("Choose your preferred language / Dilinizi seçin")
                .font(.caption)
                .foregroundColor(ErisTheme.coldGray)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ErisLanguage.allCases) { lang in
                    Button(action: {
                        langManager.setLanguage(lang)
                        ErisSpeaker.shared.speak(L10n.greetingReady)
                    }) {
                        HStack(spacing: 8) {
                            Text(lang.flag)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(lang.nativeName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(langManager.currentLanguage == lang ? .black : ErisTheme.coldWhite)
                                
                                Text(lang.englishName)
                                    .font(.system(size: 10))
                                    .foregroundColor(langManager.currentLanguage == lang ? Color.black.opacity(0.7) : ErisTheme.coldGray)
                            }
                            
                            Spacer()
                            
                            if langManager.currentLanguage == lang {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.black)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(langManager.currentLanguage == lang ? ErisTheme.bronzeHighlight : Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(langManager.currentLanguage == lang ? Color.clear : Color.white.opacity(0.08), lineWidth: 0.8)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Adım 1: Life OS Vizyonu ve Sütunlar
    private var stepLifeOSVisionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 46))
                .foregroundColor(ErisTheme.bronzeHighlight)
                .padding(.top, 8)
            
            Text("Personal Life OS")
                .font(.title3).bold()
                .foregroundColor(ErisTheme.coldWhite)
            
            Text(L10n.onboardingWelcomeSubtitle)
                .font(.caption)
                .lineSpacing(3)
                .foregroundColor(ErisTheme.coldGray)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 10) {
                LifeOSFeatureRow(
                    icon: "checklist",
                    iconColor: ErisTheme.thinkingAmber,
                    title: L10n.openLoopsTitle,
                    desc: "Konuşmalardan ve e-postalardan askıda kalan işleri tespit eder ve takip eder."
                )
                
                LifeOSFeatureRow(
                    icon: "suitcase.fill",
                    iconColor: ErisTheme.bronzeHighlight,
                    title: L10n.livingChecklistsTitle,
                    desc: "Hava durumu, şehir ve süreye göre dinamik seyahat, kiler ve rutin listeleri."
                )
                
                LifeOSFeatureRow(
                    icon: "lock.shield.fill",
                    iconColor: ErisTheme.listeningGreen,
                    title: L10n.safetyGateTitle,
                    desc: "Finans, e-posta veya takvim gibi riskli işlemleri onaysız asla yürütmez."
                )
                
                LifeOSFeatureRow(
                    icon: "sun.max.fill",
                    iconColor: Color.yellow,
                    title: "Sabah & Günlük Akış",
                    desc: "Trafik sayacı, hava tahmini ve günün ajandasıyla tam odaklanma sağlar."
                )
            }
            .padding(.top, 6)
        }
    }
    
    // MARK: - Adım 2: Ses Tonu & Karakter Seçimi
    private var stepVoiceToneView: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Eris Ses Karakteri")
                    .font(.headline)
                    .foregroundColor(ErisTheme.coldWhite)
                Text("Kendinize en yakın ses tonunu seçin ve önizleyin.")
                    .font(.caption)
                    .foregroundColor(ErisTheme.coldGray)
            }
            
            VStack(spacing: 8) {
                ForEach(ErisVoiceTone.allCases) { tone in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tone.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedVoiceTone == tone ? ErisTheme.bronzeHighlight : ErisTheme.coldWhite)
                            Text(tone.subtitle)
                                .font(.system(size: 11))
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            ErisSpeaker.shared.previewTone(tone)
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundColor(ErisTheme.bronzeHighlight)
                                .padding(7)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            selectedVoiceTone = tone
                        }) {
                            Image(systemName: selectedVoiceTone == tone ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedVoiceTone == tone ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(selectedVoiceTone == tone ? 0.08 : 0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedVoiceTone == tone ? ErisTheme.bronzeHighlight.opacity(0.4) : Color.white.opacity(0.04), lineWidth: 0.8)
                            )
                    )
                }
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            Toggle("'Hey Eris' Dinleme (Wake Word)", isOn: $wakeWordEnabled)
                .font(.subheadline)
                .foregroundColor(ErisTheme.coldWhite)
            
            Toggle("Sabah Brifingi (Saat 08:30)", isOn: $morningBriefingEnabled)
                .font(.subheadline)
                .foregroundColor(ErisTheme.coldWhite)
        }
    }
    
    // MARK: - Adım 3: İzinler & Gizlilik
    private var stepPermissionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Erişim, İzinler ve Güvenlik")
                .font(.headline)
                .foregroundColor(ErisTheme.coldWhite)
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "waveform.badge.mic")
                    .font(.title3)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mikrofon & Konuşma Tanıma").font(.subheadline).bold().foregroundColor(ErisTheme.coldWhite)
                    Text("Sesli diyalog, Barge-in ve 'Hey Eris' komutu.").font(.caption2).foregroundColor(ErisTheme.coldGray)
                    Text("Gizlilik Beyanı: Apple Speech Recognition (Cloud STT), yüksek doğruluk için ses kesitlerini Apple sunucularında güvenle işleyebilir. Eris hiçbir ham ses kaydınızı saklamaz veya üçüncü taraflarla paylaşmaz.")
                        .font(.system(size: 10))
                        .foregroundColor(ErisTheme.bronzeAccent.opacity(0.85))
                        .padding(.top, 2)
                }
            }
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Takvim & Hatırlatıcılar").font(.subheadline).bold().foregroundColor(ErisTheme.coldWhite)
                    Text("Ajandanızı okur, randevu çakışmalarını uyarır, onaysız asla etkinlik yaratmaz.").font(.caption2).foregroundColor(ErisTheme.coldGray)
                }
            }
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "icloud.fill")
                    .font(.title3)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Eşitleme").font(.subheadline).bold().foregroundColor(ErisTheme.coldWhite)
                    Text("Mac ve iPhone arasında uçtan uca şifreli not ve kilitli belge senkronizasyonu.").font(.caption2).foregroundColor(ErisTheme.coldGray)
                }
            }
            
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundColor(ErisTheme.listeningGreen)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sıfır-Güven İcra (Zero-Trust)").font(.subheadline).bold().foregroundColor(ErisTheme.coldWhite)
                    Text("Finans, mesaj veya randevu iptali gibi tüm riskli eylemler parmak izi/Face ID onayı olmadan gerçekleştirilmez.").font(.caption2).foregroundColor(ErisTheme.coldGray)
                }
            }
        }
    }
}

// MARK: - Life OS Özellik Satırı
private struct LifeOSFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(iconColor.opacity(0.12)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ErisTheme.coldWhite)
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(ErisTheme.coldGray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 0.8))
        )
    }
}
