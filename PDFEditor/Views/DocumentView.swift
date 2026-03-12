import SwiftUI

struct DocumentView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    @ObservedObject var appViewModel: AppViewModel

    var body: some View {
        PDFViewerView(wrapper: wrapper, appViewModel: appViewModel)
    }
}