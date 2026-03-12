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
            
            CommandGroup(after: .newItem) {
                Divider()
                
                Menu("Insert") {
                    Button("Blank Page") {
                        appViewModel.addBlankPage()
                    }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    
                    Button("From Image...") {
                        appViewModel.addPageFromImage()
                    }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                    
                    Button("From PDF...") {
                        appViewModel.addPageFromPDF()
                    }
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                }
                .disabled(appViewModel.documents.isEmpty)
            }
            
            CommandGroup(after: .pasteboard) {
                Divider()
                
                Button("Delete Page") {
                    appViewModel.deleteSelectedPages()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(appViewModel.selectedDocument?.selectedPages.isEmpty ?? true)
            }
        }
    }
}