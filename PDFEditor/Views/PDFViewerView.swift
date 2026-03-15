import SwiftUI
import PDFKit

struct PDFViewerView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    @ObservedObject var appViewModel: AppViewModel
    @State private var zoomLevel: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            zoomToolbar
            Divider()

            HStack(spacing: 0) {
                if appViewModel.showThumbnails {
                    ThumbnailStripView(
                        wrapper: wrapper,
                        currentPage: $wrapper.currentPageIndex,
                        selectedPages: $wrapper.selectedPages
                    )
                    .frame(width: 120)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                    .environmentObject(appViewModel)
                }

                PDFKitView(document: wrapper.document, zoomLevel: $zoomLevel, currentPage: $wrapper.currentPageIndex)
                    .clipped()
            }
        }
    }

    private var zoomToolbar: some View {
        HStack {
            Button(action: { zoomLevel = max(0.25, zoomLevel - 0.25) }) {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            
            Text("\(Int(zoomLevel * 100))%")
                .font(.system(size: 12, weight: .medium))
                .frame(width: 50)
            
            Button(action: { zoomLevel = min(4.0, zoomLevel + 0.25) }) {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            
            Divider()
                .frame(height: 16)
                .padding(.horizontal, 8)
            
            Button(action: { zoomLevel = 1.0 }) {
                Text("Fit")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            if !wrapper.selectedPages.isEmpty {
                Text("\(wrapper.selectedPages.count) selected")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private var currentPageIndex: Int {
        return wrapper.currentPageIndex
    }
}

struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    @Binding var zoomLevel: CGFloat
    @Binding var currentPage: Int
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = NSColor.controlBackgroundColor
        pdfView.scaleFactor = zoomLevel
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pdfViewChangedScale(_:)),
            name: .PDFViewScaleChanged,
            object: pdfView
        )
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pdfViewChangedPage(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )
        
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        if abs(pdfView.scaleFactor - zoomLevel) > 0.01 {
            pdfView.scaleFactor = zoomLevel
        }
        
        if let page = document.page(at: currentPage) {
            pdfView.go(to: page)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PDFKitView
        
        init(_ parent: PDFKitView) {
            self.parent = parent
        }
        
        @objc func pdfViewChangedScale(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }
            DispatchQueue.main.async {
                self.parent.zoomLevel = pdfView.scaleFactor
            }
        }
        
        @objc func pdfViewChangedPage(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView else { return }
            if let currentPage = pdfView.currentPage {
                DispatchQueue.main.async {
                    self.parent.currentPage = pdfView.document!.index(for: currentPage)
                }
            }
        }
    }
}

struct ThumbnailStripView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    @Binding var currentPage: Int
    @Binding var selectedPages: Set<Int>
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<wrapper.document.pageCount, id: \.self) { index in
                    ThumbnailItem(
                        wrapper: wrapper,
                        pageIndex: index,
                        isSelected: index == currentPage || selectedPages.contains(index),
                        isMultiSelected: selectedPages.contains(index)
                    )
                    .onTapGesture {
                        currentPage = index
                    }
                }
            }
            .padding(8)
        }
    }
}

struct ThumbnailItem: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    let pageIndex: Int
    let isSelected: Bool
    let isMultiSelected: Bool
    
    @State private var thumbnailImage: NSImage?
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            if let thumbnail = thumbnailImage {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected || isMultiSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(0.707, contentMode: .fit)
                    .frame(maxWidth: 100)
                    .cornerRadius(4)
            }
            
            Text("\(pageIndex + 1)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .onAppear {
            loadThumbnail()
        }
        .onChange(of: wrapper.documentVersion) { _ in
            loadThumbnail()
        }
        .contextMenu {
            Button("Delete") {
                appViewModel.deletePage(at: pageIndex)
            }
            
            Divider()
            
            Button("Extract as Image...") {
                appViewModel.extractAsImage(from: pageIndex)
            }
            
            Button("Extract as PDF...") {
                appViewModel.extractPagesAsPDF(indices: [pageIndex])
            }
            
            Divider()
            
            Button("Rotate 90° Clockwise") {
                appViewModel.rotatePage(at: pageIndex, degrees: 90)
            }
            
            Button("Rotate 90° Counter-clockwise") {
                appViewModel.rotatePage(at: pageIndex, degrees: -90)
            }
        }
    }
    
    private func loadThumbnail() {
        guard let page = wrapper.document.page(at: pageIndex) else { return }
        
        let thumbnailSize = NSSize(width: 100, height: 141)
        let thumbnail = page.thumbnail(of: thumbnailSize, for: .mediaBox)
        thumbnailImage = thumbnail
    }
}