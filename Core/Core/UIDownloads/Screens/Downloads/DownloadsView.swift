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

    var isSheet: Bool = false

    public init() {}

    // MARK: - Views -

    public var body: some View {
        content
            .accentColor(Color(Brand.shared.linkColor))
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
                            Text("Visit a course to download content.")
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
            if !viewModel.modules.isEmpty {
                LinkDownloadingHeader(
                    destination: DownloaderView(
                        modules: viewModel.modules
                    ),
                    title: "Downloading"
                )
                modules
            }
            Header(title: "Courses")
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
}
