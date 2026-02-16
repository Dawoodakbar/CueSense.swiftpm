import SwiftUI

enum Theme {
    // Primary purple palette
    static let primary = Color(red: 0.55, green: 0.36, blue: 0.87) // Soft purple
    static let secondary = Color(red: 0.68, green: 0.52, blue: 0.95) // Lighter purple
    static let accent = Color(red: 0.75, green: 0.62, blue: 1.0) // Lavender
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let buttonGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.36, blue: 0.87), Color(red: 0.50, green: 0.55, blue: 0.95)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // Background using the asset image
    static func backgroundImage() -> some View {
        Image("background")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
    }
    
    // Fallback gradient background
    static func gradientBackground() -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.85, green: 0.78, blue: 0.95),
                Color(red: 0.78, green: 0.82, blue: 0.98),
                Color(red: 0.88, green: 0.90, blue: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // Liquid Glass Background
    static func glassBackground() -> some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .opacity(0.8)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // Glass card style
    static func glassCard() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white.opacity(0.6))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
