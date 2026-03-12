import SwiftUI

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