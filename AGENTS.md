# PDF Editor - Agent & Developer Guidelines

## Project Overview

This is a production-ready macOS PDF editor application built with **SwiftUI** and **PDFKit**. The project uses **XcodeGen** for build configuration and maintains a document-based interface with multi-tab support, full page manipulation, and image/PDF merging capabilities.

**Current Status**: Fully functional (v1.0.0) with core features implemented and tested.

## Environment & Setup

**Target Platform**: macOS 13.0+  
**Swift Version**: 5.9  
**Xcode Version**: 15.0+  
**Bundle ID**: `com.pdeditor.pdfeditor`

## Build Commands

### Quick Start

```bash
# Generate Xcode project from project.yml (required after any project.yml changes)
xcodegen generate

# Open in Xcode and run (Cmd+R in Xcode)
open PDFEditor.xcodeproj

# Or build from command line
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Release build
```

### Common Commands

```bash
# Clean build
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor clean build

# Build with explicit macOS destination
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug -destination 'platform=macOS' build
```

⚠️ **IMPORTANT**: Do not edit `PDFEditor.xcodeproj` directly. All project configuration is managed through `project.yml`. Always run `xcodegen generate` after modifying `project.yml`.

## Project Structure

```
PDFEditor/
├── PDFEditorApp.swift           # App entry point, .commands (menus/shortcuts)
│
├── ViewModels/
│   └── AppViewModel.swift       # Central state (documents, selections, zoom)
│                                # Nested: PDFDocumentWrapper class
│
├── Views/
│   ├── ContentView.swift        # Root view, drag-drop handler, empty state
│   ├── TabBarView.swift         # Document tabs + thumbnail toggle button
│   ├── DocumentView.swift       # Container view (mostly pass-through)
│   ├── PDFViewerView.swift      # Zoom toolbar, PDF display, thumbnail strip
│   │                            # Nested: PDFKitView, ThumbnailStripView, etc.
│   │
│   └── Services/
│       └── PDFService.swift     # Static utility class for PDF operations
```

## Architecture & Data Flow

### Core Pattern: Document Wrapper

Since `PDFDocument` is not observable, the app uses a **wrapper pattern**:

```swift
class PDFDocumentWrapper: ObservableObject {
    let id: UUID
    var document: PDFDocument
    var url: URL?
    var isModified: Bool

    @Published var documentVersion: Int  // Increment to trigger UI refresh
    @Published var selectedPages: Set<Int>
    @Published var currentPageIndex: Int
}
```

**Key Insight**: After ANY PDF mutation (delete, rotate, add page), increment `wrapper.documentVersion` to trigger SwiftUI re-renders. PDFDocument mutations don't automatically notify SwiftUI.

### State Management Flow

```
PDFEditorApp.swift
    └── @StateObject AppViewModel (app-wide state)
        └── documents: [PDFDocumentWrapper] (all open PDFs)
        └── selectedDocumentId: UUID (current tab)
        └── [various action methods]

                ↓ passed via @EnvironmentObject

ContentView + all subviews
    └── @ObservedObject wrapper (for individual document state)
    └── @Binding selectedPages, currentPageIndex (two-way updates)
```

### View Hierarchy

| View                   | Role                                 | Key Bindings                                   |
| ---------------------- | ------------------------------------ | ---------------------------------------------- |
| **ContentView**        | Root, drag-drop handler, empty state | owns `showThumbnails` state                    |
| **TabBarView**         | Tab strip, thumbnail toggle button   | `@Binding showThumbnails`                      |
| **DocumentView**       | Thin wrapper, passes bindings        | delegates to PDFViewerView                     |
| **PDFViewerView**      | Zoom toolbar, PDF display            | owns `zoomLevel` state, conditional thumbnails |
| **ThumbnailStripView** | Lazy-loaded thumbnails               | shows selected pages, context menu             |

## Implemented Features

✅ **Document Management**

