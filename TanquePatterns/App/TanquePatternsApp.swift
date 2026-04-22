import SwiftUI
import SwiftData

@main
struct TanquePatternsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: PatternDocument.self)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 680)
        .windowResizability(.contentSize)
    }
}
