import SwiftUI
import SwiftData
import CoreHaptics

@available(iOS 17, *)
struct ActiveSessionView: View {
    @EnvironmentObject var speechManager: SpeechManager
    @Binding var currentTab: Int
    @Environment(\.modelContext) private var modelContext
    
    // Analysis
    private let analysisManager = AnalysisManager()
    @State private var guidance: String?
    @State private var measure: String?
    @State private var currentTone: String = "Neutral"
    @State private var sentimentScore: Double = 0.0
    @State private var socialCues: [String] = []
    @State private var aiInsight: String?
    @State private var sessionStartTime: Date?
    
    // Haptics
    @State private var engine: CHHapticEngine?
    
    // Timer for periodic analysis
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).ignoresSafeArea()
            
            // Background fluid Gradient
            RadialGradient(gradient: Gradient(colors: [
                Color.blue.opacity(0.3 + sentimentScore * 0.2), // Shift color based on sentiment
                Color.black
            ]), center: .center, startRadius: 50, endRadius: 400)
            .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Image(systemName: "recordingtape")
                        .foregroundStyle(.red)
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(sessionStartTime ?? Date(), style: .timer)
                        .font(.monospacedDigit(.body)())
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                Spacer()
                
                // Visualizer
                WaveformVisualizerView(samples: speechManager.soundSamples)
                    .frame(height: 160)
                
                // Live Tone Badge
                Text(currentTone.uppercased())
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(toneColor().opacity(0.2))
                    .foregroundStyle(toneColor())
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(toneColor().opacity(0.5), lineWidth: 1))
                    .padding(.top, 10)
                
                Spacer()
                
                // Guidance Area
                VStack(spacing: 15) {
                    if let aiInsight = aiInsight, aiInsight != "None" {
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundStyle(.blue)
                            Text("AI Insight: \(aiInsight)")
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    if let guidance = guidance {
                        VStack(spacing: 12) {
                            Text(guidance)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if !socialCues.isEmpty {
                                HStack {
                                    ForEach(socialCues, id: \.self) { cue in
                                        Text(cue)
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            if let measure = measure {
                                Text(measure)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(toneColor().opacity(0.3), lineWidth: 1)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .onAppear { triggerHaptic() }
                    } else {
                        Text("Monitoring...")
                            .font(.headline)
                            .foregroundStyle(.tertiary)
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Controls
                Button(action: endSession) {
                    Text("End Session")
                        .font(.title3.bold())
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(30)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            sessionStartTime = Date()
            prepareHaptics()
        }
        .onReceive(timer) { _ in
            analyze()
        }
        .onChange(of: speechManager.isRecording) { newValue in
            if !newValue {
                // If recording stopped externally or error
                endSession()
            }
        }
    }
    
    private func analyze() {
        guard let start = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(start)
        
        let result = analysisManager.analyze(transcript: speechManager.transcript, duration: duration)
        
        withAnimation(.spring()) {
            self.sentimentScore = result.sentimentScore
            self.currentTone = result.tone
            self.socialCues = result.socialCues
            self.aiInsight = result.aiInsight
            
            if self.guidance != result.guidance {
                self.guidance = result.guidance
                self.measure = result.measure
            }
        }
    }
    
    private func toneColor() -> Color {
        switch currentTone {
        case "Tense": return .red
        case "Positive": return .green
        case "Rushed": return .orange
        case "Engaged": return .blue
        default: return .secondary
        }
    }
    
    private func endSession() {
        speechManager.stopRecording()
        
        // Save Session
        if let start = sessionStartTime {
            let duration = Date().timeIntervalSince(start)
            let newSession = InteractionSession(
                date: start,
                duration: duration,
                overallTone: sentimentScore,
                summary: speechManager.transcript.isEmpty ? "Quiet session" : "Conversation detected",
                transcript: speechManager.transcript,
                toneLabel: currentTone
            )
            modelContext.insert(newSession)
        }
        
        withAnimation {
            currentTab = 0
        }
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptics error: \(error.localizedDescription)")
        }
    }
    
    private func triggerHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}
