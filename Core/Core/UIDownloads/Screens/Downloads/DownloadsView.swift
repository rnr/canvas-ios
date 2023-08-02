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

public struct DownloadsView: View, Navigatable, DownloadsProgressBarHidden {

    // MARK: - Injected -

    @Environment(\.viewController) var controller: WeakViewController

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsViewModel = .init()
    @State var isDisplayingAlert: Bool = false

    var isSheet: Bool = false

    public init() {}

    // MARK: - Views -

    public var body: some View {
        content
            .accentColor(Color(Brand.shared.linkColor))
            .onAppear {
                navigationController?.navigationBar.useGlobalNavStyle()
                toggleDownloadingBarView(hidden: true)
            }
            .onDisappear {
                toggleDownloadingBarView(hidden: false)
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
            Color.backgroundLightest
                .ignoresSafeArea()
            switch viewModel.state {
            case .none, .loading:
                LoadingView()
            case .loaded, .deleting, .updated:
                VStack {
                    if viewModel.isEmpty {
                        VStack {
                            Image.pandaBlocks
                            Text("No Downloads")
                                .font(.semibold18)
                                .foregroundColor(.textDarkest)
                                .padding(.vertical, 20)
                            Text("To download content, open a content type and press save. Downloaded modules will appear here")
                                .font(.regular16)
                                .foregroundColor(.textDarkest)
                                .multilineTextAlignment(.center)
                        }
                        .background(Color.backgroundLightest)
                    } else {
                        list
                    }
                }
            }
            if viewModel.state == .deleting {
                LoadingDarkView()
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
        .background(Color.backgroundLightest)
    }

    private var list: some View {
        List {
            if !viewModel.downloadingModules.isEmpty {
                modules
                    .isHidden(!viewModel.isConnected)
            }
            courses
                .isHidden(viewModel.courseViewModels.isEmpty)
        }
        .listRowBackground(Color.backgroundLightest)
        .listStyle(.inset)
        .listSystemBackgroundColor()
    }

    private var modules: some View {
        SwiftUI.Group {
            if viewModel.downloadingModules.count > 3 {
                LinkDownloadingHeader(
                    destination: DownloaderView(
                        downloadingModules: viewModel.downloadingModules
                    ),
                    title: "Downloading"
                )
                .background(Color.backgroundLightest)
            } else {
                Header(title: "Downloading")
            }
            DownloadProgressSectionView(viewModel: viewModel)
        }
        .listRowBackground(Color.backgroundLightest)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }

    private var courses: some View {
        SwiftUI.Group {
            Header(title: "Courses")
            DownloadCoursesSectionView(viewModel: viewModel)
        }
        .listRowBackground(Color.backgroundLightest)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
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
}
