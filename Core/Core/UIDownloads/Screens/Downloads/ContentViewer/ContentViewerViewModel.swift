import Combine
import SwiftUI
import mobile_offline_downloader_ios

public class ContentViewerViewModel: ObservableObject {

    private let downloadsManager = OfflineDownloadsManager.shared
    private let entry: OfflineDownloaderEntry
    private let courseDataModel: CourseStorageDataModel
    private var deleteSubscriber: AnyCancellable?

    var viewDismissalModePublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismissView = false {
        didSet {
            viewDismissalModePublisher.send(shouldDismissView)
        }
    }

    var onDeleted: ((OfflineDownloaderEntry) -> Void)?

    init(
        entry: OfflineDownloaderEntry,
        courseDataModel: CourseStorageDataModel,
        onDeleted: ((OfflineDownloaderEntry) -> Void)? = nil
    ) {
        self.entry = entry
        self.courseDataModel = courseDataModel
        self.onDeleted = onDeleted
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
                guard let self = self else {
                    return
                }
                if case .statusChanged(object: let event) = event {
                    if case .removed = event.status,
                        let eventObjectId = try? event.object.toOfflineModel().id {
                        self.shouldDismissView = true
                        onDeleted?(entry)
                    }
                }
            }
    }
}
