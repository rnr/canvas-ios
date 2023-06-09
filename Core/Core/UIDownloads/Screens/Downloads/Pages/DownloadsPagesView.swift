//
// This file is part of Canvas.
// Copyright (C) 2023-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import SwiftUI
import mobile_offline_downloader_ios

final class DownloadsPagesViewModel: ObservableObject {

    let courseDataModel: CourseStorageDataModel
    let pages: [Page]

    init(pages: [Page], courseDataModel: CourseStorageDataModel) {
        self.pages = pages
        self.courseDataModel = courseDataModel
    }

}

struct DownloadsPagesView: View {

    // MARK: - Injected -

    @Environment(\.viewController) var controller

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsPagesViewModel
    private let env = AppEnvironment.shared

    private var navigationController: UINavigationController? {
        guard let topViewController = env.topViewController as? UITabBarController,
              let helmSplitViewController = topViewController.viewControllers?.first as? UISplitViewController,
              let navigationController = helmSplitViewController.viewControllers.first as? UINavigationController
             else {
            return nil
        }
        return navigationController
    }

    init(pages: [Page], courseDataModel: CourseStorageDataModel) {
        let viewModel = DownloadsPagesViewModel(
            pages: pages,
            courseDataModel: courseDataModel
        )
        self._viewModel = .init(wrappedValue: viewModel)
    }

    // MARK: - Views -

    var body: some View {
        content
            .onAppear {
                navigationController?.navigationBar.useGlobalNavStyle()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Pages")
                        .foregroundColor(.white)
                        .font(.semibold16)
                }
            }
    }

    private var content: some View {
        DownloadsContentList {
            ForEach(viewModel.pages, id: \.self) { page in
                DownloadsPageCellView(
                    viewModel: DownloadsPageCellViewModel(page: page)
                ).onTapGesture {
                    destination(page: page)
                }
                Divider()
            }
        }
    }

    private func destination(page: Page) {
        OfflineDownloadsManager.shared.savedEntry(for: page) { result in
            result.success { entry in
                navigationController?.navigationBar.useGlobalNavStyle()
                navigationController?.pushViewController(
                    CoreHostingController(
                        ContentViewerView(
                            entry: entry,
                            courseDataModel: viewModel.courseDataModel
                        )
                    ),
                    animated: true
                )
            }
        }
    }
}
