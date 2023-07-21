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
import UIKit
import mobile_offline_downloader_ios

final public class DownloadPageListTableViewCell: UITableViewCell {

    // MARK: - Injected -

    private let storageManager = OfflineStorageManager.shared
    private let downloadsManager = OfflineDownloadsManager.shared

    // MARK: - Properties -

    var page: Page?
    var course: Course?
    private var cancellable: AnyCancellable?

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

    private var savedImage: UIImageView = {
        let savedImage = UIImageView()
        savedImage.isHidden = true
        savedImage.image = .init(systemName: "cloud")
        savedImage.contentMode = .scaleAspectFit
        return savedImage
    }()

    private var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.isHidden = true
        activityIndicator.color = .lightGray
        return activityIndicator
    }()

    // MARK: - Init -

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        savedImage.isHidden = true
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }

    // MARK: - Configuration -

    private func configure() {
        backgroundColor = .backgroundLightest
        accessoryType = .disclosureIndicator
        [titleLabel, dateLabel, savedImage, activityIndicator, accessIconView].forEach {
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
        titleLabel.trailingAnchor.constraint(equalTo: savedImage.leadingAnchor, constant: -15).isActive = true

        dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
        dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60).isActive = true
        dateLabel.trailingAnchor.constraint(equalTo: savedImage.leadingAnchor, constant: -15).isActive = true

        savedImage.widthAnchor.constraint(equalToConstant: 25).isActive = true
        savedImage.heightAnchor.constraint(equalToConstant: 25).isActive = true
        savedImage.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        savedImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 25).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 25).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        activityIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
    }

    // MARK: - Action -

    private func actions() {}

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

    private func isDownloaded(page: Page) {
        OfflineDownloadsManager.shared.eventObject(for: page) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success { event in
                self.statusChanged(event, page: page)
            }

            result.failure { _ in
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
            }
        }
        cancellable = downloadsManager
            .publisher
            .sink { [weak self] event in
                switch event {
                case .statusChanged(object: let event):
                    self?.statusChanged(event, page: page)
                default:
                    break
                }
            }
    }

    private func statusChanged(_ event: OfflineDownloadsManagerEventObject, page: Page) {
        guard let object = self.page, object == page else {
            return
        }
        do {
            let eventObjectId = try event.object.toOfflineModel().id
            let objectId = try object.toOfflineModel().id
            guard eventObjectId == objectId else {
                return
            }
            savedImage.isHidden = event.status != .completed
            switch event.status {
            case .initialized, .preparing, .active:
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            default:
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
            }
        } catch {
            activityIndicator.isHidden = true
            savedImage.isHidden = true
        }
    }
}
