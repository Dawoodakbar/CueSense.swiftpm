import SwiftData
import SwiftUI

@available(iOS 17.0, *)
@main
struct MyApp: App {
    @StateObject private var speechManager = SpeechManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(speechManager)
        }
        .modelContainer(for: InteractionSession.self)
    }
}
