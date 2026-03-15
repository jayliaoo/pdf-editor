# PDF Editor

A clean, native macOS PDF editor built with SwiftUI and PDFKit.

## Features

### Document Management
- Open single or multiple PDF files
- Tabbed interface for working with multiple documents
- Drag & drop support for opening files
- Save and Save As functionality
- Close with unsaved changes prompt

### Page Operations
- **Delete pages** - Remove single or multiple selected pages
- **Add blank pages** - Insert new blank pages
- **Add from images** - Import PNG, JPEG, TIFF, or HEIC images as pages
- **Add from PDFs** - Import pages from other PDF files with page range selection
- **Rotate pages** - Rotate 90° clockwise or counterclockwise
- **Extract pages** - Save selected pages as a new PDF or as images
- **Merge PDFs** - Combine multiple PDFs into a single document

### Viewing & Navigation
- Zoom in/out with toolbar controls
- Fit to window or view at actual size (100%)
- Thumbnail strip for quick page navigation
- Multi-select pages with ⌘+Click
- Current page indicator

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| ⌘O | Open PDF |
| ⌘S | Save |
| ⌘⇧S | Save As |
| ⌘W | Close Document |
| ⌘Delete | Delete Selected Pages |
| ⌘A | Select All Pages |
| ⌘+ | Zoom In |
| ⌘- | Zoom Out |
| ⌘0 | Actual Size (100%) |
| ⌘9 | Fit to Window |

## Requirements

- macOS 13.0 or later
- Xcode 15.0+ (for building from source)

## Installation

### Option 1: Download Release
Download the latest release from the [Releases](../../releases) page.

### Option 2: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/pdf-editor.git
   cd pdf-editor
   ```

2. Install XcodeGen (if not already installed):
   ```bash
   brew install xcodegen
   ```

3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

4. Open in Xcode:
   ```bash
   open PDFEditor.xcodeproj
   ```

5. Build and run (⌘R in Xcode)

## Usage

### Opening PDFs
- **File menu**: File → Open (⌘O)
- **Drag & drop**: Drag PDF files directly into the app window
- **Multiple files**: Select multiple PDFs in the open dialog to open them in separate tabs

### Selecting Pages
- Click a page thumbnail to select it
- ⌘+Click to select multiple pages
- ⌘A to select all pages

### Editing Pages
1. Select one or more pages in the thumbnail strip
2. Use toolbar buttons or right-click context menu
3. Available actions:
   - Delete selected pages
   - Rotate left/right
   - Extract as PDF
   - Extract as images

### Adding Pages
- **Blank page**: Edit → Add Blank Page
- **From image**: Edit → Add Page from Image
- **From PDF**: Edit → Add Page from PDF

### Saving
- **Save (⌘S)**: Saves changes to the existing file
- **Save As (⌘⇧S)**: Save to a new file

## Project Structure

```
PDFEditor/
├── PDFEditorApp.swift        # App entry point
├── ViewModels/
│   └── AppViewModel.swift    # Central state management
├── Views/
│   ├── ContentView.swift     # Root view
│   ├── TabBarView.swift      # Document tabs
│   ├── DocumentView.swift    # Document container
│   ├── PDFViewerView.swift   # PDF display & zoom controls
│   └── Services/
│       └── PDFService.swift  # PDF operations
└── Resources/
    └── Assets.xcassets       # App icons and colors
```

## Technology Stack

- **SwiftUI** - Modern declarative UI framework
- **PDFKit** - Apple's native PDF rendering engine
- **AppKit** - Native macOS integration
- **XcodeGen** - Project file generation

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

Built with Apple's native frameworks for optimal performance and seamless macOS integration.