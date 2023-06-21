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

struct DownloaderView: View {

    // MARK: - Properties -

    @StateObject var viewModel: DownloaderViewModel = .init()
    @Environment(\.viewController) var controller
    @State var isDisplayingAlert: Bool = false
    var didDeleteAll: (() -> Void)?

    // MARK: - Views -

    var body: some View {
        content
    }

    private var content: some View {
        VStack {
            DownloaderContentView(viewModel: viewModel) { indexSet in
                viewModel.delete(indexSet: indexSet)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Downloading")
                    .foregroundColor(.textDarkest)
                    .font(.semibold16)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                deleteAllButton
            }
        }
    }

    private var deleteAllButton: some View {
        Button("Delete all") {
            let cancelAction = AlertAction(NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in }
            let deleteAction = AlertAction(NSLocalizedString("Delete", comment: ""), style: .destructive) { _ in
                viewModel.deleteAll()
                didDeleteAll?()
            }
            controller.value.showAlert(
                title: NSLocalizedString("Are you sure you want to remove all downloading content?", comment: ""),
                actions: [cancelAction, deleteAction],
                style: .actionSheet
            )
            isDisplayingAlert = true
        }
        .foregroundColor(.white)
    }
}
