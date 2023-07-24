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

final class DownloadsModuleCellViewModel: ObservableObject {

    // MARK: - Injected -

    private let downloadsManager = OfflineDownloadsManager.shared

    // MARK: - Properties -

    let entry: OfflineDownloaderEntry
    private var downloadsSubscriber: AnyCancellable?

    @Published var progress: Double = 0.0
    @Published var downloaderStatus: OfflineDownloaderStatus = .initialized

    init(entry: OfflineDownloaderEntry) {
        self.entry = entry
        observeDownloadsEvents()
    }

    var dataModel: OfflineStorageDataModel {
        entry.dataModel
    }

    var moduleId: String {
        entry.dataModel.id
    }

    var item: OfflineDownloadTypeProtocol? {
        if let page = try? Page.fromOfflineModel(dataModel) {
            return page
        }
        if let moduleItem = try? ModuleItem.fromOfflineModel(dataModel) {
            return moduleItem
        }
        return nil
    }

    var title: String {
        if let page = try? Page.fromOfflineModel(dataModel) {
            return page.title
        }
        if let moduleItem = try? ModuleItem.fromOfflineModel(dataModel) {
            return moduleItem.title
        }
        return ""
    }

    var uiImage: UIImage? {
        if (try? Page.fromOfflineModel(dataModel)) != nil {
            return .documentLine
        }
        if let moduleItem = try? ModuleItem.fromOfflineModel(dataModel) {
            return image(moduleItem.type)
        }
        return nil
    }

    var type: ModuleItemType? {
        if (try? Page.fromOfflineModel(dataModel)) != nil {
            return .page("")
        }
        if let moduleItem = try? ModuleItem.fromOfflineModel(dataModel) {
            return moduleItem.type
        }
        return nil
    }

    var lastUpdated: Date? {
        if let page = try? Page.fromOfflineModel(dataModel) {
            return page.lastUpdated
        }
        return nil
    }

    func pauseResume() {
        switch entry.status {
        case .initialized, .active, .preparing:
            downloadsManager.pause(entry: entry)
        default:
            downloadsManager.resume(entry: entry)
        }
        downloaderStatus = entry.status
    }

    private func image(_ type: ModuleItemType?) -> UIImage? {
        var uiImage = UIImage()
        switch type {
        case .externalTool:
            uiImage = .ltiLine
        case .page:
            uiImage = .documentLine
        default:
            return nil
        }
        return uiImage
    }

    private func observeDownloadsEvents() {
        downloadsSubscriber = downloadsManager
            .publisher
            .sink { [weak self] event in
                switch event {
                case .statusChanged(object: let event):
                    self?.statusChanged(event)
                case .progressChanged(object: let event):
                    self?.progressChanged(event)
                }
            }
        item.flatMap {
            downloadsManager.eventObject(for: $0) { [weak self] result in
                result.success { event in
                    self?.statusChanged(event)
                }
            }
        }
    }

    private func statusChanged(_ event: OfflineDownloadsManagerEventObject) {
        let eventObjectId = try? event.object.toOfflineModel().id
        let objectId = self.dataModel.id
        guard eventObjectId == objectId else {
            return
        }
        downloaderStatus = event.status
        if event.status != .active {
            progress = 0.0
        }

    }

    private func progressChanged(_ event: OfflineDownloadsManagerEventObject) {
        do {
            let eventObjectId = try event.object.toOfflineModel().id
            let objectId = dataModel.id
            guard eventObjectId == objectId else {
                return
            }
            if event.progress == 0.0 {
                return
            }
            downloaderStatus = event.status
            if event.status != .active {
                progress = 0.0
            } else {
                progress = event.progress
            }
        } catch {}
    }
}
