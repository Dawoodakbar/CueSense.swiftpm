import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct HomeView: View {
    @EnvironmentObject var speechManager: SpeechManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InteractionSession.date, order: .reverse) private var sessions: [InteractionSession]
    
    @Binding var currentTab: Int // 0: Home, 1: Active
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "ear.and.waveform")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue.gradient)
                        .padding()
                        .background(
                            Circle()
                                .fill(.blue.opacity(0.1))
                                .frame(width: 120, height: 120)
                        )
                    
                    Text("CueSense")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your private social assistant")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 50)
                .onAppear {
                    speechManager.checkPermissions()
                }
                
                Spacer()
                
                // Main Action
                Button(action: {
                    withAnimation {
                        speechManager.startRecording()
                        currentTab = 1 // Switch to Active View
                    }
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("Start Session")
                    }
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            .shadow(radius: 10, y: 5)
                            
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Recent History
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Recent History")
                            .font(.headline)
                        Spacer()
                    }
                    
                    if sessions.isEmpty {
                        Text("No sessions yet.")
                            .italic()
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        List {
                            ForEach(sessions.prefix(5)) { session in
                                NavigationLink(destination: HistoryDetailView(session: session)) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                            Text(String(format: "%.1f min • Tone: %@", session.duration / 60, session.toneLabel ?? "Neutral"))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                                .listRowBackground(Color.secondary.opacity(0.1))
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete(perform: deleteSessions)
                        }
                        .listStyle(.plain)
                        .frame(height: 350) // Give it a fixed height in the VStack
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}
