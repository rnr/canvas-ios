import Combine
import SwiftUI
import mobile_offline_downloader_ios
import PDFKit

public struct ContentViewerView: View, Navigatable {

    // MARK: - Injected -

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.openURL) var openURL

    // MARK: - Properties -

    @StateObject var viewModel: ContentViewerViewModel

    init(
        entry: OfflineDownloaderEntry,
        courseDataModel: CourseStorageDataModel,
        onDeleted: ((OfflineDownloaderEntry) -> Void)? = nil
    ) {
        let model = ContentViewerViewModel(
            entry: entry,
            courseDataModel: courseDataModel,
            onDeleted: onDeleted
        )
        self._viewModel = .init(wrappedValue: model)
    }

    // MARK: - Views -

    public var body: some View {
        viewModel.requestType.flatMap { type in
            SUWebView(
                configurator: .init(
                    requestType: type
                ),
                onLinkActivated: onLinkActivated
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.title)
                        .foregroundColor(.white)
                        .font(.semibold16)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.canShare {
                        Button {
                            share()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                        }
                        .foregroundColor(.white)
                    }
                    Button {
                        viewModel.delete()
                    } label: {
                        Image(systemName: "trash.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                    .foregroundColor(.white)
                }
            }
            .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func onLinkActivated(_ url: URL) {
        if url.scheme?.contains("http") == true {
            openURL(url)
        } else if url.scheme?.contains("file") == true {
            guard DocViewerViewController.hasPSPDFKitLicense else {
                webView(for: url)
                return
            }
            let root = DocViewer(
                filename: url.lastPathComponent,
                previewURL: url,
                fallbackURL: url
            )
            let hosting = CoreHostingController(root)
            navigationController?.pushViewController(hosting, animated: true)
        }
    }

    func webView(for url: URL, isLocalURL: Bool = true) {
        let webView = CoreWebViewRepresentable(url: url)
        let hosting = CoreHostingController(webView)
        navigationController?.pushViewController(hosting, animated: true)
    }

    func share() {
        guard case .url(let url) = viewModel.requestType  else {
           return
        }
        let controller = CoreActivityViewController(activityItems: [url], applicationActivities: nil)
        navigationController?.present(controller, animated: true)
    }
}
