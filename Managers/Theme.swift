import SwiftUI

enum Theme {
    static let primary = Color.blue
    static let primaryGradient = LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    // Liquid Glass Background
    static func glassBackground() -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(0.8)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
