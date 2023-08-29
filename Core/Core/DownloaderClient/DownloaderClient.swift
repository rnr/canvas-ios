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

import BugfenderSDK
import Foundation
import mobile_offline_downloader_ios

public struct DownloaderClient {
    public static func setup() {
        let storageConfig = OfflineStorageConfig()
        OfflineStorageManager.shared.setConfig(config: storageConfig)

        let downloaderConfig = OfflineDownloaderConfig()
        downloaderConfig.errorsDescriptionHandler = { errorInfo, isCritical in
            if errorInfo == nil && isCritical == false {
                // successful downloading
                OfflineAnalyticsMananger().logCompleted()
            } else {
                // was ended with error
                // Analytic
                OfflineAnalyticsMananger().logError()
                // Bugfender
                if let errorInfo = errorInfo {
                    let decoder = JSONDecoder()
                    var entryInfo: String = ""
                    if let data = errorInfo.1.json.data(using: .utf8),
                        let dictionary = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) {
                        // name
                        if let name = dictionary["title"] {
                            entryInfo.append("for content \"\(name)\"")
                        } else if let name = dictionary["displayName"] {
                            entryInfo.append("for content \"\(name)\"")
                        } else {
                            entryInfo.append("for content \"Unknown\"")
                        }
                        // course ID
                        entryInfo.append(", courseID: \(dictionary["courseID"] ?? "Unknown")")
                        // link
                        if let url = dictionary["htmlURL"] {
                            entryInfo.append(", link: \(url)")
                        } else if let url = dictionary["url"] {
                            entryInfo.append(", link: \(url)")
                        } else {
                            entryInfo.append(", link: Unknown")
                        }
                    } else {
                        entryInfo.append("for unknown content")
                    }
                    let message = errorInfo.0.replacingOccurrences(of: "###MODULE_DESCRIPTION###", with: entryInfo)
                    Bugfender.log(lineNumber: 0, method: "", file: "", level: .error, tag: "Offline", message: message)
                }
            }
        }
        downloaderConfig.downloadTypes = [Page.self, ModuleItem.self, File.self]
        downloaderConfig.linksHandler = { urlString in
            if urlString.contains("/files/") && !urlString.contains("/download") && urlString.contains(AppEnvironment.shared.api.baseURL.absoluteString) {
                return urlString.replacingOccurrences(of: "?", with: "/download?")
                    .replacingOccurrences(of: "/preview", with: "")
            }
            return urlString
        }
        OfflineDownloadsManager.shared.setConfig(downloaderConfig)
    }

    public static func replaceHtml(for tag: String?) async -> String? {
        if tag?.lowercased() == "video" ||
            tag?.lowercased() == "audio" ||
            tag?.lowercased() == "iframe" ||
            tag?.lowercased() == "source",
            let image = UIImage(named: "PandaNoResults", in: .core, with: nil) {
            let originWidth = image.size.width
            let imageData = image
                .pngData()?
                .base64EncodedString() ?? ""
            let result = """
                    <div style = "width:100%; border: 2px solid #e5146fff;" >
                        <center>
                            <div style="padding: 10px;">
                                <img width = "\(originWidth)" src="data:image/png;base64, \(imageData)">
                                <p> This content has not been downloaded. </p>
                            </div>
                        </center>
                    </div>
                """
            return result
        }
        return nil
    }
}
