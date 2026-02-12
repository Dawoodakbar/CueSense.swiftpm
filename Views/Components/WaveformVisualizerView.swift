import SwiftUI

struct WaveformVisualizerView: View {
    var samples: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<min(samples.count, 50), id: \.self) { index in
                    Capsule()
                        .fill(.red)
                        .frame(width: 3, height: normalize(sound: samples[index], height: geometry.size.height))
                        .animation(.easeInOut(duration: 0.1), value: samples[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private func normalize(sound: Float, height: CGFloat) -> CGFloat {
        let level = max(0.05, CGFloat(sound) * 1.5) // Amplify
        return min(height, level * height)
    }
}
