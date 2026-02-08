import SwiftUI

struct OnboardingProfileView: View {
    @Binding var interests: String
    @Binding var conversationTopics: String
    @Binding var improvementGoals: String
    let onContinue: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                // Illustration
                Image("profile_collection")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 200)
                    .padding(.horizontal, 40)
                
                // Title
                Text("Tell Us About Yourself")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                // Form Fields
                VStack(spacing: 20) {
                    // Interests Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What is your biggest interest?")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("I enjoy...", text: $interests)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    // Conversation Topics Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What do you like to talk about?")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("I like to talk about...", text: $conversationTopics)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    // Improvement Goals Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What do you want to improve?")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        TextField("I want to improve...", text: $improvementGoals)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 30)
                
                // Continue Button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.29, green: 0.56, blue: 0.96), Color(red: 0.29, green: 0.56, blue: 0.96)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
    }
}
