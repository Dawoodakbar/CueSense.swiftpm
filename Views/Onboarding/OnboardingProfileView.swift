import SwiftUI

struct OnboardingProfileView: View {
    @Binding var favoriteTopics: String
    @Binding var improvementAreas: [String]
    @Binding var comfortFactors: [String]
    @Binding var conversationalFeeling: String
    @Binding var afterConversationFeeling: [String]
    
    let onContinue: () -> Void
    
    let improvementOptions = ["Waiting my turn", "Speaking at the right volume", "Not talking for too long", "Understanding when others want to speak", "I’m not sure yet"]
    let comfortOptions = ["Talking about my favorite topics", "Clear back-and-forth", "Quiet environments", "One-on-one conversations"]
    let initialFeelingOptions = ["Relaxed", "Excited", "Nervous", "Unsure what to say"]
    let postFeelingOptions = ["Happy with how it went", "Not sure how it went", "I think I talked too much", "I wish I said more", "Tired or overwhelmed"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 40)
                
                VStack(spacing: 8) {
                    Text("Help Us Know You")
                        .font(.largeTitle.bold())
                    Text("This helps us provide better analysis")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 32) {
                    // Q1: favoriteTopics
                    OnboardingQuestionSection(title: "What do you love talking about?") {
                        TextField("Space traveling, trains, history...", text: $favoriteTopics, axis: .vertical)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Q2: improvementAreas
                    OnboardingSelectionSection(
                        title: "What would you like to improve in conversations?",
                        options: improvementOptions,
                        selections: $improvementAreas,
                        allowMultiple: true
                    )
                    
                    // Q3: comfortFactors
                    OnboardingSelectionSection(
                        title: "What makes a conversation feel comfortable for you?",
                        options: comfortOptions,
                        selections: $comfortFactors,
                        allowMultiple: true
                    )
                    
                    // Q4: conversationalFeeling
                    OnboardingSelectionSection(
                        title: "How do you feel during most conversations?",
                        options: initialFeelingOptions,
                        selections: Binding(
                            get: { [conversationalFeeling].filter { !$0.isEmpty } },
                            set: { conversationalFeeling = $0.first ?? "" }
                        ),
                        allowMultiple: false
                    )
                    
                    // Q5: afterConversationFeeling
                    OnboardingSelectionSection(
                        title: "After a conversation, how do you usually feel?",
                        options: postFeelingOptions,
                        selections: $afterConversationFeeling,
                        allowMultiple: true
                    )
                }
                .padding(.horizontal, 24)
                
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            .padding(.bottom, 300) // Extra padding for keyboard
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct OnboardingQuestionSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            content
        }
    }
}

struct OnboardingSelectionSection: View {
    let title: String
    let options: [String]
    @Binding var selections: [String]
    let allowMultiple: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = selections.contains(option)
                    Button(action: {
                        toggleSelection(option)
                    }) {
                        Text(option)
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .foregroundColor(isSelected ? .blue : .primary)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func toggleSelection(_ option: String) {
        if isSelected(option) {
            selections.removeAll { $0 == option }
        } else {
            if !allowMultiple {
                selections = [option]
            } else {
                selections.append(option)
            }
        }
    }
    
    private func isSelected(_ option: String) -> Bool {
        selections.contains(option)
    }
}


