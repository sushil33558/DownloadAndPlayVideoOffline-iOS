//
//  NetworkManager.swift
//  VideoDownloader
//
//  Created by Sushil Chaudhary on 27/04/25.
//

import Foundation
import Network

class NetworkManager: NSObject, URLSessionDownloadDelegate {
    static let shared = NetworkManager()

    private var progressHandler: ((Float) -> Void)?
    private var completionHandler: ((URL?, Error?) -> Void)?

    func fetchVimeoVideoInfo(videoId: String) async throws -> (String, String, String) {
        let url = URL(string: "https://api.vimeo.com/videos/\(videoId)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer 75678a6c285e0ec43a1d093a87cfc4cd", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let videoData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw NSError(domain: "Error", code: 500, userInfo: nil) }
        return (
            videoData["name"] as? String ?? "No title",
            videoData["description"] as? String ?? "No description",
            videoData["created_time"] as? String ?? "No upload date"
        )
    }

    
    func downloadVideo(from urlString: String, progressHandler: @escaping (Float) -> Void, completionHandler: @escaping (URL?, Error?) -> Void) {
        guard let url = URL(string: urlString) else { return completionHandler(nil, NSError(domain: "Error", code: 400, userInfo: nil)) }
        
        self.progressHandler = progressHandler
        self.completionHandler = completionHandler
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.downloadTask(with: url).resume()
    }

    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progressHandler?(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
    }

    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(downloadTask.response?.suggestedFilename ?? "downloaded_video.mp4")
        try? FileManager.default.moveItem(at: location, to: destinationURL)
        completionHandler?(destinationURL, nil)
    }
}




class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    private init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
