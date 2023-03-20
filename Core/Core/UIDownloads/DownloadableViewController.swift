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

import UIKit
import SwiftUI

struct DownloadsContentView: View {
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack {
                HStack {
                    Text("Downloads")
                        .font(.semibold17)
                        .foregroundColor(Color(Brand.shared.linkColor))
                        .frame(height: 30)
                    Spacer()
                }
                Divider()
            }.padding()
        }
    }
}

public class DownloadableViewController: UIViewController {

    // MARK: - Properties -

    public var downloadButton: DownloadButton = {
        let downloadButton = DownloadButton()
        downloadButton.mainTintColor = .white
        downloadButton.currentState = .idle
        return downloadButton
    }()

    // MARK: - Lifecycle -

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }

    // MARK: - Configuration -

    public func configure() {
        layout()
        actions()
    }

    // MARK: - Layout -

    public func layout() {
        attachDownloadButton()
    }

    public func attachDownloadButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: downloadButton)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
    }

    // MARK: - Actions -

    func actions() {
        downloadButton.onTap = { state in
            switch state {
            case .idle:
                self.downloadButton.currentState = .waiting
            case .downloaded:
                self.downloadButton.currentState = .idle
            default:
                break
            }
        }

        var index: Float = 0.0
        downloadButton.onState = { state in
            switch state {
            case .waiting:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.downloadButton.currentState = .downloading
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                        self.downloadButton.progress = index
                        index += 0.01
                        if self.downloadButton.progress > 1.0 {
                            timer.invalidate()
                            self.downloadButton.currentState = .downloaded
                        }
                    }
                }
            default:
                break
            }
        }
    }
}
