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

import mobile_offline_downloader_ios

public struct DownloadableItem {

    private(set) var objectId: String
    private(set) var userInfo: String
    private(set) var assetType: String
    private(set) var object: OfflineDownloadTypeProtocol
    private(set) var course: Course

     init(
        objectId: String,
        userInfo: String,
        assetType: String,
        object: OfflineDownloadTypeProtocol,
        course: Course
    ) {
        self.objectId = objectId
        self.userInfo = userInfo
        self.assetType = assetType
        self.object = object
        self.course = course
    }
}

protocol DownloadableItems: UIViewController {
    func subscribe(
        detailViewController: DownloadableViewController,
        assetType: GetModuleItemSequenceRequest.AssetType
    )
}

extension DownloadableItems {
    func subscribe(
        detailViewController: DownloadableViewController,
        assetType: GetModuleItemSequenceRequest.AssetType
    ) {
        if let moduleDetail = detailViewController as? ModuleItemDetailsViewController {
            subscribe(moduleDetail: moduleDetail, assetType: assetType) { [weak detailViewController] item in
                detailViewController?.set(downloadableItem: item)
            }
        } else if let pageDetail = detailViewController as? PageDetailsViewController {
            subscribe(pageDetail: pageDetail, assetType: assetType) { [weak detailViewController] item in
                detailViewController?.set(downloadableItem: item)
            }
        }
    }

    private func subscribe(
        moduleDetail: ModuleItemDetailsViewController,
        assetType: GetModuleItemSequenceRequest.AssetType,
        completion: @escaping ((DownloadableItem) -> Void)
    ) {
        moduleDetail.onEmbedContainer = { [weak moduleDetail, weak self] vc in
            if assetType == .page, let detailPage = vc as? PageDetailsViewController {
                detailPage.updated = { page, course in
                    guard let url = page.htmlURL  else {
                        return
                    }
                    debugLog("subscribe detail PAGE", url, assetType.rawValue, page.title, course.name ?? "")
                    let item = DownloadableItem(
                        objectId: page.id,
                        userInfo: url.absoluteString,
                        assetType: assetType.rawValue,
                        object: page,
                        course: course
                    )
                    completion(item)
                }
            } else if assetType == .moduleItem {
                if let moduleDetail = moduleDetail {
                    self?.create(moduleDetail: moduleDetail, completion: completion)
                }
            } else if vc is LTIViewController {
                if let moduleDetail = moduleDetail {
                    self?.create(moduleDetail: moduleDetail, completion: completion)
                }
            }
        }
    }

    private func create(
        moduleDetail: ModuleItemDetailsViewController,
        completion: @escaping ((DownloadableItem) -> Void)
    ) {
        guard let moduleItem = moduleDetail.item,
              let url = moduleDetail.item?.htmlURL,
              let course = moduleDetail.course.first else {
            return
        }
        let item = DownloadableItem(
            objectId: moduleItem.id,
            userInfo: url.absoluteString,
            assetType: GetModuleItemSequenceRequest.AssetType.moduleItem.rawValue,
            object: moduleItem,
            course: course
        )
        completion(item)
    }

    private func subscribe(
        pageDetail: PageDetailsViewController,
        assetType: GetModuleItemSequenceRequest.AssetType,
        completion: @escaping ((DownloadableItem) -> Void)
    ) {
        pageDetail.updated = { page, course in
            guard let url = page.htmlURL else {
                return
            }
            debugLog("subscribe detail PAGE", url, assetType.rawValue, page.title, course.name ?? "")
            let item = DownloadableItem(
                objectId: page.id,
                userInfo: url.absoluteString,
                assetType: assetType.rawValue,
                object: page,
                course: course
            )
            completion(item)
        }
    }
}
