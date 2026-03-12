# PDF Editor Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS PDF editor with SwiftUI supporting page management (delete, add, extract), PDF merging, rotation, and tabbed interface.

**Architecture:** MVVM with PDFKit (native). Single window with tabbed interface, hover-activated thumbnail strip.

**Tech Stack:** SwiftUI, PDFKit (built-in), no external dependencies.

---

## Chunk 1: Project Setup & App Shell

### Task 1.1: Create Xcode Project

**Files:**
- Create: `PDFEditor/PDFEditorApp.swift`
- Create: `PDFEditor/ContentView.swift`

- [ ] **Step 1: Create project directory and SwiftUI app entry point**

```swift
// PDFEditor/PDFEditorApp.swift
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
```

- [ ] **Step 2: Create AppViewModel**

```swift
// PDFEditor/ViewModels/AppViewModel.swift
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
```

- [ ] **Step 3: Create basic ContentView**

```swift
// PDFEditor/Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if appViewModel.documents.isEmpty {
                emptyStateView
            } else {
                if let selectedId = appViewModel.selectedDocumentId,
                   let wrapper = appViewModel.documents.first(where: { $0.id == selectedId }) {
                    DocumentView(wrapper: wrapper)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No PDF Open")
                .font(.title2)
            Text("Open a PDF file to get started")
                .foregroundColor(.secondary)
            Button("Open PDF...") {
                appViewModel.openDocument()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 4: Create DocumentView placeholder**

```swift
// PDFEditor/Views/DocumentView.swift
import SwiftUI

struct DocumentView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    
    var body: some View {
        Text(wrapper.fileName)
    }
}
```

- [ ] **Step 5: Create XcodeGen project.yml**

```yaml
# project.yml
name: PDFEditor
options:
  bundleIdPrefix: com.pdeditor
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"

settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "13.0"

targets:
  PDFEditor:
    type: application
    platform: macOS
    sources:
      - PDFEditor
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.pdeditor.pdfeditor
        INFOPLIST_GENERATION_MODE: GeneratedFile
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_CFBundleDisplayName: "PDF Editor"
        INFOPLIST_KEY_LSApplicationCategoryType: "public.app-category.productivity"
        INFOPLIST_KEY_NSHumanReadableCopyright: "Copyright © 2026. All rights reserved."
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
        CODE_SIGN_STYLE: Automatic
        ENABLE_HARDENED_RUNTIME: YES
        COMBINE_HIDPI_IMAGES: YES
