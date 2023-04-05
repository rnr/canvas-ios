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

public struct DownloadsCourseDetailsCellView: View {

    // MARK: - Properties -

    let detailViewModel: DownloadsCourseDetailsViewModel

    // MARK: - Views -

    public var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: .documentLine)
                .frame(width: 20, height: 20)
                .foregroundColor(Color(detailViewModel.courseColor))
            VStack(alignment: .leading) {
                Text(detailViewModel.title)
                    .font(.semibold16)
                    .foregroundColor(.oxford)
            }
            Spacer()
            InstDisclosureIndicator()
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
        .frame(height: 54)
    }
}
