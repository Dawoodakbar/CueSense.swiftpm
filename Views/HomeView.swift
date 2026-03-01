import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct HomeView: View {
    @EnvironmentObject var speechManager: SpeechManager
    @State private var showingInfo = false
    @State private var isLoading = false
    let startSession: () -> Void
    
    var body: some View {
        ZStack {
            // Background image from assets
            if let bgImage = UIImage(named: "background") {
                Image(uiImage: bgImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                LinearGradient(colors: [.white, .blue.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Branding
                VStack(spacing: 8) {
                    Text("CueSense")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("Your conversation companion")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                    .frame(height: 10)
                
                // Ready to Listen Card
                VStack(spacing: 16) {
                    // Waveform icon in purple circle
                    ZStack {
                        Circle()
                            .fill(Theme.primary.opacity(0.15))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "waveform")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                    }
                    
                    Text("Ready to Listen")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Tap the button below to start a conversation session. I'll provide gentle cues when needed.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white.opacity(0.65))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Info Icon Button
                Button(action: { showingInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.title2)
                        .foregroundColor(Theme.primary)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Theme.primary.opacity(0.1))
                        )
                }
                .padding(.bottom, -15) // Move it closer to the start button
                
                // Start Session Button
                Button(action: {
                    withAnimation {
                        isLoading = true
                    }
                    
                    // Simulate loading delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        speechManager.startRecording()
                        startSession()
                        // Reset loading state after transition
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                        Text("Start Session")
                            .font(.title3.bold())
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.buttonGradient)
                    .clipShape(Capsule())
                    .shadow(color: Theme.primary.opacity(0.35), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 100)
                .onAppear {
                    speechManager.checkPermissions()
                }
                
                Spacer()
                    .frame(height: 50)
            }
            
            if isLoading {
                LoadingView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .sheet(isPresented: $showingInfo) {
            OnboardingWelcomeView(showNextButton: false) {
                showingInfo = false
            }
        }
    }
}