```

- [ ] **Step 6: Generate Xcode project and build**

```bash
cd /Users/mac/git/personal/pdf-editor
mkdir -p PDFEditor/ViewModels PDFEditor/Views
# Save all files created above
xcodegen generate
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "chore: create project structure and app shell"
```

---

## Chunk 2: Tab Bar & Document Management

### Task 2.1: Tab Bar Component

**Files:**
- Create: `PDFEditor/Views/TabBarView.swift`

- [ ] **Step 1: Create TabBarView**

```swift
// PDFEditor/Views/TabBarView.swift
import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(appViewModel.documents) { wrapper in
                    TabItemView(wrapper: wrapper, isSelected: wrapper.id == appViewModel.selectedDocumentId)
                        .onTapGesture {
                            appViewModel.selectedDocumentId = wrapper.id
                        }
                        .contextMenu {
                            Button("Close") {
                                appViewModel.closeDocument(wrapper)
                            }
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(height: 32)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TabItemView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(wrapper.fileName)
                .font(.system(size: 13))
                .lineLimit(1)
            
            if wrapper.isModified {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            }
            
            Button(action: {
                // Close handled by parent
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        .cornerRadius(6)
    }
}
```

- [ ] **Step 2: Add tab bar to ContentView**

```swift
// Modify ContentView.swift - replace body
var body: some View {
    VStack(spacing: 0) {
        if !appViewModel.documents.isEmpty {
            TabBarView()
            Divider()
        }
        
        if appViewModel.documents.isEmpty {
            emptyStateView
        } else {
            if let selectedId = appViewModel.selectedDocumentId,
               let wrapper = appViewModel.documents.first(where: { $0.id == selectedId }) {
                DocumentView(wrapper: wrapper)
            }
        }
    }
}
```

- [ ] **Step 3: Add closeDocument method to AppViewModel**

```swift
// Add to AppViewModel.swift
func closeDocument(_ wrapper: PDFDocumentWrapper) {
    if wrapper.isModified {
        // Show save prompt - implement later
    }
    documents.removeAll { $0.id == wrapper.id }
    if selectedDocumentId == wrapper.id {
        selectedDocumentId = documents.first?.id
    }
}
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: add tab bar component"
```

---

## Chunk 3: PDF Viewer & Thumbnail Strip

### Task 3.1: PDF Viewer with PDFView

**Files:**
- Create: `PDFEditor/Views/PDFViewerView.swift`
- Modify: `PDFEditor/Views/DocumentView.swift`

- [ ] **Step 1: Create PDFViewerView using PDFKit**

```swift
// PDFEditor/Views/PDFViewerView.swift
import SwiftUI
import PDFKit

struct PDFViewerView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    @State private var zoomScale: CGFloat = 1.0
    
    var body: some View {
        PDFKitView(document: wrapper.document, zoomScale: $zoomScale)
            .toolbar {
                ToolbarItemGroup {
                    Button(action: { zoomIn() }) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    Button(action: { zoomOut() }) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    Button(action: { fitToWindow() }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                }
            }
    }
    
    private func zoomIn() {
        zoomScale = min(zoomScale * 1.25, 4.0)
    }
    
    private func zoomOut() {
        zoomScale = max(zoomScale / 1.25, 0.25)
    }
    
    private func fitToWindow() {
        zoomScale = 1.0
    }
}

struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    @Binding var zoomScale: CGFloat
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}
```

- [ ] **Step 2: Update DocumentView to use PDFViewerView**

```swift
// PDFEditor/Views/DocumentView.swift
import SwiftUI

struct DocumentView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    @State private var showThumbnails = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Thumbnail strip (hover to show)
            if showThumbnails {
                ThumbnailStripView(wrapper: wrapper)
                    .frame(width: 180)
                    .transition(.move(edge: .leading))
            }
            
            // PDF Preview
            PDFViewerView(wrapper: wrapper)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showThumbnails = hovering
                    }
                }
        }
    }
}
```

- [ ] **Step 3: Create ThumbnailStripView**

```swift
// PDFEditor/Views/ThumbnailStripView.swift
import SwiftUI
import PDFKit

struct ThumbnailStripView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<wrapper.document.pageCount, id: \.self) { index in
                    ThumbnailItem(
                        pageIndex: index,
                        document: wrapper.document,
                        isSelected: wrapper.selectedPages.contains(index)
                    )
                    .onTapGesture {
                        handlePageTap(index)
                    }
                }
            }
            .padding(8)
        }
        .background(Color(hex: "F5F5F5"))
    }
    
    private func handlePageTap(_ index: Int) {
        if NSEvent.modifierFlags.contains(.command) {
            if wrapper.selectedPages.contains(index) {
                wrapper.selectedPages.remove(index)
            } else {
                wrapper.selectedPages.insert(index)
            }
        } else {
            wrapper.selectedPages = [index]
        }
    }
}

