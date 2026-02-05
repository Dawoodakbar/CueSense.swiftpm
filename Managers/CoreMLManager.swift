import Foundation
import NaturalLanguage
import CoreML

/// CoreMLManager handles advanced, on-device NLP tasks using pre-trained models.
@available(iOS 17.0, *)
@MainActor
class CoreMLManager {
    static let shared = CoreMLManager()
    
    // We use NLContextualEmbedding for "LLM-like" semantic understanding.
    // This provides a high-dimensional vector representation of the text.
    private var embedding: NLContextualEmbedding?
    private var isEmbeddingLoaded = false
    
    init() {
        // Asynchronously load the embedding to avoid blocking the main thread
        Task {
            embedding = NLContextualEmbedding(language: .english)
            if let embedding = embedding {
                do {
                    // Check if the embedding is available on device, otherwise it might need to be downloaded via system
                    try embedding.load()
                    isEmbeddingLoaded = true
                    print("CoreML: Contextual embedding loaded successfully.")
                } catch {
                    print("CoreML: Error loading embedding: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Analyzes the transcript and returns a "Semantic Intent Score".
    /// This helps determine if the user is asking a question, making a request, or sharing a feeling.
    func analyzeIntent(transcript: String) -> String {
        guard !transcript.isEmpty else { return "None" }
        
        // Example check: detecting a "Request" vs "Expression"
        let tokens = transcript.lowercased().split(separator: " ")
        let requestKeywords = ["can", "could", "should", "would", "how", "why", "what", "please"]
        
        // Simple heuristic for now, but in a real app, you would compare embedding vectors 
        // to pre-defined centroids (e.g., Question Centroid, Emergency Centroid).
        
        let hasRequest = tokens.contains { requestKeywords.contains(String($0)) }
        
        if hasRequest {
            return "Seeking Guidance"
        } else if transcript.count > 50 {
            return "Deep Sharing"
        }
        
        return "Expressing"
    }
    
    /// Provides AI-driven "Social Cues" based on the transcript.
    func getSocialCues(transcript: String) -> [String] {
        var cues: [String] = []
        
        if transcript.contains("?") {
            cues.append("Inquisitive")
        }
        
        if transcript.lowercased().contains("sorry") || transcript.lowercased().contains("apologize") {
            cues.append("Reconciliatory")
        }
        
        if transcript.lowercased().contains("wait") || transcript.lowercased().contains("listen") {
            cues.append("Assertive")
        }
        
        return cues
    }
}
