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
import mobile_offline_downloader_ios

struct DownloadingCellView: View {

    // MARK: - Properties -

    @ObservedObject var viewModel: DownloadsModuleCellViewModel

    // MARK: - Views -

    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    Color.gray,
                    lineWidth: 1 / UIScreen.main.scale
                )
        )
        .background(Color.backgroundLightest)
        .cornerRadius(4)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .buttonStyle(PlainButtonStyle())
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.title)
                    .font(.semibold18)
                    .foregroundColor(.textDarkest)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                HStack(alignment: .center, spacing: 2) {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(
                            LinearProgressViewStyle(
                                tint: Color(Brand.shared.linkColor)
                            )
                        )
                        .frame(height: 5)
                    Spacer()
                    Text("\(Int(round(viewModel.progress * 100))) %")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                    Spacer()
                }
            }
            DownloadButtonRepresentable(
                progress: .constant(1),
                currentState: .constant(currentState),
                mainTintColor: Brand.shared.linkColor,
                onState: { state in
                    debugLog(state)
                },
                onTap: { _ in
                    viewModel.pauseResume()
                }
            ).frame(width: 30, height: 30)
        }
        .padding(.all, 10)
    }

    private var currentState: DownloadButton.State {
        switch viewModel.downloaderStatus {
        case .initialized, .preparing:
            return .waiting
        case .active:
            return .downloading
        case .paused, .failed:
            return .retry
        default:
            return .retry
        }
    }

}
