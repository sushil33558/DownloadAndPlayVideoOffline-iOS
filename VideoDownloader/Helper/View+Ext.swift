//
//  HelperMethod.swift
//  VideoDownloader
//
//  Created by Sushil Chaudhary on 27/04/25.
//

import Foundation
import UIKit

    //MARK: - Alert helper

extension UIViewController {
    func showAlertWithTwoActions(
        title: String,
        message: String,
        on viewController: UIViewController,
        firstButtonTitle: String,
        firstButtonAction: @escaping () -> Void,
        secondButtonTitle: String,
        secondButtonAction: @escaping () -> Void
    ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let firstAction = UIAlertAction(title: firstButtonTitle, style: .default) { _ in
            firstButtonAction()
        }
        
        let secondAction = UIAlertAction(title: secondButtonTitle, style: .cancel) { _ in
            secondButtonAction()
        }
        
        alertController.addAction(firstAction)
        alertController.addAction(secondAction)
        
        viewController.present(alertController, animated: true, completion: nil)
    }
    
    func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first(where: { $0.isKeyWindow }),
               let rootViewController = window.rootViewController {
                
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }

}

    //MARK: - Show toast

extension UIViewController {
    func showToast(message: String, duration: Double = 2.0) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 16
        blurView.clipsToBounds = true
        blurView.alpha = 0.0
        
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.boldSystemFont(ofSize: 16)
        toastLabel.numberOfLines = 0
        
        blurView.contentView.addSubview(toastLabel)
        window.addSubview(blurView)
        
        let maxWidth = window.frame.width - 60
        let textSize = toastLabel.sizeThatFits(CGSize(width: maxWidth - 40, height: CGFloat.greatestFiniteMagnitude))
        let labelWidth = min(textSize.width + 40, maxWidth)
        
        blurView.frame = CGRect(
            x: (window.frame.width - labelWidth) / 2,
            y: window.frame.height,
            width: labelWidth,
            height: 60
        )
        
        toastLabel.frame = CGRect(
            x: 20,
            y: 10,
            width: labelWidth - 40,
            height: 40
        )
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            blurView.alpha = 1.0
            blurView.frame.origin.y = window.frame.height - 150
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseIn, animations: {
                blurView.alpha = 0.0
                blurView.frame.origin.y = window.frame.height
            }, completion: { _ in
                blurView.removeFromSuperview()
            })
        })
    }
}


    //MARK: - Useful for remove 'amp;', " ". "\n" from url

func fixVideoURL(_ brokenURL: String) -> String {
    var fixedURL = brokenURL
    fixedURL = fixedURL.replacingOccurrences(of: "\n", with: "")
    fixedURL = fixedURL.replacingOccurrences(of: " ", with: "")
    fixedURL = fixedURL.replacingOccurrences(of: "amp;", with: "")
    return fixedURL
}

