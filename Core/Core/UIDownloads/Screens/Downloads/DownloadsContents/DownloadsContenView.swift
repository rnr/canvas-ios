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

struct DownloadsContenView: View {

    // MARK: - Injected -

    @Environment(\.viewController) var controller
    @Environment(\.presentationMode) private var presentationMode

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsContentViewModel
    private let title: String
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

    init(
        content: [OfflineDownloaderEntry],
        courseDataModel: CourseStorageDataModel,
        title: String,
        onDeleted: ((OfflineDownloaderEntry) -> Void)? = nil,
        onDeletedAll: (() -> Void)? = nil
    ) {
        let viewModel = DownloadsContentViewModel(
            content: content,
            courseDataModel: courseDataModel,
            onDeleted: onDeleted,
            onDeletedAll: onDeletedAll
        )
        self._viewModel = .init(wrappedValue: viewModel)
        self.title = title
    }

    // MARK: - Views -

    var body: some View {
        content
            .onAppear {
                navigationController?.navigationBar.useGlobalNavStyle()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.semibold16)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    deleteAllButton
                }
            }
    }

    private var content: some View {
        DownloadsContentList {
            ForEach(viewModel.content, id: \.dataModel.id) { entry in
                VStack(spacing: 0) {
                    DownloadsContentCellView(
                        viewModel: DownloadsModuleCellViewModel(entry: entry)
                    ).onTapGesture {
                        destination(entry: entry)
                    }
                    Divider()
                }
            }
            .onDelete { indexSet in
                viewModel.swipeDelete(indexSet: indexSet)
            }
        }
    }

    private var deleteAllButton: some View {
        Button("Delete all") {
            let cancelAction = AlertAction(NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in }
            let deleteAction = AlertAction(NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
                viewModel.deleteAll()
                presentationMode.wrappedValue.dismiss()
            }
            navigationController?.showAlert(
                title: NSLocalizedString("Are you sure you want to remove content?", comment: ""),
                actions: [cancelAction, deleteAction],
                style: .actionSheet
            )
        }
        .foregroundColor(.white)
    }

    private func destination(entry: OfflineDownloaderEntry) {
        navigationController?.navigationBar.useGlobalNavStyle()
        navigationController?.pushViewController(
            CoreHostingController(
                ContentViewerView(
                    entry: entry,
                    courseDataModel: viewModel.courseDataModel,
                    onDeleted: viewModel.delete
                )
            ),
            animated: true
        )
    }
}
