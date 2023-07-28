import Combine
import SwiftUI
import mobile_offline_downloader_ios
import SafariServices

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
                ToolbarItem(placement: .navigationBarTrailing) {
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
            let config = SFSafariViewController.Configuration()
                  config.entersReaderIfAvailable = true
            let vc = SFSafariViewController(url: url, configuration: config)
            navigationController?.present(vc, animated: true)
        }
    }
}
