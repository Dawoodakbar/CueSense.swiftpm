import SwiftUI

@available(iOS 17, *)
struct HistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: InteractionSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Analysis Header
                VStack(spacing: 8) {
                    Text(session.analysisTitle ?? "Conversation Analysis")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    
                    if let topic = session.topic {
                        Text("Topic: \(topic)")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.top)
                
                // Header Stats
                HStack(spacing: 15) {
                    StatBox(title: "Duration", value: formatDuration(session.duration), icon: "clock", color: .blue)
                    StatBox(title: "Avg Tone", value: String(format: "%.1f", session.overallTone), icon: "waveform", color: .purple)
                    StatBox(title: "Tone Type", value: session.toneLabel ?? "Neutral", icon: "face.smiling", color: toneColor())
                }
                .padding(.horizontal)
                
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
                
                // Conversation Starters
                if !session.conversationStarters.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Label("Conversation Starters", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(session.conversationStarters, id: \.self) { starter in
                                Text(starter)
                                    .font(.subheadline.italic())
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Transcript Section (Collapsible or secondary)
                DisclosureGroup {
                    if let transcript = session.transcript, !transcript.isEmpty {
                        Text(transcript)
                            .padding()
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                    } else {
                        Text("No speech detected.")
                            .italic()
                            .foregroundStyle(.tertiary)
                            .padding()
                    }
                } label: {
                    Label("Conversation Transcript", systemImage: "quote.bubble.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.3)))
                .padding(.horizontal)
                
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
        .background(Color.blue.opacity(0.05).ignoresSafeArea())
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toneColor() -> Color {
        switch session.toneLabel {
        case "Tense": return .red
        case "Positive": return .green
        case "Rushed": return .orange
        case "Engaged": return .blue
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
                .font(.title3.bold())
                .multilineTextAlignment(.center)
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
