import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InteractionSession.date, order: .reverse) private var sessions: [InteractionSession]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background image
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                
                if sessions.isEmpty {
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
                } else {
                    List {
                        ForEach(sessions) { session in
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
            .navigationTitle("History")
            .toolbar {
                if !sessions.isEmpty {
                    EditButton()
                }
            }
            .onAppear {
                print("DEBUG: HistoryView sessions count: \(sessions.count)")
            }
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sessions[index])
            }
        }
    }
}

@available(iOS 17.0, *)
struct HistoryCard: View {
    let session: InteractionSession
    
    var body: some View {
        HStack {
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
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            }
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}
