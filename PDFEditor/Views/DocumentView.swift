import SwiftUI

struct DocumentView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    
    var body: some View {
        PDFViewerView(wrapper: wrapper)
    }
}