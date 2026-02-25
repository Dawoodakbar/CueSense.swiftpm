import SwiftUI

@available(iOS 17, *)
struct HistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: InteractionSession

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Analysis Header
                VStack(spacing: 8) {
                    Text(session.analysisTitle ?? "Conversation Analysis")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    if let topic = session.topic {
                        Text("Topic: \(topic)")
                            .font(.headline)
                            .foregroundStyle(Theme.primary)
                    }
                }
                .padding(.top)

                // Header Stats
                HStack(spacing: 12) {
                    StatBox(title: "Duration", value: formatDuration(session.duration), icon: "clock", color: Theme.primary)
                    StatBox(title: "Avg Tone", value: toneQualifier(session.overallTone), icon: "waveform", color: Theme.secondary)
                    StatBox(title: "Tone Type", value: session.toneLabel ?? "Neutral", icon: "face.smiling", color: toneColor())
                }
                .padding(.horizontal)

                // Conversation Summary — encouraging, soft tone
                VStack(alignment: .leading, spacing: 12) {
                    Label("Conversation Summary", systemImage: "doc.text.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.primary)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(generateSummary())
                            .font(.body)
                            .foregroundStyle(.primary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.primary.opacity(0.1), lineWidth: 1)
                    )
                }
                .padding(.horizontal)

                // Tone category explanation
                if let label = session.toneLabel, let explanation = toneExplanation(label) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.primary)
                            .font(.body)
                        Text(explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.primary.opacity(0.07))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }

                // Improvement Tips
                if !session.improvementTips.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Things to Improve", systemImage: "arrow.up.heart.fill")
                            .font(.headline)
                            .foregroundStyle(.green)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(session.improvementTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(tip)
                                        .font(.subheadline)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Next Conversation Suggestions
                VStack(alignment: .leading, spacing: 15) {
                    Label("Next Conversation Ideas", systemImage: "lightbulb.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 10) {
                        if let topic = session.topic {
                            SuggestionCard(
                                icon: "bubble.left.and.bubble.right.fill",
                                title: "Continue this topic",
                                subtitle: "Keep exploring \(topic) — ask deeper questions or share your own views."
                            )
                        }

                        SuggestionCard(
                            icon: "person.2.fill",
                            title: "Try a new topic",
                            subtitle: suggestNewTopic()
                        )

                        SuggestionCard(
                            icon: "star.fill",
                            title: "Practice a skill",
                            subtitle: suggestSkillPractice()
                        )
                    }
                }
                .padding(.horizontal)

                // Conversation Starters
                if !session.conversationStarters.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Conversation Starters", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(Theme.primary)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(session.conversationStarters, id: \.self) { starter in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "quote.opening")
                                        .font(.caption)
                                        .foregroundStyle(Theme.primary)
                                        .padding(.top, 3)
                                    Text(starter)
                                        .font(.subheadline.italic())
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.primary.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Theme.primary.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Actions
                Button(role: .destructive, action: deleteSession) {
                    Label("Delete Session", systemImage: "trash")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()
            }
            .padding(.top)
        }
        .background(
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Tone Qualifier for Sentiment Score

    private func toneQualifier(_ score: Double) -> String {
        switch score {
        case 0.5...:
            return "Very Positive"
        case 0.2..<0.5:
            return "Positive"
        case (-0.2)..<0.2:
            return "Neutral"
        case (-0.5)..<(-0.2):
            return "Slightly Tense"
        default:
            return "Tense"
        }
    }

    // MARK: - Tone Category Explanation

    private func toneExplanation(_ label: String) -> String? {
        switch label {
        case "Tense":
            return "A tense tone can occur when voices become faster, louder, or more strained. This is completely normal and improves with practice."
        case "Passive":
            return "A passive tone happens when speaking is slower or more reserved. Building confidence in conversations is a gradual process — you're making progress!"
        case "Rushed":
            return "A rushed tone means your speech pace was on the faster side. Slowing down and adding natural pauses helps others follow along more easily."
        case "Uncertain":
            return "Uncertainty in speech often shows up as hesitation or filler words. Preparing a few talking points beforehand can help build your confidence."
        case "Quiet":
            return "A quiet session had little spoken content. Even brief conversations are valuable practice — every interaction counts!"
        case "Calm":
            return "A calm tone means your pacing was measured and controlled — great for clear, meaningful conversations."
        case "Engaged":
            return "An engaged tone shows active, balanced participation. Keep it up!"
        case "Confident":
            return "A confident tone means your communication came across as clear and assertive. Well done!"
        case "Positive":
            return "A positive tone reflects an upbeat, encouraging conversational energy. Excellent!"
        default:
            return nil
        }
    }

    // MARK: - Encouraging Summary Generation

    private func generateSummary() -> String {
        var parts: [String] = []

        // Duration context
        let durationStr = formatDuration(session.duration)
        parts.append("This was a \(durationStr) conversation session.")

        // Topic
        if let topic = session.topic {
            parts.append("The discussion centered around \(topic).")
        }

        // Tone — reframed constructively
        if let tone = session.toneLabel {
            switch tone {
            case "Positive":
                parts.append("The overall mood was upbeat and encouraging — great energy!")
            case "Tense":
                parts.append("The interaction showed periods of elevated emotional intensity. This may be a good opportunity to reflect and continue improving.")
            case "Rushed":
                parts.append("The pacing was on the quicker side. Practicing with slower, deliberate speech can make conversations even more effective.")
            case "Calm":
                parts.append("The conversation maintained a calm, measured pace — ideal for clear dialogue.")
            case "Engaged":
                parts.append("Both sides were actively engaged throughout. This is a great sign of progress!")
            case "Passive":
                parts.append("This session was more quiet and reserved. That's perfectly okay — speaking up gets easier with every session.")
            case "Uncertain":
                parts.append("There were a few moments of hesitation — a natural part of building communication confidence.")
            case "Confident":
                parts.append("The tone came across as confident and assertive. Excellent work!")
            default:
                parts.append("The tone was generally neutral and measured.")
            }
        }

        // Sentiment — constructive, not judgmental
        if session.overallTone > 0.3 {
            parts.append("The emotional atmosphere leaned positively — keep building on that!")
        } else if session.overallTone < -0.3 {
            parts.append("There was some emotional tension detected. Reflecting on what triggered it is a healthy step toward improvement.")
        }

        // Closing encouraging note
        parts.append("Every conversation is a step forward. Keep practicing!")

        return parts.joined(separator: " ")
    }

    private func suggestNewTopic() -> String {
        let topics = ["current events", "favorite hobbies", "travel experiences", "movies or books", "future goals", "childhood memories"]
        let randomTopic = topics.randomElement() ?? "something new"
        return "Try talking about \(randomTopic) to broaden your conversational range."
    }

    private func suggestSkillPractice() -> String {
        if let tone = session.toneLabel {
            switch tone {
            case "Rushed":
                return "Focus on slowing down and adding natural pauses between your thoughts."
            case "Passive":
                return "Practice initiating topics and asking open-ended questions to build confidence."
            case "Tense":
                return "Work on using calming language and acknowledging the other person's viewpoint."
            case "Uncertain":
                return "Try preparing a few talking points beforehand to feel more confident going in."
            default:
                return "Keep practicing active listening and asking thoughtful follow-up questions."
            }
        }
        return "Practice active listening by summarizing what the other person says."
    }

    private func toneColor() -> Color {
        switch session.toneLabel {
        case "Tense": return .red
        case "Positive": return .green
        case "Rushed": return .orange
        case "Engaged": return Theme.primary
        default: return .secondary
        }
    }

    private func deleteSession() {
        modelContext.delete(session)
        dismiss()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.1), lineWidth: 1)
        )
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
