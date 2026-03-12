# PDF Editor - Design Specification

## 1. Project Overview

- **Project Name**: PDF Editor
- **Type**: Native macOS Application (SwiftUI)
- **Core Functionality**: A PDF editing application supporting page management (delete, add, extract), PDF merging, and page rotation with a tabbed interface.
- **Target User**: Personal use - functional completeness with simple UI

## 2. UI/UX Specification

### 2.1 Layout Structure

**Single Window with Tabbed Interface**

- **Top**: Tab bar showing open PDF files (like browser tabs)
- **Center**: PDF preview area with zoom and scroll support
- **Hover Zone**: Left edge hover reveals thumbnail strip

**Window Behavior**
- Minimum size: 800x600
- Default size: 1200x800
- Supports window resizing and fullscreen

### 2.2 Visual Design

**Color Palette**
- Primary Background: System background (`Color(.windowBackgroundColor)`)
- Secondary Background: `#F5F5F5` (thumbnail strip)
- Accent: System accent color
- Text Primary: `Color(.labelColor)`
- Text Secondary: `Color(.secondaryLabelColor)`

**Typography**
- System font (SF Pro) - follows macOS system settings
- Tab titles: System font, 13pt
- Menu items: System font, standard macOS sizes

**Spacing**
- Thumbnail size: 150x200 points
- Thumbnail margin: 8pt
- Tab height: 32pt

### 2.3 Components

| Component | States | Behavior |
|-----------|--------|----------|
| Tab | Default, Selected, Hover | Click to switch, drag to reorder |
| Thumbnail | Default, Selected, Hover | Click to select, multi-select with Cmd+Click |
| PDFView | Loading, Loaded, Error | Scroll/zoom support |
| Toolbar | Default | Delete, Add, Extract buttons |

## 3. Functionality Specification

### 3.1 Core Features

| Priority | Feature | Description |
|----------|---------|-------------|
| P0 | Open PDF | Open PDF files via menu or drag-drop |
| P0 | Delete Page | Remove selected pages from PDF |
| P0 | Add Blank Page | Insert blank A4 page at position |
| P0 | Add from Image | Import PNG/JPEG as new page |
| P0 | Add from PDF | Import pages from another PDF |
| P0 | Extract to Image | Export selected page as PNG/JPEG |
| P0 | Extract to PDF | Export selected pages as new PDF |
| P1 | Merge PDF | Combine multiple PDFs into one |
| P1 | Rotate Page | Rotate page 90°/180°/270° |
| P1 | Multi-tab | Open multiple PDFs simultaneously |

### 3.2 User Interactions

**Page Selection**
- Click thumbnail: Select single page
- Cmd+Click: Multi-select pages
- Cmd+A: Select all pages

**Context Menu (Right-click on thumbnail)**
- Delete Page(s)
- Extract as Image
- Extract as PDF
- Rotate 90° Clockwise
- Rotate 90° Counter-clockwise

**Menu Structure**
```
File
  ├── Open... (Cmd+O)
  ├── Open Recent >
  ├── Close (Cmd+W)
  ├── Save (Cmd+S)
  ├── Save As... (Cmd+Shift+S)
  ├── Merge PDFs...
  └── Quit (Cmd+Q)

Edit
  ├── Undo (Cmd+Z)
  ├── Redo (Cmd+Shift+Z)
  ├── Delete Page(s) (Delete key)
  ├── Insert >
  │   ├── Blank Page...
  │   ├── From Image...
  │   └── From PDF...
  └── Select All (Cmd+A)

View
  ├── Zoom In (Cmd++)
  ├── Zoom Out (Cmd+-)
  ├── Actual Size (Cmd+0)
  └── Fit to Window (Cmd+9)

Help
  └── PDF Editor Help
```

### 3.3 Data Handling

- **Document Model**: PDFDocument (PDFKit)
- **Auto-save**: No auto-save, explicit save required
- **File format**: Standard PDF (.pdf)
- **Thumbnail cache**: In-memory, regenerated on page change

### 3.4 Error Handling

| Scenario | Handling |
|----------|----------|
| Invalid file | Show alert: "Unable to open file" |
| Save failed | Show alert with error reason |
| No page selected | Disable delete/extract buttons |
| Empty selection | Show status bar message |

## 4. Technical Specification

### 4.1 Architecture

**Pattern**: MVVM (Model-View-ViewModel)

```
├── Models/
│   ├── PDFDocument+Extensions.swift
│   └── PageThumbnail.swift
├── ViewModels/
│   ├── DocumentViewModel.swift
│   └── AppViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── TabBarView.swift
│   ├── PDFViewerView.swift
│   └── ThumbnailStripView.swift
└── Services/
    └── PDFService.swift
```

### 4.2 Dependencies

- **PDFKit**: Native macOS PDF framework (built-in)
- **SwiftUI**: Native UI framework (built-in)
- No third-party dependencies required

### 4.3 Key APIs

- `PDFKit.PDFDocument`: PDF loading and manipulation
- `PDFKit.PDFView`: PDF rendering and interaction
- `PDFKit.PDFPage`: Individual page operations
- `NSImage`: Image export functionality

## 5. Acceptance Criteria

- [ ] Application launches without errors
- [ ] Can open PDF files via menu and drag-drop
- [ ] Tab bar shows multiple open PDFs
- [ ] Thumbnail strip shows on hover
- [ ] Can delete single and multiple pages
- [ ] Can add blank pages
- [ ] Can add pages from images (PNG, JPEG)
- [ ] Can add pages from other PDFs
- [ ] Can extract pages as images
- [ ] Can extract pages as new PDF
- [ ] Can merge multiple PDFs
- [ ] Can rotate pages
- [ ] Save/Save As works correctly
- [ ] Window resizes properly
- [ ] Keyboard shortcuts work