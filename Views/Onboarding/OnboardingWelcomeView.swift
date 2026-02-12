import SwiftUI

struct OnboardingWelcomeView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Illustration
            Image("aspergers_welcome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 400)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Description
            ScrollView {
                VStack(spacing: 20) {
                    Text("Asperger’s Syndrome")
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Asperger’s syndrome is a condition that affects how people talk, interact with others, and understand the world around them. People with Asperger’s usually have above-average intelligence and strong language skills, but they may have trouble understanding social cues, body language, or other people’s feelings. Many also have strong interests in certain topics which can lead to unhealthy obsessions.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 32)
            }
            .frame(maxHeight: 300)
            
            Spacer()
            
            // Next Button
            Button(action: onNext) {
                Text("Next")
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
            .padding(.bottom, 60)
        }
        .background(Color(.systemBackground))
    }
}
