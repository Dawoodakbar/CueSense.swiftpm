import Foundation
import NaturalLanguage

struct AnalysisResult {
    let sentimentScore: Double
    let pacing: Double // Words per minute
    let tone: String
    let toneConfidence: Double // 0.0 - 1.0
    let guidance: String?
    let measure: String?
    let socialCues: [String]
    let aiInsight: String?
    let emotion: String? // Detected emotion
    let speechMetrics: SpeechMetrics
    
    // New Fields
    let topic: String?
    let analysisTitle: String?
    let improvementTips: [String]
    let conversationStarters: [String]
}

struct SpeechMetrics {
    let wordCount: Int
    let averageWordLength: Double
    let sentenceCount: Int
    let pauseCount: Int // Detected pauses
    let fillerWordCount: Int // um, uh, like
}

@available(iOS 17.0, *)
@MainActor
class AnalysisManager {
  private let tagger = NLTagger(tagSchemes: [.sentimentScore, .lexicalClass])

  // Topic keywords for simple detection
  private let topicKeywords: [String: [String]] = [
    "Space": ["space", "stars", "aliens", "planets", "nasa", "galaxy", "telescope", "astronaut", "universe", "mars", "moon", "orbit", "solar system"],
    "Technology": ["computer", "software", "ai", "coding", "interface", "robot", "tech", "digital", "internet", "app", "phone", "smartphone", "screen", "device", "algorithm", "data"],
    "Health": ["doctor", "medicine", "health", "exercise", "nutrition", "fitness", "wellness", "sickness", "gym", "workout", "diet", "hospital", "mental health", "therapy"],
    "Nature": ["trees", "environment", "ocean", "wildlife", "climate", "mountain", "forest", "river", "lake", "sky", "sun", "rain", "flower", "garden", "hiking"],
    "Travel": ["vacation", "flight", "hotel", "destination", "adventure", "journey", "trip", "passport", "airport", "tourism", "explore", "sightseeing", "beach"],
    "Games": ["gaming", "videogame", "console", "player", "score", "level", "competitive", "strategy", "minecraft", "fortnite", "roblox", "playstation", "xbox", "nintendo", "steam"],
    "History": ["ancient", "history", "century", "empire", "war", "republic", "historical", "ancestors", "king", "queen", "past", "era", "museum", "civilization"],
    "Pets": ["cat", "dog", "pet", "kitten", "puppy", "animal", "fur", "tail", "meow", "bark", "feed", "walk", "vet", "veterinarian", "adopt", "rescue", "feline", "canine", "hamster", "bird", "fish"],
    "Food": ["food", "eat", "restaurant", "cook", "recipe", "dinner", "lunch", "breakfast", "snack", "hungry", "delicious", "tasty", "meal", "kitchen", "chef", "bake"],
    "Movies": ["movie", "film", "cinema", "actor", "actress", "director", "hollywood", "scene", "plot", "character", "watch", "show", "series", "tv", "netflix", "drama", "comedy"],
    "Music": ["music", "song", "band", "singer", "concert", "album", "listen", "guitar", "piano", "drum", "melody", "rhythm", "lyrics", "spotify", "playlist"],
    "Sports": ["sport", "game", "team", "match", "ball", "score", "win", "lose", "player", "coach", "football", "soccer", "basketball", "baseball", "tennis", "athlete"],
    "School": ["school", "class", "teacher", "student", "homework", "exam", "test", "grade", "study", "learn", "college", "university", "campus", "subject", "math", "science"],
    "Family": ["family", "mom", "dad", "mother", "father", "sister", "brother", "sibling", "grandma", "grandpa", "cousin", "aunt", "uncle", "parent", "child", "kids"],
    "Work": ["work", "job", "office", "career", "boss", "colleague", "meeting", "project", "deadline", "salary", "interview", "resume", "business"],
    "Hobbies": ["hobby", "craft", "art", "drawing", "painting", "reading", "book", "writing", "photography", "collecting", "knitting", "sewing"]
  ]

  // Enhanced thresholds
  private let veryFastPacingThreshold = 180.0 // wpm
  private let fastPacingThreshold = 150.0 // wpm
  private let slowPacingThreshold = 90.0 // wpm
  private let verySlowPacingThreshold = 60.0 // wpm

  private let strongNegativeSentiment = -0.5
  private let negativeSentiment = -0.3
  private let positiveSentiment = 0.3
  private let strongPositiveSentiment = 0.5

