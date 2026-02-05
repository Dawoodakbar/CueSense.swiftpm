import Foundation
import NaturalLanguage

struct AnalysisResult {
    let sentimentScore: Double
    let pacing: Double // Words per minute
    let tone: String
    let guidance: String?
    let measure: String?
}

class AnalysisManager {
    private let tagger = NLTagger(tagSchemes: [.sentimentScore])
    
    // Heuristics
    private let fastPacingThreshold = 160.0 // wpm
    private let slowPacingThreshold = 100.0 // wpm (optional check)
    private let negativeSentimentThreshold = -0.4
    
    func analyze(transcript: String, duration: TimeInterval) -> AnalysisResult {
        // 1. Sentiment
        tagger.string = transcript
        let (sentiment, _) = tagger.tag(at: transcript.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = Double(sentiment?.rawValue ?? "0") ?? 0.0
        
        // 2. Pacing (Simple WPM)
        let words = transcript.split(separator: " ")
        let wordCount = Double(words.count)
        let minutes = duration / 60.0
        let wpm = minutes > 0 ? wordCount / minutes : 0.0
        
        // 3. Tone and Guidance
        var tone = "Neutral"
        var guidance: String? = nil
        var measure: String? = nil
        
        if score < negativeSentimentThreshold {
            tone = "Tense"
            guidance = "The tone seems a bit heated."
            measure = "Try to lower your volume and take a slow breath. Use softer words."
        } else if score > 0.4 {
            tone = "Positive"
            guidance = "You're doing great! The conversation is very positive."
            measure = "Keep up the enthusiastic and supportive attitude."
        } else if wpm > fastPacingThreshold {
            tone = "Rushed"
            guidance = "Slow down a bit."
            measure = "Pause for 2 seconds between sentences. This helps others process your words."
        } else if duration > 30 && wordCount < 5 {
            tone = "Quiet"
            guidance = "It's a bit quiet."
            measure = "Maybe share a thought or ask an open-ended question to engage others."
        } else {
            tone = "Engaged"
            guidance = "Everything looks good."
            measure = "Maintain eye contact and stay present in the moment."
        }
        
        return AnalysisResult(
            sentimentScore: score,
            pacing: wpm,
            tone: tone,
            guidance: guidance,
            measure: measure
        )
    }
}
