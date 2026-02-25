import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InteractionSession.date, order: .reverse) private var sessions: [InteractionSession]
    @State private var selectedFilter: ToneFilter = .all

    enum ToneFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case tense = "Tense"
        case quiet = "Quiet"
        case passive = "Passive"

        var id: String { rawValue }

        var description: String {
            switch self {
            case .all:
                return "All your conversation sessions."
            case .tense:
                return "Tense moments often occur when voices become faster or more strained. This is completely normal and improves with practice."
            case .quiet:
                return "Quiet sessions are when there was little spoken. Even short conversations are great practice!"
            case .passive:
                return "Passive sessions happen when speaking was slower or more reserved. Building confidence takes time — you're doing great."
            }
        }

        var matchingLabels: [String] {
            switch self {
            case .all: return []
            case .tense: return ["Tense", "Rushed", "Uncertain"]
            case .quiet: return ["Quiet"]
            case .passive: return ["Passive"]
            }
        }
    }

    private var filteredSessions: [InteractionSession] {
        guard selectedFilter != .all else { return sessions }
        return sessions.filter { session in
            guard let label = session.toneLabel else { return false }
            if selectedFilter == .quiet {
                // Also catch sessions with very short transcripts
                return selectedFilter.matchingLabels.contains(label) ||
                    (session.transcript?.isEmpty ?? true) ||
                    (session.transcript?.split(separator: " ").count ?? 0) < 10
            }
            return selectedFilter.matchingLabels.contains(label)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background image
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ToneFilter.allCases) { filter in
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedFilter = filter
                                    }
                                }) {
                                    Text(filter.rawValue)
                                        .font(.subheadline.weight(selectedFilter == filter ? .bold : .medium))
                                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 9)
                                        .background(
                                            Capsule()
                                                .fill(selectedFilter == filter
                                                    ? Theme.primary
                                                    : Color(.systemBackground).opacity(0.6))
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    // Category explanation banner
                    if selectedFilter != .all {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Theme.primary)
                            Text(selectedFilter.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground).opacity(0.5))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if sessions.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundStyle(Theme.primary.opacity(0.3))
                            Text("No sessions yet")
                                .font(.title3.bold())
                                .foregroundStyle(.secondary)
                            Text("Your conversation history will appear here once you complete your first session.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else if filteredSessions.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundStyle(Theme.primary.opacity(0.3))
                            Text("No \(selectedFilter.rawValue) sessions")
                                .font(.title3.bold())
                                .foregroundStyle(.secondary)
                            Text("Sessions tagged as \(selectedFilter.rawValue.lowercased()) will show here.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredSessions) { session in
                                ZStack {
                                    NavigationLink(destination: HistoryDetailView(session: session)) {
                                        EmptyView()
                                    }
                                    .opacity(0)

                                    HistoryCard(session: session)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onDelete(perform: deleteSessions)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !sessions.isEmpty {
                    EditButton()
                }
            }
        }
    }

    private func deleteSessions(offsets: IndexSet) {
        let toDelete = offsets.map { filteredSessions[$0] }
        withAnimation {
            for session in toDelete {
                modelContext.delete(session)
            }
        }
    }
}

@available(iOS 17.0, *)
struct HistoryCard: View {
    let session: InteractionSession

    var body: some View {
        HStack {
            // Tone color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(toneColor(for: session.toneLabel))
                .frame(width: 4, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.analysisTitle ?? session.summary)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Label(formatDuration(session.duration), systemImage: "clock")
                    Spacer()
                    Label(session.toneLabel ?? "Neutral", systemImage: "waveform")
                        .foregroundStyle(toneColor(for: session.toneLabel))
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
    }

    private func toneColor(for label: String?) -> Color {
        switch label {
        case "Tense", "Rushed": return .red.opacity(0.8)
        case "Positive", "Engaged", "Confident": return .green.opacity(0.8)
        case "Calm": return .blue.opacity(0.7)
        case "Passive": return .orange.opacity(0.8)
        case "Uncertain": return .yellow.opacity(0.9)
        default: return Theme.primary.opacity(0.5)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}
