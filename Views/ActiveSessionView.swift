import SwiftUI
import SwiftData
import CoreHaptics

@available(iOS 17, *)
@available(iOS 17, *)
struct ActiveSessionView: View {
  @EnvironmentObject var speechManager: SpeechManager
  @Binding var isPresented: Bool
  @Environment(\.modelContext) private var modelContext
  @Query private var profiles: [UserProfile]

  private var userProfile: UserProfile? {
    profiles.first
  }

  // Analysis
  private let analysisManager = AnalysisManager()
  @State private var guidance: String?
  @State private var measure: String?
  @State private var currentTone: String = "Neutral"
  @State private var sentimentScore: Double = 0.0
  @State private var socialCues: [String] = []
  @State private var aiInsight: String?
  @State private var sessionStartTime: Date?

  // Extra analysis result for saving
  @State private var lastAnalysisResult: AnalysisResult?

  // Haptics
  @State private var engine: CHHapticEngine?

  // Timer for audio metrics (every 1s)
  let audioTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
  // Timer for guidance/suggestions (every 10s)
  let guidanceTimer = Timer.publish(every: 10.0, on: .main, in: .common).autoconnect()

  // Elapsed time
  @State private var elapsedSeconds: Int = 0

  var body: some View {
    ZStack {
      // Background image
      Image("background")
          .resizable()
          .aspectRatio(contentMode: .fill)
          .ignoresSafeArea()

      VStack(spacing: 0) {
        Spacer()
            .frame(height: 60)

        // Listening Header
        VStack(spacing: 8) {
          Text("Listening...")
              .font(.system(size: 32, weight: .heavy, design: .rounded))
              .foregroundStyle(.primary)

          HStack(spacing: 6) {
            Circle()
                .fill(Color.gray)
                .frame(width: 8, height: 8)
            Text(speechManager.transcript.isEmpty ? "Waiting for speech" : "Hearing speech")
                .font(.subheadline)
                .foregroundStyle(.secondary)
          }
        }

        Spacer()
            .frame(height: 30)

        // Dot Waveform Visualizer
        WaveformVisualizerView(samples: speechManager.soundSamples)
            .frame(height: 50)
            .padding(.horizontal, 8)

        Spacer()
            .frame(height: 30)

        // Live Transcription Section
        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 6) {
            Image(systemName: "text.bubble.fill")
                .foregroundStyle(Theme.primary)
            Text("Live Transcription")
                .font(.headline)
                .foregroundStyle(.primary)
          }

          ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.5))
                .frame(minHeight: 80)

