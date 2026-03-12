import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(appViewModel.documents) { wrapper in
                    TabItemView(wrapper: wrapper, isSelected: wrapper.id == appViewModel.selectedDocumentId)
                        .onTapGesture {
                            appViewModel.selectedDocumentId = wrapper.id
                        }
                        .contextMenu {
                            Button("Close") {
                                appViewModel.closeDocument(wrapper)
                            }
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(height: 32)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct TabItemView: View {
    @ObservedObject var wrapper: PDFDocumentWrapper
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Text(wrapper.fileName)
                .font(.system(size: 13))
                .lineLimit(1)
            
            if wrapper.isModified {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 8, height: 8)
            }
            
            Button(action: {
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        .cornerRadius(6)
    }
}