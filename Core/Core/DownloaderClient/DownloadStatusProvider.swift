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

import Foundation
import Combine
import mobile_offline_downloader_ios

final class DownloadButtonHelper {

    private let downloadsManager = OfflineDownloadsManager.shared
    private let storageManager = OfflineStorageManager.shared
    private let imageDownloader = ImageDownloader()

    private var object: OfflineDownloadTypeProtocol?
    private var course: Course?
    private var userInfo: String?
    private var cancellable: AnyCancellable?

    func update(
        object: OfflineDownloadTypeProtocol?,
        course: Course?,
        userInfo: String?
    ) {
        self.object = object
        self.course = course
        self.userInfo = userInfo
    }

    func status(
        for object: OfflineDownloadTypeProtocol,
        onState: @escaping ((DownloadButton.State, String) -> Void),
        onProgress: @escaping ((Double, String) -> Void)
    ) {
        downloadsManager.eventObject(for: object) { [weak self] result in
            guard let self = self else {
                return
            }
            result.success { event in
                self.statusChanged(
                    event: event,
                    onState: onState,
                    onProgress: onProgress
                )
            }
            result.failure {  _ in
                onState(.idle, "")
            }
        }

        cancellable = OfflineDownloadsManager.shared
            .publisher
            .sink { [weak self] event in
                switch event {
                case .statusChanged(object: let event):
                    self?.statusChanged(
                        event: event,
                        onState: onState,
                        onProgress: onProgress
                    )
                case .progressChanged(object: let event):
                    self?.statusChanged(
                        event: event,
                        onState: onState,
                        onProgress: onProgress
                    )
                }
            }
    }

    private func statusChanged(
        event: OfflineDownloadsManagerEventObject,
        onState: @escaping ((DownloadButton.State, String) -> Void),
        onProgress: @escaping ((Double, String) -> Void)
    ) {
        guard let object = self.object else {
            return
        }
        do {
            let eventObjectId = try event.object.toOfflineModel().id
            let objectId = try object.toOfflineModel().id
            guard eventObjectId == objectId else {
                return
            }
            switch event.status {
            case .initialized, .preparing:
                onState(.waiting, eventObjectId)
            case .active:
                onState(.downloading, eventObjectId)
                onProgress(event.progress, eventObjectId)
            case .completed:
                onState(.downloaded, eventObjectId)
            case .removed:
                onState(.idle, eventObjectId)
            default:
                onState(.idle, eventObjectId)
            }
        } catch {
            onState(.idle, "")
        }
    }

    func download(object: OfflineDownloadTypeProtocol) {
        do {
            guard let userInfo = self.userInfo else {
                return
            }
            try downloadsManager.addAndStart(
                object: object,
                userInfo: userInfo
            )
            addOrUpdateCourse()
        } catch {
            debugLog(error.localizedDescription)
        }
    }

    func delete(object: OfflineDownloadTypeProtocol) {
        do {
            try downloadsManager.delete(object: object)
        } catch {
            debugLog(error.localizedDescription)
        }
    }

    private func addOrUpdateCourse() {
        guard let course = course else {
            return
        }

        let courseStorageDataModel = CourseStorageDataModel(
            course: course
        )
        if let imageDownloadURL = course.imageDownloadURL {
            imageDownloader.downloadImage(from: imageDownloadURL)
        }

        if course.courseColor == nil {
            course.courseColor = course.contextColor?.color.hexString
        }

        storageManager.save(courseStorageDataModel) { result in
            result.success {
                print("success")
            }
            result.failure { _ in
                print("failure")
            }
        }
    }
}

final class DownloadStatusProvider {

    class DownloadStatus {
        var id: String {
            let id = try? object.toOfflineModel().id
            return id ?? ""
        }

        let object: OfflineDownloadTypeProtocol
        var status: OfflineDownloaderStatus?
        var progress: Double = 0.0

        init(
            object: OfflineDownloadTypeProtocol,
            status: OfflineDownloaderStatus? = nil,
            progress: Double = 0.0
        ) {
            self.object = object
            self.status = status
            self.progress = progress
        }
    }

    private let downloadsManager = OfflineDownloadsManager.shared
    private let storageManager = OfflineStorageManager.shared
    private let imageDownloader = ImageDownloader()

    private var objects: [DownloadStatus] = []
    private var course: Course?
    private var userInfo: String?
    private var cancellable: AnyCancellable?

    var onUpdate: (() -> Void)?

    init() {
        observe()
    }

    func update(
        objects: [OfflineDownloadTypeProtocol],
        course: Course?,
        userInfo: String?
    ) {

        objects.forEach { object in
            let id = try? object.toOfflineModel().id
            if !self.objects.contains(where: {$0.id == id}) {
                self.objects.append(DownloadStatus(object: object))
            }
        }
        self.course = course
        self.userInfo = userInfo
        getStatus()
    }

    func status(index: Int) -> DownloadStatus? {
        if objects.indices.contains(index) {
            return objects[index]
        }
        return nil
    }

    func status(id: String) -> DownloadStatus? {
        objects.first(where: {$0.id == id})
    }

    func getStatus() {
        let group = DispatchGroup()
        objects.forEach { object in
            group.enter()
            downloadsManager.eventObject(for: object.object) { result in
                result.success { event in
                    if object.status == nil {
                        object.status = event.status
                    }
                }
                result.failure { error in
                    debugLog(error.localizedDescription)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.onUpdate?()
        }
    }

    func observe() {
        cancellable = OfflineDownloadsManager.shared
            .publisher
            .sink { [weak self] event in
                switch event {
                case .statusChanged(object: let event):
                    self?.statusChanged(event: event)
                case .progressChanged(object: let event):
                    self?.statusChanged(event: event)
                }
            }
    }

    private func statusChanged(event: OfflineDownloadsManagerEventObject) {
        do {
            let eventObjectId = try event.object.toOfflineModel().id
            guard let object = objects.first(where: {$0.id == eventObjectId}) else {
                return
            }
            object.status = event.status
            if event.progress == 0.0 {
                return
            }
            object.progress = event.progress
            onUpdate?()
        } catch {}
    }

    func download(object: OfflineDownloadTypeProtocol) {
        do {
            guard let userInfo = self.userInfo else {
                return
            }
            try downloadsManager.addAndStart(
                object: object,
                userInfo: userInfo
            )
            addOrUpdateCourse()
        } catch {
            debugLog(error.localizedDescription)
        }
    }

    func delete(object: OfflineDownloadTypeProtocol) {
        do {
            try downloadsManager.delete(object: object)
        } catch {
            debugLog(error.localizedDescription)
        }
    }

    private func addOrUpdateCourse() {
        guard let course = course else {
            return
        }

        let courseStorageDataModel = CourseStorageDataModel(
            course: course
        )
        if let imageDownloadURL = course.imageDownloadURL {
            imageDownloader.downloadImage(from: imageDownloadURL)
        }

        if course.courseColor == nil {
            course.courseColor = course.contextColor?.color.hexString
        }

        storageManager.save(courseStorageDataModel) { result in
            result.success {
                print("success")
            }
            result.failure { _ in
                print("failure")
            }
        }
    }
}
