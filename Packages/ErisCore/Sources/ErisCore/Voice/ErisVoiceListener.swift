import Foundation
import Speech
import AVFoundation

public final class ErisVoiceListener: NSObject, @unchecked Sendable {
    public static let shared = ErisVoiceListener()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    public var onWakeWordDetected: (@Sendable () -> Void)?
    public var onTranscriptionUpdated: (@Sendable (String) -> Void)?
    public var onFinalTranscription: (@Sendable (String) -> Void)?
    public var onAudioLevel: (@Sendable (Float) -> Void)?
    
    public private(set) var isListening: Bool = false
    public var isContinuousWakeWordActive: Bool = false
    
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
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
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
                
                // Wake word kontrolü ("Hey Eris", "Eris")
                if lower.contains("eris") || lower.contains("hey eris") || lower.contains("ey eris") {
                    self.onWakeWordDetected?()
                }
                
                self.onTranscriptionUpdated?(transcription)
                
                if result.isFinal {
                    self.onFinalTranscription?(transcription)
                }
            }
            
            if error != nil {
                self.stopListening()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Canlı ses seviyesi hesaplama (Waveform animasyonu için)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = UInt(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<Int(frameLength) {
                sum += abs(channelData[i])
            }
            let average = frameLength > 0 ? (sum / Float(frameLength)) : 0
            self?.onAudioLevel?(average)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }
    
    public func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
}
