import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import AppKit

class AppViewModel: ObservableObject {
    @Published var documents: [PDFDocumentWrapper] = []
    @Published var selectedDocumentId: UUID?
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var zoomLevel: CGFloat = 1.0
    
    var selectedDocument: PDFDocumentWrapper? {
        guard let id = selectedDocumentId else { return nil }
        return documents.first { $0.id == id }
    }
    
    func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
    

    
    func deleteSelectedPages() {
        guard let wrapper = selectedDocument,
              !wrapper.selectedPages.isEmpty else { return }
        
        _ = PDFService.deletePages(from: wrapper.document, indices: wrapper.selectedPages)
        wrapper.selectedPages.removeAll()
        wrapper.isModified = true
    }
    
    func deletePage(at index: Int) {
        guard let wrapper = selectedDocument else { return }
        
        _ = PDFService.deletePages(from: wrapper.document, indices: [index])
        wrapper.isModified = true
    }
    
    func rotatePage(at index: Int, degrees: Int) {
        guard let wrapper = selectedDocument,
              let page = wrapper.document.page(at: index) else { return }
        
        PDFService.rotatePage(page, degrees: degrees)
        wrapper.isModified = true
    }
    
    func addBlankPage() {
        guard let wrapper = selectedDocument else { return }
        
        let insertPosition = showPagePositionDialog(currentPage: wrapper.currentPageIndex, totalPages: wrapper.document.pageCount)
        
        let success = PDFService.addBlankPage(to: wrapper.document, at: insertPosition)
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
                let insertPosition = self?.showPagePositionDialog(
                    currentPage: wrapper.currentPageIndex,
                    totalPages: wrapper.document.pageCount
                )
                
                let success = PDFService.addImageAsPage(to: wrapper.document, imageURL: url, at: insertPosition)
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
                let insertPosition = self?.showPagePositionDialog(
                    currentPage: wrapper.currentPageIndex,
                    totalPages: wrapper.document.pageCount
                )
                
                let success = PDFService.addPagesFromPDF(to: wrapper.document, sourceURL: url, pageIndices: nil, insertAt: insertPosition ?? wrapper.document.pageCount)
                if success {
                    wrapper.isModified = true
                } else {
                    self?.errorMessage = "Failed to add pages from PDF"
                    self?.showError = true
                }
            }
        }
    }
    
    private func showPagePositionDialog(currentPage: Int, totalPages: Int) -> Int? {
        let alert = NSAlert()
        alert.messageText = "Insert Position"
        alert.informativeText = "Choose where to insert the new page(s):"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "After Current Page")
        alert.addButton(withTitle: "Before Current Page")
        alert.addButton(withTitle: "At End")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            return currentPage + 1
        case .alertSecondButtonReturn:
            return currentPage
        case .alertThirdButtonReturn:
            return totalPages
        default:
            return nil
        }
    }
    
    func showPageRangeDialog(completion: @escaping (Set<Int>?) -> Void) {
        let alert = NSAlert()
        alert.messageText = "Select Page Range"
        alert.informativeText = "Enter page range (e.g., 1-5) or leave empty for all pages:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Extract")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.placeholderString = "e.g., 1-5 or 1,3,5"
        alert.accessoryView = input
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let text = input.stringValue
            guard let wrapper = selectedDocument else {
                completion(nil)
                return
            }
            
            let totalPages = wrapper.document.pageCount
            
            if text.isEmpty {
                completion(Set(0..<totalPages))
                return
            }
            
            var indices = Set<Int>()
            
            let parts = text.components(separatedBy: ",")
            for part in parts {
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if trimmed.contains("-") {
                    let rangeParts = trimmed.components(separatedBy: "-")
                    if rangeParts.count == 2,
                       let start = Int(rangeParts[0].trimmingCharacters(in: .whitespaces)),
                       let end = Int(rangeParts[1].trimmingCharacters(in: .whitespaces)) {
                        for i in start...end {
                            if i > 0 && i <= totalPages {
                                indices.insert(i - 1)
                            }
                        }
                    }
                } else if let page = Int(trimmed), page > 0 && page <= totalPages {
                    indices.insert(page - 1)
                }
            }
            
            completion(indices.isEmpty ? nil : indices)
        } else {
            completion(nil)
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
    
    func extractAsImage(from pageIndex: Int) {
        guard let wrapper = selectedDocument,
              let page = wrapper.document.page(at: pageIndex) else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png, .jpeg]
        panel.nameFieldStringValue = "Page_\(pageIndex + 1).png"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            let format: NSBitmapImageRep.FileType = url.pathExtension.lowercased() == "jpg" ? .jpeg : .png
            if let data = PDFService.extractAsImage(from: page, format: format, quality: 0.9) {
                do {
                    try data.write(to: url)
                } catch {
                    self?.showErrorAlert(message: "Failed to save image: \(error.localizedDescription)")
                }
            } else {
                self?.showErrorAlert(message: "Failed to extract image")
            }
        }
    }
    
    func extractPageAsImage(from pageIndex: Int, completion: @escaping (Data?) -> Void) {
        guard let wrapper = selectedDocument,
              let page = wrapper.document.page(at: pageIndex) else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let data = PDFService.extractAsImage(from: page, format: .png, quality: 1.0)
            DispatchQueue.main.async {
                completion(data)
            }
        }
    }
    
    func extractPagesAsPDF(indices: Set<Int>) {
        showPageRangeDialog { [weak self] selectedIndices in
            guard let indices = selectedIndices else { return }
            self?.performExtractPDF(indices: indices)
        }
    }
    
    private func performExtractPDF(indices: Set<Int>) {
        guard let wrapper = selectedDocument,
              let extractedDoc = PDFService.extractAsPDF(from: wrapper.document, indices: indices) else {
            showErrorAlert(message: "Failed to extract pages")
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "extracted_pages.pdf"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            if extractedDoc.write(to: url) {
            } else {
                self?.showErrorAlert(message: "Failed to save PDF")
            }
        }
    }
    
    func mergePDFs() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.message = "Select PDF files to merge"
        
        panel.begin { [weak self] response in
            guard response == .OK, !panel.urls.isEmpty else { return }
            
            if let mergedDoc = PDFService.mergePDFs(urls: panel.urls) {
                self?.saveExtractedPDF(mergedDoc)
            } else {
                self?.showErrorAlert(message: "Failed to merge PDFs")
            }
        }
    }
    
    private func saveExtractedPDF(_ document: PDFDocument) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "merged.pdf"
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            if document.write(to: url) {
                if let pdfDocument = PDFDocument(url: url) {
                    let wrapper = PDFDocumentWrapper(document: pdfDocument, url: url)
                    DispatchQueue.main.async {
                        self?.documents.append(wrapper)
                        self?.selectedDocumentId = wrapper.id
                    }
                }
            } else {
                self?.showErrorAlert(message: "Failed to save merged PDF")
            }
        }
    }
    
    func save() {
        guard let wrapper = selectedDocument else { return }
        
        if wrapper.url.path.isEmpty || wrapper.url == URL(fileURLWithPath: "") {
            saveAs()
            return
        }
        
        if wrapper.document.write(to: wrapper.url) {
            wrapper.isModified = false
        } else {
            showErrorAlert(message: "Failed to save document")
        }
    }
    
    func saveAs() {
        guard let wrapper = selectedDocument else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = wrapper.fileName
        
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            
            if wrapper.document.write(to: url) {
                wrapper.isModified = false
            } else {
                self?.showErrorAlert(message: "Failed to save document")
            }
        }
    }
    
    func selectAll() {
        guard let wrapper = selectedDocument else { return }
        wrapper.selectedPages = Set(0..<wrapper.document.pageCount)
    }
    
    func closeDocument(_ wrapper: PDFDocumentWrapper) {
        if wrapper.isModified {
            let alert = NSAlert()
            alert.messageText = "Save changes to \"\(wrapper.fileName)\"?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn:
                save()
                documents.removeAll { $0.id == wrapper.id }
                if selectedDocumentId == wrapper.id {
                    selectedDocumentId = documents.first?.id
                }
            case .alertSecondButtonReturn:
                documents.removeAll { $0.id == wrapper.id }
                if selectedDocumentId == wrapper.id {
                    selectedDocumentId = documents.first?.id
                }
            default:
                break
            }
        } else {
            documents.removeAll { $0.id == wrapper.id }
            if selectedDocumentId == wrapper.id {
                selectedDocumentId = documents.first?.id
            }
        }
    }
    
    func zoomIn() {
        zoomLevel = min(4.0, zoomLevel + 0.25)
    }
    
    func zoomOut() {
        zoomLevel = max(0.25, zoomLevel - 0.25)
    }
    
    func zoomActualSize() {
        zoomLevel = 1.0
    }
    
    func zoomFitToWindow() {
        zoomLevel = -1
    }
    
    func handleDroppedFiles(_ urls: [URL]) {
        processSelectedURLs(urls.filter { $0.pathExtension.lowercased() == "pdf" })
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