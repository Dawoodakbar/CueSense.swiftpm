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
            VStack(spacing: 16) {
                Text("Asperger's Syndrome is a form of autism that affects social interactions and communication, while often bringing unique strengths such as focus and passion for specific interests.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
            
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
