import SwiftUI

struct DocumentView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    @Binding var showThumbnails: Bool
    
    var body: some View {
        PDFViewerView(wrapper: wrapper, showThumbnails: $showThumbnails)
    }
}