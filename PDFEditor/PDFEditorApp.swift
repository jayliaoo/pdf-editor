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
                
                Divider()
                
                Button("Save") {
                    appViewModel.save()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(appViewModel.selectedDocument == nil)
                
                Button("Save As...") {
                    appViewModel.saveAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(appViewModel.selectedDocument == nil)
                
                Divider()
                
                Button("Close") {
                    if let wrapper = appViewModel.selectedDocument {
                        appViewModel.closeDocument(wrapper)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(appViewModel.selectedDocument == nil)
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
                
                Divider()
                
                Menu("Extract") {
                    Button("Extract as Image...") {
                        if let wrapper = appViewModel.selectedDocument,
                           let index = wrapper.selectedPages.first {
                            appViewModel.extractAsImage(from: index)
                        }
                    }
                    .disabled(appViewModel.selectedDocument?.selectedPages.count != 1)
                    
                    Button("Extract as PDF...") {
                        if let wrapper = appViewModel.selectedDocument,
                           !wrapper.selectedPages.isEmpty {
                            appViewModel.extractPagesAsPDF(indices: wrapper.selectedPages)
                        }
                    }
                    .disabled(appViewModel.selectedDocument?.selectedPages.isEmpty ?? true)
                }
                .disabled(appViewModel.selectedDocument == nil)
                
                Button("Merge PDFs...") {
                    appViewModel.mergePDFs()
                }
            }
            
            CommandGroup(after: .pasteboard) {
                Divider()
                
                Button("Select All") {
                    appViewModel.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
                .disabled(appViewModel.selectedDocument == nil)
                
                Button("Delete Page") {
                    appViewModel.deleteSelectedPages()
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(appViewModel.selectedDocument?.selectedPages.isEmpty ?? true)
            }
            
            CommandMenu("View") {
                Divider()
                
                Button("Zoom In") {
                    appViewModel.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out") {
                    appViewModel.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Actual Size") {
                    appViewModel.zoomActualSize()
                }
                .keyboardShortcut("0", modifiers: .command)
                
                Button("Fit to Window") {
                    appViewModel.zoomFitToWindow()
                }
                .keyboardShortcut("9", modifiers: .command)
            }
        }
    }
}