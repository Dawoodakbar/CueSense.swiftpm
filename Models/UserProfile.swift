import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class UserProfile {
    var id: UUID
    var interests: String
    var conversationTopics: String
    var improvementGoals: String
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    
    init(
        interests: String = "",
        conversationTopics: String = "",
        improvementGoals: String = "",
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = UUID()
        self.interests = interests
        self.conversationTopics = conversationTopics
        self.improvementGoals = improvementGoals
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = Date()
    }
}
