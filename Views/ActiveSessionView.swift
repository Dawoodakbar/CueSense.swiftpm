import SwiftUI
import SwiftData

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

  // Duration Error Alert
  @State private var showDurationError = false

  // Completion celebration
  @State private var showCompletion = false

  // Timer for audio metrics (every 1s)
  let audioTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
  // Timer for guidance/suggestions (every 10s)
  let guidanceTimer = Timer.publish(every: 10.0, on: .main, in: .common).autoconnect()

  // Elapsed time
  @State private var elapsedSeconds: Int = 0

  // Pulsating animation
  @State private var pulseScale: CGFloat = 1.0
  @State private var pulseOpacity: Double = 0.6
  @State private var isListening: Bool = false

  var body: some View {
    ZStack {
      // Background image
      Image("background")
          .resizable()
          .aspectRatio(contentMode: .fill)
          .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

            // Listening Header with pulsating animation
            ZStack {
              // Outer pulse rings
              if isListening {
                Circle()
                  .stroke(Theme.primary.opacity(0.15), lineWidth: 2)
                  .frame(width: 96, height: 96)
                  .scaleEffect(pulseScale * 1.3)
                  .opacity(pulseOpacity * 0.5)

                Circle()
                  .stroke(Theme.primary.opacity(0.25), lineWidth: 2)
                  .frame(width: 96, height: 96)
                  .scaleEffect(pulseScale * 1.15)
                  .opacity(pulseOpacity * 0.7)
              }

              // Inner mic button
              Circle()
                .fill(isListening
                  ? Theme.primary.opacity(0.12)
                  : Color.gray.opacity(0.1))
                .frame(width: 80, height: 80)
                .scaleEffect(isListening ? pulseScale : 1.0)
                .overlay(
                  Image(systemName: isListening ? "waveform.circle.fill" : "mic.slash.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(isListening ? Theme.primary : Color.gray)
                )
            }
            .frame(height: 100)

            VStack(spacing: 6) {
              Text(isListening ? "Listening…" : "Waiting for speech…")
                  .font(.system(size: 28, weight: .heavy, design: .rounded))
                  .foregroundStyle(.primary)
                  .animation(.easeInOut, value: isListening)

              // dB label
              let dbLabel = loudnessLabel(soundLevel: speechManager.soundLevel)
              HStack(spacing: 6) {
                Circle()
                    .fill(isListening ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isListening ? pulseScale : 1.0)
                Text(dbLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
              }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.top, 10)

            Spacer()
                .frame(height: 28)

            // === GUIDANCE — PROMINENTLY AT TOP ===
            if let guidance = guidance {
              VStack(spacing: 10) {
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
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                if let measure = measure {
                  Text(measure)
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                      .multilineTextAlignment(.center)
                }
              }
              .padding(18)
              .frame(maxWidth: .infinity)
              .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground).opacity(0.75))
                    .shadow(color: Theme.primary.opacity(0.15), radius: 10, y: 4)
              )
              .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.primary.opacity(0.3), lineWidth: 1.5)
              )
              .padding(.horizontal, 20)
              .transition(.scale.combined(with: .opacity))
            }

            Spacer()
                .frame(height: 20)

            // Waveform Visualizer
            WaveformVisualizerView(samples: speechManager.soundSamples)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .padding(.horizontal, 20)
                .clipped()

            Spacer()
                .frame(height: 24)

            // Live Transcription Section
            GeometryReader { geo in
                let boxWidth = geo.size.width - 40 // 20pt padding each side
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.primary)
                        Text("Live Transcription")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.leading, 4)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.55))
                            .frame(width: boxWidth, height: 130)

                        ScrollView {
                            Text(speechManager.transcript.isEmpty ? "Start speaking..." : speechManager.transcript)
                                .font(.body)
                                .foregroundStyle(speechManager.transcript.isEmpty ? .secondary : .primary)
                                .frame(width: boxWidth - 28, alignment: .topLeading) // subtract padding
                                .padding(14)
                        }
                        .frame(width: boxWidth, height: 130)
                    }
                }
                .padding(.horizontal, 20)
                .frame(width: geo.size.width, alignment: .leading)
            }
            .frame(height: 168) // header (~38) + box (130)

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

              // Elapsed time
              Text(formatElapsed(elapsedSeconds))
                  .font(.system(.caption, design: .monospaced))
                  .foregroundStyle(Theme.primary.opacity(0.7))
            }
            .padding(.bottom, 44)
            .padding(.top, 12)
          }
          .frame(maxWidth: .infinity)
        }

      // Completion overlay
      if showCompletion {
        SessionCompleteView()
          .transition(.opacity)
          .zIndex(10)
      }
    }
    .onAppear {
      sessionStartTime = Date()
      startPulseAnimation()
    }
    .onReceive(audioTimer) { _ in
      isListening = !speechManager.transcript.isEmpty || speechManager.soundLevel > 0.01
      if let start = sessionStartTime {
        elapsedSeconds = Int(Date().timeIntervalSince(start))
      }
      analyzeMetricsOnly()
    }
    .onReceive(guidanceTimer) { _ in
      analyzeFullGuidance()
    }
    .onChange(of: speechManager.isRecording) { newValue in
      if !newValue {
        endSession()
      }
    }
    .alert("Session Too Short", isPresented: $showDurationError) {
      Button("OK", role: .cancel) {
        withAnimation {
          isPresented = false
        }
      }
    } message: {
      Text("The conversation needs to be more than 10 seconds for it to count.")
    }
  }

  // MARK: - Loudness Label
  private func loudnessLabel(soundLevel: Float) -> String {
    let db = -64.9 + Double(soundLevel) * 64.9
    switch db {
    case ..<(-50):
      return "Too quiet — try speaking louder"
    case (-50)..<(-30):
      return "Quiet — just below normal"
    case (-30)..<(-10):
      return "Normal volume — great!"
    case (-10)..<0:
      return "Loud — nearing peak"
    default:
      return "Very loud — consider lowering your voice"
    }
  }

  // MARK: - Pulse Animation
  private func startPulseAnimation() {
    withAnimation(
      .easeInOut(duration: 1.6)
      .repeatForever(autoreverses: true)
    ) {
      pulseScale = 1.12
      pulseOpacity = 1.0
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
        triggerHaptic()
      }
    }
  }

  private func formatElapsed(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return m > 0 ? "\(m)m \(s)s" : "\(s)s"
  }

  @State private var isSaving = false

  private func endSession() {
    guard !isSaving else { return }
    isSaving = true

    let wasRecording = speechManager.isRecording
    if wasRecording {
      speechManager.stopRecording()
    }

    if let start = sessionStartTime {
      let duration = Date().timeIntervalSince(start)
      print("DEBUG: Session duration: \(duration)")

      if duration < 10.0 {
        showDurationError = true
        return
      }

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
        let context = modelContext
        Task { @MainActor in
          context.insert(newSession)
          do {
            try context.save()
            print("DEBUG: Session saved successfully! ID: \(newSession.id)")
          } catch {
            print("DEBUG: Failed to save session: \(error)")
          }

          // Show celebration before dismissing
          withAnimation(.spring()) {
            showCompletion = true
          }
          try? await Task.sleep(for: .seconds(2.5))
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

    private func triggerHaptic() {
      let generator = UINotificationFeedbackGenerator()
      generator.notificationOccurred(.warning)
    }
}
