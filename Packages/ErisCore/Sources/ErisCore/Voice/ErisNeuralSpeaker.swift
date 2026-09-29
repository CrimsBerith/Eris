//
//  ErisNeuralSpeaker.swift
//  ErisCore
//
//  Created by Eris on 2026-09-29.
//

import Foundation
import AVFoundation

/// Gerçek stüdyo ve insan ses kalitesinde (OpenAI TTS-1 / Neural) konuşma motoru.
/// Eris'e nefes alan, tok ve karizmatik gerçek insan sesi kazandırır.
public final class ErisNeuralSpeaker: NSObject, AVAudioPlayerDelegate, @unchecked Sendable {
    public static let shared = ErisNeuralSpeaker()
    
    private var audioPlayer: AVAudioPlayer?
    private let cacheDirectory: URL
    private let session: URLSession
    
    public var onSpeakingStarted: (@Sendable () -> Void)?
    public var onSpeakingFinished: (@Sendable () -> Void)?
    
    public private(set) var isSpeaking: Bool = false
    
    private override init() {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("ErisNeuralVoiceCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        self.cacheDirectory = temp
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: config)
        
        super.init()
    }
    
    // MARK: - OpenAI Nöral Ses Eşleştirmesi
    
    public static func openAIVoiceName(for tone: ErisVoiceTone) -> String {
        switch tone {
        case .tokErkek:
            return "onyx"   // Tok, derin, güvenilir ve sakin erkek sesi
        case .derinBariton:
            return "onyx"   // Düşük perdeli, koruyucu ve oturaklı
        case .sicakKadin:
            return "nova"   // Canlı, sıcak, ilham verici kadın sesi
        case .dinamikPartner:
            return "echo"   // Dinamik, enerjik ve tempolu partner sesi
        case .minimalistDirekt:
            return "alloy"  // Dengeli, net ve doğrudan profesyonel stüdyo tonu
        }
    }
    
    // MARK: - Ses Üretme ve Çalma
    
    /// Verilen metni stüdyo kalitesinde nöral ses motoruyla seslendirir.
    /// Başarısız olursa false döner (böylece çağırıcı yerel AVSpeech'e geçebilir).
    public func speak(text: String, tone: ErisVoiceTone) async -> Bool {
        let apiKey = ErisAppConfig.activeOpenAIApiKey
        guard !apiKey.isEmpty else { return false }
        
        let voice = Self.openAIVoiceName(for: tone)
        let cacheKey = "\(voice)_\(text.hashValue).mp3"
        let cachedFile = cacheDirectory.appendingPathComponent(cacheKey)
        
        do {
            let audioData: Data
            if FileManager.default.fileExists(atPath: cachedFile.path),
               let data = try? Data(contentsOf: cachedFile) {
                audioData = data
            } else {
                guard let fetched = try await fetchOpenAIAudio(text: text, voice: voice, apiKey: apiKey) else {
                    return false
                }
                audioData = fetched
                try? audioData.write(to: cachedFile)
            }
            
            return await playAudioData(audioData)
        } catch {
            return false
        }
    }
    
    private func fetchOpenAIAudio(text: String, voice: String, apiKey: String) async throws -> Data? {
        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": voice,
            "speed": 0.96,
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            return nil
        }
        
        return data
    }
    
    @MainActor
    private func playAudioData(_ data: Data) -> Bool {
        stop()
        
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {}
        #endif
        
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            player.prepareToPlay()
            if player.play() {
                self.audioPlayer = player
                self.isSpeaking = true
                self.onSpeakingStarted?()
                return true
            }
        } catch {}
        
        return false
    }
    
    public func stop() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        isSpeaking = false
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
        audioPlayer = nil
        onSpeakingFinished?()
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isSpeaking = false
        audioPlayer = nil
        onSpeakingFinished?()
    }
}
