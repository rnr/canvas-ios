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

struct DownloadDownloadingSectionView: View {

    // MARK: - Properties -

    @ObservedObject var viewModel: DownloadsViewModel

    var body: some View {
        ForEach(
            Array(viewModel.modules.prefix(3).enumerated()),
            id: \.element.id
        ) { index, module in
            DownloadingCellView(module: module)
        }
        .onDelete { indexSet in
            viewModel.swipeDeleteDownloading(indexSet: indexSet)
        }
    }

    // MARK: - Views -

    private var headerModules: some View {
        HStack {
            Text("Downloading")
                .font(.system(size: 14, weight: .bold))
            Spacer()
            if viewModel.modules.count > 3 {
                NavigationLink(
                    destination: DownloaderView { viewModel.fetch() }
                ) {
                    Text("See all")
                        .font(.system(size: 14, weight: .regular))
                }
            } else {
                Button(
                    action: {
                        viewModel.pauseResume()
                    },
                    label: {
                        Text("Button")
                            .font(.system(size: 14, weight: .regular))
                    }
                )
            }
        }
    }

}