- Open single/multiple PDFs via file dialog or drag-drop
- Tabbed interface with document tabs
- Close documents with unsaved changes prompt
- Save/Save As functionality

✅ **Page Operations**

- Delete single or multi-selected pages
- Add blank pages
- Add pages from images (PNG, JPEG, TIFF, HEIC)
- Add pages from PDFs (with page range selection)
- Rotate pages (90° clockwise/counterclockwise)
- Extract selected pages as PDF
- Extract selected pages as images (PNG/JPEG)
- Merge multiple PDFs into one

✅ **Viewing & Navigation**

- Zoom in/out, fit to window, actual size (100%)
- Thumbnail strip with lazy loading
- Multi-page selection via Cmd+Click
- Current page tracking

✅ **Keyboard Shortcuts**

- Cmd+O: Open
- Cmd+S: Save
- Cmd+Shift+S: Save As
- Cmd+W: Close Document
- Cmd+Delete: Delete Selected Pages
- Cmd+A: Select All Pages
- Cmd++: Zoom In
- Cmd+-: Zoom Out
- Cmd+0: Actual Size (100%)
- Cmd+9: Fit to Window

❌ **Not Implemented (but designed for)**

- Undo/Redo
- Open Recent menu
- 180° rotation (only 90°/−90°)
- Window size enforcement (800×600 minimum)
- Hover-activated thumbnail strip auto-hide

## Code Style & Conventions

### Imports

Group by framework, greatest breadth to narrowest:

```swift
import SwiftUI
import PDFKit
import AppKit
import Foundation
import UniformTypeIdentifiers
```

### Type Definitions

- **Classes**: Use for `ObservableObject` with `@Published` properties (AppViewModel, PDFDocumentWrapper)
- **Structs**: Use for views and simple value types
- **Enums**: Use for fixed sets (zoom modes, file filter types, etc.)

### Naming Rules

| Category             | Convention       | Examples                                                  |
| -------------------- | ---------------- | --------------------------------------------------------- |
| Type names           | PascalCase       | `AppViewModel`, `PDFViewerView`, `PDFDocumentWrapper`     |
| Variables/properties | camelCase        | `selectedDocumentId`, `showThumbnails`, `documentVersion` |
| Functions            | camelCase + verb | `openDocument()`, `deletePage(at:)`, `saveAs()`           |
| Constants            | camelCase        | `thumbnailSize = 100`, `defaultZoom = 1.0`                |
| File names           | Match main type  | `AppViewModel.swift`, `PDFService.swift`                  |

### Formatting

- **Indentation**: 4 spaces (Xcode default)
- **Line length**: Under 120 characters preferred
- **Blank lines**: Single blank line between logical sections
- **Braces**: Opening brace on same line `func foo() {`

### Property Attributes

```swift
// For observable state in ViewModels
@Published var property: Type

// For UI state in Views
@State private var property: Type

// For received bindings in Views
@Binding var property: Type

// For references to ObservableObject
@ObservedObject var wrapper: PDFDocumentWrapper

// For app-wide state
@EnvironmentObject var viewModel: AppViewModel
```

### Error Handling & Safety

```swift
// Early returns for invalid conditions
guard let document = selectedDocument else { return }
guard !selectedPages.isEmpty else { return }

// Optional binding for optional values
if let wrapper = selectedDocument {
    // Use wrapper
}

// Retain cycle prevention in closures
panel.begin { [weak self] response in
    self?.handleResponse(response)
}

// Main thread UI updates after background work
DispatchQueue.main.async {
    self?.updateUI()
}
```

### PDF Mutations & UI Updates

Always increment `documentVersion` after mutation:

```swift
func deletePage(at index: Int) {
    guard let wrapper = selectedDocument else { return }
    _ = PDFService.deletePages(from: wrapper.document, indices: [index])
    wrapper.documentVersion += 1  // ← Trigger UI refresh
    wrapper.isModified = true
}
```

