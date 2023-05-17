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

extension String {
    var trim: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func slice(fromStr: String, toStr: String) -> String? {
        guard let rangeFrom = range(of: fromStr)?.upperBound else { return nil }
        guard let rangeTo = self[rangeFrom...].range(of: toStr)?.lowerBound else { return nil }
        return String(self[rangeFrom ..< rangeTo])
    }

    func appendPath( _ path: String) -> String {
        var rootComponents = components(separatedBy: "/")
        let pathComponents = path.components(separatedBy: "/")
            .filter { !$0.isEmpty }
        rootComponents.append(contentsOf: pathComponents)
        return rootComponents.joined(separator: "/")
    }

    func removeLastPathComponent() -> String {
        var pathComponents = self.components(separatedBy: "/")
        pathComponents.removeLast()
        return pathComponents.joined(separator: "/")
    }

    func lastPathComponent() -> String {
        components(separatedBy: "/").last ?? self
    }

    func removeNewLines() -> String {
        self.replacingOccurrences(of: "\n", with: "")
    }

    func fixLink(with baseUrlString: String) -> String {
        let trimString = self.trim.removeNewLines()
        let url = URL(string: trimString, relativeTo: URL(string: baseUrlString))
        if let url = url {
            if url.scheme == nil && url.absoluteString.prefix(2) == "//" {
                return "https:" + url.absoluteString
            }
            return url.absoluteString
        } else {
            if trimString.prefix(2) == "//" {
                return "https:" + trimString
            } else {
                return trimString
            }
        }
    }
}
