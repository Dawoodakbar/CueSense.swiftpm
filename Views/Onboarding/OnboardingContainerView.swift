import SwiftUI
import SwiftData

@available(iOS 17, *)
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentPage = 0
    @State private var interests = ""
    @State private var conversationTopics = ""
    @State private var improvementGoals = ""
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingWelcomeView {
                withAnimation {
                    currentPage = 1
                }
            }
            .tag(0)
            
            OnboardingProfileView(
                interests: $interests,
                conversationTopics: $conversationTopics,
                improvementGoals: $improvementGoals
            ) {
                saveProfileAndComplete()
            }
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
    
    private func saveProfileAndComplete() {
        // Create and save user profile
        let profile = UserProfile(
            interests: interests,
            conversationTopics: conversationTopics,
            improvementGoals: improvementGoals,
            hasCompletedOnboarding: true
        )
        
        modelContext.insert(profile)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save profile: \(error)")
        }
        
        // Mark onboarding as completed
        hasCompletedOnboarding = true
        
        // Dismiss onboarding
        dismiss()
    }
}
