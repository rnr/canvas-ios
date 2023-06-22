import Combine
import SwiftUI
import mobile_offline_downloader_ios

public struct ContentViewerView: View {

    // MARK: - Injected -

    @Environment(\.presentationMode) private var presentationMode

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
                )
            )
            .toolbar {
                Button {
                    viewModel.delete()
                } label: {
                    Image(systemName: "trash.circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                .foregroundColor(.white)
            }
            .onReceive(viewModel.viewDismissalModePublisher) { shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

}