  func analyze(transcript: String, duration: TimeInterval, userProfile: UserProfile? = nil) -> AnalysisResult {
    // 1. Multi-Factor Sentiment Analysis
    let baseSentiment = calculateBaseSentiment(transcript)
    let emotionalScore = calculateEmotionalScore(transcript)
    let negationAdjustment = detectNegations(transcript)
    let intensifierMultiplier = detectIntensifiers(transcript)

    // Combine sentiment factors
    var finalSentiment = (baseSentiment + emotionalScore) / 2.0
    finalSentiment += negationAdjustment
    finalSentiment *= intensifierMultiplier
    finalSentiment = max(-1.0, min(1.0, finalSentiment)) // Clamp to [-1, 1]

    // 2. CoreML Advanced Analysis
    let socialCues = CoreMLManager.shared.getSocialCues(transcript: transcript)
    let aiInsight = CoreMLManager.shared.analyzeIntent(transcript: transcript)
    let emotion = CoreMLManager.shared.detectEmotion(transcript: transcript)

    // 3. Speech Metrics
    let metrics = calculateSpeechMetrics(transcript: transcript, duration: duration)

    // 4. Pacing Analysis
    let wpm = metrics.wordCount > 0 && duration > 0 ? Double(metrics.wordCount) / (duration / 60.0) : 0.0

    // 5. Advanced Tone Classification
    let (tone, confidence) = classifyTone(
      sentiment: finalSentiment,
      wpm: wpm,
      socialCues: socialCues,
      emotion: emotion,
      metrics: metrics
    )

    // 6. Contextual Guidance
    let (guidance, measure) = generateGuidance(
      tone: tone,
      sentiment: finalSentiment,
      wpm: wpm,
      metrics: metrics,
      socialCues: socialCues,
      userProfile: userProfile
    )

    // 7. Topic & Title Detection
    let detectedTopic = detectTopic(transcript)
    let keywords = extractKeywords(transcript)
    let analysisTitle = generateTitle(topic: detectedTopic, emotion: emotion, tone: tone, keywords: keywords)

    // 8. Personalized Tips & Starters
    let improvementTips = generateImprovementTips(metrics: metrics, tone: tone, socialCues: socialCues, userProfile: userProfile)
    let starters = generateConversationStarters(topic: detectedTopic, socialCues: socialCues, keywords: keywords)

    return AnalysisResult(
      sentimentScore: finalSentiment,
      pacing: wpm,
      tone: tone,
      toneConfidence: confidence,
      guidance: guidance,
      measure: measure,
      socialCues: socialCues,
      aiInsight: aiInsight,
      emotion: emotion,
      speechMetrics: metrics,
      topic: detectedTopic,
      analysisTitle: analysisTitle,
      improvementTips: improvementTips,
      conversationStarters: starters
    )
  }

  // MARK: - Sentiment Analysis

  private func calculateBaseSentiment(_ text: String) -> Double {
    tagger.string = text
    let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
    return Double(sentiment?.rawValue ?? "0") ?? 0.0
  }

  private func calculateEmotionalScore(_ text: String) -> Double {
    let lower = text.lowercased()
    var score = 0.0

    // Positive emotions
    let positiveWords = ["happy", "joy", "great", "excellent", "wonderful", "amazing", "love", "excited", "glad", "pleased", "delighted", "fantastic", "awesome"]
    for word in positiveWords {
      if lower.contains(word) { score += 0.15 }
    }

    // Negative emotions
    let negativeWords = ["sad", "angry", "frustrated", "upset", "annoyed", "terrible", "awful", "horrible", "hate", "worst", "bad", "disappointed"]
    for word in negativeWords {
      if lower.contains(word) { score -= 0.15 }
    }

    return max(-1.0, min(1.0, score))
  }

  private func detectNegations(_ text: String) -> Double {
    let lower = text.lowercased()
    var adjustment = 0.0

    // Negation words that flip sentiment
    let negations = ["not", "no", "never", "don't", "doesn't", "didn't", "won't", "can't", "shouldn't"]
    for negation in negations {
      if lower.contains(negation) {
        adjustment -= 0.1 // Each negation slightly reduces sentiment
      }
    }

    return adjustment
  }

  private func detectIntensifiers(_ text: String) -> Double {
    let lower = text.lowercased()
    var multiplier = 1.0

    // Intensifiers amplify sentiment
    let intensifiers = ["very", "really", "extremely", "absolutely", "totally", "completely", "so", "quite"]
    for intensifier in intensifiers {
      if lower.contains(intensifier) {
        multiplier += 0.1
      }
    }

    return min(multiplier, 1.5) // Cap at 1.5x
  }

  // MARK: - Speech Metrics

