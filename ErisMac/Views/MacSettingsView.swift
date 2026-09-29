//
//  MacSettingsView.swift
//  ErisMac
//

import SwiftUI
import ErisCore

enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "Ses & Etkileşim"
    case widgets = "Widget Seçimi"
    case agentPersona = "Özel Ajanlar"
    case modelApi = "Yapay Zekâ & Model"
    
    var id: String { rawValue }
}

struct SettingsView: View {
    @EnvironmentObject var appState: ErisMacState
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsTab(appState: appState)
                case .widgets:
                    MacWidgetsSettingsTab()
                case .agentPersona:
                    AgentPersonaSettingsTab()
                case .modelApi:
                    ModelApiSettingsTab(appState: appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 620, height: 570)
    }
}

struct GeneralSettingsTab: View {
    @ObservedObject var appState: ErisMacState
    
    var body: some View {
        Form {
            Section(header: Text("Dünya Dilleri & Ses / Languages").font(.headline)) {
                Picker("Aktif Dil:", selection: Binding(
                    get: { ErisLanguageManager.shared.currentLanguage },
                    set: { newLang in
                        ErisLanguageManager.shared.setLanguage(newLang)
                        ErisSpeaker.shared.speak(L10n.greetingReady)
                    }
                )) {
                    ForEach(ErisLanguage.allCases) { lang in
                        HStack {
                            Text("\(lang.flag) \(lang.nativeName) (\(lang.englishName))")
                            if let badge = lang.strengthBadge {
                                Text("[\(badge)]")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tag(lang)
                    }
                }
                .pickerStyle(.menu)
                
                Text("Eris; İngilizce (Global Core), Türkçe (Native) dahil 12 dünya dilinde akıcı konuşur, ses tonlarını ve sistem talimatlarını seçilen dile göre uyarlar.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Eris Ses Tonu & Karakteri").font(.headline)) {
                ForEach(ErisVoiceTone.allCases) { tone in
                    VoiceToneRowView(
                        tone: tone,
                        isSelected: appState.selectedVoiceTone == tone,
                        onSelect: {
                            appState.selectedVoiceTone = tone
                        },
                        onPreview: {
                            ErisSpeaker.shared.previewTone(tone)
                        }
                    )
                }
                
                HStack(spacing: 8) {
                    Image(systemName: ErisAppConfig.isNeuralVoiceAvailable ? "waveform.badge.sparkles" : "waveform")
                        .foregroundColor(ErisTheme.bronzeHighlight)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ErisAppConfig.isNeuralVoiceAvailable ? "Nöral Stüdyo Sesi Aktif (OpenAI TTS)" : "Apple Gelişmiş Yerel Ses Motoru")
                            .font(.caption).bold()
                        Text(ErisAppConfig.isNeuralVoiceAvailable
                            ? "Eris stüdyo kalitesinde, nefes alan gerçek insan tonlamasıyla konuşuyor."
                            : "Mac'inizde en yüksek ses doğallığı için: Sistem Ayarları > Erişilebilirlik > Seslendirilen İçerik > Sistem Sesi > Türkçe bölümünden 'Yelda (Gelişmiş / Premium)' sesini indirebilirsiniz.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Etkileşim & Dinleme").font(.headline)) {
                Toggle("'Hey Eris' Dinleme (Wake Word)", isOn: $appState.wakeWordEnabled)
                
                Text("Global Kısayol: ⌘ + ⇧ + E ile her zaman sesli görüşmeyi açıp kapatabilirsiniz.")
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldGray)
            }
            
            Section(header: Text("Sabah Brifingi").font(.headline)) {
                Text("Her sabah saat 08:30'da günün takvimini, hava durumunu, piyasaları ve kasanızdaki önemli notları sesli özetler.")
                    .font(.caption)
                    .foregroundColor(ErisTheme.coldGray)
            }
        }
        .padding(20)
    }
}

struct MacWidgetsSettingsTab: View {
    @ObservedObject var widgetManager = ErisWidgetManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Widget Görünürlük & Seçim Ayarları")
                        .font(.headline)
                        .foregroundColor(ErisTheme.coldWhite)
                    Text("Hem iPhone Widget Panosu'nda hem de Mac yan panelinde hangi modüllerin gösterileceğini seçin. Değişiklikler anında yansır.")
                        .font(.caption)
                        .foregroundColor(ErisTheme.coldGray)
                }
                
                Divider()
                
                VStack(spacing: 12) {
                    ForEach(ErisWidgetType.allCases) { widget in
                        MacWidgetRowView(widget: widget, widgetManager: widgetManager)
                    }
                }
                
