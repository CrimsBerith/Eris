//
//  IOSSettingsView.swift
//  ErisIOS
//

import SwiftUI
import ErisCore

// 3. Ayarlar Görünümü
struct IOSSettingsContentView: View {
    @EnvironmentObject var appState: ErisIOSState
    @State private var customApiKey: String = KeychainManager.shared.getCustomOverrideApiKey() ?? ""
    @State private var customOpenAIApiKey: String = KeychainManager.shared.getOpenAIApiKey() ?? ""
    @State private var showDeveloperOptions: Bool = false
    @State private var savedNotice: String = ""
    @State private var editingModule: ErisExpertiseModule? = nil
    @State private var isCreatingNewModule: Bool = false
    @State private var showResetAlert: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Ayarlar ve Tercihler")
                    .font(.title3).bold()
                    .foregroundColor(ErisTheme.coldWhite)
                    .padding(.top, 10)
                
                // Dil Seçimi / World Languages (12 Dilde Tam Destek)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("DÜNYA DİLLERİ & SES / LANGUAGES")
                            .font(.caption).bold()
                            .foregroundColor(ErisTheme.bronzeHighlight)
                            .tracking(1.2)
                        
                        Spacer()
                        
                        Text(ErisLanguageManager.shared.currentLanguage.displayName)
                            .font(.caption2).bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(ErisTheme.bronzeAccent.opacity(0.3)))
                            .foregroundColor(ErisTheme.coldWhite)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ErisLanguage.allCases) { lang in
                                Button(action: {
                                    ErisLanguageManager.shared.setLanguage(lang)
                                    ErisSpeaker.shared.speak(L10n.greetingReady)
                                }) {
                                    HStack(spacing: 5) {
                                        Text(lang.flag)
                                        Text(lang.nativeName)
                                            .font(.caption).bold()
                                        if let badge = lang.strengthBadge {
                                            Text(badge)
                                                .font(.system(size: 8, weight: .bold))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(lang == .english ? Color.blue.opacity(0.4) : Color.red.opacity(0.4)))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(ErisLanguageManager.shared.currentLanguage == lang ? ErisTheme.bronzeHighlight : Color.white.opacity(0.06))
                                    )
                                    .foregroundColor(ErisLanguageManager.shared.currentLanguage == lang ? .black : ErisTheme.coldWhite)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
                )

                // Eris Ses Tonu & Karakteri
                VStack(alignment: .leading, spacing: 14) {
                    Text("ERIS SES TONU & KARAKTERİ")
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .tracking(1.2)
                    
                    ForEach(ErisVoiceTone.allCases) { tone in
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(tone.title)
                                        .font(.subheadline).bold()
                                        .foregroundColor(appState.selectedVoiceTone == tone ? ErisTheme.bronzeHighlight : ErisTheme.coldWhite)
                                    if appState.selectedVoiceTone == tone {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(ErisTheme.bronzeHighlight)
                                            .font(.caption)
                                    }
                                }
                                Text(tone.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                ErisSpeaker.shared.previewTone(tone)
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.caption)
                                    .foregroundColor(ErisTheme.coldWhite)
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.08)))
                            }
                            
                            Button(action: {
                                appState.selectedVoiceTone = tone
                            }) {
                                Text(appState.selectedVoiceTone == tone ? "Seçili" : "Seç")
                                    .font(.caption2).bold()
                                    .foregroundColor(appState.selectedVoiceTone == tone ? .black : ErisTheme.coldWhite)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Capsule().fill(appState.selectedVoiceTone == tone ? ErisTheme.bronzeHighlight : Color.white.opacity(0.1)))
                            }
                        }
                        .padding(.vertical, 4)
                        if tone != ErisVoiceTone.allCases.last {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.06))
                    
                    // Doğallık & Ses Motoru Bilgisi
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: ErisAppConfig.isNeuralVoiceAvailable ? "waveform.badge.sparkles" : "waveform")
                                .foregroundColor(ErisTheme.bronzeHighlight)
                                .font(.caption)
                            Text(ErisAppConfig.isNeuralVoiceAvailable ? "Nöral Stüdyo Sesi Aktif (OpenAI TTS)" : "Apple Gelişmiş Yerel Ses Motoru")
                                .font(.caption).bold()
                                .foregroundColor(ErisTheme.coldWhite)
                        }
                        
                        Text(ErisAppConfig.isNeuralVoiceAvailable
                            ? "Eris stüdyo kalitesinde, nefes alan gerçek insan tonlamasıyla konuşuyor."
                            : "En yüksek yerel ses kalitesi için: iOS Ayarları > Erişilebilirlik > Seslendirilen İçerik > Sesler > Türkçe bölümünden 'Yelda (Gelişmiş)' sesini indirebilirsiniz.")
                            .font(.system(size: 11))
                            .foregroundColor(ErisTheme.coldGray)
                            .lineSpacing(2)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
                )
                
                // Yapay Zekâ & Model Bölümü
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(ErisTheme.listeningGreen)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("YAPAY ZEKÂ MOTORU")
                                .font(.caption).bold()
                                .foregroundColor(ErisTheme.bronzeHighlight)
                                .tracking(1.2)
                            Text("Eris Bulut Motoruna Doğrudan Bağlı")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Spacer()
                        
                        Text("Aktif")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ErisTheme.listeningGreen.opacity(0.18))
                            .foregroundColor(ErisTheme.listeningGreen)
                            .clipShape(Capsule())
                    }
                    
                    Text("Kullanıcının herhangi bir API anahtarı girmesine gerek yoktur. Tüm zekâ motoru ve oluşturduğunuz özel ajanlar yerleşik olarak çalışır.")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                        .lineSpacing(2)
                    
                    Divider().background(Color.white.opacity(0.08))
                    
                    HStack {
                        Text("Model:")
                            .font(.subheadline).bold()
                            .foregroundColor(ErisTheme.coldWhite)
                        
                        Spacer()
                        
                        Picker("Model Seçimi", selection: $appState.selectedModel) {
                            ForEach(GeminiModelChoice.allCases, id: \.self) { model in
                                Text(model.displayName).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(ErisTheme.bronzeHighlight)
                    }
                    
                    // Geliştirici Özel Anahtar (Opsiyonel)
                    DisclosureGroup("Geliştirici Seçenekleri (İsteğe Bağlı)", isExpanded: $showDeveloperOptions) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Geliştirici testi için özel API anahtarı girilebilir:")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                            
                            SecureField("Özel API Anahtarı (Opsiyonel)", text: $customApiKey)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                                .foregroundColor(ErisTheme.coldWhite)
                            
                            HStack {
                                Button(action: {
                                    if KeychainManager.shared.saveApiKey(customApiKey) {
                                        savedNotice = "Özel anahtar Keychain'e kaydedildi."
                                    }
                                }) {
                                    Text("Kaydet")
                                        .font(.caption).bold()
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(ErisTheme.bronzeHighlight))
                                }
                                
                                if !customApiKey.isEmpty {
                                    Button(action: {
                                        KeychainManager.shared.deleteApiKey()
                                        customApiKey = ""
                                        savedNotice = "Yerleşik geliştirici anahtarına dönüldü."
                                    }) {
                                        Text("Sıfırla")
                                            .font(.caption)
                                            .foregroundColor(ErisTheme.coldGray)
                                    }
                                }
                            }
                            
                            if !savedNotice.isEmpty {
                                Text(savedNotice)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.listeningGreen)
                            }
                            
                            Divider().background(Color.white.opacity(0.06)).padding(.vertical, 4)
                            
                            Text("Stüdyo Kalitesinde İnsan Sesi (OpenAI TTS):")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                            
                            SecureField("OpenAI API Anahtarı (Opsiyonel)", text: $customOpenAIApiKey)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                                .foregroundColor(ErisTheme.coldWhite)
                            
                            HStack {
                                Button(action: {
                                    if KeychainManager.shared.saveOpenAIApiKey(customOpenAIApiKey) {
                                        savedNotice = "OpenAI TTS anahtarı kaydedildi. Nöral ses aktif!"
                                    }
                                }) {
                                    Text("Nöral Sesi Kaydet")
                                        .font(.caption).bold()
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(ErisTheme.bronzeHighlight))
                                }
                                
                                if !customOpenAIApiKey.isEmpty {
                                    Button(action: {
                                        KeychainManager.shared.deleteOpenAIApiKey()
                                        customOpenAIApiKey = ""
                                        savedNotice = "Nöral ses kaldırıldı. Apple yerel sesine dönüldü."
                                    }) {
                                        Text("Kaldır")
                                            .font(.caption)
                                            .foregroundColor(ErisTheme.coldGray)
                                    }
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                    .font(.caption)
                    .accentColor(ErisTheme.bronzeHighlight)
                    .foregroundColor(ErisTheme.coldGray)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
                )
                
                // Özel Ajanlar & Uzmanlık Modülleri Bölümü (Custom Agents)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ÖZEL AJANLAR (CUSTOM AGENTS)")
                                .font(.caption).bold()
                                .foregroundColor(ErisTheme.bronzeHighlight)
                                .tracking(1.2)
                            Text("Kendi özel yapay zekâ ajanlarınızı yaratın, rol ve kurallarını belirleyin veya hazır şablonları uyarlayın.")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isCreatingNewModule = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Yeni Ajan Yarat")
                            }
                            .font(.caption2).bold()
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(ErisTheme.bronzeHighlight))
                        }
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(ErisAgentPersonaManager.shared.modules) { module in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: module.icon)
                                        .foregroundColor(module.isEnabled ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                                        .font(.subheadline)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(module.title)
                                                .font(.subheadline).bold()
                                                .foregroundColor(module.isEnabled ? ErisTheme.coldWhite : ErisTheme.coldGray)
                                            if module.isEnabled {
                                                Text("Aktif")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 1)
                                                    .background(Capsule().fill(ErisTheme.listeningGreen.opacity(0.2)))
                                                    .foregroundColor(ErisTheme.listeningGreen)
                                            }
                                        }
                                        Text(module.subtitle)
                                            .font(.caption2)
                                            .foregroundColor(ErisTheme.coldGray)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: Binding(
                                        get: { module.isEnabled },
                                        set: { _ in ErisAgentPersonaManager.shared.toggleModule(id: module.id) }
                                    ))
                                    .labelsHidden()
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        ErisAgentPersonaManager.shared.setActiveAgent(id: module.id)
                                    }) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "checkmark.circle")
                                            Text("Tek Aktif Yap")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(ErisTheme.coldWhite)
                                    }
                                    
                                    Button(action: { editingModule = module }) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "pencil")
                                            Text("Düzenle")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(ErisTheme.bronzeHighlight)
                                    }
                                    
                                    Button(action: { ErisAgentPersonaManager.shared.duplicateModule(id: module.id) }) {
                                        HStack(spacing: 3) {
                                            Image(systemName: "doc.on.doc")
                                            Text("Çoğalt")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(ErisTheme.coldWhite.opacity(0.8))
                                    }
                                    
                                    if ErisAgentPersonaManager.shared.modules.count > 1 {
                                        Button(action: { ErisAgentPersonaManager.shared.deleteModule(id: module.id) }) {
                                            HStack(spacing: 3) {
                                                Image(systemName: "trash")
                                                Text("Sil")
                                            }
                                            .font(.caption2)
                                            .foregroundColor(.red.opacity(0.8))
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.leading, 32)
                            }
                            .padding(.vertical, 4)
                            
                            if module.id != ErisAgentPersonaManager.shared.modules.last?.id {
                                Divider().background(Color.white.opacity(0.08))
                            }
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    Text("GENEL ÖZEL DİREKTİFLER")
                        .font(.caption2).bold()
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .tracking(1.0)
                    
                    Text("Tüm ajanlar için geçerli olmasını istediğiniz küresel kurallar:")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                    
                    IOSCustomDirectivesEditorView()
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    Button(action: { showResetAlert = true }) {
                        Text("Ajanları Varsayılana Sıfırla")
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    .confirmationDialog("Tüm ajanlar varsayılan ayarlara döndürülsün mü?", isPresented: $showResetAlert) {
                        Button("Evet, Varsayılana Sıfırla", role: .destructive) {
                            ErisAgentPersonaManager.shared.resetToDefaults()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
                )

                
                // Widget Yönetimi Bölümü
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WİDGET SEÇİMİ & YÖNETİMİ")
                                .font(.caption).bold()
                                .foregroundColor(ErisTheme.bronzeHighlight)
                                .tracking(1.2)
                            Text("Panelde ve iOS Kilit/Ana ekranında aktif olan widget'lar:")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            appState.selectedTab = .widgets
                        }) {
                            Text("Panele Git")
                                .font(.caption2).bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(ErisTheme.bronzeHighlight))
                        }
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(ErisWidgetType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(ErisWidgetManager.shared.isWidgetEnabled(type) ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                                    .font(.subheadline)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.title)
                                        .font(.subheadline).bold()
                                        .foregroundColor(ErisTheme.coldWhite)
                                    Text(type.subtitle)
                                        .font(.caption2)
                                        .foregroundColor(ErisTheme.coldGray)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { ErisWidgetManager.shared.isWidgetEnabled(type) },
                                    set: { _ in ErisWidgetManager.shared.toggleWidget(type) }
                                ))
                                .labelsHidden()
                            }
                            .padding(.vertical, 3)
                            
                            if type != ErisWidgetType.allCases.last {
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
                )
                
                // Etkileşim & Dinleme Bölümü
                VStack(alignment: .leading, spacing: 12) {
                    Text("ETKİLEŞİM & DİNLEME")
                        .font(.caption).bold()
                        .foregroundColor(ErisTheme.bronzeHighlight)
                        .tracking(1.2)
                    
                    Toggle("'Hey Eris' Dinleme (Wake Word)", isOn: $appState.wakeWordEnabled)
                        .foregroundColor(ErisTheme.coldWhite)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 90)
        }
        .sheet(item: $editingModule) { mod in
            IOSModuleEditSheet(module: mod) { title, subtitle, icon, instructions in
                ErisAgentPersonaManager.shared.updateModule(id: mod.id, title: title, subtitle: subtitle, icon: icon, instructions: instructions, isEnabled: mod.isEnabled)
            }
        }
        .sheet(isPresented: $isCreatingNewModule) {
            IOSModuleEditSheet(module: nil) { title, subtitle, icon, instructions in
                _ = ErisAgentPersonaManager.shared.addModule(title: title, subtitle: subtitle, icon: icon, instructions: instructions)
            }
        }
    }
}

