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

import Combine
import SwiftUI

public struct DownloadsView: View {

    // MARK: - Injected -

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.viewController) var controller

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsViewModel = .init()
    @State var isDisplayingAlert: Bool = false
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

    var isSheet: Bool = false

    public init() {}

    // MARK: - Views -

    public var body: some View {
        content
            .accentColor(Color(Brand.shared.linkColor))
            .onAppear {
                navigationController?.navigationBar.useGlobalNavStyle()
                hideDownloadingBarView()
            }
            .onChange(of: viewModel.error) { newValue in
                if newValue.isEmpty { return }
                navigationController?.showAlert(
                    title: NSLocalizedString(newValue, comment: ""),
                    actions: [AlertAction(NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in }],
                    style: .actionSheet
                )
                viewModel.error = ""
            }
    }

    private var content: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            switch viewModel.state {
            case .none, .loading:
                LoadingView()
            case .loaded, .updated:
                VStack {
                    if viewModel.isEmpty {
                        VStack {
                            Image.pandaBlocks
                            Text("No Courses")
                                .font(.semibold17)
                                .foregroundColor(.textDarkest)
                            Text("Visit a course to download content.")
                                .font(.regular16)
                                .foregroundColor(.textDarkest)
                        }
                    } else {
                        list
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Downloads")
                    .foregroundColor(.white)
                    .font(.semibold16)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                deleteAllButton
            }
        }
    }

    private var list: some View {
        List {
            if !viewModel.downloadingModules.isEmpty {
                if viewModel.downloadingModules.count > 3 {
                    LinkDownloadingHeader(
                        destination: DownloaderView(
                            downloadingModules: viewModel.downloadingModules
                        ),
                        title: "Downloading"
                    )
                } else {
                    Header(title: "Downloading")
                }
                modules
            }
            Header(title: "Courses")
                .hidden(viewModel.courseViewModels.isEmpty )
            courses
        }
        .listStyle(.inset)
        .background(Color.backgroundLightest.ignoresSafeArea())
    }

    private var modules: some View {
        DownloadProgressSectionView(viewModel: viewModel)
            .listRowInsets(EdgeInsets())
            .iOS15ListRowSeparator(.hidden)
    }

    private var courses: some View {
        DownloadCoursesSectionView(viewModel: viewModel)
            .listRowInsets(EdgeInsets())
            .iOS15ListRowSeparator(.hidden)
    }

    private var deleteAllButton: some View {
        Button("Delete all") {
            let cancelAction = AlertAction(NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in }
            let deleteAction = AlertAction(NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
                viewModel.deleteAll()
            }
            controller.value.showAlert(
                title: NSLocalizedString("Are you sure you want to remove all downloaded content?", comment: ""),
                actions: [cancelAction, deleteAction],
                style: .actionSheet
            )
        }
        .foregroundColor(.white)
        .hidden(viewModel.isEmpty)
    }

    private func hideDownloadingBarView() {
        guard let downloadingBarView = controller.value.tabBarController?.view.subviews.first(
            where: { $0 is DownloadingBarView }) as? DownloadingBarView
        else {
            return
        }
        downloadingBarView.hidden()
    }
}
