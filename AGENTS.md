# PDF Editor - Agent Guidelines

## Project Overview

This is a macOS PDF editor application built with SwiftUI and PDFKit. The project uses XcodeGen for build configuration.

## Build Commands

### Generate Xcode Project
```bash
xcodegen generate
```

### Build the Project
```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Release build
```

### Run the App
Open `PDFEditor.xcodeproj` in Xcode and press Cmd+R, or:
```bash
open PDFEditor.xcodeproj
```

### Build with Specific Destination
```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug -destination 'platform=macOS' build
```

### Clean Build
```bash
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor clean
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor build
```

## Project Structure

```
PDFEditor/
├── PDFEditorApp.swift       # App entry point, menu commands
├── ViewModels/
│   └── AppViewModel.swift   # Main app state, document management
├── Views/
│   ├── ContentView.swift    # Root view, drag-drop handling
│   ├── DocumentView.swift   # Document container
│   ├── PDFViewerView.swift  # PDF display, thumbnails, zoom
│   └── TabBarView.swift     # Document tabs, thumbnail toggle
├── Services/
│   └── PDFService.swift     # PDF manipulation utilities
```

## Code Style Guidelines

### Imports
- Group imports by framework: SwiftUI, PDFKit, AppKit, Foundation
- Use specific imports rather than importing entire modules when possible
```swift
import SwiftUI
import PDFKit
import AppKit
import UniformTypeIdentifiers
```

### Types
- Use SwiftUI `@State`, `@Binding`, `@StateObject`, `@ObservedObject` appropriately
- Use `ObservableObject` for classes that need to publish changes
- Use `PDFDocument` from PDFKit for PDF handling
- Use `NSOpenPanel`/`NSSavePanel` for file dialogs
- Use `NSAlert` for modal alerts

### Naming Conventions
- Types: PascalCase (e.g., `AppViewModel`, `PDFViewerView`)
- Properties/Variables: camelCase (e.g., `selectedDocumentId`, `showThumbnails`)
- Functions: camelCase starting with verb (e.g., `openDocument()`, `deletePage()`)
- Constants: camelCase with meaningful names (e.g., `thumbnailSize`)
- File names: PascalCase matching the main type (e.g., `AppViewModel.swift`)

### Formatting
- Indent: 4 spaces (matching Xcode defaults)
- Line length: Generally under 120 characters
- Empty lines: Single blank line between logical sections
- Braces: Same-line opening brace for functions and types

### Access Control
- Use `private` for internal implementation details
- Use `@Binding` for two-way data flow in SwiftUI
- Use `@Published` for ObservableObject properties that need to trigger UI updates

### Error Handling
- Use `guard` statements for early returns on invalid conditions
- Display user-facing errors via `NSAlert` or `@Published errorMessage`
- Use optional binding (`guard let`, `if let`) for optional values
- Handle async operations with `[weak self]` to prevent retain cycles

### SwiftUI Best Practices
- Use `@ObservedObject` for references to `ObservableObject`
- Use `@EnvironmentObject` for app-wide shared state
- Avoid storing PDFDocument directly in @State (use wrapper class)
- Use `@Published` wrapper property to trigger SwiftUI re-renders

### PDF Manipulation
- Use `PDFService` as a static utility class for PDF operations
- Use `PDFDocument` for loading/saving PDFs
- Use `PDFPage` for page-level operations (rotate, extract)
- Remember to call `document.write(to:)` to persist changes

### Menu Commands
- Define in `PDFEditorApp.swift` using `.commands` modifier
- Use `CommandGroup(replacing:)` to override standard menus
- Use `CommandMenu` for custom menus
- Always check `appViewModel.selectedDocument` for nil before enabling document-specific commands

### Thumbnails
- Use `PDFPage.thumbnail(of:for:)` to generate thumbnails
- Use `LazyVStack` in thumbnail strip for performance
- Trigger thumbnail reload via `@Published` property changes

### Testing
- No formal test suite currently in place
- Manual testing via Xcode's debugger
- Test PDF operations with sample PDF files

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

## Important Notes

1. **SwiftUI Reactivity**: Since `PDFDocument` is not `@Published`, use a separate `@Published var documentVersion: Int` counter to trigger UI refreshes when the document changes.

2. **Memory Management**: Always use `[weak self]` in closures that might capture `self`.

3. **Thread Safety**: PDFKit operations should be on main thread for UI updates; use `DispatchQueue.main.async` after background work.

4. **Menu Keyboard Shortcuts**: Define in `PDFEditorApp.swift` using `.keyboardShortcut()` modifier.

5. **XcodeGen**: This project uses `project.yml` for Xcode generation. Do not edit the .xcodeproj directly.