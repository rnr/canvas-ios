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

struct DownloadsView: View {

    // MARK: - Injected -

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsViewModel = .init()
    @State var isDisplayingAlert: Bool = false

    var isSheet: Bool = false

    // MARK: - Views -

    var body: some View {
        NavigationView {
            if #available(iOS 15.0, *) {
                content
                    .alert(
                        "Are you sure you want to remove all downloaded content?",
                        isPresented: $isDisplayingAlert,
                        actions: actions
                    )
            } else {
                content
                    .alert(
                        isPresented: $isDisplayingAlert,
                        content: alert
                    )
            }
        }
    }

    private var content: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            VStack {
                if viewModel.isEmpty {
                    VStack {
                      Text("Test")
                    }
                } else {
                    list
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Downloads")
                    .foregroundColor(.textDarkest)
                    .font(.semibold16)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                closeButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                deleteAllButton
            }
        }
    }

    private var list: some View {
        List {
            if !viewModel.modules.isEmpty {
                LinkDownloadingHeader(destination: DownloaderView(), title: "Downloading")
                modules
            }
            switch viewModel.state {
            case .none, .loading:
                placeholder
            case .loaded:
                Header(title: "Courses")
                courses
            }
        }
        .listStyle(.inset)
        .background(Color.backgroundLightest.ignoresSafeArea())
    }

    private var placeholder: some View {
        Section(header: Text("")) {
            Text("Downloads")
        }
    }

    private var modules: some View {
        DownloadDownloadingSectionView(viewModel: viewModel)
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
            isDisplayingAlert = true
        }
        .foregroundColor(Color(Brand.shared.linkColor))
    }

    @ViewBuilder
    @available(iOS 15.0, *)
    private func actions() -> some View {
        Button("Delete", role: .destructive) {
            viewModel.deleteAll()
        }
        Button("Cancel", role: .cancel) {
            isDisplayingAlert = false
        }
    }

    private func alert() -> Alert {
        Alert(
            title: Text("Are you sure you want to remove all downloaded content?"),
            primaryButton: .destructive(
                Text("Delete")
            ) {
                viewModel.deleteAll()
            },
            secondaryButton: .cancel()
        )
    }

    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Close")
                .foregroundColor(Color(Brand.shared.linkColor))
        })
    }
}
