import SwiftUI
import PDFKit
import UniformTypeIdentifiers

class AppViewModel: ObservableObject {
    @Published var documents: [PDFDocumentWrapper] = []
    @Published var selectedDocumentId: UUID?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            DispatchQueue.main.async {
                self?.processSelectedURLs(panel.urls)
            }
        }
    }
    
    func closeDocument(_ wrapper: PDFDocumentWrapper) {
        if wrapper.isModified {
            // Show save prompt - implement later
        }
        documents.removeAll { $0.id == wrapper.id }
        if selectedDocumentId == wrapper.id {
            selectedDocumentId = documents.first?.id
        }
    }
    
    private func processSelectedURLs(_ urls: [URL]) {
        for url in urls {
            if let pdfDocument = PDFDocument(url: url) {
                let wrapper = PDFDocumentWrapper(document: pdfDocument, url: url)
                documents.append(wrapper)
                if selectedDocumentId == nil {
                    selectedDocumentId = wrapper.id
                }
            } else {
                errorMessage = "Failed to load PDF: \(url.lastPathComponent)"
                showError = true
            }
        }
    }
}

class PDFDocumentWrapper: ObservableObject, Identifiable {
    let id = UUID()
    let document: PDFDocument
    let url: URL
    @Published var isModified: Bool = false
    @Published var selectedPages: Set<Int> = [] // For future page selection feature
    
    var fileName: String {
        url.lastPathComponent
    }
    
    init(document: PDFDocument, url: URL) {
        self.document = document
        self.url = url
    }
}