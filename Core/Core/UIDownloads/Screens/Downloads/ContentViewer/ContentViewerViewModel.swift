import Combine
import SwiftUI
import mobile_offline_downloader_ios

public class ContentViewerViewModel: ObservableObject {

    private let downloadsManager = OfflineDownloadsManager.shared
    private let entry: OfflineDownloaderEntry
    private var deleteSubscriber: AnyCancellable?

    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }

    init(entry: OfflineDownloaderEntry) {
        self.entry = entry
    }

    var requestType: WebViewConfigurator.RequestType? {
        let value = OfflineDownloadsManager.shared.savedValue(for: entry, pageIndex: .zero)
        switch value {
        case let .html(indexURL, folderURL):
            return .indexURL(indexURL, folderURL)
        case let .localURL(url):
            return .url(url)
        case .unknown:
            return nil
        }
    }

    public func delete() {
        do {
            observeDownloadsEvents()
            try downloadsManager.delete(entry: entry)
        } catch {
            print(error.localizedDescription)
        }
    }

    func observeDownloadsEvents() {
        deleteSubscriber = downloadsManager
            .publisher
            .sink { [weak self] event in
                if case .statusChanged(object: let event) = event {
                    if case .removed = event.status {
                        self?.shouldDismissView = true
                    }
                }
            }
    }
}