struct ThumbnailItem: View {
    let pageIndex: Int
    let document: PDFDocument
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if let page = document.page(at: pageIndex) {
                let thumbnail = page.thumbnail(of: CGSize(width: 150, height: 200), for: .mediaBox)
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 200)
                    .background(Color.white)
                    .cornerRadius(4)
                    .shadow(radius: 2)
            }
            Text("Page \(pageIndex + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(4)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: add PDF viewer with hover thumbnail strip"
```

---

## Chunk 4: Page Operations - Delete, Add Blank Page

### Task 4.1: Delete Page Functionality

**Files:**
- Create: `PDFEditor/Services/PDFService.swift`
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`

- [ ] **Step 1: Create PDFService with delete page**

```swift
// PDFEditor/Services/PDFService.swift
import Foundation
import PDFKit
import AppKit
import UniformTypeIdentifiers

class PDFService {
    
    static func deletePages(from document: PDFDocument, indices: Set<Int>) -> PDFDocument? {
        guard !indices.isEmpty else { return nil }
        
        let sortedIndices = indices.sorted(by: >)
        
        for index in sortedIndices {
            if let page = document.page(at: index) {
                document.removePage(at: index)
            }
        }
        
        return document
    }
    
    static func addBlankPage(to document: PDFDocument, at index: Int? = nil) -> Bool {
        guard let blankPage = PDFPage() else { return false }
        
        if let index = index, index < document.pageCount {
            document.insert(blankPage, at: index)
        } else {
            document.addPage(blankPage)
        }
        
        return true
    }
    
    static func addImageAsPage(to document: PDFDocument, imageURL: URL, at index: Int? = nil) -> Bool {
        guard let image = NSImage(contentsOf: imageURL),
              let pdfImage = PDFImageFromNSImage(image) else {
            return false
        }
        
        let pageRect = CGRect(origin: .zero, size: image.size)
        let page = PDFPage(image: pdfImage)!
        
        if let index = index, index < document.pageCount {
            document.insert(page, at: index)
        } else {
            document.addPage(page)
        }
        
        return true
    }
    
    static func addPagesFromPDF(to document: PDFDocument, sourceURL: URL, pageIndices: Set<Int>? = nil) -> Bool {
        guard let sourceDoc = PDFDocument(url: sourceURL) else { return false }
        
        let indices = pageIndices ?? Set(0..<sourceDoc.pageCount)
        
        for index in indices.sorted() {
            if let page = sourceDoc.page(at: index) {
                document.insert(page.copy() as! PDFPage, at: document.pageCount)
            }
        }
        
        return true
    }
    
    static func extractAsPDF(from document: PDFDocument, indices: Set<Int>) -> PDFDocument? {
        guard !indices.isEmpty else { return nil }
        
        let newDoc = PDFDocument()
        let sortedIndices = indices.sorted()
        
        for index in sortedIndices {
            if let page = document.page(at: index),
               let copiedPage = page.copy() as? PDFPage {
                newDoc.addPage(copiedPage)
            }
        }
        
        return newDoc
    }
    
    static func extractAsImage(from page: PDFPage, format: NSBitmapImageRep.FileType, quality: CGFloat = 0.9) -> Data? {
        let bounds = page.bounds(for: .mediaBox)
        let image = page.thumbnail(of: bounds.size, for: .mediaBox)
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmap.representation(using: format, properties: [.compressionFactor: quality])
    }
    
    static func rotatePage(_ page: PDFPage, degrees: Int) {
        let currentRotation = page.rotation
        page.rotation = currentRotation + degrees
    }
    
    static func mergePDFs(urls: [URL]) -> PDFDocument? {
        let merged = PDFDocument()
        
        for url in urls {
            guard let doc = PDFDocument(url: url) else { continue }
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    merged.addPage(page.copy() as! PDFPage)
                }
            }
        }
        
        return merged.pageCount > 0 ? merged : nil
    }
    
    private static func PDFImageFromNSImage(_ image: NSImage) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: image.size)
    }
}
```

- [ ] **Step 2: Add delete method to AppViewModel**

```swift
// Add to AppViewModel.swift
func deleteSelectedPages() {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }),
          !wrapper.selectedPages.isEmpty else { return }
    
    if let _ = PDFService.deletePages(from: wrapper.document, indices: wrapper.selectedPages) {
        wrapper.isModified = true
        wrapper.selectedPages.removeAll()
    }
}
```

- [ ] **Step 3: Add context menu to ThumbnailStripView**

```swift
// Update ThumbnailItem in ThumbnailStripView.swift
.contextMenu {
    Button("Delete") {
        // Handled by parent via callback
    }
    Divider()
    Button("Extract as Image") { }
    Button("Extract as PDF") { }
    Divider()
    Button("Rotate 90° Clockwise") { }
    Button("Rotate 90° Counter-clockwise") { }
    Button("Rotate 180°") { }
}
```

- [ ] **Step 4: Add Edit menu with Delete**

```swift
// Update PDFEditorApp.swift - add Edit menu
.commands {
    CommandGroup(replacing: .newItem) {
        Button("Open...") {
            appViewModel.openDocument()
        }
        .keyboardShortcut("o", modifiers: .command)
    }
    CommandGroup(after: .pasteboard) {
        Divider()
        Button("Delete Page(s)") {
            appViewModel.deleteSelectedPages()
        }
        .keyboardShortcut(.delete, modifiers: [])
        .disabled(appViewModel.selectedDocumentPages.isEmpty)
    }
}
```

- [ ] **Step 5: Add helper property to AppViewModel**

```swift
// Add to AppViewModel.swift
var selectedDocumentPages: Set<Int> {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else {
        return []
    }
    return wrapper.selectedPages
}
```

- [ ] **Step 6: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "feat: add delete page functionality"
```

### Task 4.2: Add Blank Page

**Files:**
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`
- Modify: `PDFEditor/PDFEditorApp.swift`

- [ ] **Step 1: Add addBlankPage to AppViewModel**

```swift
// Add to AppViewModel.swift
func addBlankPage(at position: Int? = nil) {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    if PDFService.addBlankPage(to: wrapper.document, at: position ?? wrapper.document.pageCount) {
        wrapper.isModified = true
    }
}
```

- [ ] **Step 2: Add Insert menu**

```swift
// Update PDFEditorApp.swift
CommandGroup(after: .pasteboard) {
    Divider()
    Button("Delete Page(s)") {
        appViewModel.deleteSelectedPages()
    }
    .keyboardShortcut(.delete, modifiers: [])
    .disabled(appViewModel.selectedDocumentPages.isEmpty)
    
    Menu("Insert") {
        Button("Blank Page") {
            appViewModel.addBlankPage()
        }
        Button("From Image...") {
            appViewModel.addPageFromImage()
        }
        Button("From PDF...") {
            appViewModel.addPageFromPDF()
        }
    }
}
```

- [ ] **Step 3: Add placeholder methods for Image and PDF**

```swift
// Add to AppViewModel.swift
func addPageFromImage() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg]
    panel.allowsMultipleSelection = false
    
    if panel.runModal() == .OK, let url = panel.url {
        guard let selectedId = selectedDocumentId,
              let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
        
        if PDFService.addImageAsPage(to: wrapper.document, imageURL: url) {
            wrapper.isModified = true
        }
    }
}

func addPageFromPDF() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.pdf]
    panel.allowsMultipleSelection = false
    
    if panel.runModal() == .OK, let url = panel.url {
        guard let selectedId = selectedDocumentId,
              let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
        
        if PDFService.addPagesFromPDF(to: wrapper.document, sourceURL: url) {
            wrapper.isModified = true
        }
    }
}
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: add blank page and insert from image/PDF"
```

---

## Chunk 5: Extract, Rotate, Merge

### Task 5.1: Extract Pages (Image & PDF)

**Files:**
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`

- [ ] **Step 1: Add extract methods to AppViewModel**

```swift
// Add to AppViewModel.swift
func extractAsImage(format: NSBitmapImageRep.FileType = .png) {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }),
          let pageIndex = wrapper.selectedPages.first,
          let page = wrapper.document.page(at: pageIndex) else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [format == .png ? .png : .jpeg]
    panel.nameFieldStringValue = "\(wrapper.fileName)_page_\(pageIndex + 1).\(format == .png ? "png" : "jpg")"
    
    if panel.runModal() == .OK, let url = panel.url {
        if let data = PDFService.extractAsImage(from: page, format: format) {
            try? data.write(to: url)
        }
    }
}

