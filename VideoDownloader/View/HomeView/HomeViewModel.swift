//
//  HomeViewModel.swift
//  VideoDownloader
//
//  Created by Sushil Chaudhary on 27/04/25.
//

import Foundation
import Combine
import UIKit
import Network

final class HomeViewModel: NSObject, ObservableObject {
    
    static let shared = HomeViewModel()
    
    @Published var response = [Video]()
    @Published var error = ""
    
    private var session: URLSession!
    private var activeDownloads: [URL: (task: URLSessionDownloadTask, videoId: String)] = [:]
    private let sessionIdentifier = "com.swiftapp.VideoDownloader.backgroundTask"
    private var monitor: NWPathMonitor?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        createSession()
        startNetworkMonitoring()
    }
    
    private func createSession() {
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    func reconnectBackgroundSession(identifier: String) {
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }
    
    func configData(list: [String]) {
        var data = [Video]()
        for (index, url) in list.enumerated() {
            let correctUrl = fixVideoURL(url)
            guard let url = URL(string: correctUrl) else { return }
            var item = Video(id: "\(index)", title: "Video \(index)", url: url, isDownloaded: 0, videoState: .none, progress: 0)
            
            let isDownloaded = isVideoDownloaded(item)
            if isDownloaded {
                item.isDownloaded = 1
                item.videoState = .downloaded
            }
            
            data.append(item)
        }
        self.response = data
    }
    
    func downloadVideo(video: Video) {
        guard let url = video.url else { return }
        
        if monitor?.currentPath.status != .satisfied {
            DispatchQueue.main.async {
                if let index = self.response.firstIndex(where: { $0.id == video.id }) {
                    self.response[index].videoState = .failed
                    self.response[index].progress = 0
                }
                self.error = "No Internet Connection"
            }
            return
        }
        
        let downloadTask = session.downloadTask(with: url)
        activeDownloads[url] = (task: downloadTask, videoId: video.id)
        
        if let index = response.firstIndex(where: { $0.id == video.id }) {
            response[index].videoState = .isDownloading
        }
        
        downloadTask.resume()
    }
    
    private func fixVideoURL(_ url: String) -> String {
        return url
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
    
    private func startNetworkMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            if path.status != .satisfied {
                self.cancelAllDownloadsDueToNoInternet()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor?.start(queue: queue)
    }
    
    private func cancelAllDownloadsDueToNoInternet() {
        for (_, download) in activeDownloads {
            download.task.cancel()
            if let index = response.firstIndex(where: { $0.id == download.videoId }) {
                DispatchQueue.main.async {
                    self.response[index].videoState = .failed
                    self.response[index].progress = 0
                }
            }
        }
        activeDownloads.removeAll()
        DispatchQueue.main.async {
            self.error = "Internet connection lost. Downloads cancelled."
        }
    }
}


//MARK: - URL SESSION DELEGATE METHODS, FOR FAILURE HANDLING, PROGRESS FETCHING AND DOWNLOAD COMPLETION'S

extension HomeViewModel: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let sourceURL = downloadTask.originalRequest?.url,
              let videoId = activeDownloads[sourceURL]?.videoId,
              let video = response.first(where: { $0.id == videoId }) else { return }
        
        let destinationURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(video.title.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)).mp4")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                if let index = self.response.firstIndex(where: { $0.id == videoId }) {
                    self.response[index].isDownloaded = 1
                    self.response[index].videoState = .downloaded
                    self.response[index].progress = 1.0
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error.localizedDescription
            }
        }
        
        activeDownloads[sourceURL] = nil
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        guard let videoId = activeDownloads[sourceURL]?.videoId else { return }
        
        let progress = (Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)) * 100
        
        DispatchQueue.main.async {
            if let index = self.response.firstIndex(where: { $0.id == videoId }) {
                self.response[index].progress = progress
            }
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            (UIApplication.shared.delegate as? AppDelegate)?.backgroundSessionCompletionHandler?()
            (UIApplication.shared.delegate as? AppDelegate)?.backgroundSessionCompletionHandler = nil
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        guard let sourceURL = task.originalRequest?.url else { return }
        guard let videoId = activeDownloads[sourceURL]?.videoId else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.response.firstIndex(where: { $0.id == videoId }) {
                self.response[index].videoState = .failed
                self.response[index].progress = 0
            }
            self.error = "Internet issue: \(error?.localizedDescription ?? "")"
        }
        
        activeDownloads[sourceURL] = nil
    }
}

    //MARK: - CHECKING THE VIDEO IS DOWNLOADED OR NOT ALSO DELETE THE VIDEO

extension HomeViewModel {
    
    func isVideoDownloaded(_ video: Video) -> Bool {
        let titleItem = video.title.components(separatedBy: " ")
        let title = "\(titleItem.first ?? "")_\(titleItem.last ?? "")"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(title).mp4")
        
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    func deleteVideo(video: Video) {
        guard video.url != nil else {
            self.error = "Url not found."
            return
        }
        
        let destinationURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(video.title.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)).mp4")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                self.error = "Video Deleted Successfully."
            }
            
            DispatchQueue.main.async {
                if let index = self.response.firstIndex(where: { $0.id == video.id }) {
                    self.response[index].isDownloaded = 0
                    self.response[index].videoState = .none
                    self.response[index].progress = 0
                }
            }
            
        } catch {
            self.error = error.localizedDescription
        }
    }
}
