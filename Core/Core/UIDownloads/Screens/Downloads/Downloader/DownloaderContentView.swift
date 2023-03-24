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

struct DownloaderContentView: View {

    @ObservedObject var viewModel: DownloaderViewModel
    var onDelete: ((IndexSet) -> Void)

    var body: some View {
        List {
            Header(title: "Downloading")
                .iOS15ListRowSeparator(.hidden)
            ForEach(
                Array(viewModel.modules.enumerated()),
                id: \.offset
            ) { _, module in
                DownloadingListView(module: module)
                    .listRowInsets(EdgeInsets())
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 5)
            }.onDelete { indexSet in
                onDelete(indexSet)
            }
            .iOS15ListRowSeparator(.hidden)
        }
        .listStyle(.inset)
        .background(Color.backgroundLightest.ignoresSafeArea())
    }

    private var headerDownloading: some View {
        HStack {
            Text("Downloading")
                .font(.system(size: 14, weight: .bold))
            Spacer()
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
