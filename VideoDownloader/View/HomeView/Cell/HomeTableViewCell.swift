//
//  HomeTableViewCell.swift
//  VideoDownloader
//
//  Created by Sushil Chaudhary on 27/04/25.
//

import UIKit
import MBCircularProgressBar
import Lottie

class HomeTableViewCell: UITableViewCell {

    //MARK: - IBOUTLET
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var circularProgressBar: MBCircularProgressBarView!
    @IBOutlet weak var loaderView: UIView!
    @IBOutlet weak var downloadValLabel: UILabel!
    
    //MARK: - GLOBAL VARIABLE'S
    let loaderAnimationView = LottieAnimationView()
    static let reuseIdentifier = "HomeTableViewCell"
    
    var model: Video? {
        didSet {
            guard let model = model else {
                return
            }
            
            label.text = model.title
            configMusicState(model.videoState)
            
            circularProgressBar.value = CGFloat(model.progress) / 2
            downloadValLabel.text = "\(Int(model.progress))%"
        }
    }
    
    var deleteCompletion: (()->())?
    var downloadingCompletion: (()->())?
    var playedCompletion: (()->())?
    
    
    //MARK: - CELL CYCLE'S
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        initiateLoaderAnimation()

        circularProgressBar.progressLineWidth = 1.5
        circularProgressBar.progressColor = UIColor(named: "appTint")
        circularProgressBar.progressStrokeColor = UIColor(named: "appTint")
        circularProgressBar.emptyLineWidth = 1.5
        circularProgressBar.emptyLineColor = UIColor.lightGray
        circularProgressBar.showValueString = false
        circularProgressBar.showUnitString = false
        circularProgressBar.progressAngle = 180.0
        circularProgressBar.progressRotationAngle = -90.0
        circularProgressBar.fontColor = .black
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        deleteBtn.layer.cornerRadius = deleteBtn.frame.width / 2
        downloadBtn.layer.cornerRadius = deleteBtn.frame.width / 2
        parentView.layer.cornerRadius = 10
    }
    
    
    //MARK: - IBACTION'S
    @IBAction func deleteBtnTapped(_ sender: UIButton) {
        deleteCompletion?()
    }
    
    @IBAction func downloadBtnTapped(_ sender: UIButton) {
        downloadingCompletion?()
    }
    
    @IBAction func playBtnTapped(_ sender: UIButton) {
        playedCompletion?()
    }
    
    
    //MARK: - FUNCTION'S
    private func configMusicState(_ videoState: VideoState) {
        switch videoState {
        case .none:
            self.downloadBtn.setImage(UIImage(named: "download"), for: .normal)
            self.downloadBtn.isHidden = false
            self.playBtn.isHidden = true
            self.deleteBtn.isHidden = true
            self.circularProgressBar.isHidden = true
            
        case .isDownloading:
            self.circularProgressBar.isHidden = false
            self.downloadBtn.isHidden = true
            self.playBtn.isHidden = true
            self.deleteBtn.isHidden = true
            
        case .downloaded:
            self.playBtn.isHidden = false
            self.deleteBtn.isHidden = false
            self.circularProgressBar.isHidden = true
            self.downloadBtn.isHidden = true
            
        case .failed:
            self.downloadBtn.setImage(UIImage(named: "retry"), for: .normal)
            self.downloadBtn.isHidden = false
            self.playBtn.isHidden = true
            self.deleteBtn.isHidden = true
            self.circularProgressBar.isHidden = true
        }
    }
    
    
    private func initiateLoaderAnimation() {
        loaderAnimationView.frame = CGRect(x: -7.5, y: -7.5, width: loaderView.frame.width + 15, height: loaderView.frame.height + 15)
        loaderView.addSubview(loaderAnimationView)
        
        loaderAnimationView.loopMode = .loop
        
        let circularWaveAnimation = LottieAnimation.named("loader")
        loaderAnimationView.animation = circularWaveAnimation
    }
    
}
