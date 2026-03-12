import SwiftUI
import PDFKit
import UniformTypeIdentifiers

class AppViewModel: ObservableObject {
    @Published var documents: [PDFDocumentWrapper] = []
    @Published var selectedDocumentId: UUID?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    var selectedDocument: PDFDocumentWrapper? {
        guard let id = selectedDocumentId else { return nil }
        return documents.first { $0.id == id }
    }
    
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
    
    func deleteSelectedPages() {
        guard let wrapper = selectedDocument,
              !wrapper.selectedPages.isEmpty else { return }
        
        _ = PDFService.deletePages(from: wrapper.document, indices: wrapper.selectedPages)
        wrapper.selectedPages.removeAll()
        wrapper.isModified = true
    }
    
    func addBlankPage() {
        guard let wrapper = selectedDocument else { return }
        
        let success = PDFService.addBlankPage(to: wrapper.document, at: nil)
        if success {
            wrapper.isModified = true
        }
    }
    
    func addPageFromImage() {
        guard let wrapper = selectedDocument else { return }
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                let success = PDFService.addImageAsPage(to: wrapper.document, imageURL: url, at: nil)
                if success {
                    wrapper.isModified = true
                } else {
                    self?.errorMessage = "Failed to add image as page"
                    self?.showError = true
                }
            }
        }
    }
    
    func addPageFromPDF() {
        guard let wrapper = selectedDocument else { return }
        
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                let success = PDFService.addPagesFromPDF(to: wrapper.document, sourceURL: url, pageIndices: nil)
                if success {
                    wrapper.isModified = true
                } else {
                    self?.errorMessage = "Failed to add pages from PDF"
                    self?.showError = true
                }
            }
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
    @Published var selectedPages: Set<Int> = []
    @Published var currentPageIndex: Int = 0
    
    var fileName: String {
        url.lastPathComponent
    }
    
    init(document: PDFDocument, url: URL) {
        self.document = document
        self.url = url
    }
}