import SwiftUI

struct ContentView: View {
    @State private var currentTab = 0 // 0: Home, 1: Active
    
    var body: some View {
        ZStack {
            if currentTab == 0 {
              if #available(iOS 17.0, *) {
                HomeView(currentTab: $currentTab)
                  .transition(.opacity)
              } else {
                // Fallback on earlier versions
              }
            } else {
              if #available(iOS 17, *) {
                ActiveSessionView(currentTab: $currentTab)
                  .transition(.move(edge: .bottom))
              } else {
                // Fallback on earlier versions
              }
            }
        }
        .animation(.easeInOut, value: currentTab)
    }
}
