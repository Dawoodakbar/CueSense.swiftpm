import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    @State private var selection = 0
    @State private var isSessionActive = false
    
    var body: some View {
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
    }
}
