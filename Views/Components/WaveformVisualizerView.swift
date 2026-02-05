import SwiftUI

struct WaveformVisualizerView: View {
    let samples: [Float]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<samples.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: samples[index]))
                    .frame(width: 4, height: max(6, CGFloat(samples[index]) * 150)) // Min height 6
                    .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.5, blendDuration: 0.1), value: samples[index])
            }
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func barColor(for level: Float) -> Color {
        if level > 0.8 {
            return .red
        } else if level > 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
}

struct WaveformVisualizerView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            WaveformVisualizerView(samples: (0..<50).map { _ in Float.random(in: 0.1...0.9) })
        }
    }
}
