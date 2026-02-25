import SwiftUI

struct WaveformVisualizerView: View {
    var samples: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<min(samples.count, 50), id: \.self) { index in
                    Capsule()
                        .fill(Theme.primary.opacity(0.8))
                        .frame(
                            width: 5,
                            height: dotSize(for: samples[index], height: geometry.size.height)
                        )
                        .animation(.easeInOut(duration: 0.15), value: samples[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private func dotSize(for sample: Float, height: CGFloat) -> CGFloat {
        let base: CGFloat = 8
        let maxSize: CGFloat = min(height * 0.9, 45)
        let level = max(0.01, CGFloat(sample) * 1.5)
        return min(maxSize, base + level * (maxSize - base))
    }
}