func extractAsPDF() {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }),
          !wrapper.selectedPages.isEmpty else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.pdf]
    panel.nameFieldStringValue = "\(wrapper.fileName)_extracted.pdf"
    
    if panel.runModal() == .OK, let url = panel.url {
        if let newDoc = PDFService.extractAsPDF(from: wrapper.document, indices: wrapper.selectedPages) {
            newDoc.write(to: url)
        }
    }
}
```

- [ ] **Step 2: Update context menu in ThumbnailStripView**

```swift
// Update ThumbnailItem contextMenu
.contextMenu {
    Button("Delete") {
        // Handle via notification or callback
    }
    Divider()
    Button("Extract as Image") {
        // Trigger via notification
    }
    Button("Extract as PDF") {
        // Trigger via notification
    }
    Divider()
    Button("Rotate 90° Clockwise") { }
    Button("Rotate 90° Counter-clockwise") { }
    Button("Rotate 180°") { }
}
```

- [ ] **Step 3: Add notification handling for context menu**

```swift
// Add to ThumbnailStripView.swift - add @EnvironmentObject or use closure callback
struct ThumbnailItem: View {
    // ...
    let onDelete: () -> Void
    let onExtractImage: () -> Void
    let onExtractPDF: () -> Void
    let onRotate: (Int) -> Void
    
