import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    @State private var selection = 0
    @State private var isSessionActive = false
    @State private var showWelcomeScreen = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            if isSessionActive {
                ActiveSessionView(isPresented: $isSessionActive)
                    .transition(.move(edge: .bottom))
            } else {
                TabView(selection: $selection) {
                    HomeView(startSession: {
                        withAnimation {
                            isSessionActive = true
                        }
                    })
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                    
                    HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.fill")
                    }
                    .tag(1)
                    
                    ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle.fill")
                    }
                    .tag(2)
                }
                .tint(Theme.primary)
            }
            
            // Welcome Screen Overlay - Only show if onboarding was ALREADY complete
            if showWelcomeScreen {
                WelcomeView(showWelcomeScreen: $showWelcomeScreen)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Logic:
            // 1. If hasCompletedOnboarding is FALSE, the fullScreenCover in MyApp is active.
            //    When it finishes, it sets hasCompletedOnboarding = TRUE and dismisses.
            //    We do NOT want to show WelcomeView immediately after that.
            // 2. If hasCompletedOnboarding is TRUE when this view appears, it means
            //    the user is returning (app launch with onboarding done).
            //    In this case, we DO want to show WelcomeView.
            
            if hasCompletedOnboarding {
                showWelcomeScreen = true
            }
        }
    }
}
