import Foundation
import Speech
import AVFoundation

public final class ErisVoiceListener: NSObject, @unchecked Sendable {
    public static let shared = ErisVoiceListener()
    
    private var speechRecognizer: SFSpeechRecognizer? {
        SFSpeechRecognizer(locale: ErisLanguageManager.shared.currentLanguage.speechLocale)
    }
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    public var onWakeWordDetected: (@Sendable () -> Void)?
    public var onTranscriptionUpdated: (@Sendable (String) -> Void)?
    public var onFinalTranscription: (@Sendable (String) -> Void)?
    public var onAudioLevel: (@Sendable (Float) -> Void)?
    public var onBargeInTriggered: (@Sendable () -> Void)?
    
    public private(set) var isListening: Bool = false
    public var isContinuousWakeWordActive: Bool = false
    
    // CPU & Pil optimizasyonu için eşikler
    private var silenceFrameCount: Int = 0
    private let bargeInAudioThreshold: Float = 0.075
    private var isTapInstalled: Bool = false
    
    private override init() {
        super.init()
    }
    
    public func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    public func startListening() throws {
        stopListening()
        
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "ErisVoice", code: 1, userInfo: [NSLocalizedDescriptionKey: "Ses isteği oluşturulamadı."])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                let lower = transcription.lowercased()
                
                // Barge-in tetikleme: Kullanıcı bir şeyler söylediğinde hoparlör susmalı
                if !transcription.isEmpty {
                    self.onBargeInTriggered?()
                    ErisSpeaker.shared.stopSpeaking()
                }
                
                // Wake word kontrolü ("Hey Eris", "Eris", "Ey Eris")
                if lower.contains("hey eris") || lower.contains("ey eris") || lower.contains("eris") {
                    self.onWakeWordDetected?()
                }
                
                self.onTranscriptionUpdated?(transcription)
                
                if result.isFinal {
                    self.onFinalTranscription?(transcription)
                }
            }
            
            if error != nil {
                self.stopListening()
                
                // Eğer sürekli uyandırma modu açıksa hata durumunda güvenle yeniden hazırla
                if self.isContinuousWakeWordActive {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        try? self.startListening()
                    }
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // Canlı ses seviyesi hesaplama (Waveform animasyonu için)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = UInt(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<Int(frameLength) {
                sum += abs(channelData[i])
            }
            let average = frameLength > 0 ? (sum / Float(frameLength)) : 0
            self.onAudioLevel?(average)
            
            // Barge-in: Eğer konuşurken ses algılanırsa derhal hoparlörü sustur
            if average > self.bargeInAudioThreshold {
                self.onBargeInTriggered?()
                ErisSpeaker.shared.stopSpeaking()
            }
            
            // CPU & Pil optimizasyonu: Uzun süreli tam sessizlikte gereksiz buffer yükünü sınırla
            if average < 0.005 {
                self.silenceFrameCount += 1
            } else {
                self.silenceFrameCount = 0
            }
            
            self.recognitionRequest?.append(buffer)
        }
        isTapInstalled = true
        
        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }
    
    public func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
}