  private func calculateSpeechMetrics(transcript: String, duration: TimeInterval) -> SpeechMetrics {
    let words = transcript.split(separator: " ").map(String.init)
    let wordCount = words.count

    // Average word length
    let totalChars = words.reduce(0) { $0 + $1.count }
    let avgWordLength = wordCount > 0 ? Double(totalChars) / Double(wordCount) : 0.0

    // Sentence count (approximate by punctuation)
    let sentences = transcript.components(separatedBy: CharacterSet(charactersIn: ".!?"))
    let sentenceCount = sentences.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count

    // Detect pauses (look for "..." or multiple spaces)
    let pauseCount = transcript.components(separatedBy: "...").count - 1

    // Filler words
    let lower = transcript.lowercased()
    let fillers = ["um", "uh", "like", "you know", "i mean", "sort of", "kind of"]
    var fillerCount = 0
    for filler in fillers {
      let count = lower.components(separatedBy: filler).count - 1
      fillerCount += count
    }

    return SpeechMetrics(
      wordCount: wordCount,
      averageWordLength: avgWordLength,
      sentenceCount: max(sentenceCount, 1),
      pauseCount: pauseCount,
      fillerWordCount: fillerCount
    )
  }

  // MARK: - Tone Classification

  private func classifyTone(sentiment: Double, wpm: Double, socialCues: [String], emotion: String?, metrics: SpeechMetrics) -> (String, Double) {
    var scores: [String: Double] = [:]

    // 1. Tense/Heated
    var tenseScore = 0.0
    if sentiment < strongNegativeSentiment { tenseScore += 0.5 }
    if wpm > veryFastPacingThreshold { tenseScore += 0.3 }
    if socialCues.contains("Disagreeing") { tenseScore += 0.2 }
    if emotion == "Anger" { tenseScore += 0.4 }
    scores["Tense"] = tenseScore

    // 2. Positive/Enthusiastic
    var positiveScore = 0.0
    if sentiment > strongPositiveSentiment { positiveScore += 0.5 }
    if socialCues.contains("Excited") { positiveScore += 0.3 }
    if emotion == "Joy" { positiveScore += 0.4 }
    if socialCues.contains("Grateful") { positiveScore += 0.2 }
    scores["Positive"] = positiveScore

    // 3. Rushed/Anxious
    var rushedScore = 0.0
    if wpm > fastPacingThreshold { rushedScore += 0.4 }
    if metrics.fillerWordCount > 3 { rushedScore += 0.3 }
    if socialCues.contains("Worried") || socialCues.contains("Uncertain") { rushedScore += 0.3 }
    scores["Rushed"] = rushedScore

    // 4. Calm/Measured
    var calmScore = 0.0
    if wpm >= slowPacingThreshold && wpm <= fastPacingThreshold { calmScore += 0.4 }
    if metrics.pauseCount > 0 { calmScore += 0.2 }
    if sentiment > -0.2 && sentiment < 0.2 { calmScore += 0.3 }
    scores["Calm"] = calmScore

    // 5. Engaged/Balanced
    var engagedScore = 0.0
    if wpm >= 100 && wpm <= 160 { engagedScore += 0.3 }
    if socialCues.contains("Agreeable") || socialCues.contains("Empathetic") { engagedScore += 0.3 }
    if metrics.wordCount > 20 { engagedScore += 0.2 }
    scores["Engaged"] = engagedScore

    // 6. Passive/Withdrawn
    var passiveScore = 0.0
    if wpm < slowPacingThreshold { passiveScore += 0.4 }
    if metrics.wordCount < 10 { passiveScore += 0.4 }
    if socialCues.contains("Hesitant") { passiveScore += 0.2 }
    scores["Passive"] = passiveScore

    // 7. Uncertain/Hesitant
    var uncertainScore = 0.0
    if metrics.fillerWordCount > 5 { uncertainScore += 0.4 }
    if socialCues.contains("Hesitant") || socialCues.contains("Uncertain") { uncertainScore += 0.4 }
    if sentiment > -0.1 && sentiment < 0.1 { uncertainScore += 0.2 }
    scores["Uncertain"] = uncertainScore

    // 8. Authoritative/Confident
    var authoritativeScore = 0.0
    if socialCues.contains("Assertive") || socialCues.contains("Dominating") { authoritativeScore += 0.4 }
    if metrics.fillerWordCount < 2 { authoritativeScore += 0.3 }
    if wpm >= 120 && wpm <= 150 { authoritativeScore += 0.3 }
    scores["Confident"] = authoritativeScore

    // Find tone with highest score
    let topTone = scores.max { $0.value < $1.value }
    let tone = topTone?.key ?? "Neutral"
    let confidence = topTone?.value ?? 0.0

    return (tone, min(confidence, 1.0))
  }

