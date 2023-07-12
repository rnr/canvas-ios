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

    // MARK: - Injected -

    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.viewController) var controller

    // MARK: - Properties -

    @StateObject var viewModel: DownloadsCourseDetailViewModel
    @State var isActiveLink: Bool = false

    private let headerViewModel: DownloadsCourseDetailsHeaderViewModel
    @State private var selection: DownloadsCourseCategoryViewModel?
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
        courseViewModel: DownloadCourseViewModel,
        categories: [DownloadsCourseCategoryViewModel],
        onDeletedAll: (() -> Void)? = nil
    ) {
        let model = DownloadsCourseDetailViewModel(
            courseViewModel: courseViewModel,
            categories: categories,
            onDeletedAll: onDeletedAll
        )
        self._viewModel = .init(wrappedValue: model)
        self.headerViewModel = DownloadsCourseDetailsHeaderViewModel(
            courseViewModel: courseViewModel
        )
    }

    // MARK: - Views -

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                switch viewModel.state {
                case .loaded, .updated:
                    content(geometry: geometry)
                        .onAppear {
                            if viewModel.categories.isEmpty {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                case .loading, .none:
                    LoadingView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.title)
                        .foregroundColor(.white)
                        .font(.semibold16)
                }
            }
        }
        .onPreferenceChange(ViewBoundsKey.self, perform: headerViewModel.scrollPositionChanged)
        .onAppear {
            navigationController?.navigationBar.useContextColor(viewModel.courseViewModel.color)
        }
    }

    private func content(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            imageHeader(geometry: geometry)
            List {
                VStack(spacing: 0) {
                    ForEach(viewModel.categories, id: \.self) { categoryViewModel in
                        DownloadsCourseDetailsCellView(categoryViewModel: categoryViewModel)
                            .background(
                                NavigationLink(
                                    destination: destination(sectionViewModel: categoryViewModel),
                                    tag: categoryViewModel,
                                    selection: $selection
                                ) { SwiftUI.EmptyView() }.hidden()
                            )
                            .onTapGesture {
                                selection = categoryViewModel
                            }
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

    private func destination(
        sectionViewModel: DownloadsCourseCategoryViewModel
    ) -> some View {
        DownloadsContenView(
            content: sectionViewModel.content,
            courseDataModel: viewModel.courseViewModel.courseDataModel,
            title: sectionViewModel.title,
            onDeleted: { entry in
                viewModel.delete(entry: entry, from: sectionViewModel)
            },
            onDeletedAll: {
                viewModel.delete(sectionViewModel: sectionViewModel)
            }
        )
    }
}
