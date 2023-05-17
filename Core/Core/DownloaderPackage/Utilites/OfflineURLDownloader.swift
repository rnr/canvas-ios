import Foundation

struct OfflineLinkDownloader {
    func download(urlString: String, toFolder folder: String) async throws -> URL {
        if Task.isCancelled { throw URLError(.cancelled) }

        guard let url = URL(string: urlString) else {
            throw OfflineLinkDownloaderError.wrongURL(url: urlString)
        }
        let request = URLRequest(url: url)
        // TODO: ask config for addition headers for url
        do {
            let (destinationURL, response) = try await download(with: request)
            let newURL = self.destinationURL(for: url, with: response, in: folder)

            try FileManager.default.createDirectoryAt(path: newURL.path)
            try FileManager.default.moveItem(at: destinationURL, to: newURL)
            return newURL
        } catch {
            throw OfflineLinkDownloaderError.cantDownloadFile(url: url.absoluteString, error: error)
        }
    }

    private func path(for url: URL, with response: URLResponse) -> String {
        let path = url.path
        if let last = path.components(separatedBy: "/").last,
           last.contains(".") {
            if response.mimeType?.contains("mp4") == true {
                let nameComponents = last.components(separatedBy: ".")
                return path + "/" + nameComponents[0] + ".mp4"
            }
            if response.mimeType?.contains("audio/mpeg") == true {
                let nameComponents = last.components(separatedBy: ".")
                return path + "/" + nameComponents[0] + ".mp3"
            }
            if response.mimeType?.contains("audio/x-wav") == true {
                let nameComponents = last.components(separatedBy: ".")
                return path + "/" + nameComponents[0] + ".wav"
            }
            return path
        } else if let name = response.suggestedFilename {
            return path + "/" + name
        } else {
            return path + "/" + "\(Date().timeIntervalSince1970).tmp"
        }
    }

    private func alterFilePath(_ filePath: String) -> String {
        var components = filePath.components(separatedBy: "/")
        if let fileName = components.last {
            var fileNameComponents = fileName.components(separatedBy: ".")
            if let name = fileNameComponents.first {
                let newName = name + "\(Date().timeIntervalSince1970)"
                fileNameComponents[0] = newName
            }
            let newName = fileNameComponents.joined(separator: ".")
            components[components.count - 1] = newName
        }
        return components.joined(separator: "/")
    }

    private func destinationURL(for url: URL, with response: URLResponse, in folder: String) -> URL {
        let filePath = path(for: url, with: response)
        var destinationPath = folder.appendPath(filePath)
        if FileManager.default.fileExists(atPath: destinationPath) {
            destinationPath = alterFilePath(destinationPath)
        }
        return URL(fileURLWithPath: destinationPath)
    }

    private func download(with request: URLRequest) async throws -> (URL, URLResponse) {
        if #available(iOS 15.0, *) {
            return try await URLSession.shared.download(for: request)
        } else {
            var task: URLSessionDownloadTask?
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    task = URLSession.shared.downloadTask(with: request) { url, response, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let url = url, let response = response {
                            continuation.resume(returning: (url, response))
                        } else {
                            continuation.resume(throwing: OfflineLinkDownloaderError.unknown)
                        }
                    }
                    task?.resume()
                }
            } onCancel: { [weak task] in
                task?.cancel()
            }
        }
    }
}

extension OfflineLinkDownloader {
    enum OfflineLinkDownloaderError: Error, LocalizedError {
        case unknown
        case wrongURL(url: String)
        case cantDownloadFile(url: String, error: Error)

        var errorDescription: String? {
            switch self {
            case .unknown:
                return "Unknown error was occured"
            case .wrongURL(let url):
                return "URL = \"\(url)\" is incorrect and couldn't be downloaded."
            case let .cantDownloadFile(url, error):
                return "Can't download file at: \(url), with error : \(error.localizedDescription)"
            }
        }
    }
}

extension FileManager {
    func createDirectoryAt(path: String) throws {
        var components = path.components(separatedBy: "/")
        let fileManager = FileManager.default
        if components.last?.contains(".") == true {
            components.removeLast()
            let newPath = components.joined(separator: "/")
            try fileManager.createDirectory(atPath: newPath, withIntermediateDirectories: true, attributes: nil)
        } else {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

