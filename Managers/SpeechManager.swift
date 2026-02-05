import Foundation
import Speech
import AVFoundation

/// SpeechManager handles on-device speech-to-text and audio levels.
/// It uses @MainActor to ensure UI updates are thread-safe, 
/// but utilizes nonisolated helpers to interact with system frameworks 
/// that callback on background threads.
@MainActor
class SpeechManager: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var error: String?
    @Published var soundLevel: Float = 0.0
    @Published var soundSamples: [Float] = Array(repeating: 0.0, count: 50)
    
    private let maxSamples = 50
    
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    /// Requests microphone and speech recognition permissions.
    /// Marked nonisolated to allow the system to call back on any thread 
    /// without violating MainActor constraints.
    nonisolated func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch status {
                case .authorized:
                    break
                case .denied, .restricted, .notDetermined:
                    self.error = "Speech recognition permission is required."
                @unknown default:
                    self.error = "Unknown authorization status."
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if !allowed {
                    self.error = "Microphone permission is required."
                }
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
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Audio session error: \(error.localizedDescription)"
            return
        }
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest = request
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        // We use a non-isolated task reference to avoid closure isolation issues
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            
            // Move back to MainActor for property updates
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    let nsError = error as NSError
                    // Code 216 is a user-initiated cancellation, not an error
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        return
                    }
                    print("Speech Task Error: \(error.localizedDescription)")
                    self.stopRecording()
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0 else {
            self.error = "Invalid audio format."
            return
        }
        
        inputNode.removeTap(onBus: 0)
        
        // Install tap using a closure that safely captures self nonisolatedly
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            // Recognition request append is thread-safe
            self.recognitionRequest?.append(buffer)
            
            // Level calculation is heavy, do it on the background tap thread
            let level = self.calculateRMS(buffer: buffer)
            
            // Dispatch UI update
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let scaledLevel = min(max(level * 20.0, 0), 1.0) // Increased gain for visibility
                if scaledLevel > 0.01 {
                    print("Sound Level: \(scaledLevel)")
                }
                self.soundLevel = scaledLevel
                
                // Add to samples for waveform
                self.soundSamples.append(scaledLevel)
                if self.soundSamples.count > self.maxSamples {
                    self.soundSamples.removeFirst()
                }
            }
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            self.error = "Audio engine start failed: \(error.localizedDescription)"
            self.stopRecording()
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
    nonisolated private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        let channelDataValue = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        
        if channelDataValue.isEmpty { return 0 }
        let sum = channelDataValue.reduce(0) { $0 + $1 * $1 }
        return sqrt(sum / Float(channelDataValue.count))
    }
}

