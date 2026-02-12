import SwiftUI
import SwiftData

@available(iOS 17, *)
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentPage = 0
    @State private var favoriteTopics = ""
    @State private var improvementAreas: [String] = []
    @State private var comfortFactors: [String] = []
    @State private var conversationalFeeling = ""
    @State private var afterConversationFeeling: [String] = []
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingWelcomeView {
                withAnimation {
                    currentPage = 1
                }
            }
            .tag(0)
            
            OnboardingProfileView(
                favoriteTopics: $favoriteTopics,
                improvementAreas: $improvementAreas,
                comfortFactors: $comfortFactors,
                conversationalFeeling: $conversationalFeeling,
                afterConversationFeeling: $afterConversationFeeling
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
            favoriteTopics: favoriteTopics,
            improvementAreas: improvementAreas,
            comfortFactors: comfortFactors,
            conversationalFeeling: conversationalFeeling,
            afterConversationFeeling: afterConversationFeeling.joined(separator: ", "),
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
