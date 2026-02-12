import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class UserProfile {
    var id: UUID
    var favoriteTopics: String
    var improvementAreas: [String]
    var comfortFactors: [String]
    var conversationalFeeling: String
    var afterConversationFeeling: String
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    
    init(
        favoriteTopics: String = "",
        improvementAreas: [String] = [],
        comfortFactors: [String] = [],
        conversationalFeeling: String = "",
        afterConversationFeeling: String = "",
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = UUID()
        self.favoriteTopics = favoriteTopics
        self.improvementAreas = improvementAreas
        self.comfortFactors = comfortFactors
        self.conversationalFeeling = conversationalFeeling
        self.afterConversationFeeling = afterConversationFeeling
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = Date()
    }
}
