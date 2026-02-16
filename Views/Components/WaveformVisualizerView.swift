import SwiftUI

struct WaveformVisualizerView: View {
    var samples: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<min(samples.count, 50), id: \.self) { index in
                    Circle()
                        .fill(Color(.systemGray3))
                        .frame(
                            width: dotSize(for: samples[index], height: geometry.size.height),
                            height: dotSize(for: samples[index], height: geometry.size.height)
                        )
                        .animation(.easeInOut(duration: 0.15), value: samples[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private func dotSize(for sample: Float, height: CGFloat) -> CGFloat {
        let base: CGFloat = 6
        let maxSize: CGFloat = min(height * 0.6, 18)
        let level = max(0.05, CGFloat(sample) * 1.5)
        return min(maxSize, base + level * (maxSize - base))
    }
}
