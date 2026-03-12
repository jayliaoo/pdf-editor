import Foundation
import PDFKit
import AppKit

class PDFService {
    static func deletePages(from document: PDFDocument, indices: Set<Int>) -> PDFDocument? {
        guard !indices.isEmpty else { return document }
        
        let sortedIndices = indices.sorted(by: >)
        for index in sortedIndices {
            guard document.page(at: index) != nil else { continue }
            document.removePage(at: index)
        }
        
        return document
    }
    
    static func addBlankPage(to document: PDFDocument, at index: Int?) -> Bool {
        let newPage = PDFPage()
        
        if let insertIndex = index, insertIndex >= 0 && insertIndex <= document.pageCount {
            document.insert(newPage, at: insertIndex)
            return true
        } else {
            document.insert(newPage, at: document.pageCount)
            return true
        }
    }
    
    static func addImageAsPage(to document: PDFDocument, imageURL: URL, at index: Int?) -> Bool {
        guard let image = NSImage(contentsOf: imageURL) else { return false }
        
        guard let newPage = PDFPage(image: image) else { return false }
        
        if let insertIndex = index, insertIndex >= 0 && insertIndex <= document.pageCount {
            document.insert(newPage, at: insertIndex)
            return true
        } else {
            document.insert(newPage, at: document.pageCount)
            return true
        }
    }
    
    static func addPagesFromPDF(to document: PDFDocument, sourceURL: URL, pageIndices: Set<Int>?, insertAt: Int?) -> Bool {
        guard let sourceDocument = PDFDocument(url: sourceURL) else { return false }
        
        let indicesToAdd: [Int]
        if let pageIndices = pageIndices {
            indicesToAdd = pageIndices.sorted()
        } else {
            indicesToAdd = Array(0..<sourceDocument.pageCount)
        }
        
        let insertPosition = insertAt ?? document.pageCount
        
        for index in indicesToAdd {
            guard let page = sourceDocument.page(at: index),
                  let copiedPage = page.copy() as? PDFPage else { continue }
            document.insert(copiedPage, at: insertPosition)
        }
        
        return true
    }
    
    static func extractAsPDF(from document: PDFDocument, indices: Set<Int>) -> PDFDocument? {
        guard !indices.isEmpty else { return nil }
        
        let newDocument = PDFDocument()
        let sortedIndices = indices.sorted()
        
        for index in sortedIndices {
            guard let page = document.page(at: index) else { continue }
            newDocument.insert(page, at: newDocument.pageCount)
        }
        
        return newDocument.pageCount > 0 ? newDocument : nil
    }
    
    static func extractAsImage(from page: PDFPage, format: NSBitmapImageRep.FileType, quality: CGFloat) -> Data? {
        let pageBounds = page.bounds(for: .mediaBox)
        let image = NSImage(size: pageBounds.size)
        
        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.setFillColor(NSColor.white.cgColor)
            context.fill(pageBounds)
            page.draw(with: .mediaBox, to: context)
        }
        image.unlockFocus()
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        
        return bitmap.representation(using: format, properties: [.compressionFactor: quality])
    }
    
    static func rotatePage(_ page: PDFPage, degrees: Int) {
        let normalizedDegrees = ((degrees % 360) + 360) % 360
        page.rotation = (page.rotation + normalizedDegrees) % 360
    }
    
    static func mergePDFs(urls: [URL]) -> PDFDocument? {
        let mergedDocument = PDFDocument()
        
        for url in urls {
            guard let document = PDFDocument(url: url) else { continue }
            
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) {
                    mergedDocument.insert(page, at: mergedDocument.pageCount)
                }
            }
        }
        
        return mergedDocument.pageCount > 0 ? mergedDocument : nil
    }
}