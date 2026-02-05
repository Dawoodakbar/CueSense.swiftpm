import SwiftUI

@available(iOS 17, *)
struct HistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let session: InteractionSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header Stats
                HStack(spacing: 15) {
                    StatBox(title: "Duration", value: formatDuration(session.duration), icon: "clock", color: .blue)
                    StatBox(title: "Avg Tone", value: String(format: "%.1f", session.overallTone), icon: "waveform", color: .purple)
                    StatBox(title: "Tone Type", value: session.toneLabel ?? "Neutral", icon: "face.smiling", color: toneColor())
                }
                .padding(.horizontal)
                
                // Analytics Section
                VStack(alignment: .leading, spacing: 15) {
                    Label("Conversation Transcript", systemImage: "quote.bubble.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    if let transcript = session.transcript, !transcript.isEmpty {
                        Text(transcript)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(16)
                    } else {
                        Text("No speech detected.")
                            .italic()
                            .foregroundStyle(.tertiary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal)
                
                // Actions
                Button(role: .destructive, action: deleteSession) {
                    Label("Delete Session", systemImage: "trash")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top)
        }
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
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(15)
    }
}
