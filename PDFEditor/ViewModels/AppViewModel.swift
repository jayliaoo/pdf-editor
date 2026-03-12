import SwiftUI
import PDFKit
import UniformTypeIdentifiers

class AppViewModel: ObservableObject {
    @Published var documents: [PDFDocumentWrapper] = []
    @Published var selectedDocumentId: UUID?
    
    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                if let pdfDocument = PDFDocument(url: url) {
                    let wrapper = PDFDocumentWrapper(document: pdfDocument, url: url)
                    documents.append(wrapper)
                    if selectedDocumentId == nil {
                        selectedDocumentId = wrapper.id
                    }
                }
            }
        }
    }
}

class PDFDocumentWrapper: ObservableObject, Identifiable {
    let id = UUID()
    let document: PDFDocument
    let url: URL
    @Published var isModified: Bool = false
    @Published var selectedPages: Set<Int> = []
    
    var fileName: String {
        url.lastPathComponent
    }
    
    init(document: PDFDocument, url: URL) {
        self.document = document
        self.url = url
    }
}