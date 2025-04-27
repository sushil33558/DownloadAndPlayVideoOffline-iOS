//
//  ViewController.swift
//  VideoDownloader
//
//  Created by Sushil Chaudhary on 27/04/25.
//

import UIKit
import Combine
import AVKit

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    
    let viewModel = HomeViewModel()
    var garbageBag = Set<AnyCancellable>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Home"
        observer()
        configTableView()
        configUrlData()
    }
    
    
    
    //MARK: - Common methods
    
    private func configUrlData() {
        let videoUrls: [String] = [
            "https://player.vimeo.com/progressive_redirect/playback/433925279/rendition/1080p/file.mp4?loc=extern\nal&amp;signature=50856478a378907bc656554b1de94f38a7704cc9206c9bff46a83cfb36f35e63",
            "https://player.vimeo.com/progressive_redirect/playback/433927495/rendition/360p/file.mp4?loc=external\n&amp;signature=02578fff5efc682f5afde55867c62a496a6a654107831fded0b3b48c8bd8038c",
            "https://player.vimeo.com/progressive_redirect/playback/433664412/rendition/720p/file.mp4?loc=external\n&amp;signature=c181e93e63d3979c0b9124f6a9dd98ea48c28d7d2598bedbe33f94663d6b16b6",
            "https://player.vimeo.com/progressive_redirect/playback/433937419/rendition/1080p/file.mp4?loc=extern\nal&amp;signature=5e84d1bcbbd42caf7fab6e63e284b0383b2e4e02f5cd6d76f102670099a5ff94",
            "https://player.vimeo.com/progressive_redirect/playback/433947577/rendition/1080p/file.mp4?loc=extern\nal&amp;signature=946c6b2133120806a0cbaeec334708dda1dd7bb6f399f2e6f14224a61bf164ca"
        ]
        viewModel.configData(list: videoUrls)
    }
    
    
    private func configTableView() {
        let cellNib = UINib(nibName: HomeTableViewCell.reuseIdentifier, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: HomeTableViewCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func observer() {
        self.viewModel.$response
            .dropFirst()
            .sink { response in
                self.tableView.reloadData()
            }.store(in: &garbageBag)
        
        
        self.viewModel.$error
            .dropFirst()
            .sink { message in
                if self.viewModel.error == "Video Deleted Successfully."  {
                    self.showToast(message: "Video deleted SuccessFully")
                }else {
                    if self.viewModel.error != "" {
                        self.showErrorAlert(message: self.viewModel.error)
                    }
                }
            }.store(in: &garbageBag)
    }

}


    //MARK: - PLAY VIDEO OFFLINE USING AV KIT

extension HomeViewController {
    func playDownloadedVideo(for video: Video) {
        guard video.url != nil else { return }
        
        let titleItem = video.title.components(separatedBy: " ")
        let title = "\(titleItem.first ?? "")_\(titleItem.last ?? "")"
        
        let localFileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(title).mp4")
        
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            let player = AVPlayer(url: localFileURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            
            self.present(playerViewController, animated: true) {
                player.play()
            }
        } else {
            print("Video file not found locally!")
        }
    }

}


    //MARK: - Table View delegate & data source

extension HomeViewController: UITableViewDelegate {}
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.response.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableViewCell.reuseIdentifier) as! HomeTableViewCell
        let video = self.viewModel.response[indexPath.row]
        cell.model = video
        
        cell.downloadingCompletion = { [weak self] in
            Task {
                self?.viewModel.downloadVideo(video: video)
            }
        }
        
        cell.deleteCompletion = { [weak self] in
            guard let self = self else {return}
            showAlertWithTwoActions(
                title: "Delete Video",
                message: "Are you sure you want to delete this downloaded video from your file?",
                on: self,
                firstButtonTitle: "Delete",
                firstButtonAction: {
                    self.viewModel.deleteVideo(video: video)
                    
                },
                secondButtonTitle: "Cancel",
                secondButtonAction: {
                    print("User tapped Cancel, do nothing.")
                }
            )
        }
        
        cell.playedCompletion = { [weak self] in
            self?.playDownloadedVideo(for: video)
        }
        
        return cell
    }
}

