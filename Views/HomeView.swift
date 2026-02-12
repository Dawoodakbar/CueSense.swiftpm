import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct HomeView: View {
    @EnvironmentObject var speechManager: SpeechManager
    let startSession: () -> Void
    
    var body: some View {
        ZStack {
            // Background Layer
            Color.white.ignoresSafeArea()
            
            // Decorative blobs
            VStack {
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)
                        .offset(x: -50, y: -50)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.cyan.opacity(0.1))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: 50, y: 50)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Branding
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 140, height: 140)
                            .shadow(color: .blue.opacity(0.1), radius: 20)
                        
                        Image(systemName: "ear.and.waveform")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                    
                    Text("CueSense")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.primary)
                    
                    Text("Your private social assistant")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Primary Action using Glassmorphism
                Button(action: {
                    speechManager.startRecording()
                    startSession()
                }) {
                    HStack(spacing: 15) {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                        Text("Start Session")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 10)
                }
                .padding(.horizontal, 40)
                .onAppear {
                    speechManager.checkPermissions()
                }
                
                Spacer()
                    .frame(height: 50)
            }
        }
    }
}
