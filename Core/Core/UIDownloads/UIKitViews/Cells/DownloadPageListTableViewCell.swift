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
import mobile_offline_downloader_ios

final public class DownloadPageListTableViewCell: UITableViewCell {

    // MARK: - Injected -

    let storageManager = OfflineStorageManager.shared

    // MARK: - Properties -

    var page: Page?
    var course: Course?

    private var accessIconView: AccessIconView = .init(frame: .zero)

    private var titleLabel: UILabel = {
        let titleLabel =  UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .textDarkest
        titleLabel.numberOfLines = 2
        return titleLabel
    }()

    private let dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 16, weight: .medium)
        dateLabel.textColor = .textDark
        return dateLabel
    }()

    private var downloadButton: DownloadButton = {
        let downloadButton = DownloadButton()
        downloadButton.mainTintColor = Brand.shared.linkColor
        downloadButton.currentState = .idle
        return downloadButton
    }()

    // MARK: - Init -

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration -

    private func configure() {
        backgroundColor = .backgroundLightest
        accessoryType = .disclosureIndicator
        [titleLabel, dateLabel, downloadButton, accessIconView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        layout()
        actions()
    }

    // MARK: - Layout -

    private func layout() {

        accessIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        accessIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        accessIconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        accessIconView.heightAnchor.constraint(equalToConstant: 24).isActive = true

        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -15).isActive = true

        dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        dateLabel.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -15).isActive = true

        downloadButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        downloadButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    }

    // MARK: - Action -

    private func actions() {
        downloadButton.onTap = { [weak self] state in
            guard let self = self, let course = self.course, let page = self.page else {
                return
            }

            switch state {
            case .downloaded:
                self.delete(page)
            case .downloading:
                print("downloaded")
            case .idle:
                self.download(page, for: course)
            default:
                break
            }
        }
    }

    // MARK: - Intent -

    func update(_ page: Page?, course: Course?, indexPath: IndexPath, color: UIColor?) {
        self.page = page
        self.course = course
        selectedBackgroundView = ContextCellBackgroundView.create(color: color)
        titleLabel.accessibilityIdentifier = "PageList.\(indexPath.row)"
        accessIconView.icon = UIImage.documentLine
        accessIconView.published = page?.published == true
        let dateText = page?.lastUpdated.map { // TODO: page?.lastUpdated?.dateTimeString
            DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .short)
        }
        dateLabel.setText(dateText, style: .textCellSupportingText)
        titleLabel.setText(page?.title, style: .textCellTitle)
        titleLabel.lineBreakMode = .byTruncatingTail
        page.flatMap(isDownloaded)

    }

    private func download(_ page: Page, for course: Course) {
        downloadButton.currentState = .downloading
        storageManager.save(page) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success {
                self.storageManager.save(course) { result in
                    result.success {
                        self.downloadButton.currentState = .downloaded
                    }
                }
            }
        }
    }

    private func delete(_ page: Page) {
        storageManager.delete(page) { [weak self] result in
            result.success {
                self?.downloadButton.currentState = .idle
            }
        }
    }

    private func isDownloaded(page: Page) {
        storageManager.isSaved(for: page.id) { [weak self] isSaved in
            guard let self = self else {
                return
            }
            self.downloadButton.currentState = isSaved ? .downloaded : .idle
        }
    }
}
