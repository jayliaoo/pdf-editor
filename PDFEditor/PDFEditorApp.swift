import SwiftUI

@main
struct PDFEditorApp: App {
    @StateObject private var appViewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    appViewModel.openDocument()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}