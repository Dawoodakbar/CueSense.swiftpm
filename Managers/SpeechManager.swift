import Foundation
import Speech
import AVFoundation

/// SpeechManager handles on-device speech-to-text and audio levels.
/// It uses @MainActor to ensure UI updates are thread-safe, 
/// but utilizes nonisolated helpers to interact with system frameworks 
/// that callback on background threads.
@MainActor
final class SpeechManager: ObservableObject, Sendable {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var error: String?
    @Published var soundLevel: Float = 0.0
    @Published var soundSamples: [Float] = Array(repeating: 0, count: 80)
    
    private let maxSamples = 80
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    /// Requests microphone and speech recognition permissions.
    /// Requests microphone and speech recognition permissions.
    func checkPermissions() {
        Task {
            let speechStatus = await SpeechManager.requestSpeechAuth()
            let recordAllowed = await SpeechManager.requestRecordAuth()
            
            switch speechStatus {
            case .authorized:
                break
            case .denied, .restricted, .notDetermined:
                self.error = "Speech recognition permission is required."
            @unknown default:
                self.error = "Unknown authorization status."
            }
            
            if !recordAllowed {
                self.error = "Microphone permission is required."
            }
        }
    }
    
    // MARK: - Static Permission Helpers
    
    nonisolated private static func requestSpeechAuth() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
    
    nonisolated private static func requestRecordAuth() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }
    
    /// Starts the audio engine and speech recognition task.
    func startRecording() {
        // Defensive cleanup
        stopRecording()
        
        transcript = ""
        error = nil
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            self.error = "Speech recognizer is not available."
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio Session configured: playAndRecord")
        } catch {
            self.error = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = request
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 else {
            self.error = "Invalid audio format."
            return
        }
        
        // Remove existing tap if any
        inputNode.removeTap(onBus: 0)
        
        // 1. Start Recognition Task (Non-isolated creation)
        let managerWrapper = UncheckedSendable(self)
        recognitionTask = SpeechManager.startRecognitionTask(
            recognizer: recognizer,
            request: request,
            managerWrapper: managerWrapper
        )
        
        // 2. Install Audio Tap (Non-isolated installation)
        let requestWrapper = UncheckedSendable(request)
        SpeechManager.installAudioTap(
            inputNode: inputNode,
            format: recordingFormat,
            requestWrapper: requestWrapper,
            managerWrapper: managerWrapper
        )
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            self.error = "Audio engine start failed: \(error.localizedDescription)"
            self.stopRecording()
        }
    }
    
    // MARK: - Safe State Updates
    
    func processSpeechResult(_ transcript: String?, error: Error?) {
        if let transcript = transcript {
            self.transcript = transcript
        }
        
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                return
            }
            print("Speech Task Error: \(error.localizedDescription)")
            self.stopRecording()
        }
    }
    
    func processAudioLevel(_ level: Float) {
        let scaledLevel = min(max(level * 20.0, 0), 1.0)
        if scaledLevel > 0.01 {
            // print("Sound Level: \(scaledLevel)") // Reduce log noise
        }
        self.soundLevel = scaledLevel
        
        self.soundSamples.append(scaledLevel)
        if self.soundSamples.count > 80 {
            self.soundSamples.removeFirst()
        }
    }
    
    // MARK: - Non-isolated Background Helpers
    
    nonisolated private static func startRecognitionTask(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        managerWrapper: UncheckedSendable<SpeechManager>
    ) -> SFSpeechRecognitionTask {
        return recognizer.recognitionTask(with: request) { result, error in
            let transcript = result?.bestTranscription.formattedString
            Task { @MainActor in
                managerWrapper.value.processSpeechResult(transcript, error: error)
            }
        }
    }
    
    nonisolated private static func installAudioTap(
        inputNode: AVAudioInputNode,
        format: AVAudioFormat,
        requestWrapper: UncheckedSendable<SFSpeechAudioBufferRecognitionRequest>,
        managerWrapper: UncheckedSendable<SpeechManager>
    ) {
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            requestWrapper.value.append(buffer)
            let level = SpeechManager.calculateRMS(buffer: buffer)
            
            Task { @MainActor in
                managerWrapper.value.processAudioLevel(level)
            }
        }
    }


/// A wrapper to silence strict concurrency warnings for types that are known to be safe in a specific context
/// but are not marked Sendable (like SFSpeechAudioBufferRecognitionRequest).
struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}
    
    /// Stops the audio engine and cancels the recognition task.
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.outputNode.removeTap(onBus: 0) // Extra safety check for output tap
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    /// Calculate RMS on a background thread for performance.
    nonisolated static func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let channelDataValue = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        if channelDataValue.isEmpty { return 0 }
        let sum = channelDataValue.reduce(0) { $0 + $1 * $1 }
        return sqrt(sum / Float(channelDataValue.count))
    }
}

