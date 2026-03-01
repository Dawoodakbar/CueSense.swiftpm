import SwiftUI

struct WelcomeView: View {
    @Binding var showWelcomeScreen: Bool
    var onContinue: (() -> Void)? = nil // Optional closure for onboarding flow
    @State private var showLoading = false
    @State private var showDetailSheet = false
    @State private var selectedDetail: String? = nil
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                
                // Logo & Title Section
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: [Color(red: 0.6, green: 0.4, blue: 0.9), Color(red: 0.5, green: 0.3, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    
                    VStack(spacing: 8) {
                        Text(hasCompletedOnboarding ? "Welcome Back" : "Welcome to CueSense")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                        
                        Text(hasCompletedOnboarding ? "Ready for another session?" : "Your gentle conversation guide")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Info Cards Container
                VStack(spacing: 16) {
                    // General Info Card
                    Button(action: {
                        selectedDetail = "General"
                        showDetailSheet = true
                    }) {
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Understanding Asperger's")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Learn about communication styles, social cues, and interaction patterns.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 4)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Social Challenges Card
                    Button(action: {
                        selectedDetail = "Social Challenges"
                        showDetailSheet = true
                    }) {
                        HStack(alignment: .center, spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Social Challenges")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Navigating cues & timing")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Unique Strengths Card
                    Button(action: {
                        selectedDetail = "Unique Strengths"
                        showDetailSheet = true
                    }) {
                        HStack(alignment: .center, spacing: 16) {
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Unique Strengths")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("Focus, detail & honesty")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Get Started Button
                Button(action: {
                    if let onContinue = onContinue {
                        // If used in onboarding flow, just trigger the callback
                        onContinue()
                    } else {
                        // Standard flow
                        hasCompletedOnboarding = true
                        withAnimation {
                            showWelcomeScreen = false
                        }
                    }
                }) {
                    Text(hasCompletedOnboarding ? "Continue" : "Get Started")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.55, green: 0.36, blue: 0.87), Color(red: 0.4, green: 0.3, blue: 0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.55, green: 0.36, blue: 0.87).opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background {
                Group {
                    if let bgImage = UIImage(named: "background") {
                        Image(uiImage: bgImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea()
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.93, green: 0.94, blue: 0.98), Color(red: 0.96, green: 0.93, blue: 0.98)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    }
                }
            }
            .sheet(isPresented: $showDetailSheet) {
                DetailInfoView(category: selectedDetail ?? "")
            }
    }
}

struct DetailInfoView: View {
    let category: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    if category == "Social Challenges" {
                        ForEach([
                            "Difficulty reading non-verbal cues (body language, facial expressions).",
                            "Understanding sarcasm, idioms, or metaphors.",
                            "Knowing when to start or end a conversation.",
                            "Taking turns in conversation without interrupting.",
                            "Maintaining eye contact comfortably."
                        ], id: \.self) { point in
                            Label(point, systemImage: "bubble.left.and.bubble.right")
                                .font(.body)
                                .padding(.vertical, 4)
                        }
                    } else if category == "Unique Strengths" {
                        ForEach([
                            "Deep focus and concentration on topics of interest.",
                            "Strong attention to detail and pattern recognition.",
                            "Honesty, loyalty, and reliability.",
                            "Unique perspective and creative problem-solving.",
                            "Deep knowledge in specialized subjects."
                        ], id: \.self) { point in
                            Label(point, systemImage: "star")
                                .font(.body)
                                .padding(.vertical, 4)
                        }
                    } else {
                        ForEach([
                            "Asperger's Syndrome is part of the Autism Spectrum Disorder (ASD).",
                            "It is characterized by difficulties in social interaction and nonverbal communication.",
                            "Individuals often have restricted and repetitive patterns of behavior and interests.",
                            "Intelligence and language development are typically average or above average.",
                            "Each individual is unique, with their own set of strengths and challenges."
                        ], id: \.self) { point in
                            Label(point, systemImage: "info.circle")
                                .font(.body)
                                .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text(category == "General" ? "Overview" : category)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(category == "General" ? "About" : category)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 6)
                        .frame(width: 50, height: 50)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(gradient: Gradient(colors: [.purple, .blue]), center: .center),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                }
                
                Text("Preparing Session...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}
