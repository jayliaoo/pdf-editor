import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            if !appViewModel.documents.isEmpty {
                TabBarView(appViewModel: appViewModel)
                    .zIndex(1)
                Divider()
            }

            if appViewModel.documents.isEmpty {
                emptyStateView
            } else if let selectedId = appViewModel.selectedDocumentId,
                      let wrapper = appViewModel.documents.first(where: { $0.id == selectedId }) {
                DocumentView(wrapper: wrapper, appViewModel: appViewModel)
            }
        }
        .onDrop(of: [.pdf, .fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, error in
                guard error == nil else { return }

                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        appViewModel.handleDroppedFiles([url])
                    }
                } else if let url = item as? URL {
                    DispatchQueue.main.async {
                        appViewModel.handleDroppedFiles([url])
                    }
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