struct IOSCustomDirectivesEditorView: View {
    @ObservedObject var personaManager = ErisAgentPersonaManager.shared
    @State private var text: String = ""
    @State private var notice: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $text)
                .font(.system(size: 12))
                .frame(height: 70)
                .padding(6)
                .background(Color.black.opacity(0.25))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ErisTheme.bronzeAccent.opacity(0.2), lineWidth: 0.8))
            
            HStack {
                Button(action: {
                    personaManager.customDirectives = text
                    personaManager.saveSettings()
                    notice = "Kaydedildi."
                }) {
                    Text("Kaydet")
                        .font(.caption2).bold()
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(ErisTheme.bronzeHighlight))
                }
                
                Button(action: {
                    personaManager.resetToDefaults()
                    text = ""
                    notice = "Sıfırlandı."
                }) {
                    Text("Sıfırla")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldWhite)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
                
                Spacer()
                
                if !notice.isEmpty {
                    Text(notice)
                        .font(.caption2)
                        .foregroundColor(ErisTheme.listeningGreen)
                }
            }
        }
        .onAppear {
            text = personaManager.customDirectives
        }
    }
}

struct IOSModuleEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let module: ErisExpertiseModule?
    let onSave: (String, String, String, String) -> Void
    
    @State private var title: String
    @State private var subtitle: String
    @State private var icon: String
    @State private var instructions: String
    @State private var selectedTemplateId: String? = nil
    
    init(module: ErisExpertiseModule?, onSave: @escaping (String, String, String, String) -> Void) {
        self.module = module
        self.onSave = onSave
        _title = State(initialValue: module?.title ?? "")
        _subtitle = State(initialValue: module?.subtitle ?? "")
        _icon = State(initialValue: module?.icon ?? "sparkles")
        _instructions = State(initialValue: module?.instructions ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Hazır Şablonlar / Templates
                Section(header: Text("HAZIR AJAN ŞABLONLARI")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ErisAgentPersonaManager.starterTemplates) { tmpl in
                                Button(action: {
                                    selectedTemplateId = tmpl.id
                                    title = tmpl.title
                                    subtitle = tmpl.subtitle
                                    icon = tmpl.icon
                                    instructions = tmpl.instructions
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: tmpl.icon)
                                            .font(.caption)
                                        Text(tmpl.title)
                                            .font(.caption).bold()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 7)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedTemplateId == tmpl.id ? ErisTheme.bronzeHighlight : Color.white.opacity(0.08))
                                    )
                                    .foregroundColor(selectedTemplateId == tmpl.id ? .black : ErisTheme.coldWhite)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    Text("Bir şablona dokunarak bilgileri ve talimatları anında doldurabilir, ardından dilediğiniz gibi düzenleyebilirsiniz.")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                }
                
                // Canlı Ajan Önizlemesi
                Section(header: Text("AJAN KİMLİĞİ")) {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 26))
                            .foregroundColor(ErisTheme.bronzeHighlight)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(ErisTheme.bronzeAccent.opacity(0.2)))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(title.isEmpty ? "Ajan Adı" : title)
                                .font(.headline).bold()
                                .foregroundColor(title.isEmpty ? ErisTheme.coldGray : ErisTheme.coldWhite)
                            Text(subtitle.isEmpty ? "Kısa rol veya uzmanlık tanımı" : subtitle)
                                .font(.caption)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    TextField("Ajan Adı (Örn: Kıdemli Yazılım Mimarı)", text: $title)
                    TextField("Kısa Rol / Uzmanlık (Örn: Swift, Mimari & Refactoring)", text: $subtitle)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Simge Seçimi")
                            .font(.caption)
                            .foregroundColor(ErisTheme.coldGray)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ErisAgentPersonaManager.suggestedIcons, id: \.self) { sym in
                                    Button(action: { icon = sym }) {
                                        Image(systemName: sym)
                                            .font(.caption)
                                            .foregroundColor(icon == sym ? .black : ErisTheme.coldWhite)
                                            .padding(8)
                                            .background(Circle().fill(icon == sym ? ErisTheme.bronzeHighlight : Color.white.opacity(0.1)))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("AJAN TALİMATLARI & DAVRANIŞ KURALLARI")) {
                    Text("Bu ajan devredeyken Eris'in benimseyeceği rol, tavır, teknik uzmanlık derinliği ve konuşma kuralları:")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                    
                    TextEditor(text: $instructions)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(minHeight: 160)
                }
            }
            .navigationTitle(module == nil ? "Yeni Özel Ajan" : "Ajanı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        onSave(title, subtitle, icon, instructions)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

