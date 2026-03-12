# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Generate Xcode project (after modifying project.yml)
xcodegen generate

# Build debug/release
xcodebuild -project PDFEditor.xcodeproj -scheme PDFEditor -configuration Debug build

# Run via Xcode
open PDFEditor.xcodeproj
```

## Architecture Overview

This is a SwiftUI macOS PDF editor using PDFKit. The app uses a **wrapper pattern** for documents since `PDFDocument` is not `ObservableObject`.

### Data Flow

```
PDFEditorApp.swift
    └── @StateObject AppViewModel  (app-wide state)

ContentView.swift
    ├── TabBarView.swift           (toolbar + document tabs)
    └── DocumentView.swift
        └── PDFViewerView.swift    (PDF display + thumbnails)
```

### Key Architecture Patterns

**Document Wrapper (`PDFDocumentWrapper`)**: Wraps `PDFDocument` and adds `@Published` properties for SwiftUI reactivity:
- `documentVersion: Int` - Increment to trigger UI refresh after PDF mutations
- `selectedPages: Set<Int>` - Tracks multi-page selection
- `currentPageIndex: Int` - Current viewing position

**State Management**: `AppViewModel` is the central `ObservableObject` passed via `@EnvironmentObject`. It manages:
- `documents: [PDFDocumentWrapper]` - Open documents
- `selectedDocumentId: UUID` - Currently selected tab

**Menu Commands**: Defined in `PDFEditorApp.swift` using the `.commands` modifier with `CommandGroup(replacing:)` and `CommandMenu`.

**PDF Mutations**: All PDF modifications go through `PDFService` (static utility class). After mutations, always increment `wrapper.documentVersion` to trigger SwiftUI updates.

### View Hierarchy

1. **ContentView** - Root view, handles drag-drop, owns `showThumbnails` state
2. **TabBarView** - Top toolbar with thumbnail toggle + tab scrolling
3. **DocumentView** - Passes bindings to PDFViewerView
4. **PDFViewerView** - Contains zoom toolbar, PDFKitView, and conditional ThumbnailStripView