    // Update context menu to call these
}
```

Actually, let's simplify - use AppViewModel directly via @EnvironmentObject

```swift
// Update ThumbnailStripView.swift
import SwiftUI
import PDFKit

struct ThumbnailStripView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<wrapper.document.pageCount, id: \.self) { index in
                    ThumbnailItem(
                        pageIndex: index,
                        document: wrapper.document,
                        isSelected: wrapper.selectedPages.contains(index)
                    )
                    .onTapGesture {
                        handlePageTap(index)
                    }
                    .contextMenu {
                        Button("Delete") {
                            appViewModel.deletePages(at: [index])
                        }
                        Divider()
                        Button("Extract as Image") {
                            appViewModel.extractPageAsImage(index: index)
                        }
                        Button("Extract as PDF") {
                            appViewModel.extractPagesAsPDF(at: [index])
                        }
                        Divider()
                        Button("Rotate 90° Clockwise") {
                            appViewModel.rotatePages(at: [index], degrees: 90)
                        }
                        Button("Rotate 90° Counter-clockwise") {
                            appViewModel.rotatePages(at: [index], degrees: -90)
                        }
                        Button("Rotate 180°") {
                            appViewModel.rotatePages(at: [index], degrees: 180)
                        }
                    }
                }
            }
            .padding(8)
        }
        .background(Color(hex: "F5F5F5"))
    }
    
    private func handlePageTap(_ index: Int) {
        if NSEvent.modifierFlags.contains(.command) {
            if wrapper.selectedPages.contains(index) {
                wrapper.selectedPages.remove(index)
            } else {
                wrapper.selectedPages.insert(index)
            }
        } else {
            wrapper.selectedPages = [index]
        }
    }
}
```

- [ ] **Step 4: Add all the new methods to AppViewModel**

```swift
// Add to AppViewModel.swift
func deletePages(at indices: [Int]) {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    let indexSet = Set(indices)
    if let _ = PDFService.deletePages(from: wrapper.document, indices: indexSet) {
        wrapper.isModified = true
    }
}

func extractPageAsImage(index: Int) {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }),
          let page = wrapper.document.page(at: index) else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.nameFieldStringValue = "\(wrapper.fileName)_page_\(index + 1).png"
    
    if panel.runModal() == .OK, let url = panel.url {
        if let data = PDFService.extractAsImage(from: page, format: .png) {
            try? data.write(to: url)
        }
    }
}

func extractPagesAsPDF(at indices: [Int]) {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.pdf]
    panel.nameFieldStringValue = "\(wrapper.fileName)_extracted.pdf"
    
    if panel.runModal() == .OK, let url = panel.url {
        if let newDoc = PDFService.extractAsPDF(from: wrapper.document, indices: Set(indices)) {
            newDoc.write(to: url)
        }
    }
}

func rotatePages(at indices: [Int], degrees: Int) {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    for index in indices {
        if let page = wrapper.document.page(at: index) {
            PDFService.rotatePage(page, degrees: degrees)
        }
    }
    wrapper.isModified = true
    // Force UI refresh
    objectWillChange.send()
}
```

- [ ] **Step 5: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: add extract as image/PDF and rotate page functionality"
```

### Task 5.2: Merge PDFs

**Files:**
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`
- Modify: `PDFEditor/PDFEditorApp.swift`

- [ ] **Step 1: Add merge PDFs method**

```swift
// Add to AppViewModel.swift
func mergePDFs() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.pdf]
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    
    guard panel.runModal() == .OK, !panel.urls.isEmpty else { return }
    
    if let merged = PDFService.mergePDFs(urls: panel.urls) {
        // Save merged PDF
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "Merged.pdf"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            merged.write(to: url)
            
            // Optionally open the merged document
            let wrapper = PDFDocumentWrapper(document: merged, url: url)
            documents.append(wrapper)
            selectedDocumentId = wrapper.id
        }
    }
}
```

- [ ] **Step 2: Add Merge menu item**

```swift
// Update PDFEditorApp.swift
CommandGroup(replacing: .newItem) {
    Button("Open...") {
        appViewModel.openDocument()
    }
    .keyboardShortcut("o", modifiers: .command)
    
    Button("Merge PDFs...") {
        appViewModel.mergePDFs()
    }
}
```

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: add merge PDFs functionality"
```

