import SwiftUI

struct WaveformVisualizerView: View {
    var samples: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            let barWidth: CGFloat = 5
            let spacing: CGFloat = 4
            let availableWidth = geometry.size.width
            // Calculate how many bars can fit without overflowing
            let maxBars = Int(floor(availableWidth / (barWidth + spacing)))
            
            HStack(spacing: spacing) {
                ForEach(0..<min(samples.count, maxBars), id: \.self) { index in
                    Capsule()
                        .fill(Theme.primary.opacity(0.8))
                        .frame(
                            width: barWidth,
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