  // MARK: - Guidance Generation

    private func generateGuidance(tone: String, sentiment: Double, wpm: Double, metrics: SpeechMetrics, socialCues: [String], userProfile: UserProfile? = nil) -> (String?, String?) {
        var guidance: String?
        var measure: String?

        switch tone {
        case "Tense":
            guidance = "⚠️ The conversation is getting tense."
            measure = "Take a deep breath and lower your volume. Use phrases like 'I understand' to de-escalate and bring the conversation back to a calm space."

        case "Positive":
            guidance = "✅ Great job — the energy is very positive!"
            measure = "Keep up the enthusiasm, but make sure to give others space to contribute too."

        case "Rushed":
            guidance = "⚠️ You're speaking a bit too quickly."
            measure = "Try slowing down and adding 1–2 second pauses between thoughts — this helps others follow along more easily."

        case "Calm":
            guidance = "✅ Your pace is excellent and well-measured."
            measure = "Maintain this balanced approach. You're creating space for meaningful dialogue."

        case "Engaged":
            guidance = "✅ You're actively engaged in the conversation."
            measure = "Great job! Keep asking questions and showing interest in others' perspectives."

        case "Passive":
            if metrics.wordCount < 5 {
                guidance = "⚠️ You've been very quiet — try speaking up more."
                measure = "Try contributing your thoughts or asking an open-ended question to join the conversation."
            } else {
                guidance = "⚠️ Your pacing may be too relaxed — try adding more energy."
                measure = "Consider speaking with a little more enthusiasm to show engagement and keep the conversation flowing."
            }

        case "Uncertain":
            guidance = "⚠️ You seem a bit uncertain or hesitant."
            measure = "It's okay to take your time. Gather your thoughts before speaking, or say 'Let me think about that.'"

        case "Confident":
            if socialCues.contains("Dominating") {
                guidance = "⚠️ You're speaking confidently, but try letting others contribute."
                measure = "Invite input by asking 'What do you think?' to keep the balance in the conversation."
            } else {
                guidance = "✅ Your confidence is coming through clearly."
                measure = "Excellent! Keep this assertive yet respectful tone."
            }

        default:
            guidance = "✅ Everything seems balanced."
            measure = "Continue being present in the conversation and maintain good eye contact."
        }

        // Incorporate Profile Goals
        if let profile = userProfile {
            if profile.improvementAreas.contains("Waiting my turn") && socialCues.contains("Dominating") {
                guidance = "⚠️ You're speaking a lot — remember your goal to wait your turn."
                measure = "Try counting to three before responding to give others a chance to step in."
            }
            if profile.improvementAreas.contains("Speaking at the right volume") && tone == "Tense" {
                measure = "Focus on keeping your voice gentle and steady, even if the topic feels intense."
            }
            if profile.improvementAreas.contains("Not talking for too long") && metrics.wordCount > 100 && metrics.sentenceCount > 10 {
                guidance = "⚠️ This was a long contribution — try to be more concise."
                measure = "Try summarizing your thoughts in 2–3 sentences to keep the flow balanced."
            }
        }

        return (guidance, measure)
    }
    
    // MARK: - Advanced Analysis Helpers
    
    private func detectTopic(_ text: String) -> String? {
        let lower = text.lowercased()
        var topicScores: [String: Int] = [:]
        
        for (topic, keywords) in topicKeywords {
            for keyword in keywords {
                if lower.contains(keyword) {
                    topicScores[topic, default: 0] += 1
                }
            }
        }
        
        // Return topic with the highest match count
        return topicScores.max { $0.value < $1.value }?.key
    }
    
    private func generateTitle(topic: String?, emotion: String?, tone: String, keywords: [String]) -> String {
        if let firstKeyword = keywords.first {
            return "\(firstKeyword) Discussion"
        } else if let topic = topic {
            return "\(topic) Discussion"
        } else if let emotion = emotion {
            return "\(emotion) Expression"
        } else {
            return "\(tone) Interaction"
        }
    }
    
    private func generateImprovementTips(metrics: SpeechMetrics, tone: String, socialCues: [String], userProfile: UserProfile? = nil) -> [String] {
        var tips: [String] = []
        
        if metrics.fillerWordCount > 5 {
            tips.append("Reduce filler words like 'um' and 'like' for clearer communication.")
        }
        
        if tone == "Rushed" {
            tips.append("Try to slow down your speech; your pacing is faster than usual.")
        }
        
        if socialCues.contains("Dominating") {
            tips.append("Try asking more questions to invite others into the conversation.")
        }
        
        if let profile = userProfile {
            for area in profile.improvementAreas {
                if area == "Waiting my turn" {
                    tips.append("Remember to pause and let others finish their thoughts.")
                } else if area == "Understanding when others want to speak" {
                    tips.append("Watch for small gestures or eye contact from others that signal they want to join in.")
                }
            }
        }
        
        if tips.isEmpty {
            tips.append("Continue maintaining eye contact and responsive body language.")
        }
        
        return tips
    }
    
