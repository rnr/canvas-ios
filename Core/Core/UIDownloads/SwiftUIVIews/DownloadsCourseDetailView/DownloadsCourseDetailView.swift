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

struct DownloadsCourseDetailView: View {

    let course: DownloadedCourse
    let headerViewModel: DownloadsCourseDetailsHeaderViewModel

    init(course: DownloadedCourse) {
        self.course = course
        self.headerViewModel = DownloadsCourseDetailsHeaderViewModel(course: course)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                content(geometry: geometry)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(course.courseCode)
                        .foregroundColor(.textDarkest)
                        .font(.semibold16)
                }
            }
        }
        .onPreferenceChange(ViewBoundsKey.self, perform: headerViewModel.scrollPositionChanged)
    }

    private func content(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            imageHeader(geometry: geometry, course: course)
            List {
                VStack(spacing: 0) {
                    ForEach(Array(0...20), id: \.self) { _ in
                        DownloadsCourseDetailsListView()
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
    private func imageHeader(geometry: GeometryProxy, course: DownloadedCourse) -> some View {
        if headerViewModel.shouldShowHeader(for: geometry.size.height) {
            DownloadsCourseDetailsHeaderView(viewModel: headerViewModel, width: geometry.size.width)
        }
    }
}

public class DownloadsCourseDetailsHeaderViewModel: ObservableObject {

    @Published public private(set) var hideColorOverlay: Bool = false
    @Published public private(set) var verticalOffset: CGFloat = 0
    @Published public private(set) var imageOpacity: CGFloat = 0.4
    @Published public private(set) var titleOpacity: CGFloat = 1
    @Published public private(set) var courseName = ""
    @Published public private(set) var courseColor: UIColor = .clear
    @Published public private(set) var termName = ""
    @Published public private(set) var imageURL: URL?

    public let height: CGFloat = 235

    init(course: DownloadedCourse) {
        courseName = course.shortName
        imageURL = URL(
            string: "https://fastly.picsum.photos/id/870/536/354.jpg?blur=2&grayscale&hmac=A5T7lnprlMMlQ18KQcVMi3b7Bwa1Qq5YJFp8LSudZ84"
        )
        termName = "Test"
        courseColor = .systemGroupedBackground
    }

    public func scrollPositionChanged(_ bounds: ViewBoundsKey.Value) {
        guard let frame = bounds.first?.bounds else { return }
        scrollPositionYChanged(to: frame.minY)
    }

    public func shouldShowHeader(for height: CGFloat) -> Bool {
        self.height < height / 2
    }

    private func scrollPositionYChanged(to value: CGFloat) {
        if value <= 0 { // scrolling down to content
            verticalOffset = min(0, value / 2)
            // Starts from 0 and reaches 1 when the image is fully pushed out of screen
            let offsetRatio = abs(verticalOffset) / (height / 2)
            imageOpacity = hideColorOverlay ? 1 : (1 - offsetRatio) * 0.4
            titleOpacity = 1 - offsetRatio
        } else { // pull to refresh gesture, we allow the image to move along with the content
            verticalOffset = value
            imageOpacity = hideColorOverlay ? 1 : 0.4
            titleOpacity = 1
        }
    }
}

struct DownloadsCourseDetailsHeaderView: View {
    @ObservedObject private var viewModel: DownloadsCourseDetailsHeaderViewModel
    private let width: CGFloat

    public init(viewModel: DownloadsCourseDetailsHeaderViewModel, width: CGFloat) {
        self.viewModel = viewModel
        self.width = width
    }

    public var body: some View {
        ZStack {
            Color(viewModel.courseColor.darkenToEnsureContrast(against: .white))
                .frame(width: width, height: viewModel.height)
            if let url = viewModel.imageURL {
                RemoteImage(url, width: width, height: viewModel.height)
                    .opacity(viewModel.imageOpacity)
            }
            VStack(spacing: 3) {
                Text(viewModel.courseName)
                    .font(.semibold23)
                    .accessibility(identifier: "course-details.title-lbl")
                Text(viewModel.termName)
                    .font(.semibold14)
                    .accessibility(identifier: "course-details.subtitle-lbl")
            }
            .padding()
            .multilineTextAlignment(.center)
            .foregroundColor(.textLightest)
            .opacity(viewModel.titleOpacity)
        }
        .frame(height: viewModel.height)
        .clipped()
        .offset(x: 0, y: viewModel.verticalOffset)
    }
}