## Common Patterns

### Opening a Document

```swift
func openDocument() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.pdf]

    panel.begin { [weak self] response in
        guard response == .OK else { return }
        DispatchQueue.main.async {
            self?.processSelectedURLs(panel.urls)
        }
    }
}
```

### Deleting Pages (triggers UI update)

```swift
func deletePage(at index: Int) {
    guard let wrapper = selectedDocument else { return }
    _ = PDFService.deletePages(from: wrapper.document, indices: [index])
    wrapper.documentVersion += 1  // Triggers SwiftUI update
    wrapper.isModified = true
}
```

### Context Menu in SwiftUI

```swift
.contextMenu {
    Button("Delete") {
        appViewModel.deletePage(at: pageIndex)
    }
}
```

## Known Limitations & Quirks

⚠️ **Important**: Be aware of these implementation details when modifying the code:

1. **PDFPage Copy Failures**: `page.copy() as? PDFPage` can silently fail during PDF operations. The code handles this with guards, but ensure page operations are properly validated.

2. **Zoom Level Duplication**: `appViewModel.zoomLevel` exists but isn't actively used; `PDFViewerView` maintains its own local `@State zoomLevel`. Consider consolidating to AppViewModel if you need zoom to persist across documents.

3. **Save As URL Not Updated**: After "Save As", `wrapper.url` isn't updated, causing subsequent saves to potentially go to the old location. This currently works by accident—fix by updating `wrapper.url` after successful SaveAs dialog.

4. **Thumbnail Loading State**: Thumbnails load synchronously on `onAppear` and when `documentVersion` changes, but there's no visual loading indicator. Thumbnails briefly show gray placeholders.

5. **Drag-Drop Fallback**: The drag-drop handler attempts `.pdf` UTType first, then falls back to `.fileURL`. The fallback path doesn't validate file extensions.

6. **Modal Dialog Threading**: All dialogs (NSOpenPanel, NSSavePanel, NSAlert) use `.begin` or `.runModal()` which can block the main thread briefly. Consider background task wrapping for large operations.

## Troubleshooting

### Project Won't Build After Editing project.yml

```bash
# Regenerate from project.yml
xcodegen generate

# Then try building again
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
```

### Thumbnails Not Updating

Ensure you increment `documentVersion` after PDF mutations:

```swift
wrapper.documentVersion += 1  // Must increment to trigger SwiftUI re-render
```

### Save Changes Dialog Not Appearing

Check that `wrapper.isModified` is set to `true` after document changes:

```swift
func deleteSelectedPages() {
    // ... deletion logic ...
    wrapper.isModified = true  // Required for save prompt
    wrapper.documentVersion += 1
}
```

### Zoom Not Working Correctly

Verify PDFKitView is using `pdfView.scaleFactorAttributedString` and notifying AppViewModel via Coordinator pattern.

## Testing

- **No formal test suite** currently in place
- **Manual testing**: Open `PDFEditor.xcodeproj` in Xcode, press Cmd+R
- **Test PDF files**: Use sample PDFs of various page counts and sizes
- **Debugger**: Use Xcode's debugger to step through PDF operations
- **Memory profiling**: Use Instruments to verify no retain cycles in closures

## Important Notes

1. **SwiftUI Reactivity**: Since `PDFDocument` is not `@Published`, use a separate `@Published var documentVersion: Int` counter to trigger UI refreshes when the document changes.

2. **Memory Management**: Always use `[weak self]` in closures that might capture `self`.

3. **Thread Safety**: PDFKit operations should be on main thread for UI updates; use `DispatchQueue.main.async` after background work.

4. **Menu Keyboard Shortcuts**: Define in `PDFEditorApp.swift` using `.keyboardShortcut()` modifier.

5. **XcodeGen**: This project uses `project.yml` for Xcode generation. Do not edit the .xcodeproj directly.