    private func generateConversationStarters(topic: String?, socialCues: [String], keywords: [String]) -> [String] {
        var starters: [String] = []
        
        // Use detected keywords for specific starters
        if let firstKeyword = keywords.first {
            if keywords.count >= 2 {
                starters.append("You mentioned \(firstKeyword) and \(keywords[1]). How do you see them connecting?")
            }
            starters.append("Could you tell me more about your experience with \(firstKeyword)?")
            
            // Context-aware starters based on keywords
            let lowerKeyword = firstKeyword.lowercased()
            if ["computer", "technology", "ai", "phone"].contains(where: { lowerKeyword.contains($0) }) {
                 starters.append("What's your favorite piece of technology that's come out this year?")
            } else if ["cat", "dog", "pet"].contains(where: { lowerKeyword.contains($0) }) {
                starters.append("Do you have any funny stories about your pet?")
            } else if ["movie", "film", "show"].contains(where: { lowerKeyword.contains($0) }) {
                starters.append("What's the best thing you've watched recently?")
            }
        }
        
        // Topic-based starters
        if let topic = topic {
            switch topic {
            case "Space":
                starters.append("What do you find most fascinating about the universe?")
                starters.append("Do you think human colonization of Mars is feasible soon?")
            case "Technology":
                starters.append("How do you think AI is going to change your daily life?")
                starters.append("What's a new piece of tech you're excited about?")
            case "Pets":
                starters.append("Are you more of a cat person or a dog person?")
                starters.append("What's the most unique pet you've ever met?")
            case "Food":
                starters.append("What's your absolute favorite comfort food?")
                starters.append("Do you enjoy cooking, or do you prefer eating out?")
            case "Movies":
                starters.append("What genre of movies do you enjoy the most?")
                starters.append("Is there a movie you could watch over and over again?")
            case "Music":
                starters.append("Who is your favorite artist or band right now?")
                starters.append("Do you play any instruments, or would you like to learn one?")
            case "Sports":
                starters.append("Do you follow any specific sports teams?")
                starters.append("What's your favorite way to stay active?")
            case "Travel":
                starters.append("If you could go anywhere in the world right now, where would it be?")
                starters.append("What was your most memorable trip?")
            case "School":
                starters.append("What is your favorite subject to study?")
                starters.append("How do you usually prepare for big exams?")
            case "Family":
                starters.append("Do you have any fun family traditions?")
                starters.append("Who in your family has had the biggest influence on you?")
            case "Work":
                starters.append("What's the most rewarding part of your job?")
                starters.append("How do you like to relax after a long work day?")
            case "Hobbies":
                starters.append("How did you get started with your hobby?")
                starters.append("Is there a new hobby you'd like to try soon?")
            default:
                starters.append("What's your favorite part about \(topic.lowercased())?")
                starters.append("How did you first get interested in \(topic.lowercased())?")
            }
        }
        
        // Social Cue adjustments
        if socialCues.contains("Agreeable") && starters.count < 3 {
            starters.append("I'm glad we agree on that! What else is on your mind?")
        } else if socialCues.contains("Disagreeing") && starters.count < 3 {
            starters.append("That's an interesting perspective. Tell me more about why you feel that way.")
        }
        
        // Fallback generic starters
        if starters.count < 2 {
            starters.append("What's something interesting that happened to you recently?")
            starters.append("If you could learn any new skill instantly, what would it be?")
            starters.append("What are you looking forward to this week?")
        }
        
        // Return a shuffled subset to keep it fresh
        return Array(starters.shuffled().prefix(3))
    }
    
    private func extractKeywords(_ text: String) -> [String] {
        var keywords: [String] = []
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        
        // 1. Try to find named entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag, [.personalName, .placeName, .organizationName].contains(tag) {
                let word = String(text[tokenRange])
                if !keywords.contains(word) { keywords.append(word) }
            }
            return true
        }
        
        // 2. If not enough entities, find prominent nouns
        if keywords.count < 2 {
            tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
                if let tag = tag, tag == .noun {
                    let word = String(text[tokenRange])
                    if word.count > 3 && !keywords.contains(word.capitalized) {
                        keywords.append(word.capitalized)
                    }
                }
                return true
            }
        }
        
        return Array(keywords.prefix(3))
    }
}
