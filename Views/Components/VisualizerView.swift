import SwiftUI

struct VisualizerView: View {
    var level: Float // 0.0 to 1.0
    
    @State private var phase: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Background Glow
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 100 + CGFloat(level * 100))
                .blur(radius: 20)
                .animation(.easeOut(duration: 0.2), value: level)
            
            // Core
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 50 + CGFloat(i * 30) + CGFloat(level * 50))
                    .opacity(1.0 - Double(i) * 0.3)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5).delay(Double(i) * 0.05), value: level)
            }
        }
        .drawingGroup()
    }
}
