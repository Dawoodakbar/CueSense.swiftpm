import Foundation
import NaturalLanguage
import CoreML

/// CoreMLManager handles advanced, on-device NLP tasks using Apple's frameworks.
/// Enhanced with multi-factor analysis, comprehensive social cue detection, and context-aware processing.
@available(iOS 17.0, *)
@MainActor
class CoreMLManager {
    static let shared = CoreMLManager()
    
    private var embedding: NLContextualEmbedding?
    private var isEmbeddingLoaded = false
    
    // Advanced NLP taggers for linguistic analysis
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma, .nameType])
    
    init() {
        Task {
            embedding = NLContextualEmbedding(language: .english)
            if let embedding = embedding {
                do {
                    try embedding.load()
                    isEmbeddingLoaded = true
                    print("CoreML: Contextual embedding loaded successfully.")
                } catch {
                    print("CoreML: Error loading embedding: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Intent Classification
    
    /// Multi-factor intent analysis: Questions, Requests, Emotions, Stories, Problem-solving
    func analyzeIntent(transcript: String) -> String {
        guard !transcript.isEmpty else { return "None" }
        
        let lower = transcript.lowercased()
        tagger.string = transcript
        
        // 1. Question Detection
        let questionScore = detectQuestion(lower)
        
        // 2. Request Detection
        let requestScore = detectRequest(lower)
        
        // 3. Emotional Expression
        let emotionalScore = detectEmotionalExpression(lower)
        
        // 4. Storytelling
        let narrativeScore = detectNarrative(lower)
        
        // 5. Problem-Solving
        let problemScore = detectProblemSolving(lower)
        
        // Choose highest scoring intent
        let scores = [
            ("Asking Question", questionScore),
            ("Seeking Guidance", requestScore),
            ("Sharing Feelings", emotionalScore),
            ("Telling Story", narrativeScore),
            ("Problem Solving", problemScore)
        ]
        
        let topIntent = scores.max { $0.1 < $1.1 }
        return (topIntent?.1 ?? 0) > 0.3 ? (topIntent?.0 ?? "Expressing") : "Expressing"
    }
    
    private func detectQuestion(_ text: String) -> Double {
        var score = 0.0
        
        // Question marks
        if text.contains("?") { score += 0.5 }
        
        // Question words (who, what, where, when, why, how)
        let questionWords = ["who", "what", "where", "when", "why", "how", "which"]
        for word in questionWords {
            if text.contains("\\b\(word)\\b") { score += 0.3 }
        }
        
        // Auxiliary verb inversion patterns (do/does/did/can/could/would/should at start)
        let auxiliaries = ["do you", "does it", "did we", "can i", "could you", "would it", "should we", "are you", "is it", "was that"]
        for aux in auxiliaries {
            if text.hasPrefix(aux) || text.contains(" \(aux)") { score += 0.4 }
        }
        
        return min(score, 1.0)
    }
    
    private func detectRequest(_ text: String) -> Double {
        var score = 0.0
        
        // Polite request words
        let requestWords = ["please", "could you", "would you", "can you", "may i", "might you"]
        for word in requestWords {
            if text.contains(word) { score += 0.4 }
        }
        
        // Modal verbs + action verbs
        let modals = ["could", "would", "should", "can", "may", "might"]
        let actions = ["help", "show", "tell", "give", "send", "share", "explain"]
        
        for modal in modals {
            for action in actions {
                if text.contains("\(modal)") && text.contains("\(action)") { score += 0.3 }
            }
        }
        
        return min(score, 1.0)
    }
    
    private func detectEmotionalExpression(_ text: String) -> Double {
        var score = 0.0
        
        // Feeling verbs
        let feelingVerbs = ["feel", "felt", "feeling", "sense", "sensed", "think", "believe"]
        for verb in feelingVerbs {
            if text.contains(verb) { score += 0.3 }
        }
        
        // Emotional vocabulary
        let emotions = ["happy", "sad", "angry", "frustrated", "excited", "worried", "anxious", "upset", "glad", "disappointed", "nervous", "confident"]
        for emotion in emotions {
            if text.contains(emotion) { score += 0.4 }
        }
        
        // Personal pronouns (I, me, my)
        if text.contains(" i ") || text.hasPrefix("i ") { score += 0.2 }
        if text.contains(" me ") || text.contains(" my ") { score += 0.2 }
        
        return min(score, 1.0)
    }
    
    private func detectNarrative(_ text: String) -> Double {
        var score = 0.0
        
        // Past tense indicators
        let pastIndicators = ["yesterday", "last week", "last night", "ago", "earlier", "before", "previously"]
        for indicator in pastIndicators {
            if text.contains(indicator) { score += 0.3 }
        }
        
        // Temporal connectors
        let connectors = ["then", "after that", "next", "later", "finally", "eventually", "suddenly"]
        for connector in connectors {
            if text.contains(connector) { score += 0.25 }
        }
        
        // Length factor (stories tend to be longer)
        if text.count > 100 { score += 0.2 }
        if text.count > 200 { score += 0.2 }
        
        return min(score, 1.0)
    }
    
    private func detectProblemSolving(_ text: String) -> Double {
        var score = 0.0
        
        // Conditional phrases
        if text.contains("if ") { score += 0.3 }
        if text.contains("then ") { score += 0.2 }
        
        // Problem words
        let problemWords = ["issue", "problem", "challenge", "difficult", "hard", "struggle", "trouble", "concern"]
        for word in problemWords {
            if text.contains(word) { score += 0.3 }
        }
        
        // Solution words
        let solutionWords = ["solve", "fix", "figure out", "work out", "resolve", "handle", "deal with", "manage"]
        for word in solutionWords {
            if text.contains(word) { score += 0.3 }
        }
        
        return min(score, 1.0)
    }
    
    // MARK: - Social Cues Detection
    
    /// Comprehensive social cue detection across emotional, conversational, and social dimensions
    func getSocialCues(transcript: String) -> [String] {
        var cues: [String] = []
        let lower = transcript.lowercased()
        
        // EMOTIONAL CUES
        if lower.contains("sorry") || lower.contains("apologize") || lower.contains("my bad") {
            cues.append("Apologetic")
        }
        
        if lower.contains("thank") || lower.contains("appreciate") || lower.contains("grateful") {
            cues.append("Grateful")
        }
        
        if lower.contains("argh") || lower.contains("ugh") || lower.contains("frustrated") || lower.contains("annoying") {
            cues.append("Frustrated")
        }
        
        if lower.contains("excited") || lower.contains("amazing") || lower.contains("awesome") || lower.contains("can't wait") {
            cues.append("Excited")
        }
        
        if lower.contains("worried") || lower.contains("concern") || lower.contains("anxious") || lower.contains("nervous") {
            cues.append("Worried")
        }
        
        // CONVERSATIONAL CUES
        if transcript.contains("?") {
            cues.append("Inquisitive")
        }
        
        if lower.contains("wait") || lower.contains("listen") || lower.contains("hold on") || lower.contains("stop") {
            cues.append("Assertive")
        }
        
        if lower.contains("yes") || lower.contains("agree") || lower.contains("exactly") || lower.contains("right") || lower.contains("totally") {
            cues.append("Agreeable")
        }
        
        if lower.contains("no") || lower.contains("disagree") || lower.contains("actually") || lower.contains("but ") {
            cues.append("Disagreeing")
        }
        
        if lower.contains("maybe") || lower.contains("perhaps") || lower.contains("not sure") || lower.contains("i think") || lower.contains("probably") {
            cues.append("Hesitant")
        }
        
        if lower.contains("um") || lower.contains("uh") || lower.contains("well") || lower.contains("like") {
            cues.append("Uncertain")
        }
        
        // SOCIAL CUES
        if lower.contains("great job") || lower.contains("well done") || lower.contains("impressive") || lower.contains("proud of") {
            cues.append("Complimenting")
        }
        
        if lower.contains("understand") || lower.contains("i see") || lower.contains("that must") || lower.contains("i get it") {
            cues.append("Empathetic")
        }
        
        if lower.contains("you should") || lower.contains("you need to") || lower.contains("you must") || lower.contains("listen to me") {
            cues.append("Dominating")
        }
        
        if lower.contains("i'm here") || lower.contains("support you") || lower.contains("help you") || lower.contains("got your back") {
            cues.append("Supporting")
        }
        
        return cues
    }
    
    // MARK: - Emotion Detection
    
    /// Detect dominant emotion in text
    func detectEmotion(transcript: String) -> String? {
        let lower = transcript.lowercased()
        
        let emotionPatterns: [(String, [String])] = [
            ("Joy", ["happy", "joy", "delighted", "pleased", "glad", "cheerful", "excited", "thrilled"]),
            ("Sadness", ["sad", "unhappy", "depressed", "down", "blue", "miserable", "gloomy"]),
            ("Anger", ["angry", "mad", "furious", "annoyed", "irritated", "outraged", "livid"]),
            ("Fear", ["afraid", "scared", "fearful", "terrified", "anxious", "worried", "nervous"]),
            ("Surprise", ["surprised", "shocked", "amazed", "astonished", "startled", "unexpected"]),
            ("Disgust", ["disgusted", "revolted", "sick", "nauseated", "repulsed"])
        ]
        
        for (emotion, keywords) in emotionPatterns {
            for keyword in keywords {
                if lower.contains(keyword) {
                    return emotion
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Speech Pattern Analysis
    
    /// Analyze linguistic patterns using NLTagger
    func analyzeSpeechPatterns(transcript: String) -> [String: Any] {
        var analysis: [String: Any] = [:]
        tagger.string = transcript
        
        var verbCount = 0
        var nounCount = 0
        var adjectiveCount = 0
        var pronounCount = 0
        
        tagger.enumerateTags(in: transcript.startIndex..<transcript.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag {
                switch tag.rawValue {
                case "Verb": verbCount += 1
                case "Noun": nounCount += 1
                case "Adjective": adjectiveCount += 1
                case "Pronoun": pronounCount += 1
                default: break
                }
            }
            return true
        }
        
        analysis["verbCount"] = verbCount
        analysis["nounCount"] = nounCount
        analysis["adjectiveCount"] = adjectiveCount
        analysis["pronounCount"] = pronounCount
        analysis["isDescriptive"] = adjectiveCount > 3
        analysis["isPersonal"] = pronounCount > 2
        
        return analysis
    }
}
