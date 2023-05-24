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

final class DownloadsPagesViewModel: ObservableObject {

    var pages: [Page]

    init(pages: [Page]) {
        self.pages = pages
    }

}

struct DownloadsPagesView: View {

    @StateObject var viewModel: DownloadsPagesViewModel

    init(pages: [Page]) {
        let viewModel = DownloadsPagesViewModel(pages: pages)
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Pages")
                        .foregroundColor(.textDarkest)
                        .font(.semibold16)
                }
            }
    }

    private var content: some View {
        List {
            VStack(spacing: 0) {
                ForEach(viewModel.pages, id: \.self) { page in
                    ZStack {
                        DownloadsPagesCellView(
                            viewModel: DownloadsPagesCellViewModel(page: page)
                        )
                    }.onTapGesture {

                    }
                    Divider()
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .iOS15ListRowSeparator(.hidden)
            .background(Color.backgroundLightest)
        }
        .listStyle(.plain)
        .iOS16HideListScrollContentBackground()
    }
}
