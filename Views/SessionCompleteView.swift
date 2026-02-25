import SwiftUI

/// Celebration overlay shown briefly after a session completes successfully.
@available(iOS 17, *)
struct SessionCompleteView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Frosted background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Confetti layer
            ForEach(confettiPieces) { piece in
                ConfettiParticle(piece: piece)
            }

            // Card
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.primary.opacity(0.2), Theme.secondary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.primary, Theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .opacity(showContent ? 1.0 : 0.0)
                }

                VStack(spacing: 8) {
                    Text("Great Job! 🎉")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Session complete. Keep up the great work — every conversation is a step forward.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 12)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 8)
            )
            .padding(.horizontal, 30)
            .scaleEffect(showContent ? 1.0 : 0.85)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                showContent = true
            }
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, Theme.primary, Theme.secondary]
        confettiPieces = (0..<70).map { i in
            ConfettiPiece(
                id: i,
                color: colors.randomElement() ?? .blue,
                xStart: CGFloat.random(in: 0...1),
                delay: Double.random(in: 0...0.6),
                speed: Double.random(in: 1.2...2.4),
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 6...14)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let xStart: CGFloat
    let delay: Double
    let speed: Double
    let rotation: Double
    let size: CGFloat
}

struct ConfettiParticle: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = -40
    @State private var opacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(piece.color.opacity(0.85))
                .frame(width: piece.size, height: piece.size * 0.5)
                .rotationEffect(.degrees(piece.rotation))
                .position(
                    x: geo.size.width * piece.xStart,
                    y: yOffset
                )
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(
                .easeIn(duration: piece.speed)
                .delay(piece.delay)
            ) {
                yOffset = UIScreen.main.bounds.height + 60
                opacity = 1
            }
        }
    }
}
