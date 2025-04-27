//
//  HomeDataModel.swift
//  VideoDownloader
//
//  Created by Sushil Chaudhary on 27/04/25.
//

import Foundation

enum VideoState {
    case none
    case isDownloading
    case downloaded
    case failed
}

struct Video: Identifiable {
    let id: String
    var title: String
    var url: URL?
    var isDownloaded: Int
    var videoState: VideoState
    var progress: Float  
}