---

## Chunk 6: Save, Save As, Drag & Drop, Final Polish

### Task 6.1: Save & Save As

**Files:**
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`
- Modify: `PDFEditor/PDFEditorApp.swift`

- [ ] **Step 1: Add save methods to AppViewModel**

```swift
// Add to AppViewModel.swift
func save() {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    wrapper.document.write(to: wrapper.url)
    wrapper.isModified = false
}

func saveAs() {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.pdf]
    panel.nameFieldStringValue = wrapper.fileName
    
    if panel.runModal() == .OK, let url = panel.url {
        wrapper.document.write(to: url)
        wrapper.isModified = false
    }
}
```

- [ ] **Step 2: Add Save to Edit menu**

```swift
// Update PDFEditorApp.swift
CommandGroup(replacing: .newItem) {
    Button("Open...") {
        appViewModel.openDocument()
    }
    .keyboardShortcut("o", modifiers: .command)
    
    Button("Merge PDFs...") {
        appViewModel.mergePDFs()
    }
}

CommandGroup(after: .newItem) {
    Divider()
    
    Button("Save") {
        appViewModel.save()
    }
    .keyboardShortcut("s", modifiers: .command)
    
    Button("Save As...") {
        appViewModel.saveAs()
    }
    .keyboardShortcut("s", modifiers: [.command, .shift])
}
```

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

### Task 6.2: Drag & Drop Support

**Files:**
- Modify: `PDFEditor/Views/ContentView.swift`

- [ ] **Step 1: Add drop modifier to ContentView**

```swift
// Update ContentView.swift
struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if !appViewModel.documents.isEmpty {
                TabBarView()
                Divider()
            }
            
            if appViewModel.documents.isEmpty {
                emptyStateView
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                        handleDrop(providers: providers)
                    }
            } else {
                if let selectedId = appViewModel.selectedDocumentId,
                   let wrapper = appViewModel.documents.first(where: { $0.id == selectedId }) {
                    DocumentView(wrapper: wrapper)
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      url.pathExtension.lowercased() == "pdf",
                      let pdfDocument = PDFDocument(url: url) else { return }
                
                DispatchQueue.main.async {
                    let wrapper = PDFDocumentWrapper(document: pdfDocument, url: url)
                    appViewModel.documents.append(wrapper)
                    if appViewModel.selectedDocumentId == nil {
                        appViewModel.selectedDocumentId = wrapper.id
                    }
                }
            }
        }
        return true
    }
    
    // ... rest of file
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "feat: add save, save as, and drag-drop support"
```

### Task 6.3: Unsaved Changes Prompt & Final Polish

**Files:**
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`

- [ ] **Step 1: Add unsaved changes prompt to closeDocument**

```swift
// Update closeDocument in AppViewModel.swift
func closeDocument(_ wrapper: PDFDocumentWrapper) {
    if wrapper.isModified {
        let alert = NSAlert()
        alert.messageText = "Do you want to save changes to \"\(wrapper.fileName)\"?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            wrapper.document.write(to: wrapper.url)
            wrapper.isModified = false
        case .alertThirdButtonReturn:
            return // Cancel
        default:
            break
        }
    }
    
    documents.removeAll { $0.id == wrapper.id }
    if selectedDocumentId == wrapper.id {
        selectedDocumentId = documents.first?.id
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 3: Final commit**

```bash
git add .
git commit -m "feat: add unsaved changes prompt and final polish"
```

---

## Chunk 7: Keyboard Shortcuts & Error Handling

### Task 7.1: View Menu Zoom Shortcuts

**Files:**
- Modify: `PDFEditor/PDFEditorApp.swift`
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`

- [ ] **Step 1: Add View menu with zoom shortcuts**