                HStack {
                    Text("Aktif Widget: \(widgetManager.activeWidgets.count)/\(ErisWidgetType.allCases.count)")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                    
                    Spacer()
                    
                    Button("Varsayılanlara Sıfırla") {
                        widgetManager.resetToDefaults()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(ErisTheme.bronzeHighlight)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
    }
}

struct MacWidgetRowView: View {
    let widget: ErisWidgetType
    @ObservedObject var widgetManager: ErisWidgetManager
    
    var isEnabled: Bool {
        widgetManager.isWidgetEnabled(widget)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: widget.systemImage)
                .font(.system(size: 18))
                .foregroundColor(isEnabled ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(isEnabled ? 0.08 : 0.03))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(widget.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ErisTheme.coldWhite)
                Text(widget.subtitle)
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldGray)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { widgetManager.isWidgetEnabled(widget) },
                set: { widgetManager.setWidgetEnabled(widget, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                )
        )
    }
}

struct AgentPersonaSettingsTab: View {
    @ObservedObject var personaManager = ErisAgentPersonaManager.shared
    @State private var customDirectivesText: String = ""
    @State private var savedNotice: String = ""
    @State private var expandedModuleId: String? = nil
    @State private var editingModule: ErisExpertiseModule? = nil
    @State private var isCreatingNewModule: Bool = false
    @State private var showResetConfirmation: Bool = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Özel Ajanlar (Custom Agents)")
                            .font(.headline)
                            .foregroundColor(ErisTheme.coldWhite)
                        Text("Kendi özel yapay zekâ ajanlarınızı yaratın, rol ve kurallarını belirleyin veya hazır şablonları uyarlayın.")
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldGray)
                    }
                    
                    Spacer()
                    
                    Button(action: { isCreatingNewModule = true }) {
                        Label("Yeni Özel Ajan Oluştur", systemImage: "plus.circle.fill")
                            .font(.caption).bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ErisTheme.bronzeHighlight)
                }
                .padding(.bottom, 4)
                
                ForEach(personaManager.modules) { module in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: module.icon)
                                .foregroundColor(module.isEnabled ? ErisTheme.bronzeHighlight : ErisTheme.coldGray)
                                .font(.headline)
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
                                    } else {
                                        Text("(Devre Dışı)")
                                            .font(.caption2)
                                            .foregroundColor(ErisTheme.coldGray)
                                    }
                                }
                                
                                Text(module.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(ErisTheme.coldGray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { module.isEnabled },
                                set: { _ in personaManager.toggleModule(id: module.id) }
                            ))
                            .toggleStyle(.switch)
                        }
                        
                        // Modül Yönetim Butonları
                        HStack(spacing: 12) {
                            Button(action: {
                                personaManager.setActiveAgent(id: module.id)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle")
                                    Text("Tek Aktif Yap")
                                }
                                .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: { editingModule = module }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                    Text("Düzenle")
                                }
                                .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: { personaManager.duplicateModule(id: module.id) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.doc")
                                    Text("Çoğalt")
                                }
                                .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                            
                            if personaManager.modules.count > 1 {
                                Button(role: .destructive, action: { personaManager.deleteModule(id: module.id) }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                        Text("Sil")
                                    }
                                    .font(.caption2)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation {
                                    expandedModuleId = (expandedModuleId == module.id) ? nil : module.id
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(expandedModuleId == module.id ? "Direktifleri Gizle" : "Direktifleri Gör")
                                        .font(.caption2)
                                    Image(systemName: expandedModuleId == module.id ? "chevron.up" : "chevron.down")
                                        .font(.caption2)
                                }
                                .foregroundColor(ErisTheme.bronzeHighlight)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 2)
                        
                        if expandedModuleId == module.id {
                            Text(module.instructions)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(ErisTheme.coldWhite.opacity(0.85))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.35))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ErisTheme.bronzeAccent.opacity(0.3), lineWidth: 0.8))
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            
            Section(header: Text("Özel Ajan Direktifleri & Serbest Kurallar").font(.headline)) {
                Text("Eris'in her zaman uygulamasını istediğiniz küresel özel tarz ve davranış kuralları:")
                    .font(.caption2)
                    .foregroundColor(ErisTheme.coldGray)
                
                TextEditor(text: $customDirectivesText)
                    .font(.system(size: 12))
                    .frame(height: 70)
                    .padding(6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ErisTheme.bronzeAccent.opacity(0.3), lineWidth: 0.8))
                
                HStack(spacing: 12) {
                    Button("Direktifleri Kaydet") {
                        personaManager.customDirectives = customDirectivesText
                        personaManager.saveSettings()
                        savedNotice = "Özel direktifler kaydedildi."
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ErisTheme.bronzeHighlight)
                    
                    Button("Varsayılana Sıfırla") {
                        showResetConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .confirmationDialog("Tüm ajanlar varsayılan ayarlara döndürülsün mü?", isPresented: $showResetConfirmation) {
                        Button("Evet, Varsayılana Sıfırla", role: .destructive) {
                            personaManager.resetToDefaults()
                            customDirectivesText = ""
                            savedNotice = "Özel ajanlar sıfırlandı."
                        }
                    }
                    
                    Spacer()
                    
                    if !savedNotice.isEmpty {
                        Text(savedNotice)
                            .font(.caption2)
                            .foregroundColor(ErisTheme.listeningGreen)
                    }
                }
            }
        }
        .padding(20)
        .onAppear {
            customDirectivesText = personaManager.customDirectives
        }
        .sheet(item: $editingModule) { mod in
            EditModuleSheetView(module: mod) { title, subtitle, icon, instructions in
                personaManager.updateModule(id: mod.id, title: title, subtitle: subtitle, icon: icon, instructions: instructions, isEnabled: mod.isEnabled)
            }
        }
        .sheet(isPresented: $isCreatingNewModule) {
            EditModuleSheetView(module: nil) { title, subtitle, icon, instructions in
                _ = personaManager.addModule(title: title, subtitle: subtitle, icon: icon, instructions: instructions)
            }
        }
    }
}

