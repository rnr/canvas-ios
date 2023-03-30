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
import RealmSwift

struct DownloadsCourseDetailView: View {

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsCourseDetailViewModel
    @State var isActiveLink: Bool = false

    let headerViewModel: DownloadsCourseDetailsHeaderViewModel

    init(courseViewModel: DownloadCourseViewModel) {
        let model = DownloadsCourseDetailViewModel(courseViewModel: courseViewModel)
        self._viewModel = .init(wrappedValue: model)
        self.headerViewModel = DownloadsCourseDetailsHeaderViewModel(courseViewModel: courseViewModel)
    }

    // MARK: - Views -

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                switch viewModel.state {
                case .loaded:
                    content(geometry: geometry)
                case .loading, .none:
                    Text("Loading").onAppear { viewModel.fetch() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.courseViewModel.course.courseCode)
                        .foregroundColor(.textDarkest)
                        .font(.semibold16)
                }
            }
        }
        .onPreferenceChange(ViewBoundsKey.self, perform: headerViewModel.scrollPositionChanged)
    }

    private func content(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            imageHeader(geometry: geometry)
            List {
                VStack(spacing: 0) {
                    ForEach(viewModel.detailViewModels, id: \.self) { detailViewModel in
                        ZStack {
                            DownloadsCourseDetailsCellView(detailViewModel: detailViewModel)
                            NavigationLink(
                                destination: destination(contentType: detailViewModel.contentType),
                                isActive: $isActiveLink
                            ) { SwiftUI.EmptyView() }.hidden()
                        }.onTapGesture {
                            isActiveLink = true
                        }
                        Divider()
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .iOS15ListRowSeparator(.hidden)
                .background(Color.backgroundLightest)
                .padding(.top, headerViewModel.shouldShowHeader(for: geometry.size.height) ? headerViewModel.height : 0)
                .transformAnchorPreference(key: ViewBoundsKey.self, value: .bounds) { preferences, bounds in
                    preferences = [.init(viewId: 0, bounds: geometry[bounds])]
                }
            }
            .listStyle(.plain)
            .iOS16HideListScrollContentBackground()
        }
    }

    @ViewBuilder
    private func imageHeader(geometry: GeometryProxy) -> some View {
        if headerViewModel.shouldShowHeader(for: geometry.size.height) {
            DownloadsCourseDetailsHeaderView(viewModel: headerViewModel, width: geometry.size.width)
        }
    }

    private func destination(contentType: DownloadsCourseDetailsViewModel.ContentType) -> some View {
        switch contentType {
        case .page(let pages):
            return DownloadsPagesView(pages: pages)
        }
    }
}