```swift
// Add to PDFEditorApp.swift commands
CommandGroup(after: .textEditing) {
    Menu("View") {
        Button("Zoom In") {
            appViewModel.zoomIn()
        }
        .keyboardShortcut("+", modifiers: .command)
        
        Button("Zoom Out") {
            appViewModel.zoomOut()
        }
        .keyboardShortcut("-", modifiers: .command)
        
        Button("Actual Size") {
            appViewModel.zoomActual()
        }
        .keyboardShortcut("0", modifiers: .command)
        
        Button("Fit to Window") {
            appViewModel.zoomFit()
        }
        .keyboardShortcut("9", modifiers: .command)
    }
}
```

- [ ] **Step 2: Add zoom methods to AppViewModel**

```swift
// Add to AppViewModel.swift
@Published var zoomLevel: CGFloat = 1.0

func zoomIn() {
    zoomLevel = min(zoomLevel * 1.25, 4.0)
}

func zoomOut() {
    zoomLevel = max(zoomLevel / 1.25, 0.25)
}

func zoomActual() {
    zoomLevel = 1.0
}

func zoomFit() {
    zoomLevel = 1.0 // PDFView autoScales handles fit
}
```

- [ ] **Step 3: Update PDFViewerView to use zoomLevel**

```swift
// In PDFKitView makeNSView, store reference and apply zoom in updateNSView
func updateNSView(_ pdfView: PDFView, context: Context) {
    pdfView.document = document
    pdfView.scaleFactor = zoomScale
}
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

### Task 7.2: Select All & Close Shortcuts

**Files:**
- Modify: `PDFEditor/PDFEditorApp.swift`
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`

- [ ] **Step 1: Add Select All to Edit menu**

```swift
// Add after Delete button in Edit menu
Button("Select All") {
    appViewModel.selectAllPages()
}
.keyboardShortcut("a", modifiers: .command)
```

- [ ] **Step 2: Add selectAllPages to AppViewModel**

```swift
// Add to AppViewModel.swift
func selectAllPages() {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    wrapper.selectedPages = Set(0..<wrapper.document.pageCount)
}
```

- [ ] **Step 3: Add Close shortcut (Cmd+W)**

```swift
// Add to PDFEditorApp.swift
Button("Close") {
    appViewModel.closeCurrentDocument()
}
.keyboardShortcut("w", modifiers: .command)
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

### Task 7.3: Error Handling

**Files:**
- Modify: `PDFEditor/ViewModels/AppViewModel.swift`

- [ ] **Step 1: Add error handling for file open**

```swift
// Update openDocument in AppViewModel.swift
func openDocument() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.pdf]
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    
    if panel.runModal() == .OK {
        for url in panel.urls {
            guard let pdfDocument = PDFDocument(url: url) else {
                showErrorAlert(message: "Unable to open file: \(url.lastPathComponent)")
                continue
            }
            let wrapper = PDFDocumentWrapper(document: pdfDocument, url: url)
            documents.append(wrapper)
            if selectedDocumentId == nil {
                selectedDocumentId = wrapper.id
            }
        }
    }
}

private func showErrorAlert(message: String) {
    let alert = NSAlert()
    alert.messageText = "Error"
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}
```

- [ ] **Step 2: Add error handling for save**

```swift
// Update save method in AppViewModel.swift
func save() {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    let success = wrapper.document.write(to: wrapper.url)
    if success {
        wrapper.isModified = false
    } else {
        showErrorAlert(message: "Failed to save file. Please try Save As.")
    }
}

func saveAs() {
    guard let selectedId = selectedDocumentId,
          let wrapper = documents.first(where: { $0.id == selectedId }) else { return }
    
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.pdf]
    panel.nameFieldStringValue = wrapper.fileName
    
    if panel.runModal() == .OK, let url = panel.url {
        let success = wrapper.document.write(to: url)
        if success {
            wrapper.isModified = false
        } else {
            showErrorAlert(message: "Failed to save file.")
        }
    }
}
```

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

Expected: Build succeeded

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "feat: add keyboard shortcuts and error handling"
```

---

## Summary

All chunks complete. The application now supports:
- Tabbed PDF interface
- Hover thumbnail strip
- Delete/Add pages
- Extract as Image/PDF
- Merge PDFs
- Rotate pages
- Save/Save As
- Drag & Drop
- Unsaved changes prompt