            Text(speechManager.transcript.isEmpty ? "Start speaking..." : speechManager.transcript)
                .font(.body)
                .foregroundStyle(speechManager.transcript.isEmpty ? .secondary : .primary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
          }
        }
        .padding(.horizontal, 20)

        Spacer()
            .frame(height: 16)

        // dB + Total Time
        Text("dB: \(String(format: "%.1f", -64.9 + Double(speechManager.soundLevel) * 64.9)) | Total: \(formatElapsed(elapsedSeconds))")
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Theme.primary.opacity(0.7))

        // Guidance Area (only shows when available)
        if let guidance = guidance {
          VStack(spacing: 8) {
            if let aiInsight = aiInsight, aiInsight != "None" {
              HStack(spacing: 4) {
                Image(systemName: "cpu.fill")
                    .font(.caption2)
                    .foregroundStyle(Theme.primary)
                Text(aiInsight)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
              }
              .padding(.horizontal, 10)
              .padding(.vertical, 4)
              .background(.ultraThinMaterial)
              .clipShape(Capsule())
            }

            Text(guidance)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let measure = measure {
              Text(measure)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.center)
            }
          }
          .padding()
          .frame(maxWidth: .infinity)
          .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.5))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.3), lineWidth: 1)
          )
          .padding(.horizontal, 20)
          .padding(.top, 12)
          .transition(.scale.combined(with: .opacity))
          .onAppear { triggerHaptic() }
        }

        Spacer()

        // Stop Button
        VStack(spacing: 10) {
          Button(action: endSession) {
            ZStack {
              Circle()
                  .fill(Color.red.opacity(0.9))
                  .frame(width: 72, height: 72)
                  .shadow(color: .red.opacity(0.3), radius: 10, y: 4)

              RoundedRectangle(cornerRadius: 6)
                  .fill(.white)
                  .frame(width: 24, height: 24)
            }
          }

          Text("Tap to end session")
              .font(.caption)
              .foregroundStyle(.secondary)
        }
        .padding(.bottom, 40)
      }
      .padding(.horizontal, 24)
    }
    .onAppear {
      sessionStartTime = Date()
      prepareHaptics()
    }
    .onReceive(audioTimer) { _ in
      // Update elapsed time and tone metrics every second
      if let start = sessionStartTime {
        elapsedSeconds = Int(Date().timeIntervalSince(start))
      }
      analyzeMetricsOnly()
    }
    .onReceive(guidanceTimer) { _ in
      // Update guidance/suggestions every 10 seconds
      analyzeFullGuidance()
    }
    .onChange(of: speechManager.isRecording) { newValue in
      if !newValue {
        endSession()
      }
    }
  }

  // Quick metrics update (tone, sentiment) — runs every 1s
  private func analyzeMetricsOnly() {
    guard let start = sessionStartTime else { return }
    let duration = Date().timeIntervalSince(start)

    let result = analysisManager.analyze(
      transcript: speechManager.transcript,
      duration: duration,
      userProfile: userProfile
    )

    withAnimation(.spring()) {
      self.sentimentScore = result.sentimentScore
      self.currentTone = result.tone
      self.socialCues = result.socialCues
      self.aiInsight = result.aiInsight
      self.lastAnalysisResult = result
    }
  }

  // Full guidance update — runs every 10s
  private func analyzeFullGuidance() {
    guard let start = sessionStartTime else { return }
    let duration = Date().timeIntervalSince(start)

    let result = analysisManager.analyze(
      transcript: speechManager.transcript,
      duration: duration,
      userProfile: userProfile
    )

    withAnimation(.spring()) {
      self.sentimentScore = result.sentimentScore
      self.currentTone = result.tone
      self.socialCues = result.socialCues
      self.aiInsight = result.aiInsight
      self.lastAnalysisResult = result

      if self.guidance != result.guidance {
        self.guidance = result.guidance
        self.measure = result.measure
      }
    }
  }

  private func formatElapsed(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return "\(m)m \(s)s"
  }

  @State private var isSaving = false

  private func endSession() {
    guard !isSaving else { return }
    isSaving = true

    let wasRecording = speechManager.isRecording
    if wasRecording {
      speechManager.stopRecording()
    }

    // Save Session if we have a start time
    if let start = sessionStartTime {
      let duration = Date().timeIntervalSince(start)
      print("DEBUG: Session duration: \(duration)")

      // Only save if there was actual duration or transcript, to avoid noise
      if duration > 0.1 {
        let newSession = InteractionSession(
          date: start,
          duration: duration,
          overallTone: sentimentScore,
          summary: lastAnalysisResult?.analysisTitle ?? (speechManager.transcript.isEmpty ? "Quiet session" : "Conversation detected"),
          transcript: speechManager.transcript,
          toneLabel: currentTone,
          topic: lastAnalysisResult?.topic,
          analysisTitle: lastAnalysisResult?.analysisTitle,
          improvementTips: lastAnalysisResult?.improvementTips ?? [],
          conversationStarters: lastAnalysisResult?.conversationStarters ?? []
        )
                // Perform Save
                let context = modelContext
                Task { @MainActor in
                    context.insert(newSession)
                    do {
                        try context.save()
                        print("DEBUG: Session saved successfully! ID: \(newSession.id)")
                    } catch {
                        print("DEBUG: Failed to save session: \(error)")
                    }
                    
                    // Delay dismissal slightly to ensure UI updates
                    try? await Task.sleep(for: .seconds(0.5))
                    withAnimation {
                        isPresented = false
                    }
                }
                return
      } else {
        print("DEBUG: Session too short to save")
      }
    } else {
      print("DEBUG: sessionStartTime is nil")
    }

    withAnimation {
      isPresented = false
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