struct EditModuleSheetView: View {
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(module == nil ? "Yeni Özel Ajan Oluştur" : "Ajanı Düzenle")
                    .font(.headline)
                    .foregroundColor(ErisTheme.coldWhite)
                
                Spacer()
                
                Button("İptal") { dismiss() }
                    .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Hazır Şablonlar
            VStack(alignment: .leading, spacing: 6) {
                Text("Hazır Ajan Şablonları")
                    .font(.caption).bold()
                    .foregroundColor(ErisTheme.bronzeHighlight)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(ErisAgentPersonaManager.starterTemplates) { tmpl in
                            Button(action: {
                                selectedTemplateId = tmpl.id
                                title = tmpl.title
                                subtitle = tmpl.subtitle
                                icon = tmpl.icon
                                instructions = tmpl.instructions
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: tmpl.icon)
                                    Text(tmpl.title)
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(RoundedRectangle(cornerRadius: 6).fill(selectedTemplateId == tmpl.id ? ErisTheme.bronzeHighlight : Color.white.opacity(0.08)))
                                .foregroundColor(selectedTemplateId == tmpl.id ? .black : ErisTheme.coldWhite)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            Form {
                Section(header: Text("Ajan Kimliği")) {
                    TextField("Ajan Başlığı (Örn: Kıdemli Yazılım Mimarı)", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Kısa Uzmanlık (Örn: Swift, Mimari & Refactoring)", text: $subtitle)
                        .textFieldStyle(.roundedBorder)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Simge Seçimi")
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldGray)
                        
                        HStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(ErisTheme.bronzeHighlight)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(ErisAgentPersonaManager.suggestedIcons, id: \.self) { sym in
                                        Button(action: { icon = sym }) {
                                            Image(systemName: sym)
                                                .font(.caption)
                                                .foregroundColor(icon == sym ? .black : ErisTheme.coldWhite)
                                                .padding(6)
                                                .background(Circle().fill(icon == sym ? ErisTheme.bronzeHighlight : Color.white.opacity(0.1)))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Ajan Direktifleri & Davranış Kuralları")) {
                    Text("Bu ajan etkinken Eris'in benimseyeceği rol, teknik uzmanlık, tavır ve eylem protokolü:")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                    
                    TextEditor(text: $instructions)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(height: 120)
                        .padding(6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ErisTheme.bronzeAccent.opacity(0.3), lineWidth: 0.8))
                }
            }
            
            HStack {
                Spacer()
                Button("Kaydet") {
                    onSave(title, subtitle, icon, instructions)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(ErisTheme.bronzeHighlight)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 550, height: 530)
        .background(ErisTheme.graphite)
    }
}

struct ModelApiSettingsTab: View {
    @ObservedObject var appState: ErisMacState
    @State private var customApiKey: String = KeychainManager.shared.getCustomOverrideApiKey() ?? ""
    @State private var customOpenAIApiKey: String = KeychainManager.shared.getOpenAIApiKey() ?? ""
    @State private var savedMessage: String = ""
    @State private var showDeveloperSection: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Bağlantı ve Servis Durumu Kartı
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title2)
                            .foregroundColor(ErisTheme.listeningGreen)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yapay Zekâ Motoru Aktif")
                                .font(.headline)
                                .foregroundColor(ErisTheme.coldWhite)
                            Text("Eris, yüksek performanslı bulut motoruna doğrudan bağlıdır.")
                                .font(.caption2)
                                .foregroundColor(ErisTheme.coldGray)
                        }
                        
                        Spacer()
                        
                        Text("Kullanıma Hazır")
                            .font(.caption2).bold()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(ErisTheme.listeningGreen.opacity(0.18))
                            .foregroundColor(ErisTheme.listeningGreen)
                            .clipShape(Capsule())
                    }
                    
                    Text("Son kullanıcıların herhangi bir teknik kurulum veya API anahtarı girişi yapmasına gerek yoktur. Tüm zekâ motoru ve oluşturulan özel ajanlar yerleşik olarak çalışır.")
                        .font(.caption)
                        .foregroundColor(ErisTheme.coldGray)
                        .lineSpacing(2)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                        )
                )
                
                // Model Seçimi
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dil & Analiz Modeli")
                        .font(.headline)
                        .foregroundColor(ErisTheme.coldWhite)
                    
                    Picker("Model", selection: $appState.selectedModel) {
                        ForEach(GeminiModelChoice.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(appState.selectedModel == .flash ? "Flash: Ultra-hızlı yanıt süresi, anlık sesli sohbet ve yürüyüş brifingleri için optimize edilmiştir." : "Pro: İleri düzey karmaşık analizler, kod mimarisi ve çok adımlı görevler için derinlikli model.")
                        .font(.caption2)
                        .foregroundColor(ErisTheme.coldGray)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                )
                
                // Geliştirici / Gelişmiş Override Bölümü
                DisclosureGroup("Gelişmiş Geliştirici Seçenekleri (İsteğe Bağlı)", isExpanded: $showDeveloperSection) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Geliştirici veya özel test anahtarı girmek isterseniz burayı kullanabilirsiniz. Boş bırakıldığında yerleşik geliştirici anahtarı geçerlidir.")
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldGray)
                        
                        SecureField("Özel Geliştirici API Anahtarı (Opsiyonel)", text: $customApiKey)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Özel Anahtarı Kaydet") {
                                if KeychainManager.shared.saveApiKey(customApiKey) {
                                    savedMessage = "Özel anahtar Keychain'e kaydedildi."
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(ErisTheme.bronzeHighlight)
                            .font(.caption)
                            
                            if !customApiKey.isEmpty {
                                Button("Sıfırla (Yerleşiğe Dön)") {
                                    KeychainManager.shared.deleteApiKey()
                                    customApiKey = ""
                                    savedMessage = "Yerleşik geliştirici anahtarına dönüldü."
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        Text("Stüdyo Kalitesinde İnsan Sesi (OpenAI TTS):")
                            .font(.caption2)
                            .foregroundColor(ErisTheme.coldGray)
                        
                        SecureField("OpenAI API Anahtarı (Opsiyonel)", text: $customOpenAIApiKey)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Button("Nöral Sesi Kaydet") {
                                if KeychainManager.shared.saveOpenAIApiKey(customOpenAIApiKey) {
                                    savedMessage = "OpenAI TTS anahtarı kaydedildi. Nöral ses aktif!"
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(ErisTheme.bronzeHighlight)
                            .font(.caption)
                            
                            if !customOpenAIApiKey.isEmpty {
                                Button("Kaldır") {
                                    KeychainManager.shared.deleteOpenAIApiKey()
                                    customOpenAIApiKey = ""
                                    savedMessage = "Nöral ses kaldırıldı. Apple yerel sesine dönüldü."
                                }
                                .buttonStyle(.bordered)
                                .font(.caption)
                            }
                        }
                        
                        if !savedMessage.isEmpty {
                            Text(savedMessage)
                                .font(.caption2)
                                .foregroundColor(ErisTheme.listeningGreen)
                        }
                    }
                    .padding(.top, 8)
                }
                .accentColor(ErisTheme.bronzeHighlight)
                .font(.caption)
                .foregroundColor(ErisTheme.coldGray)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.02)))
            }
            .padding(20)
        }
    }
}

struct VoiceToneRowView: View {
    let tone: ErisVoiceTone
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(tone.title)
                        .font(.subheadline).bold()
                        .foregroundColor(isSelected ? ErisTheme.bronzeHighlight : ErisTheme.coldWhite)
                    
                    if isSelected {
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
            
            Button("Sesi Dinle", action: onPreview)
                .buttonStyle(.bordered)
                .font(.caption2)
            
            if isSelected {
                Button("Seçili", action: {})
                    .buttonStyle(.borderedProminent)
                    .tint(ErisTheme.bronzeHighlight)
                    .font(.caption2)
                    .disabled(true)
            } else {
                Button("Seç", action: onSelect)
                    .buttonStyle(.bordered)
                    .tint(ErisTheme.bronzeHighlight)
                    .font(.caption2)
            }
        }
        .padding(.vertical, 4)
    }
}
