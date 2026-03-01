import SwiftUI
import SwiftData

@available(iOS 17, *)
struct ActiveSessionView: View {
    @EnvironmentObject var speechManager: SpeechManager
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var userProfile: UserProfile? { profiles.first }

    // MARK: - Analysis State
    private let analysisManager = AnalysisManager()
    @State private var guidance: String?
    @State private var measure: String?
    @State private var currentTone: String = "Neutral"
    @State private var sentimentScore: Double = 0.0
    @State private var socialCues: [String] = []
    @State private var aiInsight: String?
    @State private var sessionStartTime: Date?
    @State private var lastAnalysisResult: AnalysisResult?
    @State private var currentFeedbackType: FeedbackType = .neutral

    // MARK: - UI State
    @State private var isSaving = false
    @State private var showDurationError = false
    @State private var showCompletion = false
    @State private var elapsedSeconds: Int = 0
    @State private var isListening: Bool = false

    // Pulse animation
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6

    // Haptic trigger
    @State private var hapticTrigger = false

    // MARK: - Timers
    let audioTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    let guidanceTimer = Timer.publish(every: 10.0, on: .main, in: .common).autoconnect()

    // MARK: - Body
    var body: some View {
        // Main content — stop button pinned via safeAreaInset
        VStack(spacing: 14) {
            // Header Group
            VStack(spacing: 8) {
                pulseHeader
                statusLabels
            }
            
            Spacer(minLength: 0)
            
            guidanceCard
            waveformSection
            transcriptionSection
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Stop button pinned to bottom, never scrolls
        .safeAreaInset(edge: .bottom, spacing: 0) {
            stopButtonBar
        }
        .background {
            Image("background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .overlay {
            // Session complete overlay
            if showCompletion {
                SessionCompleteView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                    .zIndex(10)
            }
        }
        // ── iOS 17 onChange: single trailing closure receives (old, new)
        .onChange(of: speechManager.isRecording) { _, newValue in
            if !newValue { endSession() }
        }
        // Declarative haptic — no UIKit needed
        .sensoryFeedback(trigger: hapticTrigger) { _, _ in
            switch currentFeedbackType {
            case .positive:
                return .success
            case .constructive:
                return .warning
            case .neutral:
                return .impact(weight: .light)
            }
        }
        .onAppear {
            sessionStartTime = Date()
            startPulseAnimation()
        }
        .onReceive(audioTimer) { _ in
            isListening = !speechManager.transcript.isEmpty
                       || speechManager.soundLevel > 0.01
            if let start = sessionStartTime {
                elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
            analyzeMetricsOnly()
        }
        .onReceive(guidanceTimer) { _ in
            analyzeFullGuidance()
        }
        .alert("Session Too Short", isPresented: $showDurationError) {
            Button("OK", role: .cancel) {
                isPresented = false
            }
        } message: {
            Text("The conversation needs to be at least 10 seconds to be saved.")
        }
    }

    // MARK: - Sub-views

    /// Pulsating mic icon at the top
    private var pulseHeader: some View {
        ZStack {
            if isListening {
                Circle()
                    .stroke(Theme.primary.opacity(0.15), lineWidth: 2)
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulseScale * 1.3)
                    .opacity(pulseOpacity * 0.45)

                Circle()
                    .stroke(Theme.primary.opacity(0.25), lineWidth: 2)
                    .frame(width: 96, height: 96)
                    .scaleEffect(pulseScale * 1.15)
                    .opacity(pulseOpacity * 0.7)
            }

            Circle()
                .fill(isListening
                      ? Theme.primary.opacity(0.14)
                      : Color.gray.opacity(0.1))
                .frame(width: 80, height: 80)
                .scaleEffect(isListening ? pulseScale : 1.0)
                .overlay(
                    Image(systemName: isListening
                          ? "waveform.circle.fill"
                          : "mic.slash.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(isListening ? Theme.primary : .secondary)
                )
        }
        .frame(height: 100)
        .accessibilityLabel(isListening ? "Actively listening" : "Waiting for speech")
    }

    /// Title and dB status row
    private var statusLabels: some View {
        VStack(spacing: 6) {
            Text(isListening ? "Listening…" : "Waiting for speech…")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .animation(.easeInOut(duration: 0.25), value: isListening)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Circle()
                    .fill(isListening ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isListening ? pulseScale : 1.0)

                Text(loudnessLabel(soundLevel: speechManager.soundLevel))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// Prominent guidance card — only shown when guidance exists
    @ViewBuilder
    private var guidanceCard: some View {
        if let guidance = guidance {
            VStack(spacing: 10) {
                // AI insight pill
                if let insight = aiInsight, insight != "None" {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.primary)
                        Text(insight)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                Text(guidance)
                    .font(.system(size: 18, weight: .bold)) // Reduced from title3.weight(.heavy)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                if let measure = measure {
                    Text(measure)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Theme.primary.opacity(0.15), lineWidth: 1)
            )
            .transition(.scale(scale: 0.95).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Guidance: \(guidance). \(measure ?? "")")
        }
    }

    /// Animated waveform bar visualizer
    private var waveformSection: some View {
        WaveformVisualizerView(samples: speechManager.soundSamples)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .clipped()
            .accessibilityHidden(true)
    }

    /// Live transcript box — fully contained, no GeometryReader
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Live Transcription", systemImage: "text.bubble.fill")
                .font(.headline)
                .foregroundStyle(Theme.primary)

            ScrollView(.vertical, showsIndicators: false) {
                Text(speechManager.transcript.isEmpty
                     ? "Start speaking…"
                     : speechManager.transcript)
                    .font(.body)
                    .foregroundStyle(
                        speechManager.transcript.isEmpty ? .secondary : .primary
                    )
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(14)
                    .animation(.easeInOut(duration: 0.2), value: speechManager.transcript)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                .white.opacity(0.4),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .accessibilityLabel(
                speechManager.transcript.isEmpty
                ? "No speech detected yet"
                : "Transcript: \(speechManager.transcript)"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Stop button bar pinned to the bottom safe area
    private var stopButtonBar: some View {
        VStack(spacing: 6) {
            Button(action: endSession) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.9))
                        .frame(width: 70, height: 70)
                        .shadow(color: .red.opacity(0.35), radius: 12, y: 4)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                }
            }
            .accessibilityLabel("End session")
            .accessibilityHint("Stops recording and saves this conversation")

            Text("Tap to end session")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formatElapsed(elapsedSeconds))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Theme.primary.opacity(0.75))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func loudnessLabel(soundLevel: Float) -> String {
        let db = -64.9 + Double(soundLevel) * 64.9
        switch db {
        case ..<(-50): return "Too quiet — try speaking louder"
        case (-50)..<(-30): return "Quiet — just below normal"
        case (-30)..<(-10): return "Normal volume — great!"
        case (-10)..<0:     return "Loud — nearing peak"
        default:            return "Very loud — consider lowering your voice"
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        seconds >= 60
            ? "\(seconds / 60)m \(seconds % 60)s"
            : "\(seconds)s"
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.6)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.12
            pulseOpacity = 1.0
        }
    }

    // MARK: - Analysis

    private func analyzeMetricsOnly() {
        guard let start = sessionStartTime else { return }
        let result = analysisManager.analyze(
            transcript: speechManager.transcript,
            duration: Date().timeIntervalSince(start),
            userProfile: userProfile
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            sentimentScore = result.sentimentScore
            currentTone    = result.tone
            socialCues     = result.socialCues
            aiInsight      = result.aiInsight
            lastAnalysisResult = result
        }
    }

    private func analyzeFullGuidance() {
        guard let start = sessionStartTime else { return }
        let result = analysisManager.analyze(
            transcript: speechManager.transcript,
            duration: Date().timeIntervalSince(start),
            userProfile: userProfile
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            sentimentScore = result.sentimentScore
            currentTone    = result.tone
            socialCues     = result.socialCues
            aiInsight      = result.aiInsight
            lastAnalysisResult = result

            if guidance != result.guidance {
                guidance = result.guidance
                measure  = result.measure
                currentFeedbackType = result.feedbackType
                hapticTrigger.toggle()   // triggers .sensoryFeedback
            }
        }
    }

    // MARK: - Session End

    private func endSession() {
        guard !isSaving else { return }
        isSaving = true

        if speechManager.isRecording {
            speechManager.stopRecording()
        }

        guard let start = sessionStartTime else {
            isPresented = false
            return
        }

        let duration = Date().timeIntervalSince(start)

        guard duration >= 10.0 else {
            showDurationError = true
            isSaving = false
            return
        }

        let newSession = InteractionSession(
            date: start,
            duration: duration,
            overallTone: sentimentScore,
            summary: lastAnalysisResult?.analysisTitle
                  ?? (speechManager.transcript.isEmpty ? "Quiet session" : "Conversation detected"),
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
            try? context.save()

            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                showCompletion = true
            }
            try? await Task.sleep(for: .seconds(2.5))
            isPresented = false
        }
    }
}

@available(iOS 17, *)
struct ActiveSessionView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserProfile.self, InteractionSession.self, configurations: config)
        
        let mockProfile = UserProfile(
            favoriteTopics: "Technology, Space",
            improvementAreas: ["Eye Contact", "Slow down"],
            comfortFactors: ["Friendly tone"],
            hasCompletedOnboarding: true
        )
        container.mainContext.insert(mockProfile)
        
        return ActiveSessionView(isPresented: .constant(true))
            .environmentObject(SpeechManager())
            .modelContainer(container)
    }
}
