import SwiftUI

public struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    @State private var apiKey: String = KeychainManager.shared.getApiKey() ?? ""
    @State private var selectedVoice: ErisVoiceGender = .male
    @State private var wakeWordEnabled: Bool = true
    @State private var morningBriefingEnabled: Bool = true
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Üst Başlık & İlerleme Çubuğu
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                    .font(.title3)
                Text("ERIS KURULUM")
                    .font(.caption).bold()
                    .tracking(2)
                    .foregroundColor(.white)
                Spacer()
                Text("Adım \(currentStep + 1) / 4")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            
            Divider().background(Color.white.opacity(0.08))
            
            // Adım İçerikleri
            VStack(spacing: 24) {
                if currentStep == 0 {
                    stepWelcomeView
                } else if currentStep == 1 {
                    stepApiKeyView
                } else if currentStep == 2 {
                    stepPermissionsView
                } else {
                    stepPreferencesView
                }
            }
            .padding(32)
            .frame(maxHeight: .infinity)
            
            Divider().background(Color.white.opacity(0.08))
            
            // Alt Butonlar
            HStack {
                if currentStep > 0 {
                    Button("Geri") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    if currentStep < 3 {
                        withAnimation { currentStep += 1 }
                    } else {
                        // Kurulumu tamamla
                        if !apiKey.isEmpty {
                            _ = KeychainManager.shared.saveApiKey(apiKey)
                        }
                        isPresented = false
                    }
                }) {
                    Text(currentStep == 3 ? "Tamamla ve Başla" : "Devam Et")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.85, green: 0.72, blue: 0.58))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Color.white.opacity(0.03))
        }
        .background(Color(red: 0.09, green: 0.095, blue: 0.105))
        .frame(minWidth: 540, minHeight: 460)
    }
    
    // Adım 1: Karşılama
    private var stepWelcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 56))
                .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                .padding(.bottom, 6)
            
            Text("Kişisel Müttefikiniz Eris'e Hoş Geldiniz")
                .font(.title2).bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Eris; tok, net, sıfır-güven (zero-trust) mimarisine sahip dijital sağ kolunuzdur. Takviminizi, kişisel hafızanızı, piyasa ve deniz durumlarını daima sizin açık onayınızla yönetir.")
                .font(.callout)
                .lineSpacing(4)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
        }
    }
    
    // Adım 2: API Anahtarı
    private var stepApiKeyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gemini API Anahtarınız")
                .font(.title3).bold()
                .foregroundColor(.white)
            
            Text("Verileriniz doğrudan cihazınızdan şifreli tünelle işlenir. API anahtarınız Apple Keychain içinde korunur, sunucularımızda saklanmaz.")
                .font(.caption)
                .foregroundColor(.gray)
            
            SecureField("AI Studio'dan aldığınız API anahtarını yapıştırın", text: $apiKey)
                .textFieldStyle(.plain)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                        )
                )
                .foregroundColor(.white)
        }
    }
    
    // Adım 3: İzinler
    private var stepPermissionsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Erişim ve İzinler")
                .font(.title3).bold()
                .foregroundColor(.white)
            
            HStack(spacing: 14) {
                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mikrofon & Konuşma Tanıma").font(.subheadline).bold().foregroundColor(.white)
                    Text("Canlı sesli diyalog ve 'Hey Eris' komutu için kullanılır.").font(.caption2).foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 14) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Takvim Erişimi (EventKit)").font(.subheadline).bold().foregroundColor(.white)
                    Text("Ajandanızı okur; takvime yazma işlemi daima açık onayınızla yapılır.").font(.caption2).foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 14) {
                Image(systemName: "icloud.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.58))
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Eşitleme").font(.subheadline).bold().foregroundColor(.white)
                    Text("Hafızanız Mac ve iPhone cihazlarınız arasında şifreli eşitlenir.").font(.caption2).foregroundColor(.gray)
                }
            }
        }
    }
    
    // Adım 4: Tercihler
    private var stepPreferencesView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Karakter ve Ses Tercihi")
                .font(.title3).bold()
                .foregroundColor(.white)
            
            Picker("Ses Profili", selection: $selectedVoice) {
                ForEach(ErisVoiceGender.allCases, id: \.self) { g in
                    Text(g.displayName).tag(g)
                }
            }
            .pickerStyle(.segmented)
            
            Toggle("'Hey Eris' Sesle Uyandırma", isOn: $wakeWordEnabled)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Toggle("Sabah Brifingi (Saat 08:30)", isOn: $morningBriefingEnabled)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}
