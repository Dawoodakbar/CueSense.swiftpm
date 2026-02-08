import SwiftData
import SwiftUI

@available(iOS 17.0, *)
@main
struct MyApp: App {
    @StateObject private var speechManager = SpeechManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(speechManager)
                .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
                    OnboardingContainerView()
                }
        }
        .modelContainer(for: [InteractionSession.self, UserProfile.self])
    }
}
