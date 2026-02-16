import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class InteractionSession {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var overallTone: Double
    var summary: String // Auto-generated brief or just "Interaction at 2 PM"
    var transcript: String?
    var toneLabel: String?
    
    // New Analysis Fields
    var topic: String?
    var analysisTitle: String?
    var improvementTips: [String] = []
    var conversationStarters: [String] = []
    
    init(
        date: Date = Date(),
        duration: TimeInterval = 0,
        overallTone: Double = 0,
        summary: String = "",
        transcript: String? = "",
        toneLabel: String? = "Neutral",
        topic: String? = nil,
        analysisTitle: String? = nil,
        improvementTips: [String] = [],
        conversationStarters: [String] = []
    ) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.overallTone = overallTone
        self.summary = summary
        self.transcript = transcript
        self.toneLabel = toneLabel
        self.topic = topic
        self.analysisTitle = analysisTitle
        self.improvementTips = improvementTips
        self.conversationStarters = conversationStarters
    }
}
